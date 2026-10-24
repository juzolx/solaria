extends SceneTree
## QA walk-through: a brand-new player through the real main screen, with every
## new 2.1 system running together. Prints "QA:" lines; errors show as ERROR lines.
## godot --headless --path . -s tests/_qa_play.gd [-- hc]
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
var main
var went_home := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func overlays(m) -> Array:
	return m.get_children().filter(func(c): return c is Overlay)

func close_popups(m) -> void:
	m.moment_queue.clear()
	for c in m.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

## Every tab of every group, rebuilt with the current state.
func tour_tabs(m, label: String) -> void:
	for g in m._groups().size():
		var grp: TabContainer = m._groups()[g]
		for s in grp.get_tab_count():
			if grp.is_tab_hidden(s):
				continue
			m.show_tab(g, s)
			m.refresh()
			await process_frame
	await close_popups(m)
	print("QA: toured tabs (%s)" % label)

func ticks(m, n: int) -> void:
	for i in n:
		if m.state.in_town:
			went_home += 1
			await close_popups(m)
			m.dive_again()
		if m.state.hardcore:
			m.state.hero_hp = m.state.get_max_hp()  # keep the one life until the death step
		m._on_tick()
		if i % 100 == 0:
			var s: GameState = m.state
			print("QA tick %d: floor=%d fight=%d auto=%s expl=%s wait=%d offer=%s ehp=%d busy=%s cal=%s town=%s rule=%s lvl=%d pts=%d pots=%d hp=%d/%d gear=%d" % [i, s.floor_num, s.fight, s.autoplay, s.exploring, s.explore_wait, s.path_offer, s.enemy_hp, m.battle.busy(), s.calamity_pending, s.in_town, AutoRules.check(s), s.level, s.stat_points, s.potions, s.hero_hp, s.get_max_hp(), s.equipped.size()])
		if i % 50 == 0:
			m.state.auto_stats = true
			m.state.auto_spend()
			m.state.equip_best()
		if i % 10 == 0:
			await process_frame
			await close_popups(m)

func new_main(pending: Dictionary):
	if main != null:
		main.queue_free()
		await process_frame
	TitleScreen.pending = pending
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var hc := OS.get_cmdline_user_args().has("hc")
	seed(11)
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	LoadingScreen.enabled = false
	# 1. A brand-new player: the title, a welcome, no What's New
	var m = await new_main({})
	await process_frame
	var names: Array = overlays(m).map(func(o): return o.get_class() + ":" + str(o.get_script().get_global_name()))
	print("QA: title overlays ", names)
	check(not overlays(m).any(func(o): return o is WhatsNew), "a brand-new player sees no What's New")
	# 2. Found a town
	m.profile.found_town(1, "Ashford", hc)
	m.profile.save()
	m = await new_main({"new": 1, "hc": hc})
	check(m.started, "the new hero started")
	check(overlays(m).any(func(o): return o is CharacterCreator), "the creator opens for a new hero")
	for o in overlays(m):
		if o is CharacterCreator:
			o._finish()
	await process_frame
	print("QA: after creator overlays ", overlays(m).map(func(o): return str(o.get_script().get_global_name())))
	if m.state.hero_class == "":
		m._on_class_chosen("Warrior")
	await close_popups(m)
	m.timer.stop()
	check(m.state.hardcore == hc, "hero follows the town mode")
	print("QA: hero %s class=%s floor=%d in_town=%s hp=%d" % [m.state.hero_name, m.state.hero_class, m.state.floor_num, m.state.in_town, m.state.hero_hp])
	# 3. Dive and fight a while on Auto (all the juice, loot, curses, slots)
	m.state.autoplay = true
	if m.state.in_town:
		m._leave_town()
	await ticks(m, 400)
	for r in m.state.runs:
		print("QA run: ", r)
	var st: GameState = m.state
	print("QA: after 400 ticks floor=%d lvl=%d gold=%d bag=%d eggs=%d pets=%d dead=%d" % [st.floor_num, st.level, st.gold, st.bag.size(), st.eggs.size(), st.pets.size(), st.codex.stat("deaths")])
	# 4. Jewelry: a ring and a necklace drop and get worn
	for slot in ["Ring", "Necklace"]:
		if not slot in GameData.SLOT_ORDER:
			print("QA: slot name not in SLOT_ORDER: ", slot, " ", GameData.SLOT_ORDER)
			continue
		var it: Dictionary = GameData.make_item(slot, 3, st.floor_num, st._new_id())
		st.bag.append(it)
		st.equip(int(it["id"]))
	print("QA: equipped slots ", st.equipped.keys())
	# a cursed item for the Church
	var cur: Dictionary = GameData.make_item("Weapon", 3, st.floor_num, st._new_id())
	Church.curse(cur)
	st.bag.append(cur)
	# an egg
	Menagerie.give_egg(st, "nest")
	await tour_tabs(m, "in the dungeon, with jewelry, curse and egg")
	# 5. Go home
	st.return_scrolls = maxi(st.return_scrolls, 1)
	var home := Town.use_return(st)
	check(home or st.in_town, "a Return Scroll takes you home")
	check(m.go_to_town(true) or st.in_town, "main goes to town")
	await process_frame
	await close_popups(m)
	# 6. Buildings
	st.gold += 200000
	st.scrap += 20000
	st.dust += 2000
	var built := []
	for id in Buildings.LIST.keys():
		if Buildings.upgrade(st, m.profile, id):
			built.append(id)
	print("QA: built ", built, " blocked church: ", Buildings.blocked(st, m.profile, "church"))
	# 7. Church cleanse
	var r = Church.cleanse(st, cur, 0)
	print("QA: cleanse -> ", r, " cursed now=", Church.is_cursed(cur))
	# 8. Egg hatches
	if not st.eggs.is_empty():
		var pet := Menagerie.hatch(st, st.eggs[0])
		print("QA: hatched ", pet.get("species", "?"), " art ok=", not Sprites.enemy_by_key(String(Monsters.by_id(String(pet.get("species", ""))).get("art", pet.get("species", "")))).is_empty())
	# 9. Wheel (Fortune's Wheel odds and legendary)
	print("QA: wheel cost ", WheelTables.spin_cost(st), " legendary unlocked ", WheelTables.legendary_unlocked(st))
	# 10. Collections
	var got = Collections.check(st.codex)
	print("QA: collections check -> ", got)
	await tour_tabs(m, "in town after buildings, church, hatch")
	# 11. Save and load
	m.save_everything()
	var gold_before := st.gold
	var eq_before: Array = st.equipped.keys()
	var pets_before := st.pets.size()
	m = await new_main({"play": 1})
	print("QA: msgs after load: ", m.state.messages)
	check(m.started, "the hero loads")
	check(m.state.gold == gold_before, "gold survives save/load (%d vs %d)" % [m.state.gold, gold_before])
	check(m.state.equipped.keys() == eq_before, "worn slots survive (%s vs %s)" % [m.state.equipped.keys(), eq_before])
	check(m.state.pets.size() == pets_before, "pets survive")
	check(Buildings.level("inn") >= 1 or Buildings.level("church") >= 1, "building levels survive")
	await close_popups(m)
	m.timer.stop()
	st = m.state
	# 12. Auto-dive: back down, Auto heads home by its own rules
	if st.in_town:
		m._leave_town()
	AutoDive.set_value(st, "potions_at", 0)
	AutoDive.set_value(st, "hp_pct", 30)
	went_home = 0
	st.autoplay = true
	await ticks(m, 600)
	print("QA: Auto went home %d times" % went_home)
	print("QA: auto after 600 ticks floor=%d in_town=%s portal=%s trial=%s lvl=%d deaths=%d" % [st.floor_num, st.in_town, st.portal, st.trial_active, st.level, st.codex.stat("deaths")])
	# 13. Death
	if st.in_town:
		m._leave_town()
	await close_popups(m)
	st.party = null if st.hardcore else st.party
	var fl := st.floor_num
	st.hero_hp = 0
	st._hero_died()
	m.refresh()
	await process_frame
	if hc:
		check(st.run_over, "Hardcore death is final")
		m._handle_events()
		await process_frame
		check(overlays(m).any(func(o): return true), "the fallen card shows")
	else:
		check(not st.run_over and st.hero_hp == st.get_max_hp(), "Regular hero wakes")
		print("QA: Regular fell on %d, woke on %d, in_town=%s" % [fl, st.floor_num, st.in_town])
	await tour_tabs(m, "after death")
	print("QA PLAY DONE, failures: ", fails)
	main.queue_free()
	await process_frame
	GameState.delete_saves()
	quit()
