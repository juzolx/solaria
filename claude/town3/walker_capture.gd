extends SceneTree
## In-game capture of the town walkers (PixelLab heroes) at 430x932: frames for a GIF and a strip.
## godot --path . --resolution 430x932 -s claude/town3/walker_capture.gd   (needs a real window)
var main
var OUT := ProjectSettings.globalize_path("res://claude/town3/out/walkers_v2/frames/")   # or the first user arg (a folder under out/)

func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		OUT = ProjectSettings.globalize_path("res://claude/town3/out/%s/frames/" % OS.get_cmdline_user_args()[0])
	DirAccess.make_dir_recursive_absolute(OUT)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var prof := Profile.new()
	prof.save_epoch = Profile.SAVE_EPOCH
	prof.max_floor = 300
	prof.save()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"}
	g.hero_name = "Thorin"
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.best_floor = 60
	g.floor_num = 30
	g.gold = 9000
	g.stat_points = 5 * 29
	g.auto_spend()
	g.hero_hp = g.get_max_hp() / 2
	g.save_game()
	# A few more heroes in the roster (they walk around town too)
	var others := [[2, "Cleric", {"body": "fem", "skin": 3, "hair": "Long", "hair_color": 4, "eyes": 2, "race": "Elf"}, "Lysa"],
		[3, "Knight", {"body": "masc", "skin": 0, "hair": "Short", "hair_color": 8, "eyes": 1, "race": "Dwarf"}, "Brom"],
		[4, "Mage", {"body": "fem", "skin": 5, "hair": "Bun", "hair_color": 12, "eyes": 3, "race": "Human"}, "Ivi"]]
	for o in others:
		var h := GameState.new()
		h.slot = int(o[0])
		h.codex.path = ""
		h.appearance = o[2]
		h.hero_name = o[3]
		h.new_game()
		h.choose_class(o[1])
		h.level = 25
		h.equipped["Chest"] = GameData.make_item("Chest", 3, 30, 100 + int(o[0]))
		h.equipped["Helmet"] = GameData.make_item("Helmet", 2, 30, 200 + int(o[0]))
		h.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	await process_frame
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	var st: GameState = main.state
	st.codex.stats["guide_skip"] = 1
	st.codex.deeds = ["f25", "lv25", "k100"]
	# Pets: a hatched pet, a caught one and an egg (the Clinic and its pen appear)
	Menagerie.make_pet(st, "barghest", "barghest", 2, "egg")
	var hurt := Menagerie.make_pet(st, "will_o_wisp", "will_o_wisp", 1, "caught")
	hurt["hurt"] = 6
	st.eggs.append({"id": st._new_id(), "floors": 4, "from": "reward"})
	st.tips_seen["town"] = true
	main.go_to_town(true)
	main.refresh()
	for n in 3:
		await create_timer(0.5).timeout
		for c in main.get_children():
			if c is Overlay or c is Moments:
				c.queue_free()
	var tv = main.town_view
	print("town walkers: ", tv.folk.size(), " heroes: ", tv.folk.filter(func(f): return f.get("hero", false)).size())
	# bring a few walkers into the market view so the GIF shows them up close
	var cells: Array = tv.walk.keys().filter(func(c): return c.x >= 15 and c.x <= 24 and c.y >= 13 and c.y <= 24)
	for k in tv.folk.size():
		var f: Dictionary = tv.folk[k]
		var c: Vector2i = cells[(k * 7) % cells.size()]
		var p: Vector2 = tv._cell_px(c)
		f["x"] = p.x; f["y"] = p.y; f["cell"] = c; f["path"] = []; f["inside"] = 0.0; f["fade"] = 0.0
		f["wait"] = 0.2 + 0.15 * k
	for i in 60:
		await create_timer(0.1).timeout
		root.get_texture().get_image().save_png(OUT + "f%03d.png" % i)
	tv._zoom_to(3.0, tv.size / 2.0)
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(OUT + "zoom3.png")
	# the hope path: two walkers on the stairs, the view on the dungeon
	tv._zoom_to(2.0, tv.size / 2.0)
	var gate: Rect2 = tv._spot_rect("gate")
	tv.pan_v = tv.size / 2.0 - gate.get_center() * tv.scale_f
	tv._layout()
	var hope: Array = tv.raised.keys()
	hope.sort_custom(func(a, b): return a.y > b.y)
	for k in 2:
		var f: Dictionary = tv.folk[k]
		var c0: Vector2i = hope[k * 2]
		var p0: Vector2 = tv._cell_px(c0)
		f["x"] = p0.x; f["y"] = p0.y; f["cell"] = c0; f["inside"] = 0.0; f["fade"] = 0.0; f["wait"] = 0.0
		f["path"] = tv._grid_path(c0, hope[-1])
	for i in 24:
		await create_timer(0.1).timeout
		root.get_texture().get_image().save_png(OUT + "d%03d.png" % i)
	# pan far into a corner: the view stops at the town's edge (no void)
	tv.pan_v = Vector2(4000, 4000)
	tv._layout()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(OUT + "corner.png")
	print("CAPTURE DONE")
	quit()
