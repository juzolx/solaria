class_name SkillsTab
extends VBoxContainer
## Hero › Skills: the Skill Book. Every skill you've found from ability
## stones. Equip 3 active and 5 passive (slots open as you level), rank them
## up with duplicate stones, and craft any skill with dust.

var main
var state: GameState
var slot_row_a: HBoxContainer
var slot_row_p: HBoxContainer
var sig_row: HBoxContainer
var filter_pick: OptionButton   # the filter's state; the page shows it as chips (filter_chips)
var filter_chips: HFlowContainer
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
	# Fable r1 #13: no literal dots (dots mean cut-off text); the page is slots + book, a tap opens the rest
	dust_label = UI.label("", UI.FONT_BODY, Color("#c4b5fd"))
	dust_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dust_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(dust_label)
	head.add_child(UI.button("Autoplay", func(): auto_battle_popup(main)))
	head.add_child(UI.button("Craft", _craft_popup))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var book := UI.vbox(8)
	book.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(book)
	book.add_child(UI.heading("Active"))
	slot_row_a = UI.hbox(4)
	book.add_child(slot_row_a)
	sig_row = UI.hbox(4)
	book.add_child(sig_row)
	book.add_child(UI.heading("Passive"))
	slot_row_p = UI.hbox(4)
	book.add_child(slot_row_p)

	filter_pick = OptionButton.new()
	for f in FILTERS:
		filter_pick.add_item(f)
	for tag in Classes.TAGS:
		filter_pick.add_item(tag)
	filter_pick.item_selected.connect(func(_i): shown = ""; refresh())
	filter_pick.visible = false
	add_child(filter_pick)
	# Fable r2 #7: the chips wrap (every filter in sight), like the sub-tab chips
	filter_chips = HFlowContainer.new()
	filter_chips.add_theme_constant_override("h_separation", 6)
	filter_chips.add_theme_constant_override("v_separation", 6)
	filter_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in filter_pick.item_count:
		var c := UI.button(filter_pick.get_item_text(i), func():
			filter_pick.select(i)
			shown = ""
			refresh())
		c.focus_mode = Control.FOCUS_NONE
		filter_chips.add_child(c)
	# 0.13+ (Juzo): the skill book as cards, like the bag: icon, name, rank pips, rarity frame
	book.add_child(UI.heading("Skill book"))
	book.add_child(filter_chips)
	cards = GridContainer.new()
	cards.columns = 4
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	book.add_child(cards)
	empty_note = UI.label("", UI.FONT_BODY, UI.DIM)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	book.add_child(empty_note)
	var box := UI.panel(UI.INSET, UI.EMPTY, 8, 8, 1)
	box.visible = false   # the detail and its buttons are copied into the tap popup (_popup)
	add_child(box)
	detail = UI.rich(UI.FONT_BODY)
	detail.custom_minimum_size = Vector2(0, 62)
	box.add_child(detail)
	var row := UI.hbox(6)
	row.visible = false
	add_child(row)
	equip_button = UI.primary("Equip", _toggle_equip, UI.GREEN)
	sell_button = UI.button("Sell", func():
		if selected == "":
			return
		var sid := selected
		main.confirm("Sell %s for dust?" % SkillData.skill_name(sid), "You get %d dust to rank up your other skills, and this one is gone from your book (you'd have to find or craft it again)." % state.skill_sell_price(sid), "Sell it", func():
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

func _slot_button(id: String, open: bool, need: int, active: bool, index := -1) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, UI.TAP)
	b.clip_text = true
	b.add_theme_font_size_override("font_size", UI.MIN_FONT)
	if not open:
		b.text = "Lv %d ›" % need   # Fable r5 #19: a tap says when it opens
		UI.why(b, "Opens at level %d." % need, false)
		b.add_theme_color_override("font_color", UI.DIM)
		return b
	# Next update: drag a skill card onto a slot to put it there; drag a slotted skill back to the book to take it off
	Drag.wire(b, {} if id == "" else {"kind": "skill", "id": id, "from_slot": true}, null if id == "" else SkillIcons.for_tag(String(SkillData.info(id)["tags"][0])),
		func(d): return d.get("kind", "") == "skill" and SkillData.is_active(str(d["id"])) == active and state.skill_rank(str(d["id"])) > 0,
		func(d):
			state.equip_skill(str(d["id"]), index)
			main.sfx.play("equip")
			shown = ""
			refresh())
	if id == "":
		b.text = "Empty"   # Fable r5 #19 (was "+"): a dim slate block that says what it is
		b.add_theme_color_override("font_color", UI.DIM)
		_face(b, UI.PANEL, UI.EMPTY)
		b.pressed.connect(func():
			filter_pick.select(1 if active else 2)
			shown = ""
			refresh())
		return b
	var s := SkillData.info(id)
	b.text = "%s
Rank %d" % [s["name"], state.skill_rank(id)]
	b.icon = SkillIcons.for_tag(String(s["tags"][0]))  # 0.13+: slots show the skill's icon
	b.add_theme_constant_override("icon_max_width", 32)   # native size: crisp pixels
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	if active:   # interface pass (approved mockup 04): the three active slots are big, icon at 2x on top
		b.icon = UiIcons.big(b.icon, 64)
		b.add_theme_constant_override("icon_max_width", 64)
		b.custom_minimum_size = Vector2(0, 104)
	else:   # five passive slots share a phone row: icon on top, just the name under it
		b.text = String(s["name"])
		b.custom_minimum_size = Vector2(0, 62)
	_face(b, UiSkin.SLATE, UI.GOLD_DULL if id == selected else UI.EDGE)
	b.add_theme_color_override("font_color", Color("#f4e6c4"))
	b.tooltip_text = SkillData.describe(id, state.skill_rank(id))
	b.pressed.connect(func():
		selected = id
		_popup())
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
	# Fable r5 #19: tag chips only for tags you own a skill in (All / Active / Passive / Equipped always)
	var have_tags := {}
	for sid in state.skill_book:
		if SkillData.SKILLS.has(sid):
			for tg in SkillData.info(sid)["tags"]:
				have_tags[String(tg)] = true
	for i in filter_chips.get_child_count():
		var c := filter_chips.get_child(i) as Button
		var on := i == filter_pick.selected
		c.visible = i < 4 or on or have_tags.has(filter_pick.get_item_text(i))
		_face(c, UiSkin.SLATE if on else UI.PANEL, UI.GOLD_DULL if on else UI.EMPTY)
		c.add_theme_color_override("font_color", UI.GOLD if on else UI.DIM)
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
		sb.clip_text = true
		sb.add_theme_font_size_override("font_size", UI.FONT_BODY)
		sb.text = "Signature: %s" % (SkillData.skill_name(state.sig_slot) if state.sig_slot != "" else "(none)")
		sb.custom_minimum_size = Vector2(0, UI.TAP)
		_face(sb, UiSkin.SLATE, UI.GOLD_DULL)   # interface pass: the signature slot is gold-edged
		sb.add_theme_color_override("font_color", UI.GOLD)
		sb.pressed.connect(func(): main.show_tab(0, 1))
		sig_row.add_child(sb)
	for i in 3:
		slot_row_a.add_child(_slot_button(state.active_slots[i], i < state.active_slot_count(), int(SkillData.ACTIVE_SLOTS_AT[i]), true, i))
	for i in 5:
		slot_row_p.add_child(_slot_button(state.passive_slots[i], i < state.passive_slot_count(), int(SkillData.PASSIVE_SLOTS_AT[i]), false, i))
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
	b.add_theme_constant_override("icon_max_width", 32)   # native size: crisp pixels
	b.clip_text = true
	b.add_theme_font_size_override("font_size", UI.FONT_BODY)
	b.text = "%s\n%s" % [s["name"], "Rank %d" % r if r > 0 else "Not learned"]   # (the font has no ● ○)
	var rc := Color(SkillData.RARITY_COLORS[int(s["rarity"])])
	var eq := state.is_skill_equipped(id)
	var sel := id == selected
	# interface pass: a slate card; its edge says rarity, green = equipped, gold = picked
	_face(b, UiSkin.SLATE if sel else UI.PANEL, UI.GOLD_DULL if sel else (UI.GREEN if eq else rc))
	b.add_theme_color_override("font_color", rc.lightened(0.35))
	b.tooltip_text = SkillData.describe(id, maxi(1, r))
	Drag.wire(b, {"kind": "skill", "id": id}, SkillIcons.for_tag(String(s["tags"][0])),
		func(d): return d.get("kind", "") == "skill" and d.get("from_slot", false),
		func(d):
			state.unequip_skill(str(d["id"]))
			main.sfx.play("click")
			shown = ""
			refresh())
	b.pressed.connect(func():
		selected = id
		shown = ""
		refresh()
		_popup())
	return b

## Fable r1 #13: a tapped skill opens like an item: what it does, then Equip / Rank up / Sell.
func _popup() -> void:
	if selected == "" or not SkillData.SKILLS.has(selected):
		return
	_show_detail()
	var s := SkillData.info(selected)
	var o := Overlay.new().open(main, String(s["name"]), 560.0, Color(SkillData.RARITY_COLORS[int(s["rarity"])]))
	var d := UI.rich(UI.FONT_BODY)
	d.text = detail.text
	o.content.add_child(d)
	o.foot.visible = true
	for src: Button in [equip_button, craft_button, sell_button]:
		var b := UI.primary(src.text, func(): o.close(); src.pressed.emit(), UI.GREEN) if src == equip_button else UI.button(src.text, func(): o.close(); src.pressed.emit())
		UI.why(b, String(src.get_meta("why", "")))
		b.tooltip_text = src.tooltip_text
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = UI.TAP
		o.foot.add_child(b)

func _show_detail() -> void:
	if selected == "" or not SkillData.SKILLS.has(selected):
		detail.text = "[color=%s]Tap a skill to see it, tap it again to equip or unequip. Skills that share a tag with your class (%s) hit %d%% harder.[/color]" % [
			UI.hex(UI.DIM), ", ".join(state.class_info().get("tags", [])), int(Classes.AFFINITY_POWER * 100)]
		for nb in [equip_button, craft_button, sell_button]:
			UI.why(nb, "Tap a skill in your book first.")
		craft_button.text = "Rank up"
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
	UI.why(equip_button, "Craft it first: it isn't in your book yet." if r <= 0 else "")
	var block := state.skill_sell_block(selected)
	sell_button.text = "Sell (%d dust)" % state.skill_sell_price(selected) if state.skill_book.has(selected) else "Sell"
	sell_button.set_meta("tip0", "Sell it for dust to rank up your other skills (it leaves your book)")
	UI.why(sell_button, block)
	equip_button.text = "Unequip" if state.is_skill_equipped(selected) else "Equip"
	if r >= SkillData.MAX_RANK:
		craft_button.text = "Max rank"
		UI.why(craft_button, "It's at its highest rank.")
	else:
		var cost := SkillData.craft_cost(selected, r)
		craft_button.text = "%s (%d dust)" % ["Rank up" if r > 0 else "Craft", cost]
		UI.why(craft_button, "" if state.dust >= cost else "Need %d more dust." % (cost - state.dust))

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
	o.content.add_child(UI.label("You have %d dust. Dust comes from bosses, rare monsters, vaults and stones of skills you have already maxed." % state.dust, UI.FONT_BODY, UI.DIM))
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
	o.content.add_child(UI.label("Double-tap a skill to craft it.", UI.FONT_BODY, UI.DIM))

## Autoplay settings: whether the fight runs by itself, and what it does for you.
static func auto_battle_popup(m) -> void:
	var st: GameState = m.state
	var o := Overlay.new().open(m, "Autoplay", 560.0, UI.TEAL)
	_fill_auto(m, o, st)

static func _fill_auto(m, o: Overlay, st: GameState) -> void:
	for c in o.content.get_children():   # the title row lives above the scroll now (Fable r1 #3)
		c.queue_free()
	# The big switch
	var mode := UI.primary("Autoplay: ON  (the fight runs by itself)" if st.autoplay else "Autoplay: OFF  (you take every turn)", func():
		st.autoplay = not st.autoplay
		st.save_game()
		m.refresh()
		_fill_auto(m, o, st), UI.TEAL if st.autoplay else UI.RED)
	mode.custom_minimum_size = Vector2(0, UI.TAP + 8)
	o.content.add_child(mode)
	var note := UI.label("With Autoplay off, nothing happens until you act: tap Attack (or the enemy) to take a turn, and use your skills when you choose.", UI.FONT_BODY, UI.DIM)
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
	# 2.1: going home, stopping, potions and the loot filter live in one panel
	UI.section(o.content, "Auto-dive", "When Auto heads home or stops, potions and elixirs, and the loot filter.")
	var dive := UI.primary("Auto-dive settings", func():
		o.close()
		AutoDivePanel.new().show_for(m), UI.TEAL)
	dive.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(dive)
	var lfb := UI.button("Loot filter: %s" % LootRules.summary(st), func():
		o.close()
		LootFilter.new().show_for(m))
	lfb.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(lfb)
	UI.section(o.content, "Skill order", "Auto tries your skills top to bottom and uses the first one that makes sense right now (it won't heal you at full HP, or waste a big hit on a monster that resists it). Turn a skill off to only use it yourself.")
	var order := st.auto_order()
	if order.is_empty():
		o.content.add_child(UI.label("No active skills equipped yet.", UI.FONT_BODY, UI.DIM))
	for i in order.size():
		var id: String = order[i]
		var s := SkillData.info(id)
		var c := Color(Classes.tag_color(String(s["tags"][0]))) if not Signatures.is_signature(id) else Color(Signatures.COLOR)
		var row := UI.hbox(6)
		o.content.add_child(row)
		var nl := UI.label("%d. %s" % [i + 1, s["name"]], UI.FONT_BODY, c.lightened(0.3) if not st.skill_auto_off.has(id) else UI.DIM)
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

## Interface pass: a skill button wears the slate block look (normal, hover, pressed, disabled).
func _face(b: Button, fill: Color, edge: Color) -> void:
	b.add_theme_stylebox_override("normal", UiSkin.bevel(fill, edge, 4))
	b.add_theme_stylebox_override("hover", UiSkin.bevel(UiSkin.SLATE, UI.GOLD_DULL, 4))
	b.add_theme_stylebox_override("pressed", UiSkin.bevel(fill, edge, 4, true))
	b.add_theme_stylebox_override("disabled", UiSkin.bevel(UI.PANEL, UI.EMPTY, 4))
