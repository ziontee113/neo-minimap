local M = {}

---@param state minimap_state
---@param lines minimap_line_object[]
local function jump_and_zz(state, lines)
	local curLine = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_win_set_cursor(state.contentWin, { lines[curLine].lnum + 1, lines[curLine].lcol })

	vim.api.nvim_win_call(state.contentWin, function()
		vim.cmd([[normal! zz]])
	end)
end

---@param state minimap_state
---@param lines minimap_line_object[]
M.handle_autocmds = function(state, lines)
	local window_augroup_name = "NeoMinimapFloat"
	pcall(vim.api.nvim_del_augroup_by_name, window_augroup_name)
	local augroup = vim.api.nvim_create_augroup(window_augroup_name, {})

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = state.minimapBuf,
		group = augroup,
		callback = function()
			jump_and_zz(state, lines)
		end,
	})
end

return M
