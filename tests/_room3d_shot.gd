extends SceneTree
## Screenshots the room view (3D room) and a fight in several rooms and regions into shots/room3d.
## godot --path . --resolution 430x932 -s tests/_room3d_shot.gd
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var out := TestHero.shots_dir("room3d")
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var st: GameState = main.state
	var floors := [2, 3, 4, 5, 6, 7, 40, 80, 140]
	for i in floors.size():
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		st.floor_num = floors[i]
		st.room_count = i * 3 + 1
		st.exploring = true
		st.in_town = false
		main._room_ready = true
		main.refresh()
		await create_timer(0.9).timeout
		var rv: RoomView = main.room_view
		var label: String = rv.scene.r3.kind if rv.scene.r3 else "2d"
		root.get_texture().get_image().save_png(out.path_join("room_%02d_f%d_%s.png" % [i, floors[i], label.replace(" ", "_")]))
		print("room f%d: %s (3d=%s)" % [floors[i], label, rv.scene.is_3d()])
	# a fight in the same room
	st.exploring = false
	main.refresh()
	await create_timer(0.9).timeout
	root.get_texture().get_image().save_png(out.path_join("fight.png"))
	SpriteLight.enabled = false
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out.path_join("fight_unlit.png"))
	SpriteLight.enabled = true
	# Low graphics falls back to the 2D room
	HallsScene.low = true
	st.exploring = true
	main.refresh()
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(out.path_join("room_low.png"))
	print("low: 3d=%s" % main.room_view.scene.is_3d())
	HallsScene.low = false
	print("ROOM3D SHOTS DONE")
	quit()
