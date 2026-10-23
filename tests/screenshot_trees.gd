extends SceneTree

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_class_chosen("Warrior")
	main.timer.stop()
	var s: GameState = main.state
	for i in 300:
		s.take_turn()
		if i % 20 == 0:
			s.equip_best()
	s.messages.clear()
	s.events.clear()
	# A level 20 Guardian heading toward Templar
	s.level = 20
	s.stat_points = 0
	s.stats = {"STR": 8, "VIT": 30, "AGI": 0, "INT": 19}
	s.last_spec = s.title()
	s.skills = {"might1": 3, "guard1": 5, "guard2": 2, "a2": 1, "cun1": 1}
	s.dust = 90
	s.scrap = 300
	s.best_floor = 22
	main.battle.last_floor = s.floor_num
	main.battle.toasts.clear()
	main.battle.toast_life = 0.0
	main._refresh()

	main.tabs.current_tab = 1
	await create_timer(0.3).timeout
	for n in main.class_tree.nodes:
		if n["key"] == "evo_Templar":
			main._on_class_node_clicked(n)
			main.class_tree.selected_key = n["key"]
	await create_timer(0.2).timeout
	shot("class_tree")

	main.tabs.current_tab = 2
	main._show_skill_detail("a3")
	main._refresh()
	await create_timer(0.3).timeout
	shot("skills")

	main.tabs.current_tab = 6
	main._refresh()
	await create_timer(0.3).timeout
	shot("craft")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
