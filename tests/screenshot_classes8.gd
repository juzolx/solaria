extends SceneTree
## Phase 8 screens: class picker, skill book, class tab paths.

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
	seed(4)
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
			c.name_edit.text = "Kai"
			c._finish()
	await process_frame
	await shot("c1_class_picker")
	main._on_class_chosen("Wanderer")
	await close_popups()
	main.timer.stop()
	var s: GameState = main.state
	s.codex.stats["guide_skip"] = 1
	s.dev_mode = true
	for i in 3000:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		s.path_offer = []
		if i % 50 == 0:
			s.equip_best()
			while s.stat_points > 0:
				s.spend_point("AGI", 1)
	s.dust += 2000
	for id in ["thousand_cuts", "iaido", "swordsmanship", "precision", "vampirism"]:
		s.craft_skill(id)
	main.show_tab(0, 3)
	main.refresh()
	main.skills_tab.selected = "iaido"
	main.skills_tab._show_detail()
	await shot("c2_skill_book")
	main.show_tab(0, 1)
	main.refresh()
	await shot("c3_class_wanderer")
	main.show_tab(0, 0)
	main.refresh()
	main.hero_tab.scroll_vertical = 400
	await shot("c4_hero_special")
	s.hero_class = "Mage"
	main.show_tab(0, 1)
	main.class_tab.shown = ""
	main.refresh()
	await shot("c5_class_mage")
	main._show_school_picker()
	await shot("c6_school_picker")
	await close_popups()
	s.hero_class = "Acolyte"
	s.faith = -35
	main.class_tab.shown = ""
	main.refresh()
	await shot("c7_class_acolyte")
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
