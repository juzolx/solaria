extends SceneTree
## Screenshots every screen at phone size into shots/tour (a fresh test hero, never real saves).
## godot --path . --resolution 430x932 -s tests/ui_tour.gd
const TestHero := preload("res://tests/test_hero.gd")

var out := ""
var n := 0

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
				print("SCREEN TOO WIDE: %s needs %.0f px of %.0f%s" % [label, need, screen_w, _culprit(c.get("ui_root"), screen_w)])
			var tall: float = (c.get("ui_root") as Control).get_combined_minimum_size().y
			if tall > root.get_visible_rect().size.y + 1.0:
				print("SCREEN TOO TALL: %s needs %.0f px of %.0f (the bottom bar is pushed off)" % [label, tall, root.get_visible_rect().size.y])
	for c in root.get_children():
		for o in c.get_children():
			if o is Overlay and o.box != null and o.box.size.x > screen_w + 1.0:
				print("TOO WIDE: %s (%.0f px on a %.0f px screen)" % [label, o.box.size.x, screen_w])

## The deepest visible control that is wider than the screen (what to fix).
func _culprit(n: Control, w: float) -> String:
	for ch in n.get_children():
		if ch is Control and (ch as Control).is_visible_in_tree() and (ch as Control).get_combined_minimum_size().x > w - 12.0:
			return _culprit(ch, w)
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

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	out = TestHero.shots_dir("tour")
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
	await shot("first_popup")  # whatever opened during the first turns (guide book, tips)
	await close_popups(main)
	await shot("fight")
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
	print("TOUR DONE: %d screens in %s" % [n, out])
	quit()
