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

local function on_tick()
    for unit_number, entry in pairs(storage.combinators) do
        local combinator = entry.combinator
        local sensor = entry.sensor
        if not (combinator and combinator.valid and sensor and sensor.valid) then
            log("PNC: invalid pair, destroying")
            helpers.destroy_pair(entry)
        end
		if sensor.is_connected_to_electric_network() then
			local network = sensor.electric_network
			log(network)
		else
			log("PNC: sensor not connected to electric network")
		end
    end
end

script.on_nth_tick(10, on_tick)
