extends SceneTree
## The dwarf smith's forged wares.
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
	g.level = 40
	g.best_floor = 60
	g.floor_num = 60
	for s in ["Weapon", "Chest"]:
		g.equipped[s] = GameData.make_item(s, 4, 60, g._new_id())
	Smith.restock(g)
	check(g.smith_stock.size() == Smith.STOCK, "three forged pieces")
	var avg := g.average_gear_score()
	var ok := true
	for e in g.smith_stock:
		if int(e["item"]["rarity"]) < 3 or GameData.gear_score(e["item"]) < avg:
			ok = false
	check(ok, "Epic or better, never below your average Gear Score (%d)" % avg)
	g.gold = 0
	check(not Smith.buy(g, 0), "can't buy without the gold")
	g.gold = 10000000
	var n := g.bag.size()
	check(Smith.buy(g, 0) and g.bag.size() == n + 1 and g.smith_stock[0]["sold"], "buying puts it in your bag")
	check(not Smith.buy(g, 0), "sold once only")
	print("STAGE4 SMITH TESTS DONE, failures: ", fails)
	quit()
