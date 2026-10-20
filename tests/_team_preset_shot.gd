extends SceneTree
## Party page: presets and heroes at home. shots/teampresets
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(60)
	for d in [[2, "Trickster", "Vex"], [3, "Bard", "Lark"], [4, "Knight", "Oren"]]:
		var g := GameState.new()
		g.codex.path = ""
		g.slot = d[0]
		g.new_game()
		g.choose_class(d[1])
		g.hero_name = d[2]
		g.level = 35
		g.save_game()
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.set_party([4])
	main.profile.presets[0] = {"slots": [1, 4]}
	main.profile.presets[1] = {"slots": [2, 3]}
	st.in_town = false
	for i in 120:
		Bench.on_kill(st)
	main.show_tab(0, 4)
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("teampresets").path_join("party.png"))
	main.party_tab.scroll_vertical = 2000
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("teampresets").path_join("party2.png"))
	print("TEAM SHOT DONE")
	quit()
