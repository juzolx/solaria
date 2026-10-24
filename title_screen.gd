class_name TitleScreen
extends Control
## The first thing you see: an animated dungeon scene, Continue / New hero /
## Heroes / Settings, today's events and tip, and the patch notes.
## Picking a hero closes it and starts the game.

## Something to do right after the scene reloads ({"new": slot, "hc": bool} or {"play": slot}).
static var pending := {}

var m
var t := 0.0
var bg_tex: Texture2D
var bg_next: Texture2D
var bg_fade := 0.0
var bg_index := 0
var bg_keys: Array = []
var hero_tex: Texture2D
var monster: Dictionary = {}
var motes: Array = []
var menu_box: VBoxContainer
var side_box: VBoxContainer
var layout: BoxContainer

func show_for(main_node) -> void:
	m = main_node
	m.add_child(self)
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_fit)
	# Backgrounds: start where your last hero is, then drift through the zones
	var meta := GameState.slot_meta(m.profile.active_slot)
	var start_zone := GameData.zone_index(int(meta.get("floor", 1)))
	for zi in GameData.ZONES.size():
		bg_keys.append((start_zone + zi) % GameData.ZONES.size())
	bg_tex = _bg(bg_keys[0])
	if not meta.is_empty():
		hero_tex = Sprites.portrait(meta.get("appearance", {}), HeroArt.meta_looks(meta))
	else:
		hero_tex = Sprites.portrait({"body": "masc", "skin": 1, "hair": "Short", "hair_color": 1, "eyes": 0, "race": "Human"})
	_pick_monster()
	for i in 40:
		motes.append(_new_mote(true))
	_build()
	if m.sfx:
		m.sfx.play_music("menu")

func _bg(zi: int) -> Texture2D:
	var path := "res://art/bg/zone_%d.png" % zi
	return DarkGrade.texture(path, DarkGrade.SCENE, false)

func _pick_monster() -> void:
	var z: Dictionary = GameData.ZONES[bg_keys[bg_index]]
	var arts: Array = []
	for e in z["enemies"]:
		arts.append(e.get("art", e["id"]))
	monster = Sprites.enemy_by_key(String(arts.pick_random()))

func _new_mote(anywhere := false) -> Dictionary:
	var vs := get_viewport().get_visible_rect().size
	return {"x": randf() * vs.x, "y": randf() * vs.y if anywhere else vs.y + 10.0, "speed": randf_range(12.0, 40.0),
		"size": randf_range(2.0, 5.0), "phase": randf() * TAU, "warm": randf() < 0.6}

func _fit() -> void:
	size = get_viewport().get_visible_rect().size
	if layout:
		layout.vertical = size.x < size.y * 0.95

func _process(delta: float) -> void:
	t += delta
	# Slowly cross-fade to the next zone every 14 seconds
	if t > 14.0 * (bg_index + 1):
		bg_index += 1
		bg_next = _bg(bg_keys[bg_index % bg_keys.size()])
		bg_fade = 0.0
	if bg_next:
		bg_fade += delta / 2.0
		if bg_fade >= 1.0:
			bg_tex = bg_next
			bg_next = null
			_pick_monster()
	for mo in motes:
		mo["y"] -= mo["speed"] * delta
		if mo["y"] < -10.0:
			mo.merge(_new_mote(), true)
	queue_redraw()

func _draw() -> void:
	var vs := size
	draw_rect(Rect2(Vector2.ZERO, vs), UI.BG)
	# Cover the screen with the background and pan it gently
	var ground_y := vs.y * 0.44
	var scale := 1.0
	for tex in [bg_tex, bg_next]:
		if tex == null:
			continue
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		scale = maxf(vs.x / tw, vs.y / th) * 1.12
		var w := tw * scale
		var h := th * scale
		var pan := sin(t * 0.05) * (w - vs.x) * 0.45
		var top := ground_y - 136.0 * scale  # line the background's ground up with the fighters
		top = clampf(top, vs.y - h, 0.0)
		ground_y = top + 136.0 * scale
		var a := 1.0 if tex == bg_tex else bg_fade
		draw_texture_rect(tex, Rect2(Vector2((vs.x - w) / 2.0 + pan, top), Vector2(w, h)), false, Color(0.62, 0.62, 0.68, a))
	# Hero on the left facing a monster on the right
	var unit := maxf(1.0, roundf(minf(vs.y * 0.22, vs.x * 0.2) / (32.0 * Sprites.HD)))
	if hero_tex:
		var hs := Vector2(hero_tex.get_size()) * unit
		var bob := roundf(sin(t * 2.2) * unit * 0.5)
		var feet := float(Sprites.HERO_FOOT - Sprites.PORTRAIT_CROP.position.y) * unit
		draw_texture_rect(hero_tex, Rect2(Vector2(vs.x * 0.30 - hs.x / 2.0, ground_y - feet + bob), hs), false)
	if not monster.is_empty():
		var tex: Texture2D = monster["tex"]
		var ms := Vector2(tex.get_size()) * unit
		var squash := 1.0 + sin(t * 3.0) * 0.03
		var feet: float = float(monster["foot"]) * unit
		var pos := Vector2(vs.x * 0.70 - ms.x / 2.0, ground_y - feet * squash)
		draw_texture_rect(tex, Rect2(pos, Vector2(ms.x, ms.y * squash)), false, Color(0.85, 0.82, 0.9))
	# Dark fade at the bottom so the menu reads well
	var steps := 24
	for i in steps:
		var y := vs.y * (0.45 + 0.55 * i / float(steps))
		draw_rect(Rect2(0, y, vs.x, vs.y / steps + 1.0), Color(UI.BG, 0.04 + 0.8 * pow(i / float(steps), 1.4)))
	# Drifting embers and fireflies
	for mo in motes:
		var c := Color("#feae34") if mo["warm"] else Color("#a4dddb")
		c.a = 0.35 + 0.35 * sin(t * 2.0 + mo["phase"])
		var x: float = mo["x"] + sin(t * 0.8 + mo["phase"]) * 8.0
		draw_rect(Rect2(roundf(x), roundf(mo["y"]), mo["size"], mo["size"]), c)

# =====================================================================
# Menu
# =====================================================================

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var col := UI.vbox(10)
	margin.add_child(col)
	var title := UI.label("SOLARIA", 64, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color("#3a1f05"))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(title)
	var sub := UI.label("A dungeon of myths and monsters", 15, UI.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(gap)

	layout = BoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	col.add_child(layout)
	var menu_panel := UI.panel(Color(UI.PANEL, 0.92), UI.GOLD, 10, 16, 2)
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(menu_panel)
	menu_box = UI.vbox(8)
	menu_panel.add_child(menu_box)
	var side_panel := UI.panel(Color(UI.PANEL, 0.92), UI.BORDER, 10, 14, 1)
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(side_panel)
	side_box = UI.vbox(8)
	side_panel.add_child(side_box)
	_fit()
	_fill_menu()
	_fill_side()
	var ver := UI.label("v" + PatchNotes.VERSION, UI.FONT_CAPTION, UI.DIM)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(ver)

func _fill_menu() -> void:
	OnlineUI.clear(menu_box)
	var p: Profile = m.profile
	var meta := GameState.slot_meta(p.active_slot)
	if meta.is_empty():
		for n in range(1, GameData.MAX_HEROES + 1):
			if GameState.has_slot(n):
				p.active_slot = n
				meta = GameState.slot_meta(n)
				break
	var town_l := UI.label("%s  ·  %s  ·  %d / %d heroes" % [p.town_name(p.town).to_upper(), "HARDCORE" if p.town_hardcore(p.town) else "REGULAR", GameState.town_heroes(p.town), p.slots_open()], 12, UI.GOLD)
	town_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	town_l.tooltip_text = "The town you're in. Switch or found another from Towns."
	menu_box.add_child(town_l)
	if not meta.is_empty():
		var cont := UI.primary("Continue", func(): close_and(func(): m.play_slot(p.active_slot)), UI.GOLD)
		cont.custom_minimum_size = Vector2(0, 52)
		cont.add_theme_font_size_override("font_size", 20)
		menu_box.add_child(cont)
		menu_box.add_child(_hero_line(meta))
	# Juzo: no "New hero" here. A town's first hero comes with founding it; later
	# heroes are recruited at the Inn when a slot opens.
	if meta.is_empty():
		var found := UI.primary("Found your town", func(): FoundTown.new().show_for(m, p.town), UI.GREEN)
		found.custom_minimum_size = Vector2(0, 48)
		menu_box.add_child(found)
	var row := UI.hbox(8)
	menu_box.add_child(row)
	for entry in [["Heroes", func(): HeroSelect.new().show_for(m, self)], ["Towns", func(): TownSelect.new().show_for(m, self)], ["Settings", func(): SettingsMenu.new().show_for(m)],
			["Guide", func(): GuideBook.open_book(m, "")]]:
		var b := UI.button(entry[0], entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 36)
		row.add_child(b)
	if OS.get_name() in ["Windows", "macOS", "Linux"]:
		var q := UI.button("Quit", func(): m.get_tree().quit())
		menu_box.add_child(q)

func _hero_line(meta: Dictionary) -> Control:
	var row := UI.hbox(10)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(meta.get("appearance", {}), HeroArt.meta_looks(meta))
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(64, 64)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var info := UI.rich(UI.FONT_CAPTION)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = HeroSelect.describe(meta)
	row.add_child(info)
	return row

func _fill_side() -> void:
	OnlineUI.clear(side_box)
	# The new update's banner
	if m.profile.notes_seen != PatchNotes.VERSION:
		var up := UI.panel(Color("#2a1a2e"), Color("#e8b14a"), 8, 10, 2)
		side_box.add_child(up)
		var ut := UI.rich(UI.FONT_CAPTION)
		ut.text = "[color=#e8b14a][b]%s[/b][/color]  [color=%s]v%s[/color]\nNew class rules with God classes, pets from region nests, three currencies, the Legendary Wheel and safer saves." % [String(PatchNotes.NOTES[0]["name"]).to_upper(), UI.hex(UI.DIM), PatchNotes.VERSION]
		up.add_child(ut)
		var pulse := up.create_tween().set_loops()
		pulse.tween_property(up, "modulate", Color(1.15, 1.1, 0.95), 0.9)
		pulse.tween_property(up, "modulate", Color(1, 1, 1), 0.9)
	var wn := UI.button("What's new in v%s" % PatchNotes.VERSION, func(): WhatsNew.new().show_for(m))  # 2.1 G9
	wn.custom_minimum_size = Vector2(0, UI.TAP)
	side_box.add_child(wn)
	var week := Realms.realm_of_week()
	var wk := UI.rich(UI.FONT_CAPTION)
	wk.text = "[color=%s]REALM OF THE WEEK[/color]\n[color=%s][b]%s[/b][/color]: double reputation and better loot." % [UI.hex(UI.DIM), Realms.info(week)["color"], Realms.realm_name(week)]
	side_box.add_child(wk)
	var ev := GameData.active_events()
	if not ev.is_empty():
		var names := []
		for id in ev:
			names.append("[color=#f472b6][b]%s[/b][/color]: %s" % [GameData.EVENTS[id]["name"], GameData.EVENTS[id]["text"]])
		var banner := UI.rich(UI.FONT_CAPTION)
		banner.text = "[color=#f472b6]EVENT NOW[/color]\n" + "\n".join(names)
		side_box.add_child(banner)
	var tip := UI.rich(UI.FONT_CAPTION)
	tip.text = "[color=%s]TIP OF THE DAY[/color]\n%s" % [UI.hex(UI.DIM), PatchNotes.tip_of_the_day()]
	side_box.add_child(tip)
	side_box.add_child(UI.heading("What's new"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_box.add_child(scroll)
	var notes := UI.rich(UI.FONT_CAPTION)
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lines := []
	for n in PatchNotes.NOTES:
		lines.append("[color=#e8b14a][b]%s  %s[/b][/color]" % [n["version"], n["name"]])
		for l in n["lines"]:
			lines.append("  - " + l)
		lines.append("")
	notes.text = "\n".join(lines)
	scroll.add_child(notes)
	m.profile.notes_seen = PatchNotes.VERSION
	m.profile.save()

func refresh_menu() -> void:
	_fill_menu()

func close_and(action: Callable) -> void:
	queue_free()
	action.call()
