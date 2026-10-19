extends SceneTree
## A spore-cloud fight bursting, into shots/hazard.
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
	Variants.make(st, "Gilded")
	st.cfight["turns"] = 3
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("variant").path_join("countdown.png"))
	print("VARIANT SHOT DONE")
	quit()
