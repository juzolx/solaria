extends SceneTree
## Bag: Select mode with picks, then the compare popup on first tap. shots/bagpick
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
	for i in 12:
		st.bag.append(GameData.make_item(GameData.SLOT_ORDER[i % GameData.SLOT_ORDER.size()], i % 4, 30, st._new_id()))
	st.bag_version += 1
	main.show_tab(1, 1)
	main.refresh()
	var bt: BagTab = main.bag_tab
	bt._toggle_picking()
	for i in 4:
		bt._tap(int(st.bag[st.bag.size() - 1 - i]["id"]))
	await create_timer(0.6).timeout
	var dir := TestHero.shots_dir("bagpick")
	root.get_texture().get_image().save_png(dir.path_join("pick.png"))
	var n0 := st.bag.size()
	bt._bulk("salvage")
	await process_frame
	print("BULK removed ", n0 - st.bag.size(), " picking=", bt.picking)
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	bt._tap(int(st.bag[0]["id"]))
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("compare.png"))
	print("BAGPICK SHOT DONE")
	quit()
