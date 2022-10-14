local M = {}

-- TODO: Add hot query swapping / filtering functionality
-- TODO: Add current cursor position when initiate Window Maker
-- TODO: Handle duplications

-- local ts_utils = require("nvim-treesitter.ts_utils")
local ns = vim.api.nvim_create_namespace("buffer-brower-ns")

local function __set_lnum_extmarks(buf, lnumLines, opts)
	local line_max = tonumber(#tostring(lnumLines[#lnumLines]))

	for i, lnum in ipairs(lnumLines) do
		local str = tostring(lnum + 1)
		str = string.rep(" ", line_max - #str) .. str

		vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
			virt_text = { { str, opts.hl_group } },
			virt_text_pos = "overlay",
		})
	end
end

local function __buffer_query_processor(opts)
	local return_tbl = {
		textLines = {},
		lnumLines = {},
		lcolLines = {},
		oldBuf = vim.api.nvim_get_current_buf(),
		oldWin = vim.api.nvim_get_current_win(),
	}

	local ts = vim.treesitter
	local current_buffer = vim.api.nvim_get_current_buf()

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
		OpenFOAM = "foam",
		pandoc = "markdown",
		rmd = "markdown",
		cs = "c_sharp",
	}

	opts.filetype = vim.bo[current_buffer].ft
	local ok, parser = pcall(ts.get_parser, 0)
	if not ok then
		local cur_buf_filetype = vim.bo[current_buffer].ft
		parser = ts.get_parser(0, filetype_to_parsername[cur_buf_filetype])
		opts.filetype = filetype_to_parsername[cur_buf_filetype]
	end

	local trees = parser:parse()
	local root = trees[1]:root()

	local ok, iter_query = pcall(vim.treesitter.query.parse_query, opts.filetype, opts.query)
	if ok then
		local duplications_hashmap_check = {}
		for _, matches, _ in iter_query:iter_matches(root, 0) do
			local row, col = matches[1]:range()

			if not duplications_hashmap_check[row] then
				local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
				table.insert(return_tbl.textLines, string.rep(" ", #tostring(row)) .. "\t" .. line_text)
				table.insert(return_tbl.lnumLines, row)
				table.insert(return_tbl.lcolLines, col)
				duplications_hashmap_check[row] = true
			end
		end
	end

	return return_tbl
end

local defaults = {
	hl_group = "DiagnosticWarn",
	auto_jump = true,
	width = 44,
	height = 12,
}

local function jump_and_zz(line_data)
	local curLine = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_win_set_cursor(line_data.oldWin, { line_data.lnumLines[curLine] + 1, line_data.lcolLines[curLine] })

	vim.api.nvim_win_call(line_data.oldWin, function()
		vim.cmd([[normal! zz]])
	end)
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
		jump_and_zz(line_data)
	end, { buffer = buf })
	vim.keymap.set("n", "<CR>", function()
		jump_and_zz(line_data)
		vim.api.nvim_win_close(win, true)

		vim.fn.win_gotoid(line_data.oldWin)
	end, { buffer = buf })

	if opts.search_patterns then
		for _, v in ipairs(opts.search_patterns) do
			local pattern, keymap, forward = unpack(v)
			vim.keymap.set("n", keymap, function()
				if forward == true then
					if old_search_pattern ~= pattern then
						vim.cmd("/" .. pattern)
					else
						vim.cmd("norm! n")
					end
				elseif forward == false then
					if old_search_pattern ~= pattern then
						vim.cmd("?" .. pattern)
					else
						vim.cmd("norm! N")
					end
				end
			end, { buffer = buf })
		end
	end
end

M.browse = function(opts)
	local line_data = __buffer_query_processor(opts)
	if #line_data.lnumLines == 0 then
		print("0 targets for buffer-browser")
		return
	end

	for k, v in pairs(defaults) do
		if opts[k] == nil then
			opts[k] = v
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", opts.filetype) -- WARN: this opts.filetype got mutated in __buffer_query_processor()
	vim.api.nvim_buf_set_option(buf, "bufhidden", "delete")

	local stats = vim.api.nvim_list_uis()[1]
	local width = stats.width
	local height = stats.height
	local winWidth = opts.width
	local winHeight = opts.height

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = winWidth,
		col = math.ceil((width - winWidth) / 2),
		row = math.ceil((height - winHeight) / 2) - 1,
		style = "minimal",
		height = winHeight,
		border = "single",
	})

	vim.api.nvim_win_set_option(win, "winhl", "Normal:")
	vim.api.nvim_win_set_option(win, "scrolloff", 2)
	vim.api.nvim_win_set_option(win, "conceallevel", 0)
	vim.api.nvim_win_set_option(win, "concealcursor", "n")
	vim.api.nvim_win_set_option(win, "cursorline", true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, line_data.textLines or {})

	__set_lnum_extmarks(buf, line_data.lnumLines, opts)
	__mappings_handling(buf, win, line_data, opts)

	local group = vim.api.nvim_create_augroup("Augroup Name", { clear = true })
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		group = group,
		callback = function()
			if opts.auto_jump then
				jump_and_zz(line_data)
			end
		end,
	})
end

local augroup = vim.api.nvim_create_augroup("BufferBrowser", {})
M.set = function(keymap, pattern, opts)
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = pattern,
		group = augroup,
		callback = function()
			vim.keymap.set("n", keymap, function()
				M.browse(opts)
			end, { buffer = 0 })
		end,
	})
end

return M
