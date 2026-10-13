extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	GameState.delete_saves()
	Profile.delete()
	var prof := Profile.new()
	prof.last_mode = "regular"
	prof.save()
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is CharacterCreator:
			c._finish()
	await process_frame
	main._on_class_chosen("Warrior")
	main.timer.stop()
	var s: GameState = main.state
	s.floor_num = 23
	s.best_floor = 23
	s.spawn_enemy()
	s.path_offer = ["fight", "treasure", "elite"]
	main.battle.last_floor = 23
	main.refresh()
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("/root/shots/path_1.png")
	main._choose_path("elite")
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("/root/shots/path_2.png")
	main.profile.dev_mode = true
	var m := SettingsMenu.new()
	m.show_for(main)
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("/root/shots/menu.png")
	GameState.delete_saves()
	Profile.delete()
	quit()
