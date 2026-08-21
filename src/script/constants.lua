local constants = {}

---@class MultiplierOption
---@field multiplier number Divisor applied to power/energy values
---@field label LocalisedString Display label
---@field range_label LocalisedString Max representable value (e.g. "2.1 GW")

---@alias SignalKind "usage" | "percentage" | "capacity"

---@class SignalMapping
---@field [1] string Circuit signal name
---@field [2] string flow_last_tick field name
---@field [3] SignalKind How the raw flow value is converted:
---  "usage"     - power/energy rate, multiplied by 60 and divided by the unit multiplier
---  "percentage" - fraction (0-1), multiplied by the satisfaction scale
---  "capacity"  - absolute value, used as-is

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
---@type {value: integer, label: LocalisedString}[]
constants.satisfaction_options = {
	{ value = 100, label = "100 (%)" },
	{ value = 1000, label = "1000 (‰)" },
	-- The language server misresolves the nested LocalisedString here.
	---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
	{ value = 1e6, label = { "", "1", { "si-prefix-symbol-mega" } } },
}

constants.prefixes = { "", "kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta", "quetta" }


---@param index integer
---@return LocalisedString
local function unit_label(index)
	local prefix = constants.prefixes[index] or ""
	local p = prefix ~= "" and { "si-prefix-symbol-" .. prefix } or ""
	return { "", p, { "si-unit-symbol-watt" }, " / ", p, { "si-unit-symbol-joule" } }
end


local function entry(index)
	return {
		multiplier = (1000 ^ (index - 1)),
		label = unit_label(index),
		range_label = { "", { "pnc-locale.up-to-2-1" }, " ", unit_label(index + 3) }
	}
end
-- Unit scales: divisor applied to power/energy output values.
---@type MultiplierOption[]
constants.multiplier_options = {}
for i = 1, 7 do
	constants.multiplier_options[i] = entry(i)
end
-- Circuit signal mapping: slot index -> { signal name, flow field }
---@type SignalMapping[]
constants.signal_map = {
	{ "signal-P", "maximum_production", "usage" },
	{ "signal-C", "maximum_consumption", "usage" },
	{ "signal-S", "production_satisfaction", "percentage" },
	{ "signal-A", "accumulator_energy", "capacity" },
	{ "signal-B", "accumulator_capacity", "capacity" },
	{ "signal-T", "total_transfer", "usage" },
	{ "signal-D", "solar_output", "usage" },
	{ "signal-U", "consumption_satisfaction", "percentage" },
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
	"[virtual-signal=signal-S]: Production satisfaction",
	"[virtual-signal=signal-A]: Accumulator energy",
	"[virtual-signal=signal-B]: Accumulator capacity",
	"[virtual-signal=signal-T]: Total transfer",
	"[virtual-signal=signal-D]: Solar output",
	"[virtual-signal=signal-U]: Consumption satisfaction",
}, "\n")

return constants
