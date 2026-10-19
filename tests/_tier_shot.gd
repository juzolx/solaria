extends SceneTree
## A fight against each monster tier (Common..Mythic) into shots/tiers.
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var out := TestHero.shots_dir("tiers")
	var st: GameState = main.state
	for t in 6:
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		st.enemy_tier = t
		main.refresh()
		await create_timer(0.5).timeout
		var img := root.get_texture().get_image()
		img.save_png(out.path_join("tier_%d.png" % t))
	print("TIER SHOTS DONE")
	quit()
