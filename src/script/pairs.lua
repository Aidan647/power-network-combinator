local constants = require("script.constants")
local util = require("script.util")
local storage_mod = require("script.storage")

local pairs_mod = {}

--- Create a hidden sensor next to a placed combinator and register the pair.
---@param entity LuaEntity
function pairs_mod.create(entity)
	if entity.name ~= constants.COMBINATOR_NAME then return end

	local sensor = entity.surface.create_entity {
		name = constants.SENSOR_NAME,
		position = entity.position,
		force = entity.force,
		quality = entity.quality,
		create_build_effect_smoke = false,
		raise_built = false,
	}
	if not sensor then
		util.log("PNC: failed to create sensor")
		return
	end

	sensor.destructible = false
	sensor.minable_flag = false
	sensor.operable = false
	entity.combinator_description = constants.combinator_description

	local entry = {
		combinator = entity,
		sensor = sensor,
		combinator_unit = entity.unit_number,
		sensor_unit = sensor.unit_number,
		multiplier_index = constants.DEFAULT_MULTIPLIER_INDEX,
	}
	storage_mod.add(entry)

	util.log("PNC: placed")
end

--- Remove a pair from storage and destroy both entities.
---@param entry CombinatorEntry
function pairs_mod.destroy(entry)
	if not entry then return end

	storage_mod.remove(entry)

	for _, entity in ipairs({ entry.combinator, entry.sensor }) do
		if entity and entity.valid then
			entity.destructible = true
			entity.destroy()
		end
	end
end

---@param event table
local function on_built(event)
	local entity = event.entity or event.created_entity
	if entity and entity.valid then
		pairs_mod.create(entity)
	end
end

---@param event table
local function on_mined(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end

	local entry = storage_mod.get(entity.unit_number)
	if entry then
		pairs_mod.destroy(entry)
	end
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.script_raised_revive, on_built)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)

return pairs_mod
