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

## Fable r2: monsters must not sink into their dark halls (38-94 mean luma): the whole picture,
## outline included, averages at least 68 (commons) or 60 (bosses and Calamities, which glow).
func _luma_floor(key: String, img: Image) -> void:
	var total := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			total += 0.299 * c.r8 + 0.587 * c.g8 + 0.114 * c.b8
			n += 1
	var floor_y := 59.5 if key.begins_with("boss_") or key.begins_with("calamity_") else 67.5
	check(n > 0 and total / n >= floor_y, "%s averages luma %.1f (at least %.0f, monster_import.py lifts it)" % [key, total / maxi(1, n), floor_y + 0.5])

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
				_luma_floor(f.get_basename(), img)
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

	# 2.1 heroes (art/heroes, baked from the PixelLab hero): every layer on the same 9 frames of 96x96 (weapons 128),
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
	# every body folder: the two standard bodies and each build's (goblin_m, orc_f...)
	var dirs: Array = ["m", "f"]
	for race in hi.get("builds", {}):
		for body in (hi["builds"][race]["bodies"] as Dictionary):
			var d := "%s_%s" % [hi["builds"][race]["key"], body]
			if not d in dirs:
				dirs.append(d)
	check(dirs.size() == 10, "hero body folders: m, f and 8 builds (%d)" % dirs.size())
	check(not DirAccess.dir_exists_absolute("res://art/heroes/golem_m"), "the retired golem is not shipped")
	for b in dirs:
		for f in _pngs("res://art/heroes/%s/" % b):
			var img := _load("res://art/heroes/%s/%s" % [b, f])
			# weapons swing past the body, so their cells are the whole padded frame (128); the rest are 96
			var n := HeroArt.FRAME if f.begins_with("weapon_") else HeroArt.CELL
			check(img.get_height() == n and img.get_width() % n == 0, "art/heroes/%s/%s is whole %dx%d cells" % [b, f, n, n])
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
	# Registration (Fable hero R2 item 13): frames of one body agree with each other
	for b in dirs:
		var c := HeroArt.CELL
		var out := _load("res://art/heroes/%s/outfit_%s.png" % [b, "warrior" if b in ["m", "f"] else "plate"])
		var t0 := out.get_region(Rect2i(0, 0, c, c)).get_used_rect().position.y
		for i in [2, 6]:  # (a) the head doesn't jump between the idle and the swing or the hit
			var ti := out.get_region(Rect2i(i * c, 0, c, c)).get_used_rect().position.y
			check(absi(ti - t0) <= 3, "%s outfit top idle %d vs frame %d: %d (a lurch)" % [b, t0, i, ti])
		var hands: Array = hi["hand"][b]
		for wt in hi.get("weapons", []):
			var w := _load("res://art/heroes/%s/weapon_%s.png" % [b, wt])
			var fs := HeroArt.FRAME
			for i in 9:
				var cell := w.get_region(Rect2i(i * fs, 0, fs, fs))
				var used := cell.get_used_rect()
				var h := Vector2i(int(hands[i][0]) + HeroArt.PAD, int(hands[i][1]) + HeroArt.PAD)
				var near := false  # (b) the hand holds the weapon
				for y in range(maxi(0, h.y - 3), mini(fs, h.y + 4)):
					for x in range(maxi(0, h.x - 3), mini(fs, h.x + 4)):
						near = near or cell.get_pixel(x, y).a8 > 0
				check(near, "%s weapon_%s frame %d: the hand %s holds it" % [b, wt, i, h])
				# (c) at rest the weapon stays above the floor and inside the portrait crop
				var low := (HeroArt.FOOT + HeroArt.PAD) if i in [0, 1, 6] else (99 if i >= 7 else fs)
				check(used.end.y - 1 <= low, "%s weapon_%s frame %d reaches row %d (under %d)" % [b, wt, i, used.end.y - 1, low])
		if FileAccess.file_exists("res://art/heroes/%s/look_crown.png" % b):  # (d) the crown stays on the head
			var cr := _load("res://art/heroes/%s/look_crown.png" % b)
			var x0 := cr.get_region(Rect2i(0, 0, c, c)).get_used_rect().get_center().x
			for i in 7:
				var xi := cr.get_region(Rect2i(i * c, 0, c, c)).get_used_rect().get_center().x
				check(absf(xi - x0) <= 3.0, "%s crown frame %d at x %.0f, idle at %.0f" % [b, i, xi, x0])
			if b in ["m", "f"]:
				var hs := _load("res://art/heroes/%s/hair_short.png" % b).get_region(Rect2i(0, 0, c, c)).get_used_rect()
				check(absf(x0 - hs.get_center().x) <= 3.0, "%s crown centred on the hair (%.0f vs %.0f)" % [b, x0, hs.get_center().x])
	# The dyed share of the build outfits (the class colour must read on every family)
	for b in dirs:
		if b in ["m", "f"]:
			continue
		for fam in ["plate", "robe", "leather", "cloth"]:
			var ip := "res://art/heroes/%s/outfit_%s_idx.png" % [b, fam]
			if not FileAccess.file_exists(ip):
				continue
			var ix := _load(ip)
			var col := _load("res://art/heroes/%s/outfit_%s.png" % [b, fam])
			var tot := 0
			var dyed := 0
			for y in HeroArt.CELL:
				for x in HeroArt.CELL:
					var q := ix.get_pixel(x, y)
					if col.get_pixel(x, y).a8 == 0 or q.r8 > 0 or q.g8 > 0:
						continue
					tot += 1
					if q.b8 > 0:
						dyed += 1
			check(dyed * 100 >= tot * 15, "%s outfit_%s idle0: %d of %d pixels dyed (under 15%%: the tiny fairy plate is mostly metal at 19%%)" % [b, fam, dyed, tot])
	# The hero builds from the layers, battle and portrait, recoloured, for any class/tier/weapon
	var hb := Sprites.hero_back({"body": "fem", "skin": 6, "hair": "Braid", "hair_color": 8, "race": "Orc", "face": "grim"},
		{"Class": {"cls": "Knight", "tier": 75}, "Weapon": {"type": "spear", "glow": false}})
	check(hb.get("pl", false) and (hb["anims"]["combat_idle"]["tex"] as Array).size() == 2 and (hb["anims"]["slash"]["tex"] as Array).size() == 4 and (hb["anims"]["hurt"]["tex"] as Array).size() == 1, "battle frames: idle 2, attack 4, hit 1")
	var hf := Sprites.hero({"body": "masc", "hair": "Afro", "face": "laughing"}, {"Class": {"cls": "Bard", "tier": 0}})
	check(hf.get("pl", false) and (hf["anims"]["combat_idle"]["tex"] as Array).size() == 2, "portrait frames: idle 2")
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
