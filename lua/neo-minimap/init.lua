local M = {}
local window_lib = require("neo-minimap.lib.window")

-- TODO:

vim.keymap.set("n", "zi", function()
	window_lib.open_center_window({
		open_win_opts = {
			relative = "cursor",
			width = 20,
			height = 10,
		},
	})
end, {})

return M
