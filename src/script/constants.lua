local constants = {}

---@class MultiplierOption
---@field multiplier number Divisor applied to power/energy values
---@field label LocalisedString Display label
---@field range_label LocalisedString Max representable value (e.g. "2.1 GW")

---@class SignalMapping
---@field [1] string Circuit signal name
---@field [2] string flow_last_tick field name
---@field [3] boolean|nil is percentage boolean (optional) Whether the value is a percentage (0-1) and should be scaled to 0-1000

-- Entity names
constants.COMBINATOR_NAME = "power-network-combinator"
constants.SENSOR_NAME = "power-network-combinator-sensor"

-- Default unit scale index into multiplier_options (kW / kJ)
constants.DEFAULT_MULTIPLIER_INDEX = 2

-- Default satisfaction scale (0-1 fraction multiplied by this to get the output signal)
constants.DEFAULT_SATISFACTION_SCALE_INDEX = 1

-- Default number of combinators updated per tick.
constants.DEFAULT_UPDATES_PER_TICK = 100


-- Preset satisfaction scales shown in the dropdown.
---@type {value: integer, label: any}[]
constants.satisfaction_options = {
	{ value = 100, label = "100 (%)" },
	{ value = 1000, label = "1000 (‰)" },
	{ value = 1e6, label = { "", "1", { "si-prefix-symbol-mega" } } },
}

-- Compose a unit label from base-game SI prefix + unit symbols.
-- e.g. prefix "kilo" + watt/joule -> "kW / kJ"
---@param prefix string Base-game si-prefix-symbol-* key suffix ("" for none)
---@return LocalisedString
local function unit_label(prefix)
	local p = prefix ~= "" and { "si-prefix-symbol-" .. prefix } or ""
	return { "", p, { "si-unit-symbol-watt" }, " / ", p, { "si-unit-symbol-joule" } }
end

-- Compose a range label showing the max representable value: "2.1 GW", "2.1 TW", etc.
---@param prefix string Current scale prefix ("" for W)
---@return LocalisedString
local function make_range_label(prefix)
	return { "", "Up to 2.1 ", unit_label(prefix) }
end

-- Unit scales: divisor applied to power/energy output values.
---@type MultiplierOption[]
constants.multiplier_options = {
	{ multiplier = 1e0,  label = unit_label(""),     range_label = make_range_label("giga") },
	{ multiplier = 1e3,  label = unit_label("kilo"), range_label = make_range_label("tera") },
	{ multiplier = 1e6,  label = unit_label("mega"), range_label = make_range_label("peta") },
	{ multiplier = 1e9,  label = unit_label("giga"), range_label = make_range_label("exa") },
	{ multiplier = 1e12, label = unit_label("tera"), range_label = make_range_label("zetta") },
	{ multiplier = 1e15, label = unit_label("peta"), range_label = make_range_label("yotta") },
	{ multiplier = 1e18, label = unit_label("exa"),  range_label = make_range_label("quetta") },
}

-- Circuit signal mapping: slot index -> { signal name, flow field }
---@type SignalMapping[]
constants.signal_map = {
	{ "signal-P", "maximum_production" },
	{ "signal-C", "maximum_consumption" },
	{ "signal-S", "production_satisfaction",  true },
	{ "signal-A", "accumulator_energy" },
	{ "signal-B", "accumulator_capacity" },
	{ "signal-T", "total_transfer" },
	{ "signal-D", "solar_output" },
	{ "signal-U", "consumption_satisfaction", true },
}
local cache = {}

---@param signal string
---@return SignalMapping|nil
constants.find_on_signal = function(signal)
	if cache[signal] then return cache[signal] end
	for _, mapping in ipairs(constants.signal_map) do
		if mapping[1] == signal then
			cache[signal] = mapping
			return mapping
		end
	end
end

-- Short description shown in the combinator tooltip, one line per signal.
constants.combinator_description = table.concat({
	"[virtual-signal=signal-P]: Maximum production",
	"[virtual-signal=signal-C]: Maximum consumption",
	"[virtual-signal=signal-S]: Production satisfaction (0-1000)",
	"[virtual-signal=signal-A]: Accumulator energy",
	"[virtual-signal=signal-B]: Accumulator capacity",
	"[virtual-signal=signal-T]: Total transfer",
	"[virtual-signal=signal-D]: Solar output",
	"[virtual-signal=signal-U]: Consumption satisfaction (0-1000)",
}, "\n")

return constants
