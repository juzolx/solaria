extends SceneTree
## Phase 11: the new races in the creator, a realm fight, a portal choice,
## the Race tab, hidden classes and the big moments.

var main

func shot(n: String, wait := 0.6) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % n)

func close_overlays() -> void:
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(7)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.max_floor = 300
	prof.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 2, "hair": "Short", "hair_color": 6, "eyes": 0, "race": "Dwarf"}
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class("Warrior")
	var looks: Dictionary = g.class_info()["look"]
	for s in looks:
		var it := GameData.make_item(s, 3, 250, g._new_id())
		it["type"] = looks[s]
		g.equipped[s] = it
	g.level = 70
	g.stat_points = 0
	g.stats = {"STR": 120, "VIT": 90, "AGI": 30, "INT": 10}
	g.race_power = 64.0
	g.awaken = 1
	Lineage.update_look(g)
	g.rep = Races.start_rep("Dwarf")
	g.rep["Elf"] = 45.0
	g.rep["Demon"] = -70.0
	g.hero_hp = g.get_max_hp()
	g.best_floor = 260
	g.floor_num = 256
	g.realm_order.assign(["elf"])
	g.feats["seen_realm_elf"] = 1
	g.feats["deaths"] = 31
	g.feats["goblins"] = 14
	g.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	await close_overlays()
	main.timer.stop()
	var s: GameState = main.state
	s.codex.stats["guide_skip"] = 1
	s.spawn_enemy()
	for i in 8:
		s.take_turn()
		main.refresh()
		await process_frame
	await close_overlays()
	main.show_tab(0, 2)
	main.refresh()
	await shot("r1_hushwood_race_tab", 0.4)
	main.show_tab(0, 1)
	main.refresh()
	await shot("r2_class_hidden", 0.3)
	# Portal choice
	s.realm_order.clear()
	GameData.realm_order = []
	s.feats.erase("seen_realm_elf")
	s.floor_num = 250
	s.next_floor()
	main.refresh()
	await shot("r3_portals", 0.5)
	s.choose_path(s.path_offer[0])
	main.refresh()
	await shot("r4_realm_entrance", 2.2)
	await close_overlays()
	# A fight in each realm
	var n := 5
	for id in Realms.IDS:
		GameData.realm_order = [id]
		s.realm_order.assign([id])
		s.feats["seen_realm_" + id] = 1
		s.floor_num = 255
		s.path_offer = []
		s.spawn_enemy()
		for i in 4:
			s.take_turn()
			main.refresh()
			await process_frame
		await close_overlays()
		await shot("r%d_fight_%s" % [n, id], 0.5)
		n += 1
	# The big moments
	Lineage._rank_up(s)
	main.refresh()
	await shot("r10_awaken", 2.0)
	await close_overlays()
	Hidden.unlock(s, "fool")
	main.refresh()
	await shot("r11_hidden", 2.6)
	await close_overlays()
	# The creator with the new races
	var cc := CharacterCreator.new()
	cc.show_for(main, {"body": "fem", "skin": 6, "hair": "Ponytail", "hair_color": 2, "eyes": 1, "race": "Goblin"}, func(_a): pass, "Create your hero", false, {}, true)
	await shot("r12_creator", 0.5)
	cc.app["race"] = "Dragonkin"
	cc.app["skin"] = 7
	cc._update()
	await shot("r13_creator_dragonkin", 0.3)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
