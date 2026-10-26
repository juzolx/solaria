class_name ShareCard
extends RefCounted
## 2.1 G8: the share card. A portrait picture (1080 x 1350, the shape social apps
## like) of your hero: name, title, class and rank, race, level, deepest floor,
## gear score, pet, town, proudest trophies and the game's name, in the game's
## pixel style. It's drawn small (360 x 450) with crisp, unsmoothed text and art,
## then blown up 3x with hard pixels. Saved as a PNG in user://share/. No online needed.
##
## Godot 4.7 has no native share sheet and can't put an image on the clipboard
## (only DisplayServer.clipboard_get_image), so the card is saved and shown in a
## popup: on a computer "Open folder" shows the file, on a phone a screenshot of
## the popup shares it. A share plugin (iOS UIActivityViewController) would add
## sending it straight to Messages, Photos or social apps.

const ENABLED := true  # the feature's on/off switch
const W := 360
const H := 450
const SCALE := 3      # 1080 x 1350 when saved
const DIR := "user://share"

static var _font: FontFile = null

# =====================================================================
# What goes on the card (no rendering: safe to test headless)
# =====================================================================

static func facts(state: GameState, codex: Codex, profile: Profile) -> Dictionary:
	var f := {}
	f["name"] = state.hero_name if state.hero_name != "" else "Hero"
	f["title"] = codex.title if codex != null else ""
	f["class"] = state.title()
	var rank := ""
	if state.god_class != "":
		rank = "GOD CLASS"
	elif state.hidden_class != "":
		rank = "SECRET CLASS"
	else:
		var r := ClassTree.rank_of(ClassTree.current(state))
		if r != "":
			rank = "%s RANK" % r
	f["rank"] = rank
	f["rank_color"] = ClassTree.RANK_COLORS.get("God", "#fde047") if state.god_class != "" else ("#c4b5fd" if state.hidden_class != "" else ClassTree.RANK_COLORS.get(rank.replace(" RANK", ""), "#e8b14a"))
	f["class_color"] = String(state.class_info().get("color", "#e5e7eb"))
	f["race"] = state.race()
	f["level"] = state.level
	f["deepest"] = state.best_floor
	f["gear"] = state.average_gear_score()
	f["hardcore"] = state.hardcore
	f["town"] = profile.town_name(profile.town) if profile != null else ""
	var pet := _pet(state)
	f["pet"] = ("%s (%s)" % [pet["name"], Menagerie.TIER_NAMES[clampi(int(pet["tier"]), 0, 5)]]) if not pet.is_empty() else ""
	f["pet_tier"] = int(pet.get("tier", 0))
	var top: Array = []
	for t in _top_trophies():
		top.append(String(t["name"]))
	f["moments_head"] = "PROUDEST MOMENTS"
	if top.is_empty() and codex != null:  # no trophies in this town yet: the latest deeds instead
		f["moments_head"] = "LATEST DEEDS"
		for a in Codex.ACHIEVEMENTS:
			if codex.achievements.has(a["id"]):
				top.append(String(a["name"]))
		top = top.slice(maxi(0, top.size() - 3))
	f["trophies"] = top
	f["deeds"] = "%d / %d" % [codex.achievements.size(), Codex.ACHIEVEMENTS.size()] if codex != null else ""
	f["rewards"] = "%d / %d" % [codex.coll_earned.size(), Collections.all().size()] if codex != null else ""
	f["date"] = Time.get_date_string_from_system()
	return f

## The pet to show: the strongest one coming along on runs, else the strongest you own.
static func _pet(state: GameState) -> Dictionary:
	var pool: Array = Menagerie.out(state)
	if pool.is_empty():
		pool = state.pets
	var best := {}
	for p in pool:
		if best.is_empty() or int(p["tier"]) > int(best["tier"]):
			best = p
	return best

## The 3 proudest trophies in this town: Calamities and God classes first, then finds, bosses, depth.
static func _top_trophies() -> Array:
	var order := ["calamity", "god", "find", "boss", "floor"]
	var list := Trophies.all()  # newest first
	var out: Array = []
	for k in order:
		for t in list:
			if String(t.get("kind", "")) == k and out.size() < 3:
				out.append(t)
	return out

static func file_name(hero: String) -> String:
	var clean := ""
	for ch in hero:
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			clean += ch
	if clean == "":
		clean = "hero"
	return "solaria_%s_%s.png" % [clean.to_lower(), Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")]

# =====================================================================
# Building the picture
# =====================================================================

## The game's font without smoothing: hard pixel edges when the card is scaled up.
static func pixel_font() -> FontFile:
	if _font == null:
		_font = (ThemeDB.fallback_font as FontFile).duplicate() as FontFile
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NORMAL
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font

static func _label(text: String, size: int, color: Color, center := false, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.clip_text = true
	return l

static func _box(bg: Color, border: Color, width := 1, margin := 4) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	return p

## A SubViewport holding the card at its small size (W x H). Not yet in the tree.
static func build(state: GameState, codex: Codex, profile: Profile) -> SubViewport:
	var f := facts(state, codex, profile)
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var th := Theme.new()
	th.default_font = pixel_font()
	th.default_font_size = 10
	var frame := Cosmetics.frame(codex)
	var accent := Color(String(frame["color"])) if String(frame.get("color", "")) != "" else UI.GOLD
	var root := _box(Color("#0b0a18"), accent, 3, 3)
	root.theme = th
	root.position = Vector2.ZERO
	root.size = Vector2(W, H)
	root.custom_minimum_size = Vector2(W, H)
	vp.add_child(root)
	var zi := clampi(GameData.zone_index(maxi(1, state.best_floor)), 0, GameData.ZONES.size() - 1)
	var back := TextureRect.new()  # the deepest region's mood light glowing up from below
	back.texture = BestiaryTab._ground(zi)
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.modulate = Color(1, 1, 1, 0.55)
	root.add_child(back)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	root.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	m.add_child(v)
	# The game's name
	var logo := _label("SOLARIA", 30, UI.GOLD, true)
	logo.add_theme_color_override("font_shadow_color", Color("#3a1f05"))
	logo.add_theme_constant_override("shadow_offset_x", 2)
	logo.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(logo)
	v.add_child(_label("A dungeon of myths and monsters", 9, UI.DIM, true))
	# The hero
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 10)
	v.add_child(hero)
	var plate := _box(Color(0.02, 0.02, 0.04), accent.darkened(0.2), 2, 0)
	hero.add_child(plate)
	var ground := TextureRect.new()
	ground.texture = BestiaryTab._ground(zi)
	ground.custom_minimum_size = Vector2(128, 128)
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_SCALE
	plate.add_child(ground)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(state.appearance, state.hero_looks())
	pic.custom_minimum_size = Vector2(128, 128)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.add_child(pic)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 3)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(who)
	who.add_child(_label(String(f["name"]), 18, Cosmetics.name_color(codex)))
	if String(f["title"]) != "":
		who.add_child(_label("\"%s\"" % f["title"], 11, UI.GOLD))
	who.add_child(_label(String(f["class"]), 14, Color(String(f["class_color"])).lightened(0.25)))
	if String(f["rank"]) != "":
		who.add_child(_chip(String(f["rank"]), Color(String(f["rank_color"]))))
	who.add_child(_label("%s  -  Level %d" % [f["race"], int(f["level"])], 11, UI.TEXT))
	if bool(f["hardcore"]):
		who.add_child(_chip("HARDCORE", Color("#f87171")))
	# The numbers
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for pair in [["DEEPEST FLOOR", str(f["deepest"])], ["GEAR SCORE", str(f["gear"])], ["TOWN", String(f["town"]) if String(f["town"]) != "" else "-"], ["DEEDS", String(f["deeds"])]]:
		var b := _box(Color(0.06, 0.06, 0.12, 0.92), UI.BORDER, 1, 5)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 0)
		b.add_child(bv)
		bv.add_child(_label(String(pair[0]), 9, UI.DIM, false, false))
		bv.add_child(_label(String(pair[1]), 15, UI.GOLD, false, false))
		grid.add_child(b)
	# The pet
	if String(f["pet"]) != "":
		var pr := HBoxContainer.new()
		pr.add_theme_constant_override("separation", 6)
		v.add_child(pr)
		var pt := TextureRect.new()
		pt.texture = Menagerie.texture(_pet(state))
		pt.custom_minimum_size = Vector2(32, 32)
		pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pr.add_child(pt)
		var pl := _label("Pet: %s" % f["pet"], 11, Color(Menagerie.TIER_COLORS[clampi(int(f["pet_tier"]), 0, 5)]))
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pr.add_child(pl)
	# Proudest moments
	var top: Array = f["trophies"]
	if not top.is_empty():
		v.add_child(_label(String(f["moments_head"]), 10, Color("#c9a36a")))
		for t in top:
			v.add_child(_label("*  " + String(t), 10, UI.TEXT, false, false))
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	v.add_child(_label("Codex rewards %s   -   %s" % [f["rewards"], f["date"]], 9, UI.DIM, true))
	return vp

static func _chip(text: String, c: Color) -> Control:
	var h := HBoxContainer.new()
	var b := _box(Color(c, 0.18), Color(c, 0.8), 1, 2)
	b.add_child(_label(text, 9, c.lightened(0.3), false, false))
	h.add_child(b)
	return h

## Can this run draw pictures? (A headless run, like the tests, can't.)
static func can_render() -> bool:
	return DisplayServer.get_name() != "headless"

## Draws the card and returns it at full size (1080 x 1350), or null if it can't be drawn.
## A coroutine: `var img = await ShareCard.render(...)`.
static func render(host: Node, state: GameState, codex: Codex, profile: Profile) -> Image:
	var tree := Engine.get_main_loop() as SceneTree
	if not can_render() or host == null or tree == null:
		return null
	var vp := build(state, codex, profile)
	host.add_child(vp)
	await tree.process_frame  # let the containers lay out
	await tree.process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGBA8)
	img.resize(W * SCALE, H * SCALE, Image.INTERPOLATE_NEAREST)
	return img

## Saves a card image. Returns the user:// path, or "" if it failed.
static func save(img: Image, hero: String) -> String:
	if img == null:
		return ""
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR + "/" + file_name(hero)
	return path if img.save_png(path) == OK else ""

# =====================================================================
# The Share button (Hero tab)
# =====================================================================

static func share(main) -> void:
	if not ENABLED:
		return
	if not can_render():
		main.toast("The share card can't be drawn here.")
		return
	var img: Image = await render(main, main.state, main.codex, main.profile)
	var path := save(img, main.state.hero_name)
	if path == "":
		main.toast("Couldn't make the share card. Please try again.")
		return
	_preview(main, img, path)

static func _preview(main, img: Image, path: String) -> void:
	var o := Overlay.new().open(main, "Share card", 440.0, UI.GOLD)
	var pic := TextureRect.new()
	pic.texture = ImageTexture.create_from_image(img)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(W, H)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	o.content.add_child(pic)
	var full := ProjectSettings.globalize_path(path)
	if OS.has_feature("pc"):
		o.content.add_child(UI.wrap("Saved as a picture (1080 x 1350): %s" % full, UI.FONT_BODY, UI.DIM))
		var b := UI.primary("Open folder", func(): OS.shell_show_in_file_manager(full), UI.TEAL)
		b.custom_minimum_size = Vector2(0, UI.TAP)
		o.content.add_child(b)
	else:
		o.content.add_child(UI.wrap("Saved in the game's files. To share it, take a screenshot of this card.", UI.FONT_BODY, UI.DIM))
	var ok := UI.button("Close", o.close)
	ok.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(ok)
