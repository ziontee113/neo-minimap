local M = {}
local extmark_handler = require("neo-minimap.handlers.extmarks")

-- stylua: ignore
local labels = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ";", "!",
}

---@param state minimap_state
---@param lines minimap_line_object[]
M.initiate_jumper = function(state, lines)
	-- clear all lnum extmarks
	vim.api.nvim_buf_clear_namespace(state.minimapBuf, state.namespace, 0, -1)

	-- display labels
	local first_line, last_line = vim.fn.line("w0"), vim.fn.line("w$")
	local hash_table = {}

	local labels_index = 1
	for i = first_line, last_line do
		local row = i - 1
		local col = state.space_for_digits - 1

		hash_table[labels[labels_index]] = row + 1

		vim.api.nvim_buf_set_extmark(state.minimapBuf, state.namespace, row, col, {
			virt_text = { { labels[labels_index], "@field" } },
			virt_text_pos = "overlay",
		})
		labels_index = labels_index + 1
	end

	vim.cmd("redraw")

	-- get_char
	local ok, keynum = pcall(vim.fn.getchar)
	if ok then
		local key = string.char(keynum)
		if hash_table[key] then
			vim.api.nvim_win_set_cursor(state.minimapWin, { hash_table[key], 0 })
		end
	end

	-- return the lnum extmarks
	vim.api.nvim_buf_clear_namespace(state.minimapBuf, state.namespace, 0, -1)
	extmark_handler.handle_extmarks(state, lines)

	-- close the win for now
	vim.schedule(function()
		vim.api.nvim_win_close(state.minimapWin, true)
	end)
end

return M
