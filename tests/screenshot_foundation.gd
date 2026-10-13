extends SceneTree
## Screens for 0.7.5: title, fight with a rare monster, codex, wheel, floor picker, merchant.

var main

func shot(n: String, wait := 0.5) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % n)

func close_popups() -> void:
	for c in main.get_children():
		if c is Overlay:
			c.close()
	await process_frame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(9)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.new_hero(1, false)
	await process_frame
	for c in main.get_children():
		if c is CharacterCreator:
			c._pick("race", "Human")
			c._pick("hair", "Ponytail")
			c._pick("body", "fem")
			c.name_edit.text = "Aria"
			c._finish()
	await process_frame
	main._on_class_chosen("Warrior")
	await close_popups()
	main.timer.stop()
	var s: GameState = main.state
	s.codex.stats["guide_skip"] = 1
	for i in 2500:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		s.path_offer = []
		if i % 50 == 0:
			s.equip_best()
			while s.stat_points > 0:
				s.spend_point("STR", 1)
	s.save_game()
	main.codex.save()
	# Title screen with a hero
	main.queue_free()
	await process_frame
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await shot("f1_title", 1.5)
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await close_popups()
	main.timer.stop()
	s = main.state
	s.dev_mode = true
	s.floor_num = 33
	s.spawn_enemy()
	s._apply_tier(4)
	main.battle.last_floor = s.floor_num
	main.refresh()
	await shot("f2_rare_monster", 1.0)
	s.start_event("goblin")
	s.spawn_enemy()
	main.refresh()
	await shot("f3_goblin", 1.0)
	main.show_tab(3, 0)
	main.bestiary_tab.selected = s.enemy_species if s.codex.seen(s.enemy_species) else "Kobold"
	main.refresh()
	main.bestiary_tab.selected = "Kobold"
	main.bestiary_tab._show()
	await shot("f4_bestiary")
	main.show_tab(3, 2)
	main.refresh()
	await shot("f5_achievements")
	s.gold += 50000
	s.best_floor = maxi(s.best_floor, 12)
	main.show_tab(2, 2)
	main.refresh()
	if main.wheel_tab.ids.size() > 0 and main.wheel_tab.ids[0] >= 0:
		main.wheel_tab.selected_id = main.wheel_tab.ids[0]
	main.wheel_tab._update()
	await shot("f6_wheel")
	FloorPicker.new().show_for(main)
	await shot("f7_floors")
	await close_popups()
	s._make_merchant()
	MerchantPopup.new().show_for(main)
	await shot("f8_merchant")
	await close_popups()
	main.show_tab(3, 1)
	main.refresh()
	await shot("f9_collection")
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
