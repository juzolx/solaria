extends SceneTree
## Saves a sheet of every pose for a hero and some monsters (to check the animation art).
func _initialize() -> void:
	var looks := {"Weapon": Sprites.gear_look({"slot": "Weapon", "type": "sword", "rarity": 2}), "Chest": Sprites.gear_look({"slot": "Chest", "type": "plate", "rarity": 2}),
		"Helmet": Sprites.gear_look({"slot": "Helmet", "type": "helm", "rarity": 2}), "Legs": Sprites.gear_look({"slot": "Legs", "type": "greaves", "rarity": 1})}
	var h := Sprites.hero({"body": "masc", "skin": 1, "hair": "Short", "hair_color": 2, "eyes": 0, "race": "Human"}, looks)
	var rows: Array = []
	rows.append(Sprites.poses_for("hsheet", h["body_img"], 1, int(h["hand"].y)))
	for k in ["kobold", "redcap", "cyclops", "boss_grendel"]:
		var e := Sprites.enemy_by_key(k)
		rows.append(Sprites.poses_for("esheet" + k, (e["tex"] as Texture2D).get_image(), -1))
	var S := 4
	var cell := 48 * S + 8
	var names: Array = Sprites.POSES.keys()
	var sheet := Image.create(cell * names.size(), cell * rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#262b44"))
	for r in rows.size():
		for i in names.size():
			var img: Image = (rows[r][names[i]]["tex"] as Texture2D).get_image()
			img.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(i * cell + (cell - img.get_width()) / 2, r * cell + cell - img.get_height() - 4))
	sheet.save_png("/tmp/claude-0/prev/poses.png")
	print("poses: ", names)
	quit()
