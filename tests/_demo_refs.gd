extends SceneTree
## Dumps one hero portrait (with the current sword held), one monster and one consumable icon as PNGs (read-only audit helper).
##   godot --headless --path . -s tests/_demo_refs.gd -- --out=C:/some/folder
func _initialize() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var app := {"body": "masc", "race": "Human", "skin": 1, "hair": "Short", "hair_color": 1}
	var tex := Sprites.portrait(app, {"Class": {"cls": "Warrior", "tier": 0}, "Weapon": Sprites.gear_look({"slot": "Weapon", "type": "sword", "rarity": 1})})
	tex.get_image().save_png(out + "hero.png")
	var m := (load("res://art/enemies/ankou.png") as Texture2D).get_image()
	m.save_png(out + "monster.png")
	Sprites.item_icon({"slot": "Weapon", "type": "sword", "rarity": 2}).get_image().save_png(out + "old_sword.png")
	Sprites.item_icon({"slot": "Weapon", "type": "axe", "rarity": 2}).get_image().save_png(out + "old_axe.png")
	Sprites.item_icon({"slot": "Weapon", "type": "bow", "rarity": 2}).get_image().save_png(out + "old_bow.png")
	Sprites.item_icon({"slot": "Weapon", "type": "staff", "rarity": 2}).get_image().save_png(out + "old_staff.png")
	var c := Sprites.consumable_icon("potion")
	if c:
		c.get_image().save_png(out + "potion.png")
	print("refs ok ", m.get_size(), tex.get_size())
	quit()
