extends SceneTree
## Short per-screen cost report (a few seconds each): CPU process time and frame time in the
## dungeon room, the town, a fight; plus boot cost of the sound bank and save-write times.
## godot --path . --resolution 430x932 -s tests/_perf_screens.gd
const TestHero := preload("res://tests/test_hero.gd")
var main

func _measure(label: String, seconds := 3.0) -> String:
	await create_timer(0.8).timeout   # settle
	var proc := 0.0
	var frame := 0.0
	var n := 0
	var start := Time.get_ticks_msec()
	var last := Time.get_ticks_usec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		frame += (now - last) / 1000.0
		last = now
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		n += 1
		for c in main.get_children():
			if c is Overlay or c is Moments:
				c.queue_free()
	return "%s: frame %.3f ms, process %.3f ms (%d frames)" % [label, frame / n, proc / n, n]

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	seed(11)
	TestHero.make(30)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var out: Array[String] = []
	await process_frame
	# the sound bank's boot cost
	var t0 := Time.get_ticks_usec()
	var s := Sfx.new()
	root.add_child(s)
	out.append("Sfx boot: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	s.queue_free()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	var st: GameState = main.state
	st.autoplay = false
	out.append(await _measure("room"))
	main.go_to_town(true)
	main.refresh()
	await create_timer(2.0).timeout   # walkers built
	out.append(await _measure("town"))
	# save writes, unthrottled (what a codex write after each fight costs)
	st.codex.path = Codex.PATH
	var t1 := Time.get_ticks_usec()
	for i in 20:
		st.codex.save()
	out.append("codex write: %.2f ms each" % ((Time.get_ticks_usec() - t1) / 20000.0))
	var t2 := Time.get_ticks_usec()
	for i in 20:
		st.save_game(true)
	out.append("hero write: %.2f ms each" % ((Time.get_ticks_usec() - t2) / 20000.0))
	for l in out:
		print("PERFS ", l)
	quit()
