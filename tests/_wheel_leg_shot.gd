extends SceneTree
## Wheel Legendary table + odds screen at phone size. shots/wheel_leg
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
	main.codex.stats["guide_skip"] = 1
	var s: GameState = main.state
	s.gold += 5000000
	var dir := TestHero.shots_dir("wheel_leg")
	main.go_to_town(true)
	await create_timer(0.3).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	main.show_tab(2, 2)
	main.wheel_tab.leg = true
	main.wheel_tab.shown = ""
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("1_locked.png"))
	s.best_floor = 250
	s.stats["LUK"] = 60
	WheelTables.on_floor(s)
	main.wheel_tab.shown = ""
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("2_open.png"))
	main.wheel_tab._spin()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("3_spun.png"))
	main.wheel_tab.show_odds()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("4_odds.png"))
	print("WHEEL LEG SHOT DONE ", dir)
	quit()
