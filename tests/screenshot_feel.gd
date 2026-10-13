extends SceneTree

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(5)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var s: GameState = main.state

	# 1: brand new game - tip toast, only Gear and Bag tabs
	main._on_tick()
	await create_timer(0.5).timeout
	shot("new_game")

	# 2: tapping the enemy a few times
	for i in 3:
		main.last_tap_ms = 0
		main._on_battle_tapped(Vector2(560 + i * 15, 230))
		await create_timer(0.05).timeout
	shot("tapping")

	# 3: play on until shop unlocks, then force a legendary drop on a kill
	for i in 40:
		s.take_turn()
	s.messages.clear()
	s.events.clear()
	main.battle.last_floor = s.floor_num
	main._refresh()
	s.enemy_hp = 1
	s.hero_hp = s.get_max_hp()
	s.take_turn()
	# swap the last loot event to a legendary for the picture
	for e in s.events:
		if e["type"] == "loot":
			e["rarity"] = 4
			e["name"] = "Legendary Tower Shield"
	main._refresh()
	await create_timer(0.35).timeout
	shot("legendary")
	await create_timer(1.0).timeout
	shot("after")
	print("tabs hidden shop/craft: ", main.tabs.is_tab_hidden(2), " ", main.tabs.is_tab_hidden(3), " best floor ", s.best_floor, " upgrades ", s.upgrade_count())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
