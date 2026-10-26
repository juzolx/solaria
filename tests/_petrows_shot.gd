extends SceneTree
## Character > Pets with three pets, into shots/pets.
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
	st.pets.clear()
	st.pets_out.clear()
	Menagerie.make_pet(st, "barghest", "barghest", 1, "test")
	var b := Menagerie.make_pet(st, "Gullinbursti", "gullinbursti", 3, "test")
	b["level"] = 12
	Menagerie.make_pet(st, "will_o_wisp", "will_o_wisp", 2, "test")
	Menagerie.give_egg(st, "test")
	main.show_tab(0, 5)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("pets").path_join("tab.png"))
	print("PET TAB SHOT DONE")
	quit()
