## Neo-Minimap

Plugin for Neovim that lets you create your own *"minimap"* from *Treesitter Queries*.

## Syntax

```lua
local nm = require("neo-minimap")

nm.set("keymap", "language", {
	query = [[
;; query
((query_goes_here) @cap)
  ]],
	search_patterns = {
		{ "/search", "search_mapping", true }, -- true means search forward
		{ "/search", "search_mapping", false }, -- false means search backwards
	},


	hl_group = "my_hl_group", -- optional, defaults to "DiagnosticWarn"
	auto_jump = true, -- optional, defaults to `true`, auto jump when move cursor
})
```

## Example

Example for Lua:
```lua
local nm = require("neo-minimap") -- for shorthand use later

-- Lua
nm.set("zi", "lua", { -- press `zi` to open the minimap, in `lua` files
	query = [[
;; query
((for_statement) @cap) ;; matches for loops
((function_call (dot_index_expression) @field (#eq? @field "vim.keymap.set")) @cap) ;; matches vim.keymap.set
((function_declaration) @cap) ;; matches function declarations
  ]],
	search_patterns = {
		{ "function", "<C-j>", true }, -- jump to the next 'function' (Vim pattern)
		{ "function", "<C-k>", false }, -- jump to the previous 'function' (Vim pattern)
		{ "keymap", "<A-j>", true }, -- jump to the next 'keymap' (Vim pattern)
		{ "keymap", "<A-k>", false }, -- jump to the previous 'keymap' (Vim pattern)
	},
})
```

```lua
local nm = require("neo-minimap") -- for shorthand use later

-- TSX
nm.set("zi", "typescriptreact", {  -- press `zi` to open the minimap, in `typescriptreact` files
	query = [[
;; query
((function_declaration) @cap) ;; matches function declarations
((arrow_function) @cap) ;; matches arrow functions
((identifier) @cap (#vim-match? @cap "^use.*")) ;; matches hooks (useState, useEffect, use***, etc...)
  ]],
})
```

## Minimap Specific Mappings

- `a` - Toggle `auto_jump`
- `c` - Toggle `conceallevel`
- `q` / `Esc` - close the Minimap
- `h` / `t` - toggle Treesitter highlighting for Minimap

- `l` - jump to location (for when `auto_jump` is `false`), doesn't close Minimap.
- `Enter` - jump to location, closes Minimap.
