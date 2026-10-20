extends SceneTree
## A fight with a full bag (the warning chip), into shots/bagfull.
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
	while not st.bag_full():
		st.bag.append(GameData.make_item("Legs", 0, 30, st._new_id()))
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("bagfull").path_join("fight.png"))
	print("BAGFULL SHOT DONE ", st.bag.size())
	quit()
