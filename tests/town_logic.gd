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
	c0["reward"] = {"gold": 100, "item": {"slot": "Weapon", "rarity": 3}}
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(not c0["done"] and tg.contracts.has(c0), "contract not done after 1 of 2")
	var mail0 := tg.mail.size()
	Town.on_kill(tg, "Kobold", 0, false, 0)
	check(not tg.contracts.has(c0) and tg.mail.size() > mail0 and tg.mail[mail0]["from"] == "The Bounty Board", "finished contract pays into the Mailbox")
	var letter: Dictionary = tg.mail[mail0]
	check(int(letter["gold"]) > 0 and (letter["items"] as Array).size() == 1, "bounty letter holds gold and a weapon")
	check(String(letter["items"][0]["type"]) == String(tg.class_info().get("look", {}).get("Weapon", "")), "reward weapon fits the class (%s)" % letter["items"][0]["type"])
	var bag0 := tg.bag.size()
	var gold0 := tg.gold
	var saved_bag: Array = tg.bag.duplicate()
	while not tg.bag_full():
		tg.bag.append(GameData.make_item("Helmet", 0, 1, tg._new_id()))
	Mail.collect(tg, String(letter["id"]))
	check(tg.gold > gold0 and tg.bag.size() == tg.bag_capacity() and (letter["items"] as Array).size() == 1, "full bag: gold collected, the weapon waits in the letter")
	tg.bag = saved_bag
	tg.bag_version += 1
	check(Mail.collect(tg, String(letter["id"])) != "" and tg.bag.size() == bag0 + 1 and Mail.is_empty(letter), "collect again: weapon reaches the bag")
	check(Mail.delete_empty(tg) >= 1 and not tg.mail.has(letter), "opened letters can be thrown away")
	tg.codex.deeds = ["f25"]
	var mail1 := tg.mail.size()
	check(Town.claim_deed(tg, "f25") != "" and tg.codex.deeds.is_empty() and tg.mail.size() == mail1 + 1, "old deeds turn into mail")
	var prof := Profile.new()
	var mail2 := tg.mail.size()
	Mail.sync(tg, prof)
	check(tg.mail.size() == mail2 + Mail.NEWS.size() and prof.mail_seen.size() == Mail.NEWS.size(), "news letters delivered")
	Mail.sync(tg, prof)
	check(tg.mail.size() == mail2 + Mail.NEWS.size(), "news letters arrive only once")
	Profile.delete()
	tg.hero_hp = 1
	check(Town.rest(tg) and tg.hero_hp == tg.get_max_hp(), "inn heals fully")
	# Snik the goblin trader and Return Scrolls
	Town.leave(tg)
	tg._make_merchant()
	var kinds: Array = tg.merchant.map(func(e): return String(e["kind"]) + ":" + String(e.get("id", "")))
	check("potions:" in kinds and "scroll:return" in kinds and tg.merchant.size() in [6, 7], "Snik sells gear, potions, a Return Scroll and a scroll (sometimes an egg)")
	tg.bag.append(GameData.make_item("Chest", 0, 10, tg._new_id()))
	var g0 := tg.gold
	var junkv := tg.goblin_junk_value()
	check(junkv > 0 and tg.goblin_buy_junk() == junkv and tg.gold == g0 + junkv and tg.goblin_junk().is_empty(), "Snik buys your junk for carried gold")
	tg.return_scrolls = 1
	tg.fight = 2
	check(Town.blocked(tg) == Town.FLOOR_BLOCK, "can't walk home mid-floor")
	check(Town.use_return(tg) and tg.in_town and tg.return_scrolls == 0, "a Return Scroll gets you home mid-floor")
	# Backpacks: only kept once you get them home
	Town.leave(tg)
	var cap0 := tg.bag_capacity()
	tg.packs_carried = 1
	tg._death_losses()
	check(tg.packs_carried == 0 and tg.bag_capacity() == cap0, "a backpack is lost if you fall")
	tg.packs_carried = 2
	Town.enter(tg)
	check(tg.packs_carried == 0 and tg.bag_capacity() == cap0 + 2 * GameData.PACK_SLOTS, "backpacks brought home grow the bag")
	# The Bank: carry a share down, bank it all on the way home
	tg.gold = 1000
	tg.bank = 0
	tg.carry_pick = 1
	Town.leave(tg)
	check(tg.gold == 250 and tg.bank == 750 and not tg.in_town, "leaving town carries a quarter, banks the rest")
	tg.gold += 40
	Town.enter(tg)
	check(tg.gold == 1040 and tg.bank == 0 and tg.in_town, "coming home banks what you carried")
	tg.carry_pick = 0
	Town.leave(tg)
	check(tg.gold == 0 and tg.bank == 1040, "carry nothing: all gold stays in the Bank")
	tg.fight = 1
	tg.enemy_hp = tg.enemy_max_hp
	check(Town.blocked(tg) == "", "can head home between floors")
	tg.enemy_hp = maxi(0, tg.enemy_max_hp - 1)
	check(Town.blocked(tg) == Town.FLOOR_BLOCK, "can't head home mid-fight")
	tg.go_home_after = true
	tg.next_floor()
	check(tg.in_town and not tg.go_home_after, "asked to go home mid-floor: walk home once it's cleared")
	Town.leave(tg)
	tg.save_game()
	var bk := GameState.new()
	bk.slot = tg.slot
	bk.codex.path = ""
	bk.load_game()
	check(bk.bank == 1040 and bk.gold == 0, "the Bank is saved")
	Town.enter(tg)
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
