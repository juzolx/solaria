extends SceneTree
## 2.1 G1-G3: town building levels, the Church and cursed loot, the Trophy Cabin.
## Levels, costs, the floor gate, every benefit, per-town separation, save/load,
## curse drops, cleansing and blessing, and trophies being recorded.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	return g

func _rich(g: GameState) -> void:
	g.gold = 1000000
	g.scrap = 10000
	g.dust = 10000

func _initialize() -> void:
	var p := Profile.new()
	p.reset_progress()
	check(Buildings.levels == p.buildings, "the static levels point at the profile's town")
	var g := _hero()

	# ---- Levels and costs
	for id in Buildings.LIST:
		check(Buildings.level(id) == 1, "%s starts at level 1" % id)
		check(Buildings.benefit(id, 1) != "" and Buildings.benefit(id, 2) != "" and Buildings.benefit(id, 3) != "", "%s says what every level gives" % id)
		check(Town.BUILDINGS.has(id), "%s has a page on the town map" % id)
	check(Buildings.id_for_page(1) == "smith" and Buildings.id_for_page(9) == "church" and Buildings.id_for_page(7) == "", "pages map to buildings (the Mailbox has no levels)")
	check(Buildings.next_cost("inn") == Economy.BUILDING_COST[2], "level 2 costs the level-2 price")
	g.gold = 0
	check(Buildings.blocked(g, p, "inn").begins_with("Not enough gold"), "can't build without gold")
	check(not Buildings.upgrade(g, p, "inn") and Buildings.level("inn") == 1, "a failed build changes nothing")
	_rich(g)
	var gold0 := g.gold
	var scrap0 := g.scrap
	check(Buildings.upgrade(g, p, "inn"), "level 2 builds")
	check(Buildings.level("inn") == 2 and p.buildings["inn"] == 2, "the Inn is level 2 in this town")
	check(g.gold == gold0 - 1500 and g.scrap == scrap0 - 60, "level 2 costs 1500 gold and 60 scrap")
	g.best_floor = 50
	p.max_floor = 50
	check(Buildings.blocked(g, p, "inn").contains("floor %d" % Economy.BUILDING_L3_FLOOR), "level 3 waits for floor 100")
	check(not Buildings.upgrade(g, p, "inn"), "level 3 is gated by depth even with money")
	p.max_floor = 100  # another hero of this town got there
	var dust0 := g.dust
	check(Buildings.upgrade(g, p, "inn") and Buildings.level("inn") == 3, "level 3 builds once the town reached floor 100")
	check(g.dust == dust0 - 40, "level 3 costs dust too")
	check(Buildings.blocked(g, p, "inn").contains("fully built") and not Buildings.upgrade(g, p, "inn"), "3 is the top level")

	# ---- Every benefit applies
	var epic := GameData.make_item("Weapon", 3, 10, g._new_id())
	var up1 := GameData.upgrade_cost(epic)
	var fee1 := GameData.gamble_fee(GameData.make_item("Weapon", 2, 40, g._new_id()))
	var shop_item := GameData.make_item("Chest", 3, 40, g._new_id())
	var shop1 := g.shop_cost(shop_item)
	var cap1 := p.stash_capacity()
	var deed := {"id": "test_deed", "reward": {"gold": 1000}}
	var deed1 := int(Town.deed_reward(deed)["gold"])
	var pet := {"id": 1, "name": "Rex", "hurt": 10, "level": 2}
	var heal1 := Menagerie.heal_cost(pet)
	check(up1 == 20, "an Epic +1 costs 20 scrap at Blacksmith level 1 (unchanged)")
	check(Town.max_taken() == 3, "3 contracts at Bounty Board level 1")
	for id in ["smith", "shop", "tavern", "stash", "bounty", "guild", "clinic", "church", "cabin"]:
		Buildings.upgrade(g, p, id)
		Buildings.upgrade(g, p, id)
		check(Buildings.level(id) == 3, "%s reaches level 3" % id)
	check(GameData.upgrade_cost(epic) == 18, "Blacksmith 3: upgrades 10%% cheaper (got %d)" % GameData.upgrade_cost(epic))
	check(GameData.gamble_fee(GameData.make_item("Weapon", 2, 40, g._new_id())) < fee1, "Tavern 3: the wheel's fee is lower")
	check(g.shop_cost(shop_item) < shop1, "Shop 3: shelf gear is cheaper")
	check(p.stash_capacity() == cap1 + 10, "Vault 3: 10 more spaces")
	check(Town.max_taken() == 5, "Bounty Board 3: carry 5 contracts")
	check(int(Town.deed_reward(deed)["gold"]) == int(round(deed1 * 1.2)), "Guild Hall 3: deeds pay 20% more gold")
	check(Menagerie.heal_cost(pet) == int(round(heal1 * 0.5)), "Clinic 3: healing a pet costs half")
	g.level = 10
	check(Town.rest_cost(g) == 0, "Inn 3: rooms are free")
	var pots := g.potions
	var gold1 := g.gold
	Buildings.on_recruit(g)
	check(g.potions == pots + 3 and g.gold == gold1 + 300, "Inn 3: new recruits bring 3 potions and 300 gold")
	check(Trophies.slots() == 20, "Trophy Cabin 3: 20 trophies on display")
	check(int(Buildings.pick("clinic", Economy.CLINIC_HEAL_FLOORS)) == 6, "Clinic 3: hurt pets rest 6 floors")

	# ---- Per town: another town has its own buildings
	p.save()
	p.switch_town(2)
	check(Buildings.level("smith") == 1 and Buildings.levels == p.buildings, "town 2 starts with level 1 buildings")
	check(GameData.upgrade_cost(epic) == 20, "town 2's Blacksmith charges full price")
	check(Trophies.slots() == 6, "town 2's cabin is small")
	Buildings.upgrade(g, p, "shop")
	check(Buildings.level("shop") == 2, "town 2 builds its own Shop")
	p.switch_town(1)
	check(Buildings.level("smith") == 3 and Buildings.level("shop") == 3, "back home: town 1 kept its levels")

	# ---- Save and load
	p.save()
	var p2 := Profile.load_profile()
	check(p2.town == 1 and Buildings.level("inn") == 3 and Buildings.level("cabin") == 3, "levels survive save and load")
	p2.switch_town(2)
	check(Buildings.level("shop") == 2 and Buildings.level("inn") == 1, "town 2's levels survive too")
	p2.switch_town(1)
	p = p2

	# ---- Cursed loot: drops
	var rare := GameData.make_item("Weapon", 2, 30, g._new_id())
	var b0 := int(rare["bonus"])
	Church.maybe_curse(g, rare, 100.0)
	check(Church.is_cursed(rare), "a Rare drop can come Cursed")
	check(int(rare["bonus"]) > b0, "a Cursed item is stronger")
	check(Church.DOWNS[String(rare["curse"]["down"])]["key"] != Church.UPS[String(rare["curse"]["up"])]["key"], "the downside and the hidden power touch different stats")
	check(GameData.display_name(rare).begins_with("Cursed "), "Cursed is in the name")
	check(ItemText.describe(g, rare).contains("CURSED") and ItemText.describe(g, rare).contains("???"), "the item text shows the curse and hides the power")
	var uniq := GameData.make_unique(GameData.ZONES[0]["boss"]["uniques"][0], 50, g._new_id())
	Church.maybe_curse(g, uniq, 100.0)
	check(not Church.was_cursed(uniq), "Uniques are never cursed")
	var common := GameData.make_item("Weapon", 0, 30, g._new_id())
	Church.maybe_curse(g, common, 100.0)
	check(not Church.was_cursed(common), "Commons are never cursed")
	var n := 0
	for i in 4000:
		var it := GameData.make_item("Chest", 3, 30, 0)
		Church.maybe_curse(g, it)
		if Church.was_cursed(it):
			n += 1
	check(n > 20 and n < 200, "about %.0f%% of Rare+ drops come Cursed (got %d of 4000)" % [Economy.CURSE_CHANCE, n])
	# Real monster drops go through the curse roll
	var src := FileAccess.get_file_as_string("res://game_state.gd")
	check(src.count("Church.maybe_curse(self") >= 3, "monster and boss drops roll for curses")

	# ---- Curses work while worn: a real downside, a hidden upside
	var g2 := _hero()
	g2.equipped["Weapon"] = GameData.make_item("Weapon", 3, 300, g2._new_id())  # big numbers, so +8% shows
	var w := GameData.make_item("Helmet", 2, 10, g2._new_id())
	g2.equipped["Helmet"] = w
	var hp_plain := g2.get_max_hp()
	var atk_plain := g2.get_attack()
	w["curse"] = {"down": "frail", "up": "wrath", "known": false, "tries": 0}
	check(g2.get_max_hp() < hp_plain, "the downside works (-12% max HP)")
	check(g2.get_attack() > atk_plain, "the hidden power works before it's known (+8% Attack)")

	# ---- The Church cleanses
	Buildings.levels["church"] = 1
	_rich(g2)
	check(Church.cleanse_chance(w) == 70, "Church 1: cleansing works 70% of the time")
	var cg := Church.cleanse_gold(w)
	gold0 = g2.gold
	dust0 = g2.dust
	check(not Church.cleanse(g2, w, 99), "a cleanse can fail")
	check(g2.gold == gold0 - cg and g2.dust == dust0 - Economy.CLEANSE_DUST, "a cleanse is paid either way")
	check(bool(w["curse"]["known"]) and Church.is_cursed(w), "a failed cleanse reveals the power but keeps the curse")
	check(Church.cleanse_chance(w) == 85, "every failed try makes the next likelier")
	check(Church.cleanse(g2, w, 0), "a cleanse works")
	check(not Church.is_cursed(w) and Church.was_cursed(w), "the curse is gone")
	check(not GameData.display_name(w).begins_with("Cursed"), "no longer called Cursed")
	check(g2.get_max_hp() == hp_plain, "the downside is gone")
	check(g2.get_attack() > atk_plain, "the hidden power stays")
	check(ItemText.describe(g2, w).contains("Cleansed: +8% Attack"), "the power is shown")
	check(not Church.cleanse(g2, w, 0), "a clean item can't be cleansed again")
	var w2 := GameData.make_item("Chest", 3, 40, g2._new_id())
	Church.curse(w2)
	var cheap := Church.cleanse_gold(w2)
	Buildings.levels["church"] = 3
	check(Church.cleanse_chance(w2) == 90 and Church.cleanse_gold(w2) < cheap, "Church 3: better odds, lower price")
	g2.gold = 0
	check(Church.cleanse_short(g2, w2).begins_with("Not enough gold") and not Church.cleanse(g2, w2, 0), "no gold, no cleanse")
	_rich(g2)

	# ---- Blessing
	check(not Church.can_bless(w2), "lift the curse before blessing")
	var sword := GameData.make_item("Weapon", 2, 300, g2._new_id())
	g2.equipped["Weapon"] = sword
	var atk0 := g2.get_attack()
	check(Church.bless(g2, sword) and sword.get("blessed", false), "the Church blesses an item")
	check(g2.get_attack() > atk0, "a blessed weapon hits a little harder")
	check(not Church.bless(g2, sword), "only one blessing per item")
	check(GameData.display_name(sword).begins_with("Blessed "), "Blessed is in the name")

	# ---- Trophies
	var g3 := _hero()
	check(Trophies.data == p.trophies, "trophies belong to the town you're in")
	g3.floor_num = 25
	g3.best_floor = 25
	g3.spawn_enemy()
	var boss := g3.enemy_species
	g3.enemy_hp = 0
	g3._enemy_defeated()
	check(Trophies.has("boss:" + boss), "a boss kill is recorded")
	var before := Trophies.data.size()
	Trophies.on_boss(g3, boss)
	check(Trophies.data.size() == before, "each trophy is recorded once")
	g3.best_floor = 260
	Trophies.on_floor(g3)
	check(Trophies.has("floor:100") and Trophies.has("floor:250") and not Trophies.has("floor:500"), "depth trophies")
	Trophies.on_find(g3, uniq)
	check(Trophies.has("find:" + String(uniq["def"])), "a Unique find is recorded")
	before = Trophies.data.size()
	Trophies.on_find(g3, GameData.make_item("Weapon", 4, 10, 0))
	check(Trophies.data.size() == before, "plain Legendaries aren't trophies")
	Trophies.on_god(g3, "god_test", "Test God")
	Trophies.on_calamity(g3, 0, "Test Calamity")
	check(Trophies.has("god:god_test") and Trophies.has("calamity:0"), "God classes and Calamities are recorded")
	var atk_t := g3.get_attack()
	for i in 30:
		Trophies.record(g3, "test:%d" % i, "find", "Thing %d" % i)
	check(g3.get_attack() == atk_t, "trophies never give power")
	Buildings.levels["cabin"] = 1
	check(Trophies.shown().size() == 6 and Trophies.all().size() > 6, "Cabin 1 shows 6, the rest wait")
	Buildings.levels["cabin"] = 2
	check(Trophies.shown().size() == 12, "Cabin 2 shows 12")
	check(String(Trophies.shown()[0]["id"]) == "test:29", "the newest is shown first")
	p.save()
	p.switch_town(2)
	check(not Trophies.has("calamity:0"), "another town has its own trophies")
	p.switch_town(1)
	var p3 := Profile.load_profile()
	check(Trophies.has("calamity:0") and p3.trophies.has("boss:" + boss), "trophies survive save and load")

	# ---- The map: new buildings have a spot and placeholder art in one table
	var j := load("res://art/town/town.json") as JSON
	var ids: Array = []
	for s in j.data["spots"]:
		ids.append(String(s["id"]))
	for id in ["church", "cabin"]:
		check(id in ids, "%s has a spot on the town map" % id)
		check(Buildings.ART.has(id), "%s has placeholder art" % id)

	p3.reset_progress()
	p3.save()
	print("stage6_buildings DONE, failures: %d" % fails)
	quit(1 if fails > 0 else 0)
