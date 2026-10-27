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
			if c is TextureRect and c.has_meta("hero_pic") and c.is_visible_in_tree():
				_check_seat(label, c as TextureRect)
			# Fable r5 #4: a grey button whose reason only shows on hover says nothing on a phone (use UI.why)
			if c is Button and c.is_visible_in_tree() and (c as Button).disabled and c.tooltip_text != "":
				fail("MUTE BUTTON: %s \"%s\" hides \"%s\" in a hover tooltip [%s]" % [label, String(c.get("text")).left(24).replace("\n", " "), c.tooltip_text.left(30), _path(c)])
			# Fable r5 #2: a list squeezed under one row while it has more to show
			if c is ScrollContainer and c.is_visible_in_tree() and c.get_child_count() > 0 and c.size.y > 0.0 and c.size.y < ItemGrid.CELL:
				var inner := c.get_child(0) as Control
				if inner and inner.get_combined_minimum_size().y > c.size.y + 1.0:
					fail("SQUEEZED LIST: %s list is %.0f px tall (one row is %d) [%s]" % [label, c.size.y, ItemGrid.CELL, _path(c)])
			# Fable r5 #9: a chip strip that wraps one chip onto a row of its own
			if c is HFlowContainer and c.is_visible_in_tree() and c.get_child_count() >= 3 and c.get_child_count() <= 8 and c.get_children().all(func(k): return k is Button):
				var ys := {}
				for k in c.get_children():
					if k is Control and (k as Control).visible:
						ys[(k as Control).position.y] = int(ys.get((k as Control).position.y, 0)) + 1
				if ys.size() > 1 and int(ys[ys.keys().max()]) == 1:
					fail("ORPHAN CHIP: %s strip leaves one chip on its last row [%s]" % [label, _path(c)])
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
				# Fable r4 #14: a Button whose text runs past its face with no "..."
				if c is Button and (c as Button).clip_text and (c as Button).text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and c.size.x > 0.0:
					var sb := c.get_theme_stylebox("normal")
					var room := c.size.x - (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT) if sb else 0.0)
					var bi: Texture2D = (c as Button).icon
					if bi and (c as Button).icon_alignment != HORIZONTAL_ALIGNMENT_CENTER:   # a centred icon sits above the words
						room -= bi.get_width() + c.get_theme_constant("h_separation")
					for line in (c as Button).text.split("\n"):
						if c.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room + 2.0:
							fail("CLIPPED TEXT: %s button \"%s\" is cut at %.0f px [%s]" % [label, line.left(24), room, _path(c)])
							break
				# Fable r4 #2: every word in Pixelify (a Control outside the themed tree fell back to Godot's sans)
				if not _pixel(c.get_theme_font("font")):
					fail("WRONG FONT: %s \"%s\" [%s]" % [label, String(c.get("text")).left(24).replace("\n", " "), _path(c)])
			elif c is RichTextLabel and c.is_visible_in_tree() and (c as RichTextLabel).text != "":
				var rs := c.get_theme_font_size("normal_font_size")
				if rs < UI.MIN_FONT:
					fail("SMALL FONT: %s rich text is %d px (floor %d) [%s]" % [label, rs, UI.MIN_FONT, _path(c)])
				if not _pixel(c.get_theme_font("normal_font")):
					fail("WRONG FONT: %s rich text [%s]" % [label, _path(c)])
		check_floors(label, ch)

## Juzo (r5 follow-up): a hero on a plinth stands in its shadow. The boots' bottom edge (the last
## opaque row of the portrait in its middle columns, measured, not assumed) must sit on the shadow's
## centre line within 1 screen px, and the whole shadow must show: on screen, inside every clipping
## parent, and under no text.
func _check_seat(label: String, pl: TextureRect) -> void:
	var pic := pl.get_meta("hero_pic") as TextureRect
	if pic == null or not is_instance_valid(pic) or pic.texture == null:
		return
	var img := pic.texture.get_image()
	var low := -1
	for y in img.get_height():
		for x in range(img.get_width() / 2 - 12, img.get_width() / 2 + 12):
			if img.get_pixel(x, y).a > 0.5:
				low = y
	var k := pic.get_global_rect().size.y / float(img.get_height())
	var boots := pic.get_global_rect().position.y + (low + 1) * k
	var shadow := pl.get_global_rect()
	var mid := shadow.position.y + shadow.size.y / 2.0
	var px := 1.0 / maxf(0.01, root.get_final_transform().get_scale().y)   # one screen px in design px
	if absf(boots - mid) > px + 0.01:
		fail("FLOATING HERO: %s boots end at %.0f, the shadow's centre is %.0f [%s]" % [label, boots, mid, _path(pic)])
	# (a list scrolled past the hero is fine; the bug is a hero in view whose shadow is cut)
	var seen := _shown_rect(pic)
	if seen.size.y < pic.get_global_rect().size.y - 0.5:
		return
	if _shown_rect(pl).size.y < shadow.size.y - 0.5 or _shown_rect(pl).size.x < shadow.size.x - 0.5:
		fail("CUT SHADOW: %s the hero shows but their shadow is cut [%s]" % [label, _path(pl)])
		return
	for t in root.find_children("*", "Control", true, false):
		var tc := t as Control
		if tc == pic or tc == pl or not tc.is_visible_in_tree() or not (tc is Label or tc is RichTextLabel or tc is Button):
			continue
		if String(tc.get("text")).strip_edges() == "":
			continue
		var tr := _shown_rect(tc)   # text scrolled out of sight under a pinned stage doesn't count
		if tc.is_ancestor_of(pl) or tr.size.x <= 0.0 or tr.size.y <= 0.0:
			continue
		if tr.intersects(shadow.grow(-1.0)) and tc.get_parent() != pl.get_parent():
			fail("CUT SHADOW: %s \"%s\" sits on the hero's shadow [%s]" % [label, String(tc.get("text")).left(24).replace("\n", " "), _path(tc)])
			return

## The part of c on screen: its rect cut by the screen and every clipping parent.
func _shown_rect(c: Control) -> Rect2:
	var r := c.get_global_rect().intersection(root.get_visible_rect())
	var p := c.get_parent()
	while p is Control:
		if (p as Control).clip_contents:
			r = r.intersection((p as Control).get_global_rect())
		p = p.get_parent()
	return r

func _pixel(f: Font) -> bool:
	if f == null:
		return false
	if f == UI.game_font():
		return true
	var base: Font = (f as FontVariation).base_font if f is FontVariation else f
	return base != null and base.resource_path.contains("Pixelify")

## Fable r4 #1: tap a control the way a finger does and fail when no tip appears (UI.force_touch
## lets the PC's mouse click count as a tap); the tip is then shot and font-checked like any screen.
func touch_check(where: String, c: Control) -> void:
	if c == null:
		fail("NO TIP: %s has nothing with a tap-tip" % where)
		return
	UI.force_touch = true
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = c.size / 2.0
	c.gui_input.emit(ev)
	await create_timer(0.3).timeout
	var tl := UI.tip_layer
	if tl == null or tl.get_child_count() == 0:
		fail("NO TIP: a tap on %s (%s) showed nothing" % [where, _path(c)])
		return
	var p := tl.get_child(tl.get_child_count() - 1) as Control
	# Fable r5 #3: a tip that only repeats the words you tapped teaches that taps do nothing
	var said := ""
	for k in p.find_children("*", "RichTextLabel", true, false):
		said = (k as RichTextLabel).get_parsed_text()
	if c.get("text") != null and said.strip_edges() == String(c.get("text")).strip_edges():
		fail("ECHO TIP: tapping %s only repeats \"%s\"" % [where, said.left(30)])
	if not root.get_visible_rect().encloses(p.get_global_rect()):
		fail("TIP OFF SCREEN: %s at %s" % [where, p.get_global_rect()])
	await shot("tip_" + where)
	if is_instance_valid(p):
		p.queue_free()
	await process_frame

## The first visible non-button with a tap-tip on screen (whose tip holds `has`).
func _find_tip(n: Node, has := "") -> Control:
	for ch in n.get_children():
		if ch is CanvasItem and not (ch as CanvasItem).visible:
			continue
		if ch is Control and not (ch is BaseButton) and (ch as Control).is_visible_in_tree() and (ch as Control).tooltip_text != "" and (ch as Control).gui_input.get_connections().size() > 0 and (ch as Control).tooltip_text.contains(has):
			return ch
		var r := _find_tip(ch, has)
		if r != null:
			return r
	return null

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
		if c.get("ui_box") is Control:   # (the screen itself never grows: ui_need() is what it asks for)
			var need: float = c.ui_need().x
			if need > screen_w + 1.0:
				fail("SCREEN TOO WIDE: %s needs %.0f px of %.0f%s" % [label, need, screen_w, _culprit(c.get("ui_box"), screen_w)])
			var tall: float = c.ui_need().y
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
	# the game never draws the fight under the title (it reloads the scene); both drawing at
	# once pass the shared 3D room back and forth every frame and crash the engine
	main.ui_root.visible = false
	var ts := TitleScreen.new()
	ts.show_for(main)
	await shot("title")
	ts.queue_free()
	await process_frame
	main.ui_root.visible = true
	await process_frame
	Onboarding.show_welcome(main)
	await shot("welcome")
	await close_popups(main)
	var coach := Onboarding.coach(main, "Your hero fights on their own. Tap [color=#e8b14a]Hero[/color] to spend points when you level up.")
	await shot("coach")
	if is_instance_valid(coach):
		coach.queue_free()
	var cc := CharacterCreator.new()
	cc.show_for(main, main.state.appearance, func(_a): pass)
	await shot("creator")
	cc.scroll.scroll_vertical = 99999   # Fable r4 #7: the rows under the race card (Hair colour, Fur, Eyes, Face)
	await shot("creator_bottom")
	# Fable r5 #1: the hero stays in view while you pick the rows at the bottom
	if not (cc.preview.is_visible_in_tree() and root.get_visible_rect().encloses(cc.preview.get_global_rect())):
		fail("PREVIEW GONE: the creator's hero scrolled out of view")
	await close_popups(main)
	HeroSelect.new().show_for(main, null)
	await shot("hero_select")
	await close_popups(main)
	main.state.last_death = {"floor": main.state.floor_num, "enemy": "A Cave Troll", "woke": 26, "lost": "4,516 gold, 3 items",
		"taken": {"hit": 60, "fire": 40}, "total": 100, "enemy_left": 0.35, "tips": ["Drink a potion below half health (Auto-potion in Hero › Skills)."]}
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
	var mo := Moments.play(main, "boss", "Cave Troll", "Floor 25 is clear", UI.GOLD)
	await shot("moment")
	mo.close()   # its own fade (freeing it mid-tween leaves a lambda pointing at a freed label)
	await create_timer(0.5).timeout
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
	# Fable r4 #3: the goal line ends where it should (no "..." over the place to go)
	var gl: Label = main.goal_label
	if gl.is_visible_in_tree() and gl.get_theme_font("font").get_string_size(gl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, gl.get_theme_font_size("font_size")).x > gl.size.x + 1.0:
		fail("GOAL CUT: \"%s\" needs more than %.0f px" % [gl.text, gl.size.x])
	await touch_check("goal_line", gl)
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
			# Fable r4 #1: a stat tile ("Strength: ...") and a heading (Your party) answer a tap
			var tap_at := {"character_Hero": ": ", "character_Party": "Take a team"}
			var tk := "%s_%s" % [group_names[g], grp.get_tab_title(s)]
			if tap_at.has(tk):
				await touch_check(tk.to_lower(), _find_tip(grp.get_current_tab_control(), tap_at[tk]))
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
