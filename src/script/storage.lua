local storage_mod = {}

---@class CombinatorEntry
---@field combinator LuaEntity The visible combinator entity
---@field sensor LuaEntity The hidden sensor entity
---@field combinator_unit uint Unit number of the combinator
---@field sensor_unit uint Unit number of the sensor
---@field multiplier_index integer index into constants.multiplier_options

--- Initialize persistent storage.
function storage_mod.init()
	--- @type table<uint, CombinatorEntry>
	storage.combinators = storage.combinators or {}
end

--- Get the entry registered under a unit number.
---@param unit_number uint
---@return CombinatorEntry|nil
function storage_mod.get(unit_number)
	return storage.combinators[unit_number]
end

--- Register a pair under both its entity unit numbers.
---@param entry CombinatorEntry
function storage_mod.add(entry)
	storage.combinators[entry.combinator_unit] = entry
	storage.combinators[entry.sensor_unit] = entry
end

--- Unregister a pair.
---@param entry CombinatorEntry
function storage_mod.remove(entry)
	if not entry then return end
	storage.combinators[entry.combinator_unit] = nil
	storage.combinators[entry.sensor_unit] = nil
end

--- Iterate all registered pairs.
---@return table<uint, CombinatorEntry>
function storage_mod.all()
	return storage.combinators
end

script.on_init(storage_mod.init)
script.on_configuration_changed(storage_mod.init)

return storage_mod
