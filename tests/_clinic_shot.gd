extends SceneTree
## The Clinic with pets to bring along, and the wheel with a full bag, into shots/clinic.
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
	var st: GameState = main.state
	st.pets.clear()
	st.pets_out.clear()
	Menagerie.make_pet(st, "Barghest", "barghest", 1, "t")
	var b := Menagerie.make_pet(st, "Gullinbursti", "gullinbursti", 3, "t")
	b["hurt"] = 4
	Menagerie.make_pet(st, "Will-o'-Wisp", "will_o_wisp", 2, "t")
	main.go_to_town()
	await create_timer(0.3).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	main.refresh()
	await create_timer(0.3).timeout
	main._on_building("clinic")
	main.refresh()
	await create_timer(0.5).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("clinic").path_join("clinic.png"))
	while st.bag.size() < st.bag_capacity() + 2:
		st.bag.append(GameData.make_item("Legs", 1, 30, st._new_id()))
	st.bag_version += 1
	main._on_building("tavern")
	main.refresh()
	await create_timer(0.5).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("clinic").path_join("wheel_full.png"))
	print("CLINIC SHOTS DONE")
	quit()
