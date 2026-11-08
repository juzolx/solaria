extends SceneTree
## Audit helper (read-only): dumps weapon icons as the bag (44 box) and the shop's featured box (64) show them,
## and the hero holding each weapon type, for before/after sheets.
##   godot --headless --path . -s tests/_weapons_final_dump.gd -- --out=C:/folder
func _initialize() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var names: Array = []
	var items: Array = []
	for t in ["sword", "axe", "dagger", "mace", "spear", "bow", "staff"]:
		for r in [0, 2, 4]:
			items.append([ "%s_r%d" % [t, r], {"slot": "Weapon", "type": t, "rarity": r}])
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			if String(u["slot"]) == "Weapon":
				items.append(["u_" + String(u["id"]), GameData.make_unique(u, 50, 1)])
	for sid in GameData.SETS:
		if GameData.SETS[sid]["pieces"].has("Weapon"):
			items.append(["set_" + sid, GameData.make_set_item(sid, "Weapon", 50, 1)])
	for it in items:
		var tex: ImageTexture = Sprites.item_icon(it[1])
		tex.get_image().save_png(out + "%s_raw.png" % it[0])
		UiIcons.big(tex, 44).get_image().save_png(out + "%s_bag.png" % it[0])
		UiIcons.big(tex, 64).get_image().save_png(out + "%s_shop.png" % it[0])
		UiIcons.big(tex, 76).get_image().save_png(out + "%s_shop76.png" % it[0])
		names.append(it[0])
	for t in ["sword", "axe", "dagger", "mace", "spear", "bow", "staff"]:
		var app := {"body": "masc", "race": "Human", "skin": 1, "hair": "Short", "hair_color": 1}
		var tex := Sprites.portrait(app, {"Class": {"cls": "Warrior", "tier": 0}, "Weapon": Sprites.gear_look({"slot": "Weapon", "type": t, "rarity": 1})})
		tex.get_image().save_png(out + "hero_%s.png" % t)
		# the fight view: the hero from behind, idle frame 0
		var fr: Dictionary = HeroArt.frames({"body": "masc", "race": "Human", "skin": 1, "hair": "Short", "hair_color": 1}, "Warrior", 0, t, true)
		(fr["img"][0] as Image).save_png(out + "fight_%s.png" % t)
	print("dumped ", names.size())
	quit()
