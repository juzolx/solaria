extends SceneTree
## The Guild Hall looks shop, into shots/store.
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
	main._on_building("guild")
	await create_timer(0.3).timeout
	st.gold = 2000000
	st.codex.bought.append("color:torch")
	main.achievements_tab.shop_open = true
	main.achievements_tab.shown = 0
	main.refresh()
	await create_timer(0.5).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("store").path_join("looks_shop.png"))
	print("STORE SHOT DONE")
	quit()
