local constants = require("script.constants")
local storage_mod = require("script.storage")


local FRAME_NAME = "pnc-frame"
local STEP_DROPDOWN_NAME = "pnc-step-dropdown"
local LABEL_NAME = "pnc-label"
local SATISFACTION_DROPDOWN_NAME = "pnc-satisfaction-dropdown"
local RELATIVE_GUI = defines.relative_gui_type.constant_combinator_gui
local RELATIVE_POSITION = defines.relative_gui_position.right

--- Check whether an entity is one of our combinators.
---@param entity LuaEntity|nil
---@return boolean
local function is_our_combinator(entity)
	if not (entity and entity.valid) then return false end
	return entity.name == constants.COMBINATOR_NAME
end

--- Get the combinator entry if the event is for our combinator.
--- Returns the player and entry.
---@param event table
---@return LuaPlayer|nil, CombinatorEntry|nil
local function get_combinator_entry(event)
	if event.gui_type ~= defines.gui_type.entity then return end
	if not is_our_combinator(event.entity) then return end

	local player = game.get_player(event.player_index)
	if not player then return end

	local entry = storage_mod.get(event.entity.unit_number)
	if not entry then return end

	return player, entry
end

--- @type LocalisedString[]
local scale_selector_items = {}
for _, opt in ipairs(constants.multiplier_options) do
	table.insert(scale_selector_items, opt.label)
end

--- @type string[]
local satisfaction_selector_items = {}
for _, opt in ipairs(constants.satisfaction_options) do
	table.insert(satisfaction_selector_items, opt.label)
end

--- Find the dropdown index for a satisfaction scale, defaulting to the default option.
---@param value integer|nil
---@return integer
local function satisfaction_index(value)
	return value or constants.DEFAULT_SATISFACTION_SCALE_INDEX
end

--- Build the scale dropdown, anchored to the combinator GUI.
---@param player LuaPlayer
---@param entry CombinatorEntry
local function build_scale_frame(player, entry)
	local frame = player.gui.relative.add {
		type = "frame",
		name = FRAME_NAME,
		caption = { "pnc-locale.gui-unit-scale" },
		direction = "vertical",
		anchor = {
			gui = RELATIVE_GUI,
			position = RELATIVE_POSITION,
		},
	}
	local idx = entry.multiplier_index or constants.DEFAULT_MULTIPLIER_INDEX
	frame.add {
		type = "drop-down",
		name = STEP_DROPDOWN_NAME,
		items = scale_selector_items,
		selected_index = idx
	}
	frame.add {
		type = "label",
		caption = constants.multiplier_options[idx].range_label,
		name = LABEL_NAME,
		style = "bold_label"
	}
	frame.add {
		type = "line"
	}
	frame.add {
		type = "label",
		caption = { "pnc-locale.gui-satisfaction-output-maximum" },
	}
	frame.add {
		type = "drop-down",
		name = SATISFACTION_DROPDOWN_NAME,
		items = satisfaction_selector_items,
		selected_index = satisfaction_index(entry.satisfaction_index),
	}
end

--- Remove the scale dropdown frame if present.
---@param player LuaPlayer
local function destroy_scale_frame(player)
	local frame = player.gui.relative[FRAME_NAME]
	if frame then frame.destroy() end
end

local function on_gui_opened(event)
	local player, entry = get_combinator_entry(event)
	if player and entry then
		build_scale_frame(player, entry)
	end
end

local function on_gui_closed(event)
	if event.gui_type ~= defines.gui_type.entity then return end
	local player = game.get_player(event.player_index)
	if player then
		destroy_scale_frame(player)
	end
end

--- Handle a selection change in either of our dropdowns, persisting the chosen
--- value and updating the range label for the step dropdown.
local function on_gui_selection_changed(event)
	local element = event.element
	if not (element and element.valid) then return end
	local is_step = element.name == STEP_DROPDOWN_NAME
	local is_satisfaction = element.name == SATISFACTION_DROPDOWN_NAME
	if not (is_step or is_satisfaction) then return end

	local player = game.get_player(event.player_index)
	if not player then return end

	local entity = player.opened
	---@cast entity LuaEntity
	if not is_our_combinator(entity) then return end

	local entry = storage_mod.get(entity.unit_number)
	if not entry then return end
	local selected_index = element.selected_index or 1
	if is_step then
		entry.multiplier_index = selected_index

		-- Update the range label
		local label = player.gui.relative[FRAME_NAME]
		if label then
			label = label[LABEL_NAME]
			if label then
				label.caption = constants.multiplier_options[selected_index].range_label
			end
		end
	else
		entry.satisfaction_index = selected_index
	end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_changed)
