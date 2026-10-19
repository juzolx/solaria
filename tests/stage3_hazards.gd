extends SceneTree
## Room hazards hit both sides every few turns.
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
	g.floor_num = 20
	g.best_floor = 20
	g.in_town = false
	g.spawn_enemy()
	g.enemy_is_boss = false
	return g

func _initialize() -> void:
	var g := hero()
	g.hazard = "spores"
	g.cfight["turns"] = 2
	check(Hazards.tick(g) == "", "nothing between bursts")
	check(Hazards.turns_left(g) == 1, "the countdown says next turn")
	g.cfight["turns"] = 3
	g.hero_status.clear()
	g.enemy_poison_turns = 0
	var line := Hazards.tick(g)
	check(line != "" and g.enemy_poison_turns >= 3, "spores poison the monster")
	check(g.events.any(func(e): return e["type"] == "hazard"), "a hazard event for the screen")
	var r := hero()
	r.hazard = "rubble"
	r.cfight["turns"] = 6
	var hp0 := r.hero_hp
	var ehp0 := r.enemy_hp
	Hazards.tick(r)
	check(r.hero_hp < hp0 and r.enemy_hp < ehp0, "falling stones hurt both sides")
	# Bosses never get one; ordinary fights sometimes do
	var b := hero()
	b.enemy_is_boss = true
	b.hazard = "embers"
	Hazards.roll(b)
	check(b.hazard == "", "no hazards in boss fights")
	var n := 0
	var o := hero()
	o.horde_left = 0
	o.horde_pack = false
	for i in 3000:
		Hazards.roll(o)
		if o.hazard != "":
			n += 1
	check(n > 3000 * 0.08 and n < 3000 * 0.16, "about 1 fight in 8 has a hazard (%d of 3000)" % n)
	check(o.hazard == "" or o.hazard == Hazards.BY_ZONE[GameData.zone_index(20)], "the hazard belongs to the region")
	# Whole turns
	var w := hero()
	w.hazard = "dark"
	w.cfight["turns"] = 0
	var bursts := 0
	for i in 9:
		w.hero_hp = w.get_max_hp()
		w.enemy_hp = w.enemy_max_hp
		w.events.clear()
		w.take_turn()
		if w.events.any(func(e): return e["type"] == "hazard"):
			bursts += 1
		if w.hazard == "":
			break
	check(bursts == 3, "three bursts in nine turns (%d)" % bursts)
	print("STAGE3 HAZARD TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
