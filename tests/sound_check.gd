extends SceneTree
func _initialize() -> void:
	var s := Sfx.new()
	root.add_child(s)
	await process_frame
	var missing := []
	for n in ["hit", "crit", "hurt", "tap", "kill", "loot_0", "loot_1", "loot_2", "loot_3", "loot", "legendary", "unique",
			"potion", "floor", "death", "click", "equip", "buy", "sell", "salvage", "craft", "level_up", "spec",
			"boss_intro", "dodge", "burn", "stun", "buff", "ability", "error"]:
		if not s.sounds.has(n) or not (s.sounds[n] is AudioStreamWAV) or not ResourceLoader.exists("res://sounds/%s.wav" % n):
			missing.append(n)
	print("missing: ", missing)
	for k in s.music_paths:
		var st: AudioStreamWAV = s.music_stream(k)
		print(k, " len ", st.get_length(), " loop ", st.loop_mode, " end ", st.loop_end, " rate ", st.mix_rate, " fmt ", st.format)
	var gs := GameState.new()
	gs.new_game()
	s.update_music(gs)
	await create_timer(0.5).timeout
	print("music playing: ", s.music_a.playing or s.music_b.playing, " current ", s.music_current)
	gs.floor_num = 10
	gs.enemy_is_boss = true
	s.update_music(gs)
	await create_timer(1.5).timeout
	print("now ", s.music_current)
	for n in s.sounds:
		s.play(n)
	quit()
