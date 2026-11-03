extends SceneTree
## Times single pieces the perf pass changed (desktop numbers; compare, don't trust as phone numbers).
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	var g := GameState.new()
	g.slot = 1
	g.load_game()
	g.save_game(true)
	var hp: String = g.save_paths()[0]
	var cx := Codex.load_codex()
	cx.save()
	for k in [[hp, "hero"], [Codex.PATH, "codex"]]:
		var t := Time.get_ticks_usec()
		for i in 50:
			SaveIO._parse(k[0], k[1])
		print("PERFB parse %s (%d bytes): %.3f ms" % [k[1], FileAccess.get_file_as_bytes(k[0]).size(), (Time.get_ticks_usec() - t) / 50000.0])
	var t2 := Time.get_ticks_usec()
	var n := 0
	for track in ["zone_0", "zone_1", "zone_2", "zone_3", "zone_4", "zone_5", "zone_6", "zone_7", "zone_8", "zone_9", "boss", "boss2", "menu", "town"]:
		var s = ResourceLoader.load("res://sounds/music_%s.wav" % track, "", ResourceLoader.CACHE_MODE_IGNORE)
		n += 1 if s else 0
	print("PERFB load %d music tracks: %.1f ms" % [n, (Time.get_ticks_usec() - t2) / 1000.0])
	quit()
