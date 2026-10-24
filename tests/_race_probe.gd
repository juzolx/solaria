extends SceneTree
## Every standard-body race on both bodies (battle idle, attack, hit, portrait) into shots/race_probe.png.
const RACES := ["Human", "Elf", "Angel", "Demon", "Beastkin", "Dragonkin", "Undead", "Vampire", "Lich", "Goblin", "Goblin", "Dwarf", "Dwarf"]
const CLASSES := ["Warrior", "Mage", "Ranger", "Knight", "Cleric", "Nightstalker", "Conjurer", "Bard", "Acolyte", "Ranger", "Wanderer", "Knight", "Cleric"]
func _initialize() -> void:
	var cols := [0, 3, 6]  # battle idle, attack (raised), hit
	var sheet := Image.create(96 * 8, 96 * RACES.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#1e1c24"))
	for r in RACES.size():
		for bi in 2:
			var app := {"body": ["masc", "fem"][bi], "race": RACES[r], "skin": Races.skins(RACES[r])[0], "hair": ["Short", "Long"][bi], "hair_color": 1, "face": "smile"}
			var looks := {"Class": {"cls": CLASSES[r], "tier": 0}, "Weapon": {"type": "sword", "glow": false}}
			var back: Dictionary = Sprites.hero_back(app, looks)["lpc"]
			var frames: Array = back["combat_idle"]["img"] + back["slash"]["img"] + back["hurt"]["img"]
			var front: Array = Sprites.hero(app, looks)["lpc"]["combat_idle"]["img"]
			var row := [frames[0], frames[3], frames[6], front[0]]
			for i in row.size():
				sheet.blend_rect(row[i], Rect2i(0, 0, 96, 96), Vector2i((bi * 4 + i) * 96, r * 96))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/race_probe.png")
	print("RACE PROBE DONE")
	quit()
