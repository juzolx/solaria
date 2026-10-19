extends SceneTree
## The team strip with two companions, into shots/team.
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	for pair in [[2, "Cleric"], [3, "Mage"]]:
		var ph := GameState.new()
		ph.slot = int(pair[0])
		ph.codex.path = ""
		ph.new_game()
		ph.choose_class(pair[1])
		ph.level = 30
		ph.save_game()
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	st.set_party([2, 3])
	st.party.members[1].hp = int(st.party.members[1].max_hp() * 0.2)
	main.refresh()
	await create_timer(0.8).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("team").path_join("strip.png"))
	print("STRIP SHOT DONE ", st.party.size())
	GameState.delete_saves()
	quit()
