extends SceneTree
## QA screenshots the tour misses: pets (new art), jewelry worn, daily reward,
## welcome, What's New, a Regular death recap and the Hardcore fallen card.
## godot --path . --resolution 430x932 -s tests/_qa_shots.gd
const TestHero := preload("res://tests/test_hero.gd")
var out := ""
var n := 0

func shot(label: String) -> void:
	await create_timer(0.7).timeout
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, label])
	var w := root.get_visible_rect().size
	for c in root.get_children():
		for o in c.get_children():
			if o is Overlay and o.box != null and (o.box.size.x > w.x + 1.0 or o.box.size.y > w.y + 1.0):
				print("QA TOO BIG: %s %s on %s" % [label, o.box.size, w])

func close_popups(m) -> void:
	m.moment_queue.clear()
	for c in m.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	out = TestHero.shots_dir("qa")
	for f in DirAccess.get_files_at(out):
		DirAccess.remove_absolute(out.path_join(f))
	seed(3)
	# Welcome for a brand-new player
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	LoadingScreen.enabled = false
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.5).timeout
	await shot("welcome")
	m.queue_free()
	await process_frame
	# What's New for a returning player
	TestHero.make(60)
	var p := Profile.load_profile()
	p.whats_new_seen = ""
	p.save()
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.5).timeout
	await shot("whats_new")
	m.queue_free()
	await process_frame
	# Daily reward on load
	TestHero.make(60)
	var cx := Codex.load_codex()
	cx.login = {}
	cx.save()
	TitleScreen.pending = {"play": 1}
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.5).timeout
	await shot("daily_reward")
	await close_popups(m)
	m.timer.stop()
	var st: GameState = m.state
	# Pets of several kinds, and jewelry worn
	for zi in [0, 3, 7]:
		Menagerie.give_egg(st, "nest", zi, 3)
	while not st.eggs.is_empty():
		var pet := Menagerie.hatch(st, st.eggs.pop_back())
		if not pet.is_empty() and not st.pets.has(pet):
			st.pets.append(pet)
	if not st.pets.is_empty() and "active_pet" in st:
		st.active_pet = int(st.pets[0].get("id", 0))
	for slot in GameData.SLOT_ORDER:
		var it: Dictionary = GameData.make_item(slot, 3, 60, st._new_id())
		st.bag.append(it)
		st.equip(int(it["id"]))
	var cur: Dictionary = GameData.make_item("Weapon", 4, 60, st._new_id())
	Church.curse(cur)
	st.bag.append(cur)
	m.refresh()
	m.show_tab(0, 5)
	m.refresh()
	await shot("pets_tab")
	m.show_tab(1, 0)
	m.refresh()
	await shot("gear_jewelry")
	m.show_tab(1, 1)
	m.refresh()
	await shot("bag_cursed")
	m.nav_page = 0
	m._apply_nav()
	m.refresh()
	for i in 6:
		st.take_turn()
		m.refresh()
		await create_timer(0.15).timeout
	await shot("fight_with_pet")
	# Regular death
	st.party = null
	st.hero_hp = 0
	st._hero_died()
	m._handle_events()
	m.refresh()
	await shot("regular_death")
	await close_popups(m)
	m.queue_free()
	await process_frame
	# Hardcore fallen card
	TestHero.make(40)
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.load_game()
	g.hardcore = true
	g.save_game()
	TitleScreen.pending = {"play": 1}
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.4).timeout
	await close_popups(m)
	m.timer.stop()
	m.state.hardcore = true
	m.state.hero_hp = 0
	m.state._hero_died()
	m._handle_events()
	m.refresh()
	await shot("hardcore_fallen")
	print("QA SHOTS DONE: %d in %s" % [n, out])
	m.queue_free()
	await process_frame
	GameState.delete_saves()
	quit()
