extends SceneTree
## Into the dungeon: team with rows, supplies to bring. shots/dive
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(120)
	for d in [[2, "Cleric", "Mara"], [3, "Ranger", "Fen"]]:
		var g := GameState.new()
		g.codex.path = ""
		g.slot = d[0]
		g.new_game()
		g.choose_class(d[1])
		g.hero_name = d[2]
		g.level = 40
		g.save_game()
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	main.go_to_town(true)
	st.set_party([2])
	st.supplies_home = {"potion": 4, "scroll": 1, "might": 2, "iron": 1}
	st.potions = 2
	await create_timer(0.4).timeout
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	FloorPicker.new().show_from_town(main)
	await create_timer(0.6).timeout
	var dir := TestHero.shots_dir("dive")
	root.get_texture().get_image().save_png(dir.path_join("dive.png"))
	var fp: Overlay = null
	for c in main.get_children():
		if c is FloorPicker:
			fp = c
	fp.scroll.scroll_vertical = 330
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(dir.path_join("dive2.png"))
	print("DIVE SHOT DONE")
	quit()
