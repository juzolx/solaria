extends SceneTree

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(21)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	shot("class_picker")

	main._on_class_chosen("Mage")
	main.timer.stop()
	var s: GameState = main.state
	s.tips_seen["tap"] = true
	for i in 120:
		s.take_turn()
		if i % 10 == 0:
			s.equip_best()
	s.messages.clear()
	s.events.clear()
	main.battle.last_floor = s.floor_num
	main.battle.toast_life = 0.0
	main.battle.toasts.clear()
	main._refresh()
	s.ability_cd = 0
	s.use_ability()
	main._refresh()
	await create_timer(0.15).timeout
	shot("fireball")

	s.xp = GameData.xp_to_next(s.level) - 1
	s.gain_xp(5)
	main._refresh()
	await create_timer(0.6).timeout
	shot("level_up")

	main.tabs.current_tab = 1
	main._refresh()
	await create_timer(0.2).timeout
	shot("bag_salvage")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
