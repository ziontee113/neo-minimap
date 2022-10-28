local M = {}
local window_lib = require("neo-minimap.lib.window")
local query_handler = require("neo-minimap.handlers.treesitter-query")

---@class minimap_state
---@field contentBuf number
---@field contentWin number
---@field minimapBuf number
---@field minimapWin number
---@field filetype string

---@type minimap_state
local minimap_state = {}

---@class browse_opts
---@field queries string[]
---@field regex string[]

---@param opts browse_opts
M.browse = function(opts)
	-- get contentBuf and contentWin
	local contentBuf = vim.api.nvim_get_current_buf()
	local contentWin = vim.api.nvim_get_current_win()
	local filetype = vim.bo[contentBuf].ft

	-- open floating window, get minimapWin and minimapBuf
	local minimapWin, minimapBuf = window_lib.open_win({
		open_win_opts = {
			relative = "editor",
			width = 40,
			height = 10,
		},
	})

	vim.api.nvim_buf_set_option(minimapBuf, "filetype", filetype)

	-- initiate minimap_state
	minimap_state = {
		contentBuf = contentBuf,
		contentWin = contentWin,
		minimapBuf = minimapBuf,
		minimapWin = minimapWin,
		filetype = filetype,
	}

	-- get minimap_lines_objects
	local minimap_lines_objects = {}
	for _, query in ipairs(opts.queries) do
		query_handler.handle_query(query, minimap_state, minimap_lines_objects)
	end

	-- turn minimap_lines_objects to minimap_lines
	local minimap_lines = {}
	for _, line in ipairs(minimap_lines_objects) do
		table.insert(minimap_lines, line.text)
	end

	vim.api.nvim_buf_set_lines(minimap_state.minimapBuf, 0, -1, false, minimap_lines)
end

vim.keymap.set("n", "zi", function()
	M.browse({
		queries = {
			[[
    ;; query
    ((function_declaration) @cap)
    ((assignment_statement(expression_list((function_definition) @cap))))
            ]],
		},
	})
end, {})

return M
