extends SceneTree
## Found a town, the town picker, and the Inn's recruit section. shots/found
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.8).timeout
	var dir := TestHero.shots_dir("found")
	FoundTown.new().show_for(main, 2)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(dir.path_join("found.png"))
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	TownSelect.new().show_for(main)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(dir.path_join("towns.png"))
	for c in main.get_children():
		if c is Overlay or c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	main.go_to_town(true)
	main.show_tab(2, 3)
	main.refresh()
	await create_timer(0.8).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(dir.path_join("inn.png"))
	print("FOUND SHOT DONE")
	quit()
