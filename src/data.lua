require("__base__.prototypes.entity.combinator-pictures")
local sounds = require("__base__.prototypes.entity.sounds")
local hit_effects = require("__base__.prototypes.entity.hit-effects")
local item_sounds = require("__base__.prototypes.item_sounds")

local icon = "__power-network-combinator__/graphics/icon.png"
local from_start = settings.startup["pnc-enable-from-start"].value
---@cast from_start boolean

local combinator = generate_constant_combinator({
	type = "constant-combinator",
	name = "power-network-combinator",
	icon = icon,
	flags = { "placeable-neutral", "player-creation" },
	minable = { mining_time = 0.1, result = "power-network-combinator" },
	max_health = 150,
	corpse = "constant-combinator-remnants",
	dying_explosion = "constant-combinator-explosion",
	collision_box = { { -0.35, -0.35 }, { 0.35, 0.35 } },
	selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
	damaged_trigger_effect = hit_effects.entity(),
	open_sound = sounds.combinator_open,
	close_sound = sounds.combinator_close,
	icon_draw_specification = { scale = 0.7 },
	activity_led_light =
	{
		intensity = 0,
		size = 1,
		color = { r = 1.0, g = 1.0, b = 1.0 }
	},

	activity_led_light_offsets =
	{
		{ 0.296875,  -0.40625 },
		{ 0.25,      -0.03125 },
		{ -0.296875, -0.078125 },
		{ -0.21875,  -0.46875 }
	},

	circuit_wire_max_distance = combinator_circuit_wire_max_distance,
	water_reflection = chest_reflection()
})
combinator.sprites =
	make_4way_animation_from_spritesheet({
		layers =
		{
			{
				scale = 0.5,
				filename = "__power-network-combinator__/graphics/entity.png",
				width = 114,
				height = 102,
				shift = util.by_pixel(0, 5)
			},
			{
				scale = 0.5,
				filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
				width = 98,
				height = 66,
				shift = util.by_pixel(8.5, 5.5),
				draw_as_shadow = true
			}
		}
	})
data:extend({
	combinator,
	{
		type = "lamp",
		name = "power-network-combinator-sensor",
		icon = icon,
		flags = { "placeable-neutral", "player-creation", "placeable-off-grid" },
		selectable_in_game = false,
		minable = { mining_time = 0.1, result = nil },
		max_health = 50,
		localised_name = { "entity-name.power-network-combinator" },
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
		circuit_wire_max_distance = 0,
		draw_copper_wires = false,
		draw_circuit_wires = false,
		--no pictures = invisible
	},
	{
		type = "item",
		name = "power-network-combinator",
		icon = icon,
		subgroup = "circuit-network",
		place_result = "power-network-combinator",
		order = "c[combinators]-p[power-network-combinator]",
		inventory_move_sound = item_sounds.combinator_inventory_move,
		pick_sound = item_sounds.combinator_inventory_pickup,
		drop_sound = item_sounds.combinator_inventory_move,
		stack_size = 50
	},
	{
		type = "recipe",
		name = "power-network-combinator",
		enabled = from_start,
		ingredients =
		{
			{ type = "item", name = "copper-cable",       amount = 5 },
			{ type = "item", name = "electronic-circuit", amount = 5 }
		},
		results = { { type = "item", name = "power-network-combinator", amount = 1 } }
	},
})
