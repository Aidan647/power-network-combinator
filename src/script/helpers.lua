local helpers = {}


function helpers.init_storage()
    --- @alias CombinatorEntry {combinator: LuaEntity, sensor: LuaEntity}
    storage.combinators = storage.combinators or {}
end

---@param pair {combinator: LuaEntity, sensor: LuaEntity}
function helpers.destroy_pair(pair)
	if not pair then return end
	storage.combinators[pair.combinator.unit_number] = nil
	storage.combinators[pair.sensor.unit_number] = nil
	if pair.combinator and pair.combinator.valid then
		pair.combinator.destructible = true
		pair.combinator.destroy()
	end
	if pair.sensor and pair.sensor.valid then
		pair.sensor.destructible = true
		pair.sensor.destroy()
	end
end

function helpers.create_pair(entity)
	if entity.name ~= "power-network-combinator" then return end

	local sensor = entity.surface.create_entity{
		name = "power-network-combinator-sensor",
		position = entity.position,
		force = entity.force,
		quality = entity.quality,
		create_build_effect_smoke = false,
		raise_built = false,
	}
	if not sensor then
		log("PNC: failed to create sensor")
		return
	end

	sensor.destructible = false
	sensor.minable_flag = false
	sensor.operable = false

	local entry = {
		combinator = entity,
		sensor = sensor,
	}
	storage.combinators[entity.unit_number] = entry
	storage.combinators[sensor.unit_number] = entry

	log("PNC: placed")
end

function helpers.on_mined(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end

	local entry = storage.combinators[entity.unit_number]
	if not entry then return end

	helpers.destroy_pair(entry)
end

return helpers