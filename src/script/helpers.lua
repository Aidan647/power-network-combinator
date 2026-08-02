local helpers = {}

function helpers.log(tbl, indent)
	local freturn = 1
	if not indent then 
		indent = 0 
		freturn = 0
	end
	local toprint = "\n" .. string.rep("	", indent) .. "{\n"
	indent = indent + 1 
	if type(tbl) == "table" then
		for k, v in pairs(tbl) do
			toprint = toprint .. string.rep("	", indent)
			if (type(k) == "number") then
				toprint = toprint .. "[" .. k .. "] = "
			elseif (type(k) == "string") then
				toprint = toprint	.. k ..	" = "
			end
			if (type(v) == "number") then
				toprint = toprint .. v .. ",\n"
			elseif (type(v) == "string") then
				toprint = toprint .. "\"" .. v .. "\",\n"
			elseif (type(v) == "table") then
				toprint = toprint .. helpers.log(v, indent + 1) .. ",\n"
			elseif (type(v) == "userdata") then
				toprint = toprint .. "[userdata: " .. tostring(v) .. "],\n"
			else
				toprint = toprint .. "" .. tostring(v) .. ",\n"
			end
		end
		toprint = toprint .. string.rep("	", indent - 1) .. "}"
		if freturn == 0 then
			log(toprint)
		else
			return toprint
		end
	else
		if freturn == 0 then
			log(type(tbl) .. ": " .. tostring(tbl))
		else
			return tbl
		end
	end
end


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

    -- entity.operable = false

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

---@param flow table|nil Raw flow_last_tick table
---@return table|nil Display values or nil
function helpers.convert_flow(flow)
	if not flow then return nil end
	return {
		maximum_production       = flow.maximum_production * 60,
		maximum_consumption      = flow.maximum_consumption * 60,
		production_satisfaction  = flow.production_satisfaction * 1000,
		accumulator_energy       = flow.accumulator_energy,
		accumulator_capacity     = flow.accumulator_capacity,
		total_transfer           = flow.total_transfer * 60,
		solar_output             = flow.solar_output * 60,
		consumption_satisfaction = flow.consumption_satisfaction * 1000,
	}
end

function helpers.on_mined(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end

	local entry = storage.combinators[entity.unit_number]
	if not entry then return end

	helpers.destroy_pair(entry)
end

return helpers