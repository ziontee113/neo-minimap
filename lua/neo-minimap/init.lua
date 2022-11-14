local M = {}
local autocmd_list = {}

local oldBuf, oldWin
local oldContentBuf, oldContentWin
local move_start_init = false

local ns = vim.api.nvim_create_namespace("neo-minimap-ns")
local old_write_autocmd

local user_defaults = {}
local defaults = {
	hl_group = "LineNr",
	auto_jump = true,
	width = 44,
	height = 12,
	height_toggle_index = 1,
	query_index = 1,
}
local default_win_opts = {
	winhl = "NormalFloat:",
	scrolloff = 2,
	conceallevel = 0,
	concealcursor = "n",
	cursorline = true,
}

local function __set_lnum_extmarks(buf, lines, opts)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	local lnumLines = {}
	for _, line in ipairs(lines) do
		table.insert(lnumLines, line.lnum)
	end

	local line_max = tonumber(#tostring(lnumLines[#lnumLines]))

	for i, line in ipairs(lines.lines) do
		local lnum = line.lnum
		local str = tostring(lnum + 1)
		str = string.rep(" ", line_max - #str) .. str

		vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
			virt_text = { { str, opts.hl_group } },
			virt_text_pos = "overlay",
		})
	end
end

local function __buffer_query_processor(opts)
	local duplications_hashmap_check = {}
	local return_tbl = {
		lines = {},
		oldBuf = vim.api.nvim_get_current_buf(),
		oldWin = vim.api.nvim_get_current_win(),
	}

	-- Treesitter Query Results Handling
	local ts = vim.treesitter
	local current_buffer

	if not opts.hotswap then
		current_buffer = return_tbl.oldBuf
		oldContentBuf = current_buffer
		oldContentWin = return_tbl.oldWin
	else
		current_buffer = oldContentBuf
		return_tbl.oldBuf = oldContentBuf
		return_tbl.oldWin = oldContentWin
	end

	local filetype_to_parsername = {
		arduino = "cpp",
		javascriptreact = "javascript",
		ecma = "javascript",
		jsx = "javascript",
		PKGBUILD = "bash",
		html_tags = "html",
		typescriptreact = "tsx",
		["typescript.tsx"] = "tsx",
		terraform = "hcl",
		["html.handlebars"] = "glimmer",
		systemverilog = "verilog",
		cls = "latex",
		sty = "latex",
		tex = "latex",
		OpenFOAM = "foam",
		pandoc = "markdown",
		rmd = "markdown",
		cs = "c_sharp",
	}

	opts.filetype = vim.bo[current_buffer].ft
	local ok, parser = pcall(ts.get_parser, current_buffer)
	if not ok then
		local cur_buf_filetype = vim.bo[current_buffer].ft

		ok, parser = pcall(ts.get_parser, current_buffer, filetype_to_parsername[cur_buf_filetype])
		if ok then
			opts.filetype = filetype_to_parsername[cur_buf_filetype]
		end
	end

	local root
	if parser and type(parser) ~= "string" then
		local trees = parser:parse()
		root = trees[1]:root()
	end

	local ok, iter_query = pcall(vim.treesitter.query.parse_query, opts.filetype, opts.query[opts.query_index] or "")
	if ok then
		for _, matches, _ in iter_query:iter_matches(root, current_buffer) do
			local row, col = matches[1]:range()

			if not duplications_hashmap_check[row] then
				local line_text = vim.api.nvim_buf_get_lines(current_buffer, row, row + 1, false)[1]
				if opts.disable_indentation then
					line_text = line_text:gsub("^%s+", "")
				end
				table.insert(return_tbl.lines, {
					text = string.rep(" ", #tostring(row)) .. "\t" .. line_text,
					lnum = row,
					lcol = col,
				})
				duplications_hashmap_check[row] = true
			end
		end
	end

	-- Vim Regex Results Handling
	if opts.regex then
		if opts.regex[opts.query_index] then
			for _, pattern in ipairs(opts.regex[opts.query_index]) do
				local regex = vim.regex(pattern)
				local buf_lines = vim.api.nvim_buf_get_lines(return_tbl.oldBuf, 0, -1, false)

				for row, line in ipairs(buf_lines) do
					if regex:match_str(line) then
						if not duplications_hashmap_check[row] then
							if opts.disable_indentation then
								line = line:gsub("^%s+", "")
							end
							table.insert(return_tbl.lines, {
								text = string.rep(" ", #tostring(row)) .. "\t" .. line,
								lnum = row - 1,
								lcol = 0,
							})
							duplications_hashmap_check[row] = true
						end
					end
				end
			end
		end
	end

	-- Sort return_tbl according to lnumLines
	table.sort(return_tbl.lines, function(a, b)
		return a.lnum < b.lnum
	end)

	return return_tbl
end

local function jump_and_zz(line_data, opts)
	if move_start_init or opts.auto_jump == false then
		local curLine = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_win_set_cursor(
			line_data.oldWin,
			{ line_data.lines[curLine].lnum + 1, line_data.lines[curLine].lcol }
		)

		vim.api.nvim_win_call(line_data.oldWin, function()
			vim.cmd([[normal! zz]])
		end)

		opts.current_cursor_line_pos = line_data.lines[curLine].lnum + 1
	else
		move_start_init = true
	end
end

local function __protected_search(command, pattern)
	local full_command = command .. pattern
	local ok, _ = pcall(vim.cmd, full_command)

	if not ok then
		print("Pattern Not Found")
	end
end

local old_search_pattern = ""
local function __mappings_handling(buf, win, line_data, opts)
	-- add cutom user buffer mappings here
	vim.keymap.set("n", "q", ":q!<cr>", { buffer = buf })
	vim.keymap.set("n", "<Esc>", ":q!<cr>", { buffer = buf })
	vim.keymap.set("n", "t", ":TSBufToggle highlight<cr>", { buffer = buf })
	vim.keymap.set("n", "h", ":TSBufToggle highlight<cr>", { buffer = buf })
	vim.keymap.set("n", "c", function()
		if vim.wo.conceallevel > 0 then
			vim.wo.conceallevel = 0
		else
			vim.wo.conceallevel = 2
		end
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "a", function()
		opts.auto_jump = not opts.auto_jump
	end, { buffer = buf })
	vim.keymap.set("n", "l", function()
		jump_and_zz(line_data, opts)
		if opts.auto_jump then
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buf })
	vim.keymap.set("n", "<CR>", function()
		jump_and_zz(line_data, opts)
		vim.api.nvim_win_close(win, true)

		vim.fn.win_gotoid(line_data.oldWin)
	end, { buffer = buf })

	-- will open Minimap as vsplit
	vim.keymap.set("n", "<C-s>", function()
		vim.api.nvim_win_call(oldWin, function()
			vim.cmd(":vs")
			vim.api.nvim_win_close(win, true)
			oldWin = vim.api.nvim_get_current_win()
		end)
	end, { buffer = buf })

	-- will open target in vsplit
	vim.keymap.set("n", "<C-v>", function()
		if opts.auto_jump then
			vim.api.nvim_win_call(oldWin, function()
				jump_and_zz(line_data, opts)
				vim.api.nvim_win_close(win, true)
				vim.cmd(":vs")
			end)
		else
			-- get current Minimap Line
			local curMinimapLine = vim.api.nvim_win_get_cursor(0)[1]

			-- move to oldContentWin, :vs
			vim.api.nvim_set_current_win(oldContentWin)
			vim.cmd.vs()

			-- set cursor position for new vsplit, then "zz"
			vim.api.nvim_win_set_cursor(
				0,
				{ line_data.lines[curMinimapLine].lnum + 1, line_data.lines[curMinimapLine].lcol }
			)
			vim.cmd("norm! zz")

			-- close Minimap
			vim.api.nvim_win_close(win, true)
		end
	end, {})

	-- Hot swap mapping
	vim.keymap.set("n", "o", function()
		opts.hotswap = true
		opts.query_index = opts.query_index + 1
		if opts.query_index > #opts.query then
			opts.query_index = 1
		end
		M.browse(opts)
	end, { buffer = buf })
	vim.keymap.set("n", "i", function()
		opts.hotswap = true
		opts.query_index = opts.query_index - 1
		if opts.query_index < 1 then
			opts.query_index = #opts.query
		end
		M.browse(opts)
	end, { buffer = buf })

	vim.keymap.set("n", "<C-h>", function()
		if opts.height_toggle then
			-- set height
			opts.height_toggle_index = opts.height_toggle_index + 1
			if opts.height_toggle_index > #opts.height_toggle then
				opts.height_toggle_index = 1
			end
			vim.api.nvim_win_set_height(0, opts.height_toggle[opts.height_toggle_index])

			-- set pos
			local stats = vim.api.nvim_list_uis()[1]
			vim.api.nvim_win_set_config(0, {
				relative = "editor",
				row = math.ceil((stats.height - opts.height_toggle[opts.height_toggle_index]) / 2),
				col = opts.open_win_opts.col,
			})
		end
	end, { buffer = buf })

	if opts.search_patterns then
		for _, v in ipairs(opts.search_patterns) do
			local pattern, keymap, forward = unpack(v)
			vim.keymap.set("n", keymap, function()
				if forward == true then
					if old_search_pattern ~= pattern then
						__protected_search("/", pattern)
					else
						vim.cmd("norm! n")
					end
				elseif forward == false then
					if old_search_pattern ~= pattern then
						__protected_search("/", pattern)
					else
						vim.cmd("norm! N")
					end
				end
			end, { buffer = buf })
		end
	end
end

M.browse = function(opts)
	vim.cmd("norm! m'") -- add current cursor position to the jump list before opening Minimap

	-- Queries handling
	if opts.query then
		if type(opts.query) == "string" then
			opts.query = { opts.query }
		end
		for i, _ in ipairs(opts.query) do
			if type(opts.query[i]) == "number" then
				if opts.query[opts.query[i]] then
					opts.query[i] = opts.query[opts.query[i]]
				end
			end
		end
	end
	if opts.regex then
		-- Regex handling
		for i, value in ipairs(opts.regex) do
			if type(value) == "string" then
				opts.regex[i] = { opts.regex[i] }
			end
		end
		for i, regex_group in ipairs(opts.regex) do
			if type(regex_group) == "number" then
				opts.regex[i] = opts.regex[regex_group]
			end
		end
	end

	-- Default options handling
	for k, v in pairs(defaults) do
		if opts[k] == nil then
			opts[k] = v
		end
	end

	-- Get Line Data
	local line_data = __buffer_query_processor(opts)
	if #line_data.lines == 0 then
		print("0 targets for buffer-browser")
		return
	end

	-- Buf & Win Handling
	local buf, win

	if opts.hotswap then
		buf = oldBuf
		win = oldWin
	end

	if not opts.hotswap then
		-- Buffer opts section
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(buf, "filetype", opts.filetype) -- WARN: this opts.filetype got mutated in __buffer_query_processor()
		vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")
		vim.api.nvim_buf_set_option(buf, "tabstop", 4)
		vim.api.nvim_buf_set_option(buf, "softtabstop", 4)
		vim.api.nvim_buf_set_option(buf, "shiftwidth", 4)

		local stats = vim.api.nvim_list_uis()[1]
		local width = stats.width
		local height = stats.height
		local winWidth = opts.width
		local winHeight = opts.height

		-- nvim_open_win section
		local open_win_opts = {
			relative = "editor",
			width = winWidth,
			col = math.ceil((width - winWidth) / 2),
			row = math.ceil((height - winHeight) / 2) - 1,
			style = "minimal",
			height = winHeight,
			border = "single",
		}

		if opts.open_win_opts then
			for key, value in pairs(opts.open_win_opts) do
				open_win_opts[key] = value
			end
		end

		opts.open_win_opts = open_win_opts
		win = vim.api.nvim_open_win(buf, true, open_win_opts)

		-- win_set_option section
		if opts.win_opts then
			for key, value in pairs(opts.win_opts) do
				default_win_opts[key] = value
			end
		end

		for key, value in pairs(default_win_opts) do
			vim.api.nvim_win_set_option(win, key, value)
		end

		oldBuf = buf
		oldWin = win
	end

	-- Set Minimap Lines
	local setTextLines = {}
	for _, line in ipairs(line_data.lines) do
		table.insert(setTextLines, line.text)
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, setTextLines or {})

	-- Set minimap to the closest possible location
	move_start_init = false
	local last_compare = math.huge
	for i, line in ipairs(line_data.lines) do
		if math.abs(line.lnum - opts.current_cursor_line_pos) < last_compare then
			last_compare = math.abs(line.lnum - opts.current_cursor_line_pos)
			vim.api.nvim_win_set_cursor(win, { i, 0 })
		else
			break
		end
	end

	__set_lnum_extmarks(buf, line_data, opts)
	__mappings_handling(buf, win, line_data, opts)

	-- Cursor Move handling
	local group = vim.api.nvim_create_augroup("Neo-Minimap-CursorMoved", { clear = true })
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		group = group,
		callback = function()
			if opts.auto_jump then
				jump_and_zz(line_data, opts)
			end
		end,
	})
end

local augroup = vim.api.nvim_create_augroup("Neo-Minimap", {})
M.set = function(keymaps, pattern, opts)
	-- Event Handling
	local events = { "FileType" }
	if type(pattern) == "string" then
		pattern = { pattern }
	end
	for _, p in ipairs(pattern) do
		if string.match(p, "%*") then
			events = { "BufEnter" }
			break
		end
	end
	if opts.events then
		events = opts.events
	end

	local autocmd = vim.api.nvim_create_autocmd(events, {
		pattern = pattern,
		group = augroup,
		callback = function()
			if type(keymaps) == "string" then
				keymaps = { keymaps }
			end
			for i, value in ipairs(keymaps) do
				vim.keymap.set("n", value, function()
					opts.hotswap = nil
					opts.query_index = i
					opts.current_cursor_line_pos = vim.api.nvim_win_get_cursor(0)[1]

					-- user_defaults handling
					for key, opts_value in pairs(user_defaults) do
						if not opts[key] then
							opts[key] = opts_value
						end
					end

					M.browse(opts)
				end, { buffer = 0 })
			end
		end,
	})

	table.insert(autocmd_list, autocmd)
end

M.setup_defaults = function(opts)
	user_defaults = opts
end

M.clear_all = function()
	for _, autocmd in ipairs(autocmd_list) do
		vim.api.nvim_del_autocmd(autocmd)
	end
	autocmd_list = {}
end
M.source_on_save = function(path)
	if old_write_autocmd then
		vim.api.nvim_del_autocmd(old_write_autocmd)
	end

	old_write_autocmd = vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = path .. "*",
		group = augroup,
		callback = function()
			M.clear_all()
			vim.cmd(":so")
		end,
	})
end

return M
