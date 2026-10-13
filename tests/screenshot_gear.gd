extends SceneTree

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(11)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var s: GameState = main.state
	s.bag_level = 3
	for i in 60:
		s.take_turn()
	s.messages.clear()
	s.events.clear()
	main.battle.last_floor = s.floor_num
	main._refresh()

	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	main._on_card_input(ev, "Helmet")
	await create_timer(0.2).timeout
	shot("gear_pick")

	# tap the top item in the list (index 0 or 1 depending on 'wearing' row)
	var idx := 1 if s.equipped.has("Helmet") else 0
	main._on_gear_item_selected(idx)
	await create_timer(0.2).timeout
	shot("gear_equipped")

	main._on_card_input(ev, "Weapon")
	s.equip_best()
	main._refresh()
	await create_timer(0.2).timeout
	shot("gear_best")
	print("equipped slots: ", s.equipped.keys())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
