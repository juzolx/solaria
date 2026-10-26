class_name HeroSelect
extends Overlay
## Your roster in this town: up to 9 heroes (Profile.slots_open: all 9 for now).
## Play, delete, or make a new hero in an open slot.
## Any 3 Regular heroes can go down together (you plus 2 companions).

var m
var title_screen

func show_for(main_node, from_title = null) -> void:
	m = main_node
	title_screen = from_title
	open(m, "Heroes of %s" % m.profile.town_name(m.profile.town), 860.0)
	var p: Profile = m.profile
	var note := UI.label(p.roster_line(), UI.FONT_BODY, UI.DIM)
	UI.tip(note, "Pick any 3 Regular heroes to go down together from the Party page. Heroes in this town share its stash and skill book; the Codex is shared by every town.")   # Fable r2: one line, the rest on a tap
	content.add_child(note)
	var towns_b := UI.button("Switch town...", func(): close(); TownSelect.new().show_for(m, title_screen))
	towns_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(towns_b)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	content.add_child(row)
	var shown_empty := false
	for n in range(1, GameData.MAX_HEROES + 1):
		var open_slot := n <= p.slots_open()
		if GameState.has_slot(n):
			row.add_child(_card(n, true))
		elif open_slot and not shown_empty:
			shown_empty = true   # one empty slot is enough to make a hero in
			row.add_child(_card(n, true))

## One line about a hero for menus: name, level, class, mode and depth.
static func describe(meta: Dictionary) -> String:
	var hc: bool = meta.get("hardcore", false)
	var mode := ("[color=%s]Hardcore[/color]" % UI.hex(UI.RED)) if hc else ""   # Fable r4 #16: Regular says nothing (the town line has the mode)
	var nm: String = str(meta.get("name", ""))
	if nm == "":
		nm = "Hero"
	return "[b]%s[/b]  %s\nLv %d %s %s\nFloor %d, %s  [color=%s](best %d)[/color]" % [nm, mode, int(meta.get("level", 1)),
		Races.current(str(meta.get("appearance", {}).get("race", "Human"))), str(meta.get("title", "")), int(meta.get("floor", 1)),
		str(meta.get("zone", "")), UI.hex(UI.DIM), int(meta.get("best", 1))]

func _card(n: int, open_slot: bool) -> PanelContainer:
	var meta := GameState.slot_meta(n)
	var active: bool = m.profile.active_slot == n and not meta.is_empty()
	var card := UI.panel(UI.INSET, UI.GOLD if active else UI.BORDER, 10, 10, 2 if active else 1)
	card.custom_minimum_size = Vector2(minf(400.0, get_viewport().get_visible_rect().size.x - 64.0), 0)
	var h := UI.hbox(10)
	card.add_child(h)
	if meta.is_empty():
		var one := UI.wrap("Slot %d · %s" % [n, "empty: recruit a hero at the Inn" if open_slot else "locked: " + m.profile.slot_lock_note(n)], UI.FONT_BODY, UI.DIM)
		one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(one)
		return card
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(meta.get("appearance", {}), HeroArt.meta_looks(meta))
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 2   # never 1x: 2x in the slot list
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(pic)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.label("Slot %d" % n, UI.FONT_CAPTION, UI.DIM))
	if m.started and m.state != null and n in m.state.party_slots:
		top.add_child(UI.chip("In team", UI.GREEN, UI.FONT_CAPTION))
	var info := UI.rich(UI.FONT_BODY)
	info.text = describe(meta)
	v.add_child(info)
	var row := UI.hbox(6)
	v.add_child(row)
	if m.started and active:   # Fable r4 #4: the hero you're playing is a chip, not a dead gold button
		var now := UI.chip("Playing now", UI.DIM, UI.FONT_BODY)
		now.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # Fable r5 #11: a tag, not a wide text box
		row.add_child(now)
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gap)
	else:
		var play := UI.primary("Play", func(): _play(n), UI.GOLD)
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(play)
	var del := UI.button("Delete", func():
		m.confirm("Delete %s?" % str(meta.get("name", "this hero")), "This hero, their gear and gold are gone for good. The Codex and the shared stash are kept.", "Delete hero", func():
			if m.started and active:
				m.reset_save()
				return
			GameState.delete_slot(n)
			close()
			if title_screen and is_instance_valid(title_screen):
				title_screen.refresh_menu()
			HeroSelect.new().show_for(m, title_screen)))
	del.add_theme_color_override("font_color", UI.DIM)
	del.custom_minimum_size = Vector2(96, UI.TAP)   # Fable r5 #11: body size, a real target (the confirm guards it)
	row.add_child(del)
	return card

func _play(n: int) -> void:
	close()
	if m.started:
		TitleScreen.pending = {"play": n}
		m.back_to_title()
	else:
		if title_screen and is_instance_valid(title_screen):
			title_screen.queue_free()
		m.play_slot(n)
