extends SceneTree
## Times a 2.1 hero build (battle + portrait) and saves a sheet of a few heroes to shots/hero_probe.png.
func _initialize() -> void:
	var t0 := Time.get_ticks_usec()
	var app := {"body": "fem", "skin": 2, "hair": "Braid", "hair_color": 3, "race": "Human", "face": "smile"}
	var looks := {"Class": {"cls": "Ranger", "tier": 0}, "Weapon": {"type": "bow", "glow": false}}
	var back := Sprites.hero_back(app, looks)
	var t1 := Time.get_ticks_usec()
	var front := Sprites.portrait(app, looks)
	var t2 := Time.get_ticks_usec()
	print("HERO PROBE: battle frames %.1f ms, portrait %.1f ms" % [(t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	var sheet := Image.create(96 * 9, 96 * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#1e1c24"))
	var heroes := [[app, looks], [{"body": "masc", "skin": 0, "hair": "Shaggy", "hair_color": 1, "race": "Human"}, {"Class": {"cls": "Warrior", "tier": 75}, "Weapon": {"type": "sword", "glow": false}}],
		[{"body": "masc", "skin": 6, "hair": "Mohawk", "hair_color": 5, "race": "Orc", "face": "fierce"}, {"Class": {"cls": "Knight", "tier": 0}, "Weapon": {"type": "axe", "glow": false}}],
		[{"body": "fem", "skin": 9, "hair": "Long", "hair_color": 8, "race": "Elf", "face": "sleepy"}, {"Class": {"cls": "Conjurer", "tier": 0}, "Weapon": {"type": "staff", "glow": false}}]]
	for r in heroes.size():
		var bk := Sprites.hero_back(heroes[r][0], heroes[r][1])
		var an: Dictionary = bk["lpc"]
		var i := 0
		for nm in ["combat_idle", "slash", "hurt"]:
			for im in an[nm]["img"]:
				sheet.blend_rect(im, Rect2i(0, 0, 96, 96), Vector2i(i * 96, r * 96))
				i += 1
		var fr: Dictionary = Sprites.hero(heroes[r][0], heroes[r][1])["lpc"]
		for im in fr["combat_idle"]["img"]:
			sheet.blend_rect(im, Rect2i(0, 0, 96, 96), Vector2i(i * 96, r * 96))
			i += 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/hero_probe.png")
	quit()
