extends SceneTree
## Screenshots the 3D room view of one zone in each of its room types into shots/halls/<tag>.
## godot --path . --resolution 430x932 --position 3000,3000 -s tests/_halls_zone_shot.gd -- <zone 0-9> <tag>
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var zone := int(args[0]) if args.size() > 0 else 1
	var tag := String(args[1]) if args.size() > 1 else "now"
	var out := TestHero.shots_dir("halls/%s" % tag)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var st: GameState = main.state
	# another run sharing this user folder (check.sh) can swap the save under us: say so, loudly
	print("user data: %s" % OS.get_user_data_dir())
	assert(st.hero_name == "Thorin", "shots: the test hero is %s, not Thorin (another run shares %s)" % [st.hero_name, OS.get_user_data_dir()])
	if st.hero_name != "Thorin":
		quit(1)
		return
	var seen := {}
	for rc in range(1, 40):
		if seen.size() >= 3:
			break
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		st.floor_num = zone * GameData.ZONE_FLOORS + 12
		st.room_count = rc
		st.room_props = []   # a plain room: no event left in the save (a rift stood in the middle door)
		st.room_trap = {}
		st.exploring = true
		st.in_town = false
		main._room_ready = true
		main.refresh()
		# the doors you'd pick from, glowing and tappable, as the player sees the room
		st.doors = ["fight", "treasure", "elite"]
		st.path_offer = ["door_l", "door_m", "door_r"]
		await create_timer(0.9).timeout
		var rv: RoomView = main.room_view
		var label: String = rv.scene.r3.kind if rv.scene.r3 else "2d"
		if seen.has(label):
			continue
		seen[label] = true
		await create_timer(0.8).timeout   # let the rebuilt room render before the shot
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(out.path_join("z%d_%s.png" % [zone, label.replace(" ", "_")]))
		if rv.scene.r3 and rv.scene.r3.pool_mat:
			# the Flooded Depths pool reads as water: its rim colour shows inside its spot (Fable dungeon r5)
			# canvas (design) px to the image's screen px
			var xf := Transform2D.IDENTITY.scaled(Vector2.ONE * float(img.get_width()) / root.get_visible_rect().size.x) * rv.get_global_transform_with_canvas()
			var a := xf * rv.scene.proj(1.0, HallsScene.FLOOR_Y, 3.8)
			var b := xf * rv.scene.proj(3.0, HallsScene.FLOOR_Y, 4.8)
			var rim := Color("#4fb0c6")
			var n := 0
			for y in range(int(minf(a.y, b.y)), int(maxf(a.y, b.y)) + 1):
				for x in range(int(minf(a.x, b.x)), int(maxf(a.x, b.x)) + 1):
					if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
						var c := img.get_pixel(x, y)
						n += 1 if Vector3(c.r - rim.r, c.g - rim.g, c.b - rim.b).length() < 0.1 else 0
			var u := ArtStyle.unit(HallsScene.screen_scale(rv))
			var texels := n / (u * u)   # art pixels, the same on every phone
			print("z%d %s: pool rim texels %d" % [zone, label, texels])
			if texels < 8:
				push_error("z%d %s: the pool barely shows (%d rim texels, want 8+)" % [zone, label, texels])
				quit(1)
				return
		print("z%d room %d: %s" % [zone, rc, label])
	print("HALLS SHOTS DONE")
	quit()
