extends SceneTree
## The one-time 0.12 save reset: old saves are wiped once, settings are kept,
## and saves made after the reset are left alone.
## godot --headless --path . -s tests/fresh_start.gd
var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)

func _initialize() -> void:
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	# Saves from an older version (no epoch)
	var old := Profile.new()
	old.volume = 0.33
	old.max_floor = 120
	old.stash = [{"id": 1}]
	old.player_name = "Juzo"
	old.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = Codex.PATH
	g.new_game()
	g.choose_class("Warrior")
	g.save_game()
	g.codex.add("kills", 500)
	g.codex.save()
	check(GameState.has_slot(1), "setup: an old hero exists")
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	check(not GameState.has_slot(1), "old heroes are wiped")
	check(main.codex.stat("kills") == 0, "the old codex is wiped")
	check(main.profile.save_epoch == Profile.SAVE_EPOCH and main.profile.max_floor == 0 and main.profile.stash.is_empty(), "progress reset")
	check(is_equal_approx(main.profile.volume, 0.33) and main.profile.player_name == "Juzo", "settings and online name kept")
	check(main.fresh_start_notice or main.get_children().any(func(c): return c is Overlay), "the player is told")
	main.queue_free()
	await process_frame
	# A hero made after the reset survives the next launch
	var h := GameState.new()
	h.slot = 2
	h.codex.path = ""
	h.new_game()
	h.choose_class("Mage")
	h.save_game()
	var main2 = load("res://main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	check(GameState.has_slot(2), "saves after the reset are kept")
	check(not main2.fresh_start_notice, "no notice the second time")
	main2.queue_free()
	await process_frame
	# A brand-new player gets no reset notice
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var main3 = load("res://main.tscn").instantiate()
	root.add_child(main3)
	await process_frame
	check(not main3.fresh_start_notice and main3.profile.save_epoch == Profile.SAVE_EPOCH, "new players start at the current epoch quietly")
	main3.queue_free()
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	print("FRESH START TESTS DONE, failures: ", fails)
	quit()
