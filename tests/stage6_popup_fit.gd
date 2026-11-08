extends SceneTree
## QA r1 (screens): every popup opened on a 375 pt phone (the iPhone SE: 504 design px wide) fits
## the screen across. A popup is never wider than the viewport, so its Close is always reachable
## (the Wardrobe was 952 px, Auto-dive 569, Settings › Access 567, Snik with a full bag 942).
## Also: the phone top bar never makes the layout wider than the screen with a big bank (A1),
## the fall card stays inside the fight view and hides under popups (A2), one gold format (B1).
## godot --headless --path . -s tests/stage6_popup_fit.gd
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
var main

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _clear() -> void:
	for c in main.get_children():
		if c is Overlay:
			c.free()
	await process_frame

func _newest() -> Overlay:
	var o: Overlay = null
	for c in main.get_children():
		if c is Overlay and not c.is_queued_for_deletion():
			o = c
	return o

## Lays the newest popup out and checks its frame fits the viewport across (with the 12 px gutters).
func _fits(what: String) -> void:
	await process_frame
	await process_frame
	var o := _newest()
	if o == null:
		check(false, "%s opened a popup" % what)
		return
	var w: float = main.get_viewport().get_visible_rect().size.x
	var need: float = o.box.get_combined_minimum_size().x
	check(need <= w - 24.0 + 0.5, "%s fits a 375 pt phone (needs %.0f of %.0f px)%s" % [what, need, w - 24.0, "" if need <= w - 24.0 + 0.5 else _culprit(o.box)])
	await _clear()

## The widest thing inside (what to fix), for the failure line.
func _culprit(node: Control, depth := 0) -> String:
	var widest: Control = null
	for ch in node.get_children():
		if ch is Control and (ch as Control).visible:
			if widest == null or (ch as Control).get_combined_minimum_size().x > widest.get_combined_minimum_size().x:
				widest = ch
	if widest == null or depth > 16:
		return " [%s %s]" % [node.get_class(), String(node.get("text")).left(30) if node.get("text") != null else ""]
	return _culprit(widest, depth + 1)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	root.size = Vector2i(375, 667)
	# Headless never applies the window stretch: the game runs inside a viewport of the SE's
	# design size (504 wide, the SE's aspect), which is what every popup measures itself against
	var sv := SubViewport.new()
	sv.size = Vector2i(504, int(504.0 * 667.0 / 375.0))
	root.add_child(sv)
	TitleScreen.pending = {"play": 1}
	main = load("res://main.tscn").instantiate()
	sv.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
			main.play_slot(1)
			await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	await _clear()
	main.test_window = Vector2i(375, 667)   # the phone layout, where the window can't resize
	main._fit_layout()
	check(main.is_tall, "the phone layout is on")
	await process_frame
	var vw: float = main.get_viewport().get_visible_rect().size.x
	check(absf(vw - 504.0) < 1.0, "the test lays out at the phone's 504 design px (got %.0f)" % vw)
	main.ui_root.size = main.get_viewport().get_visible_rect().size
	var st: GameState = main.state
	st.in_town = false
	st.gold = 12345
	st.bank = 250000
	# a rich state: looks in the wardrobe, a full bag, Snik's wares
	for i in 30:
		var it: Dictionary = GameData.make_item(GameData.SLOT_ORDER[i % GameData.SLOT_ORDER.size()], i % 5, 120, 70000 + i)
		st.add_to_wardrobe(it)
		if not st.bag_full():
			st.bag.append(it)
	main.refresh()
	await process_frame

	# A1: the top bar fits with a big bank (the bank gives way, its tip still says it)
	main.ui_root.size = main.get_viewport().get_visible_rect().size
	await process_frame
	var need_x: float = main.ui_need().x
	check(need_x <= vw + 1.0, "the phone layout fits across with 250k in the bank (needs %.0f of %.0f)%s %s" % [need_x, vw, _culprit(main.ui_box), main.gold_label.text])
	check(String(main.gold_label.get_parent().tooltip_text).contains("250,000"), "the gold pill's tip names the bank with commas")

	# Every popup at 375 pt
	Wardrobe.new().show_for(main)
	await _fits("Wardrobe")
	AutoDivePanel.new().show_for(main)
	await _fits("Auto-dive settings")
	SkillsTab.auto_battle_popup(main)
	await _fits("Autoplay")
	var menu := SettingsMenu.new()
	menu.show_for(main)
	await process_frame
	var tabs: TabContainer = null
	for t in menu.content.find_children("*", "TabContainer", true, false):
		tabs = t
	if tabs:
		for i in tabs.get_tab_count():
			tabs.current_tab = i
			await process_frame
			var need: float = menu.box.get_combined_minimum_size().x
			check(need <= vw - 24.0 + 0.5, "Menu › %s fits (needs %.0f)%s" % [tabs.get_tab_title(i), need, "" if need <= vw - 23.5 else _culprit(menu.box)])
	await _clear()
	TownSelect.new().show_for(main, null)
	await _fits("Your towns")
	HeroSelect.new().show_for(main, null)
	await _fits("Heroes")
	FoundTown.new().show_for(main, 2)
	await _fits("Found a town")
	Smith.restock(st)
	st.merchant_who = ""
	if st.merchant.is_empty() and st.has_method("roll_merchant"):
		st.roll_merchant()
	MerchantPopup.new().show_for(main)
	await _fits("Snik with a full bag")
	TravelerPopup.new().show_for(main, {"kind": "traveler", "who": Travelers.pick()})
	await _fits("Traveler")
	CampPopup.new().show_for(main)
	await _fits("Camp")
	SuppliesPopup.new().show_for(main)
	await _fits("Supplies")
	StorePopup.new().show_for(main)
	await _fits("Store")
	LootFilter.new().show_for(main)
	await _fits("Loot filter")
	FloorPicker.new().show_for(main)
	await _fits("Floor picker")
	WhatsNew.new().show_for(main)
	await _fits("What's new")
	GuideBook.open_book(main, "")
	await _fits("Guide")
	main.wheel_tab.show_odds()
	await _fits("Wheel odds")

	# A2: the fall card stays inside the fight view and hides while a popup is open
	st.last_death = {"floor": st.floor_num, "enemy": "A Cave Troll", "woke": 101, "lost": "4,516 gold, 3 items",
		"taken": {"hits": 60, "burning": 40}, "total": 100, "enemy_left": 0.35, "tips": ["Drink a potion below half health."]}
	main._show_recap()
	await process_frame
	await process_frame
	await process_frame
	if is_instance_valid(main.recap_panel):
		var rp: PanelContainer = main.recap_panel
		check(rp.position.x >= 0.0 and rp.position.x + rp.size.x <= minf(main.battle.size.x, vw) + 1.0,
			"the fall card fits the fight view (x %.0f, w %.0f of %.0f)" % [rp.position.x, rp.size.x, minf(main.battle.size.x, vw)])
		SettingsMenu.new().show_for(main)
		await process_frame
		check(not rp.visible, "the fall card hides under the Menu")
		await _clear()
		await process_frame
		check(rp.visible, "the fall card comes back when the Menu closes")
		rp.queue_free()
	else:
		check(false, "the fall card showed")

	# B1: one gold format
	check(UI.short(250000) == "250k" and UI.short(124400) == "124.4k" and UI.short(1200000) == "1.2M", "UI.short drops a trailing .0")
	check(UI.gold(4743) == "4,743" and UI.gold(12345) == "12.3k" and UI.commas(124359) == "124,359", "UI.gold / UI.commas")
	check(UI.cost("Buy", 1899) == "Buy · 1,899 gold", "UI.cost unchanged")
	check(WheelTab._odds_amount("Scroll of Luck", "1 Scroll of Luck, kept for later") == "×1, kept for later", "wheel odds name a prize once")

	# A12: a tip too long for the fight's two-line strip shows in parts, never cut mid-sentence
	var long_tip := "The boss guards its hoard. Come back to it when you're stronger, or bring a friend: a party of three shares the fight and the countdown. Snik too, if he likes you."
	var parts: Array = main.battle._toast_split(long_tip)
	var font := UI.game_font()
	var two := 2.0 * font.get_height(UI.FONT_BODY) + 0.5
	check(parts.size() == 2 and font.get_multiline_string_size(parts[0], HORIZONTAL_ALIGNMENT_CENTER, main.battle.size.x - 40.0, UI.FONT_BODY).y <= two,
		"a long fight tip splits into a first part that fits two lines (%s)" % [parts])

	print("POPUP FIT DONE, failures: %d" % fails)
	main.get_parent().queue_free()
	await process_frame
	GameState.delete_saves()
	quit(1 if fails > 0 else 0)
