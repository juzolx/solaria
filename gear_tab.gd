class_name GearTab
extends VBoxContainer
## Items > Gear: what you're wearing. Tap a slot, then tap an item to wear it.

var main
var state: GameState
var slot_labels := {}
var slot_styles := {}
var stats_label: RichTextLabel
var list_title: Label
var item_grid: GridContainer
var empty_note: Label
var slot_pics := {}
var doll_pic: TextureRect   # your hero, wearing what's equipped
var doll_key := ""
var slot := "Weapon"
var shown := ""
var equip_best_button: Button

func setup(m) -> void:
	main = m
	state = m.state
	name = "Gear"
	add_theme_constant_override("separation", 8)

	var head := UI.hbox(8)
	add_child(head)
	var hint := UI.wrap("Tap a slot, then an item to wear it, or drag an item onto a slot.", UI.FONT_CAPTION, UI.DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(hint)
	equip_best_button = UI.primary("Equip Best", func():
		state.equip_best()
		main.sfx.play("equip")
		main.refresh(), UI.GREEN)
	equip_best_button.tooltip_text = "Wear whatever makes your whole build strongest, counting set bonuses and special effects"
	head.add_child(equip_best_button)

	# 0.13+: a paper doll: your hero in the middle wearing it all, slots on either side
	var doll := UI.hbox(6)
	add_child(doll)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doll.add_child(left)
	doll_pic = TextureRect.new()
	doll_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	doll_pic.custom_minimum_size = Vector2(124, 0)
	doll_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	doll_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	doll.add_child(doll_pic)
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doll.add_child(right)
	for s in GameData.SLOT_ORDER:
		var grid: VBoxContainer = left if s in ["Weapon", "Helmet", "Chest"] else right
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 66)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := UI.style(UI.INSET, UI.EMPTY, 8, 6)
		card.add_theme_stylebox_override("panel", st)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(s))
		Drag.wire(card, {"kind": "worn", "slot": s}, func(): return slot_pics[s].texture, _takes.bind(s), _dropped_on_slot.bind(s))  # next update: drag and drop
		var ch := UI.hbox(8)
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ch)
		var pic := ItemGrid.picture(36)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ch.add_child(pic)
		slot_pics[s] = pic
		var r := UI.rich(UI.FONT_CAPTION)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.add_child(r)
		grid.add_child(card)
		slot_labels[s] = r
		slot_styles[s] = st

	stats_label = UI.rich(UI.FONT_CAPTION)
	add_child(stats_label)
	list_title = UI.wrap("", UI.FONT_CAPTION, UI.TEXT)
	add_child(list_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	item_grid = ItemGrid.grid()
	sv.add_child(item_grid)
	empty_note = UI.label("", UI.FONT_CAPTION, UI.DIM)
	sv.add_child(empty_note)
	resized.connect(_on_resized)

	# 2.1: gear loadouts are part of the one Presets screen (gear, skills, team, supplies)
	var pb := UI.button("Presets: save or swap gear, skills and team", func(): PresetsScreen.new().show_for(main))
	pb.custom_minimum_size = Vector2(0, UI.TAP)
	add_child(pb)

func _on_resized() -> void:
	ItemGrid.fit([item_grid], size.x)

func _on_card_input(event: InputEvent, s: String) -> void:
	var mb := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or (touch != null and touch.pressed):
		slot = s
		main.sfx.play("click")
		main.refresh()

## Tapping an item shows it next to what you're wearing; Equip from there.
func _show(id: int) -> void:
	var found := state.find_item(id)
	if found.is_empty():
		return
	main.sfx.play("click")
	var acts := []
	if found["where"] == "bag":
		acts.append(["Equip", func(): state.equip(id); main.sfx.play("equip"); main.refresh(), UI.GREEN])
	elif not state.bag_full():
		acts.append(["Unequip", func(): state.unequip(id); main.refresh(), UI.RED])
	ItemPopup.show_item(main, found["item"], acts)

var _ghosts := {}
## A plain item picture for an empty slot (same look every time).
func _ghost(s: String) -> Texture2D:
	if not _ghosts.has(s):
		var keep := randi()
		seed(hash(s))
		var it: Dictionary = GameData.make_item(s, 0, 1, 0)
		seed(keep)
		_ghosts[s] = Sprites.item_icon(it)
	return _ghosts[s]

func _count(s: String) -> int:
	var n := 0
	for item in state.bag:
		if item["slot"] == s:
			n += 1
	return n

func refresh() -> void:
	var ups := 0
	var dk := str(state.appearance) + str(state.hero_looks())
	if dk != doll_key:
		doll_key = dk
		doll_pic.texture = Sprites.portrait(state.appearance, state.hero_looks())
	for s in GameData.SLOT_ORDER:
		var r: RichTextLabel = slot_labels[s]
		var st: StyleBoxFlat = slot_styles[s]
		var n := _count(s)
		var extra := "[color=%s]%d in bag[/color]" % [UI.hex(UI.DIM), n] if n > 0 else ""
		if state.has_upgrade(s):
			extra += "  [color=#4ade80]UPGRADE![/color]"
			ups += 1
		var pic: TextureRect = slot_pics[s]
		pic.texture = Sprites.item_icon(state.equipped[s]) if state.equipped.has(s) else _ghost(s)
		pic.modulate = Color.WHITE if state.equipped.has(s) else Color(0.55, 0.6, 0.8, 0.22)  # empty: a faint outline of what goes here
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
	text += "     Gear Score [color=#e8b14a]%d[/color]" % state.average_gear_score()  # the average of what you wear
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
			text += "\n[color=#2dd4bf]%s set: %d pieces active[/color]" % [GameData.set_name_of(set_name), counts[set_name]]
	stats_label.text = text

	var key := "%s|%d" % [slot, state.bag_version]
	if key != shown:
		shown = key
		_rebuild()

func _rebuild() -> void:
	list_title.text = "%s  -  %d in your bag  (tap one to compare and wear it)" % [slot.to_upper(), _count(slot)]
	ItemGrid.fit([item_grid], size.x)
	for c in item_grid.get_children():
		c.queue_free()
	if state.equipped.has(slot):
		var worn: Dictionary = state.equipped[slot]
		var wc := ItemGrid.cell(worn, _show.bind(int(worn["id"])), true, ItemGrid.CELL, "ON")
		Drag.wire(wc, {"kind": "worn", "slot": slot}, Sprites.item_icon(worn), _takes_off, _dropped_off)
		item_grid.add_child(wc)
	var best := state.best_for_slot(slot)
	var items: Array = state.bag.filter(func(it): return it["slot"] == slot)
	items.sort_custom(func(a, b): return state.score_with(a) > state.score_with(b))
	for item in items:
		var pct := state.compare_pct(item)
		var badge := ""
		if not best.is_empty() and int(best["id"]) == int(item["id"]) and pct > 0.0:
			badge = "BEST"
		elif pct > 0.0:
			badge = "+%d%%" % int(round(pct))
		var ic := ItemGrid.cell(item, _show.bind(int(item["id"])), false, ItemGrid.CELL, badge)
		Drag.wire(ic, {"kind": "item", "id": int(item["id"])}, Sprites.item_icon(item), _takes_off, _dropped_off)
		item_grid.add_child(ic)
	empty_note.visible = items.is_empty()
	empty_note.text = "No %s items in your bag yet." % slot

# =====================================================================
# Next update: drag and drop. An item onto a slot wears it; a worn piece
# dragged into the item list comes off.
# =====================================================================

func _takes(d: Dictionary, s: String) -> bool:
	if d.get("kind", "") != "item":
		return false
	var found := state.find_item(int(d["id"]))
	return not found.is_empty() and found["where"] == "bag" and found["item"]["slot"] == s

func _dropped_on_slot(d: Dictionary, s: String) -> void:
	state.equip(int(d["id"]))
	main.sfx.play("equip")
	slot = s
	shown = ""
	main.refresh()

func _takes_off(d: Dictionary) -> bool:
	return d.get("kind", "") == "worn" and state.equipped.has(str(d["slot"])) and not state.bag_full()

func _dropped_off(d: Dictionary) -> void:
	state.unequip(int(state.equipped[str(d["slot"])]["id"]))
	main.sfx.play("click")
	shown = ""
	main.refresh()
