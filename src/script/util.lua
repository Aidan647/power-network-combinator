local util = {}

--- Print a human-readable representation of a value to the log.
---@param value any
function util.log(value)
	local function serialize(v, indent)
		local pad = string.rep("\t", indent)
		if type(v) ~= "table" then
			return pad .. type(v) .. ": " .. tostring(v)
		end

		local lines = { pad .. "{" }
		for k, child in pairs(v) do
			local key = type(k) == "number" and ("[" .. k .. "]") or tostring(k)
			local child_str
			if type(child) == "table" then
				child_str = serialize(child, indent + 1)
			elseif type(child) == "string" then
				child_str = pad .. "\t" .. key .. " = \"" .. child .. "\""
			elseif type(child) == "userdata" then
				child_str = pad .. "\t" .. key .. " = [userdata: " .. tostring(child) .. "]"
			else
				child_str = pad .. "\t" .. key .. " = " .. tostring(child)
			end
			lines[#lines + 1] = child_str
		end
		lines[#lines + 1] = pad .. "}"
		return table.concat(lines, "\n")
	end
	log("\n" .. serialize(value, 0))
end

return util
