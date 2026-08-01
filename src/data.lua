local combinator_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
local combinator_item = table.deepcopy(data.raw["item"]["constant-combinator"])
local combinator_recipe = table.deepcopy(data.raw["recipe"]["constant-combinator"])
combinator_entity.name = "power-network-combinator"
combinator_entity.minable.result = "power-network-combinator"



combinator_item.name = "power-network-combinator"
combinator_item.place_result = "power-network-combinator"
combinator_recipe.name = "power-network-combinator"
combinator_recipe.enabled = true
combinator_recipe.results = {
	{ type = "item", name = "power-network-combinator", amount = 1 }
}
data:extend({ combinator_entity, combinator_item, combinator_recipe })



data:extend({
	{
		type = "lamp",
		name = "power-network-combinator-sensor",
		icon = combinator_entity.icon,
		icon_size = 64,
		flags = {"placeable-neutral", "player-creation", "placeable-off-grid"},
		minable = {mining_time = 0.1, result = nil },
		max_health = 50,
		corpse = "small-remnants",
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
		},
		energy_usage_per_tick = "100W",
		light = {
			intensity = 0.2,
			size = 2,
		},
		always_on = true,
		picture_off = {
			filename = "__base__/graphics/entity/small-lamp/lamp.png",
			priority = "high",
			width = 83,
			height = 70,
			shift = {0.125, 0.1875},
			scale = 0.5,
		},
		picture_on = {
			filename = "__base__/graphics/entity/small-lamp/lamp-light.png",
			priority = "high",
			width = 90,
			height = 78,
			shift = {0, -0.4375},
			scale = 0.5,
		},
		circuit_wire_max_distance = 0,
		draw_copper_wires = false,
		draw_circuit_wires = false,
	}
})
