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

	# Battery saver and Low graphics
	main.profile.battery_saver = true
	main.profile.low_graphics = true
	main.apply_settings()
	check(Engine.max_fps == 30, "battery saver caps at 30 fps")
	check(HallsScene.low, "low graphics reaches the room renderer")
	var p := Profile.load_profile()
	check(p.battery_saver and p.low_graphics, "both settings are saved")
	main.profile.battery_saver = false
	main.profile.low_graphics = false
	main.apply_settings()
	check(Engine.max_fps == 60 and not HallsScene.low, "both settings turn off again")

	# Reduce motion and high-contrast text
	main.profile.reduce_motion = true
	main.profile.high_contrast = true
	main.apply_settings()
	main.battle.freeze_left = 0.0
	main.battle._hit_stop(0.2)
	check(main.battle.freeze_left == 0.0, "no hit stop with Reduce motion")
	var dim_label := UI.label("hint", 13, UI.DIM)
	check(dim_label.get_theme_color("font_color") == UI.DIM_CONTRAST, "high-contrast text brightens dim labels")
	dim_label.free()
	var pp := Profile.load_profile()
	check(pp.reduce_motion and pp.high_contrast, "both accessibility settings are saved")
	main.profile.reduce_motion = false
	main.profile.high_contrast = false
	main.apply_settings()
	main.battle._hit_stop(0.2)
	check(main.battle.freeze_left > 0.0, "hit stop is back once Reduce motion is off")

	# Speed cycles 1x -> 2x -> 3x -> 1x and sets the turn timer
	main.state.speed = 1
	var waits: Array = []
	for i in 3:
		main.speed_button.pressed.emit()
		waits.append(snappedf(main.timer.wait_time, 0.001))
	check(main.state.speed == 1 and waits.size() == 3 and waits[1] < waits[0] and waits[2] > waits[1], "speed cycles 2x, 3x, back to 1x (%s)" % str(waits))

	# Dive again: from town, straight back down
	main.state.return_scrolls = 1
	var _home := Town.use_return(main.state)
	main.refresh()
	check(main.state.in_town, "home for the dive-again check")
	main.dive_again()
	check(not main.state.in_town and main.state.floor_num == main.dive_again_floor(), "dive again leaves town at the last checkpoint")
	print("STAGE2 LIFECYCLE TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
