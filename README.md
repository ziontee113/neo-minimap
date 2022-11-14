## Neo-Minimap

Plugin for Neovim that lets you create your own *"minimap"* from *Treesitter Queries* or *Vim Regex*.

https://user-images.githubusercontent.com/102876811/195559738-2508d4b0-c33e-44ad-a617-fa785e1c7a57.mp4

## Overview & Setup Guide

[![neominimap](https://user-images.githubusercontent.com/102876811/196762594-8eadeef9-97e9-4c8c-94fb-d4071b698264.png)](https://youtu.be/vNyQBWfSh7c)

You can watch Overview & Setup Guide on [Youtube](https://youtu.be/vNyQBWfSh7c)

## New Syntax

```lua
-- for shorthand usage
local nm = require("neo-minimap")

-- will reload your neo-minimap config file on save
-- works only when you have only 1 neo-minimap config file
nm.source_on_save("/path/to/your/neo-minimap/config-file") -- optional

nm.set({"keymap1", "keymap2"}, { "*.your_file_extension", "your_autocmd_pattern" }, {
     events = { "BufEnter" },

     -- lua table, values inside can be type `string` or `number`
     -- accepts multiple treesitter queries, corresponse to each keymap,
     -- if you press "keymap1", minimap will start with first query,
     -- if you press "keymap2", minimap will start with second query,
     -- you can have empty query table option if you want to use regex only
    query = {
            [[
        ;; query
        ((function_declaration) @cap)
        ((assignment_statement(expression_list((function_definition) @cap))))
        ]], -- first query
            [[
        ;; query
        ((function_declaration) @cap)
        ((assignment_statement(expression_list((function_definition) @cap))))
        ((for_statement) @cap)
        ]], -- second query

        1, -- if passed in a number, a query with that index will take it's place
           -- in this case, instead of copying the entire first query,
           -- we use `1` to point to it.
    },

    -- optional
	regex = { -- lua table, values inside can be type `table` or `number`
		{ [[--.*]], [[===.*===]] }, -- first set of regexes
		{}, -- no regex
		1, -- acts as first regex set
	},
    -- you can have empty regex option if you want to use Treesitter queries only

    -- optional
    search_patterns = {
		{ "vim_regex", "<C-j>", true }, -- jump to the next instance of "vim_regex"
		{ "vim_regex", "<C-k>", false }, -- jump to the previous instance of "vim_regex"
	},

    auto_jump = true, -- optional, defaults to `true`, auto jump when move cursor

    -- other options
    width = 44, -- optional, defaults to 44, width of the minimap
    height = 12, -- optional, defaults to 12, height of the minimap
    hl_group = "my_hl_group", -- highlight group of virtual text, optional, defaults to "DiagnosticWarn"
    
    open_win_opts = {}, -- optional, for setting custom `nvim_open_win` options
    win_opts = {}, -- optional, for setting custom `nvim_win_set_option` options
    
    -- change minimap's height with <C-h>
    -- this means default minimap height is 12
    -- minimap height will change to 36 after pressing <C-h>
    height_toggle = { 12, 36 },

    disable_indentation = false, -- if `true`, will remove any white space / tab at the start of the results.
})
```

[Here's the config I use myself](https://github.com/ziontee113/ziontee113-neovim-config/blob/master/lua/plugins/neo-minimap/init.lua)

## Minimap Specific Mappings

- `a` - Toggle `auto_jump`
- `c` - Toggle `conceallevel`
- `q` / `Esc` - close the Minimap
- `h` / `t` - toggle Treesitter highlighting for Minimap

- `<C-h>` - toggle Minimap's height, depends on `height_toggle` option
- `i` - **switch to previous query && set of regexes**
- `o` - **switch to next query && set of regexes**

- `<C-s>` - open Minimap in vertical split
- `<C-v>` - open the result in vertical split

- `l` - jump to location, (depends on `auto_jump`), if `true` doesn't close Minimap, if `false` do.
- `Enter` - jump to location, closes Minimap.

## The setup_default() function

You can call `nm.setup_default({opts})` to set up default options.

```lua
nm.setup_defaults({
	height_toggle = { 12, 36 },
})
```

<details>
<summary>Old Syntax</summary>

## Syntax

```lua
local nm = require("neo-minimap")

nm.set("keymap", "filetype", { -- `:set filetype?` if you don't know your desired filetype
	query = [[
;; query
((query_goes_here) @cap)
  ]],

    regex = { 
        "vim_regex_goes_here",
        [[another_vim_regex]],
    }, -- vim regex option, for when you can't or don't want to use Treesitter Queries

	search_patterns = { -- optional
		{ "/search", "search_mapping", true }, -- true means search forward
		{ "/search", "search_mapping", false }, -- false means search backwards
	},
	width = 44, -- optional, defaults to 44, width of the minimap
	height = 12, -- optional, defaults to 12, height of the minimap
	hl_group = "my_hl_group", -- optional, defaults to "LineNr"
	auto_jump = true, -- optional, defaults to `true`, auto jump when move cursor

    open_win_opts = {}, -- optional, for setting `nvim_open_win` options
    win_opts = {}, -- optional, for setting `nvim_win_set_option` options
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

## Custom Events

Example:

```lua
nm.set("zo", "*/snippets/*.lua", { -- "mapping", "pattern"
	regex = { [[--.*\w]] },
	events = { "BufEnter" }, -- events
})
```

</details>

## Feedback

If you run into issues or come up with an awesome idea, please feel free to open an issue or PR.
