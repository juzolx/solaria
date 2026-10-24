class_name LootFilter
extends Overlay
## 2.1: the one Loot filter screen. Every rule for new drops in one place (the rules
## themselves live in loot_rules.gd). Opened from the Bag tab, the Autoplay and
## Auto-dive panels. Locked items, set pieces, upgrades and Legendary-or-better are never touched.

var m
var state: GameState
var body: VBoxContainer

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Loot filter", 560.0)
	body = UI.vbox(10)
	content.add_child(body)
	_fill()

func _row_button(text: String, on: bool, cb: Callable, tip := "") -> Button:
	var b := UI.button(text, func():
		cb.call()
		_fill())
	b.custom_minimum_size = Vector2(0, UI.TAP)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", UI.TEAL if on else UI.DIM)
	if tip != "":
		b.tooltip_text = tip
	body.add_child(b)
	return b

func _fill() -> void:
	OnlineUI.clear(body)
	var lf := LootRules.rules(state)
	var master := UI.primary("Loot filter: ON" if bool(lf["on"]) else "Loot filter: OFF (keeps everything)", func():
		LootRules.toggle(state, "on")
		_fill(), UI.TEAL if bool(lf["on"]) else UI.RED)
	master.custom_minimum_size = Vector2(0, UI.TAP + 8)
	body.add_child(master)
	body.add_child(UI.wrap("New drops that match a rule below are dealt with the moment they drop. Right now it %s." % LootRules.summary(state), UI.FONT_CAPTION, UI.DIM))

	UI.section(body, "What happens to them")
	var sell := String(lf["action"]) == "sell"
	var act := UI.primary("Sell them for gold" if sell else "Salvage them for scrap", func():
		LootRules.cycle_action(state)
		_fill(), UI.GOLD if sell else UI.BLUE)
	act.custom_minimum_size = Vector2(0, UI.TAP)
	act.tooltip_text = "Tap to switch between selling (gold) and salvaging (scrap)"
	body.add_child(act)
	body.add_child(UI.wrap("Gold from sold drops is carried: you lose it if you fall. Scrap is safe.", UI.FONT_CAPTION, UI.GOLD if sell else UI.DIM))

	UI.section(body, "By rarity", "Drops of this rarity and below.")
	_row_button("Rarity: %s" % LootRules.RARITY_NAMES[state.auto_salvage + 1], state.auto_salvage >= 0,
		func(): LootRules.cycle_rarity(state), "Tap to step through Off, Commons, up to Epic and below")

	UI.section(body, "By slot", "Common to Rare drops for the slots you mark.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	var slots: Dictionary = lf["slots"]
	for s in GameData.SLOT_ORDER:
		var on := bool(slots.get(s, false))
		var sl: String = s
		var b := UI.button("%s: %s" % [s, "goes" if on else "keep"], func():
			LootRules.toggle_slot(state, sl)
			_fill())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UI.TAP)
		b.add_theme_color_override("font_color", UI.RED if on else UI.TEXT)
		grid.add_child(b)

	UI.section(body, "Smart rules")
	_row_button("Weaker than what I wear: %s" % ("ON" if bool(lf["weaker"]) else "OFF"), bool(lf["weaker"]),
		func(): LootRules.toggle(state, "weaker"), "Common to Rare drops weaker than what you wear in that slot")
	_row_button("Below my Gear Score (%d): %s" % [state.average_gear_score(), "ON" if bool(lf["below_gs"]) else "OFF"], bool(lf["below_gs"]),
		func(): LootRules.toggle(state, "below_gs"), "Common to Epic drops with a Gear Score below the average of what you wear")

	UI.section(body, "Always keep", "These win over every rule above.")
	_row_button("Set pieces: %s" % ("ON" if bool(lf["keep_sets"]) else "OFF"), bool(lf["keep_sets"]),
		func(): LootRules.toggle(state, "keep_sets"), "Pieces of a gear set are kept, whatever their rarity")
	body.add_child(UI.wrap("Upgrades for what you wear, locked items and Legendary or better are never touched.", UI.FONT_CAPTION, UI.DIM))

	UI.section(body, "While Auto plays")
	_row_button("Use the loot filter during Auto: %s" % ("ON" if AutoDive.filter_in_auto(state) else "OFF"), AutoDive.filter_in_auto(state),
		func(): AutoDive.set_value(state, "filter_in_auto", not AutoDive.filter_in_auto(state)))
	m.refresh()
