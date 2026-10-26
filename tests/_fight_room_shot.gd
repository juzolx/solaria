extends SceneTree
## The fight in one zone's room: a common monster and the zone's boss, into shots/fights/<tag>, with
## the room's standing props printed (the face-off keeps them off the monster: Room3D.monster_clear).
## godot --path . --resolution 430x932 --position 3000,3000 -s tests/_fight_room_shot.gd -- <zone 0-9> <tag>
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var zone := int(args[0]) if args.size() > 0 else 1
	var tag := String(args[1]) if args.size() > 1 else "now"
	var out := TestHero.shots_dir("fights/%s" % tag)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	var st: GameState = main.state
	# another run sharing this user folder (check.sh) can swap the save under us: say so, loudly
	print("user data: %s" % OS.get_user_data_dir())
	assert(st.hero_name == "Thorin", "shots: the test hero is %s, not Thorin (another run shares %s)" % [st.hero_name, OS.get_user_data_dir()])
	if st.hero_name != "Thorin":
		quit(1)
		return
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	st.in_town = false
	st.autoplay = false
	main.nav_page = 0
	main._apply_nav()
	var boss: String = String(GameData.ZONES[zone]["boss"]["art"])
	for which in ["common", "boss"]:
		st.floor_num = zone * GameData.ZONE_FLOORS + 12
		main.battle.last_floor = st.floor_num
		st.room_count = 3
		st.room_props = []   # a fight room: no event left in the save
		st.room_trap = {}
		st.spawn_enemy()
		st.enemy_variant = ""
		st.enemy_tier = 0
		st.enemy_mods.clear()
		st.enemy_elite = false
		st.enemy_calamity = 0
		st.horde_left = 0
		st.horde_pack = false
		st.horde_total = 0
		st.pets_out.clear()
		if which == "boss":
			st.enemy_species = boss.trim_prefix("boss_")
			st.enemy_name = Monsters.name_of(st.enemy_species)
			st.enemy_art = boss
			st.enemy_is_boss = true
		Sprites.clear_monster_cache()
		main.refresh()
		await create_timer(3.0 if which == "boss" else 1.5).timeout
		await RenderingServer.frame_post_draw
		var hs: HallsScene = main.battle.halls
		var props: Array = []
		if hs.r3:
			for a in hs.r3.standing:
				props.append("%s (%.2f, %.2f)" % [a[4], a[0], a[1]])
		print("z%d %s %s: %s" % [zone, which, st.enemy_art, ", ".join(props) if not props.is_empty() else "no standing props"])
		root.get_texture().get_image().save_png(out.path_join("z%d_%s.png" % [zone, which]))
	print("FIGHT SHOTS DONE")
	quit()
