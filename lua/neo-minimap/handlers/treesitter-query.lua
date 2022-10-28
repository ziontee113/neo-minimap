local M = {}
local ts = vim.treesitter

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
	tex = "latex",
	OpenFOAM = "foam",
	pandoc = "markdown",
	rmd = "markdown",
	cs = "c_sharp",
}

---@class minimap_line_object
---@field lnum number
---@field lcol number
---@field text string

---@param query string
---@param lines minimap_line_object[]
---@param state minimap_state
M.handle_query = function(query, state, lines)
	local duplications_hashmap_check = {}

	-- parser handling
	local filetype = state.filetype
	local ok, parser = pcall(ts.get_parser, state.contentBuf, filetype)
	if not ok then
		local parser_name = filetype_to_parsername[filetype]
		parser = pcall(ts.get_parser, state.contentBuf, parser_name)
		filetype = parser_name
	end

	-- parse tree, get root
	local trees = parser:parse()
	local root = trees[1]:root()

	-- iter_query phase
	local iter_query_ok, iter_query = pcall(ts.query.parse_query, filetype, query or "")
	if iter_query_ok then
		for _, matches, _ in iter_query:iter_matches(root, state.contentBuf) do
			local row, col = matches[1]:range()

			if not duplications_hashmap_check[row] then
				local line_text = vim.api.nvim_buf_get_lines(state.contentBuf, row, row + 1, false)[1]
				table.insert(lines, {
					text = line_text,
					lnum = row,
					lcol = col,
				})
				duplications_hashmap_check[row] = true
			end
		end
	end
end

return M
