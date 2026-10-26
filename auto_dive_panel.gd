class_name AutoDivePanel
extends Overlay
## 2.1: Auto-dive settings, one panel. When Auto heads home, when it stops,
## what it drinks, and the loot filter during Auto. Rules: auto_dive.gd (head home,
## elixirs) and auto_rules.gd (pause). Opened from the Autoplay popup.

var m
var state: GameState
var body: VBoxContainer

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Auto-dive settings", 560.0, UI.TEAL)
	body = UI.vbox(10)
	content.add_child(body)
	_fill()

func _btn(text: String, on: bool, cb: Callable) -> Button:
	var b := UI.button(text, func():
		cb.call()
		_fill())
	b.custom_minimum_size = Vector2(0, UI.TAP)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", UI.TEAL if on else UI.DIM)
	body.add_child(b)
	return b

func _stepper(title: String, key: String, steps: Array) -> void:
	var v := int(AutoDive.value(state, key))
	_btn("%s: %s" % [title, AutoDive.label_for(key, v)], v > 0 or (key == "potions_at" and v >= 0),
		func(): AutoDive.step(state, key, steps))

func _fill() -> void:
	OnlineUI.clear(body)
	body.add_child(UI.wrap("These work with Autoplay on. Tap a button to change it.", UI.FONT_BODY, UI.DIM))

	UI.section(body, "Go home when...", "Auto finishes the floor, then heads home with your loot.")
	_stepper("Bag is", "bag_pct", AutoDive.BAG_STEPS)
	_stepper("Potions", "potions_at", AutoDive.POTION_STEPS)
	_stepper("HP", "hp_pct", AutoDive.HP_STEPS)
	if not state.hardcore:
		_stepper("Team", "downs", AutoDive.DOWN_STEPS)

	UI.section(body, "Stop Auto when...", "Auto pauses and tells you why, once per thing. Tap Auto to carry on.")
	_stepper("You reach", "stop_floor", AutoDive.FLOOR_STEPS)
	for rid in AutoRules.RULES:
		var r_id: String = rid
		_btn("%s: %s" % [AutoRules.RULES[r_id], "ON" if AutoRules.on(state, r_id) else "OFF"], AutoRules.on(state, r_id), func():
			AutoRules.toggle(state, r_id)
			state.save_game())

	UI.section(body, "Potions and elixirs")
	_btn("Auto-potion: %s" % ("ON" if state.auto_potion else "OFF"), state.auto_potion, func():
		state.auto_potion = not state.auto_potion
		state.save_game())
	var prow := UI.hbox(8)
	body.add_child(prow)
	var pl := UI.label("", 15, UI.PINK)
	pl.custom_minimum_size = Vector2(110, 0)
	var slider := HSlider.new()
	slider.min_value = 10
	slider.max_value = 70
	slider.step = 5
	slider.value = state.auto_potion_at * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, UI.TAP)
	pl.text = "Below %d%%" % int(slider.value)
	slider.value_changed.connect(func(val: float):
		state.auto_potion_at = val / 100.0
		pl.text = "Below %d%%" % int(val)
		state.save_game())
	prow.add_child(slider)
	prow.add_child(pl)
	body.add_child(UI.wrap("Auto drinks a potion when your HP drops below this.", UI.FONT_BODY, UI.DIM))
	_btn("Drink an elixir before bosses: %s" % ("ON" if bool(AutoDive.value(state, "elixir_boss")) else "OFF"), bool(AutoDive.value(state, "elixir_boss")),
		func(): AutoDive.set_value(state, "elixir_boss", not bool(AutoDive.value(state, "elixir_boss"))))

	UI.section(body, "Loot")
	_btn("Use the loot filter during Auto: %s" % ("ON" if AutoDive.filter_in_auto(state) else "OFF"), AutoDive.filter_in_auto(state),
		func(): AutoDive.set_value(state, "filter_in_auto", not AutoDive.filter_in_auto(state)))
	var lfb := UI.button("Loot filter: %s" % LootRules.summary(state), func():
		close()
		LootFilter.new().show_for(m))
	lfb.custom_minimum_size = Vector2(0, UI.TAP)
	body.add_child(lfb)
	m.refresh()
