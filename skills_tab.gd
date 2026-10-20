class_name SkillsTab
extends VBoxContainer
## Character > Skills: the Skill Book. Every skill you've found from ability
## stones. Equip 3 active and 5 passive (slots open as you level), rank them
## up with duplicate stones, and craft any skill with dust.

var main
var state: GameState
var slot_row_a: HBoxContainer
var slot_row_p: HBoxContainer
var sig_row: HBoxContainer
var filter_pick: OptionButton
var cards: GridContainer
var empty_note: Label
var ids: Array[String] = []
var detail: RichTextLabel
var equip_button: Button
var craft_button: Button
var sell_button: Button
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
	head.add_child(UI.button("Autoplay...", func(): auto_battle_popup(main)))
	head.add_child(UI.button("Craft...", _craft_popup))

	add_child(UI.label("ACTIVE", 10, UI.DIM))
	slot_row_a = UI.hbox(4)
	add_child(slot_row_a)
	sig_row = UI.hbox(4)
	add_child(sig_row)
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
	# 0.13+ (Juzo): the skill book as cards, like the bag: icon, name, rank pips, rarity frame
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	cards = GridContainer.new()
	cards.columns = 4
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	scroll.add_child(cards)
	empty_note = UI.label("", 12, UI.DIM)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(empty_note)
	var box := UI.panel(UI.INSET, UI.EMPTY, 8, 8, 1)
	add_child(box)
	detail = UI.rich(12)
	detail.custom_minimum_size = Vector2(0, 62)
	box.add_child(detail)
	var row := UI.hbox(6)
	add_child(row)
	equip_button = UI.primary("Equip", _toggle_equip, UI.GREEN)
	sell_button = UI.button("Sell", func():
		if selected == "":
			return
		var sid := selected
		main.confirm("Sell %s?" % SkillData.skill_name(sid), "You get %d gold, and the skill is gone from your book (you'd have to find or craft it again)." % state.skill_sell_price(sid), "Sell it", func():
			if state.sell_skill(sid) > 0:
				main.sfx.play("sell")
				selected = ""
			shown = ""
			main.refresh()))
	craft_button = UI.button("", func():
		if state.craft_skill(selected):
			main.sfx.play("craft")
		shown = ""
		main.refresh())
	for b in [equip_button, craft_button, sell_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)

func _slot_button(id: String, open: bool, need: int, active: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 34)
	b.clip_text = true
	b.add_theme_font_size_override("font_size", UI.MIN_FONT)
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
	b.text = "%s
Rank %d" % [s["name"], state.skill_rank(id)]
	b.icon = SkillIcons.for_tag(String(s["tags"][0]))  # 0.13+: slots show the skill's icon
	b.add_theme_constant_override("icon_max_width", 22)
	b.custom_minimum_size = Vector2(0, 46)
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
	var key := "%s|%s|%s|%d|%d|%d|%s" % [str(state.skill_book), str(state.active_slots), str(state.passive_slots), filter_pick.selected, state.level, state.dust, state.sig_slot]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(slot_row_a)
	OnlineUI.clear(slot_row_p)
	OnlineUI.clear(sig_row)
	if not Signatures.owned(state).is_empty():
		var sb := Button.new()
		sb.focus_mode = Control.FOCUS_NONE
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.custom_minimum_size = Vector2(0, 34)
		sb.clip_text = true
		sb.add_theme_font_size_override("font_size", UI.MIN_FONT)
		var sc := Color(Signatures.COLOR)
		sb.text = "Signature: %s" % (SkillData.skill_name(state.sig_slot) if state.sig_slot != "" else "(none)")
		sb.add_theme_stylebox_override("normal", UI.style(sc.darkened(0.75), sc.darkened(0.2), 6, 4, 1))
		sb.add_theme_color_override("font_color", sc.lightened(0.3))
		sb.pressed.connect(func(): main.show_tab(0, 1))
		sig_row.add_child(sb)
	for i in 3:
		slot_row_a.add_child(_slot_button(state.active_slots[i], i < state.active_slot_count(), int(SkillData.ACTIVE_SLOTS_AT[i]), true))
	for i in 5:
		slot_row_p.add_child(_slot_button(state.passive_slots[i], i < state.passive_slot_count(), int(SkillData.PASSIVE_SLOTS_AT[i]), false))
	ids.clear()
	var owned: Array = state.skill_book.keys()
	owned.sort_custom(func(a, b):
		var ea := state.is_skill_equipped(a)
		var eb := state.is_skill_equipped(b)
		if ea != eb:
			return ea
		return SkillData.skill_name(a) < SkillData.skill_name(b))
	OnlineUI.clear(cards)
	for id in owned:
		if not _passes(id):
			continue
		cards.add_child(_card(id))
		ids.append(id)
	empty_note.visible = ids.is_empty()
	empty_note.text = "No skills here yet. Monsters drop ability stones (bosses always do)."
	_show_detail()

## One skill as a card: its tag icon, name, rank pips, framed in its rarity color
## (a green edge when equipped). Tap to look; tap again to equip or unequip.
func _card(id: String) -> Button:
	var s := SkillData.info(id)
	var r := state.skill_rank(id)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 92)
	b.icon = SkillIcons.for_tag(String(s["tags"][0]))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 34)
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 11)
	b.text = "%s\n%s" % [s["name"], "●".repeat(r) + "○".repeat(maxi(0, SkillData.MAX_RANK - r))]
	var rc := Color(SkillData.RARITY_COLORS[int(s["rarity"])])
	var eq := state.is_skill_equipped(id)
	var sel := id == selected
	b.add_theme_stylebox_override("normal", UI.style(rc.darkened(0.78), UI.GREEN if eq else rc.darkened(0.15), 6, 4, 3 if sel else (2 if eq else 1)))
	b.add_theme_stylebox_override("hover", UI.style(rc.darkened(0.65), UI.GREEN if eq else rc, 6, 4, 3 if sel else 2))
	b.add_theme_color_override("font_color", rc.lightened(0.35))
	b.tooltip_text = SkillData.describe(id, maxi(1, r))
	b.pressed.connect(func():
		if selected == id:
			_toggle_equip()  # second tap: equip or unequip
		else:
			selected = id
			shown = ""
			refresh())
	return b

func _show_detail() -> void:
	if selected == "" or not SkillData.SKILLS.has(selected):
		detail.text = "[color=%s]Tap a skill to see it, tap it again to equip or unequip. Skills that share a tag with your class (%s) hit %d%% harder.[/color]" % [
			UI.hex(UI.DIM), ", ".join(state.class_info().get("tags", [])), int(Classes.AFFINITY_POWER * 100)]
		equip_button.disabled = true
		craft_button.disabled = true
		craft_button.text = "Rank up"
		sell_button.disabled = true
		sell_button.text = "Sell"
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
	var block := state.skill_sell_block(selected)
	sell_button.text = "Sell (%d gold)" % state.skill_sell_price(selected) if state.skill_book.has(selected) else "Sell"
	sell_button.disabled = block != ""
	sell_button.tooltip_text = block if block != "" else "Sell it for gold (it leaves your book)"
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
	l.add_theme_font_size_override("font_size", UI.MIN_FONT)
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

## Autoplay settings: whether the fight runs by itself, and what it does for you.
static func auto_battle_popup(m) -> void:
	var st: GameState = m.state
	var o := Overlay.new().open(m, "Autoplay", 560.0, UI.TEAL)
	_fill_auto(m, o, st)

static func _fill_auto(m, o: Overlay, st: GameState) -> void:
	for c in o.content.get_children():
		if c != o.content.get_child(0):
			c.queue_free()
	# The big switch
	var mode := UI.primary("Autoplay: ON  (the fight runs by itself)" if st.autoplay else "Autoplay: OFF  (you take every turn)", func():
		st.autoplay = not st.autoplay
		st.save_game()
		m.refresh()
		_fill_auto(m, o, st), UI.TEAL if st.autoplay else UI.RED)
	mode.custom_minimum_size = Vector2(0, UI.TAP + 8)
	o.content.add_child(mode)
	var note := UI.label("With Autoplay off, nothing happens until you act: tap Attack (or the enemy) to take a turn, and use your skills when you choose.", 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	o.content.add_child(note)
	UI.section(o.content, "What runs by itself", "Each of these works in both modes.")
	var toggles: Array = [
		["Auto skills", st.auto_ability, func(): st.auto_ability = not st.auto_ability],
		["Pick rooms at forks", st.auto_paths, func(): st.auto_paths = not st.auto_paths],
		["Spend stat points on your build", st.auto_stats, func(): st.auto_stats = not st.auto_stats],
		["Skip easy fights (far below you: one turn)", st.skip_easy, func(): st.skip_easy = not st.skip_easy],
	]
	for tg in toggles:
		var cb: Callable = tg[2]
		var b := UI.button("%s: %s" % [tg[0], "ON" if tg[1] else "OFF"], func():
			cb.call()
			st.save_game()
			m.refresh()
			_fill_auto(m, o, st))
		b.custom_minimum_size = Vector2(0, UI.TAP)
		o.content.add_child(b)
	UI.section(o.content, "Pause Auto when...", "Autoplay stops and tells you why, once per thing. Tap Auto to carry on.")
	for rid in AutoRules.RULES:
		var r_id: String = rid
		var rb := UI.button("%s: %s" % [AutoRules.RULES[r_id], "ON" if AutoRules.on(st, r_id) else "OFF"], func():
			AutoRules.toggle(st, r_id)
			st.save_game()
			_fill_auto(m, o, st))
		rb.custom_minimum_size = Vector2(0, UI.TAP)
		rb.add_theme_color_override("font_color", UI.TEAL if AutoRules.on(st, r_id) else UI.DIM)
		o.content.add_child(rb)
	UI.section(o.content, "Potions", "Auto-potion drinks one when your HP drops below this.")
	var prow := UI.hbox(8)
	o.content.add_child(prow)
	var pl := UI.label("", 15, UI.PINK)
	pl.custom_minimum_size = Vector2(70, 0)
	var slider := HSlider.new()
	slider.min_value = 10
	slider.max_value = 70
	slider.step = 5
	slider.value = st.auto_potion_at * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, UI.TAP)
	pl.text = "%d%%" % int(slider.value)
	slider.value_changed.connect(func(v: float):
		st.auto_potion_at = v / 100.0
		pl.text = "%d%%" % int(v)
		st.save_game())
	prow.add_child(slider)
	prow.add_child(pl)
	var ap := UI.button("Auto-potion: %s" % ("ON" if st.auto_potion else "OFF"), func():
		st.auto_potion = not st.auto_potion
		st.save_game()
		_fill_auto(m, o, st))
	ap.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(ap)
	UI.section(o.content, "Skill order", "Auto tries your skills top to bottom and uses the first one that makes sense right now (it won't heal you at full HP, or waste a big hit on a monster that resists it). Turn a skill off to only use it yourself.")
	var order := st.auto_order()
	if order.is_empty():
		o.content.add_child(UI.label("No active skills equipped yet.", 13, UI.DIM))
	for i in order.size():
		var id: String = order[i]
		var s := SkillData.info(id)
		var c := Color(Classes.tag_color(String(s["tags"][0]))) if not Signatures.is_signature(id) else Color(Signatures.COLOR)
		var row := UI.hbox(6)
		o.content.add_child(row)
		var nl := UI.label("%d. %s" % [i + 1, s["name"]], 15, c.lightened(0.3) if not st.skill_auto_off.has(id) else UI.DIM)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		row.add_child(nl)
		var up := UI.button("Up", func(): st.move_priority(id, -1); _fill_auto(m, o, st))
		var dn := UI.button("Down", func(): st.move_priority(id, 1); _fill_auto(m, o, st))
		var tg := UI.button("Auto ON" if not st.skill_auto_off.has(id) else "Auto OFF", func(): st.toggle_skill_auto(id); _fill_auto(m, o, st))
		up.disabled = i == 0
		dn.disabled = i == order.size() - 1
		for b in [up, dn, tg]:
			b.custom_minimum_size = Vector2(0, UI.TAP)
			row.add_child(b)
	var reset := UI.button("Reset to default order", func():
		st.skill_priority = []
		st.skill_auto_off = {}
		st.save_game()
		_fill_auto(m, o, st))
	reset.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(reset)
