extends SceneTree
## The Autoplay popup with its rules, into shots/auto.
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
	AutoRules.toggle(main.state, "stop_boss")
	SkillsTab.auto_battle_popup(main)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("auto").path_join("popup.png"))
	print("AUTO SHOT DONE")
	quit()
