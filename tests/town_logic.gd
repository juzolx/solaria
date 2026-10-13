extends SceneTree
## Town logic only (also part of run_tests.gd).
var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)

func _initialize() -> void:
	GameState.delete_saves()
	# ---- Town: no fighting inside, contracts, deeds, the inn
	var tg := GameState.new()
	tg.slot = 1
	tg.codex.path = ""
	tg.new_game()
	tg.choose_class("Warrior")
	tg.best_floor = 40
	tg.floor_num = 30
	tg.level = 20
	tg.gold = 100000
	tg.spawn_enemy()
	check(Town.enter(tg) and tg.in_town, "can go to town")
	var hp0 := tg.enemy_hp
	var fl0 := tg.floor_num
	for i in 20:
		tg.take_turn()
	check(tg.enemy_hp == hp0 and tg.floor_num == fl0, "nothing happens while in town")
	Town.refresh_board(tg)
	check(tg.contracts.size() == Town.POSTED, "board has %d postings" % tg.contracts.size())
	var c0: Dictionary = tg.contracts[0]
	check(Town.take(tg, int(c0["id"])), "take a contract")
	c0["kind"] = "hunt"
	c0["monster"] = "Kobold"
	c0["need"] = 2
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(not c0["done"], "contract not done after 1 of 2")
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(c0["done"], "contract done after 2 of 2")
	var bag0 := tg.bag.size()
	var gold0 := tg.gold
	c0["reward"] = {"gold": 100, "item": {"slot": "Weapon", "rarity": 3}}
	check(Town.claim(tg, int(c0["id"])) != "" and tg.bag.size() == bag0 + 1 and tg.gold > gold0, "contract pays gold and a weapon")
	check(String(tg.bag[-1]["type"]) == String(tg.class_info().get("look", {}).get("Weapon", "")), "reward weapon fits the class (%s)" % tg.bag[-1]["type"])
	tg.codex.deeds = ["f25"]
	check(Town.claim_deed(tg, "f25") != "" and tg.codex.deeds.is_empty(), "deed claimed at the Guild Hall")
	tg.hero_hp = 1
	check(Town.rest(tg) and tg.hero_hp == tg.get_max_hp(), "inn heals fully")
	tg.save_game()
	var tg2 := GameState.new()
	tg2.slot = 1
	tg2.load_game()
	check(tg2.in_town and tg2.contracts.size() == tg.contracts.size(), "town state saved")
	Town.leave(tg)
	check(not tg.in_town and tg.enemy_hp > 0, "leaving town starts a fight")
	GameState.delete_saves()
	print("TOWN TESTS DONE, failures: ", fails)
	quit()
