extends SceneTree
## Records a few fight turns as PNG frames in /root/shots/fightgif/ (made into a GIF after).
## xvfb-run -a godot --path . --resolution 1152x648 -s tests/fight_gif.gd -- <monster art key> <class> <weapon type>
var main
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mon: String = args[0] if args.size() > 0 else "obsidian_knight"
	var cls: String = args[1] if args.size() > 1 else "Warrior"
	var wpn: String = args[2] if args.size() > 2 else "sword"
	DirAccess.make_dir_recursive_absolute("/root/shots/fightgif")
	for f in DirAccess.get_files_at("/root/shots/fightgif"):
		DirAccess.remove_absolute("/root/shots/fightgif/" + f)
	seed(3)
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
	g.choose_class(cls)
	g.level = 30
	g.best_floor = 30
	g.floor_num = 30
	g.stat_points = 5 * 29
	g.auto_spend()
	for s in ["Weapon", "Chest", "Legs", "Feet", "Helmet"]:
		var it := GameData.make_item(s, 3, 30, g._new_id())
		if s == "Weapon":
			it["type"] = wpn
		g.equipped[s] = it
	g.hero_hp = g.get_max_hp()
	g.save_game()
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
	main.timer.stop()
	var st: GameState = main.state
	st.codex.stats["guide_skip"] = 1
	st.spawn_enemy()
	st.enemy_art = mon
	st.enemy_name = mon.capitalize()
	st.path_offer.clear()
	main.refresh()
	await create_timer(0.5).timeout
	var k := 0
	for turn in 5:
		st.take_turn()
		st.path_offer.clear()
		if st.enemy_hp <= 0 or st.enemy_art != mon:
			st.enemy_art = mon
			st.enemy_name = mon.capitalize()
		main.refresh()
		for i in 14:
			await create_timer(0.05).timeout
			var img := root.get_texture().get_image()
			img.save_png("/root/shots/fightgif/f%03d.png" % k)
			k += 1
	print("frames ", k)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	quit()
