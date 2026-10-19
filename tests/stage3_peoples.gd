extends SceneTree
## Friendly peoples may let you pass, with a gift.
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
	g.level = 30
	g.floor_num = 260
	g.best_floor = 260
	g.in_town = false
	g.spawn_enemy()
	return g

func _initialize() -> void:
	var g := hero()
	var passes := 0
	for i in 400:
		g.enemy_people = "Elf"
		g.enemy_is_boss = false
		g.horde_left = 0
		g.rep["Elf"] = 95.0  # Exalted
		Peoples.on_spawn(g)
		if g.enemy_peaceful:
			passes += 1
	check(passes > 400 * 0.55 and passes < 400 * 0.85, "Exalted: most of them let you pass (%d of 400)" % passes)
	g.rep["Elf"] = -70.0
	var hostile := 0
	for i in 200:
		g.enemy_people = "Elf"
		Peoples.on_spawn(g)
		if g.enemy_peaceful:
			hostile += 1
	check(hostile == 0, "a race that hates you never steps aside")
	g.enemy_people = "Elf"
	g.enemy_peaceful = true
	g.rep["Elf"] = 70.0
	var fight0 := g.fight
	var gold0 := g.gold
	var pots0 := g.potions
	var rep0 := float(g.rep["Elf"])
	g.take_turn()
	check(not g.enemy_peaceful and (g.fight != fight0 or g.floor_num != 260), "they step aside and you move on")
	check(g.gold > gold0 or g.potions > pots0, "with a gift")
	check(float(g.rep.get("Elf", 0.0)) > rep0, "and they like you a bit more")
	print("STAGE3 PEOPLES TESTS DONE, failures: ", fails)
	quit()
