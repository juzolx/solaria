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
	var count := 0
	for n in range(1, GameData.MAX_HEROES + 1):
		if GameState.has_slot(n):
			count += 1
	var note := UI.label("Roster %d / %d  ·  %d slots open. Pick any 3 Regular heroes to go down together from the Party page. Heroes in this town share its stash and skill book; the Codex is shared by every town." % [count, GameData.MAX_HEROES, p.slots_open()], 13, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	var towns_b := UI.button("Switch town...", func(): close(); TownSelect.new().show_for(m, title_screen))
	towns_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(towns_b)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	content.add_child(row)
	var shown_empty := false
	var locked: Array = []
	for n in range(1, GameData.MAX_HEROES + 1):
		var open_slot := n <= p.slots_open()
		if GameState.has_slot(n):
			row.add_child(_card(n, true))
		elif open_slot and not shown_empty:
			shown_empty = true   # one empty slot is enough to make a hero in
			row.add_child(_card(n, true))
		elif not open_slot:
			locked.append(n)
	if not locked.is_empty():
		var n0: int = locked[0]
		var more := UI.label(p.slot_lock_note(n0) + ((" %d more locked." % (locked.size() - 1)) if locked.size() > 1 else ""), 12, UI.DIM)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(more)

## One line about a hero for menus: name, level, class, mode and depth.
static func describe(meta: Dictionary) -> String:
	var hc: bool = meta.get("hardcore", false)
	var mode := "[color=#f87171]HARDCORE[/color]" if hc else "[color=#4ade80]Regular[/color]"
	var nm: String = str(meta.get("name", ""))
	if nm == "":
		nm = "Hero"
	return "[b]%s[/b]  %s\nLv %d %s %s\nFloor %d, %s  [color=%s](best %d)[/color]" % [nm, mode, int(meta.get("level", 1)),
		str(meta.get("appearance", {}).get("race", "Human")), str(meta.get("title", "")), int(meta.get("floor", 1)),
		str(meta.get("zone", "")), UI.hex(UI.DIM), int(meta.get("best", 1))]

func _card(n: int, open_slot: bool) -> PanelContainer:
	var meta := GameState.slot_meta(n)
	var active: bool = m.profile.active_slot == n and not meta.is_empty()
	var card := UI.panel(UI.INSET, UI.GOLD if active else UI.BORDER, 10, 10, 2 if active else 1)
	card.custom_minimum_size = Vector2(minf(400.0, get_viewport().get_visible_rect().size.x - 64.0), 0)
	var h := UI.hbox(10)
	card.add_child(h)
	if meta.is_empty():
		var v0 := UI.vbox(6)
		v0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v0)
		v0.add_child(UI.label("SLOT %d" % n, 11, UI.DIM))
		v0.add_child(UI.label("Empty slot" if open_slot else "Locked", 14, UI.TEXT if open_slot else UI.DIM))
		v0.add_child(UI.wrap("Recruit a new hero at the Inn in town." if open_slot else m.profile.slot_lock_note(n), 12, UI.DIM))
		return card
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(meta.get("appearance", {}), meta.get("looks", {}))
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(pic)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.label("SLOT %d" % n, 11, UI.DIM))
	if m.started and m.state != null and n in m.state.party_slots:
		top.add_child(UI.chip("IN TEAM", UI.GREEN, 10))
	var info := UI.rich(13)
	info.text = describe(meta)
	v.add_child(info)
	var row := UI.hbox(6)
	v.add_child(row)
	var play := UI.primary("Playing" if (m.started and active) else "Play", func(): _play(n), UI.GOLD)
	play.disabled = m.started and active
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
	del.add_theme_color_override("font_color", UI.RED)
	del.custom_minimum_size = Vector2(0, UI.TAP)
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
