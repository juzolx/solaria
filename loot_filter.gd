class_name LootFilter
extends Overlay
## Loot filter rules: which new drops get turned into scrap right away.
## Legendary, Unique, Set and Signature items are always kept.

var m
var state: GameState
var rarity_button: Button
var slot_buttons := {}
var weaker_button: Button
var gs_button: Button

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Loot filter", 560.0)
	var note := UI.label("Filtered drops turn into scrap as soon as they drop. Legendary and better items are always kept.", 13, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	content.add_child(UI.heading("By rarity"))
	rarity_button = UI.button("", func(): state.cycle_auto_salvage(); _update())
	content.add_child(rarity_button)
	content.add_child(UI.heading("Slots you don't want (Common to Rare drops)"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for s in GameData.SLOT_ORDER:
		var b := UI.button("", _toggle_slot.bind(s))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		slot_buttons[s] = b
	content.add_child(UI.heading("Smart rule"))
	weaker_button = UI.button("", func():
		state.loot_filter["weaker"] = not bool(state.loot_filter.get("weaker", false))
		state.save_game()
		_update())
	weaker_button.tooltip_text = "Common to Rare drops that are weaker than what you wear in that slot (and wouldn't make your build stronger) become scrap."
	content.add_child(weaker_button)
	gs_button = UI.button("", func():
		state.loot_filter["below_gs"] = not bool(state.loot_filter.get("below_gs", false))
		state.save_game()
		_update())
	gs_button.tooltip_text = "Common to Epic drops with a Gear Score below the average of what you wear become scrap."
	content.add_child(gs_button)
	_update()

func _toggle_slot(s: String) -> void:
	var slots: Dictionary = state.loot_filter.get("slots", {})
	slots[s] = not bool(slots.get(s, false))
	state.loot_filter["slots"] = slots
	state.save_game()
	_update()

func _update() -> void:
	var names := ["Off", "Commons", "Uncommon and below", "Rare and below", "Epic and below"]
	rarity_button.text = "Salvage new drops: %s" % names[state.auto_salvage + 1]
	var slots: Dictionary = state.loot_filter.get("slots", {})
	for s in slot_buttons:
		var on := bool(slots.get(s, false))
		var b: Button = slot_buttons[s]
		b.text = "%s: %s" % [s, "salvage" if on else "keep"]
		b.add_theme_color_override("font_color", UI.RED if on else UI.TEXT)
	weaker_button.text = "Salvage drops weaker than what I wear: %s" % ("ON" if state.loot_filter.get("weaker", false) else "OFF")
	gs_button.text = "Salvage drops below my Gear Score (%d): %s" % [state.average_gear_score(), "ON" if state.loot_filter.get("below_gs", false) else "OFF"]
	m.refresh()
