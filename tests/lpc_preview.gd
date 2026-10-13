extends SceneTree
## Saves every animation frame of a few LPC heroes to /root/shots/lpcanim/ (for previews).
func _initialize() -> void:
	var heroes := [
		["death_knight", {"body": "masc", "skin": 12, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"},
			{"Weapon": ["sword", "dark"], "Chest": ["plate", "dark"], "Legs": ["greaves", "dark"], "Feet": ["sabatons", "dark"], "Helmet": ["helm", "dark"], "Cape": "#5a1020"}],
		["elf_ranger", {"body": "fem", "skin": 0, "hair": "Very Long", "hair_color": 16, "eyes": 5, "race": "Elf"},
			{"Weapon": ["bow", "wood"], "Chest": ["tunic", "leather"], "Legs": ["leggings", "dark"], "Feet": ["boots", "leather"]}],
		["orc_warlord", {"body": "masc", "skin": 6, "hair": "Mohawk", "hair_color": 0, "eyes": 6, "race": "Orc"},
			{"Weapon": ["axe", "iron"], "Chest": ["plate", "iron"], "Legs": ["pants", "dark"], "Feet": ["boots", "leather"]}],
		["demon_mage", {"body": "fem", "skin": 7, "hair": "Wild", "hair_color": 10, "eyes": 6, "race": "Demon"},
			{"Weapon": ["staff", "dark"], "Chest": ["robe", "dark"], "Feet": ["sandals", "leather"]}],
		["dwarf_guard", {"body": "masc", "skin": 2, "hair": "Bald", "hair_color": 6, "eyes": 2, "race": "Dwarf"},
			{"Weapon": ["spear", "steel"], "Off Hand": ["shield", "steel"], "Chest": ["plate", "steel"], "Legs": ["greaves", "steel"], "Feet": ["sabatons", "steel"]}],
	]
	for h in heroes:
		var looks := {}
		for slot in h[2]:
			if slot == "Cape":
				looks["Cape"] = {"type": "cape", "mat": "cloth", "ramp": Sprites.ramp_from(Color(h[2]["Cape"])), "trim": Color("#fde047"), "glow": false}
			else:
				looks[slot] = {"type": h[2][slot][0], "mat": h[2][slot][1], "trim": Color.WHITE, "glow": false}
		var art := Sprites.hero(h[1], looks)
		var anims: Dictionary = art["lpc"]
		for an in anims:
			var imgs: Array = anims[an]["img"]
			for i in imgs.size():
				(imgs[i] as Image).save_png("/root/shots/lpcanim/%s__%s__%02d.png" % [h[0], an, i])
	print("lpc preview ok")
	quit()
