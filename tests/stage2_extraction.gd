extends SceneTree
## Extraction clarity: the "Made it home" tally counts what a dive brought back.
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
	g.level = 20
	g.floor_num = 12
	g.best_floor = 12
	g.in_town = true
	return g

func _initialize() -> void:
	var g := hero()
	g.gold = 1000
	g.carry_pick = 2  # half
	Town.leave(g)
	check(not g.dive.is_empty() and int(g.dive["gold"]) == g.gold, "leaving town remembers what the dive set off with")
	var carried_start := g.gold
	# A good dive: gold, two items, kills, two floors
	g.gold += 340
	g._give_item(GameData.make_item("Weapon", 3, g.floor_num, g._new_id()))
	g._give_item(GameData.make_item("Helmet", 1, g.floor_num, g._new_id()))
	g.codex.add("kills", 7)
	g.floor_num += 2
	g.events.clear()
	g.path_offer.clear()
	check(Town.enter(g, true), "can head home after a cleared floor")
	var tally: Dictionary = {}
	for e in g.events:
		if e["type"] == "home_tally":
			tally = e
	check(not tally.is_empty(), "getting home makes a tally")
	check(int(tally.get("gold", -1)) == 340, "tally gold is what was earned (%d)" % int(tally.get("gold", -1)))
	check(int(tally.get("items", -1)) == 2, "tally counts the new items (%d)" % int(tally.get("items", -1)))
	check(int((tally.get("best", {}) as Dictionary).get("rarity", -1)) == 3, "tally names the rarest item")
	check(int(tally.get("floors", -1)) == 2 and int(tally.get("kills", -1)) == 7, "tally floors and kills")
	check(g.dive.is_empty(), "the dive is done once home")
	check(carried_start > 0, "test carried gold down")
	# Saved and loaded
	Town.leave(g)
	var saved: Dictionary = g.dive.duplicate()
	var d: Dictionary = {}
	d["dive"] = g.dive
	check(not saved.is_empty() and d["dive"] == saved, "the dive snapshot is plain data that saves")
	# A fall restarts the count: lost loot isn't "brought home"
	g._give_item(GameData.make_item("Chest", 2, g.floor_num, g._new_id()))
	g._hero_died()
	check(not g.dive.is_empty() and int(g.dive["gold"]) == g.gold, "after a fall the dive counts again from the checkpoint")
	# The first dive is the tutorial: clear 3 floors, then head home
	var n := GameState.new()
	n.codex.path = ""
	n.autosave = false
	n.new_game()
	n.choose_class("Warrior")
	n.stat_points = 0
	var g1: String = World.next_goal(n).get("text", "")
	check(g1.begins_with("First dive: clear 3 more floors"), "a new hero is told to clear 3 floors (%s)" % g1)
	n.floor_num = 4
	n.best_floor = 4
	var g2: String = World.next_goal(n).get("text", "")
	check(g2.begins_with("Head home"), "after 3 floors: head home (%s)" % g2)
	n.path_offer.clear()
	check(Town.enter(n, true) and n.codex.stat("home_trips") == 0, "a dive with no snapshot isn't counted")
	Town.leave(n)
	n.floor_num += 1
	n.path_offer.clear()
	var _back := Town.enter(n, true)
	check(n.codex.stat("home_trips") == 1, "a safe dive counts as a trip home")
	Town.leave(n)
	check(World.first_dive_goal(n).is_empty(), "the tutorial goal is gone once you've made it home")
	var vet := hero()
	vet.best_floor = 40
	vet.in_town = false
	check(World.first_dive_goal(vet).is_empty(), "veterans never see the first-dive goal")
	print("STAGE2 EXTRACTION TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
