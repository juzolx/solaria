extends SceneTree
## Every room event (the one thing in the room) and every trap plate in one zone, into shots/room_events/<tag>.
## godot --path . --resolution 430x932 --position 3000,3000 -s tests/_room_events_shot.gd -- <zone 0-9> <tag>
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var zone := int(args[0]) if args.size() > 0 else 1
	var tag := String(args[1]) if args.size() > 1 else "now"
	var out := TestHero.shots_dir("room_events/%s" % tag)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var st: GameState = main.state
	st.in_town = false
	st.floor_num = zone * GameData.ZONE_FLOORS + 12
	st.autoplay = false   # Auto would use the event before the shot
	var shots := ["treasure", "mimic", "altar", "nest", "stranger", "traveler", "merchant", "beast", "rest", "rift", "camp"]
	for k in Halls.TRAPS.keys():
		shots.append("trap_" + String(k))
	shots.append("trial")   # last: the champion fight it starts would spill into later shots
	for i in shots.size():
		var what: String = shots[i]
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		var room := "treasure" if what == "mimic" else ("treasure" if what.begins_with("trap_") else what)
		for attempt in 6:   # a door can roll an ambush or a mid boss: roll again until the room is quiet
			st.room_count = 7   # same room every time
			st.enemy_hp = 0
			st._room_cleared()
			st.doors = [room, room, room]
			st.choose_path("door_m")
			if st.enemy_hp <= 0:
				break
		if st.room_props.is_empty() and not what.begins_with("trap_"):
			st.exploring = true
			Halls.enter_event_room(st, room)   # the door rolled an ambush: set the event up directly
		if what == "mimic":
			st.room_props[0]["mimic"] = true
			st.room_props[0]["spotted"] = true
		if what == "trial":   # the test hero has no champion waiting: give the gate one
			st.room_props[0]["trial"] = {"kind": "hidden", "id": "shot", "name": "A champion", "goal": "Win."}
			st.room_props[0]["used"] = false
		if what == "traveler":
			st.room_props[0]["who"] = "smith"
		if what.begins_with("trap_"):
			st.room_props.clear()
			st.room_trap = {"kind": what.substr(5), "spotted": true, "done": false, "x": 0.5, "y": 0.6}
		main.nav_page = 0
		main._apply_nav()
		main._room_ready = true
		main.refresh()
		await create_timer(1.0).timeout
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("z%d_%02d_%s.png" % [zone, i, what]))
	print("ROOM EVENTS SHOTS DONE")
	quit()
