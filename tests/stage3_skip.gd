extends SceneTree
## Skip easy fights: monsters far below you fall in one turn (when switched on).
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
	g.level = 80
	g.best_floor = 80
	g.floor_num = 3
	g.in_town = false
	g.spawn_enemy()
	g.enemy_tier = 0
	g.enemy_variant = ""
	check(g.is_easy_fight(), "a level 80 hero on floor 3: easy")
	var kills := g.codex.stat("kills")
	g.take_turn()
	check(g.codex.stat("easy_skips") == 0, "off by default")
	g.skip_easy = true
	g.spawn_enemy()
	g.enemy_tier = 0
	g.horde_left = 0
	g.path_offer.clear()
	g.exploring = false
	kills = g.codex.stat("kills")
	g.take_turn()
	check(g.codex.stat("easy_skips") == 1 and g.codex.stat("kills") > kills, "switched on: it falls in one turn, and counts as a kill")
	var h := GameState.new()
	h.codex.path = ""
	h.autosave = false
	h.new_game()
	h.choose_class("Warrior")
	h.floor_num = 25
	h.spawn_enemy()
	check(not h.is_easy_fight(), "bosses are never easy")
	print("STAGE3 SKIP TESTS DONE, failures: ", fails)
	quit()
