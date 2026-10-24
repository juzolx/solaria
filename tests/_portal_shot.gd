extends SceneTree
## The rift portal card (depth 3) at phone size, into shots/rift.
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
	st._room_cleared()
	st.doors = ["rift", "rift", "rift"]
	st.choose_path("door_m")
	st.room_props[0]["depth"] = 3
	Halls.interact(st, 0)
	main._room_ready = true
	main.refresh()
	await create_timer(0.5).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.8).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("rift").path_join("rift_card.png"))
	print("RIFT CARD SHOT DONE ", st.path_offer, " ", st.path_info("portal:rift"))
	quit()
