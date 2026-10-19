extends SceneTree
## A Rare monster winding up (the orange !) into shots/telegraph.
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
	st.enemy_tier = 2
	st.cfight["turns"] = 3
	Combat.start_windup(st, Combat.HEAVY_MULT)
	main.refresh()
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("telegraph").path_join("windup.png"))
	print("WINDUP SHOT DONE")
	quit()
