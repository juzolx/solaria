extends SceneTree
## 0.13 one-thing rooms: each door leads to a fight or to a single thing.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.floor_num = 40
	g.spawn_enemy()
	g.horde_left = 0
	return g

## Walk into a room of this kind (door kind).
func room(kind: String) -> GameState:
	var g := hero()
	g._room_cleared()
	g.doors = [kind, kind, kind]
	g.door_traps = [false, false, false]  # a random trap on the door would change what happens inside
	g.choose_path("door_m")
	return g

## A chest room whose chest is still closed (a spotted mimic, a rare roll, opens the doors as you walk in).
func chest_room() -> GameState:
	var g := room("treasure")
	while not g.exploring:
		g = room("treasure")
	return g

func _initialize() -> void:
	# A fight room starts the fight right away
	var f := room("fight")
	check(not f.exploring and f.room_kind == "fight" and f.enemy_hp > 0 and f.room_props.is_empty(), "a fight room starts the fight")
	# A chest room: one chest, tap it, then the doors
	var c := chest_room()
	c.room_props[0]["mimic"] = false
	c.room_props[0]["spotted"] = false
	check(c.exploring and c.room_props.size() == 1 and String(c.room_props[0]["kind"]) == "chest", "a treasure room holds one chest")
	var g0 := c.gold
	var bag0 := c.bag.size()
	Halls.interact(c, 0)
	check(c.gold > g0 and c.bag.size() > bag0 and c.door_pending(), "the chest pays and the doors open")
	check(Halls.interact(c, 0) == "", "opened once only")
	# A mimic fights; beating it opens the doors
	var m := chest_room()
	m.room_props[0]["mimic"] = true
	m.room_props[0]["spotted"] = false
	Halls.interact(m, 0)
	check(m.enemy_name == "Mimic" and m.enemy_tier >= Monsters.EPIC and not m.exploring and not m.door_pending(), "a mimic attacks")
	m.enemy_hp = 0
	m._enemy_defeated()
	check(m.door_pending(), "beating the mimic opens the doors")
	# A mimic never brings a pack (spawn_enemy can roll one; it used to leak out of the chest)
	var leaked := 0
	for s in 60:
		seed(1000 + s)
		var mm := chest_room()
		mm.room_props[0]["mimic"] = true
		mm.room_props[0]["spotted"] = false
		Halls.interact(mm, 0)
		if mm.horde_left > 0 or mm.horde_pack:
			leaked += 1
	check(leaked == 0, "a mimic comes alone (%d of 60 brought a pack)" % leaked)
	var mimics := 0
	for i in 300:
		var r := room("treasure")
		if r.room_props[0].get("mimic", false):
			mimics += 1
	check(mimics > 15 and mimics < 70, "about 1 in 8 chests is a mimic (%d/300)" % mimics)
	# Campfire and Snik: done as you walk in, doors already open
	var rs := room("rest")
	rs.hero_hp = 1
	check(rs.door_pending(), "a campfire room: rest, then doors")
	var mr := room("merchant")
	check(mr.door_pending() and not mr.merchant.is_empty(), "Snik's room: shop, doors open")
	check(Halls.interact(mr, 0) == "" and mr.events.any(func(e): return e["type"] == "merchant"), "tapping Snik opens the shop")
	# A stranger in need
	var n := room("stranger")
	n.potions = 2
	var ng := n.gold
	Halls.interact(n, 0)
	check(n.potions == 1 and n.gold > ng and n.door_pending(), "helping the stranger pays")
	var n2 := room("stranger")
	n2.potions = 0
	Halls.interact(n2, 0)
	check(n2.door_pending(), "no potion: you move on")
	# Eggs
	var eggs := 0
	for i in 60:
		var b := room("beast")
		Halls.interact(b, 0)
		eggs += b.eggs.size()
	check(eggs == 0, "dying beasts leave no eggs (%d/60)" % eggs)
	var nests := 0
	for i in 20:
		var ns := room("nest")
		Halls.interact(ns, 0)
		nests += ns.eggs.size()
	check(nests == 20, "a nest always holds an egg (%d/20)" % nests)
	var al := room("altar")
	check(Halls.interact(al, 0) != "" and al.door_pending(), "the shrine does something")
	# Auto handles the room by itself
	var au := room("treasure")
	au.room_props[0]["mimic"] = false
	au.room_props[0]["spotted"] = false
	au.exploring = true  # (a spotted mimic would have opened the doors already)
	au.path_offer = []
	au.autoplay = true
	for _t in GameData.EXPLORE_WAIT_TURNS + 1:
		au.take_turn()
	check(au.room_props[0]["used"], "Auto opens the chest")
	# Before a boss floor every door is the boss
	var bb := hero()
	bb.floor_num = 1
	while not GameData.is_boss_floor(bb.floor_num + 1):
		bb.floor_num += 1
	check(bb.roll_doors() == ["fight", "fight", "fight"], "before a boss: all doors lead to it")
	var busy := hero()
	busy.exploring = false
	busy.room_props = [{"kind": "chest", "used": false, "x": 0.5, "y": 0.5}]
	check(Halls.interact(busy, 0) == "", "nothing to poke at mid-fight")
	print("STAGE2 PROP TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
