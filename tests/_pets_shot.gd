extends SceneTree
## A baby pet and a grown Cherished pet in a fight and in the room, into shots/pets.
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
	var a := Menagerie.make_pet(st, "Barghest", "barghest", 1, "test")
	var b := Menagerie.make_pet(st, "Gullinbursti", "gullinbursti", 3, "test")
	b["level"] = 30
	b["cherished"] = true
	st.pets_out = [int(a["id"]), int(b["id"])]
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("pets").path_join("fight.png"))
	a["level"] = 30
	a["cherished"] = true
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("pets").path_join("fight_grown.png"))
	st.exploring = true
	main._room_ready = true
	main.refresh()
	await create_timer(0.8).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("pets").path_join("room.png"))
	print("PETS SHOT DONE ", Menagerie.out(st).size())
	quit()
