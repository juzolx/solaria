extends SceneTree
## The hatching and forge moments, into shots/moments.
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
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	Menagerie.hatch(st, {"quest": "hunt", "prog": 99})
	main.refresh()
	await create_timer(3.0).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("moments").path_join("hatch.png"))
	for c in main.get_children():
		if c is Moments:
			c.close()
	await create_timer(0.6).timeout
	var setn: String = GameData.SETS.keys()[0]
	var item := GameData.make_set_item(setn, String((GameData.SETS[setn]["pieces"] as Dictionary).keys()[0]), 30, 9999)
	st.events.append({"type": "forge_moment", "item": item, "set": setn})
	main.refresh()
	await create_timer(3.0).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("moments").path_join("forge.png"))
	print("HATCH SHOTS DONE")
	quit()
