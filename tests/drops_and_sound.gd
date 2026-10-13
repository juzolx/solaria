extends SceneTree

func _initialize() -> void:
	seed(99)
	# ---- Sounds: build them and save a few to check they aren't silent ----
	var sfx := Sfx.new()
	root.add_child(sfx)
	await process_frame
	for n in ["hit", "crit", "loot", "legendary", "potion"]:
		var wav: AudioStreamWAV = sfx.sounds[n]
		wav.save_to_wav("/root/sfx_%s.wav" % n)
	sfx.play("hit")
	sfx.play("legendary")
	print("sounds built: ", sfx.sounds.size())

	# ---- Drop rates ----
	var counts := [0, 0, 0, 0, 0]
	var trials := 200000
	for i in trials:
		counts[GameData.roll_rarity(0, GameData.LEGENDARY_CHANCE_NORMAL)] += 1
	print("normal drops %: ", counts.map(func(c): return snappedf(100.0 * c / trials, 0.01)))
	counts = [0, 0, 0, 0, 0]
	for i in trials:
		counts[GameData.roll_rarity(GameData.BOSS_RARITY_BONUS, GameData.LEGENDARY_CHANCE_BOSS)] += 1
	print("boss drops %:   ", counts.map(func(c): return snappedf(100.0 * c / trials, 0.01)))

	var leg := GameData.make_item("Weapon", GameData.LEGENDARY, 10, 1)
	print("legendary example: ", leg["name"], " -> ", GameData.effect_text(leg["effect"], leg["effect_value"]))

	# Unique pity: how many boss kills until a unique, over many players
	var kills_needed: Array[int] = []
	for p in 20000:
		var g := GameState.new()
		var k := 0
		while true:
			k += 1
			if randf() * 100.0 < g.unique_chance():
				break
			g.bosses_since_unique += 1
		kills_needed.append(k)
	kills_needed.sort()
	var avg := 0.0
	for k in kills_needed:
		avg += k
	print("boss kills until a unique: average %.1f, half of players by %d, 90%% by %d, worst %d" % [
		avg / kills_needed.size(), kills_needed[kills_needed.size() / 2], kills_needed[int(kills_needed.size() * 0.9)], kills_needed[-1]])

	# Old legendary in a save gets an effect
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var s := GameState.new()
	s.new_game()
	var old := GameData.make_item("Helmet", 2, 5, 500)
	old["rarity"] = 4
	old["name"] = "Legendary Helm"
	s.bag.append(old)
	s.save_game()
	var s2 := GameState.new()
	s2.load_game()
	print("old legendary after load: ", s2.bag[0]["name"], " / ", s2.bag[0]["effect"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
