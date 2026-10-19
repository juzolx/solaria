extends SceneTree
## Hidden portals: three rift fights, then the vault; floors don't move inside.
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
	g.level = 40
	g.floor_num = 20
	g.best_floor = 20
	g.in_town = false
	g.spawn_enemy()
	g.horde_left = 0
	return g

func _initialize() -> void:
	var n := 0
	var f := hero()
	for i in 20000:
		if Rifts.maybe_door(f, "fight") == "rift":
			n += 1
	check(n > 20000 * 0.01 and n < 20000 * 0.02, "about 1 door in 70 hides a rift (%d of 20000)" % n)
	var g := hero()
	g._room_cleared()
	g.doors = ["rift", "rift", "rift"]
	g.choose_path("door_m")
	var floor_in := g.floor_num
	check(g.exploring and String(g.room_props[0]["kind"]) == "rift", "the room holds a rift")
	Halls.interact(g, 0)
	check(int(g.portal.get("left", 0)) == 3 and g.enemy_name.begins_with("Rift-touched") and g.enemy_tier == Monsters.EPIC, "through the rift: a rift-touched Epic (%s)" % g.enemy_name)
	check(Lineage.escape_block(g) != "", "no running in the rift")
	var bag0 := g.bag.size()
	var gold0 := g.gold
	g.enemy_hp = 0
	g._enemy_defeated()
	check(int(g.portal.get("left", 0)) == 2 and g.floor_num == floor_in, "two to go, same floor")
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.enemy_name.begins_with("Vault Keeper") and g.enemy_tier == Monsters.LEGENDARY, "the Vault Keeper last (%s)" % g.enemy_name)
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.portal.is_empty() and g.door_pending(), "out again, doors ahead")
	check(g.floor_num == floor_in, "the floor never changed")
	var fine := g.bag.slice(bag0).filter(func(it): return int(it["rarity"]) >= 3).size()
	check(fine >= 2 and g.gold > gold0, "the vault: two Epic-or-better pieces and gold (%d)" % fine)
	check(g.codex.stat("rifts") == 1, "counted")
	# Falling inside closes the rift
	var d := hero()
	Rifts.enter(d)
	d._hero_died()
	check(d.portal.is_empty(), "falling closes the rift")
	print("STAGE3 RIFT TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
