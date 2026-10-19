extends SceneTree
## The paper-doll gear screen with some gear on, into shots/doll.
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
	for s in ["Weapon", "Helmet", "Chest", "Feet"]:
		st.equipped[s] = GameData.make_item(s, [2, 3, 4, 1][["Weapon", "Helmet", "Chest", "Feet"].find(s)], 30, st._new_id())
	main.show_tab(1, 0)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("doll").path_join("gear.png"))
	print("DOLL SHOT DONE")
	quit()
