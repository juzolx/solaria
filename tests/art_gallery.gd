extends SceneTree
## Renders heroes through the real game pipeline (key colors, layers, gear) into one picture.
func _initialize() -> void:
	var combos := []
	var races := Races.ORDER
	var hairs := Sprites.HAIR_STYLES
	var gear_sets := [
		{},
		{"Chest": "plate", "Legs": "greaves", "Feet": "sabatons", "Helmet": "helm", "Weapon": "sword", "Off Hand": "shield"},
		{"Chest": "tunic", "Legs": "leggings", "Feet": "boots", "Helmet": "hood", "Weapon": "bow"},
		{"Chest": "robe", "Feet": "sandals", "Weapon": "staff", "Off Hand": "tome"},
		{"Chest": "tunic", "Legs": "pants", "Feet": "boots", "Helmet": "cap", "Weapon": "dagger"},
		{"Chest": "plate", "Legs": "pants", "Feet": "boots", "Helmet": "crown", "Weapon": "axe", "Cape": true},
	]
	var i := 0
	for r in races:
		var app := {"body": "masc" if i % 2 == 0 else "fem", "skin": 1 + (i % 4), "hair": hairs[i % hairs.size()], "hair_color": i % 17, "eyes": i % 7, "race": r}
		var rs: Array = Races.INFO[r].get("skins", [])
		if not rs.is_empty():
			app["skin"] = rs[0]
		combos.append([app, gear_sets[i % gear_sets.size()]])
		i += 1
	for h in hairs.size():
		combos.append([{"body": "masc" if h < 7 else "fem", "skin": 1, "hair": hairs[h], "hair_color": (h * 3) % 17, "eyes": 0, "race": "Human"}, {}])
	var cell := Sprites.CANVAS
	var cols := 9
	var rows := int(ceil(combos.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#0f172a"))
	for k in combos.size():
		var c: Array = combos[k]
		var looks := {}
		var gs: Dictionary = c[1]
		for slot in gs:
			if slot == "Cape":
				looks["Cape"] = {"type": "cape", "mat": "cloth", "ramp": Sprites.ramp_from(Color("#b02e40")), "trim": Color("#fde047"), "glow": false}
			else:
				looks[slot] = Sprites.gear_look({"slot": slot, "type": gs[slot], "rarity": 3})
		var tex := Sprites.portrait(c[0], looks)
		var img := tex.get_image()
		sheet.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((k % cols) * cell, (k / cols) * cell))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png("/root/shots/v11_art_gallery.png")
	print("gallery ok")
	quit()
