class_name GearTab
extends VBoxContainer
## Items › Gear: what you're wearing. Tap a slot, then tap an item to wear it.

var main
var state: GameState
var slot_labels := {}
var slot_styles := {}
var stats_label: Label
var list_title: Label
var item_grid: GridContainer
var empty_note: Label
var slot_pics := {}
var doll_pic: TextureRect   # your hero, wearing what's equipped
var doll_key := ""
var slot := "Weapon"
var shown := ""
var equip_best_button: Button
var slot_caps := {}           # slot -> the small name under its square
var slot_cards := {}          # slot -> its square (tap-tip = the full line)
var slot_info := {}           # slot -> "RING: Bone Band  +12 Defense  (2 in bag)  UPGRADE!" (the tap-tip, tests read it)
var slot_detail: RichTextLabel  # the picked slot's item, one line under the hero
var pills := {}               # "ATK"/"DEF"/"HP"/"Score" -> value Label
const SLOT_PX := 60   # Fable r1: 60 keeps Gear on a 375x667 screen with body-20 captions
## Fable r5 #2: on a short phone (the SE) the slots shrink to 52, the four number pills become one
## line and the bag list keeps a full row, so the upgrade the page points at can be tapped.
var slot_px := SLOT_PX
var pill_line: RichTextLabel
var pill_row: HBoxContainer
var doll_center: Control
var short_on := -1   # the layout applied: -1 none yet, 0 roomy, 1 short (the screen size is known at refresh, not setup)

func setup(m) -> void:
	main = m
	state = m.state
	name = "Gear"
	add_theme_constant_override("separation", 3)   # phone sweep: fits a 375x667 phone (896 design px)

	var head := UI.hbox(8)
	add_child(head)
	# Fable r1 (SE fit, fewer words): Presets and Equip Best share the top row; no hint line
	# 2.1: gear loadouts are part of the one Presets screen (gear, skills, team, supplies)
	var pb := UI.button("Presets", func(): PresetsScreen.new().show_for(main))
	pb.tooltip_text = "Save or swap gear, skills and team"
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(pb)
	equip_best_button = UI.primary("Equip Best", func():
		state.equip_best()
		main.sfx.play("equip")
		main.refresh(), UI.GREEN)
	equip_best_button.tooltip_text = "Wear whatever makes your whole build strongest, counting set bonuses and special effects"
	equip_best_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(equip_best_button)

	# 0.13+: a paper doll: your hero in the middle wearing it all, slots on either side.
	# Interface pass (approved mockup 08): square slots with their name under them, the hero
	# big in the middle on a plinth, and the picked slot's item on one line underneath.
	var doll := UI.hbox(6)
	add_child(doll)
	var left := UI.vbox(3)
	doll.add_child(left)
	var center := Control.new()
	doll_center = center
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(0, 4 * (slot_px + 22) - 4)
	doll.add_child(center)
	var right := UI.vbox(3)
	doll.add_child(right)
	var pl := TextureRect.new()
	pl.texture = UiIcons.plinth(64)
	pl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(pl)
	doll_pic = TextureRect.new()
	doll_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	doll_pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 3
	doll_pic.size = doll_pic.custom_minimum_size
	doll_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	doll_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(doll_pic)
	center.resized.connect(func():
		var cw := center.size.x
		var ph := doll_pic.custom_minimum_size
		doll_pic.position = Vector2(roundf((cw - ph.x) / 2.0), center.size.y - ph.y - 14)
		pl.position = Vector2(roundf((cw - pl.texture.get_width()) / 2.0), center.size.y - pl.texture.get_height() - 2))
	for s in GameData.SLOT_ORDER:
		var grid: VBoxContainer = left if s in ["Weapon", "Helmet", "Chest", "Ring"] else right  # 2.1: four a side, jewelry at the bottom
		var col := UI.vbox(1)
		grid.add_child(col)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(slot_px, slot_px)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := UI.style(UI.INSET, UI.EMPTY, 8, 6)
		card.add_theme_stylebox_override("panel", st)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(s))
		Drag.wire(card, {"kind": "worn", "slot": s}, func(): return slot_pics[s].texture, _takes.bind(s), _dropped_on_slot.bind(s))  # next update: drag and drop
		var pic := ItemGrid.picture(48)
		pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED   # whole pixels only (interface pass)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(pic)
		slot_pics[s] = pic
		col.add_child(card)
		var cap := UI.label(s.replace("Off Hand", "Off-hand").replace("Helmet", "Head").replace("Necklace", "Neck"), UI.FONT_BODY, UI.DIM)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.custom_minimum_size = Vector2(slot_px, 0)
		col.add_child(cap)
		slot_caps[s] = cap
		slot_labels[s] = cap
		slot_cards[s] = card
		UI.tip(card, s)
		slot_styles[s] = st
	slot_detail = UI.rich(UI.FONT_BODY)
	slot_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot_detail)
	# Your numbers as four pills (icon-free words, big values): Attack, Defense, HP, Gear Score
	var prow := UI.hbox(6)
	add_child(prow)
	pill_row = prow
	pill_line = UI.rich(UI.FONT_BODY)
	pill_line.visible = false
	add_child(pill_line)
	for k in ["ATK", "DEF", "HP", "Score"]:
		var pp := PanelContainer.new()
		pp.add_theme_stylebox_override("panel", UiSkin.bevel(UiSkin.SLATE, UI.EDGE, 4))
		pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prow.add_child(pp)
		var pv := UI.vbox(0)
		pp.add_child(pv)
		var kl := UI.label(k, UI.FONT_BODY, UI.DIM)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(kl)
		var vl := UI.label("0", UI.FONT_TITLE, Color("#f4e6c4"))
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(vl)
		pills[k] = vl

	# Fable r4 #11: the effects at body size, two lines where there's room (one on the SE), "..." on
	# the last; the whole list is a tap away
	stats_label = UI.label("", UI.FONT_BODY, UI.GOLD)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats_label.clip_text = true
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.tip(stats_label, "")
	add_child(stats_label)
	list_title = UI.wrap("", UI.FONT_BODY, UI.TEXT)
	add_child(list_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = ItemGrid.CELL + 12   # always one whole row; the doll gives way first
	add_child(scroll)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	item_grid = ItemGrid.grid()
	sv.add_child(item_grid)
	empty_note = UI.label("", UI.FONT_BODY, UI.DIM)
	sv.add_child(empty_note)
	resized.connect(_on_resized)


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

## Fable r5 #2: the short-screen layout (52 px slots, the numbers as one line).
func _fit_short() -> void:
	var s := 1 if get_viewport_rect().size.y < 1000.0 else 0
	if s == short_on:
		return
	short_on = s
	slot_px = 52 if s == 1 else SLOT_PX
	doll_center.custom_minimum_size.y = 4 * (slot_px + 22) - 4
	for k in slot_cards:
		(slot_cards[k] as Control).custom_minimum_size = Vector2(slot_px, slot_px)
		(slot_caps[k] as Control).custom_minimum_size.x = slot_px
	pill_row.visible = s == 0
	pill_line.visible = s == 1

func refresh() -> void:
	_fit_short()
	var ups := 0
	var dk := str(state.appearance) + str(state.hero_looks())
	if dk != doll_key:
		doll_key = dk
		doll_pic.texture = Sprites.portrait(state.appearance, state.hero_looks())
	for s in GameData.SLOT_ORDER:
		var st: StyleBoxFlat = slot_styles[s]
		var cap: Label = slot_caps[s]
		var upg := state.has_upgrade(s)
		if upg:
			ups += 1
		var pic: TextureRect = slot_pics[s]
		pic.texture = UiIcons.big(Sprites.item_icon(state.equipped[s]) if state.equipped.has(s) else UiIcons.ghost(_ghost(s)), 48)
		pic.modulate = Color.WHITE  # empty slots show a slate ghost of what goes here
		var picked: bool = s == slot
		st.border_color = UI.GOLD if picked else (Color.html(GameData.color_of(state.equipped[s]["rarity"])) if state.equipped.has(s) else UI.EMPTY)
		st.set_border_width_all(3 if picked else 2)
		st.bg_color = UI.INSET   # the gold frame marks the picked slot; a slate fill would hide its ghost
		var nm: String = String(s).replace("Off Hand", "Off-hand").replace("Helmet", "Head").replace("Necklace", "Neck")
		cap.text = nm + (" !" if upg else "")   # "!" = an upgrade is waiting in your bag
		cap.add_theme_color_override("font_color", UI.GREEN if upg else (UI.GOLD if picked else UI.DIM))
		var cnt := _count(s)
		var info := "%s · %s" % [nm, (GameData.display_name(state.equipped[s]) + "  +%d %s" % [GameData.item_power(state.equipped[s]), state.equipped[s]["stat"]]) if state.equipped.has(s) else "Empty"]
		if cnt > 0:
			info += "  (%d in bag)" % cnt
		if upg:
			info += " · upgrade in your bag"
		slot_info[s] = info
		(slot_cards[s] as Control).tooltip_text = info
	# the picked slot, in one line: what's worn there and what's waiting in the bag
	var n := _count(slot)
	var extra := ("   [color=%s]%d in bag[/color]" % [UI.hex(UI.DIM), n]) if n > 0 else ""
	if state.has_upgrade(slot):
		extra += "  [color=%s]upgrade![/color]" % UI.hex(UI.GREEN)
	if state.equipped.has(slot):
		var item: Dictionary = state.equipped[slot]
		slot_detail.text = "[color=%s]%s[/color] · [color=%s]%s[/color]  +%d %s%s" % [UI.hex(UI.GOLD), slot, GameData.color_of(item["rarity"]),
			GameData.display_name(item), GameData.item_power(item), item["stat"], extra]
	else:
		slot_detail.text = "[color=%s]%s[/color] · [color=%s]Empty[/color]%s" % [UI.hex(UI.GOLD), slot, UI.hex(UI.DIM), extra]
	equip_best_button.text = "Equip Best (%d)" % ups if ups > 0 else "Equip Best"
	equip_best_button.disabled = ups == 0

	(pills["ATK"] as Label).text = UI.short(state.get_attack())
	(pills["DEF"] as Label).text = UI.short(state.get_defense())
	(pills["HP"] as Label).text = UI.short(state.get_max_hp())
	(pills["Score"] as Label).text = UI.short(state.average_gear_score())  # the average of what you wear
	var pl: Array[String] = []
	for k in ["ATK", "DEF", "HP", "Score"]:
		pl.append("[color=%s]%s[/color] [color=%s]%s[/color]" % [UI.hex(UI.DIM), k, UI.hex(UI.GOLD), (pills[k] as Label).text])
	pill_line.text = " · ".join(pl)
	var text := ""
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
		text += "[color=%s]%s[/color]" % [UI.hex(UI.GOLD), " · ".join(effects)]
	var counts := state.set_counts()
	for set_name in counts:
		if int(counts[set_name]) >= 2:
			text += ("\n" if text != "" else "") + "[color=%s]%s set: %d pieces active[/color]" % [UI.hex(UI.GOLD_DULL), GameData.set_name_of(set_name), counts[set_name]]
	stats_label.tooltip_text = RegEx.create_from_string("\\[[^\\]]*\\]").sub(text, "", true)   # the tip: plain text
	stats_label.text = stats_label.tooltip_text.get_slice("\n", 0)
	stats_label.max_lines_visible = 2 if get_viewport_rect().size.y >= 1000.0 else 1   # the SE has no line to spare
	stats_label.visible = text != ""

	var key := "%s|%d" % [slot, state.bag_version]
	if key != shown:
		shown = key
		_rebuild()

func _rebuild() -> void:
	list_title.text = "%s · %d in your bag" % [slot, _count(slot)]
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
