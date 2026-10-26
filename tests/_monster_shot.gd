extends SceneTree
## Redrawn monsters in the real fight at phone size, for Juzo: one picture per art key.
##   godot --path . --resolution 430x932 -s tests/_monster_shot.gd -- <tag> <key>[@floor][#tier][+pack] ...
## -> shots/monsters/<tag>/<key>.png (floor picks the zone's hall behind it, tier 0-5 its rank,
## +pack two pack-mates waiting behind it; calamity_N keys appear as that Calamity)
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.in_town = false  # the fight, never the town (a reused test save may be in town)
	main.nav_page = 0
	main._apply_nav()
	var dir := TestHero.shots_dir("monsters/" + args[0])
	for arg in args.slice(1):
		var pack := arg.ends_with("+pack")
		arg = arg.trim_suffix("+pack")
		var tier := int(arg.get_slice("#", 1)) if arg.contains("#") else 0
		arg = arg.get_slice("#", 0)
		var key: String = arg.get_slice("@", 0)
		if arg.contains("@"):
			st.floor_num = int(arg.get_slice("@", 1))
			main.battle.last_floor = st.floor_num
		st.spawn_enemy()
		# the plain monster: no variant recolour, rarity aura or mods
		st.enemy_variant = ""
		st.enemy_tier = tier
		st.enemy_mods.clear()
		st.enemy_elite = false
		st.enemy_calamity = 0
		# one monster, labelled with its own name (not a pack of whatever spawned)
		st.horde_left = 0
		st.horde_pack = false
		st.horde_total = 0
		st.enemy_species = key.trim_prefix("boss_")
		st.enemy_name = Monsters.name_of(st.enemy_species)
		st.enemy_art = key
		st.enemy_is_boss = key.begins_with("boss_")
		if key.begins_with("calamity_"):
			st.enemy_calamity = int(key.trim_prefix("calamity_")) + 1
			st.enemy_name = String(Calamity.info(st.enemy_calamity - 1)[0])
		if pack:
			st.horde_left = 3
			st.horde_total = 3
			st.horde_pack = true
		var shot := key + ("_t%d" % tier if tier > 0 else "") + ("_pack" if pack else "")
		Sprites.clear_monster_cache()
		main.refresh()
		await create_timer(3.0 if st.enemy_is_boss or st.enemy_calamity > 0 else 1.5).timeout
		root.get_texture().get_image().save_png(dir.path_join(shot + ".png"))
	quit()

