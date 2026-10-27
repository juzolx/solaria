extends SceneTree
## One body build (race) in the game: the 4 outfit families on both bodies, battle idle / attack /
## hit and the portrait, into shots/build_<race>.png. godot --headless -s tests/_build_probe.gd -- Goblin
const FORMS := ["Werewolf", "Vampire", "Lich"]
const ROWS := [["Warrior", "sword"], ["Mage", "staff"], ["Ranger", "bow"], ["Wanderer", "axe"]]
func _initialize() -> void:
	var race: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "Goblin"
	var sheet := Image.create(HeroArt.FRAME * 10, HeroArt.FRAME * ROWS.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#1e1c24"))
	for r in ROWS.size():
		for bi in 2:
			var app := {"body": ["masc", "fem"][bi], "race": race, "skin": Races.skins(race)[0], "hair_color": 1}
			if race in FORMS:  # a transformation: a bitten human
				app = {"body": ["masc", "fem"][bi], "race": "Human", "form": race, "skin": Races.skins("Human")[0], "hair_color": 1}
			var looks := {"Class": {"cls": ROWS[r][0], "tier": 0}, "Weapon": {"type": ROWS[r][1], "glow": false}}
			var back: Dictionary = Sprites.hero_back(app, looks)["anims"]
			var fr: Array = _imgs(back["combat_idle"]) + _imgs(back["slash"]) + _imgs(back["hurt"])
			var front: Array = _imgs(Sprites.hero(app, looks)["anims"]["combat_idle"])
			var row := [fr[0], fr[3], fr[5], fr[6], front[0]]
			for i in row.size():
				sheet.blend_rect(row[i], Rect2i(0, 0, HeroArt.FRAME, HeroArt.FRAME), Vector2i((bi * 5 + i) * HeroArt.FRAME, r * HeroArt.FRAME))
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	sheet.save_png("res://shots/build_%s.png" % race.to_lower())
	print("BUILD PROBE DONE ", race)
	quit()

## An animation's frames as Images (the textures hold them: only the first idle keeps its Image).
func _imgs(an: Dictionary) -> Array:
	var out := []
	for t in an["tex"]:
		out.append((t as Texture2D).get_image())
	return out
