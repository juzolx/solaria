extends SceneTree
## Snik is rarer, and his stall always has one of his own curios.
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
	g.best_floor = 80
	g.floor_num = 80
	g._make_merchant()
	var items: Array = g.merchant.filter(func(e): return e["kind"] == "item")
	check(items.size() == 3, "three pieces")
	check(items.any(func(e): return e["item"].get("snik", false) and int(e["item"]["rarity"]) == GameData.UNIQUE), "one is a Snik curio (unique)")
	check(items.all(func(e): return int(e["item"]["rarity"]) >= 3), "all Epic or better")
	var snik := 0
	for i in 2000:
		snik += g.roll_doors(false).count("merchant")
	check(snik < 6000 * 0.065, "Snik is behind a door rarely (%d of 6000 doors)" % snik)
	print("STAGE4 SNIK TESTS DONE, failures: ", fails)
	quit()
