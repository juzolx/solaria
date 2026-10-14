extends SceneTree
## Screenshots of the town: the map in a few zones, then each building's page.
## xvfb-run -a godot --path . --resolution 430x932 -s tests/town_shots.gd -- [prefix]
var main

func shot(n: String, wait := 0.5) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/town/%s.png" % n)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "phone"
	DirAccess.make_dir_recursive_absolute("/root/shots/town")
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.max_floor = 300
	prof.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"}
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.best_floor = 60
	g.floor_num = 30
	g.gold = 9000
	g.stat_points = 5 * 29
	g.auto_spend()
	g.hero_hp = g.get_max_hp() / 2
	g.save_game()
	# A few more heroes in the roster (they walk around town too)
	var others := [[2, "Cleric", {"body": "fem", "skin": 3, "hair": "Long", "hair_color": 4, "eyes": 2, "race": "Elf"}, "Lysa"],
		[3, "Knight", {"body": "masc", "skin": 0, "hair": "Short", "hair_color": 8, "eyes": 1, "race": "Dwarf"}, "Brom"],
		[4, "Mage", {"body": "fem", "skin": 5, "hair": "Bun", "hair_color": 12, "eyes": 3, "race": "Human"}, "Ivi"]]
	for o in others:
		var h := GameState.new()
		h.slot = int(o[0])
		h.codex.path = ""
		h.appearance = o[2]
		h.hero_name = o[3]
		h.new_game()
		h.choose_class(o[1])
		h.level = 25
		h.equipped["Chest"] = GameData.make_item("Chest", 3, 30, 100 + int(o[0]))
		h.equipped["Helmet"] = GameData.make_item("Helmet", 2, 30, 200 + int(o[0]))
		h.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	var st: GameState = main.state
	st.codex.stats["guide_skip"] = 1
	st.codex.deeds = ["f25", "lv25", "k100"]
	main.go_to_town()
	main.refresh()
	await shot(prefix + "_1_map", 1.0)
	print("town walkers: ", main.town_view.folk.size(), " heroes: ", main.town_view.folk.filter(func(f): return f.get("hero", false)).size())
	# take two contracts and finish one
	Town.refresh_board(st)
	for c in st.contracts.slice(0, 2):
		Town.take(st, int(c["id"]))
	st.contracts[0]["have"] = st.contracts[0]["need"]
	st.contracts[0]["done"] = true
	Mail.post(st, "The Bounty Board", "Bounty paid: Kobold hunt", "Contract done. Here is what you were promised.", {"gold": 100, "item": {"slot": "Weapon", "rarity": 3}})
	Mail.post(st, "The Guild Hall", "Deed: Into the Deep", "Reach floor 25. Well done! Here is your reward.", {"gold": 500, "potions": 2, "item": {"slot": "Chest", "rarity": 4}})
	main.refresh()
	var pages := ["shop", "smith", "tavern", "inn", "stash", "bounty", "guild", "mail"]
	for id in pages:
		main._on_building(id)
		await shot(prefix + "_2_" + id, 0.4)
	# other zones' looks
	main.nav_page = 0
	main._apply_nav()
	for f in [60, 110, 160, 210, 460]:
		st.floor_num = f
		main.refresh()
		await shot(prefix + "_3_zone_%d" % f, 0.8)
	st.floor_num = 30
	main.refresh()
	main._on_building("gate")
	await shot(prefix + "_4_pick_floor", 0.6)
	for c in main.get_children():
		if c is FloorPicker:
			c._go(c.last_start())
	await shot(prefix + "_5_left", 0.6)
	st.gold = 4000
	st.bag.append(GameData.make_item("Chest", 0, 20, st._new_id()))
	st._make_merchant()
	MerchantPopup.new().show_for(main)
	await shot(prefix + "_6_goblin", 0.6)
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	HeroSelect.new().show_for(main)
	await shot(prefix + "_7_heroes", 0.6)
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	st.set_party([2, 3])
	main.refresh()
	await shot(prefix + "_8_team", 0.6)
	st.enemy_hp = 99999999
	st.enemy_max_hp = st.enemy_hp
	st.hero_hp = 0
	st._hero_died()
	main.refresh()
	await shot(prefix + "_9_down", 1.2)
	print("leader down: ", st.leader_down)
	print("went to floor ", st.floor_num)
	print("town shots ok, in_town=", st.in_town)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
