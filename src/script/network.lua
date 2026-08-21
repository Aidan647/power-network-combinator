local constants = require("script.constants")
local storage_mod = require("script.storage")
local pairs_mod = require("script.pairs")
local util = require("script.util")


---@class FlowLastTick
---@field maximum_production number
---@field maximum_consumption number
---@field production_satisfaction number
---@field accumulator_energy number
---@field accumulator_capacity number
---@field total_transfer number
---@field solar_output number
---@field consumption_satisfaction number

---
---@param filter LogisticFilter
---@param flow LuaElectricNetwork.flow_last_tick | nil
---@param multiplier_index integer
---@param satisfaction_scale integer
---@return LogisticFilter | nil
local function set_filter(filter, flow, multiplier_index, satisfaction_scale)
	if not filter.value then return end
	if filter.value.type ~= "virtual" or filter.value.quality ~= "normal" then return end
	local name = filter.value.name
	local mapping = constants.find_on_signal(name)
	if not mapping then return end
	if flow == nil then
		filter.min = 0
		return filter
	end
	local value = flow[mapping[2]]
	local kind = mapping[3]
	if kind == "percentage" then
		-- fraction (0-1) scaled by the satisfaction scale
		value = math.floor(value * satisfaction_scale)
	elseif kind == "usage" then
		-- power/energy rate: per-tick value scaled to per-second and divided by the unit multiplier
		local multiplier = constants.multiplier_options[multiplier_index].multiplier
		value = math.floor(value * 60 / multiplier)
	else
		-- capacity: absolute value divided by the unit multiplier
		local multiplier = constants.multiplier_options[multiplier_index].multiplier
		value = math.floor(value / multiplier)
	end
	-- If the filter's min is already equal to the value, we don't need to update it.
	if value == filter.min then
		return
	end
	value = math.max(value, 0)
	value = math.min(value, 2 ^ 31 - 1)
	filter.min = value
	return filter
end


--- Write converted values into the combinator's circuit slots.
---@param entry CombinatorEntry
---@param flow LuaElectricNetwork.flow_last_tick | nil
---@param multiplier_index integer | nil
---@param satisfaction_index integer | nil
local function set_values(entry, flow, multiplier_index, satisfaction_index)
	if not flow then
		if not entry.powered then
			return
		end
		entry.powered = false
	elseif not entry.powered then
		entry.powered = true
	end

	-- Cache the control behavior on the entry to avoid a Lua API lookup every tick.
	local control = entry.control
	if not (control and control.valid) then
		local created = entry.combinator.get_or_create_control_behavior()
		---@cast created LuaConstantCombinatorControlBehavior|nil
		if not created or created.object_name ~= "LuaConstantCombinatorControlBehavior" then
			entry.control = nil
			return
		end
		control = created
		entry.control = control
	end
	multiplier_index = multiplier_index or constants.DEFAULT_MULTIPLIER_INDEX
	satisfaction_index = satisfaction_index or constants.DEFAULT_SATISFACTION_SCALE_INDEX
	local satisfaction_scale = constants.satisfaction_options[satisfaction_index].value

	for _, section in ipairs(control.sections) do
		if section.group == "" and section.is_manual == true then
			for i, filter in pairs(section.filters) do
				local f = set_filter(filter, flow, multiplier_index, satisfaction_scale)
				if f then
					section.set_slot(i, f)
				end
			end
		end
	end
end

--- Update up to `updates_per_tick` pairs with the latest electric network data.
local function on_tick(event)
	storage_mod.each(storage_mod.get_updates_per_tick(), function(entry)
		local combinator = entry.combinator
		local sensor = entry.sensor

		if not (combinator and combinator.valid and sensor and sensor.valid) then
			pairs_mod.destroy(entry)
		elseif sensor.is_connected_to_electric_network() then
			local electric_network = sensor.electric_network
			local parent_network = electric_network and electric_network.parent_network
			set_values(entry, parent_network and parent_network.flow_last_tick, entry.multiplier_index, entry.satisfaction_index)
		else
			set_values(entry, nil, entry.multiplier_index, entry.satisfaction_index)
		end
	end)
end

script.on_event(defines.events.on_tick, on_tick)
