## Neo-Minimap

Plugin for Neovim that lets you create your own *"minimap"* from *Treesitter Queries*.

https://user-images.githubusercontent.com/102876811/195559738-2508d4b0-c33e-44ad-a617-fa785e1c7a57.mp4

## Syntax

```lua
local nm = require("neo-minimap")

nm.set("keymap", "filetype", { -- `:set filetype?` if you don't know your desired filetype
	query = [[
;; query
((query_goes_here) @cap)
  ]],

    regex = { "vim_regex_goes_here" }, -- vim regex option, for when you can't or don't want to use Treesitter Queries

	search_patterns = { -- optional
		{ "/search", "search_mapping", true }, -- true means search forward
		{ "/search", "search_mapping", false }, -- false means search backwards
	},
	width = 44, -- optional, defaults to 44, width of the minimap
	height = 12, -- optional, defaults to 12, height of the minimap
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
	regex = { [[\.insert]] }, -- 1 vim regex, matches lines with `.insert` pattern
	search_patterns = {
		{ "function", "<C-j>", true }, -- jump to the next 'function' (Vim pattern)
		{ "function", "<C-k>", false }, -- jump to the previous 'function' (Vim pattern)
		{ "keymap", "<A-j>", true }, -- jump to the next 'keymap' (Vim pattern)
		{ "keymap", "<A-k>", false }, -- jump to the previous 'keymap' (Vim pattern)
	},
})
```

Example for Typescript:
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

https://user-images.githubusercontent.com/102876811/195559769-0373bc88-9cba-4731-a7d2-7ec5c461b569.mp4

## Minimap Specific Mappings

- `a` - Toggle `auto_jump`
- `c` - Toggle `conceallevel`
- `q` / `Esc` - close the Minimap
- `h` / `t` - toggle Treesitter highlighting for Minimap

- `l` - jump to location (for when `auto_jump` is `false`), doesn't close Minimap.
- `Enter` - jump to location, closes Minimap.

## The `.browse()` method

You can also use `nm.browse()` method if you want more control over how you define your keymaps.

Syntax:

```lua
nm.browse(opts)
```

Example:

```lua
local nm = require("neo-minimap")

vim.keymap.set("n", "your_keymap", function()
    nm.browse({
        query = [[
    ;; query
    ((for_statement) @cap)
    ((function_declaration) @cap)
      ]],
        search_patterns = {
            { "function", "<C-j>", true },
            { "function", "<C-k>", false },
        },
        width = 44,
        height = 12,
    })
end)
```
