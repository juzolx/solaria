extends SceneTree
## Pets on screen at phone size (Fable pets R1): the companion and three menagerie pets in a
## fight and in the room, Codex > Pets, the card a tap opens, the Pet tab.
##   godot --path . --resolution 430x932 --position 3000,3000 -s tests/_pets_shot.gd -- [out dir under res://]
const TestHero := preload("res://tests/test_hero.gd")

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var out := ProjectSettings.globalize_path("res://" + (args[0] if args.size() > 0 else "claude/art_test/pets/fable_r2"))
	DirAccess.make_dir_recursive_absolute(out)
	TestHero.make(12, "Knight")
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	var st: GameState = main.state
	st.in_town = false
	st.level = maxi(st.level, World.PET_LEVEL)
	st.pet_on = true
	st.hidden_class = "beast_tamer"   # three pets out
	st.pets.clear()
	st.pets_out.clear()
	for e in [["banshee", 5], ["will_o_wisp", 2], ["pale_stag", 3]]:
		var sp: String = e[0]
		var p := Menagerie.make_pet(st, sp, String(Monsters.by_id(sp).get("art", sp)), int(e[1]), "test")
		p["cherished"] = sp == "banshee"
	st.events.clear()   # no first-find fanfare over the shots
	await _close(main)
	main.nav_page = 0
	main._apply_nav()
	main.refresh()
	await create_timer(1.5).timeout
	await _shot(out, "fight")
	var bv = main.battle
	print("LAYOUT (design units) size ", bv.size, " scale ", PixelPic.stretch(bv), " u ", bv._u(), " lay ", bv.team_layout(), " bar ", bv._bar_rect(bv._hero_rect()), " hero ", bv._hero_rect(), " ground ", bv._team_ground())
	st.exploring = true
	main._room_ready = true
	main.refresh()
	await create_timer(1.0).timeout
	await _close(main)
	await _shot(out, "room")
	st.exploring = false
	for gi in main._groups().size():
		var grp: TabContainer = main._groups()[gi]
		for s in grp.get_tab_count():
			var title := grp.get_tab_title(s)
			if title != "Pets" and title != "Pet":
				continue
			main.show_tab(gi, s)
			main.refresh()
			await create_timer(0.4).timeout
			await _shot(out, "tab_%d_%s" % [gi, title.to_lower()])
			_check_pixels(grp.get_child(s))
			var page = grp.get_child(s)
			if page is PetBookTab:
				var flow := _find_flow(page)
				if flow != null:
					page.scroll_vertical = int(flow.get_global_rect().position.y - page.get_global_rect().position.y) - 40
					await create_timer(0.3).timeout
					await _shot(out, "codex_pets_cells")
				page._show("banshee", true, 5)
				await create_timer(0.4).timeout
				await _shot(out, "codex_pets_card")
				await _close(main)
	print("PETS SHOTS DONE ", Menagerie.out(st).size())
	quit()

## Every pet picture on a tab shows whole screen pixels per art pixel (Fable pets R2).
func _check_pixels(n: Node) -> void:
	for c in n.get_children():
		if c is PixelPic and c.is_visible_in_tree():
			var px: float = c.size.x * PixelPic.stretch(c) / c.art_px
			print(("PIXELS OK " if absf(px - roundf(px)) < 0.02 else "PIXELS FAIL ") + "%.2f screen px per art px" % px)
		_check_pixels(c)

func _find_flow(n: Node) -> HFlowContainer:
	for c in n.get_children():
		if c is HFlowContainer:
			return c
		var f := _find_flow(c)
		if f != null:
			return f
	return null

func _close(main) -> void:
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await process_frame

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
