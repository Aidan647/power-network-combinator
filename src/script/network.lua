local constants = require("script.constants")
local util = require("script.util")
local storage_mod = require("script.storage")
local pairs_mod = require("script.pairs")

local network = {}

---@class FlowLastTick
---@field maximum_production number
---@field maximum_consumption number
---@field production_satisfaction number
---@field accumulator_energy number
---@field accumulator_capacity number
---@field total_transfer number
---@field solar_output number
---@field consumption_satisfaction number

---@class DisplayValues
---@field maximum_production integer
---@field maximum_consumption integer
---@field production_satisfaction integer
---@field accumulator_energy integer
---@field accumulator_capacity integer
---@field total_transfer integer
---@field solar_output integer
---@field consumption_satisfaction integer

--- Convert raw electric network flow data into display-ready values.
---@param flow table|nil Raw flow_last_tick table
---@param multiplier_index integer|nil 0-based index into constants.multiplier_options
---@return DisplayValues|nil
function network.convert_flow(flow, multiplier_index)
	if not flow then return nil end
	multiplier_index = multiplier_index or constants.DEFAULT_MULTIPLIER_INDEX
	local multiplier = constants.multiplier_options[multiplier_index].multiplier

	local function to_power(raw)
		return math.floor(raw / multiplier * 60)
	end

	return {
		maximum_production       = to_power(flow.maximum_production),
		maximum_consumption      = to_power(flow.maximum_consumption),
		production_satisfaction  = math.floor(flow.production_satisfaction * 1000),
		accumulator_energy       = math.floor(flow.accumulator_energy / multiplier),
		accumulator_capacity     = math.floor(flow.accumulator_capacity / multiplier),
		total_transfer           = to_power(flow.total_transfer),
		solar_output             = to_power(flow.solar_output),
		consumption_satisfaction = math.floor(flow.consumption_satisfaction * 1000),
	}
end

---
---@param filter LogisticFilter
---@param flow LuaElectricNetwork.flow_last_tick | nil
---@param multiplier_index integer
---@return LogisticFilter|nil
local function set_filter(filter, flow, multiplier_index)
	if filter.value.type ~= "virtual" and filter.value.quality ~= "normal" then return end
	local name = filter.value.name
	local mapping = constants.find_on_signal(name)
	if not mapping then return end
	if flow == nil then
		filter.min = 0
		return
	end
	local value = flow[mapping[2]]
	log("PNC: setting filter for " .. name .. " to " .. value .. "multiplier_index: " .. multiplier_index)
	if mapping[3] then
		value = value * 1000
	else
		local multiplier = constants.multiplier_options[multiplier_index].multiplier
		value = math.floor(value * 60 / multiplier)
	end
	value = math.max(value, 0)
	value = math.min(value, 2 ^ 31 - 1)
	filter.min = value
	return filter
end


--- Write converted values into the combinator's circuit slots.
---@param combinator LuaEntity
---@param flow LuaElectricNetwork.flow_last_tick | nil
---@param multiplier_index integer | nil
local function set_values(combinator, flow, multiplier_index)
	local control = combinator.get_or_create_control_behavior()
	---@cast control LuaConstantCombinatorControlBehavior|nil
	if not control or control.object_name ~= "LuaConstantCombinatorControlBehavior" then return end
	multiplier_index = multiplier_index or constants.DEFAULT_MULTIPLIER_INDEX

	for _, section in ipairs(control.sections) do
		if section.group == "" and section.is_manual == true then
			for i, filter in pairs(section.filters) do
				local f = set_filter(filter, flow, multiplier_index)
				if f then
					section.set_slot(i, f)
				end
			end
		end
	end
end

--- Update every pair with the latest electric network data.
local function on_tick()
	local seen = {}
	for _, entry in pairs(storage_mod.all()) do
		-- Each pair is stored under both entity unit numbers; process once.
		if not seen[entry] then
			seen[entry] = true

			local combinator = entry.combinator
			local sensor = entry.sensor

			if not (combinator and combinator.valid and sensor and sensor.valid) then
				util.log("PNC: invalid pair, destroying")
				pairs_mod.destroy(entry)
			elseif sensor.is_connected_to_electric_network() then
				local flow = sensor.electric_network.parent_network.flow_last_tick
				set_values(combinator, flow, entry.multiplier_index)
			else
				set_values(combinator, nil, entry.multiplier_index)
			end
		end
	end
end

script.on_nth_tick(6, on_tick)

return network
