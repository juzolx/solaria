extends SceneTree
## A skill button right after use (ring) into shots/cooldown.
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
	var id: String = st.active_slots[0]
	var cd := int(SkillData.info(id).get("cd", 4))
	st.skill_cds[id] = int(cd * 0.6)
	main.refresh()
	await create_timer(0.4).timeout
	var img := root.get_texture().get_image()
	img.save_png(TestHero.shots_dir("cooldown").path_join("cooling.png"))
	print("CD SHOT DONE ", id, " ", cd)
	quit()
