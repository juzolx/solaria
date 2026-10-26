extends SceneTree
## Hero Fable review sheets: godot --headless -s tests/_fable_hero_probe.gd -- <out dir> (absolute).
## 1 frames: both bodies x 4 weapons, the 7 battle frames + portrait (128-px frames, cell edges drawn)
## 2 builds: every body build as a Mage (staff) and a Warrior (sword)
## 3 looks: race signatures, awakening looks and the Fallen Angel (battle idle + portrait)
## 4 portraits: the menu portrait crop of 13 classes holding their own weapon, 3x
const BG := Color("#1e1c24")
const EDGE := Color("#3a3646")
var out_dir := "res://shots"

func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		out_dir = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_frames()
	_builds()
	_looks()
	_portraits()
	print("FABLE HERO PROBE DONE ", out_dir)
	quit()

func _looks_for(cls: String, weapon: String) -> Dictionary:
	return {"Class": {"cls": cls, "tier": 0}, "Weapon": {"type": weapon, "glow": false}}

## One row: the 7 battle frames then the 2 portrait frames.
func _row(app: Dictionary, cls: String, weapon: String) -> Array:
	var back := HeroArt.frames(app, cls, 0, weapon, true)
	var front := HeroArt.frames(app, cls, 0, weapon, false)
	var row: Array = []
	for i in 7:
		row.append(back["img"][i])
	row.append(front["img"][7]); row.append(front["img"][8])
	return row

func _sheet(rows: Array, name: String, scale := 2) -> void:
	var f := HeroArt.FRAME
	var cols := 0
	for r in rows:
		cols = maxi(cols, (r as Array).size())
	var img := Image.create(f * cols, f * rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(BG)
	for j in rows.size():
		for i in (rows[j] as Array).size():
			var cell: Image = rows[j][i]
			var at := Vector2i(i * f, j * f)
			img.fill_rect(Rect2i(at, Vector2i(f, 1)), EDGE); img.fill_rect(Rect2i(at, Vector2i(1, f)), EDGE)
			if cell != null:
				img.blend_rect(cell, Rect2i(0, 0, f, f), at)
	img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.save_png(out_dir.path_join(name))

func _frames() -> void:
	var rows := []
	for body in ["masc", "fem"]:
		for w in [["Warrior", "sword"], ["Mage", "staff"], ["Knight", "spear"], ["Ranger", "bow"]]:
			rows.append(_row({"body": body, "race": "Human", "skin": 1, "hair": "Long" if body == "fem" else "Short", "hair_color": 1}, w[0], w[1]))
	_sheet(rows, "1_frames.png")

func _builds() -> void:
	var rows := []
	for race in ["Orc", "Goblin", "Dwarf", "Fairy"]:
		for body in ["masc", "fem"]:
			var app := {"body": body, "race": race, "skin": Races.skins(race)[0], "hair_color": 1}
			rows.append(_row(app, "Mage", "staff"))
			rows.append(_row(app, "Warrior", "sword"))
	for body in ["masc", "fem"]:
		rows.append(_row({"body": body, "race": "Human", "form": "Werewolf", "skin": 1, "hair_color": 1}, "Warrior", "axe"))
	_sheet(rows, "2_builds.png")

func _looks() -> void:
	var list := [["Angel", "", ""], ["Angel", "", "wings2"], ["Angel", "", "wings3"], ["Angel", "Fallen Angel", ""],
		["Demon", "", ""], ["Demon", "", "horns_big"], ["Demon", "", "crown"], ["Undead", "", ""],
		["Elf", "", "glow"], ["Dwarf", "", "crown"], ["Fairy", "", "wings_big"], ["Beastkin", "", "glow"]]
	var rows := []
	for body in ["masc", "fem"]:
		var row := []
		for l in list:
			var app := {"body": body, "race": l[0], "skin": Races.skins(l[0])[0], "hair_color": 1}
			if l[1] != "":
				app["form"] = l[1]
			if l[2] != "":
				app["look"] = l[2]
			row.append(HeroArt.frames(app, "Cleric", 0, "mace", true)["img"][0])
		rows.append(row)
		var row2 := []
		for l in list:
			var app := {"body": body, "race": l[0], "skin": Races.skins(l[0])[0], "hair_color": 1}
			if l[1] != "":
				app["form"] = l[1]
			if l[2] != "":
				app["look"] = l[2]
			row2.append(HeroArt.frames(app, "Cleric", 0, "mace", false)["img"][7])
		rows.append(row2)
	_sheet(rows, "3_looks.png")

func _portraits() -> void:
	var p := Sprites.PORTRAIT
	var names: Array = Classes.CLASSES.keys()
	var img := Image.create(p * 7, p * 4, false, Image.FORMAT_RGBA8)
	img.fill(BG)
	var i := 0
	for body in ["masc", "fem"]:
		for c in names:
			if i >= 28:
				break
			var w := str(Classes.CLASSES[c].get("look", {}).get("Weapon", "sword"))
			var app := {"body": body, "race": "Human", "skin": 1, "hair": "Long" if body == "fem" else "Short", "hair_color": 1}
			var tex := Sprites.portrait(app, {"Class": {"cls": c, "tier": 0}, "Weapon": Sprites.gear_look({"slot": "Weapon", "type": w, "rarity": 1})})
			var im := tex.get_image()
			img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % 7) * p, (i / 7) * p))
			i += 1
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(out_dir.path_join("4_portraits.png"))
