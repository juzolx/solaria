extends SceneTree
## 2.1 art rules (art_style.gd, baked by tools/bake_art.gd): every monster, companion, prop,
## consumable icon and effect stays on the shared palette, with hard pixels, the one dark
## outline and the standard sizes. If this fails after adding art, run the bake tool:
##   godot --headless --path . -s tools/bake_art.gd
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		if fails <= 40:
			print("FAIL: ", m)

func _pngs(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			out.append(f)
	return out

func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

## Palette, hard alpha and the outline rule (no colored pixel touches empty space).
func _sprite_rules(path: String, img: Image, outline := true) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var off_palette := 0
	var soft := 0
	var bare := 0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			if c.a8 != 255:
				soft += 1
			if ArtStyle.is_outline(c):
				continue
			if not ArtStyle.in_palette(c):
				off_palette += 1
			if not outline:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and img.get_pixel(nx, ny).a8 == 0:
					bare += 1
					break
	check(off_palette == 0, "%s: %d pixels off the palette" % [path, off_palette])
	check(soft == 0, "%s: %d soft (half see-through) pixels" % [path, soft])
	check(bare == 0, "%s: %d edge pixels without the dark outline" % [path, bare])

func _initialize() -> void:
	check(not ArtStyle.in_palette(ArtStyle.OUTLINE), "the outline color is not a palette color")
	check(ArtStyle.in_palette(Color(ArtStyle.PALETTE[3])), "palette colors are in the palette")

	# Monsters, bosses, Calamities and companions: 68x68 (giants 68x132), on a 2x grid
	var monsters := 0
	for d in ["res://art/enemies/", "res://art/pets/"]:
		for f in _pngs(d):
			var img := _load(d + f)
			monsters += 1
			check(img.get_size() == ArtStyle.MONSTER_SIZE or img.get_size() == ArtStyle.TALL_SIZE, "%s%s is %s (68x68 or 68x132)" % [d, f, img.get_size()])
			var rough := 0
			for by in range(0, img.get_height(), 2):
				for bx in range(0, img.get_width(), 2):
					var c := img.get_pixel(bx, by)
					if img.get_pixel(bx + 1, by) != c or img.get_pixel(bx, by + 1) != c or img.get_pixel(bx + 1, by + 1) != c:
						rough += 1
			check(rough == 0, "%s%s: %d blocks off the 2x art grid" % [d, f, rough])
			_sprite_rules(d + f, img)
	check(monsters > 150, "monster and companion files found (%d)" % monsters)

	# Props and consumable icons: 32x32
	for d in ["res://art/dungeon/", "res://art/consumables/"]:
		for f in _pngs(d):
			if f.contains("_floor_") or f.contains("_wall_"):
				continue
			var img := _load(d + f)
			check(img.get_size() == ArtStyle.PROP_SIZE, "%s%s is %s (32x32)" % [d, f, img.get_size()])
			_sprite_rules(d + f, img)
	var room_props := 0
	for f in _pngs("res://art/props/"):
		var img := _load("res://art/props/" + f)
		room_props += 1
		check(img.get_size() == ArtStyle.ROOM_PROP_SIZE, "art/props/%s is %s (40x40)" % [f, img.get_size()])
		_sprite_rules("res://art/props/" + f, img)
	check(room_props >= 20, "room prop files found (%d)" % room_props)
	# Traps: one magic circle laid flat on the floor and tinted per trap, so no outline ring
	var circle := _load("res://art/traps/circle.png")
	check(circle.get_size() == ArtStyle.PROP_SIZE * 2, "art/traps/circle.png is %s (64x64)" % circle.get_size())
	_sprite_rules("res://art/traps/circle.png", circle, false)
	for k in Halls.TRAPS.keys():
		check(Halls.TRAPS[k].has("color"), "trap %s has its circle colour" % k)

	# Effects: palette colors, a few hard alpha steps
	for f in _pngs("res://art/fx/"):
		var img := _load("res://art/fx/" + f)
		var bad := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a8 == 0:
					continue
				if not (c.a8 in ArtStyle.FX_ALPHA) or not ArtStyle.in_palette(c):
					bad += 1
		check(bad == 0, "art/fx/%s: %d pixels with soft alpha or off the palette" % [f, bad])

	# art_info.gd lists every monster file with its real size and feet
	var info: Dictionary = ArtInfo.DATA["enemies"]
	for f in _pngs("res://art/enemies/"):
		var k: String = f.get_basename()
		var img := _load("res://art/enemies/" + f)
		check(info.has(k), "art_info.gd lists " + k)
		if info.has(k):
			check(info[k]["size"] == [img.get_width(), img.get_height()], "art_info size of " + k)
			check(int(info[k]["foot"]) == img.get_used_rect().end.y - 1, "art_info foot of " + k)
	for k in info:
		check(FileAccess.file_exists("res://art/enemies/%s.png" % k), "art_info.gd entry %s has a file" % k)

	# The game stands monsters on their real feet (the old table put bosses' feet mid-body)
	var az := Sprites.enemy_by_key("boss_azgaroth")
	var azi := _load("res://art/enemies/boss_azgaroth.png")
	check(int(az["foot"]) == azi.get_used_rect().end.y - 1, "a tall boss stands on its lowest row")
	var kb := Sprites.enemy_by_key("kobold")
	check(float(kb["foot"]) >= kb["size"].y * 0.8, "a monster's feet are near the bottom of its picture")

	# Item icons: one frame for all
	for slot in ItemPool.TYPES:
		for t in ItemPool.TYPES[slot]:
			var ic := Sprites.item_icon({"slot": slot, "type": t, "rarity": 2})
			check(ic != null and ic.get_width() == ArtStyle.ICON_FRAME and ic.get_height() == ArtStyle.ICON_FRAME, "%s icon is %dx%d" % [t, ArtStyle.ICON_FRAME, ArtStyle.ICON_FRAME])

	# The flame trap is the warm one, the frost trap the cold one
	check(_warmth_c("flames") > _warmth_c("frost"), "flame trap is warmer than frost trap")

	# Hero pixel switch helper: 2x2 blocks, same size
	var hero_img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	hero_img.fill_rect(Rect2i(1, 1, 5, 6), Color.RED)
	var ch := Sprites.chunky(hero_img, 2)
	check(ch.get_size() == hero_img.get_size(), "chunky keeps the size")
	var blocks_ok := true
	for by in range(0, 8, 2):
		for bx in range(0, 8, 2):
			var c0 := ch.get_pixel(bx, by)
			for dy in 2:
				for dx in 2:
					blocks_ok = blocks_ok and ch.get_pixel(bx + dx, by + dy) == c0
	check(blocks_ok, "chunky makes every 2x2 block one color")
	check(ch.get_pixel(2, 2) == Color.RED and ch.get_pixel(6, 6).a8 == 0, "chunky keeps solid blocks solid and clear blocks clear")
	var before := hero_img.get_data()
	check(Sprites.chunky(hero_img, 1).get_data() == before, "pixel size 1 leaves the hero's pixels alone")
	check(hero_img.get_data() == before, "chunky never changes its source image")
	var spec := {"body": "male"}
	var spec2 := Sprites._px_spec(spec)
	check(not spec.has("px") or Sprites.HERO_PIXEL <= 1, "_px_spec doesn't change the caller's spec")
	check((spec2.get("px", 1) == Sprites.HERO_PIXEL) or Sprites.HERO_PIXEL <= 1, "_px_spec adds the pixel size to its copy")

	print("ART RULES DONE, failures: ", fails)
	quit()

## Warm minus cool in a trap's circle colour.
func _warmth_c(kind: String) -> float:
	var c := Color(String(Halls.TRAPS[kind]["color"]))
	return c.r - c.b

func _warmth(img: Image) -> float:
	var t := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 > 0 and c.s > 0.3:
				t += c.r - c.b
	return t
