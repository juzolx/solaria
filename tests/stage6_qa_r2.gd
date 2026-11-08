extends SceneTree
## QA code review r2 (claude/research/qa-code-r2.md): regression tests for the SAFE fixes.
## godot --headless --path . -s tests/stage6_qa_r2.gd
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

class FakeMain extends Node:
	var state: GameState
	var profile := Profile.new()
	var sfx = null
	func refresh() -> void:
		pass

func hero(n: int, cls: String) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.slot = n
	g.new_game()
	g.choose_class(cls)
	g.hero_name = cls
	g.best_floor = 60
	g.save_game(true)
	return g

func loaded(n: int) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.slot = n
	g.load_game()
	return g

func spare_skill(g: GameState) -> String:
	for id in SkillData.SKILLS:
		if not g.skill_book.has(id):
			return id
	return ""

func buttons(n: Node, out: Array) -> Array:
	if n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		buttons(c, out)
	return out

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1

	# --- #1 HIGH: a sold skill doesn't come back from another hero's save (infinite dust)
	var p := Profile.new()
	var a := hero(1, "Warrior")
	var b := hero(2, "Ranger")
	var x := spare_skill(a)
	a.skill_book[x] = 3
	b.skill_book[x] = 3               # B's own file lists X too
	b.save_game(true)
	a.profile_ref = p
	check(a.join_book(p.skill_book), "the first join merges A's book")
	check(not a.join_book(p.skill_book), "a second join doesn't merge again")
	var bb := loaded(2)
	bb.profile_ref = p
	bb.join_book(p.skill_book)        # what main does when B is played
	bb.save_game(true)
	check(p.skill_book.has(x), "X is in the shared book")
	a.skill_book = p.skill_book
	var dust0 := a.dust
	var paid := a.sell_skill(x)
	check(paid > 0 and a.dust == dust0 + paid, "selling X pays dust")
	check(not p.skill_book.has(x), "X left the shared book")
	var b2 := loaded(2)               # play B again: its file still holds a copy of X
	check(b2.book_shared, "B's file remembers its book was shared")
	b2.join_book(p.skill_book)
	check(not p.skill_book.has(x), "playing B doesn't bring X back")
	a.set_party([2])                  # Remove / Add B in the party tab
	check(a.party != null and a.party.size() == 1, "B joins A's party")
	check(not a.skill_book.has(x), "B joining the party doesn't bring X back")
	check(a.sell_skill(x) == 0, "X can't be sold a second time")
	# A brand-new hero still brings their own skills into the shared book once
	var c := hero(3, "Mage")
	var y := ""
	for id in SkillData.SKILLS:
		if not p.skill_book.has(id) and id != x:
			y = id
			break
	c.skill_book[y] = 2
	c.join_book(p.skill_book)
	check(int(p.skill_book.get(y, 0)) == 2, "a new hero's own skills join the shared book")

	# --- #2 / #14 HIGH: walking out of town and straight back restocks nothing
	var t := hero(4, "Warrior")
	t.in_town = true
	Town.leave(t)
	check(not t.in_town, "left town")
	check(Town.enter(t), "back home at once")
	var shop_ids: Array = t.shop.map(func(it): return int(it.get("id", -1)))
	var smith_ids: Array = t.smith_stock.map(func(it): return int(it.get("id", -1)))
	var trips := t.codex.stat("home_trips")
	var ev := t.town_event
	for i in 5:
		Town.leave(t)
		Town.enter(t)
	check(t.shop.map(func(it): return int(it.get("id", -1))) == shop_ids, "the shop isn't restocked by a bounce")
	check(t.smith_stock.map(func(it): return int(it.get("id", -1))) == smith_ids, "Hilde's stock isn't either")
	check(t.codex.stat("home_trips") == trips, "a bounce isn't a home trip (%d -> %d)" % [trips, t.codex.stat("home_trips")])
	check(t.town_event == ev, "a bounce doesn't reroll the town event")
	Town.leave(t)
	t.codex.add("kills")              # a dive that fought
	Town.enter(t)
	check(t.codex.stat("home_trips") == trips + 1, "a real dive counts a home trip")
	check(t.shop.map(func(it): return int(it.get("id", -1))) != shop_ids, "and restocks the shop")

	# --- #3 HIGH: the team can't change in the dungeon, and changing it never resets the fight
	var d := hero(5, "Warrior")
	d.in_town = false
	d.enemy_name = "MARKER"
	var hp := d.enemy_hp
	d.set_party([2])
	check(d.enemy_name == "MARKER" and d.enemy_hp == hp, "set_party in the dungeon keeps the fight")
	d.in_town = true
	d.set_party([])
	check(d.enemy_name != "MARKER", "in town the next fight is made for the new team")
	var fm := FakeMain.new()
	fm.state = d
	root.add_child(fm)
	var tab := PartyTab.new()
	fm.add_child(tab)
	tab.setup(fm)
	d.set_party([2])
	d.in_town = false
	tab.refresh()
	var labels := buttons(tab, [])
	check(not "Add" in labels and not "Remove" in labels, "the party tab has no Add / Remove in the dungeon (%s)" % str(labels))
	d.in_town = true
	tab.shown = ""
	tab.refresh()
	labels = buttons(tab, [])
	check("Add" in labels and "Remove" in labels, "but does in town (%s)" % str(labels))
	fm.queue_free()

	# --- #4 HIGH: Floors travel can't leave a rift or trial, or escape a Calamity
	var f := hero(1, "Warrior")
	f.in_town = false
	f.best_floor = 60
	f.go_to_floor(30)
	check(f.floor_num == 30, "travel works normally")
	f.portal = {"kind": "rift", "left": 3, "floor": 1}
	check(not f.go_to_floor(20) and f.floor_num == 30, "not out of a rift")
	f.portal = {}
	f.trial_active = true
	check(not f.go_to_floor(20) and f.floor_num == 30, "not out of a trial")
	f.trial_active = false
	f.calamity_pending = true
	check(not f.go_to_floor(20) and f.floor_num == 30, "not away from a Calamity")
	f.calamity_pending = false
	f.enemy_calamity = 0
	f.leader_down = true
	f.hero_hp = 0
	check(f.go_to_floor(20) and f.floor_num == 20, "travel works again")
	check(not f.leader_down and f.hero_hp > 0, "a knocked-out leader gets up on the new floor")

	# --- #5 HIGH: "Follow the scout" brings the new floor's monster; no shortcut past a boss
	var s := hero(1, "Warrior")
	s.in_town = false
	var before := GameData.ZONE_FLOORS - 1    # the floor under the zone boss
	check(GameData.is_boss_floor(before + 1), "floor %d is a boss floor" % (before + 1))
	s.floor_num = before
	s.path_rooms_on = true
	for i in 300:
		World.start_event(s)
		if "follow_scout" in s.path_offer:
			break
	check(not "follow_scout" in s.path_offer, "the scout never offers a shortcut onto a boss floor")
	s.path_offer = []
	s.floor_num = 30
	s.fight = 2
	s.enemy_name = "MARKER"
	World.choose(s, "follow_scout")
	check(s.floor_num == 31 and s.fight == 1, "the scout takes you one floor down")
	check(s.enemy_name != "MARKER" and s.enemy_hp == s.enemy_max_hp, "and the new floor has its own monster")
	s.floor_num = before
	World.choose(s, "follow_scout")   # an old save offered it anyway: the boss is there
	check(s.floor_num == before + 1 and s.enemy_is_boss, "following onto a boss floor meets the boss")

	# --- #8: every achievement can be earned
	var keys_ok := true
	for ach in Codex.ACHIEVEMENTS:
		if String(ach["key"]) in ["specs", "evos", "branch_offs"]:
			keys_ok = false
		if String(ach["key"]) == "heroes" and int(ach["target"]) > GameData.MAX_HEROES:
			keys_ok = false
	check(keys_ok, "no achievement waits on a stat nothing counts")
	check(Guide.has_page("bounties"), "the guide page exists")

	# --- #13: a clock moved back gives no login reward and doesn't reroll bounties
	var k := hero(2, "Ranger")
	var cx := k.codex
	var now := 1_800_000_000.0
	check(cx.check_login_at(now) > 0, "first login pays")
	check(cx.check_login_at(now + 86400) > 0, "next day pays")
	var streak := int(cx.login["streak"])
	check(cx.check_login_at(now - 86400 * 3) == 0, "a clock set back pays nothing")
	check(int(cx.login["streak"]) == streak, "and doesn't reset the streak")
	cx.refresh_bounties_at(k, now + 86400)
	(cx.bounties["daily"] as Array)[0]["have"] = 1
	var kept: Dictionary = (cx.bounties["daily"] as Array)[0]
	var day := String(cx.bounties["day"])
	cx.refresh_bounties_at(k, now - 86400 * 5)
	check(String(cx.bounties["day"]) == day, "a clock set back doesn't roll a new bounty day")
	cx.refresh_bounties_at(k, now + 86400 * 2)
	check((cx.bounties["daily"] as Array).has(kept), "a new day keeps a bounty you made progress on")
	check((cx.bounties["daily"] as Array).size() == Codex.DAILY_BOUNTIES, "and fills the rest (%d)" % (cx.bounties["daily"] as Array).size())

	# --- #20 / #21: a Calamity is capped well under int64 and never re-tiered or renamed
	var m := hero(3, "Warrior")
	m.in_town = false
	Calamity.appear(m, 0)
	check(m.enemy_max_hp <= int(Calamity.CAP) and m.enemy_attack <= int(Calamity.CAP), "Calamity numbers are capped")
	var chp := m.enemy_max_hp
	m._apply_tier(Monsters.LEGENDARY)
	check(m.enemy_max_hp == chp, "a Calamity isn't re-tiered")

	# --- #22: closing the app at the doors brings you back to the same doors
	var r := hero(4, "Warrior")
	r.in_town = false
	r.path_rooms_on = true
	r.floor_num = 12
	r._room_cleared()
	var doors: Array = r.doors.duplicate()
	check(r.door_pending(), "the doors are up")
	r.save_game(true)
	var r2 := loaded(4)
	check(r2.doors == doors and r2.door_pending(), "after a relaunch the same doors are waiting")
	check(Town.floor_clear(r2), "and town is allowed (the floor is clear)")
	# An event room you hadn't touched yet is still there
	var e := hero(5, "Warrior")
	e.in_town = false
	e.floor_num = 12
	Halls.enter_event_room(e, "altar")
	check(e.exploring, "standing in a shrine room")
	e.save_game(true)
	var e2 := loaded(5)
	check(e2.exploring and String(e2.room_props[0]["kind"]) == String(e.room_props[0]["kind"]), "the shrine is still there after a relaunch")

	# --- #25: a Unique bought from Snik is locked like any other Unique
	var u := hero(1, "Warrior")
	u.gold = 100000
	var item := GameData.make_item(String(GameData.SLOT_ORDER[0]), GameData.UNIQUE, 20, u._new_id())
	u.merchant = [{"kind": "item", "item": item, "price": 10, "sold": false}]
	check(u.buy_merchant(0), "bought the curio")
	check(bool(item.get("locked", false)), "it is locked")

	# --- #26: XP from sparing levels you up at once
	var l := hero(2, "Warrior")
	l.xp = GameData.xp_to_next(l.level) - 1
	var lv := l.level
	l.xp += 5
	l.gain_xp(0)
	check(l.level == lv + 1, "a full bar levels up right away")

	# --- #28: Legends are held per town and slot
	var h := hero(1, "Warrior")
	GameState.town = 1
	var key1 := Hidden.legend_key(h)
	GameState.town = 2
	check(Hidden.legend_key(h) != key1, "slot 1 in town 2 is a different holder than slot 1 in town 1")
	GameState.town = 1

	# --- #39: billions read short
	check(UI.short(2_100_000_000) == "2.1B", "UI.short has a B step (%s)" % UI.short(2_100_000_000))
	check(UI.short(3_500_000) == "3.5M", "millions unchanged")

	GameState.delete_saves()
	Profile.delete()
	print("STAGE6 QA R2 TESTS DONE, failures: ", fails)
	quit()
