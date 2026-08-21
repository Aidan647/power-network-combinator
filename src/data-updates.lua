

local from_start = settings.startup["pnc-enable-from-start"].value
---@cast from_start boolean
if not from_start then
	local recipe_name = "power-network-combinator"

	-- Returns true if the given technology has an unlock-recipe effect for the recipe.
	local function has_unlock_recipe(tech, recipe)
		if not tech or not tech.effects then
			return false
		end
		for _, effect in pairs(tech.effects) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe then
				return true
			end
		end
		return false
	end

	local target_tech = nil

	-- 1. Prefer circuit-network if it unlocks decider-combinator.
	if has_unlock_recipe(data.raw.technology["circuit-network"], "decider-combinator") then
		target_tech = data.raw.technology["circuit-network"]
	else
		-- 2. Otherwise find any technology that unlocks decider-combinator.
		for _, tech in pairs(data.raw.technology) do
			if has_unlock_recipe(tech, "decider-combinator") then
				target_tech = tech
				break
			end
		end
		-- 3. Fallback to circuit-network if it exists.
		if not target_tech and data.raw.technology["circuit-network"] then
			target_tech = data.raw.technology["circuit-network"]
		end
	end

	if target_tech then
		if not target_tech.effects then
			target_tech.effects = {}
		end
		table.insert(target_tech.effects, { type = "unlock-recipe", recipe = recipe_name })
	else
		-- 4. Last resort: enable the recipe directly and log an error.
		local recipe = data.raw.recipe[recipe_name]
		if recipe then
			recipe.enabled = true
		end
		log("power-network-combinator: could not find a technology to unlock the recipe; enabled it directly")
	end
end