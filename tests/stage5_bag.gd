extends SceneTree
## Next update: Gear Score loot filter.
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
	g.floor_num = 60
	g.auto_salvage = -1
	LootRules.test_ignore_upgrades = true  # 2.1: upgrades are always kept; test the Gear Score rule alone
	for s in ["Weapon", "Chest", "Helmet"]:
		g.equipped[s] = GameData.make_item(s, 3, 60, g._new_id())
	var avg := g.average_gear_score()
	var weak := GameData.make_item("Legs", 0, 5, g._new_id())
	var strong := GameData.make_item("Legs", 3, 120, g._new_id())
	var legend := GameData.make_item("Legs", GameData.LEGENDARY, 5, g._new_id())
	check(GameData.gear_score(weak) < avg, "test setup: weak item is below average (%d < %d)" % [GameData.gear_score(weak), avg])
	check(not g.filter_salvages(weak), "filter off: weak drop kept")
	g.loot_filter["below_gs"] = true
	check(g.filter_salvages(weak), "filter on: below-average drop salvaged")
	check(GameData.gear_score(strong) < avg or not g.filter_salvages(strong), "filter on: an above-average drop is kept")
	check(not g.filter_salvages(legend), "Legendary is always kept")
	weak["locked"] = true
	check(not g.filter_salvages(weak), "locked is always kept")
	g.equipped.clear()
	weak["locked"] = false
	check(not g.filter_salvages(weak), "nothing worn: the filter does nothing")
	print("STAGE5 BAG TESTS DONE, failures: ", fails)
	quit()
