extends SceneTree
## Descenders' Camps after bosses: rest, Snik, and the courier.
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
	g.level = 30
	g.floor_num = 26
	g.best_floor = 26
	g.in_town = false
	g.spawn_enemy()
	var doors := g.roll_doors(true)
	check("camp" in doors, "after a boss one door leads to a camp (%s)" % str(doors))
	g._room_cleared()
	g.doors = ["camp", "camp", "camp"]
	g.hero_hp = 5
	g.choose_path("door_m")
	check(g.hero_hp == g.get_max_hp(), "the fire heals you")
	check(not g.merchant.is_empty(), "Snik sets up shop")
	check(g.door_pending(), "the doors are open while you're here")
	g.events.clear()
	Halls.interact(g, 0)
	check(g.events.any(func(e): return e["type"] == "descender_camp"), "tapping the camp opens it")
	g.gold = 1000
	var bank0 := g.bank
	check(Camp.send_home(g) == 900 and g.bank - bank0 == 900 and g.gold == 0, "the courier banks 90%")
	check(Camp.send_home(g) == 0, "nothing to send twice")
	print("STAGE3 CAMP TESTS DONE, failures: ", fails)
	quit()
