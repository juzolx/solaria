extends SceneTree
## Run history: each dive is logged, home or fallen.
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
	g.level = 20
	g.floor_num = 12
	g.best_floor = 12
	g.in_town = true
	g.gold = 100
	Town.leave(g)
	g.floor_num = 15
	g.gold += 300
	g.path_offer.clear()
	Town.enter(g, true)
	check(g.runs.size() == 1 and String(g.runs[0]["out"]) == "home" and int(g.runs[0]["gold"]) == 300, "a safe dive is logged with its gold")
	Town.leave(g)
	g.spawn_enemy()
	var killer := g.enemy_name
	g._hero_died()
	check(g.runs.size() == 2 and String(g.runs[0]["out"]) == "fell" and String(g.runs[0]["killer"]) == killer, "a fall is logged with the killer, newest first")
	check(RunLog.lines(g).size() == 2, "lines for the Stats tab")
	for i in 30:
		g.dive = {"floor": 1}
		RunLog.add(g, "home", 1, 0)
	check(g.runs.size() == RunLog.MAX, "only the last %d are kept" % RunLog.MAX)
	print("STAGE3 RUN TESTS DONE, failures: ", fails)
	quit()
