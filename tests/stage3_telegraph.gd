extends SceneTree
## Telegraphed attacks: a wind-up always gives you one turn to answer.
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
	g.floor_num = 30
	g.best_floor = 30
	g.in_town = false
	return g

func _initialize() -> void:
	var g := hero()
	g.spawn_enemy()
	g.cfight["turns"] = 7
	Combat.start_windup(g, Combat.HEAVY_MULT)
	check(Combat.winding(g) and Combat.charging(g), "winding up, and this turn it only gathers strength")
	check(Combat.crush_mult(g) == 1.0 and Combat.winding(g), "no big hit on the wind-up turn")
	g.cfight["turns"] = 8
	check(not Combat.charging(g), "the next turn it isn't charging any more")
	check(Combat.crush_mult(g) == Combat.HEAVY_MULT and not Combat.winding(g), "the next hit lands heavy, then the wind-up is spent")
	Combat.start_windup(g, Combat.HEAVY_MULT)
	check(Combat.try_stagger(g) != "" and not Combat.winding(g), "a skill staggers it")
	# Whole turns against a tough Rare monster that never dies
	seed(3)
	var w := hero()
	w.spawn_enemy()
	w.enemy_tier = 3
	w.enemy_is_boss = false
	w.enemy_goblin = false
	var winds := 0
	var resolved := 0
	var same_turn := 0
	var hit_while_charging := 0
	for i in 300:
		w.hero_hp = w.get_max_hp()
		w.enemy_hp = w.enemy_max_hp
		w.events.clear()
		var was_winding := Combat.winding(w)
		w.take_turn()
		var ids: Array = []
		var hits := 0
		for e in w.events:
			if e["type"] == "boss_mechanic":
				ids.append(String(e["id"]))
			if e["type"] == "enemy_hit" and not e.get("minion", false) and not e.get("status", false) and not e.get("hazard", false):
				hits += 1
		if "windup" in ids:
			winds += 1
			if "crush" in ids:
				same_turn += 1
			if hits > 0 and not was_winding:
				hit_while_charging += 1
		if "crush" in ids or "stagger" in ids:
			resolved += 1
		if w.enemy_hp <= 0 or w.in_town or w.enemy_tier != 3:
			w.spawn_enemy()
			w.enemy_tier = 3
			w.enemy_is_boss = false
	check(winds > 3, "Rare monsters wind up now and then (%d)" % winds)
	check(same_turn == 0, "the big hit never lands on the wind-up turn (%d)" % same_turn)
	check(hit_while_charging == 0, "it doesn't attack while gathering strength (%d)" % hit_while_charging)
	check(resolved >= winds - 1, "every wind-up ends in a heavy blow or a stagger (%d of %d)" % [resolved, winds])
	# Auto answers a wind-up with a ready skill
	var a := hero()
	a.spawn_enemy()
	a.enemy_is_boss = false
	a.auto_ability = true
	var acts: Array = a.equipped_actives().filter(func(id): return SkillData.info(id).has("power"))
	check(not acts.is_empty(), "the test hero has a damage skill")
	if not acts.is_empty():
		for id in a.skill_cds:
			a.skill_cds[id] = 0
		a.cfight["turns"] = 5
		Combat.start_windup(a, Combat.HEAVY_MULT)
		a.cfight["windup"] = 6  # it wound up last turn: this is your turn to answer
		a.events.clear()
		a.enemy_hp = a.enemy_max_hp * 50
		a.enemy_max_hp = a.enemy_hp
		a.take_turn()
		var staggered := a.events.any(func(e): return e["type"] == "boss_mechanic" and e["id"] == "stagger")
		check(staggered, "Auto staggers a wind-up when a skill is ready")
	# Common monsters never do
	var c := hero()
	c.spawn_enemy()
	c.enemy_tier = 0
	c.enemy_elite = false
	c.enemy_is_boss = false
	c.cfight["turns"] = Combat.HEAVY_EVERY - 1
	for i in 20:
		Combat.monster_turn(c)
	check(not Combat.winding(c), "common monsters don't wind up")
	print("STAGE3 TELEGRAPH TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
