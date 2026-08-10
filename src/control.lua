-- Entry point: each module self-registers its own events.
local storage_mod = require("script.storage")

local SETTING_NAME = "pnc-updates-per-tick"

--- Apply the updates-per-tick map setting.
local function apply_updates_per_tick()
	local value = settings.global[SETTING_NAME]
	if value then
		storage_mod.set_updates_per_tick(value.value)
	end
end

script.on_init(apply_updates_per_tick)
script.on_configuration_changed(apply_updates_per_tick)
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == SETTING_NAME then
		apply_updates_per_tick()
	end
end)

require("script.pairs")
require("script.network")
require("script.gui")
