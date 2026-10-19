extends SceneTree
## Milestone cutscenes play once, as they happen.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func count(g: GameState) -> int:
	return g.events.filter(func(e): return e["type"] == "milestone_moment").size()

func _initialize() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.events.clear()
	g.best_floor = 50
	g.floor_num = 50
	Milestones.on_floor(g)
	check(count(g) == 1, "reaching floor 50 plays its moment")
	Milestones.on_floor(g)
	check(count(g) == 1, "only once")
	var v := GameState.new()
	v.codex.path = ""
	v.best_floor = 120
	v.floor_num = 121
	Milestones.on_floor(v)
	check(count(v) == 0, "a veteran past those floors gets no backlog")
	g.events.clear()
	g.codex.add("boss_kills")
	Milestones.on_boss(g, "Black Annis")
	check(count(g) == 1, "the first boss")
	g.events.clear()
	Milestones.on_item(g, GameData.make_item("Weapon", GameData.LEGENDARY, 20, 77))
	Milestones.on_item(g, GameData.make_item("Weapon", GameData.LEGENDARY, 20, 77))
	check(count(g) == 1, "the first Legendary, once")
	print("STAGE3 MILESTONE TESTS DONE, failures: ", fails)
	quit()
