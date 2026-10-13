class_name HeroSelect
extends Overlay
## Your heroes: up to 3 slots. The 2nd opens when any hero reaches floor 25,
## the 3rd at floor 50. Play, delete, or make a new hero in an empty slot.

var m
var title_screen

func show_for(main_node, from_title = null) -> void:
	m = main_node
	title_screen = from_title
	open(m, "Your heroes", 860.0)
	content.add_child(UI.label("Switch heroes any time from Menu > Title screen. Regular heroes share the stash; the Codex is shared by everyone.", 13, UI.DIM))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 12)
	content.add_child(row)
	var p: Profile = m.profile
	for n in range(1, GameData.MAX_HEROES + 1):
		row.add_child(_card(n, n <= p.slots_open()))

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
	var card := UI.panel(UI.INSET, UI.GOLD if active else UI.BORDER, 10, 12, 2 if active else 1)
	card.custom_minimum_size = Vector2(250, 250)
	var v := UI.vbox(8)
	card.add_child(v)
	v.add_child(UI.label("SLOT %d" % n, 11, UI.DIM))
	if meta.is_empty():
		var msg := "Empty slot" if open_slot else "Locked: any hero must reach floor %d" % int(GameData.SLOT_UNLOCKS[n - 1])
		var l := UI.label(msg, 14, UI.TEXT if open_slot else UI.DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(gap)
		var b := UI.primary("New hero", func(): close(); NewHeroPicker.new().show_for(m, n), UI.GREEN)
		b.disabled = not open_slot
		b.custom_minimum_size = Vector2(0, 40)
		v.add_child(b)
		return card
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(meta.get("appearance", {}))
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(96, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(pic)
	var info := UI.rich(13)
	info.text = describe(meta)
	v.add_child(info)
	var row := UI.hbox(6)
	v.add_child(row)
	var play := UI.primary("Playing" if (m.started and active) else "Play", func(): _play(n), UI.GOLD)
	play.disabled = m.started and active
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
