extends SceneTree
## 0.13 room interactions.
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
	g.exploring = true
	return g

func one(kind: String, extra := {}) -> GameState:
	var g := hero()
	var p := {"kind": kind, "used": false, "x": 0.5, "y": 0.6}
	p.merge(extra, true)
	g.room_props = [p]
	return g

func _initialize() -> void:
	var c := one("chest", {"mimic": false})
	var g0 := c.gold
	var bag0 := c.bag.size()
	Halls.interact(c, 0)
	check(c.gold > g0 and c.bag.size() > bag0 and c.room_props[0]["used"], "a chest pays out")
	check(Halls.interact(c, 0) == "", "opened once only")
	var m := one("chest", {"mimic": true})
	Halls.interact(m, 0)
	check(m.enemy_name == "Mimic" and m.enemy_tier >= Monsters.EPIC and not m.exploring, "a mimic attacks")
	var mimics := 0
	for i in 400:
		var r := hero()
		Halls.roll_props(r)
		for p in r.room_props:
			if p["kind"] == "chest" and p.get("mimic", false):
				mimics += 1
	check(mimics > 3, "mimics exist (%d)" % mimics)
	var k := hero()
	k.room_props = [{"kind": "locked", "used": false, "x": 0.5, "y": 0.4}, {"kind": "key", "used": false, "x": 0.3, "y": 0.6}]
	check(Halls.interact(k, 0).contains("locked"), "locked without the key")
	Halls.interact(k, 1)
	var kg := k.gold
	Halls.interact(k, 0)
	check(k.room_key and k.gold > kg, "the key opens the locked chest")
	var n := one("npc")
	n.potions = 0
	Halls.interact(n, 0)
	check(not n.room_props[0]["used"], "no potion to give")
	n.potions = 2
	var ng := n.gold
	Halls.interact(n, 0)
	check(n.potions == 1 and n.gold > ng, "helping the adventurer pays")
	var eggs := 0
	for i in 60:
		var b := one("beast")
		Halls.interact(b, 0)
		eggs += b.eggs.size()
	check(eggs > 15, "dying beasts leave eggs (%d/60)" % eggs)
	var nests := 0
	for i in 80:
		var ns := one("nest")
		Halls.interact(ns, 0)
		nests += ns.eggs.size()
		if ns.eggs.is_empty():
			check(ns.horde_left >= 2, "an angry nest brings a pack")
	check(nests > 5, "nests hold eggs sometimes (%d/80)" % nests)
	for kind in ["pot", "altar", "lever"]:
		var x := one(kind)
		check(Halls.interact(x, 0) != "" and x.room_props[0]["used"], "%s does something" % kind)
	var busy := one("chest", {"mimic": false})
	busy.exploring = false
	check(Halls.interact(busy, 0) == "", "nothing to poke at mid-fight")
	print("STAGE2 PROP TESTS DONE, failures: ", fails)
	quit()
