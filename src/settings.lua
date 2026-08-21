data:extend({
	{
		type = "int-setting",
		name = "pnc-updates-per-tick",
		setting_type = "runtime-global",
		default_value = 100,
		minimum_value = 1,
		maximum_value = 10000,
		order = "a",
	},
	{
		type = "bool-setting",
		name = "pnc-enable-from-start",
		setting_type = "startup",
		default_value = false,
		order = "b",
	}
})
