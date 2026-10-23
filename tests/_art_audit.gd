extends SceneTree
## Art audit: renders contact sheets of every kind of art into shots/audit/ so the
## owner can mark each asset keep / fix / replace. Needs a real window:
##   godot --path . --resolution 1400x1000 -s tests/_art_audit.gd
## Another folder (for before/after sets):  ... -s tests/_art_audit.gd -- --out=res://shots/art_after/after/
## Also writes shots/audit/stats.txt (per-file pixel stats used for the notes in
## claude/art-audit.md). Every picture is scaled nearest-neighbor, same scale
## for a whole sheet, so mixed pixel sizes show up as mixed sizes.

const OUT := "res://shots/audit/"
const BG := Color("#0c0c14")
const TILE_BG := Color("#15151f")
const IMG_BG := Color("#23233a")
const TXT := Color("#e8e6f0")
const DIM := Color("#8a8aa0")
const WARN := Color("#ff7a59")
const GOOD_SIZE := {"enemy": 68, "boss": 68}  # ArtStyle.MONSTER_SIZE (two-tile giants 68x132)

var _root: Control
var _w := 0
var _y := 0
var _made: Array = []
var _used_keys := {}
var _out := OUT

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	await process_frame
	await _stats()
	await _monsters()
	await _calamities_orphans()
	await _heroes()
	await _items()
	await _backgrounds()
	await _dungeon()
	await _halls()
	await _town()
	await _fx()
	await _pets()
	await _ui()
	await _density()
	print("AUDIT sheets: ", _made.size())
	for m in _made:
		print("  ", m)
	quit()

# ---------------------------------------------------------------- sheet helpers

func _begin(width: int, title: String, note := "") -> void:
	_root = Control.new()
	_w = width
	_y = 10
	_lab(title, Vector2(16, _y), 26, TXT)
	_y += 36
	if note != "":
		_lab(note, Vector2(16, _y), 13, DIM)
		_y += 22
	_y += 8

func _lab(text: String, pos: Vector2, size := 13, color := TXT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_root.add_child(l)
	return l

func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	_root.add_child(r)
	return r

func _section(text: String) -> void:
	_y += 6
	_rect(Vector2(16, _y + 22), Vector2(_w - 32, 1), Color("#33334a"))
	_lab(text, Vector2(16, _y), 17, Color("#d6b86a"))
	_y += 30

## Draws a texture at pos with a lighter backing so its exact bounds show. null = NO ART.
func _pic(tex: Texture2D, pos: Vector2, sc: float, fallback := Vector2(64, 64)) -> Vector2:
	if tex == null:
		var s := fallback * sc
		_rect(pos, s, Color("#5a1620"))
		_lab("NO ART", pos + Vector2(6, s.y / 2 - 8), 13, Color("#ffd0d0"))
		return s
	var s := Vector2(tex.get_size()) * sc
	_rect(pos, s, IMG_BG)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.position = pos
	tr.size = s
	_root.add_child(tr)
	return s

## items: [{imgs: [Texture2D|null...], label, sub, flag}]. Lays them out in rows of cols.
func _grid(items: Array, sc: float, cols: int, min_cell_w := 150) -> void:
	if items.is_empty():
		return
	var mw := 8.0
	var mh := 8.0
	var n := 1
	for it in items:
		n = maxi(n, (it["imgs"] as Array).size())
		for t in it["imgs"]:
			if t != null:
				mw = maxf(mw, t.get_width())
				mh = maxf(mh, t.get_height())
	if mw < 8.0:
		mw = 64.0
		mh = 64.0
	var cw := maxf(float(min_cell_w), 16.0 + n * mw * sc + (n - 1) * 8.0)
	var ch := 8.0 + mh * sc + 8.0 + 44.0
	_w = maxi(_w, int(16 + cols * (cw + 8)))
	var i := 0
	for it in items:
		var cx := 16.0 + (i % cols) * (cw + 8)
		var cy := _y + (i / cols) * (ch + 8)
		_rect(Vector2(cx, cy), Vector2(cw, ch), TILE_BG)
		var x := cx + 8
		for t in it["imgs"]:
			var fb := Vector2(mw, mh)
			var s := _pic(t, Vector2(x, cy + 8), sc, fb)
			x += s.x + 8
		var ly := cy + 8 + mh * sc + 6
		_lab(str(it["label"]), Vector2(cx + 8, ly), 13, WARN if it.get("flag", false) else TXT)
		_lab(str(it.get("sub", "")), Vector2(cx + 8, ly + 18), 11, WARN if it.get("flag", false) else DIM)
		i += 1
	_y += int(ceil(items.size() / float(cols)) * (ch + 8)) + 8

func _finish(file_name: String) -> void:
	var h := maxi(_y + 16, 64)
	var vp := SubViewport.new()
	vp.size = Vector2i(_w, h)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var back := ColorRect.new()
	back.color = BG
	back.size = Vector2(_w, h)
	vp.add_child(back)
	vp.add_child(_root)
	root.add_child(vp)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var path := ProjectSettings.globalize_path(_out + file_name)
	img.save_png(path)
	_made.append("%s  (%dx%d)" % [path, _w, h])
	vp.queue_free()
	await process_frame

# ---------------------------------------------------------------- data helpers

func _load_img(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img

func _tex(img: Image) -> Texture2D:
	return ImageTexture.create_from_image(img) if img != null else null

func _png_names(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			out.append(f.get_basename())
	out.sort()
	return out

func _sz(t: Texture2D) -> String:
	return "no file" if t == null else "%dx%d" % [t.get_width(), t.get_height()]

func _monster_entry(m: Dictionary, boss: bool, used: Dictionary) -> Dictionary:
	var key: String = m.get("art", "")
	if key == "":
		key = ("boss_" if boss else "") + String(m.get("id", ""))  # art goes by id, like the game
	used[key] = true
	var raw := _load_img("res://art/enemies/%s.png" % key)
	var graded: Image = DarkGrade.image(raw) if raw != null else null
	var want: int = GOOD_SIZE["boss"] if boss else GOOD_SIZE["enemy"]
	var odd := raw != null and (raw.get_width() != want or (raw.get_height() != want and not (boss and raw.get_height() == ArtStyle.TALL_SIZE.y)))
	var src := "png" if raw != null else ("LPC-built" if Lpc.MONSTERS.has(key) else "MISSING")
	return {"imgs": [_tex(raw), _tex(graded)], "label": "%s%s" % [m["name"], "  [BOSS]" if boss else ""],
		"sub": "%s  %s  %s%s" % [key, _sz(_tex(raw)), src, "   << off-size (standard %d)" % want if odd else ""],
		"flag": odd or raw == null}

# ---------------------------------------------------------------- monsters

func _monsters() -> void:
	var used := {}
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var normal: Array = []
		var bosses: Array = []
		for e in z["enemies"]:
			normal.append(_monster_entry(e, false, used))
		for s in z["subs"]:
			var en := _monster_entry(s["monster"], false, used)
			en["label"] = "%s  (%s)" % [s["monster"]["name"], s["name"]]
			normal.append(en)
		bosses.append(_monster_entry(z["mid"], true, used))
		bosses.append(_monster_entry(z["boss"], true, used))
		_begin(1500, "Monsters: zone %d, %s" % [zi, z["name"]], "Each tile: RAW png | DARK-GRADED (what the game shows). Scale 2x for every tile, so a smaller sprite looks smaller. Orange = off the 68px standard or missing.")
		_section("Regular monsters (5 roots + 5 sub-area)")
		_grid(normal, 2.0, 3)
		_section("Mid boss and zone boss")
		_grid(bosses, 2.0, 2)
		await _finish("monsters_z%d.png" % zi)
	_used_keys = used

func _calamities_orphans() -> void:
	var used: Dictionary = _used_keys
	var cal: Array = []
	for i in 10:
		var k := "calamity_%d" % i
		used[k] = true
		var raw := _load_img("res://art/enemies/%s.png" % k)
		cal.append({"imgs": [_tex(raw), _tex(DarkGrade.image(raw) if raw != null else null)], "label": k,
			"sub": _sz(_tex(raw)), "flag": raw == null or raw.get_width() != ArtStyle.MONSTER_SIZE.x})
	var orphans: Array = []
	var orphan_names: Array = []
	for k in _png_names("res://art/enemies"):
		if not used.has(k):
			orphan_names.append(k)
			var raw := _load_img("res://art/enemies/%s.png" % k)
			orphans.append({"imgs": [_tex(raw), _tex(DarkGrade.image(raw))], "label": k, "sub": _sz(_tex(raw)) + "  not used by any zone"})
	_begin(1500, "Calamities and unused monster files", "Calamity bosses, then art/enemies files that no zone refers to (mimic, treasure goblin and other special spawns appear here when not in ZONES).")
	_section("Calamities")
	_grid(cal, 2.0, 3)
	_section("Not referenced by GameData.ZONES (%d)" % orphan_names.size())
	_grid(orphans, 2.0, 3)
	await _finish("monsters_calamities_unused.png")
	print("ORPHAN enemy files: ", ", ".join(PackedStringArray(orphan_names)))

# ---------------------------------------------------------------- heroes

func _app(race: String, i: int) -> Dictionary:
	var hairs := Sprites.HAIR_STYLES
	var app := {"body": "masc" if i % 2 == 0 else "fem", "skin": 1 + (i % 4), "hair": hairs[(i * 3) % hairs.size()],
		"hair_color": (i * 2) % 17, "eyes": i % 7, "race": race}
	var rs: Array = Races.INFO[race].get("skins", [])
	if not rs.is_empty():
		app["skin"] = rs[0]
	return app

func _looks(gs: Dictionary) -> Dictionary:
	var looks := {}
	for slot in gs:
		looks[slot] = Sprites.gear_look({"slot": slot, "type": gs[slot], "rarity": 2})
	return looks

func _heroes() -> void:
	var naked: Array = []
	var back: Array = []
	var i := 0
	for r in Races.ORDER:
		for body in ["masc", "fem"]:
			var app := _app(r, i)
			app["body"] = body
			var t := Sprites.portrait(app, {})
			naked.append({"imgs": [t], "label": "%s (%s)" % [r, body], "sub": _sz(t)})
		i += 1
	i = 0
	for r in Races.ORDER:
		var app := _app(r, i)
		var h := Sprites.hero_back(app, {})
		var img: Image = h["body_img"]
		var crop := img.get_region(Rect2i(Sprites.PORTRAIT_CROP).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
		back.append({"imgs": [_tex(crop)], "label": "%s, from behind" % r, "sub": _sz(_tex(crop))})
		i += 1
	_begin(1500, "Heroes: every race, both builds, front and back", "LPC parts via Sprites.portrait (the menu portrait, %dpx). Scale 3x. Shows how the race add-ons (wings, horns, tails) sit on the shared body." % Sprites.PORTRAIT)
	_section("Front")
	_grid(naked, 3.0, 6, 130)
	_section("From behind (back-to-front fights)")
	_grid(back, 3.0, 6, 130)
	await _finish("heroes_races.png")

	var sets := {
		"Warrior (plate, sword, shield)": {"Chest": "plate", "Legs": "greaves", "Feet": "sabatons", "Helmet": "helm", "Weapon": "sword", "Off Hand": "shield"},
		"Knight (plate, mace, tower)": {"Chest": "plate", "Legs": "greaves", "Feet": "sabatons", "Helmet": "crown", "Weapon": "mace", "Off Hand": "tower"},
		"Ranger (tunic, bow, hood)": {"Chest": "tunic", "Legs": "leggings", "Feet": "boots", "Helmet": "hood", "Weapon": "bow"},
		"Mage (robe, staff, tome)": {"Chest": "robe", "Feet": "sandals", "Weapon": "staff", "Off Hand": "tome"},
		"Mage 2 (robe, orb, hood)": {"Chest": "robe", "Feet": "sandals", "Helmet": "hood", "Weapon": "staff", "Off Hand": "orb"},
		"Trickster (tunic, dagger, cap)": {"Chest": "tunic", "Legs": "pants", "Feet": "boots", "Helmet": "cap", "Weapon": "dagger"},
		"Axe fighter (plate, axe, cape)": {"Chest": "plate", "Legs": "pants", "Feet": "boots", "Helmet": "helm", "Weapon": "axe"},
		"Spear (tunic, spear, buckler)": {"Chest": "tunic", "Legs": "pants", "Feet": "boots", "Weapon": "spear", "Off Hand": "buckler"},
	}
	var cls: Array = []
	var j := 0
	for name in sets:
		var app := _app("Human", j)
		var t := Sprites.portrait(app, _looks(sets[name]))
		cls.append({"imgs": [t], "label": name, "sub": _sz(t)})
		j += 1
	var hairs: Array = []
	var h := 0
	for hs in Sprites.HAIR_STYLES:
		var app := {"body": "masc" if h % 2 == 0 else "fem", "skin": 1, "hair": hs, "hair_color": (h * 3) % 17, "eyes": 0, "race": "Human"}
		var t := Sprites.portrait(app, {})
		hairs.append({"imgs": [t], "label": str(hs), "sub": app["body"]})
		h += 1
	_begin(1500, "Heroes: class kits and all hair styles", "Gear shown on the hero at Rare quality. Scale 3x.")
	_section("Class kits (Human)")
	_grid(cls, 3.0, 5, 130)
	_section("Hair styles (%d)" % Sprites.HAIR_STYLES.size())
	_grid(hairs, 3.0, 8, 130)
	await _finish("heroes_classes_hair.png")

# ---------------------------------------------------------------- items

func _items() -> void:
	var rarities := [0, 1, 2, 3, 4, 8]
	_begin(1500, "Item icons by slot and rarity", "Sprites.item_icon (hero gear layer recolored). Columns: Common, Uncommon, Rare, Epic, Legendary, Mythic. Scale 3x. Every icon sits centered in one %dx%d frame at the gear art's own pixel size." % [ArtStyle.ICON_FRAME, ArtStyle.ICON_FRAME] + "")
	var types: Dictionary = ItemPool.TYPES
	for slot in types:
		_section("%s: %s" % [slot, ", ".join(PackedStringArray(types[slot]))])
		var items: Array = []
		for t in types[slot]:
			var imgs: Array = []
			for r in rarities:
				imgs.append(Sprites.item_icon({"slot": slot, "type": t, "rarity": r}))
			var first: Texture2D = imgs[0]
			items.append({"imgs": imgs, "label": "%s / %s" % [slot, t], "sub": "common icon " + _sz(first)})
		_grid(items, 3.0, 2 if types[slot].size() > 3 else 3)
	await _finish("items_icons.png")

	# Raw gear layers (the sources: key-colored masks on the hero canvas)
	var raw: Array = []
	for n in _png_names("res://art/gear"):
		var im := _load_img("res://art/gear/%s.png" % n)
		raw.append({"imgs": [_tex(im)], "label": n, "sub": _sz(_tex(im)) + "  used " + str(im.get_used_rect().size)})
	_begin(1500, "Raw gear layers (art/gear)", "These are hero-body overlays drawn in key colors, not icons. Scale 2x.")
	_grid(raw, 2.0, 6, 130)
	await _finish("items_gear_layers_raw.png")

	var cons: Array = []
	for n in _png_names("res://art/consumables"):
		var t := Sprites.consumable_icon(n)
		cons.append({"imgs": [t], "label": n, "sub": _sz(t)})
	_begin(1500, "Consumable icons (art/consumables)", "Scale 4x. Mixed pixel sizes show here (DCSS 32px tiles next to the hand-drawn ones).")
	_grid(cons, 4.0, 7, 140)
	await _finish("items_consumables.png")

# ---------------------------------------------------------------- backgrounds

func _backgrounds() -> void:
	for zi in 10:
		var z: Dictionary = GameData.ZONES[zi]
		var items: Array = []
		var paths := ["res://art/bg/zone_%d.png" % zi]
		var names := ["zone default"]
		for s in 5:
			paths.append("res://art/bg/zone_%d_%d.png" % [zi, s])
			names.append(str(z["subs"][s]["name"]))
		for k in paths.size():
			var raw := _load_img(paths[k])
			var g: Image = DarkGrade.image(raw, DarkGrade.SCENE, false) if raw != null else null
			items.append({"imgs": [_tex(raw), _tex(g)], "label": "%s: %s" % [paths[k].get_file(), names[k]],
				"sub": _sz(_tex(raw)), "flag": raw == null or raw.get_size() != Vector2i(320, 180)})
		_begin(1500, "Backgrounds: zone %d, %s" % [zi, z["name"]], "RAW | GRADED (DarkGrade.SCENE). Native 320x180 shown at 1.5x. Orange = not 320x180.")
		_grid(items, 1.5, 2)
		await _finish("backgrounds_z%d.png" % zi)

# ---------------------------------------------------------------- dungeon props and tiles

func _dungeon() -> void:
	var props: Array = []
	var tiles: Array = []
	for n in _png_names("res://art/dungeon"):
		var im := _load_img("res://art/dungeon/%s.png" % n)
		var graded: Image = DarkGrade.image(im)
		var e := {"imgs": [_tex(im), _tex(graded)], "label": n, "sub": _sz(_tex(im)), "flag": im.get_size() != Vector2i(32, 32)}
		if n.contains("_floor_") or n.contains("_wall_"):
			tiles.append(e)
		else:
			props.append(e)
	_begin(1500, "Dungeon room props (art/dungeon)", "RAW | GRADED. Scale 4x. Used by the room views (halls_scene.gd, room_view.gd). Orange = not 32x32.")
	_grid(props, 4.0, 5)
	await _finish("dungeon_props.png")
	_begin(1500, "Dungeon floor and wall tiles (art/dungeon zN_floor/wall)", "RAW | GRADED. Scale 3x. Orange = not 32x32.")
	_grid(tiles, 3.0, 6)
	await _finish("dungeon_tiles.png")

func _halls() -> void:
	var items: Array = []
	for n in _png_names("res://art/halls"):
		var im := _load_img("res://art/halls/%s.png" % n)
		items.append({"imgs": [_tex(im)], "label": n, "sub": _sz(_tex(im)), "flag": im.get_size() != Vector2i(32, 32) and not n.begins_with("door")})
	_begin(1500, "First-person room textures (art/halls)", "Walls, floors, ceilings per zone, plus doors. Scale 3x. These are tiled across big 3D surfaces, so seams and repeats matter.")
	_grid(items, 3.0, 9, 110)
	await _finish("halls_textures.png")

# ---------------------------------------------------------------- town

func _town() -> void:
	_begin(1500, "Town map (art/town), four seasons", "Full map 704x1088 at 1x (so ~half of a phone screen wide). Zoomed crops at 3x below.")
	var x := 16
	var y0 := _y
	var maxh := 0
	var seasons := ["spring", "summer", "autumn", "winter"]
	var imgs: Dictionary = {}
	for s in seasons:
		imgs[s] = _load_img("res://art/town/town_%s.png" % s)
	_w = 16 + 2 * (704 + 16)
	for k in seasons.size():
		var im: Image = imgs[seasons[k]]
		var px := 16 + (k % 2) * (704 + 16)
		var py := y0 + (k / 2) * (1088 + 40)
		_lab("town_%s.png  %s" % [seasons[k], _sz(_tex(im))], Vector2(px, py), 14, TXT)
		_pic(_tex(im), Vector2(px, py + 22), 1.0)
	_y = y0 + 2 * (1088 + 40)
	_section("Zoomed crops (3x, spring): gate, guild, market, fountain")
	var spring: Image = imgs["spring"]
	var crops := [Rect2i(288, 48, 128, 128), Rect2i(64, 160, 160, 128), Rect2i(300, 500, 128, 128), Rect2i(280, 800, 128, 128)]
	var cl: Array = []
	for r in crops:
		var rr: Rect2i = r.intersection(Rect2i(Vector2i.ZERO, spring.get_size()))
		cl.append({"imgs": [_tex(spring.get_region(rr))], "label": "crop %s" % str(rr), "sub": "3x"})
	_grid(cl, 3.0, 3)
	await _finish("town_map.png")

# ---------------------------------------------------------------- fx

func _fx() -> void:
	var frames: Dictionary = (load("res://art/fx/fx.json") as JSON).data
	var items: Array = []
	for n in _png_names("res://art/fx"):
		var im := _load_img("res://art/fx/%s.png" % n)
		var cnt: int = int(frames.get(n, 1))
		var fw := im.get_width() / maxi(cnt, 1)
		var strip: Array = []
		for f in cnt:
			strip.append(_tex(im.get_region(Rect2i(f * fw, 0, fw, im.get_height()))))
		var ok: bool = im.get_width() % maxi(cnt, 1) == 0
		items.append({"n": n, "strip": strip, "label": n, "sub": "%s, %d frames of %dx%d%s" % [_sz(_tex(im)), cnt, fw, im.get_height(), "" if ok else "  << width not divisible"], "flag": not ok})
	_begin(1500, "Hit and spell effects (art/fx)", "Every frame of every effect, 2x, in order. The game plays them left to right.")
	for it in items:
		_lab("%s    %s" % [it["label"], it["sub"]], Vector2(16, _y), 13, WARN if it["flag"] else TXT)
		_y += 20
		var x := 16
		var rowh := 0
		for t in it["strip"]:
			var s := _pic(t, Vector2(x, _y), 2.0)
			x += int(s.x) + 4
			rowh = maxi(rowh, int(s.y))
			if x > 1450:
				x = 16
				_y += rowh + 4
				rowh = 0
		_y += rowh + 14
		_w = maxi(_w, x + 16)
	await _finish("fx_frames.png")

# ---------------------------------------------------------------- pets

func _pets() -> void:
	var items: Array = []
	for n in _png_names("res://art/pets"):
		var raw := _load_img("res://art/pets/%s.png" % n)
		items.append({"imgs": [_tex(raw), _tex(DarkGrade.image(raw))], "label": n, "sub": _sz(_tex(raw)), "flag": raw.get_size() != ArtStyle.MONSTER_SIZE})
	_begin(1500, "Companions (art/pets)", "RAW | GRADED, four growth stages per class. Scale 2x. Orange = not 68x68.")
	_grid(items, 2.0, 4)
	await _finish("pets.png")

# ---------------------------------------------------------------- ui

func _ui() -> void:
	_begin(1500, "UI pieces (ui_skin.gd, drawn in code) and brand art", "Frames, bevel buttons and the backdrop are generated at runtime (2x art pixels). Shown at 1x as the game draws them.")
	_section("Frames: UiSkin.frame(fill, accent)")
	var accents := [UiSkin.IRON, Color("#e43b44"), Color("#fbbf24"), Color("#60a5fa"), Color("#c084fc"), Color("#4ade80")]
	var x := 16
	for a in accents:
		var p := Panel.new()
		p.position = Vector2(x, _y)
		p.size = Vector2(200, 110)
		p.add_theme_stylebox_override("panel", UiSkin.frame(Color("#161628"), a))
		_root.add_child(p)
		_lab("accent " + a.to_html(false), Vector2(x + 14, _y + 44), 12, TXT)
		x += 216
		if x > 1300:
			x = 16
			_y += 126
	_section("Buttons: UiSkin.bevel (normal | pressed)")
	x = 16
	for c in [["#3a3d55", "#8a8ca3"], ["#5a1a22", "#e43b44"], ["#5a4a14", "#fbbf24"], ["#1a3a5a", "#60a5fa"], ["#2a5a2a", "#4ade80"]]:
		for pressed in [false, true]:
			var b := Button.new()
			b.text = "Press" if not pressed else "Held"
			b.position = Vector2(x, _y)
			b.size = Vector2(110, 44)
			var sb := UiSkin.bevel(Color(c[0]), Color(c[1]), 6, pressed)
			for st in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(st, sb)
			_root.add_child(b)
			x += 122
	_y += 64
	_section("Backdrop: UiSkin.backdrop")
	var bd := UiSkin.backdrop()
	var bt := TextureRect.new()
	bt.texture = bd
	bt.position = Vector2(16, _y)
	bt.size = Vector2(430, 560)
	bt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bt.stretch_mode = TextureRect.STRETCH_SCALE
	bt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_root.add_child(bt)
	_lab("backdrop %s, shown stretched to 430x560" % _sz(bd), Vector2(460, _y), 13, TXT)
	var ic := load("res://icon.png") as Texture2D
	var sp := load("res://splash.png") as Texture2D
	var isc := 160.0 / ic.get_width()
	_pic(ic, Vector2(460, _y + 30), isc)
	_lab("icon.png " + _sz(ic) + " (shown " + str(snappedf(isc, 0.01)) + "x)", Vector2(460, _y + 30 + 164), 12, TXT)
	var ssc := 520.0 / sp.get_height()
	_pic(sp, Vector2(700, _y + 30), ssc)
	_lab("splash.png " + _sz(sp) + " (shown " + str(snappedf(ssc, 0.01)) + "x)", Vector2(700, _y + 30 + 524), 12, TXT)
	_y += 580
	_section("Skill icons (SkillIcons.for_tag: one fx frame each)")
	var items: Array = []
	for tag in SkillIcons.TAG_FX:
		var t := SkillIcons.for_tag(tag)
		items.append({"imgs": [t], "label": tag, "sub": _sz(t) + "  fx " + SkillIcons.TAG_FX[tag]})
	_grid(items, 2.0, 8, 120)
	await _finish("ui_pieces.png")

# ---------------------------------------------------------------- pixel density (decision D4)

## One monster and one hero at the battle's sizes: the hero as today (1x pixels, drawn a size
## bigger) and with Sprites.HERO_PIXEL = 2 (snapped to the monsters' 2x grid, same unit).
func _density() -> void:
	var u := 4
	var looks := _looks({"Chest": "plate", "Legs": "greaves", "Feet": "sabatons", "Helmet": "helm", "Weapon": "sword", "Off Hand": "shield"})
	var app := _app("Human", 0)
	var hero: Image = Sprites.hero(app, looks)["body_img"]
	var mon := _load_img("res://art/enemies/redcap.png")
	var boss := _load_img("res://art/enemies/boss_grendel.png")
	_begin(1500, "Pixel density: heroes vs monsters (decision D4)", "Battle sizes with a unit of %d screen px per file pixel. Monster files are 2x art. Left: hero today (1x art, unit x4/3). Right: Sprites.HERO_PIXEL = 2." % u)
	var x := 16.0
	var y := float(_y)
	var s := _pic(_tex(mon), Vector2(x, y), u)
	_lab("redcap (2x art) at %dx" % u, Vector2(x, y + s.y + 4), 13, TXT)
	x += s.x + 24
	s = _pic(_tex(hero), Vector2(x, y), roundf(u * 4.0 / 3.0))
	_lab("hero today: 1x art at %dx" % int(roundf(u * 4.0 / 3.0)), Vector2(x, y + s.y + 4), 13, TXT)
	x += s.x + 24
	s = _pic(_tex(Sprites.chunky(hero, 2)), Vector2(x, y), u)
	_lab("HERO_PIXEL = 2: 2x art at %dx" % u, Vector2(x, y + s.y + 4), 13, TXT)
	x += s.x + 24
	s = _pic(_tex(boss), Vector2(x, y), u)
	_lab("boss_grendel at %dx" % u, Vector2(x, y + s.y + 4), 13, TXT)
	_w = maxi(_w, int(x + s.x + 16))
	_y = int(y + Sprites.CANVAS * roundf(u * 4.0 / 3.0) + 40)
	await _finish("density_heroes.png")

# ---------------------------------------------------------------- stats

## Per-file numbers for the written notes: size, palette depth, partial-alpha share
## (soft/anti-aliased edges), checker-like 2x2 cells, and how cleanly a 2x upscale
## the picture really is (share of aligned 2x2 blocks that are one flat color).
func _stats() -> void:
	var lines: Array = ["folder\tfile\tw\th\tcolors\tsoft_alpha%\tchecker%\tblock2x2_flat%\topaque%"]
	for d in ["enemies", "pets", "dungeon", "halls", "bg", "gear", "consumables", "fx", "hero", "town"]:
		for n in _png_names("res://art/" + d):
			var im := _load_img("res://art/%s/%s.png" % [d, n])
			if im == null:
				continue
			lines.append("%s\t%s\t%s" % [d, n, _measure(im)])
	var f := FileAccess.open(ProjectSettings.globalize_path(_out + "stats.txt"), FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(lines)) + "\n")
	f.close()
	print("AUDIT stats lines: ", lines.size())

func _measure(im: Image) -> String:
	var w := im.get_width()
	var h := im.get_height()
	var data := im.get_data()
	var colors := {}
	var opaque := 0
	var soft := 0
	for i in range(0, data.size(), 4):
		var a := data[i + 3]
		if a == 0:
			continue
		opaque += 1
		if a < 255:
			soft += 1
		if colors.size() < 5000:
			colors[(data[i] << 16) | (data[i + 1] << 8) | data[i + 2]] = true
	var chk := 0
	var cells := 0
	for y in range(0, h - 1):
		for x in range(0, w - 1):
			var i := (y * w + x) * 4
			if data[i + 3] != 255:
				continue
			var j := i + 4
			var k := i + w * 4
			var m := k + 4
			if data[j + 3] != 255 or data[k + 3] != 255 or data[m + 3] != 255:
				continue
			cells += 1
			if _same(data, i, m) and _same(data, j, k) and not _same(data, i, j):
				chk += 1
	var flat := 0
	var blocks := 0
	for by in range(0, h - 1, 2):
		for bx in range(0, w - 1, 2):
			var i := (by * w + bx) * 4
			var any := data[i + 3] != 0 or data[i + 7] != 0 or data[i + w * 4 + 3] != 0 or data[i + w * 4 + 7] != 0
			if not any:
				continue
			blocks += 1
			if _same(data, i, i + 4) and _same(data, i, i + w * 4) and _same(data, i, i + w * 4 + 4):
				flat += 1
	var total := w * h
	return "%d\t%d\t%d\t%.1f\t%.1f\t%.1f\t%.1f" % [w, h, colors.size(), 100.0 * soft / maxi(opaque, 1),
		100.0 * chk / maxi(cells, 1), 100.0 * flat / maxi(blocks, 1), 100.0 * opaque / maxi(total, 1)]

func _same(d: PackedByteArray, a: int, b: int) -> bool:
	return d[a] == d[b] and d[a + 1] == d[b + 1] and d[a + 2] == d[b + 2] and d[a + 3] == d[b + 3]
