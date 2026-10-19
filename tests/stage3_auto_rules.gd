extends SceneTree
## Auto rules: Autoplay pauses once per thing when a rule fires.
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
	g.floor_num = 25
	g.in_town = false
	g.spawn_enemy()
	check(g.enemy_is_boss, "floor 25 has a boss")
	check(AutoRules.check(g) == "", "no rules on: nothing pauses")
	AutoRules.toggle(g, "stop_boss")
	check(AutoRules.check(g).begins_with("a boss"), "boss rule pauses before the boss")
	check(AutoRules.check(g) == "", "but only once for that boss")
	g.floor_num = 20
	g.spawn_enemy()
	g.enemy_is_boss = false
	AutoRules.toggle(g, "stop_low")
	g.potions = 0
	g.hero_hp = 1
	check(AutoRules.check(g).contains("no potions"), "low HP, no potions: pause")
	g.autoplay = false
	g.auto_rule_seen = ""
	check(AutoRules.check(g) == "", "nothing to pause when Auto is already off")
	print("STAGE3 AUTO RULE TESTS DONE, failures: ", fails)
	quit()
