extends SceneTree
## QA (Oct 24): every Town page fits a phone screen top to bottom. The 2.1 building
## bar sits over every building page, and the Tavern's wheel then pushed the bottom
## navigation off the screen. Checks the whole interface's minimum height.
## godot --headless --path . -s tests/stage6_fit_height.gd
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
	TestHero.make(30)
	root.size = Vector2i(430, 932)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	# Headless windows can't be resized: lay the interface out at an iPhone's 430x932
	# by hand (the phone design width, 504, and the height that aspect gives).
	var phone := Vector2(main.PORTRAIT_DESIGN.x, main.PORTRAIT_DESIGN.x * 932.0 / 430.0)
	main.is_tall = true
	main.body.vertical = true
	main.wheel_tab.vertical = true
	main.ui_root.size = phone
	await process_frame
	main.state.in_town = true
	main.nav_page = 3
	main._apply_nav()
	var tg: TabContainer = main._groups()[2]
	var screen_h: float = phone.y
	for s in tg.get_tab_count():
		main.show_tab(2, s)
		main.refresh()
		await process_frame
		main.ui_root.size = phone
		await process_frame
		var need: float = main.ui_need().y
		check(need <= screen_h + 1.0, "%s fits the phone screen (needs %.0f of %.0f px)" % [tg.get_tab_title(s), need, screen_h])
	# The wheel keeps its win line off the rim, at readable size
	check(main.wheel_tab.wheel.custom_minimum_size.y <= 180.0 and main.wheel_tab.wheel.size_flags_vertical & Control.SIZE_EXPAND, "the wheel is smaller on phones and grows into spare room")
	# Small text fixes from the same QA pass
	check(BestiaryTab.a_slot("Off Hand") == "An off hand" and BestiaryTab.a_slot("Helmet") == "A helmet", "a/an before a slot name")
	var card := Collections.track_card(main.codex, "slots")
	var title: Label = card.get_child(0).get_child(0).get_child(0)
	check(not title.clip_text and title.autowrap_mode != TextServer.AUTOWRAP_OFF, "collection card titles wrap instead of being cut off")
	card.free()
	var dg: GridContainer = main.daily_grid()
	check(dg.columns == 4, "the daily reward days take two rows on a phone (%d columns)" % dg.columns)
	dg.free()
	# The guide's "When you fall" page matches the grave rules (and the death tip)
	var page := {}
	for pg in Guide.PAGES:
		if pg["id"] == "death":
			page = pg
	var t := String(page.get("text", ""))
	check(t.contains("guarded") and t.contains("Half the gold") and not t.contains("costs everything"), "the death guide page describes the grave, not the old total loss")
	main.queue_free()
	await process_frame
	GameState.delete_saves()
	print("STAGE6 FIT HEIGHT TESTS DONE, failures: ", fails)
	quit()
