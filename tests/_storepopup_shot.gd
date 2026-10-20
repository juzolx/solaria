extends SceneTree
## The (switched off) supporter store popup, into shots/store.
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
	main.go_to_town(true)
	await create_timer(0.3).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	StorePopup.new().show_for(main)
	await create_timer(0.3).timeout
	main.refresh()
	await create_timer(0.5).timeout
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("store").path_join("supporter_store.png"))
	print("STORE SHOT DONE")
	quit()
