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

func _native_rules(path: String, img: Image) -> void:
	check(img.get_width() <= ArtStyle.NATIVE_MAX.x and img.get_height() <= ArtStyle.NATIVE_MAX.y, "%s is %s (at most %s)" % [path, img.get_size(), ArtStyle.NATIVE_MAX])
	var colors := {}
	var soft := 0
	var bare := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			if c.a8 != 255:
				soft += 1
			colors[c.to_rgba32()] = true
			if ArtStyle.is_outline(c):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height() or img.get_pixel(nx, ny).a8 == 0:
					bare += 1
					break
	check(colors.size() <= ArtStyle.NATIVE_COLORS, "%s: %d colours (at most %d)" % [path, colors.size(), ArtStyle.NATIVE_COLORS])
	check(soft == 0, "%s: %d soft (half see-through) pixels" % [path, soft])
	check(bare == 0, "%s: %d edge pixels without the dark outline" % [path, bare])

## Fable r1: on a 430 pt phone (504 design wide, 0.853 stretch) every monster must show at the
## hero's 3x inside its share of the stage (battle_view._width_cap): commons 56%, bosses 92%,
## Calamities 96%. A wider picture would drop to 2x and look smaller than a common.
func _phone_width(key: String, w: int) -> void:
	var share := 0.96 if key.begins_with("calamity_") else (0.92 if key.begins_with("boss_") else 0.56)
	check(w * 3 <= int(504.0 * share * 0.853), "%s is %d px wide: over %d it draws below 3x on a phone" % [key, w, int(504.0 * share * 0.853) / 3])

## Fable pets R2: every 32 px pet still has a dark silhouette (half its edge pixels near-black by
## their brightest channel, so pale pets read on pale halls) and no idle frame ends below the
## still (a bob goes up from the ground). Fix with claude/pets2/tools/outline.gd / idle_fix.gd.
func _pet32_rules() -> void:
	var dir := "res://art/pets/32/"
	for f in _pngs(dir):
		if f.ends_with("_idle.png"):
			continue
		var img := _load(dir + f)
		var edge := 0
		var dark := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a <= 0.5:
					continue
				var open := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x < 0 or n.y < 0 or n.x >= img.get_width() or n.y >= img.get_height() or img.get_pixelv(n).a <= 0.5:
						open = true
						break
				if open:
					edge += 1
					var c := img.get_pixel(x, y)
					if maxf(c.r, maxf(c.g, c.b)) * 255.0 < 70.0:
						dark += 1
		check(edge > 0 and dark >= edge * 0.5, "pet %s has a dark outline (%d of %d edge pixels)" % [f, dark, edge])
		var strip_path: String = dir + String(f).get_basename() + "_idle.png"
		if FileAccess.file_exists(strip_path):
			var strip := _load(strip_path)
			for fi in 2:
				check(strip.get_region(Rect2i(fi * 32, 0, 32, 32)).get_used_rect().end.y <= img.get_used_rect().end.y, "pet %s idle frame %d stays above its ground row" % [f, fi])

func _initialize() -> void:
	check(not ArtStyle.in_palette(ArtStyle.OUTLINE), "the outline color is not a palette color")
	check(ArtStyle.in_palette(Color(ArtStyle.PALETTE[3])), "palette colors are in the palette")

	# Monsters, bosses, Calamities and companions: 68x68 (giants 68x132), on a 2x grid.
	# Redrawn monsters are native art ("hd": 1 in art_info.gd): 1 file pixel = 1 art pixel,
	# any size up to ArtStyle.NATIVE_MAX, their own few colours, hard alpha and a closed outline.
	var monsters := 0
	var native_info: Dictionary = ArtInfo.DATA["enemies"]
	for d in ["res://art/enemies/", "res://art/pets/"]:
		for f in _pngs(d):
			var img := _load(d + f)
			monsters += 1
			if d == "res://art/enemies/" and int(native_info.get(f.get_basename(), {}).get("hd", 2)) == 1:
				_native_rules(d + f, img)
				_phone_width(f.get_basename(), img.get_width())
				continue
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
	# People (room strangers, travelers, town keepers): 64x64, hard alpha, every keeper drawn
	for f in _pngs("res://art/people/"):
		var img := _load("res://art/people/" + f)
		check(img.get_size() == Vector2i(64, 64), "art/people/%s is %s (64x64)" % [f, img.get_size()])
		var soft := 0
		for y in img.get_height():
			for x in img.get_width():
				var a8 := img.get_pixel(x, y).a8
				if a8 != 0 and a8 != 255:
					soft += 1
		check(soft == 0, "art/people/%s: %d soft pixels" % [f, soft])
	for page in Lore.KEEPER_ART.keys():
		check(Lore.keeper_art(int(page)) != null, "keeper picture for town page %d" % int(page))

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

	# 2.1 heroes (art/heroes, baked from the PixelLab hero): every layer on the same 9 frames of 96x96,
	# hard alpha, the feet on one row, every class on both bodies, the 37 styles, 10 faces, 7 weapons
	check(HeroArt.available(), "the 2.1 hero art is baked (art/heroes/heroes.json)")
	var hi := HeroArt.info()
	check(int(hi.get("cell", 0)) == HeroArt.CELL and (hi.get("frames", []) as Array).size() == 9, "hero frames: 9 cells of 96x96")
	for cls in Classes.ORDER:
		for b in ["m", "f"]:
			check(0 in (hi.get("classes", {}).get(cls.to_lower(), {}).get(b, []) as Array).map(func(t): return int(t)), "%s outfit for body %s" % [cls, b])
	check((hi.get("styles", {}) as Dictionary).size() == Sprites.HAIR_STYLES.size(), "every hair style is drawn on the new hero")
	for st in Sprites.HAIR_STYLES:
		check((hi.get("styles", {}) as Dictionary).has(st), "hair style %s drawn" % st)
	check((hi.get("faces", []) as Array) == HeroArt.FACES, "the 10 faces")
	for wt in ["sword", "dagger", "axe", "mace", "spear", "bow", "staff"]:
		check(wt in hi.get("weapons", []), "weapon drawing " + wt)
	for b in ["m", "f"]:
		for f in _pngs("res://art/heroes/%s/" % b):
			var img := _load("res://art/heroes/%s/%s" % [b, f])
			check(img.get_height() == HeroArt.CELL and img.get_width() % HeroArt.CELL == 0, "art/heroes/%s/%s is whole 96x96 cells" % [b, f])
			if f.ends_with("_idx.png"):
				continue
			var soft := 0
			for y in img.get_height():
				for x in img.get_width():
					var a8 := img.get_pixel(x, y).a8
					if a8 != 0 and a8 != 255:
						soft += 1
			check(soft == 0, "art/heroes/%s/%s: %d soft pixels" % [b, f, soft])
			if f.begins_with("outfit_"):
				for i in img.get_width() / HeroArt.CELL:
					var used := img.get_region(Rect2i(i * HeroArt.CELL, 0, HeroArt.CELL, HeroArt.CELL)).get_used_rect()
					check(used.end.y - 1 == Sprites.HERO_FOOT - 8, "art/heroes/%s/%s frame %d stands on the feet row" % [b, f, i])
	# The hero builds from the layers, battle and portrait, recoloured, for any class/tier/weapon
	var hb := Sprites.hero_back({"body": "fem", "skin": 6, "hair": "Braid", "hair_color": 8, "race": "Orc", "face": "grim"},
		{"Class": {"cls": "Knight", "tier": 75}, "Weapon": {"type": "spear", "glow": false}})
	check(hb.get("pl", false) and (hb["lpc"]["combat_idle"]["tex"] as Array).size() == 2 and (hb["lpc"]["slash"]["tex"] as Array).size() == 4 and (hb["lpc"]["hurt"]["tex"] as Array).size() == 1, "battle frames: idle 2, attack 4, hit 1")
	var hf := Sprites.hero({"body": "masc", "hair": "Afro", "face": "laughing"}, {"Class": {"cls": "Bard", "tier": 0}})
	check(hf.get("pl", false) and (hf["lpc"]["combat_idle"]["tex"] as Array).size() == 2, "portrait frames: idle 2")
	var plain := HeroArt.frames({"body": "masc", "skin": 1, "hair_color": 1}, "Mage", 0, "", false)["img"][7] as Image
	var tinted := HeroArt.frames({"body": "masc", "skin": 6, "hair_color": 8}, "Mage", 0, "", false)["img"][7] as Image
	check(plain.get_data() != tinted.get_data(), "skin and hair colours recolour the hero")
	check(HeroArt.outfit_key("Warrior", 80, "m").ends_with("_t75") and HeroArt.outfit_key("Mage", 75, "m") == "m/outfit_mage", "tier outfits only where drawn")
	# Standard-body races wear their signature on both bodies (ears, wings, horns...), recoloured with the race skin
	for race in ["Elf", "Angel", "Demon", "Beastkin", "Dragonkin", "Undead", "Vampire", "Lich"]:
		for b in ["m", "f"]:
			check(HeroArt.race_key({"race": race}, b) != "", "%s signature on body %s" % [race, b])
	check(HeroArt.race_key({"race": "Human"}, "m") == "", "humans have no race layer")
	var elf := HeroArt.frames({"body": "masc", "race": "Elf"}, "Warrior", 0, "", true)["img"][0] as Image
	var hum := HeroArt.frames({"body": "masc", "race": "Human"}, "Warrior", 0, "", true)["img"][0] as Image
	check(elf.get_used_rect().size.x > hum.get_used_rect().size.x, "elf ears widen the silhouette from behind")
	# Transformations wear their own art: a bitten human turns werewolf (the orc build plus wolf head and tail)
	check(HeroArt.race_key({"race": "Human", "form": "Vampire"}, "m") == "m/race_vampire", "a vampire form wears the vampire layer")
	for b in ["masc", "fem"]:
		var ww := {"body": b, "race": "Human", "form": "Werewolf"}
		check(HeroArt.build_dir(ww).begins_with("orc_"), "a werewolf (%s) uses the orc build" % b)
		var orc := HeroArt.frames({"body": b, "race": "Orc"}, "Warrior", 0, "", true)["img"][0] as Image
		var wolf := HeroArt.frames(ww, "Warrior", 0, "", true)["img"][0] as Image
		check(wolf.get_used_rect().size.y > orc.get_used_rect().size.y, "the werewolf's ears and tail stretch the orc silhouette (%s)" % b)
	# Golem is no longer playable: its art stays in art/heroes/golem_m but no hero wears it
	# (an old slot summary that still says Golem draws the Dwarf it became)
	check(HeroArt.build_dir({"body": "masc", "race": "Golem"}).begins_with("dwarf_"), "no golem body build is offered: a Golem draws as a Dwarf")
	# Fairies are the Tiny build: shorter than a human and hovering above the feet row
	# (the body layer alone: the butterfly wings sit behind and their tails hang below the feet)
	var fdir := HeroArt.build_dir({"body": "masc", "race": "Fairy"})
	var fay := HeroArt._img(fdir + "/outfit_plate.png").get_region(Rect2i(0, 0, HeroArt.CELL, HeroArt.CELL)).get_used_rect()
	var man := (HeroArt.frames({"body": "masc", "race": "Human"}, "Warrior", 0, "", true)["img"][0] as Image).get_used_rect()
	check(fay.size.y < man.size.y * 0.85 and fay.end.y < man.end.y, "a fairy is tiny and floats")
	# ONE scale: battle draws every art pixel at the same whole number of screen pixels
	check(ArtStyle.unit(1.0) == 3 and ArtStyle.unit(2.0) == 6 and ArtStyle.unit(1.0 / 3.0) == 1, "one integer battle scale (3 pt per art pixel)")
	_pet32_rules()
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
