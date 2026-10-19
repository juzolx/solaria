extends SceneTree
## Fortune's Wheel wins are as strong as your average gear; Gear Score compares slots.
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
	g.level = 60
	g.best_floor = 120
	g.floor_num = 120
	g.gold = 10000000
	for s in ["Weapon", "Helmet", "Chest"]:
		g.equipped[s] = GameData.make_item(s, 3, 120, g._new_id())
	var avg := g.average_gear_score()
	check(avg > 0, "an average Gear Score (%d)" % avg)
	var old := GameData.make_item("Feet", 1, 5, g._new_id())
	g.bag.append(old)
	g.dev_mode = true
	g.dev_always_win = true
	var r := g.gamble(int(old["id"]))
	check(r.get("win", false), "the wheel wins (dev)")
	var won: Dictionary = r["item"]
	check(GameData.gear_score(won) >= avg, "a win is at least your average (%d vs %d)" % [GameData.gear_score(won), avg])
	check(int(won["floor"]) >= 120, "and made for your depth")
	var w1 := GameData.make_item("Weapon", 0, 1, 1)
	var h1 := GameData.make_item("Helmet", 0, 1, 2)
	check(absi(GameData.gear_score(w1) - GameData.gear_score(h1)) <= 3, "Gear Score puts slots on one scale (%d vs %d)" % [GameData.gear_score(w1), GameData.gear_score(h1)])
	print("STAGE4 WHEEL TESTS DONE, failures: ", fails)
	quit()
