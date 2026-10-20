extends SceneTree
## The class picker with all base classes. shots/classpick
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
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	main._show_class_picker()
	await create_timer(0.6).timeout
	var dir := TestHero.shots_dir("classpick")
	root.get_texture().get_image().save_png(dir.path_join("a.png"))
	for c in main.get_children():
		if c is Overlay:
			c.scroll.scroll_vertical = 100000
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(dir.path_join("b.png"))
	print("CLASSPICK SHOT DONE")
	quit()
