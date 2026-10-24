extends SceneTree
## 2.1 F3: one portal system (portals.gd, claude/portals.md). Every kind goes
## through the same card panel and the same rules: rifts (one type with a depth),
## realm gates and trials; falls, Return Scrolls, Hardcore, and save/load mid-portal.
## godot --headless --path . -s tests/stage6_portals.gd
var fails := 0
const SLOT := 7

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(f := 20, hc := false) -> GameState:
	var g := GameState.new()
	g.slot = SLOT
	g.codex = Codex.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.hardcore = hc
	g.choose_class("Warrior")
	g.level = 40
	g.floor_num = f
	g.best_floor = f
	g.in_town = false
	g.spawn_enemy()
	g.horde_left = 0
	return g

## Walk into a rift room (depth d; 0 = as rolled) and tap the rift.
func rift_room(g: GameState, d := 0) -> void:
	g._room_cleared()
	g.doors = ["rift", "rift", "rift"]
	g.choose_path("door_m")
	if d > 0:
		g.room_props[0]["depth"] = d
	Halls.interact(g, 0)

func win(g: GameState) -> void:
	g.enemy_hp = 0
	g._enemy_defeated()

func reload(g: GameState) -> GameState:
	g.autosave = true
	g.save_game(true)
	var h := GameState.new()
	h.slot = SLOT
	h.codex = Codex.new()
	h.codex.path = ""
	check(h.load_game(), "the save loads")
	h.autosave = false
	return h

func trial(g: GameState) -> bool:
	return g.start_special_trial({"name": "The Test Champion", "art": "boss_grendel", "lore": ""}, "god", {})

func _initialize() -> void:
	# --- One rules table, one card shape
	for k in ["rift", "realm", "trial"]:
		var r: Dictionary = Portals.KINDS.get(k, {})
		for field in ["name", "found", "cost", "run", "home", "death", "floors", "reward"]:
			check(r.has(field), "rules table: %s has %s" % [k, field])

	# --- Rift through the portal card: depth 1
	var g := hero(20)
	rift_room(g)
	var floor_in := g.floor_num  # walking through the door is the next floor
	check(g.path_offer == ["portal:rift", "portal:leave"], "tapping a rift shows its card and Walk on")
	check(Portals.title(g) == "A rift (depth 1)", "the panel title shows the depth (%s)" % Portals.title(g))
	var c: Dictionary = g.path_info("portal:rift")
	check(String(c["name"]) == "Rift, depth 1" and String(c["text"]).contains("Danger") and String(c["color"]) == Portals.COLOR, "the rift card: name, danger, portal color")
	check(String(g.path_info("portal:leave")["name"]) == "Walk on", "the Walk on card")
	check(g.auto_path() == "portal:rift", "Auto still steps through")
	g.choose_path("portal:rift")
	check(Portals.inside(g) and Portals.kind(g) == "rift" and String(g.portal.get("kind", "")) == "rift" and Rifts.depth(g) == 1, "inside a depth 1 rift")
	check(Lineage.escape_block(g) == "No running in a rift" and not Lineage.can_spare(g), "no running, no sparing")
	check(Town.blocked(g) == Portals.hold_text(g) and Town.blocked(g).contains("Return Scroll"), "no walking home (one line)")
	check(Portals.open_block(g) != "" and not trial(g), "one portal at a time: no trial inside a rift")
	for i in Rifts.FIGHTS:
		win(g)
	check(g.portal.is_empty() and g.door_pending() and g.floor_num == floor_in, "the vault, then back out to your doors on the same floor")
	check(g.codex.stat("rifts") == 1 and g.codex.stat("rifts_found") == 1 and g.codex.stat("deep_rifts") == 0, "counted as a depth 1 rift")

	# --- Walk on
	var w := hero(20)
	rift_room(w)
	w.choose_path("portal:leave")
	check(w.portal.is_empty() and w.door_pending() and bool(w.room_props[0]["used"]) and w.codex.stat("rifts_found") == 0, "Walk on: the rift closes, no risk, doors open")

	# --- Depth 3 through the same card
	var dp := hero(60)
	rift_room(dp, 3)
	check(String(dp.path_info("portal:rift")["name"]) == "Rift, depth 3", "a depth 3 card")
	dp.choose_path("portal:rift")
	var kills := 0
	while not dp.portal.is_empty() and kills < 20:
		win(dp)
		kills += 1
	check(kills == Rifts.FIGHTS * Rifts.MAX_DEPTH and dp.codex.stat("deep_rifts") == 1, "depth 3: three floors of three fights, counted (%d)" % kills)
	# depth is rolled from floor 30 only, as before (30%)
	var low := 0
	var deep := 0
	var lo := hero(20)
	var hi := hero(60)
	for i in 2000:
		low += 1 if Rifts.roll_depth(lo) > 1 else 0
		deep += 1 if Rifts.roll_depth(hi) > 1 else 0
	check(low == 0 and deep > 450 and deep < 750, "depth 3 odds unchanged: none below floor 30, about 30%% deeper (%d of 2000)" % deep)

	# --- Realm gates through the same card panel
	GameData.realm_order = []
	var r := hero(251)
	r.realm_order = []
	Realms.offer_portals(r)
	check(r.path_offer.size() >= 2 and r.path_offer.all(func(k): return String(k).begins_with("portal:")), "realm gates offered as portal cards")
	check(Portals.title(r) == "Choose a realm", "realm panel title")
	var rc: Dictionary = r.path_info(r.path_offer[0])
	check(String(rc["text"]).contains("Danger") and String(rc["name"]) == Realms.realm_name(String(r.path_offer[0]).substr(7)), "the realm card: name and danger")
	check(not Portals.inside(r) and Town.blocked(r, true) == "", "a realm is not a place that holds you")
	# save/load before choosing: the choice comes back (the realm is never decided for you)
	var r2 := reload(r)
	check(r2.path_offer.size() >= 2 and String(r2.path_offer[0]).begins_with("portal:") and r2.realm_order.is_empty(), "loading mid-choice: the realm gates open again")
	# walking home before choosing: they open again when you come down
	r2.best_floor = 251
	check(Town.enter(r2, true) and r2.path_offer.is_empty(), "home before choosing")
	Town.leave(r2)
	check(r2.path_offer.size() >= 2 and String(r2.path_offer[0]).begins_with("portal:"), "back down: the realm gates open again")
	var pick: String = r2.path_offer[0]
	r2.choose_path(pick)
	check(r2.realm_order == [pick.substr(7)] and GameData.realm_of(251) == pick.substr(7), "the chosen realm")
	GameData.realm_order = []

	# --- Trials: same rules
	var t := hero(20)
	t.in_town = true
	check(not trial(t) and not t.trial_active, "trials open only in the dungeon")
	t.in_town = false
	check(trial(t) and Portals.inside(t) and Portals.kind(t) == "trial", "a trial is a portal")
	check(Lineage.escape_block(t) == "No running in a trial" and not Lineage.can_spare(t), "trial: no running, no sparing")
	check(Town.blocked(t) == Portals.hold_text(t) and Town.blocked(t).contains("Return Scroll"), "trial: the same hold line")
	check(Rifts.maybe_door(t, "fight") == "fight", "no rift doors during a trial")
	var gold0 := t.gold
	win(t)
	check(not t.trial_active and t.floor_num == 20 and t.gold > gold0, "won: back on your floor, with gold")

	# --- Falls
	var f := hero(40)
	f.gold = 1000
	rift_room(f)
	f.choose_path("portal:rift")
	f._hero_died()
	check(f.portal.is_empty() and f.floor_num == f.checkpoint_start(40) and not f.run_over and f.gold < 1000, "a fall in a rift: the rift closes, a normal fall (checkpoint, losses)")
	var tf := hero(40)
	tf.gold = 1000
	trial(tf)
	tf._hero_died()
	check(not tf.trial_active and tf.floor_num == 40 and tf.gold == 1000 and tf.hero_hp == tf.get_max_hp() and not tf.run_over, "a lost trial costs nothing")

	# --- Hardcore: one life, in every portal
	var hr := hero(40, true)
	rift_room(hr)
	hr.choose_path("portal:rift")
	hr._hero_died()
	check(hr.run_over and hr.portal.is_empty(), "Hardcore: a fall in a rift is final")
	var ht := hero(40, true)
	trial(ht)
	ht._hero_died()
	check(ht.run_over, "Hardcore: a lost trial is final too")
	check(Portals.open_block(hr) != "" and not trial(hr), "a finished Hardcore hero opens no portal")

	# --- Return Scrolls get you out of any portal (no reward)
	var sr := hero(20)
	sr.return_scrolls = 1
	rift_room(sr)
	sr.choose_path("portal:rift")
	check(Portals.scroll_note(sr).contains("no vault"), "the scroll prompt says the vault is lost")
	check(Town.use_return(sr) and sr.in_town and sr.portal.is_empty() and sr.return_scrolls == 0 and sr.codex.stat("rifts") == 0, "Return Scroll out of a rift: home, no vault")
	var st := hero(20)
	st.return_scrolls = 1
	trial(st)
	check(Town.use_return(st) and st.in_town and not st.trial_active and st.floor_num == 20, "Return Scroll out of a trial: home, try again later")

	# --- Save and load mid-portal
	var s := hero(40)
	rift_room(s, 3)
	var s2 := reload(s)
	check(s2.path_offer == ["portal:rift", "portal:leave"] and Portals.rift_depth_here(s2) == 3, "loading before stepping through: the same rift card")
	s2.choose_path("portal:rift")
	win(s2)
	win(s2)
	win(s2)  # rift floor 2 now
	var s3 := reload(s2)
	check(Portals.inside(s3) and Rifts.depth(s3) == 3 and int(s3.portal["floor"]) == 2 and int(s3.portal["left"]) == Rifts.FIGHTS, "loading mid-rift: same depth, floor and fights left")
	check(s3.enemy_name.begins_with("Rift-touched") and s3.enemy_tier == Monsters.EPIC and Lineage.escape_block(s3) != "", "loading mid-rift: a rift fight again (not an ordinary monster)")
	var k3 := 0
	while not s3.portal.is_empty() and k3 < 10:
		win(s3)
		k3 += 1
	check(k3 == Rifts.FIGHTS * 2 and s3.codex.stat("deep_rifts") == 1, "the loaded rift finishes normally (%d more fights)" % k3)
	# a save written before 2.1 F3 ({"floors": 3})
	var o := hero(40)
	o.portal = {"left": 2, "floor": 1, "floors": 3}
	var o2 := reload(o)
	check(String(o2.portal.get("kind", "")) == "rift" and Rifts.depth(o2) == 3 and not o2.portal.has("floors"), "an older rift save becomes a depth 3 rift")

	print("STAGE6 PORTAL TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
