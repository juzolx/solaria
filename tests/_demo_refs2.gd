extends SceneTree
## Read-only audit helper: dumps the hero's held-weapon sheet cells (cropped) and the hero portrait holding each weapon.
func _initialize() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	for t in ["sword", "axe", "dagger", "mace", "spear", "bow", "staff"]:
		var im := (load("res://art/heroes/m/weapon_%s.png" % t) as Texture2D).get_image()
		im.convert(Image.FORMAT_RGBA8)
		var cw := im.get_width() / 9
		print(t, " sheet ", im.get_size(), " cell ", cw)
		for i in 9:
			var cell := im.get_region(Rect2i(i * cw, 0, cw, im.get_height()))
			var u := cell.get_used_rect()
			if u.size.x > 0:
				cell.get_region(u).save_png(out + "w_%s_%d.png" % [t, i])
				print("  cell ", i, " used ", u.size)
		var app := {"body": "masc", "race": "Human", "skin": 1, "hair": "Short", "hair_color": 1}
		var tex := Sprites.portrait(app, {"Class": {"cls": "Warrior", "tier": 0}, "Weapon": Sprites.gear_look({"slot": "Weapon", "type": t, "rarity": 1})})
		tex.get_image().save_png(out + "hero_%s.png" % t)
	quit()
