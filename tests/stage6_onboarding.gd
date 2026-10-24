extends SceneTree
## 2.1 G7 + G9: the first-time flow (order, one at a time, skip), What's New (once,
## not for brand-new players, plain words) and hidden/God class hints (never a name).
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
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	_flow()
	_skip()
	_whats_new_logic()
	_hints()
	await _screens()
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	print("ONBOARDING TESTS DONE, failures: ", fails)
	quit()

func _hero() -> GameState:
	var g := GameState.new()
	g.autosave = false
	g.codex.path = ""
	g.new_game()
	return g

# ---------- G9: the first-time flow ----------

func _flow() -> void:
	var p := Profile.new()
	check(Onboarding.should_welcome(p), "a brand-new player with no heroes is welcomed")
	check(Onboarding.pump(p, _hero(), 100000) == "", "nothing shows before the player says yes")
	Onboarding.set_on(p, true)
	check(Onboarding.active(p) and not Onboarding.should_welcome(p), "after yes the flow runs and the welcome is done")
	check(Onboarding.menu_tip(p, "town").contains("Regular"), "the town step explains Regular simply")
	check(Onboarding.menu_tip(p, "town") == "", "a menu step shows once")
	check(Onboarding.menu_tip(p, "hero") != "", "the hero step shows")
	var g := _hero()
	g.in_town = false
	var t := 1000000
	var shown: Array = []
	# The first fight, loot and a kill all happen at once: the cards still come in order, one at a time
	g.codex.add("kills")
	g.bag.append({"name": "Rusty Sword", "rarity": 0})
	var first := Onboarding.pump(p, g, t)
	check(first == Onboarding.step("dive")["text"], "the dive card comes first")
	check(Onboarding.pump(p, g, t + 100) == "", "one card at a time (a gap between cards)")
	for i in 8:
		t += Onboarding.GAP_MS + 1
		if i == 2:
			g.floor_num = 3
		if i == 3:
			g.in_town = true
			g.bag.clear()
		if i == 4:
			g.codex.add("deaths")
		if i == 5:
			g.level = 5
		var c := Onboarding.pump(p, g, t)
		for s in Onboarding.STEPS:
			if s["text"] == c:
				shown.append(s["id"])
	check(shown == ["fight", "loot", "home", "safe", "death", "more"], "the flow order is dive, fight, loot, home, safe, death, more (got %s)" % str(shown))
	check(Onboarding.finished(p) and not Onboarding.active(p), "the flow ends after the last card")
	t += Onboarding.GAP_MS + 1
	check(Onboarding.pump(p, g, t) == "", "nothing more after the end")
	# Covered first-time tips aren't said twice
	var p2 := Profile.new()
	Onboarding.set_on(p2, true)
	var g2 := _hero()
	Onboarding.on_start(p2, g2)
	check(g2.tips_seen.has("tap") and g2.tips_seen.has("death"), "the coach replaces the tap and death tips")
	check(Onboarding.holds_page(p2, "welcome") and not Onboarding.holds_page(p2, "zones"), "only covered guide pages wait")
	# Experienced players: anyone with a hero is never welcomed
	TestHero.make(5)
	check(not Onboarding.should_welcome(Profile.new()), "a player with a hero is not welcomed")
	GameState.delete_saves()
	Profile.delete()
	# Every card is short and plain (phone, big text)
	for s in Onboarding.STEPS:
		check(String(s["text"]).length() <= 160, "card %s is short" % s["id"])

func _skip() -> void:
	var p := Profile.new()
	Onboarding.set_on(p, true)
	var g := _hero()
	g.in_town = false
	check(Onboarding.pump(p, g, 5000000) != "", "a card shows while on")
	Onboarding.set_on(p, false)  # "Skip tips"
	g.codex.add("kills")
	check(Onboarding.pump(p, g, 6000000) == "" and not Onboarding.active(p), "skip stops every card")
	check(Onboarding.menu_tip(p, "town") == "", "skip stops menu cards too")
	check(not Onboarding.should_welcome(p), "a player who skipped isn't asked again")
	var g2 := _hero()
	Onboarding.on_start(p, g2)
	check(not g2.tips_seen.has("death"), "with tips skipped the normal first-time tips still work")
	Onboarding.set_on(p, true)  # Settings: Beginner tips ON starts again
	check(Onboarding.active(p) and not Onboarding.seen(p, "dive"), "turning tips back on starts from the beginning")

# ---------- G9: What's New ----------

func _whats_new_logic() -> void:
	var p := Profile.new()
	check(not WhatsNew.due(p, true), "a brand-new player doesn't get What's New")
	check(p.whats_new_seen == PatchNotes.VERSION, "...and it's marked seen for them")
	var p2 := Profile.new()
	check(WhatsNew.due(p2, false), "a returning player gets What's New")
	p2.whats_new_seen = PatchNotes.VERSION
	check(not WhatsNew.due(p2, false), "What's New shows once per version")
	check(String(PatchNotes.NOTES[0]["version"]) == PatchNotes.VERSION, "What's New reads the newest patch notes")
	var blob := ""
	for it in WhatsNew.summary():
		blob += " %s %s " % [it[0], it[1]]
	check(WhatsNew.summary().size() >= 6, "there is a friendly summary for %s" % PatchNotes.VERSION)
	for topic in ["God", "nest", "gold, scrap and dust", "Legendary", "Church", "Trophy Cabin", "share", "Portals", "saves"]:
		check(blob.to_lower().contains(topic.to_lower()), "the summary mentions %s" % topic)
	for w in WhatsNew.CASINO_WORDS:
		check(not (" " + blob.to_lower() + " ").contains(w), "no casino word '%s' in What's New" % w)
	check(ClassHints.leaks(blob).is_empty(), "What's New names no secret class")

# ---------- G7: hints ----------

func _hints() -> void:
	# Every possible hint, from every source, never names a secret class
	var all: Array = []
	for id in Hidden.CLASSES:
		all.append(String(Hidden.info(id)["rumor"]))
	for id in GodClasses.LIST:
		for o in ClassHints.OPENERS.size():
			var r := ClassHints.god_riddle(id, o)
			check(r != "", "God class %s has a riddle" % id)
			all.append(r)
	for line in all:
		var lk := ClassHints.leaks(line)
		check(lk.is_empty(), "hint names a secret class %s: %s" % [str(lk), line])
		check(not RegEx.create_from_string("\\d").search(line), "hint gives no number or count: %s" % line)
	check(not ClassHints.leaks("The Titan rises").is_empty(), "the leak check really catches a name")
	# Not before a milestone
	var g := _hero()
	g.in_town = false
	check(ClassHints.pool(g).is_empty(), "no hints before the first milestone")
	check(ClassHints.on_progress(g) == "" and ClassHints.riddles(g).is_empty(), "no whispers or riddles yet")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var inn_hits := 0
	for i in 200:
		if ClassHints.inn_line(g, rng) != "":
			inn_hits += 1
	check(inn_hits == 0, "the Inn has no hint before a milestone")
	# After the first boss: hidden rumors, but no God riddles yet
	g.best_floor = 25
	var pool := ClassHints.pool(g)
	check(not pool.is_empty(), "hints open at the first boss")
	check(pool.size() == Hidden.CLASSES.size(), "only hidden rumors before the deeper milestone")
	inn_hits = 0
	for i in 400:
		var l := ClassHints.inn_line(g, rng)
		if l != "":
			inn_hits += 1
			check(ClassHints.leaks(l).is_empty(), "inn line leaks nothing: " + l)
	check(inn_hits > 40 and inn_hits < 160, "the Inn hint is sparing (%d of 400)" % inn_hits)
	var w := ClassHints.on_progress(g)
	check(w != "" and ClassHints.leaks(w).is_empty(), "a whisper at the first milestone, naming nothing")
	check(ClassHints.on_progress(g) == "", "only one whisper per milestone")
	g.best_floor = 49
	check(ClassHints.on_progress(g) == "", "no whisper until the next milestone")
	g.best_floor = 50
	check(ClassHints.on_progress(g) != "", "a whisper at the next milestone")
	check(ClassHints.riddles(g).size() == 1, "one riddle in the Class tab at first")
	var r1 := ClassHints.riddles(g)
	check(r1 == ClassHints.riddles(g), "riddles keep their order")
	# Deeper: God riddles join; earned classes drop out
	g.best_floor = 400
	check(ClassHints.pool(g).size() > Hidden.CLASSES.size(), "God riddles join after the deeper milestone")
	check(ClassHints.riddles(g).size() <= ClassHints.RIDDLE_MAX, "riddles stay few")
	var first_id: String = Hidden.ORDER[0]
	g.hidden[first_id] = true
	check(not String(Hidden.info(first_id)["rumor"]) in ClassHints.pool(g), "an earned class's rumor is no longer told")
	for l in ClassHints.riddles(g) + ClassHints.pool(g):
		check(ClassHints.leaks(l).is_empty(), "late hint leaks nothing: " + String(l))
	# Hint text never counts how many secret classes there are
	for s in [Guide.page("hidden")["text"], Guide.page("paths")["text"]]:
		check(ClassHints.leaks(String(s)).is_empty(), "guide page names no secret class")

# ---------- the screens open ----------

func _screens() -> void:
	# A returning 2.1 player (has a profile, never saw What's New): it opens once
	TestHero.make(5)
	var p := Profile.load_profile()
	p.whats_new_seen = ""
	p.save()
	TitleScreen.pending = {}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var wn: Array = main.get_children().filter(func(c): return c is WhatsNew)
	check(wn.size() == 1, "What's New opens on the title after an update")
	check(not main.get_children().any(func(c): return c is Overlay and not c is WhatsNew), "no welcome card for a player with heroes")
	check(main.profile.whats_new_seen == PatchNotes.VERSION, "What's New is marked seen")
	main.queue_free()
	await process_frame
	var main2 = load("res://main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	await process_frame
	check(not main2.get_children().any(func(c): return c is WhatsNew), "What's New doesn't show twice")
	main2.queue_free()
	await process_frame
	# A brand-new player: no What's New, the welcome card instead
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var main3 = load("res://main.tscn").instantiate()
	root.add_child(main3)
	await process_frame
	await process_frame
	check(not main3.get_children().any(func(c): return c is WhatsNew), "a brand-new player gets no What's New")
	check(main3.get_children().any(func(c): return c is Overlay), "a brand-new player gets the welcome card")
	var c := Onboarding.coach(main3, "Test card")
	check(c != null and c.get_global_rect().end.y <= main3.get_viewport().get_visible_rect().size.y, "a coach card fits on screen")
	main3.queue_free()
	await process_frame
