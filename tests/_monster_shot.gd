extends SceneTree
## Redrawn monsters in the real fight at phone size, for Juzo: one picture per art key.
##   godot --path . --resolution 430x932 -s tests/_monster_shot.gd -- <tag> <key>[@floor] ...
## -> shots/monsters/<tag>/<key>.png (floor picks the zone's hall behind it)
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
		var key: String = arg.get_slice("@", 0)
		if arg.contains("@"):
			st.floor_num = int(arg.get_slice("@", 1))
			main.battle.last_floor = st.floor_num
		st.spawn_enemy()
		# the plain monster: no variant recolour, rarity aura or mods
		st.enemy_variant = ""
		st.enemy_tier = 0
		st.enemy_mods.clear()
		st.enemy_elite = false
		st.enemy_calamity = 0
		st.enemy_art = key
		st.enemy_is_boss = key.begins_with("boss_") or key.begins_with("calamity_")
		Sprites.clear_monster_cache()
		main.refresh()
		await create_timer(3.0 if st.enemy_is_boss else 1.5).timeout
		root.get_texture().get_image().save_png(dir.path_join(key + ".png"))
	quit()

