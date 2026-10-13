extends SceneTree
## Tall (phone) layout check.
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
	main._on_class_chosen("Mage")
	main.timer.stop()
	var s: GameState = main.state
	for i in 600:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		if i % 50 == 0:
			s.equip_best()
	main.battle.last_floor = s.floor_num
	main.refresh()
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("/root/shots/phone_1.png")
	main.show_tab(0, 0)
	main.refresh()
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("/root/shots/phone_2.png")
	GameState.delete_saves()
	Profile.delete()
	quit()
