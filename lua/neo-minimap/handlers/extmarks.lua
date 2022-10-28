local M = {}

---@param lines minimap_line_object[]
M.max_digits = function(lines)
	local max = 1
	for _, line in ipairs(lines) do
		local current_digit = #tostring(line.lnum)
		if current_digit > max then
			max = current_digit
		end
	end
	return max
end

local ns = vim.api.nvim_create_namespace("neo_minimap_floating")
---@param state minimap_state
---@param lines minimap_line_object[]
M.handle_extmarks = function(state, lines)
	for i, line in ipairs(lines) do
		local lnum_content = tostring(line.lnum)
		lnum_content = string.rep(" ", state.space_for_digits - #lnum_content) .. lnum_content

		vim.api.nvim_buf_set_extmark(state.minimapBuf, ns, i - 1, 0, {
			virt_text = { { lnum_content, "DiagnosticWarn" } },
			virt_text_pos = "overlay",
		})
	end

	state.namespace = ns
end

return M
