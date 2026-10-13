extends SceneTree
## Phase 10: a party of three in a fight, and the Party tab.

var main

func shot(n: String, wait := 0.6) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % n)

func make_hero(slot_n: int, cls: String, nm: String, app: Dictionary) -> void:
	var g := GameState.new()
	g.slot = slot_n
	g.codex.path = ""
	g.appearance = app
	g.hero_name = nm
	g.new_game()
	g.choose_class(cls)
	var looks: Dictionary = g.class_info()["look"]
	for s in looks:
		var it := GameData.make_item(s, 2, 30, g._new_id())
		it["type"] = looks[s]
		g.equipped[s] = it
	g.level = 22
	g.stat_points = 63
	Party.auto_spend(g)
	g.hero_hp = g.get_max_hp()
	g.save_game()

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(11)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.max_floor = 60
	prof.save()
	make_hero(2, "Cleric", "Mira", {"body": "fem", "skin": 0, "hair": "Long", "hair_color": 5, "eyes": 1, "race": "Human"})
	make_hero(3, "Knight", "Bram", {"body": "masc", "skin": 2, "hair": "Short", "hair_color": 1, "eyes": 0, "race": "Human"})
	make_hero(1, "Mage", "Aria", {"body": "fem", "skin": 1, "hair": "Ponytail", "hair_color": 3, "eyes": 2, "race": "Elf"})
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	for c in main.get_children():
		if c is Overlay:
			c.close()
	main.timer.stop()
	var s: GameState = main.state
	s.codex.stats["guide_skip"] = 1
	s.set_party([2, 3])
	s.floor_num = 28
	s.best_floor = 30
	s.spawn_enemy()
	for i in 40:
		s.take_turn()
		main.refresh()
		await process_frame
	main.show_tab(0, 4)
	main.refresh()
	await shot("p1_party_fight", 0.3)
	for i in 3:
		s.take_turn()
		main.refresh()
		await create_timer(0.12).timeout
	await shot("p2_party_action", 0.05)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
