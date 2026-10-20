extends SceneTree
## Level 15 with a hidden class earned: the popup, then the Class page after taking it. shots/hidden
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
	st.class_path = []
	main.codex.stats["guide_skip"] = 1
	st.class_told = -1
	st.level = 14
	st.xp = 0
	st.feats["wheel_best"] = 5
	st.feats["goblins"] = 25
	Hidden.check(st)
	st.gain_xp(GameData.xp_to_next(14))
	main.refresh()
	await create_timer(1.0).timeout
	for c in main.get_children():
		if c is Overlay and not c.get_child_count() == 0 and c.has_method("close") and c.scroll and c.content.get_child_count() < 3:
			pass
	var dir := TestHero.shots_dir("hidden")
	root.get_texture().get_image().save_png(dir.path_join("offer.png"))
	var picker: Overlay = null
	for c in main.get_children():
		if c is Overlay:
			picker = c
	if picker:
		picker.scroll.scroll_vertical = 100000
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(dir.path_join("offer2.png"))
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	Hidden.take(st, "jester")
	await create_timer(3.5).timeout
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	main.show_tab(0, 1)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join("class.png"))
	print("HIDDEN SHOT DONE offer=", st.hidden_offer, " class=", st.hidden_class)
	quit()
