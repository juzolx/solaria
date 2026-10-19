extends SceneTree
## The "first boss" milestone cutscene, into shots/moments.
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
	main.state.events.append({"type": "milestone_moment", "title": "Your First Boss", "sub": "Black Annis falls. The deep has noticed you now.", "color": Milestones.COLOR})
	main.refresh()
	await create_timer(3.0).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("moments").path_join("first_boss.png"))
	print("MOMENT SHOT DONE")
	quit()
