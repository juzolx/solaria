extends SceneTree
## Name color + frame on the fight plate, and the Guild Hall pickers, into shots/looks.
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
	var cx: Codex = main.codex
	for id in ["f50", "grendel", "evo"]:
		cx.achievements[id] = "2026-10-19"
	cx.name_color = "moss"
	cx.frame = "bone"
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("looks").path_join("fight_plate.png"))
	print("LOOKS SHOTS DONE")
	quit()
