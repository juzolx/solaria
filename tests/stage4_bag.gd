extends SceneTree
## A full bag still takes drops, over the limit, locked until you make room.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.floor_num = 20
	g.auto_salvage = -1
	while g.bag.size() < g.bag_capacity():
		g.bag.append(GameData.make_item("Legs", 0, 20, g._new_id()))
	var drop := GameData.make_item("Weapon", 3, 20, g._new_id())
	g._give_item(drop)
	check(g.bag.size() == g.bag_capacity() + 1, "a drop with a full bag still comes in (%d / %d)" % [g.bag.size(), g.bag_capacity()])
	check(g.over_limit(int(drop["id"])), "it's over the limit")
	g.equip(int(drop["id"]))
	check(not g.equipped.has("Weapon") or int(g.equipped["Weapon"]["id"]) != int(drop["id"]), "it can't be equipped yet")
	check(g.best_for_slot("Weapon").get("id", -1) != int(drop["id"]), "Equip Best ignores it")
	g.sell(int(g.bag[0]["id"]))
	check(not g.over_limit(int(drop["id"])), "sell something: now it's yours to use")
	g.equip(int(drop["id"]))
	check(g.equipped.has("Weapon") and int(g.equipped["Weapon"]["id"]) == int(drop["id"]), "and you can wear it")
	while g.bag.size() < g.bag_capacity() + GameState.OVERFLOW_MAX:
		g.bag.append(GameData.make_item("Legs", 0, 20, g._new_id()))
	var n := g.bag.size()
	var scrap0 := g.scrap
	g._give_item(GameData.make_item("Feet", 1, 20, g._new_id()))
	check(g.bag.size() == n and g.scrap > scrap0, "past the overflow cap, drops turn into scrap")
	print("STAGE4 BAG TESTS DONE, failures: ", fails)
	quit()
