extends SceneTree
## Gear recovery: what you carried drops where you fell, guarded by your killer.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.floor_num = 12
	g.best_floor = 12
	g.in_town = false
	return g

func loaded(g: GameState) -> void:
	g.bag.clear()
	g.equipped.clear()
	for s in ["Weapon", "Helmet", "Chest"]:
		g.equipped[s] = GameData.make_item(s, 2, 12, g._new_id())
	for i in 3:
		g.bag.append(GameData.make_item("Legs", 1, 12, g._new_id()))
	g.gold = 1000

func _initialize() -> void:
	var g := hero()
	loaded(g)
	g.fight = 2
	g.spawn_enemy()
	g.enemy_is_boss = false
	var killer := g.enemy_species
	g._hero_died()
	check(not g.grave.is_empty(), "falling leaves a grave")
	check(int(g.grave.get("floor", -1)) == 12 and String(g.grave.get("killer", "")) == killer, "on the floor you fell, guarded by your killer (%s)" % killer)
	check((g.grave.get("items", []) as Array).size() == 6, "all six carried items are in it (%d)" % (g.grave.get("items", []) as Array).size())
	check(int(g.grave.get("gold", 0)) == 500, "half the carried gold is in it")
	check(g.bag.is_empty() and g.equipped.is_empty() and g.gold == 0, "and they're gone from you")
	check(String(Grave.goal(g).get("text", "")).begins_with("Your gear: floor 12"), "the Next line can point to it")
	var ids: Array = (g.grave["items"] as Array).map(func(it): return int(it["id"]))
	# Back on floor 12, the first monster is the killer
	g.floor_num = 12
	g.fight = 1
	g.horde_left = 0
	g.spawn_enemy()
	if g.enemy_calamity > 0 or g.enemy_goblin:
		g.enemy_goblin = false
		g.spawn_enemy()
	check(g.enemy_grave, "the guardian is waiting on floor 12")
	check(g.enemy_species == killer and g.enemy_tier >= Monsters.RARE, "it's the killer, and tougher (tier %d)" % g.enemy_tier)
	var gold_before := g.gold
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.grave.is_empty(), "beating it empties the grave")
	var back := 0
	for it in g.bag:
		if int(it["id"]) in ids:
			back += 1
	for l in g.mail:
		for it in l["items"]:
			if int(it["id"]) in ids:
				back += 1
	check(back == 6, "all six items come back (%d)" % back)
	check(g.gold - gold_before >= 500, "and the gold")
	# Falling to the guardian keeps everything together
	var h := hero()
	loaded(h)
	h.fight = 1
	h.spawn_enemy()
	h.enemy_is_boss = false
	h._hero_died()
	h.floor_num = 12
	h.fight = 1
	h.horde_left = 0
	h.enemy_goblin = false
	h.spawn_enemy()
	check(h.enemy_grave, "guardian for the second hero")
	h.bag.append(GameData.make_item("Feet", 1, 12, h._new_id()))
	h._hero_died()
	check((h.grave.get("items", []) as Array).size() == 7, "dying to the guardian keeps the old items and adds the new (%d)" % (h.grave.get("items", []) as Array).size())
	# Falling somewhere else: the old grave crumbles
	h.floor_num = 13
	h.fight = 2
	h.horde_left = 0
	h.spawn_enemy()
	h.enemy_grave = false
	h.bag.append(GameData.make_item("Feet", 1, 13, h._new_id()))
	h._hero_died()
	check(int(h.grave.get("floor", -1)) == 13 and (h.grave.get("items", []) as Array).size() == 1, "a new grave replaces the old one")
	# Hardcore heroes don't get graves
	var hc := hero()
	hc.hardcore = true
	loaded(hc)
	hc.spawn_enemy()
	hc._hero_died()
	check(hc.grave.is_empty(), "no graves in Hardcore")
	print("STAGE3 GRAVE TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()

func _count_items(g: GameState) -> int:
	var n := g.bag.size()
	for l in g.mail:
		n += (l["items"] as Array).size()
	return n
