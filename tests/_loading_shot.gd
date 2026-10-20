extends SceneTree
## The loading screen, then the town page and shop with the new look. shots/look
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	LoadingScreen.enabled = true
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.15).timeout
	var dir := TestHero.shots_dir("look")
	root.get_texture().get_image().save_png(dir.path_join("loading.png"))
	await create_timer(1.0).timeout
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	main.go_to_town(true)
	main.nav_page = 3
	main._apply_nav()
	main.refresh()
	await create_timer(0.8).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(dir.path_join("town.png"))
	main.show_tab(2, 0)
	main.refresh()
	await create_timer(0.6).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(dir.path_join("shop.png"))
	print("LOOK SHOT DONE")
	quit()
