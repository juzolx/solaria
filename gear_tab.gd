class_name GearTab
extends VBoxContainer
## Items > Gear: what you're wearing. Tap a slot, then tap an item to wear it.

var main
var state: GameState
var slot_labels := {}
var slot_styles := {}
var stats_label: RichTextLabel
var list_title: Label
var list: ItemList
var ids: Array[int] = []
var slot := "Weapon"
var shown := ""
var equip_best_button: Button
var loadout_buttons: Array[Button] = []

func setup(m) -> void:
	main = m
	state = m.state
	name = "Gear"
	add_theme_constant_override("separation", 8)

	var head := UI.hbox(8)
	add_child(head)
	var hint := UI.label("Tap a slot, then tap an item to wear it", 13, UI.DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(hint)
	equip_best_button = UI.primary("Equip Best", func():
		state.equip_best()
		main.sfx.play("equip")
		main.refresh(), UI.GREEN)
	equip_best_button.tooltip_text = "Wear whatever makes your whole build strongest, counting set bonuses and special effects"
	head.add_child(equip_best_button)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for s in GameData.SLOT_ORDER:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 66)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := UI.style(UI.INSET, UI.EMPTY, 8, 6)
		card.add_theme_stylebox_override("panel", st)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(s))
		var r := UI.rich(12)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(r)
		grid.add_child(card)
		slot_labels[s] = r
		slot_styles[s] = st

	stats_label = UI.rich(13)
	add_child(stats_label)
	list_title = UI.label("", 13, UI.TEXT)
	add_child(list_title)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", 13)
	list.item_selected.connect(_on_item_selected)
	add_child(list)

	# Loadouts: save your gear to swap builds in one tap
	var lrow := UI.hbox(6)
	add_child(lrow)
	lrow.add_child(UI.label("Loadouts:", 12, UI.DIM))
	for i in 3:
		var b := UI.button("", _loadout.bind(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lrow.add_child(b)
		loadout_buttons.append(b)
	var save_lo := UI.button("Save to...", func():
		var o := Overlay.new().open(main, "Save your gear as a loadout", 420.0)
		var r := UI.hbox(6)
		o.content.add_child(r)
		for i in 3:
			var sb := UI.primary("Loadout %d" % (i + 1), func(): state.save_loadout(i); o.close(); main.refresh(), UI.GOLD)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(sb))
	lrow.add_child(save_lo)

func _on_card_input(event: InputEvent, s: String) -> void:
	var mb := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or (touch != null and touch.pressed):
		slot = s
		main.sfx.play("click")
		main.refresh()

## Tapping an item shows it next to what you're wearing; Equip from there.
func _on_item_selected(idx: int) -> void:
	if idx >= 0 and idx < ids.size() and ids[idx] >= 0:
		var id := ids[idx]
		var found := state.find_item(id)
		if not found.is_empty():
			var acts := []
			if found["where"] == "bag":
				acts.append(["Equip", func(): state.equip(id); main.sfx.play("equip"); main.refresh(), UI.GREEN])
			elif not state.bag_full():
				acts.append(["Unequip", func(): state.unequip(id); main.refresh(), UI.RED])
			ItemPopup.show_item(main, found["item"], acts)
	list.deselect_all()
	main.refresh()

func _loadout(i: int) -> void:
	if Input.is_key_pressed(KEY_SHIFT) or state.loadouts[i].is_empty():
		state.save_loadout(i)
	else:
		state.wear_loadout(i)
		main.sfx.play("equip")
	main.refresh()

func _count(s: String) -> int:
	var n := 0
	for item in state.bag:
		if item["slot"] == s:
			n += 1
	return n

func refresh() -> void:
	for i in loadout_buttons.size():
		var empty: bool = state.loadouts[i].is_empty()
		loadout_buttons[i].text = "%d: %s" % [i + 1, "empty" if empty else "Wear"]
		loadout_buttons[i].tooltip_text = "Empty: tap to save what you're wearing now." if empty else "Put on loadout %d (shift-click to overwrite it)." % (i + 1)
	var ups := 0
	for s in GameData.SLOT_ORDER:
		var r: RichTextLabel = slot_labels[s]
		var st: StyleBoxFlat = slot_styles[s]
		var n := _count(s)
		var extra := "[color=%s]%d in bag[/color]" % [UI.hex(UI.DIM), n] if n > 0 else ""
		if state.has_upgrade(s):
			extra += "  [color=#4ade80]UPGRADE![/color]"
			ups += 1
		if state.equipped.has(s):
			var item: Dictionary = state.equipped[s]
			var c := GameData.color_of(item["rarity"])
			r.text = "[color=%s]%s[/color]   %s\n[color=%s]%s[/color]\n+%d %s" % [
				UI.hex(UI.DIM), s.to_upper(), extra, c, GameData.display_name(item), GameData.item_power(item), item["stat"]]
			st.border_color = Color.html(c)
		else:
			r.text = "[color=%s]%s[/color]   %s\n[color=#555566]Empty[/color]" % [UI.hex(UI.DIM), s.to_upper(), extra]
			st.border_color = UI.EMPTY
		var picked: bool = s == slot
		st.set_border_width_all(4 if picked else 2)
		st.bg_color = UI.HILITE if picked else UI.INSET
	equip_best_button.text = "Equip Best (%d)" % ups if ups > 0 else "Equip Best"
	equip_best_button.disabled = ups == 0

	var text := "Attack [color=#fbbf24]%d[/color]     Defense [color=#60a5fa]%d[/color]     Max HP [color=#4ade80]%d[/color]" % [
		state.get_attack(), state.get_defense(), state.get_max_hp()]
	var effects: Array[String] = []
	for effect in ["lifesteal", "regen", "double_strike", "crit", "dodge", "thorns", "gold_find"]:
		var total := state.effect_total(effect)
		if total > 0:
			effects.append(GameData.effect_text(effect, total))
	for effect in GameData.ITEM_BONUS_EFFECTS:
		var t2 := int(round(state._flat(effect)))
		if t2 > 0:
			effects.append(GameData.effect_text(effect, t2))
	if not effects.is_empty():
		text += "\n[color=#fbbf24]%s[/color]" % ", ".join(effects)
	var counts := state.set_counts()
	for set_name in counts:
		if int(counts[set_name]) >= 2:
			text += "\n[color=#2dd4bf]%s set: %d pieces active[/color]" % [set_name, counts[set_name]]
	stats_label.text = text

	var key := "%s|%d" % [slot, state.bag_version]
	if key != shown:
		shown = key
		_rebuild()

func _rebuild() -> void:
	list_title.text = "%s  -  %d in your bag  (tap one to wear it)" % [slot.to_upper(), _count(slot)]
	list.clear()
	ids.clear()
	if state.equipped.has(slot):
		var worn: Dictionary = state.equipped[slot]
		var w := list.add_item("%s   +%d %s   (wearing)" % [GameData.display_name(worn), GameData.item_power(worn), worn["stat"]])
		list.set_item_custom_fg_color(w, Color.html(GameData.color_of(worn["rarity"])))
		list.set_item_custom_bg_color(w, UI.HILITE)
		list.set_item_selectable(w, false)
		ids.append(-1)
	var best := state.best_for_slot(slot)
	var items: Array = state.bag.filter(func(it): return it["slot"] == slot)
	items.sort_custom(func(a, b): return state.score_with(a) > state.score_with(b))
	for item in items:
		var tag := "  BEST" if not best.is_empty() and int(best["id"]) == int(item["id"]) else ""
		var idx := list.add_item("%s   +%d %s   %s%s" % [GameData.display_name(item), GameData.item_power(item), item["stat"], ItemText.delta(state, item), tag])
		list.set_item_custom_fg_color(idx, Color.html(GameData.color_of(item["rarity"])))
		list.set_item_tooltip(idx, ItemText.tip(state, item))
		ids.append(int(item["id"]))
	if items.is_empty():
		var e := list.add_item("No %s items in your bag yet." % slot)
		list.set_item_selectable(e, false)
		list.set_item_custom_fg_color(e, UI.DIM)
		ids.append(-1)
