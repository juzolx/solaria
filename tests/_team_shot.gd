extends SceneTree
## A summon in a fight and the pet in the room, into shots/team.
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
	var out := TestHero.shots_dir("team")
	var st: GameState = main.state
	print("pet stage ", World.pet_stage(st), " pet_on ", st.pet_on)
	for nm in ["Skeleton", "Wolf"]:
		st.summon_turns = 5
		st.summon_name = nm
		await create_timer(0.6).timeout
		root.get_texture().get_image().save_png(out.path_join("summon_%s.png" % nm))
	st.summon_turns = 0
	if World.pet_stage(st) < 0:
		st.hero_class = World.PETS.keys()[0]
	print("pet stage now ", World.pet_stage(st), " ", st.hero_class)
	st.exploring = true
	main._room_ready = true
	main.refresh()
	await create_timer(0.8).timeout
	root.get_texture().get_image().save_png(out.path_join("room_pet.png"))
	print("TEAM SHOTS DONE")
	quit()
