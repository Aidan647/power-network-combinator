local helpers = require("script.helpers")

script.on_init(helpers.init_storage)
script.on_configuration_changed(helpers.init_storage)

local function on_built(event)
	local entity = event.entity or event.created_entity
	if entity and entity.valid then
		helpers.create_pair(entity)
	end
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.script_raised_revive, on_built)

script.on_event(defines.events.on_player_mined_entity, helpers.on_mined)
script.on_event(defines.events.on_robot_mined_entity, helpers.on_mined)
script.on_event(defines.events.on_entity_died, helpers.on_mined)
local signal_map = {
	{ "signal-P", "maximum_production" },
	{ "signal-C", "maximum_consumption" },
	{ "signal-S", "production_satisfaction" },
	{ "signal-A", "accumulator_energy" },
	{ "signal-B", "accumulator_capacity" },
	{ "signal-T", "total_transfer" },
	{ "signal-D", "solar_output" },
	{ "signal-U", "consumption_satisfaction" },
}
local function set_values(combinator, values)
	local control = combinator.get_or_create_control_behavior()
	if not control then return 1 end

	local section = control.get_section(1)
	if not section then section = control.add_section() end
	if not section then return 2 end
	control.enabled = true

	for i, mapping in ipairs(signal_map) do
		local signal_name = mapping[1]
		local field = mapping[2]
		local min_val = 0
		if values and values[field] then
			min_val = values[field]
		end
		section.set_slot(i, { value = { type = "virtual", name = signal_name, quality = "normal" }, min = min_val })
	end
end

local function on_tick()
	for unit_number, entry in pairs(storage.combinators) do
		local combinator = entry.combinator
		local sensor = entry.sensor
		if not (combinator and combinator.valid and sensor and sensor.valid) then
			log("PNC: invalid pair, destroying")
			helpers.destroy_pair(entry)
		elseif sensor.is_connected_to_electric_network() then
			local flow = sensor.electric_network.parent_network.flow_last_tick
			set_values(combinator, helpers.convert_flow(flow))
		else
			set_values(combinator, nil)
		end
	end
end

script.on_nth_tick(10, on_tick)
