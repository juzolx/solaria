extends SceneTree
## The "Leave the dungeon?" confirm, into shots/leave.
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
	await process_frame
	var st: GameState = main.state
	st.path_offer.clear()
	st.fight = 1
	st.dive = {"floor": 30, "gold": 0, "items": []}
	main.go_to_town()
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("leave").path_join("confirm.png"))
	print("LEAVE SHOT DONE paused=", main.timer.paused, " in_town=", st.in_town, " blocked=", Town.blocked(st))
	quit()
