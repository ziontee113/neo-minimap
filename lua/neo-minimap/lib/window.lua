local M = {}

---@class open_win_opts
---@field width number
---@field height number
---@field style "minimal"
---@field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|table
---@field noautocmd boolean
---@field relative "editor"|"cursor"

---@class win_set_opts
---@field winhl string
---@field cursorline boolean

---@class buf_set_opts
---@field filetype string
---@field bufhidden "delete"

---@class open_center_window_opts
---@field open_win_opts open_win_opts
---@field win_set_opts win_set_opts
---@field buf_set_opts buf_set_opts

---open floating window at the center of the editor
---@return number, number
---@param opts open_center_window_opts
M.open_center_window = function(opts)
	local buf, win

	-- handle buf_set_opts
	buf = vim.api.nvim_create_buf(false, true)
	local default_buf_set_opts = {
		filetype = "",
		bufhidden = "delete",
	}
	opts.buf_set_opts = vim.tbl_extend("force", default_buf_set_opts, opts.buf_set_opts or {})
	for key, value in pairs(opts.buf_set_opts) do
		vim.api.nvim_buf_set_option(buf, key, value)
	end

	-- get editorStats
	local editorStats = vim.api.nvim_list_uis()[1]
	local editorWidth = editorStats.width
	local editorHeight = editorStats.height

	-- handle open_win_opts
	local col = math.ceil((editorWidth - opts.open_win_opts.width) / 2)
	local row = math.ceil((editorHeight - opts.open_win_opts.height) / 2) - 1

	if opts.open_win_opts.relative == "cursor" then
		col = 0
		row = 0
	end

	local default_open_win_opts = {
		relative = opts.open_win_opts.relative,
		col = col,
		row = row,
		style = "minimal",
		border = "single",
		width = opts.open_win_opts.width,
		height = opts.open_win_opts.height,
	}
	opts.open_win_opts = vim.tbl_extend("force", default_open_win_opts, opts.open_win_opts or {})
	win = vim.api.nvim_open_win(buf, true, opts.open_win_opts) -- win open

	-- handle win_set_opts
	local default_win_set_opts = {
		winhl = "NormalFloat:",
		cursorline = true,
	}
	opts.win_set_opts = vim.tbl_extend("force", default_win_set_opts, opts.win_set_opts or {})
	for key, value in pairs(opts.win_set_opts) do
		vim.api.nvim_win_set_option(win, key, value)
	end

	return win, buf
end

---if `value` is *nil*, `toggle` *current_modifiable_value*
--- -> *modifiable* = *not current_modifiable_value*
---otherwise set `modifiable` to `value`
---@param buf number
---@param value boolean
M.toggle_buffer_modifiable = function(buf, value)
	local current_modifiable_value = vim.bo[buf].modifiable
	if value ~= nil then
		vim.api.nvim_buf_set_option(buf, "modifiable", value)
	else
		vim.api.nvim_buf_set_option(buf, "modifiable", not current_modifiable_value)
	end
end

return M
