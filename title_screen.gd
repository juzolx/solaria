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
## Interface pass (Juzo: "the background images... we can't do better?"): the title stands in the
## real dungeon room of your hero's floor (the fight's own HallsScene), your hero at 3x in front,
## a monster of the zone at the far wall. key_art: a portrait painting instead (mockup to compare).
static var key_art_path := ""
var halls: HallsScene
var room_state: GameState
var room_h := 0.0     # the scene's height: from the top of the screen down to the menu
var key_tex: Texture2D

func show_for(main_node) -> void:
	m = main_node
	m.add_child(self)
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_fit)
	# Backgrounds: start where your last hero is, then drift through the zones
	var meta := GameState.slot_meta(m.profile.active_slot)
	GameData.realm_order = meta.get("realm_order", [])  # Fable code r1 #6: no hero is loaded here, so the static may hold the last one's realms
	var start_zone := GameData.zone_index(int(meta.get("floor", 1)))
	for zi in GameData.ZONES.size():
		bg_keys.append((start_zone + zi) % GameData.ZONES.size())
	bg_tex = _bg(bg_keys[0])
	if key_art_path != "":
		var img := Image.load_from_file(key_art_path)
		if img:
			key_tex = ImageTexture.create_from_image(img)
	halls = HallsScene.new()
	room_state = GameState.new()
	room_state.floor_num = maxi(1, int(meta.get("floor", 1)))
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
	var z: Dictionary = GameData.ZONES[bg_keys[bg_index % bg_keys.size()]]  # bg_index keeps counting up while the title sits open
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

## The shared 3D room is lent to whichever view draws; hand it back loose when the title goes,
## or it is freed with us while the fight view's deferred move still points at it (tour crash).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and HallsScene.shared != null and is_instance_valid(HallsScene.shared) and HallsScene.shared.get_parent() == self:
		remove_child(HallsScene.shared)
		HallsScene.shared.remove_meta("moving")

var _drawn_at := -1.0
var _things: Array = []   # the room's scenery, far to near (rebuilt when the room changes)
var _things_key := "-"

func _process(delta: float) -> void:
	t += delta
	# Slowly cross-fade to the next zone every 14 seconds
	if halls == null and t > 14.0 * (bg_index + 1):
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
	if m != null and (m.profile.battery_saver or m.profile.reduce_motion):
		if t - _drawn_at < 1.0 / 30.0:
			return
	_drawn_at = t
	queue_redraw()

func _draw() -> void:
	var vs := size
	draw_rect(Rect2(Vector2.ZERO, vs), UI.BG)
	if halls != null:
		_draw_scene(vs)
		return
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
		var feet := float(Sprites.PORTRAIT_FOOT) * unit
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

## The room (or the key art), the hero, the monster, motes and a fade into the menu.
func _draw_scene(vs: Vector2) -> void:
	var sh := maxf(room_h, vs.y * 0.34)
	var sz := Vector2(vs.x, sh)
	if key_tex:
		# whole pixels: the painting is 168 px wide, 3x on a 504 px phone
		var k := maxf(1.0, floorf(vs.x / float(key_tex.get_width())))
		var kw := key_tex.get_width() * k
		var kh := key_tex.get_height() * k
		# the painting's focus (its lower part: the hero, the gate) sits just above the menu
		var ky := minf(0.0, roundf(sh - kh * 0.9))
		draw_texture_rect(key_tex, Rect2(roundf((vs.x - kw) / 2.0), ky, kw, kh), false)
	else:
		halls.t = t
		halls.build(room_state, sz)
		halls.draw_shell(self, sz)
		halls.draw_doors(self, null, {}, UI.game_font())
		if _things_key != halls.key:
			_things_key = halls.key
			_things = halls.scenery()
			_things.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
		for th in _things:
			halls.draw_scenery(self, th)
		# a monster of the zone waits by the far wall, a whole-pixel 2x
		if not monster.is_empty():
			var mt: Texture2D = monster["tex"]
			var mu := 2.0 if mt.get_height() <= 96 else 1.0
			var ms := Vector2(mt.get_size()) * mu
			var feet_y := halls.proj(0.0, HallsScene.FLOOR_Y, 4.4).y
			var squash := 1.0 + sin(t * 3.0) * 0.02
			var mpos := Vector2(roundf(vs.x * 0.5 - ms.x / 2.0 + 70.0), roundf(feet_y - float(monster["foot"]) * mu * squash))
			draw_texture_rect(mt, Rect2(mpos, Vector2(ms.x, ms.y * squash)), false, Color(0.55, 0.52, 0.62))
		halls.vignette(self, sz)
		# your hero in front at 3x, on the floor near you
		if hero_tex:
			var u := 3.0
			var hs := Vector2(hero_tex.get_size()) * u
			var floor_y := minf(halls.proj(0.0, HallsScene.FLOOR_Y, 2.1).y, sz.y - 6.0)
			var feet := float(Sprites.PORTRAIT_FOOT + 1) * u   # the boots' bottom edge on the shadow's centre line
			var bob := roundf(sin(t * 2.2) * 0.6) * u
			var pos := Vector2(roundf(vs.x * 0.5 - hs.x / 2.0 - 40.0), roundf(floor_y - feet + bob))
			draw_set_transform(Vector2(pos.x + hs.x / 2.0, floor_y), 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, hs.x * 0.22, Color(0, 0, 0, 0.45))
			draw_set_transform(Vector2.ZERO)
			draw_texture_rect(hero_tex, Rect2(pos, hs), false)
	# the scene melts into the menu
	var steps := 12
	for i in steps:
		var f := i / float(steps)
		var y := sz.y - 120.0 + 120.0 * f
		draw_rect(Rect2(0, y, vs.x, 120.0 / steps + 1.0), Color(UI.BG, 0.85 * f))
	draw_rect(Rect2(0, sz.y, vs.x, vs.y - sz.y), UI.BG)
	for mo in motes:
		var c := Color("#feae34") if mo["warm"] else Color("#a4dddb")
		c.a = 0.3 + 0.3 * sin(t * 2.0 + mo["phase"])
		var x: float = mo["x"] + sin(t * 0.8 + mo["phase"]) * 8.0
		draw_rect(Rect2(roundf(x), roundf(mo["y"]), 2, 2), c)

# =====================================================================
# Menu
# =====================================================================

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 22 + int(UI.safe_top))   # Fable r2 #13
	margin.add_theme_constant_override("margin_bottom", 22 + int(UI.safe_bottom))
	add_child(margin)
	var col := UI.vbox(10)
	margin.add_child(col)
	var mark := Control.new()   # interface pass (approved mockup 17): the sun-disc mark above the name
	mark.custom_minimum_size = Vector2(0, 76)
	mark.draw.connect(func(): _draw_sun(mark))
	col.add_child(mark)
	var title := UI.label("SOLARIA", UI.FONT_DISPLAY * 2, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", UiSkin.SOOT)   # an ink outline, like the sprites
	title.add_theme_constant_override("outline_size", 10)
	col.add_child(title)
	var sub := UI.label("A dungeon of myths and monsters", UI.FONT_BODY, UI.TEXT)
	sub.add_theme_color_override("font_outline_color", UiSkin.SOOT)   # Fable r5 #17: readable over the door art
	sub.add_theme_constant_override("outline_size", 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.custom_minimum_size = Vector2(0, 150)   # room for the hero standing in the scene
	col.add_child(gap)

	layout = BoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	col.add_child(layout)
	layout.resized.connect(func():
		room_h = layout.global_position.y - global_position.y + 30.0
		queue_redraw())
	var menu_panel := PanelContainer.new()
	menu_panel.add_theme_stylebox_override("panel", UiSkin.frame(Color(UI.PANEL, 0.94), UI.GOLD_DULL, 16))
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(menu_panel)
	menu_box = UI.vbox(8)
	menu_panel.add_child(menu_box)
	var side_panel := PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", UiSkin.frame(Color(UI.PANEL, 0.94), UiSkin.IRON, 14))
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(side_panel)
	side_box = UI.vbox(8)
	side_panel.add_child(side_box)
	_fit()
	_fill_menu()
	_fill_side()
	var ver := UI.label("v" + PatchNotes.VERSION, UI.FONT_BODY, UI.DIM)
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
	var town_l := UI.label("%s · %s" % [p.town_name(p.town), "Hardcore" if p.town_hardcore(p.town) else "Regular"], UI.FONT_BODY, UI.GOLD)
	town_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.tip(town_l, "The town you're in. Switch or found another from Towns.")
	menu_box.add_child(town_l)
	var roster_l := UI.label(p.roster_line(), UI.FONT_BODY, UI.DIM)   # Fable r4 #4: the same line as Heroes and the Inn
	roster_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(roster_l)
	if not meta.is_empty():
		var cont := UI.primary("Continue", func(): close_and(func(): m.play_slot(p.active_slot)), UI.GOLD)
		cont.custom_minimum_size = Vector2(0, UI.TAP)
		menu_box.add_child(cont)
		menu_box.add_child(_hero_line(meta))
	# Juzo: no "New hero" here. A town's first hero comes with founding it; later
	# heroes are recruited at the Inn when a slot opens.
	if meta.is_empty():
		var found := UI.primary("Found your town", func(): FoundTown.new().show_for(m, p.town), UI.GREEN)
		found.custom_minimum_size = Vector2(0, UI.TAP)
		menu_box.add_child(found)
	var row := UI.hbox(8)
	menu_box.add_child(row)
	for entry in [["Heroes", func(): HeroSelect.new().show_for(m, self)], ["Towns", func(): TownSelect.new().show_for(m, self)], ["Settings", func(): SettingsMenu.new().show_for(m)],
			["Guide", func(): GuideBook.open_book(m, "")]]:
		var b := UI.button(entry[0], entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(b)
	if OS.get_name() in ["Windows", "macOS", "Linux"]:
		var q := UI.button("Quit", func(): m.get_tree().quit())
		q.custom_minimum_size = Vector2(0, UI.TAP)
		menu_box.add_child(q)

func _hero_line(meta: Dictionary) -> Control:
	var row := UI.hbox(10)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(meta.get("appearance", {}), HeroArt.meta_looks(meta))
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 2   # 2x, whole pixels (the grid)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var info := UI.rich(UI.FONT_BODY)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = HeroSelect.describe(meta)
	row.add_child(info)
	return row

func _fill_side() -> void:
	OnlineUI.clear(side_box)
	# The new update's banner
	if m.profile.notes_seen != PatchNotes.VERSION:
		var up := UI.panel(UI.PANEL, UI.GOLD, 8, 10, 2)
		side_box.add_child(up)
		var ut := UI.rich(UI.FONT_BODY)
		ut.text = "[color=#e8b14a][b]%s[/b][/color]  [color=%s]v%s[/color]\nNew class rules with God classes, pets from region nests, three currencies, the Legendary Wheel and safer saves." % [String(PatchNotes.NOTES[0]["name"]), UI.hex(UI.DIM), PatchNotes.VERSION]
		up.add_child(ut)
		var pulse := up.create_tween().set_loops()
		pulse.tween_property(up, "modulate", Color(1.15, 1.1, 0.95), 0.9)
		pulse.tween_property(up, "modulate", Color(1, 1, 1), 0.9)
	var wn := UI.button("What's new in v%s" % PatchNotes.VERSION, func(): WhatsNew.new().show_for(m))  # 2.1 G9
	wn.custom_minimum_size = Vector2(0, UI.TAP)
	side_box.add_child(wn)
	var week := Realms.realm_of_week()
	var wk := UI.rich(UI.FONT_BODY)
	wk.text = "[color=%s]Realm of the week[/color]\n[color=%s][b]%s[/b][/color]: double reputation and better loot." % [UI.hex(UI.GOLD), Realms.info(week)["color"], Realms.realm_name(week)]
	side_box.add_child(wk)
	var ev := GameData.active_events()
	if not ev.is_empty():
		var names := []
		for id in ev:
			names.append("[b]%s[/b]: %s" % [GameData.EVENTS[id]["name"], GameData.EVENTS[id]["text"]])
		var banner := UI.rich(UI.FONT_BODY)
		banner.text = "[color=%s]Event now[/color]\n" % UI.hex(UI.GOLD) + "\n".join(names)
		side_box.add_child(banner)
	m.profile.notes_seen = PatchNotes.VERSION
	if size.x < size.y * 0.95:
		m.profile.save()
		return   # phone: the scene needs the height; tips are on the loading screen, notes behind the button
	var tip := UI.rich(UI.FONT_BODY)
	tip.text = "[color=%s]Tip of the day[/color]\n%s" % [UI.hex(UI.GOLD), PatchNotes.tip_of_the_day()]
	side_box.add_child(tip)
	side_box.add_child(UI.heading("What's new"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_box.add_child(scroll)
	var notes := UI.rich(UI.FONT_BODY)
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

## The sun-disc mark: gold rings with ink outlines around a bright core (palette.gpl golds).
func _draw_sun(c: Control) -> void:
	var o := Vector2(c.size.x / 2.0, c.size.y / 2.0)
	for ring in [[34.0, "#6a4a28"], [28.0, "#9a7040"], [22.0, "#c8a060"]]:
		c.draw_arc(o, ring[0], 0.0, TAU, 48, UiSkin.SOOT, 6.0)
		c.draw_arc(o, ring[0], 0.0, TAU, 48, Color(ring[1]), 3.0)
	c.draw_circle(o, 13.0, UiSkin.SOOT)
	c.draw_circle(o, 11.0, Color("#feae34"))
	c.draw_circle(o, 5.0, Color("#fee761"))
