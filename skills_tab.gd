class_name SkillsTab
extends VBoxContainer
## Character > Skills: the Skill Book. Every skill you've found from ability
## stones. Equip 3 active and 5 passive (slots open as you level), rank them
## up with duplicate stones, and craft any skill with dust.

var main
var state: GameState
var slot_row_a: HBoxContainer
var slot_row_p: HBoxContainer
var filter_pick: OptionButton
var list: ItemList
var ids: Array[String] = []
var detail: RichTextLabel
var equip_button: Button
var craft_button: Button
var dust_label: Label
var selected := ""
var shown := ""

const FILTERS := ["All", "Active", "Passive", "Equipped"]

func setup(m) -> void:
	main = m
	state = m.state
	name = "Skills"
	add_theme_constant_override("separation", 6)
	var head := UI.hbox(8)
	add_child(head)
	var t := UI.label("SKILL BOOK", 14, UI.TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	dust_label = UI.label("", 13, Color("#c4b5fd"))
	head.add_child(dust_label)
	head.add_child(UI.button("Craft...", _craft_popup))

	add_child(UI.label("ACTIVE", 10, UI.DIM))
	slot_row_a = UI.hbox(4)
	add_child(slot_row_a)
	add_child(UI.label("PASSIVE", 10, UI.DIM))
	slot_row_p = UI.hbox(4)
	add_child(slot_row_p)

	filter_pick = OptionButton.new()
	for f in FILTERS:
		filter_pick.add_item(f)
	for tag in Classes.TAGS:
		filter_pick.add_item(tag)
	filter_pick.item_selected.connect(func(_i): shown = ""; refresh())
	add_child(filter_pick)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", 12)
	list.item_selected.connect(func(i: int):
		if i >= 0 and i < ids.size():
			selected = ids[i]
			_show_detail())
	list.item_activated.connect(func(_i): _toggle_equip())
	add_child(list)
	var box := UI.panel(UI.INSET, UI.EMPTY, 8, 8, 1)
	add_child(box)
	detail = UI.rich(12)
	detail.custom_minimum_size = Vector2(0, 62)
	box.add_child(detail)
	var row := UI.hbox(6)
	add_child(row)
	equip_button = UI.primary("Equip", _toggle_equip, UI.GREEN)
	craft_button = UI.button("", func():
		if state.craft_skill(selected):
			main.sfx.play("craft")
		shown = ""
		main.refresh())
	for b in [equip_button, craft_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)

func _slot_button(id: String, open: bool, need: int, active: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 34)
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 11)
	if not open:
		b.text = "Lv %d" % need
		b.disabled = true
		return b
	if id == "":
		b.text = "(empty)"
		b.add_theme_color_override("font_color", UI.DIM)
		b.pressed.connect(func():
			filter_pick.select(1 if active else 2)
			shown = ""
			refresh())
		return b
	var s := SkillData.info(id)
	b.text = "%s %d" % [s["name"], state.skill_rank(id)]
	var c := Color(Classes.tag_color(s["tags"][0]))
	b.add_theme_stylebox_override("normal", UI.style(c.darkened(0.7), c.darkened(0.2), 6, 4, 1))
	b.add_theme_color_override("font_color", c.lightened(0.4))
	b.tooltip_text = SkillData.describe(id, state.skill_rank(id))
	b.pressed.connect(func():
		selected = id
		_show_detail())
	return b

func _passes(id: String) -> bool:
	var s := SkillData.info(id)
	match filter_pick.selected:
		0:
			return true
		1:
			return s["kind"] == "active"
		2:
			return s["kind"] == "passive"
		3:
			return state.is_skill_equipped(id)
	var tag: String = filter_pick.get_item_text(filter_pick.selected)
	return tag in s["tags"]

func refresh() -> void:
	dust_label.text = "Dust %d" % state.dust
	var key := "%s|%s|%s|%d|%d|%d" % [str(state.skill_book), str(state.active_slots), str(state.passive_slots), filter_pick.selected, state.level, state.dust]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(slot_row_a)
	OnlineUI.clear(slot_row_p)
	for i in 3:
		slot_row_a.add_child(_slot_button(state.active_slots[i], i < state.active_slot_count(), int(SkillData.ACTIVE_SLOTS_AT[i]), true))
	for i in 5:
		slot_row_p.add_child(_slot_button(state.passive_slots[i], i < state.passive_slot_count(), int(SkillData.PASSIVE_SLOTS_AT[i]), false))
	list.clear()
	ids.clear()
	var owned: Array = state.skill_book.keys()
	owned.sort_custom(func(a, b):
		var ea := state.is_skill_equipped(a)
		var eb := state.is_skill_equipped(b)
		if ea != eb:
			return ea
		return SkillData.skill_name(a) < SkillData.skill_name(b))
	for id in owned:
		if not _passes(id):
			continue
		var s := SkillData.info(id)
		var tags := "/".join(s["tags"])
		var eq := "  [equipped]" if state.is_skill_equipped(id) else ""
		var i := list.add_item("%s  %d/5   %s  -  %s%s" % [s["name"], state.skill_rank(id), "Active" if s["kind"] == "active" else "Passive", tags, eq])
		list.set_item_custom_fg_color(i, Color(SkillData.RARITY_COLORS[int(s["rarity"])]))
		list.set_item_tooltip(i, SkillData.describe(id, state.skill_rank(id)))
		ids.append(id)
		if id == selected:
			list.select(i)
	if ids.is_empty():
		var e := list.add_item("No skills here yet. Monsters drop ability stones (bosses always do).")
		list.set_item_selectable(e, false)
		list.set_item_custom_fg_color(e, UI.DIM)
		ids.append("")
	_show_detail()

func _show_detail() -> void:
	if selected == "" or not SkillData.SKILLS.has(selected):
		detail.text = "[color=%s]Select a skill. Double-tap to equip or unequip. Skills that share a tag with your class (%s) hit %d%% harder.[/color]" % [
			UI.hex(UI.DIM), ", ".join(state.class_info().get("tags", [])), int(Classes.AFFINITY_POWER * 100)]
		equip_button.disabled = true
		craft_button.disabled = true
		craft_button.text = "Rank up"
		return
	var s := SkillData.info(selected)
	var r := state.skill_rank(selected)
	var tags: Array = []
	for t in s["tags"]:
		tags.append("[color=%s]%s[/color]" % [Classes.tag_color(t), t])
	var extra := ""
	if s["kind"] == "active" and r > 0:
		extra = "  [color=%s]Power now: x%.2f, cooldown %d.[/color]" % [UI.hex(UI.DIM), state.skill_mult(selected), state.skill_cd(selected)]
	detail.text = "[b]%s[/b]  [color=%s]%s %s[/color]  %s  [color=#e8b14a]Rank %d/5[/color]\n%s%s" % [
		s["name"], SkillData.RARITY_COLORS[int(s["rarity"])], SkillData.RARITY_NAMES[int(s["rarity"])], "active" if s["kind"] == "active" else "passive",
		" ".join(tags), r, SkillData.describe(selected, maxi(1, r)), extra]
	equip_button.disabled = r <= 0
	equip_button.text = "Unequip" if state.is_skill_equipped(selected) else "Equip"
	if r >= SkillData.MAX_RANK:
		craft_button.text = "Max rank"
		craft_button.disabled = true
	else:
		var cost := SkillData.craft_cost(selected, r)
		craft_button.text = "%s (%d dust)" % ["Rank up" if r > 0 else "Craft", cost]
		craft_button.disabled = state.dust < cost

func _toggle_equip() -> void:
	if selected == "" or state.skill_rank(selected) <= 0:
		return
	if state.is_skill_equipped(selected):
		state.unequip_skill(selected)
	elif state.equip_skill(selected):
		main.sfx.play("equip")
	shown = ""
	main.refresh()

## Pick any skill in the game to craft with dust.
func _craft_popup() -> void:
	var o := Overlay.new().open(main, "Craft a skill with dust", 640.0, Color("#c4b5fd"))
	o.content.add_child(UI.label("You have %d dust. Dust comes from stones of skills you've already maxed." % state.dust, 13, UI.DIM))
	var l := ItemList.new()
	l.custom_minimum_size = Vector2(0, 340)
	l.add_theme_font_size_override("font_size", 12)
	o.content.add_child(l)
	var all_ids: Array = SkillData.SKILLS.keys()
	all_ids.sort_custom(func(a, b): return SkillData.skill_name(a) < SkillData.skill_name(b))
	var picks: Array[String] = []
	for id in all_ids:
		var s := SkillData.info(id)
		var r := state.skill_rank(id)
		if r >= SkillData.MAX_RANK:
			continue
		var cost := SkillData.craft_cost(id, r)
		var i := l.add_item("%s  (%s, %s)  %s  -  %d dust" % [s["name"], "/".join(s["tags"]), "active" if s["kind"] == "active" else "passive",
			"new" if r == 0 else "rank %d -> %d" % [r, r + 1], cost])
		l.set_item_custom_fg_color(i, Color(SkillData.RARITY_COLORS[int(s["rarity"])]) if state.dust >= cost else UI.DIM)
		l.set_item_tooltip(i, s["text"])
		picks.append(id)
	l.item_activated.connect(func(i: int):
		if state.craft_skill(picks[i]):
			main.sfx.play("craft")
			o.close()
			selected = picks[i]
			shown = ""
			main.refresh())
	o.content.add_child(UI.label("Double-tap a skill to craft it.", 11, UI.DIM))
