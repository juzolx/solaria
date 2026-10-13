extends SceneTree
## v0.11 tour: title, creator, fight and the main tabs at the window size given
## on the command line:  xvfb-run -a godot --path . --resolution WxH -s tests/screenshot_v11.gd -- <prefix>
var main
var prefix := "v11"

func shot(n: String, wait := 0.45) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/tour/%s_%s.png" % [prefix, n])

func close_overlays() -> void:
	for c in main.get_children():
		if c is Overlay or c is Moments or c is CharacterCreator:
			c.queue_free()
	await process_frame

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		prefix = args[0]
	var force_art := ""
	if args.size() > 1:
		force_art = args[1]
	DirAccess.make_dir_recursive_absolute("/root/shots/tour")
	seed(11)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.max_floor = 300
	prof.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 2, "hair": "Spiky", "hair_color": 6, "eyes": 0, "race": "Human"}
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class("Warrior")
	g.level = 72
	g.best_floor = 40
	g.floor_num = 40
	g.class_path.assign(["champion", "weaponmaster", "titan"])
	g.ctrack["trial_titan"] = 1
	g.stat_points = 5 * 71
	g.auto_spend()
	for s in ["Weapon", "Chest", "Legs", "Feet", "Helmet", "Off Hand"]:
		g.equipped[s] = GameData.make_item(s, 4, 40, g._new_id())
	g.hero_hp = g.get_max_hp()
	g.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await shot("0_title", 0.6)
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	await close_overlays()
	main.timer.stop()
	var st: GameState = main.state
	st.codex.stats["guide_skip"] = 1
	st.spawn_enemy()
	for i in 6:
		st.take_turn()
		main.refresh()
		await create_timer(0.12).timeout
	await close_overlays()
	st.path_offer.clear()
	if force_art != "":
		st.enemy_art = force_art
		st.enemy_name = force_art.capitalize()
	main.refresh()
	await shot("1_fight", 1.2)
	var names := ["2_hero", "3_class", "4_race", "5_skills", "6_party"]
	for k in names.size():
		main.show_tab(0, k)
		main.refresh()
		await shot(names[k])
		if k == 0:
			# and the stat boxes further down
			for ht in main.find_children("*", "HeroTab", true, false):
				var sg: Control = ht.stat_grid
				var sc := sg.get_parent()
				while sc != null and not sc is ScrollContainer:
					sc = sc.get_parent()
				if sc:
					(sc as ScrollContainer).ensure_control_visible(sg)
					await process_frame
					(sc as ScrollContainer).scroll_vertical = int(sg.global_position.y - (sc as ScrollContainer).global_position.y + (sc as ScrollContainer).scroll_vertical - 40)
			await shot("2b_stats")
	main.show_tab(1, 0)
	main.refresh()
	await shot("7_gear")
	main.show_tab(3, 0)
	main.refresh()
	await shot("8_bestiary")
	CharacterCreator.new().show_for(main, st.appearance, func(_a): pass, "Change your look")
	await shot("9_creator", 0.6)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
