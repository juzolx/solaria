extends SceneTree
## Rare wanderers: Legendary, leave after a few turns, drop a Legendary.
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
	g.level = 40
	g.floor_num = 30
	g.best_floor = 30
	g.in_town = false
	g.spawn_enemy()
	return g

func _initialize() -> void:
	seed(11)
	var g := hero()
	g.enemy_is_boss = false
	g.horde_left = 0
	Wanderers.make(g, Wanderers.LIST[0])
	check(g.enemy_wanderer and g.enemy_tier == Monsters.LEGENDARY and g.enemy_name == "Black Shuck", "Black Shuck, Legendary")
	check(Monsters.info("Black Shuck").get("lore", "") != "", "it has a bestiary entry")
	g.cfight["turns"] = 4
	check(Wanderers.turns_left(g) == Wanderers.STAY_TURNS - 4, "the countdown")
	check(not Wanderers.wander_off(g), "it stays while there's time")
	g.cfight["turns"] = Wanderers.STAY_TURNS
	check(Wanderers.wander_off(g) and g.enemy_name != "Black Shuck", "then it wanders off and the next monster steps up")
	var k := hero()
	k.enemy_is_boss = false
	k.horde_left = 0
	Wanderers.make(k, Wanderers.LIST[1])
	var legend_before := k.bag.filter(func(it): return int(it["rarity"]) == GameData.LEGENDARY).size()
	k.enemy_hp = 0
	k._enemy_defeated()
	var legend_after := k.bag.filter(func(it): return int(it["rarity"]) == GameData.LEGENDARY).size()
	check(legend_after > legend_before or k.mail.size() > 0, "beating it leaves a Legendary")
	check(k.codex.stat("wanderers") == 1, "counted in the codex")
	check("Lantern-Snuffer" in k.codex.titles(), "and a trophy title")
	var n := 0
	var o := hero()
	for i in 20000:
		o.enemy_is_boss = false
		o.enemy_goblin = false
		o.enemy_grave = false
		o.horde_left = 0
		Wanderers.maybe(o)
		if o.enemy_wanderer:
			n += 1
	check(n > 20000 * 0.002 and n < 20000 * 0.007, "rare: about 1 fight in 250 (%d of 20000)" % n)
	print("STAGE3 WANDERER TESTS DONE, failures: ", fails)
	GameState.delete_saves()
	quit()
