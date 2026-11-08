extends SceneTree
## A6 motion / juice and R6 performance + debug log:
## effects follow the settings (Reduce motion, Flashing effects, Screen shake),
## particles are capped, the fight runs headless without errors, and the local
## debug log keeps only its last lines and survives a restart.
## godot --headless --path . -s tests/stage6_juice.gd
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func errors_in_log() -> int:
	var n := 0
	for l in DebugLog.lines:
		if l.contains(" ERROR ") or l.contains(" ERR "):
			n += 1
	return n

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return

	# --- Debug log: catches errors, caps, survives a restart ---
	DebugLog.start()
	DebugLog.clear()
	push_error("juice test marker")
	check(Array(DebugLog.lines).any(func(l): return String(l).contains("juice test marker")), "push_error lands in the debug log")
	for i in DebugLog.MAX + 40:
		DebugLog.add("line %d %s" % [i, "x".repeat(500 if i == 3 else 1)])
	check(DebugLog.lines.size() == DebugLog.MAX, "log keeps only the last %d lines (has %d)" % [DebugLog.MAX, DebugLog.lines.size()])
	check(String(DebugLog.lines[-1]).ends_with("line %d x" % (DebugLog.MAX + 39)), "newest line kept last")
	var longest := 0
	for l in DebugLog.lines:
		longest = maxi(longest, l.length())
	check(longest <= DebugLog.LINE_MAX, "lines are cut to %d characters" % DebugLog.LINE_MAX)
	DebugLog.flush()
	check(not DebugLog.dirty, "flush writes and clears dirty")
	DebugLog.reset_memory()  # like closing the app
	check(DebugLog.lines.is_empty(), "memory cleared")
	DebugLog.load_file()
	check(DebugLog.lines.size() == DebugLog.MAX, "the log survives a restart")
	DebugLog.add("after restart")
	check(DebugLog.lines.size() == DebugLog.MAX, "still capped after a restart")
	var rep := DebugLog.report()
	check(rep.contains("Solaria " + PatchNotes.VERSION) and rep.contains("after restart"), "report has the version and the log")
	DebugLog.clear()
	check(DebugLog.lines.is_empty() and FileAccess.get_file_as_string(DebugLog.PATH) == "", "clear empties the log and its file")
	check(SettingsMenu.new().has_method("_show_debug_info"), "Menu has Copy report info")

	# --- Effects follow the settings ---
	var prof := Profile.new()
	var bv := BattleView.new()
	bv.profile = prof
	root.add_child(bv)
	prof.flashes = true
	check(bv._flash_col(1.0, false).a == 1.0 and bv._flash_col(1.0, false).g == 1.0, "hit flash is one hard white frame")
	check(bv._flash_col(0.3, true).a == 0.0, "flash never lingers as a tint")
	check(bv._flash_col(1.0, true).r == 1.0 and bv._flash_col(1.0, true).g < 0.5, "team flash is red")
	prof.flashes = false
	check(bv._flash_col(1.0, false).a <= 0.3, "Flashing effects OFF: only a dim blink")
	prof.reduce_motion = true
	bv._squash("enemy_squash")
	check(bv.enemy_squash == 0.0, "Reduce motion: no hit squash")
	check(not bv._motion_ok(), "Reduce motion is seen")
	bv._hit_stop(0.1)
	check(bv.freeze_left == 0.0, "Reduce motion: no hit stop")
	prof.reduce_motion = false
	prof.shake = false
	bv._hit_stop(0.1)
	check(bv.freeze_left == 0.0, "Screen shake OFF: no hit stop")
	prof.shake = true
	bv._squash("hero_squash")
	check(bv.hero_squash == 1.0, "hit squash plays when motion is on")
	var r := Rect2(10, 20, 40, 60)
	var sq := BattleView.squashed(r, 1.0)
	check(is_equal_approx(sq.end.y, r.end.y) and sq.size.x > r.size.x and sq.size.y < r.size.y, "squash keeps the feet on the ground")
	check(is_equal_approx(sq.get_center().x, r.get_center().x), "squash stays centered")
	check(BattleView.squashed(r, 0.0) == r, "no squash at rest")
	check(int(Sprites.POSES["hit1"]["squash"]) > 0, "pixel pose hit frame squashes")

	# --- Particles are capped ---
	for i in 30:
		bv._burst(Vector2(100, 100), Color.WHITE, 30, 200.0)
	check(bv.particles.size() <= BattleView.MAX_PARTICLES, "particles capped (%d)" % bv.particles.size())
	bv.particles.clear()
	prof.low_graphics = true
	for i in 30:
		bv._burst(Vector2(100, 100), Color.WHITE, 30, 200.0)
	check(bv.particles.size() <= BattleView.MAX_PARTICLES / 2.0, "Low graphics halves the cap")
	var arr: Array = [{"life": 0.5}, {"life": -0.1}, {"life": 0.0}, {"life": 1.0}]
	BattleView._prune(arr, "", "life")
	check(arr.size() == 2, "prune drops dead effects in place")
	var arr2: Array = [{"t": 0.2, "life": 1.0}, {"t": 1.2, "life": 1.0}]
	BattleView._prune(arr2, "t", "life")
	check(arr2.size() == 1, "prune by t/life")
	var arr3: Array[Dictionary] = [{"t": 0.5}, {"t": 1.0}]
	BattleView._prune(arr3, "t", "")
	check(arr3.size() == 1, "prune typed arrays by t")
	bv.queue_free()

	# --- A real fight, headless, with every flourish: no errors ---
	TestHero.make(12)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var before := errors_in_log()
	main.profile.damage_numbers = true
	main.battle._level_up_fx({"level": 13})
	main.battle._burst(Vector2(200, 300), Color.RED, 40, 300.0)
	main.battle._squash("enemy_squash", 1.4)
	main.battle._float("CRIT 120", Vector2(200, 300), Color.YELLOW, 26)
	var mo := Moments.play(main, "god", "Test God", "Your class is reborn.", Color.GOLD)
	for i in 120:
		await process_frame
	if is_instance_valid(mo):
		mo.close()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
	check(errors_in_log() == before, "no errors in a headless fight with every effect (%d new)" % (errors_in_log() - before))
	main.queue_free()
	await process_frame

	DebugLog.clear()
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	print("STAGE6 JUICE TESTS DONE, failures: ", fails)
	quit()
