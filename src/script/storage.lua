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
---@field _removed boolean|nil True once removed, pending compaction of update_list

---@type integer
local updates_per_tick = constants.DEFAULT_UPDATES_PER_TICK

---@diagnostic disable-next-line: unknown-cast-variable
---@cast __power_network_combinator__storage.combinators table<uint, CombinatorEntry|nil>
---@diagnostic disable-next-line: unknown-cast-variable
---@cast __power_network_combinator__storage.sensor_index table<uint, CombinatorEntry|nil>


---@type integer
local cursor = 0

local function rebuild_update_list()
	storage.update_list = {}
	local i = 0
	for _, entry in pairs(storage.combinators) do
		i = i + 1
		storage.update_list[i] = entry
	end
	if cursor >= i then
		cursor = 0
	end
end

local function compact_update_list()
	if not storage._needs_compact then return end
	rebuild_update_list()
	storage._needs_compact = false
end

local tables_created = false
local function ensure_tables()
	if tables_created then return end
	storage.combinators = storage.combinators or {}
	storage.sensor_index = storage.sensor_index or {}
	storage.update_list = storage.update_list or {}
	tables_created = true
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
	ensure_tables()
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
	storage.combinators[entry.combinator_unit or entry.combinator.unit_number] = nil
	storage.sensor_index[entry.sensor_unit or entry.sensor.unit_number] = nil
	entry._removed = true
	storage._needs_compact = true
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
	local scanned = 0
	while taken < count and scanned < n do
		cursor = cursor + 1
		if cursor > n then cursor = 1 end
		scanned = scanned + 1
		local entry = storage.update_list[cursor]
		if entry and not entry._removed then
			local ok, err = pcall(fn, entry)
			if ok then
				taken = taken + 1
			else
				log("PNC: error updating entry, removing it: " .. tostring(err))
				storage_mod.remove(entry)
			end
		end
	end
	compact_update_list()
end

script.on_init(storage_mod.init)
script.on_configuration_changed(storage_mod.init)
script.on_load(storage_mod.on_load)

return storage_mod
