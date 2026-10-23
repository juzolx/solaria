extends SceneTree
## Renders every screen of the polish update to /root/shots/.

var main

func shot(name: String) -> void:
	await create_timer(0.35).timeout
	var img := root.get_texture().get_image()
	img.save_png("/root/shots/%s.png" % name)

func _close_popups() -> void:
	for c in main.get_children():
		if c is Overlay:
			c.close()
	await process_frame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(11)
	GameState.delete_saves()
	Profile.delete()
	var prof := Profile.new()
	prof.last_mode = "regular"
	prof.save()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is CharacterCreator:
			c._finish()
	await process_frame
	await shot("00_class_picker")
	main._on_class_chosen("Warrior")
	main.timer.stop()
	var s: GameState = main.state
	for i in 2600:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		if i % 40 == 0:
			s.equip_best()
			while s.stat_points > 0:
				s.spend_point("STR" if i % 80 == 0 else "VIT", 1)
	s.dev_grant("dust")
	s.dev_grant("legendary")
	s.dev_grant("unique")
	s.gold += 5000
	s.scrap += 300
	main.battle.last_floor = s.floor_num
	main.refresh()
	main._on_tick()

	var names := [["hero", "class", "skills"], ["gear", "bag"], ["shop", "craft"]]
	for g in 3:
		var group: TabContainer = [main.char_tabs, main.item_tabs, main.town_tabs][g]
		for sub in group.get_tab_count():
			if group.is_tab_hidden(sub):
				continue
			main.show_tab(g, sub)
			main.refresh()
			await shot("%d%d_%s" % [g + 1, sub, names[g][sub]])

	main.show_tab(1, 1)
	if s.bag.size() > 0:
		main.bag_tab.selected_id = int(s.bag[0]["id"])
	main.refresh()
	await shot("21_bag_selected")

	var fp := FloorPicker.new()
	fp.show_for(main)
	await shot("40_floor_picker")
	await _close_popups()

	s.dev_mode = true
	var menu := SettingsMenu.new()
	menu.show_for(main)
	await shot("41_menu_dev")
	await _close_popups()
	main.show_tab(0, 1)
	main.refresh()
	await shot("42_class_dev")
	s.dev_mode = false

	main.confirm("Delete your save?", "This wipes everything. It can't be undone.", "Delete everything", func(): pass)
	await shot("43_confirm")
	await _close_popups()

	# Boss fight
	s.floor_num = 30
	s.fight = 1
	s.spawn_enemy()
	main.battle.last_floor = 29
	main.refresh()
	await shot("44_boss")

	GameState.delete_saves()
	quit()
