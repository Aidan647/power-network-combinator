local constants = require("script.constants")

local storage_mod = {}

---@class CombinatorEntry
---@field combinator LuaEntity The visible combinator entity
---@field sensor LuaEntity The hidden sensor entity
---@field combinator_unit uint Unit number of the combinator
---@field sensor_unit uint Unit number of the sensor
---@field multiplier_index integer index into constants.multiplier_options
---@field satisfaction_index integer index into constants.satisfaction_options
---@field powered boolean
---@field control LuaConstantCombinatorControlBehavior|nil Cached control behavior

---@type integer
local updates_per_tick = constants.DEFAULT_UPDATES_PER_TICK

---@type integer
local cursor = 0

local function rebuild_update_list()
	storage.update_list = {}
	for _, entry in pairs(storage.combinators) do
		storage.update_list[#storage.update_list + 1] = entry
	end
	cursor = 0
end

local function ensure_tables()
	storage.combinators = storage.combinators or {}
	storage.sensor_index = storage.sensor_index or {}
end

---@param value integer
function storage_mod.set_updates_per_tick(value)
	updates_per_tick = math.max(1, math.floor(value))
	storage.updates_per_tick = updates_per_tick
end

---@return integer
function storage_mod.get_updates_per_tick()
	return updates_per_tick
end

function storage_mod.init()
	storage.combinators = storage.combinators or {}
	storage.sensor_index = storage.sensor_index or {}
	rebuild_update_list()
end

function storage_mod.on_load()
	if storage.updates_per_tick then
		updates_per_tick = math.max(1, math.floor(storage.updates_per_tick))
	end
end

---@param unit_number uint
---@return CombinatorEntry|nil
function storage_mod.get(unit_number)
	ensure_tables()
	return storage.combinators[unit_number] or storage.sensor_index[unit_number]
end

---@param entry CombinatorEntry
function storage_mod.add(entry)
	ensure_tables()
	storage.combinators[entry.combinator_unit] = entry
	storage.sensor_index[entry.sensor_unit] = entry
	storage.update_list[#storage.update_list + 1] = entry
end

--- Unregister a pair.
---@param entry CombinatorEntry
function storage_mod.remove(entry)
	if not entry then return end
	ensure_tables()
	local unit = entry.combinator_unit or entry.combinator.unit_number
	for i, list_entry in ipairs(storage.update_list) do
		if list_entry == entry then
			table.remove(storage.update_list, i)
			break
		end
	end
	storage.combinators[unit] = nil
	storage.sensor_index[entry.sensor_unit or entry.sensor.unit_number] = nil
end

---@param count integer
---@param fn fun(entry: CombinatorEntry)
function storage_mod.each(count, fn)
	ensure_tables()
	if not storage.update_list then
		rebuild_update_list()
	end
	local n = #storage.update_list
	if n == 0 then return end

	local taken = 0
	while taken < count do
		cursor = cursor + 1
		if cursor > n then cursor = 1 end
		fn(storage.update_list[cursor])
		taken = taken + 1
		if taken >= n then break end
	end
end

script.on_init(storage_mod.init)
script.on_configuration_changed(storage_mod.init)
script.on_load(storage_mod.on_load)

return storage_mod
