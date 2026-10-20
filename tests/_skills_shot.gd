extends SceneTree
## The skill book as cards, with several skills, into shots/skills.
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
	var n := 0
	for id in SkillData.SKILLS:
		if n >= 11:
			break
		if not st.skill_book.has(id):
			st.skill_book[id] = 1 + n % 5
			n += 1
	main.show_tab(0, 3)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("skills").path_join("book.png"))
	print("SKILLS SHOT DONE")
	quit()
