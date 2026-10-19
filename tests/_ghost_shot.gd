extends SceneTree
## Captures fight frames right after hits, to see the HP ghost and hit feedback.
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
	var out := TestHero.shots_dir("feel")
	for i in 6:
		main._on_tick()
		await create_timer(0.12).timeout
		root.get_texture().get_image().save_png(out.path_join("hit_%d.png" % i))
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		await create_timer(0.5).timeout
	print("FEEL SHOTS DONE")
	quit()
