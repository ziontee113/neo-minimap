local M = {}

local function set_key(modes, keys, callback, opts)
	if type(keys) == "string" then
		keys = { keys }
	end
	for _, key in ipairs(keys) do
		vim.keymap.set(modes, key, callback, opts)
	end
end

---@param state minimap_state
---@param lines minimap_line_object[]
M.handle_keymaps = function(state, lines)
	set_key("n", { "q", "<Esc>" }, function()
		vim.api.nvim_win_close(state.minimapWin, true)
	end, { buffer = state.minimapBuf })
end

return M
