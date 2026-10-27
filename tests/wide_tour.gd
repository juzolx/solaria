extends SceneTree
## Juzo (PC wide layout, "the game keeps moving the screen further"): a late-game hero (level 39,
## 188 points to spend, best floor 100, a long title, a big bank, every resource chip) played for
## many turns on a landscape window, with every page visited after each batch of turns and again
## at the larger text size. Fails with ROOT OVERFLOW when the interface asks for more than the
## window, or when any visible control runs past its edge.
## Run (a real window): godot --audio-driver Dummy --path . --resolution 1152x648 -s tests/wide_tour.gd [-- --shots=DIR]
const TestHero := preload("res://tests/test_hero.gd")
const ROUNDS := 3          # batches of turns, all pages after each
const TURNS := 40          # turns per batch

var main
var fails := 0
var checks := 0
var shot_dir := ""

func fail(msg: String) -> void:
	fails += 1
	print("TOUR FAIL: " + msg)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shot_dir = a.get_slice("=", 1)
	seed(7)
	TestHero.make(19)
	var g := GameState.new()
	g.slot = 1
	g.load_game()
	g.level = 39
	g.best_floor = 100
	g.floor_num = 19
	g.stat_points = 188
	g.bank = 183100
	g.scrap = 4321
	g.dust = 987
	g.potions = 14
	g.hidden_class = "fool"
	g.hidden_stage = {"fool": 2}
	g.save_game()
	TitleScreen.pending = {"play": 1}
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	await _close()
	var win := DisplayServer.window_get_size()
	await _sweep("start", true)
	for r in ROUNDS:
		for i in TURNS:
			main._on_tick()
			await process_frame
		await _close()
		await _sweep("after %d turns" % ((r + 1) * TURNS), r == ROUNDS - 1)
	# the larger text size (Settings › Text size) makes the design screen smaller
	main.profile.text_size = 2
	main._fit_layout()
	await process_frame
	await process_frame
	await _sweep("larger text", false)
	main.profile.text_size = 1
	main._fit_layout()
	print("WIDE TOUR DONE %dx%d, checks: %d, failures: %d" % [win.x, win.y, checks, fails])
	quit()

## Every page, checked; pictures of a few on the last pass (with --shots=).
func _sweep(when: String, pictures: bool) -> void:
	_check(when)
	for gi in main._groups().size():
		var grp: TabContainer = main._groups()[gi]
		for s in grp.get_tab_count():
			if grp.is_tab_hidden(s):
				continue
			main.show_tab(gi, s)
			main.refresh()
			await process_frame
			await process_frame
			var title: String = grp.get_tab_title(s).get_slice(" ", 0)
			_check("%s, %s" % [when, title])
			if pictures and shot_dir != "" and title in ["Hero", "Gear", "Bag", "Class", "Skills"]:
				await _close()
				await create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(shot_dir.path_join("%d_%s.png" % [DisplayServer.window_get_size().x, title.to_lower()]))

## ROOT OVERFLOW: what the interface asks for, then every visible control not inside a clipping
## parent (a scroll list's rows are checked through the list itself).
func _check(where: String) -> void:
	checks += 1
	var vp := root.get_visible_rect().size
	var need: Vector2 = main.ui_need()
	if need.x > vp.x + 0.5 or need.y > vp.y + 0.5:
		fail("ROOT OVERFLOW: %s, the interface needs %.0fx%.0f of %.0fx%.0f%s" % [where, need.x, need.y, vp.x, vp.y, _widest(main.ui_box, vp)])
		return
	var screen := Rect2(Vector2.ZERO, vp).grow(0.5)
	var worst: Control = null
	for c in main.ui_box.find_children("*", "Control", true, false):
		var cc := c as Control
		if not cc.is_visible_in_tree() or cc.size.x <= 0.0 or cc.size.y <= 0.0 or _clipped(cc):
			continue
		if not screen.encloses(cc.get_global_rect()):
			if worst == null or cc.get_path().get_name_count() > worst.get_path().get_name_count():
				worst = cc   # the deepest one says what to fix
	if worst != null:
		fail("ROOT OVERFLOW: %s, %s runs past the window (%s) [%s]" % [where, worst.get_class(), worst.get_global_rect(), _path(worst)])

func _clipped(c: Control) -> bool:
	var p := c.get_parent()
	while p is Control and p != main.ui_box:
		if (p as Control).clip_contents:
			return true
		p = p.get_parent()
	return false

## Down the widest (or tallest) children: the control whose minimum makes the interface too big.
func _widest(c: Control, vp: Vector2) -> String:
	var bits := []
	var n := c
	for d in 14:
		var best: Control = null
		var best_over := 0.0
		for k in n.get_children():
			if k is Control and (k as Control).visible:
				var m := (k as Control).get_combined_minimum_size()
				var over := maxf(m.x / vp.x, m.y / vp.y)
				if best == null or over > best_over:
					best = k
					best_over = over
		if best == null:
			break
		var t = best.get("text")
		bits.append("%s%s %.0fx%.0f" % [best.get_class(), (" \"%s\"" % str(t).left(24)) if t != null and str(t) != "" else "", best.get_combined_minimum_size().x, best.get_combined_minimum_size().y])
		n = best
	return " (" + " > ".join(bits) + ")"

func _path(c: Node) -> String:
	var bits := []
	var p := c
	for i in 4:
		if p == null:
			break
		bits.push_front(String(p.name) if not String(p.name).begins_with("@") else p.get_class())
		p = p.get_parent()
	return "/".join(bits)

func _close() -> void:
	main.moment_queue.clear()
	for c in main.get_children():
		if c is Moments:
			c.close()
		elif c is Overlay:
			c.queue_free()
	await create_timer(0.6).timeout
	await process_frame
