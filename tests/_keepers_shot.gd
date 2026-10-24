extends SceneTree
## Each town page with its keeper's picture and line, into shots/keepers.
## godot --path . --resolution 430x932 --position 3000,3000 -s tests/_keepers_shot.gd
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var out := TestHero.shots_dir("keepers")
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var st: GameState = main.state
	st.in_town = true
	st.exploring = false
	for page in Lore.KEEPERS.keys():
		if int(page) >= main.town_tabs.get_tab_count():
			continue
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		main.town_tabs.set_tab_hidden(int(page), false)   # show locked buildings too
		main.show_tab(2, int(page))
		main.refresh()
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("page_%02d.png" % int(page)))
	print("KEEPERS SHOTS DONE")
	quit()
