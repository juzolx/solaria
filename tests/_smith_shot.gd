extends SceneTree
## Hilde's wares at the Blacksmith, into shots/smith.
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
	main.go_to_town()
	await create_timer(0.3).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	main._on_building("smith")
	await create_timer(0.3).timeout
	main.craft_tab._show_section("wares")
	main.refresh()
	await create_timer(0.5).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("smith").path_join("wares.png"))
	print("SMITH SHOT DONE ", st.smith_stock.size())
	quit()
