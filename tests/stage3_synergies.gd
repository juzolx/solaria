extends SceneTree
## Team synergies and the Team Strike.
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	for pair in [[2, "Cleric"], [3, "Mage"]]:
		var ph := GameState.new()
		ph.slot = int(pair[0])
		ph.codex.path = ""
		ph.new_game()
		ph.choose_class(pair[1])
		ph.level = 20
		ph.save_game()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Knight")
	g.level = 20
	g.floor_num = 20
	g.in_town = false
	check(Synergies.active(g).is_empty(), "alone: no synergies")
	g.spawn_enemy()
	var solo_hit := g.damage_taken()
	g.set_party([2, 3])
	var on := Synergies.active(g)
	check("shield_prayer" in on, "Knight + Cleric: Shield and Prayer")
	check("three_paths" in on, "three classes: Three Paths")
	check(not "spellweave" in on, "one spell-slinger isn't Spellweave")
	check(Synergies.damage_mult(g) == Synergies.DAMAGE_CUT and Synergies.reward_mult(g) == Synergies.REWARD_BOOST, "their effects are on")
	var gd := g.gold
	g._add_gold(100)
	check(g.gold - gd == 110, "Three Paths: +10% gold")
	check(Synergies.strike_left(g) > 0, "a Team Strike countdown")
	g.cfight["turns"] = Synergies.STRIKE_EVERY
	g.enemy_hp = g.enemy_max_hp * 10
	g.enemy_max_hp = g.enemy_hp
	var hp0 := g.enemy_hp
	var line := Synergies.team_strike(g)
	check(line.contains("TEAM STRIKE") and g.enemy_hp < hp0, "every %d turns the team strikes together" % Synergies.STRIKE_EVERY)
	g.cfight["turns"] = Synergies.STRIKE_EVERY + 1
	check(Synergies.team_strike(g) == "", "not on other turns")
	print("STAGE3 SYNERGY TESTS DONE, failures: ", fails, "  (solo hit %d)" % solo_hit)
	GameState.delete_saves()
	quit()
