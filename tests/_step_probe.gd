extends SceneTree
## HeroArt.steps on the portrait frame for a few races: idle, step L, step R (2x), then the same at half size.
## godot --headless -s tests/_step_probe.gd  -> shots/steps.png
func _initialize() -> void:
	var races := ["Human", "Elf", "Dwarf", "Orc", "Goblin", "Werewolf"]
	var sheet := Image.create(96 * 3 * races.size(), 96 + 48, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#1e1c24"))
	for ri in races.size():
		var app := {"body": "masc" if ri % 2 == 0 else "fem", "race": races[ri], "skin": Races.skins(races[ri])[0], "hair_color": 1}
		var looks := {"Class": {"cls": "Warrior", "tier": 0}, "Weapon": {"type": "sword", "glow": false}}
		var im: Image = Sprites.hero(app, looks)["lpc"]["combat_idle"]["img"][0]
		var row := [im] + HeroArt.steps(im)
		for i in 3:
			var x := (ri * 3 + i) * 96
			sheet.blend_rect(row[i], Rect2i(0, 0, 96, 96), Vector2i(x, 0))
			var h := (row[i] as Image).duplicate() as Image
			h.resize(48, 48, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(h, Rect2i(0, 0, 48, 48), Vector2i(x + 24, 96))
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/steps.png")
	print("STEP PROBE DONE")
	quit()
