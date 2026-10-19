extends SceneTree
## A monster dissolving as it dies, into shots/dissolve.
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
	await create_timer(0.4).timeout
	var st: GameState = main.state
	st.enemy_hp = 0
	st._enemy_defeated()
	main.refresh()
	for k in 4:
		await create_timer(0.14).timeout
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		await process_frame
		root.get_texture().get_image().save_png(TestHero.shots_dir("dissolve").path_join("d%d.png" % k))
	print("DISSOLVE SHOT DONE")
	quit()
