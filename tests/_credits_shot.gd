extends SceneTree
## Menu > Credits at phone size into shots/credits.
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
	CreditsScreen.new().show_for(main)
	await create_timer(0.5).timeout
	var img := root.get_texture().get_image()
	img.save_png(TestHero.shots_dir("credits").path_join("credits.png"))
	print("CREDITS SHOT DONE")
	quit()
