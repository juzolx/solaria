extends SceneTree
## The game saves when the phone pauses the app, loses focus or closes.
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(12)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	check(main.started, "the test hero is playing")
	var events := {"paused": Node.NOTIFICATION_APPLICATION_PAUSED, "focus lost": Node.NOTIFICATION_APPLICATION_FOCUS_OUT, "close request": Node.NOTIFICATION_WM_CLOSE_REQUEST}
	var extra := 100
	for label in events:
		main.state.gold += extra
		var expected: int = main.state.gold
		main.notification(events[label])
		var g := GameState.new()
		g.slot = 1
		check(g.load_game() and g.gold == expected, "saved on %s (gold %d, expected %d)" % [label, g.gold, expected])
		extra += 37
	main.profile.dark_art = not main.profile.dark_art
	var want: bool = main.profile.dark_art
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(Profile.load_profile().dark_art == want, "profile saved on pause")
	print("STAGE2 LIFECYCLE TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
