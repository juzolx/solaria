extends SceneTree
## Smarter Auto: doors by what the reader knows; a potion before a blow that would kill.
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
	g.choose_class("Ranger")
	g.class_branch = "wayfinder"
	g.level = 30
	g.floor_num = 20
	g.in_town = false
	check(Halls.team_sense(g) == 3, "a Wayfinder reads every door")
	g.doors = ["elite", "rest", "fight"]
	g.door_traps = [false, false, false]
	var picks := {}
	g.hero_hp = int(g.get_max_hp() * 0.3)
	for i in 20:
		picks[g.auto_door()] = true
	check(picks.size() == 1 and picks.has(GameState.DOOR_KEYS[1]), "hurt: Auto takes the campfire")
	g.hero_hp = g.get_max_hp()
	picks.clear()
	for i in 20:
		picks[g.auto_door()] = true
	check(picks.size() == 1 and picks.has(GameState.DOOR_KEYS[0]), "healthy: Auto takes the elite room")
	g.doors = ["fight", "elite", "treasure"]
	picks.clear()
	for i in 20:
		picks[g.auto_door()] = true
	check(picks.size() == 1 and picks.has(GameState.DOOR_KEYS[2]), "treasure beats an elite")
	# No reader: blind like you
	var b := GameState.new()
	b.codex.path = ""
	b.autosave = false
	b.new_game()
	b.choose_class("Warrior")
	b.doors = ["elite", "rest", "fight"]
	picks.clear()
	for i in 60:
		picks[b.auto_door()] = true
	check(picks.size() == 3, "without a reader Auto picks blind")
	# A potion before a telegraphed blow that would kill
	var p := GameState.new()
	p.codex.path = ""
	p.autosave = false
	p.new_game()
	p.choose_class("Warrior")
	p.level = 20
	p.floor_num = 20
	p.in_town = false
	p.spawn_enemy()
	p.auto_ability = false
	p.auto_potion = true
	p.potions = 3
	p.auto_potion_at = 0.0  # only the wind-up rule can drink
	p.cfight["turns"] = 4
	Combat.start_windup(p, Combat.HEAVY_MULT)
	p.hero_hp = maxi(1, int(p.damage_taken() * 1.5))
	p.enemy_hp = p.enemy_max_hp * 20
	p.enemy_max_hp = p.enemy_hp
	p.take_turn()
	check(p.potions == 2, "Auto drinks before the heavy blow lands (%d potions left)" % p.potions)
	print("STAGE3 AUTO TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
