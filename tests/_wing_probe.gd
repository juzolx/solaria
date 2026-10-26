extends SceneTree
## The fairy's wings on a few frames (idle open, idle flap, attack, portrait; both bodies), 3x,
## into shots/wings_<style>.png. godot --headless -s tests/_wing_probe.gd -- monarch
func _initialize() -> void:
	var style: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "wings"
	var sheet := Image.create(96 * 8, 96, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#1e1c24"))
	for bi in 2:
		var app := {"body": ["masc", "fem"][bi], "race": "Fairy", "skin": Races.skins("Fairy")[0], "hair_color": 1}
		var looks := {"Class": {"cls": "Warrior", "tier": 0}, "Weapon": {"type": "sword", "glow": false}}
		var back: Dictionary = Sprites.hero_back(app, looks)["anims"]
		var fr: Array = back["combat_idle"]["img"] + back["slash"]["img"]
		var row := [fr[0], fr[1], fr[4], Sprites.hero(app, looks)["anims"]["combat_idle"]["img"][0]]
		for i in row.size():
			sheet.blend_rect(row[i], Rect2i(0, 0, 96, 96), Vector2i((bi * 4 + i) * 96, 0))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/wings_%s.png" % style)
	print("WING PROBE DONE ", style)
	quit()
