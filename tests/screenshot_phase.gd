extends SceneTree
## Screens for phases 4-6: mode select, creator, wardrobe, online tabs, fallen hero.
## The online part uses the local test server (tests/online_test.gd notes).

var main

func shot(name: String, wait := 0.4) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % name)

func close_popups() -> void:
	for c in main.get_children():
		if c is Overlay:
			c.close()
	await process_frame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(5)
	GameState.delete_saves()
	Profile.delete()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await shot("p0_mode_select")
	main.queue_free()
	await process_frame

	var prof := Profile.new()
	prof.last_mode = "regular"
	prof.save()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var cc: CharacterCreator = null
	for c in main.get_children():
		if c is CharacterCreator:
			cc = c
	cc._pick("race", "Elf")
	cc._pick("body", "fem")
	cc._pick("hair", "Ponytail")
	cc._pick("hair_color", 6)
	cc._pick("skin", 1)
	cc._pick("eyes", 1)
	await shot("p1_creator")
	cc._finish()
	await process_frame
	main._on_class_chosen("Archer")
	await close_popups()
	main.timer.stop()
	var s: GameState = main.state
	for i in 1500:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		if i % 50 == 0:
			s.equip_best()
			while s.stat_points > 0:
				s.spend_point("AGI", 1)
	main.battle.last_floor = s.floor_num
	main.refresh()
	await shot("p2_fight")

	var w := Wardrobe.new()
	w.show_for(main)
	await shot("p3_wardrobe")
	await close_popups()

	# Online with the local test server
	main.online.url = "http://127.0.0.1:3000"
	main.online.key = "test-anon-key"
	main.show_tab(3, 0)
	main.refresh()
	await shot("p4_online_name", 1.0)
	await main.online.register_name("Juzo")
	s.best_floor = 64
	await main.online.submit_run(s)
	main.leaderboard_tab.loaded_at = -100000
	main.refresh()
	await shot("p5_leaders", 1.2)
	main.show_tab(3, 1)
	main.refresh()
	await shot("p6_guild_none", 1.5)
	await main.online.create_guild("Sun Seekers", "SUN", 64)
	main.guild_tab.reload()
	await shot("p7_guild", 1.5)
	main.show_tab(3, 2)
	main.refresh()
	await shot("p8_raid", 1.5)

	# Hardcore fall
	s.hardcore = true
	s.run_over = true
	main.fallen_shown = false
	main.profile.last_mode = "hardcore"
	main.refresh()
	await shot("p9_fallen", 2.2)
	GameState.delete_saves()
	Profile.delete()
	quit()
