extends SceneTree

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_class_chosen("Archer")
	main.timer.stop()
	var s: GameState = main.state
	for i in 400:
		s.take_turn()
		if i % 20 == 0:
			s.equip_best()
	s.messages.clear()
	s.events.clear()
	s.spend_point("AGI", 6)
	s.spend_point("STR", 3)
	main.battle.last_floor = s.floor_num
	main.battle.toasts.clear()
	main.battle.toast_life = 0.0
	main.tabs.current_tab = 0
	main._refresh()
	await create_timer(0.3).timeout
	shot("hero_before")

	# jump to level 15 to see the specialization happen
	s.level = 14
	s.xp = GameData.xp_to_next(14) - 1
	s.gain_xp(10)
	s.spend_point("AGI", s.stat_points)
	main._refresh()
	await create_timer(1.6).timeout
	shot("hero_spec")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
