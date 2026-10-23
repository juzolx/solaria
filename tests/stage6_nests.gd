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
			check(e.has("zone") and e.has("tier") and int(e["zone"]) == GameData.zone_index(n.floor_num), "the egg knows its region and rank")
			check(Menagerie.egg_name(e).contains(Menagerie.TIER_NAMES[int(e["tier"])]) and Menagerie.egg_name(e).contains(String(GameData.ZONES[int(e["zone"])]["name"])), "egg name shows rank and region (%s)" % Menagerie.egg_name(e))
	# Hatching: that region's monsters, at the egg's rank
	for zi in [0, 1, 2]:
		var z: Dictionary = GameData.ZONES[zi]
		var names: Array = []
		for en in z["enemies"]:
			names.append(en["name"])
		for s in z["subs"]:
			names.append(s["monster"]["name"])
		for t in 6:
			var h := hero()
			var p := Menagerie.hatch(h, {"id": 1, "floors": 0, "zone": zi, "tier": t})
			check(String(p["species"]) in names or String(p["name"]) in names, "zone %d tier %d hatches a local monster (%s)" % [zi, t, p["species"]])
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
	# Old saves: Snik's egg item and eggs without a region still work
	var o := hero()
	o.merchant = [{"kind": "scroll", "id": "egg", "price": 1, "sold": false}]
	o.gold = 100
	check(o.buy_merchant(0) and o.eggs.size() == 1, "an old Snik egg can still be bought")
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
