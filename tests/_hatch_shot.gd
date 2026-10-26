extends SceneTree
## The hatching and forge moments, into shots/moments.
const TestHero := preload("res://tests/test_hero.gd")
## Args: [out dir under res://] (default shots/moments). Fable pets R4: a Mythic hatch and a nest too.
func _shot(dir: String, n: String) -> void:
	root.get_texture().get_image().save_png(dir.path_join(n + ".png"))

func _close(main) -> void:
	for c in main.get_children():
		if c is Moments:
			c.close()
	await create_timer(0.6).timeout

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var dir: String = ProjectSettings.globalize_path("res://" + args[0]) if args.size() > 0 else TestHero.shots_dir("moments")
	DirAccess.make_dir_recursive_absolute(dir)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	Menagerie.hatch(st, {"quest": "hunt", "prog": 99})
	main.refresh()
	await create_timer(3.0).timeout
	_shot(dir, "hatch")
	await _close(main)
	Menagerie.hatch(st, {"zone": String(GameData.ZONES[2]["id"]), "tier": 5})   # a Mythic: rays and the legendary chime
	main.refresh()
	await create_timer(2.2).timeout
	_shot(dir, "hatch_mythic")
	await _close(main)
	st.eggs.clear()
	Menagerie.give_egg(st, "nest", 1, 4)   # a Legendary nest
	main.refresh()
	await create_timer(2.2).timeout
	_shot(dir, "nest")
	await _close(main)
	var setn: String = GameData.SETS.keys()[0]
	var item := GameData.make_set_item(setn, String((GameData.SETS[setn]["pieces"] as Dictionary).keys()[0]), 30, 9999)
	st.events.append({"type": "forge_moment", "item": item, "set": setn})
	main.refresh()
	await create_timer(3.0).timeout
	_shot(dir, "forge")
	print("HATCH SHOTS DONE")
	quit()
