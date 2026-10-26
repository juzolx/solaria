extends SceneTree
## Screenshots every screen at phone size into shots/tour (a fresh test hero, never real saves).
## godot --path . --resolution 430x932 -s tests/ui_tour.gd   (add "-- se" for the 375x667 run: shots/tour_se)
## A gate since Fable r2 #18: overflow, a visible button shorter than UI.BUTTON_H, or text under
## UI.MIN_FONT prints a "TOUR FAIL" line and the tour exits 1 (tools/check.sh shots runs both sizes).
const TestHero := preload("res://tests/test_hero.gd")

var out := ""
var n := 0
var fails := 0
var seen_fail := {}   # one line per problem, not one per shot

func fail(text: String) -> void:
	if seen_fail.has(text):
		return
	seen_fail[text] = true
	fails += 1
	print("TOUR FAIL: " + text)

## Every visible button at least BUTTON_H tall, every label at least MIN_FONT.
func check_floors(label: String, node: Node) -> void:
	for ch in node.get_children():
		if ch is CanvasItem and not (ch as CanvasItem).visible:
			continue
		if ch is Control:
			var c := ch as Control
			if c is Button and c.is_visible_in_tree() and c.size.y > 0.0 and c.size.y < UI.BUTTON_H - 1.0 and not c.has_meta("tour_small_ok"):
				fail("SHORT BUTTON: %s \"%s\" is %.0f px (floor %d) [%s]" % [label, String(c.get("text")).left(24).replace("\n", " "), c.size.y, UI.BUTTON_H, _path(c)])
			if (c is Label or c is Button) and c.is_visible_in_tree() and String(c.get("text")) != "":
				var fs := c.get_theme_font_size("font_size")
				if fs < UI.MIN_FONT:
					fail("SMALL FONT: %s \"%s\" is %d px (floor %d) [%s]" % [label, String(c.get("text")).left(24).replace("\n", " "), fs, UI.MIN_FONT, _path(c)])
				# Fable r3 #15: a one-line Label cut at its edge with no "..." (clip_text hides it from the overflow check)
				if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF and (c as Label).text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and c.size.x > 0.0:
					var font := c.get_theme_font("font")
					for line in (c as Label).text.split("\n"):
						if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > c.size.x + 2.0:
							fail("CLIPPED TEXT: %s \"%s\" is cut at %.0f px [%s]" % [label, line.left(24), c.size.x, _path(c)])
							break
			elif c is RichTextLabel and c.is_visible_in_tree() and (c as RichTextLabel).text != "":
				var rs := c.get_theme_font_size("normal_font_size")
				if rs < UI.MIN_FONT:
					fail("SMALL FONT: %s rich text is %d px (floor %d) [%s]" % [label, rs, UI.MIN_FONT, _path(c)])
		check_floors(label, ch)

func _path(c: Node) -> String:
	var bits := []
	var p := c
	for i in 3:
		if p == null:
			break
		bits.push_front(String(p.name) if not String(p.name).begins_with("@") else p.get_class())
		p = p.get_parent()
	return "/".join(bits)

func shot(label: String) -> void:
	await create_timer(0.6).timeout
	n += 1
	var path := "%s/%02d_%s.png" % [out, n, label.to_lower().replace(" ", "_").replace("(", "").replace(")", "")]
	root.get_texture().get_image().save_png(path)
	# Flag any popup or screen that runs off a phone-width screen
	var screen_w := root.get_visible_rect().size.x
	for c in root.get_children():
		if c.get("ui_root") is Control:
			var need: float = (c.get("ui_root") as Control).get_combined_minimum_size().x
			if need > screen_w + 1.0:
				fail("SCREEN TOO WIDE: %s needs %.0f px of %.0f%s" % [label, need, screen_w, _culprit(c.get("ui_root"), screen_w)])
			var tall: float = (c.get("ui_root") as Control).get_combined_minimum_size().y
			if tall > root.get_visible_rect().size.y + 1.0:
				fail("SCREEN TOO TALL: %s needs %.0f px of %.0f (the bottom bar is pushed off)" % [label, tall, root.get_visible_rect().size.y])
	for c in root.get_children():
		for o in c.get_children():
			if o is Overlay and o.box != null and o.box.size.x > screen_w + 1.0:
				fail("TOO WIDE: %s (%.0f px on a %.0f px screen)%s" % [label, o.box.size.x, screen_w, _culprit(o.box, screen_w - 40.0)])
	check_floors(label, root)

## The deepest visible control that is wider than the screen (what to fix).
func _culprit(n: Control, w: float, depth := 0) -> String:
	var widest: Control = null
	for ch in n.get_children():
		if ch is Control and (ch as Control).is_visible_in_tree():
			if widest == null or (ch as Control).get_combined_minimum_size().x > widest.get_combined_minimum_size().x:
				widest = ch
	if widest != null and depth < 12 and (widest.get_combined_minimum_size().x > w - 40.0 or widest.get_child_count() > 0) and not (widest is Label or widest is Button):
		return _culprit(widest, w, depth + 1)
	var bits := []
	for ch in n.get_children():
		if ch is Control:
			bits.append("%s%s=%.0f" % [ch.get_class(), (" \"%s\"" % String(ch.get("text")).left(20)) if ch.get("text") != null else "", (ch as Control).get_combined_minimum_size().x])
	return " (widest: %s [%s])" % [n.get_class(), ", ".join(bits)]

func close_popups(main: Node) -> void:
	main.moment_queue.clear()
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

## Fable r3 #6: what a new player sees in the first session, one picture each.
func _first_session(main) -> void:
	var ts := TitleScreen.new()
	ts.show_for(main)
	await shot("title")
	ts.queue_free()
	await process_frame
	Onboarding.show_welcome(main)
	await shot("welcome")
	await close_popups(main)
	var coach := Onboarding.coach(main, "Your hero fights on their own. Tap [color=#e8b14a]Hero[/color] to spend points when you level up.")
	await shot("coach")
	if is_instance_valid(coach):
		coach.queue_free()
	CharacterCreator.new().show_for(main, main.state.appearance, func(_a): pass)
	await shot("creator")
	await close_popups(main)
	HeroSelect.new().show_for(main, null)
	await shot("hero_select")
	await close_popups(main)
	main.state.last_death = {"floor": main.state.floor_num, "enemy": "A Cave Troll", "woke": 26, "lost": "gold",
		"taken": {"hit": 60, "fire": 40}, "total": 100, "enemy_left": 0.35, "tips": ["Drink a potion below half health (Auto-potion in Hero › Skills)."]}
	main._show_recap()
	await shot("death_card")
	if is_instance_valid(main.recap_panel):
		main.recap_panel.queue_free()
	var o := Overlay.new().open(main, "Your hero has fallen", 520.0, UI.RED, false)
	DeathScreen.hardcore(o.content, "Thorin", 30, "Human", "Warrior", 30, true, 30, func(): pass, func(): pass)
	await shot("death_hardcore")
	await close_popups(main)
	CreditsScreen.new().show_for(main)
	await shot("credits")
	await close_popups(main)
	GuideBook.open_book(main, "")
	await shot("guide_book")
	await close_popups(main)
	Moments.play(main, "boss", "Cave Troll", "Floor 25 is clear", UI.GOLD)
	await shot("moment")
	await close_popups(main)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	out = TestHero.shots_dir("tour_se" if "se" in OS.get_cmdline_user_args() else "tour")
	for f in DirAccess.get_files_at(out):
		DirAccess.remove_absolute(out.path_join(f))
	seed(7)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	await close_popups(main)
	for i in 4:
		main._on_tick()
		await create_timer(0.2).timeout
	await close_popups(main)
	await shot("fight")
	await _first_session(main)
	var group_names := ["character", "items", "town", "codex", "online"]
	for g in [0, 1, 3, 4]:
		var grp: TabContainer = main._groups()[g]
		for s in grp.get_tab_count():
			if grp.is_tab_hidden(s):
				continue
			main.show_tab(g, s)
			main.refresh()
			await shot("%s_%s" % [group_names[g], grp.get_tab_title(s)])
			if g == 1 and s == 1 and not main.state.bag.is_empty():
				ItemPopup.show_item(main, main.state.bag[0])
				await shot("item_popup")
				await close_popups(main)
	main.nav_page = 0
	main._apply_nav()
	var menu = SettingsMenu.new()
	menu.show_for(main)
	await shot("menu")
	menu.queue_free()
	await process_frame
	if not main.state.in_town:
		# a fresh hero stands mid-floor, so read a Return Scroll to get home
		# (with a little dive behind it, for the "Made it home" card)
		Town.start_dive(main.state)
		main.state.gold += 480
		main.state.codex.add("kills", 9)
		main.state.return_scrolls = maxi(main.state.return_scrolls, 1)
		var _home := Town.use_return(main.state)
	if main.go_to_town(true):
		main.nav_page = 0
		main._apply_nav()
		main.refresh()
		await create_timer(0.8).timeout
		await shot("home_tally")
		await close_popups(main)
		await create_timer(0.4).timeout
		await shot("town_map")
		# the Map overlay over the town (interface pass, approved mockup 10)
		TownMap.open_for(main, main.town_view.hidden_spots, main.town_view.locked, main._on_building)
		await create_timer(0.3).timeout
		await shot("town_map_overlay")
		await close_popups(main)
		var tg: TabContainer = main._groups()[2]
		for s in tg.get_tab_count():
			if tg.is_tab_hidden(s):
				continue
			main.show_tab(2, s)
			main.refresh()
			await close_popups(main)
			await shot("town_%s" % tg.get_tab_title(s))
		main._choose_floor()
		await shot("floor_picker")
	print("TOUR DONE: %d screens in %s, %d problem%s" % [n, out, fails, "" if fails == 1 else "s"])
	quit(1 if fails > 0 else 0)
