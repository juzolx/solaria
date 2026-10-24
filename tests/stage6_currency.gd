extends SceneTree
const TestHero := preload("res://tests/test_hero.gd")
## 2.1 F2 currency merge (Juzo, D3 a): only gold, scrap and dust exist. Every old
## material source pays dust or scrap, every old material cost is paid with them,
## and the new sinks (dust upgrades/rerolls, floor-scaled restock) work.
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

func _initialize() -> void:
	if not TestHero.safe():  # this file writes a hero save: only ever in the test folder
		quit(1)
		return
	# ---- Only three currencies exist
	var g := _hero()
	check(not ("materials" in g), "the hero has no materials any more")
	check(not g.has_method("material_total"), "no material_total()")
	for c in Economy.CURRENCIES:
		check(c in g and typeof(g.get(c)) == TYPE_INT, "%s is a whole number on the hero" % c)
	var gd_consts: Dictionary = (load("res://game_data.gd") as Script).get_script_constant_map()
	for k in ["MATERIALS", "BOSS_MATERIAL_DROP", "SALVAGE_MATERIALS", "SET_PIECE_MATERIALS", "BAG_CRAFT_MATERIALS", "SHOP_RESTOCK_GOLD"]:
		check(not gd_consts.has(k), "GameData.%s is gone" % k)
	check(not (load("res://realms.gd") as Script).get_script_constant_map().has("MATERIALS"), "Realms.MATERIALS is gone")
	for t in Monsters.TIERS:
		check(not (t as Dictionary).has("mats") and (t as Dictionary).has("dust"), "monster tiers pay dust, not materials")
	for s in GameData.SET_ORDER:
		check(not GameData.SETS[s].has("material") and GameData.SETS[s].has("zone"), "set %s belongs to a zone, not a material" % s)
	for a in Codex.ACHIEVEMENTS:
		check(not (a["reward"] as Dictionary).has("mats"), "achievement %s pays no materials" % a["id"])
	for r in Codex.LOGIN_REWARDS:
		check(not (r as Dictionary).has("mats"), "login rewards pay no materials")

	# ---- Conversion: old material sources now pay dust or scrap
	g.floor_num = 25
	g.best_floor = 25
	var d0 := g.dust
	g.spawn_enemy()
	check(g.enemy_is_boss, "floor 25 is a boss")
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.dust >= d0 + Economy.BOSS_DUST[0] and g.dust <= d0 + Economy.BOSS_DUST[1] + 2 * Economy.SALVAGE_DUST[4], "a boss pays 5-8 dust (got %d)" % (g.dust - d0))
	d0 = g.dust
	var epic := GameData.make_item("Weapon", 3, 10, g._new_id())
	g.bag.append(epic)
	g.salvage(int(epic["id"]))
	check(g.dust == d0 + 1, "salvaging Epic gear pays 1 dust")
	d0 = g.dust
	check(g.give_reward({"dust": 4}).contains("dust") and g.dust == d0 + 4, "rewards can pay dust")
	d0 = g.dust
	g.give_reward({"mats": 3})  # a 2.0 letter still in the mailbox
	check(g.dust == d0 + 3, "an old 'mats' reward pays dust instead of crashing")
	check(Mail.summary({"gold": 0, "scrap": 0, "potions": 0, "extra": {"mats": 2}, "items": []}) == "2 dust", "old mail shows its materials as dust")
	var s0 := g.scrap
	g.floor_num = 30
	g.horde_left = 1
	g.horde_pack = false
	g._finish_horde()
	check(g.scrap >= s0 + Economy.CHEST_SCRAP[0] * Economy.MAT_TO_SCRAP and g.scrap <= s0 + Economy.CHEST_SCRAP[1] * Economy.MAT_TO_SCRAP + 2 * GameData.SCRAP_VALUES[4], "a horde chest pays 8-12 scrap (plain chest, not materials)")
	d0 = g.dust
	World.champion_reward(g)
	check(g.dust >= d0 + Economy.CHAMPION_DUST[0], "a Champion's chest pays dust")
	d0 = g.dust
	var box := g.use_scroll("box")
	check(box != "", "the Mystery Box still opens")
	check(not box.contains("material"), "the Mystery Box never mentions materials")
	d0 = g.dust
	g.raid_reward()
	check(g.dust > d0, "the raid reward pays dust")

	# ---- Every former material cost is payable with scrap and dust
	var c := _hero()
	c.best_floor = 250
	c.dust = 0
	c.scrap = 0
	check(c.set_block_reason("grendels_kin").contains("dust"), "a set piece needs dust")
	for s in GameData.SET_ORDER:
		if not Economy.set_zone_reached(c, s):
			check(c.set_block_reason(s) == "Reach its zone first", "set %s waits for its zone" % s)
			continue
		c.dust = Economy.set_piece_dust(s)
		c.scrap = GameData.SET_PIECE_SCRAP
		c.bag.clear()
		check(c.set_block_reason(s) == "", "set %s can be paid with dust and scrap (%s)" % [s, c.set_block_reason(s)])
		c.craft_set_piece(s, String(GameData.SETS[s]["pieces"].keys()[0]))
		check(c.bag.size() == 1 and c.dust == 0 and c.scrap == 0, "set %s took exactly its dust and scrap" % s)
	check(Economy.set_piece_dust("pact_of_the_abyss") > Economy.set_piece_dust("grendels_kin"), "deeper sets cost more dust")
	var reached := 0
	for s in ["grendels_kin", "hels_shroud", "tidecaller", "muspel_forge", "titanborn"]:
		if Economy.set_zone_reached(c, s):
			reached += 1
	check(reached == 5, "best floor 250 has reached all five base zones (%d)" % reached)
	var fresh := _hero()
	check(Economy.set_zone_reached(fresh, "grendels_kin") and not Economy.set_zone_reached(fresh, "titanborn"), "a new hero can only craft the first zone's set")
	c.scrap = GameData.bag_craft_scrap(c.bag_level)
	var cap := c.bag_capacity()
	check(c.bag_craft_block_reason() == "", "a bigger bag needs only scrap")
	c.craft_bag()
	check(c.bag_capacity() > cap and c.scrap == 0, "crafting a bag spends just scrap")
	check(GameData.bag_craft_scrap(0) == Economy.BAG_CRAFT_SCRAP + Economy.MAT_TO_SCRAP * Economy.BAG_CRAFT_MATS, "the bag's old material part became scrap")

	# ---- Dust sinks: top upgrades, rerolls, skills
	var u := _hero()
	var w := GameData.make_item("Weapon", 3, 10, u._new_id())
	w["level"] = 4
	u.bag.append(w)
	check(Economy.upgrade_dust(w) == 0, "upgrading to +5 costs no dust")
	u.scrap = 10000
	u.dust = 0
	u.upgrade(int(w["id"]))
	check(int(w["level"]) == 5, "+5 with scrap only")
	check(Economy.upgrade_dust(w) == Economy.UPGRADE_DUST_STEP, "+6 costs dust")
	u.upgrade(int(w["id"]))
	check(int(w["level"]) == 5, "no dust, no +6")
	u.dust = 100
	u.upgrade(int(w["id"]))
	check(int(w["level"]) == 6 and u.dust == 100 - Economy.UPGRADE_DUST_STEP, "+6 spends dust")
	var total := 0
	var probe := w.duplicate()
	for lv in range(5, GameData.MAX_UPGRADE):
		probe["level"] = lv
		total += Economy.upgrade_dust(probe)
	check(total == 30, "+6 to +10 costs 30 dust in all (%d)" % total)
	u.dust = 0
	var rare := GameData.make_item("Chest", 2, 10, u._new_id())
	u.bag.append(rare)
	u.reroll(int(rare["id"]))
	check(int(rare["rarity"]) == 2 and u.scrap == 10000 - GameData.upgrade_cost({"level": 4, "rarity": 3}) - GameData.upgrade_cost({"level": 5, "rarity": 3}), "a Rare reroll needs dust too")
	u.dust = Economy.reroll_dust(rare)
	u.reroll(int(rare["id"]))
	check(u.dust == 0, "a Rare reroll spends its dust")
	var sk := String(u.active_slots[0])
	var cost := SkillData.craft_cost(sk, u.skill_rank(sk))
	u.dust = cost
	check(u.craft_skill(sk) and u.dust == 0, "dust ranks up a skill")

	# ---- Gold sink: restocking scales with depth
	var r := _hero()
	r.best_floor = 1
	var cheap := r.restock_cost()
	r.best_floor = 100
	var deep := r.restock_cost()
	check(cheap <= 50 and deep >= 900, "restock: about 40 gold at floor 1, about 1,000 at floor 100 (%d, %d)" % [cheap, deep])
	r.gold = deep
	r.paid_restock()
	check(r.gold == 0, "a paid restock takes its gold")
	r.gold = deep - 1
	r.paid_restock()
	check(r.gold == deep - 1, "no restock without the gold")

	# ---- A save with 2.0 keys (materials) loads without trouble
	var sv := _hero()
	sv.autosave = true
	sv.slot = 7
	sv.dust = 12
	sv.save_game()
	var path: String = sv.save_paths()[0]
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = f.get_var()
	f.close()
	data["materials"] = [5, 5, 5, 0, 0, 0, 0, 0, 0, 0]
	data["mystery_old_key"] = {"x": 1}
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_var(data)
	f.close()
	var ld := GameState.new()
	ld.codex.path = ""
	ld.slot = 7
	check(ld.load_game() and ld.dust == 12, "a save with old material keys still loads")
	GameState.delete_slot(7)

	# ---- Realm sets count only once this hero chose that realm
	var rs := _hero()
	rs.best_floor = 260
	var set_for := func(realm: String) -> String:
		for sid in GameData.SETS:
			if int(GameData.SETS[sid]["zone"]) == Realms.zone_for_id(realm):
				return String(sid)
		return ""
	var dwarf_set: String = set_for.call("dwarf")
	var elf_set: String = set_for.call("elf")
	if dwarf_set != "" and elf_set != "":
		rs.realm_order = []
		check(not Economy.set_zone_reached(rs, dwarf_set) and not Economy.set_zone_reached(rs, elf_set), "no realm set before a realm is chosen")
		rs.realm_order = ["dwarf"]
		check(Economy.set_zone_reached(rs, dwarf_set) and not Economy.set_zone_reached(rs, elf_set), "only the chosen realm's set opens")
	else:
		check(false, "realm sets exist for the dwarf and elf realms")

	# ---- Bought gear salvages for scrap only (no gold -> dust)
	var by := _hero()
	by.gold = 10000000
	var found_epic := GameData.make_item("Feet", 3, 40, by._new_id())
	by.bag.clear()
	by.bag.append(found_epic.duplicate(true))
	var bought := found_epic.duplicate(true)
	bought["id"] = by._new_id()
	bought["bought"] = true
	by.bag.append(bought)
	check(Economy.salvage_dust(found_epic) == Economy.SALVAGE_DUST[3] and Economy.salvage_dust(bought) == 0, "a found Epic gives dust, a bought one doesn't")
	by.dust = 0
	by.salvage(int(bought["id"]))
	check(by.dust == 0, "salvaging bought gear gives no dust")
	by.salvage(int(by.bag[0]["id"]))
	check(by.dust == Economy.SALVAGE_DUST[3], "salvaging found Epic gear still gives dust")
	by.shop.clear()
	by.shop.append(GameData.make_item("Feet", 3, 40, by._new_id()))
	check(by.buy_shop(0) and bool(by.bag[-1].get("bought", false)), "shop purchases are marked bought")

	print("STAGE6 CURRENCY TESTS DONE, failures: ", fails)
	quit()
