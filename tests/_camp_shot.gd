extends SceneTree
## A room with a hidden portal, into shots/rift.
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
	st.doors = ["camp", "camp", "camp"]
	st.choose_path("door_m")
	main._room_ready = true
	main.refresh()
	await create_timer(1.0).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("camp").path_join("camp_room.png"))
	st.gold = 4200
	CampPopup.new().show_for(main)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("camp").path_join("camp_popup.png"))
	print("CAMP SHOT DONE ", st.exploring)
	quit()
