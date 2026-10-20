extends SceneTree
## Next update: heroes at home bring things back; team presets live in the town.
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _hero(n: int, cls: String, lvl: int) -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.slot = n
	g.new_game()
	g.choose_class(cls)
	g.level = lvl
	g.hero_name = cls
	g.save_game()

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1
	_hero(2, "Trickster", 40)
	_hero(3, "Warrior", 40)
	var g := GameState.new()
	g.codex.path = ""
	g.slot = 1
	g.new_game()
	g.choose_class("Ranger")
	g.floor_num = 60
	Bench.refresh(g)
	check(g.bench_roster.size() == 2, "two heroes at home (%d)" % g.bench_roster.size())
	check(float(Bench.rate("Trickster")["gold"]) > float(Bench.rate("Warrior")["gold"]), "Tricksters bring more gold")
	check(float(Bench.rate("Warrior")["scrap"]) > float(Bench.rate("Trickster")["scrap"]), "Warriors bring more scrap")
	g.in_town = false
	for i in 400:
		Bench.on_kill(g)
	check(int(g.bench_haul.get("gold", 0)) > 0 and int(g.bench_haul.get("scrap", 0)) > 0, "they find gold and scrap while you fight")
	g.in_town = true
	var before := int(g.bench_haul["gold"])
	Bench.on_kill(g)
	check(int(g.bench_haul["gold"]) == before, "nothing while you're in town")
	var gold0 := g.gold
	var line := Bench.collect(g)
	check(g.gold == gold0 + before and line != "" and g.bench_haul.is_empty(), "paid out at home")
	g.set_party([2])
	check(g.bench_roster.size() == 1 and int(g.bench_roster[0]["slot"]) == 3, "a hero in your team isn't at home")
	g.hardcore = true
	Bench.refresh(g)
	check(g.bench_roster.is_empty(), "Hardcore heroes get no help")
	var p := Profile.new()
	p.presets[0] = {"slots": [1, 2]}
	p.save()
	p.switch_town(2)
	check(p.presets[0].is_empty(), "presets belong to a town")
	p.switch_town(1)
	check(p.presets[0].get("slots", []) == [1, 2], "and come back with it")
	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1
	print("STAGE5 TEAM TESTS DONE, failures: ", fails)
	quit()
