extends SceneTree
## A traveler in the dungeon, then the talk popup. shots/traveler
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
	st.in_town = false
	st.enemy_hp = 0
	st._room_cleared()
	st.doors = ["traveler", "traveler", "traveler"]
	st.choose_path("door_m")
	st.room_props[0]["who"] = "smith"
	main.nav_page = 0
	main._apply_nav()
	main._room_ready = true
	main.refresh()
	await create_timer(0.8).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.3).timeout
	var dir := TestHero.shots_dir("traveler")
	root.get_texture().get_image().save_png(dir.path_join("room.png"))
	Halls.interact(st, 0)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("talk.png"))
	print("TRAVELER SHOT DONE")
	quit()
