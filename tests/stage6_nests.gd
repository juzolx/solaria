extends SceneTree
## Nests: the only source of pets' eggs. Rare, always an egg, region eggs hatch region monsters at their rank.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(floor_n := 20) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 20
	g.floor_num = floor_n
	return g

func _initialize() -> void:
	# Nest doors: rare, and never before floor 3
	check(not GameState.DOOR_WEIGHTS.has("nest"), "nests are not in the door table")
	var g := hero(10)
	var nests := 0
	var total := 0
	for i in 30000:
		g.floor_num = 10 + (i % 3)
		for d in g.roll_doors():
			total += 1
			if d == "nest":
				nests += 1
	# 0.05% of 90000 doors is about 45
	check(nests >= 10 and nests <= 110, "nest doors are rare, about 1 in 2000 (%d of %d)" % [nests, total])
	var early := 0
	for i in 20000:
		g.floor_num = 1 + (i % 2)
		for d in g.roll_doors():
			if d == "nest":
				early += 1
	check(early == 0, "no nest doors before floor 3 (%d)" % early)
	# A nest always gives an egg with a region and a rank
	for zi in [0, 1, 2]:
		var n := hero(1 + zi * GameData.ZONE_FLOORS)
		n.floor_num = 1 + zi * GameData.ZONE_FLOORS
		Halls.enter_event_room(n, "nest")
		Halls.interact(n, 0)
		check(n.eggs.size() == 1, "a nest holds an egg")
		if n.eggs.size() == 1:
			var e: Dictionary = n.eggs[0]
			check(e.has("zone") and e.has("tier") and typeof(e["zone"]) == TYPE_STRING and Menagerie.egg_zone(e) == GameData.zone_index(n.floor_num), "the egg knows its region (by id) and rank")
			var zname := String(GameData.ZONES[Menagerie.egg_zone(e)]["name"])
			check(Menagerie.egg_name(e) == "%s Egg of %s" % [Menagerie.TIER_NAMES[int(e["tier"])], zname], "egg name shows rank and region (%s)" % Menagerie.egg_name(e))
	# Hatching: that region's monsters, at the egg's rank
	for zi in [0, 1, 2]:
		var z: Dictionary = GameData.ZONES[zi]
		var ids: Array = []
		for en in z["enemies"]:
			ids.append(String(en["id"]))
		for s in z["subs"]:
			ids.append(String(s["monster"]["id"]))
		for t in 6:
			var h := hero()
			var egg_zone = String(z["id"]) if t % 2 == 0 else zi  # new eggs keep the id, older ones the index
			var p := Menagerie.hatch(h, {"id": 1, "floors": 0, "zone": egg_zone, "tier": t})
			check(String(p["species"]) in ids, "zone %d tier %d hatches a local monster (%s)" % [zi, t, p["species"]])
			check(int(p["tier"]) == t, "zone %d hatches at the egg's rank %d (got %d)" % [zi, t, int(p["tier"])])
	# No other egg source
	var eggs := 0
	for i in 200:
		var h := hero()
		Halls.enter_event_room(h, "beast")
		Halls.interact(h, 0)
		eggs += h.eggs.size()
	check(eggs == 0, "dying beasts leave no egg (%d)" % eggs)
	eggs = 0
	for i in 300:
		var h := hero()
		h.enemy_people = ""
		h.enemy_calamity = 0
		h.enemy_is_boss = false
		h.enemy_goblin = false
		h.enemy_max_hp = 100
		h.enemy_hp = 10
		h.horde_left = 0
		Lineage.spare(h)
		eggs += h.eggs.size()
	check(eggs == 0, "sparing leaves no egg (%d)" % eggs)
	eggs = 0
	for i in 400:
		var h := hero()
		h._make_merchant()
		for it in h.merchant:
			if String(it.get("id", "")) == "egg":
				eggs += 1
	check(eggs == 0, "Snik never stocks an egg (%d)" % eggs)
	eggs = 0
	for i in 400:
		var c := Town._new_contract(hero())
		if c.has("reward") and c["reward"].has("egg"):
			eggs += 1
	check(eggs == 0, "bounties never pay an egg (%d)" % eggs)
	# Snik's old Strange Egg is gone: reading an "egg" scroll gives nothing
	var o := hero()
	check(o.use_scroll("egg") == "" and o.eggs.is_empty(), "use_scroll(\"egg\") gives no egg")
	check(not o.SCROLLS.has("egg"), "there is no egg scroll any more")
	# The Wheel and rewards never give an egg either
	for pz in WheelTables.LEGENDARY_PRIZES:
		check(not (pz.get("reward", {}) as Dictionary).has("egg"), "Wheel prize %s gives no egg" % pz["id"])
	o.give_reward({"egg": 1})
	check(o.eggs.is_empty(), "an old egg reward pays nothing")
	# Old eggs (index zone, or no region at all) still hatch
	check(Menagerie.egg_name({"tier": 3, "zone": 0}) == "Epic Egg of %s" % GameData.ZONES[0]["name"], "an old egg with a zone index still names its region")
	var legacy := Menagerie.hatch(o, {"id": 2, "floors": 0, "from": "old"})
	check(not legacy.is_empty(), "an old egg (no region, no rank) still hatches")
	# Higher ranks hit clearly harder
	var last := -1.0
	for t in 6:
		var pw := Menagerie.power({"tier": t, "level": 1})
		check(pw > last * 1.25 or t == 0, "tier %d hits clearly harder (%.3f vs %.3f)" % [t, pw, last])
		last = pw
	print("STAGE6 NEST TESTS DONE, failures: ", fails)
	quit()
