extends SceneTree
## Lets a test hero play on Auto for a while at phone size and reports frame times.
## godot --path . --resolution 430x932 -s tests/perf_run.gd -- [seconds]
## On a desktop GPU the numbers only matter compared with earlier runs (spot slowdowns);
## phones need a real-device test.
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var seconds := float(args[0]) if args.size() > 0 else 60.0
	seed(11)
	TestHero.make(12)
	TitleScreen.pending = {"play": 1}
	# Measure headroom: no vsync, no cap
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await create_timer(2.0).timeout  # let loading settle
	var frames: Array[float] = []
	var calls: Array[int] = []
	var start := Time.get_ticks_msec()
	var last := Time.get_ticks_usec()
	var floor_start: int = main.state.floor_num
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
	var sorted := frames.duplicate()
	sorted.sort()
	var total := 0.0
	for f in frames:
		total += f
	var avg := total / frames.size()
	var p95: float = sorted[int(sorted.size() * 0.95)]
	var worst: float = sorted[-1]
	var call_total := 0
	var call_max := 0
	for c in calls:
		call_total += c
		call_max = maxi(call_max, c)
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var report := "PERF: %d frames in %.0fs | avg %.2f ms (%.0f fps) | p95 %.2f ms | worst %.2f ms | draw calls avg %d max %d | memory %.0f MB | floors %d -> %d" % [
		frames.size(), seconds, avg, 1000.0 / avg, p95, worst, call_total / calls.size(), call_max, mem, floor_start, main.state.floor_num]
	print(report)
	var f := FileAccess.open(TestHero.shots_dir("perf").path_join("perf_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")), FileAccess.WRITE)
	f.store_string(report + "\n")
	quit()
