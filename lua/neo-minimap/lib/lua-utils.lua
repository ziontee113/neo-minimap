local M = {}

---returns `index` of *value* in *tbl*
---@param tbl table
---@param value any
---@return integer|nil
M.tbl_index_of = function(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
end

---@class increment_index_opts
---@field table table
---@field index number
---@field increment number
---@field fallback number
---@field decrement_fallback boolean

---if *index + increment <= #tbl*, returns `index + increment`
---otherwise returns `fallback`
---@param opts increment_index_opts
M.increment_index = function(opts)
	local increment_result = opts.index + opts.increment
	if (increment_result <= #opts.table) and (increment_result > 0) then
		return opts.index + opts.increment
	else
		if opts.decrement_fallback and opts.increment < 0 then
			return #opts.table
		end
		return opts.fallback
	end
end

return M
