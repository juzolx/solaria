extends SceneTree
## Stable ids: every monster, boss, zone, item def, set, class node and pet species has a
## permanent id; saves, the Codex and every lookup use ids, names are only shown.
## See claude/stable-ids.md.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(floor_n := 20) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 20
	g.floor_num = floor_n
	return g

var id_re := RegEx.create_from_string("^[a-z][a-z0-9_]*$")

## Every id is snake_case and appears once in its list.
func unique_ids(label: String, ids: Array) -> void:
	var seen := {}
	for id in ids:
		check(id_re.search(String(id)) != null, "%s id is snake_case: '%s'" % [label, id])
		check(not seen.has(id), "%s id used twice: %s" % [label, id])
		seen[id] = true

func _initialize() -> void:
	# ---------- Every id is unique per category ----------
	var monsters: Array = []
	var bosses: Array = []
	var zones: Array = []
	var subs: Array = []
	var uniques: Array = []
	for z in GameData.ZONES:
		zones.append(z["id"])
		for e in z["enemies"]:
			monsters.append(e["id"])
		for s in z["subs"]:
			subs.append(s["id"])
			monsters.append(s["monster"]["id"])
		for b in [z["mid"], z["boss"]]:
			bosses.append(b["id"])
			for u in b["uniques"]:
				uniques.append(u["id"])
	for w in Wanderers.LIST:
		monsters.append(w["id"])
	unique_ids("zone", zones)
	unique_ids("sub-area", subs)
	unique_ids("unique item", uniques)
	unique_ids("creature", monsters + bosses + Calamity.LIST.map(func(cal): return String(cal[1])) + Monsters.SPECIAL.keys())
	check(monsters.size() == 115 and bosses.size() == 20, "110 monsters + 5 wanderers, 20 bosses (%d, %d)" % [monsters.size(), bosses.size()])
	for i in Realms.IDS.size():
		check(GameData.ZONES[Realms.BASE_ZONES + i]["id"] == Realms.IDS[i], "a realm's zone id is its realm id: " + Realms.IDS[i])
	var sets: Array = GameData.SETS.keys() + GameData.EVO_SETS.keys()
	unique_ids("set", sets)
	check(GameData.SET_ORDER.all(func(st): return GameData.SETS.has(st)) and GameData.EVO_SET_ORDER.all(func(st): return GameData.EVO_SETS.has(st)), "set orders list set ids")
	var pieces: Array = []
	for s in sets:
		var info := GameData.set_info(s)
		check(String(info.get("name", "")) != "", "set %s has a name to show" % s)
		for slot in info["pieces"]:
			pieces.append(GameData.piece_id(s, slot))
			check(info["types"].has(slot), "set %s has a look for its %s" % [s, slot])
	unique_ids("set piece", pieces)
	var race_gear: Array = []
	for r in Races.RACE_GEAR:
		for d in Races.RACE_GEAR[r]:
			race_gear.append(d["id"])
	unique_ids("race gear", race_gear)
	unique_ids("item def", uniques + pieces + race_gear + Snik.CURIOS.map(func(cu): return cu["id"]) + Monsters.all_monsters().map(func(mon): return GameData.sig_id(mon)))
	var tree_ids: Array = []
	for id in ClassTree.all_nodes():
		if not ClassTree.node(id).get("god", false):
			tree_ids.append(id)
	unique_ids("class node", tree_ids + GodClasses.LIST.keys())
	check(tree_ids.size() == 182, "182 tree nodes, each with its own frozen id (%d)" % tree_ids.size())
	unique_ids("hidden class", Hidden.CLASSES.keys())
	for id in Hidden.CLASSES:
		check(ClassTree.node(id).is_empty(), "a hidden class id doesn't clash with a class node: " + id)
	unique_ids("traveler", Travelers.LIST.keys())
	unique_ids("achievement", Codex.ACHIEVEMENTS.map(func(ach): return ach["id"]))

	# ---------- Data keyed by id points at things that exist ----------
	for table in Monsters.all_info():
		for id in table:
			check(not Monsters.by_id(id).is_empty(), "monster info key is a monster id: " + id)
	for m in Monsters.all_monsters():
		check(Monsters.info(m).get("lore", "") != "" and Monsters.has_signature(m), "monster %s has info and a Signature" % m)
	for b in Monsters.all_bosses():
		check(bool(Monsters.info(b).get("boss", false)), "boss %s has boss info" % b)
		check(Combat.BOSS_MECHANICS.has(b), "boss %s has its mechanics" % b)
	for k in Combat.BOSS_MECHANICS:
		check(k in Monsters.all_bosses(), "boss mechanics key is a boss id: " + k)
	for k in Combat.ZONE_ELEMENTS:
		check(k in zones, "zone elements key is a zone id: " + k)
	for k in World.ZONE_HAZARDS:
		check(k in zones, "zone hazards key is a zone id: " + k)
	for k in ItemPool.SPECIAL_TYPES:
		check(k in uniques, "special type key is a unique id: " + k)
	for k in Sprites.SET_STYLES:
		check(GameData.SETS.has(k), "set style key is a set id: " + k)
	for k in Sprites.UNIQUE_STYLES:
		check(String(k).trim_prefix("u_") in uniques, "unique style key is u_ + a unique id: " + k)
	for id in Signatures.NAMES:
		check(not ClassTree.node(id).is_empty(), "signature key is a class node id: " + id)
	for id in ClassTree.FINAL_STATS:
		check(not ClassTree.node(id).is_empty(), "FINAL_STATS key is a class node id: " + id)
	for id in ClassTree.MID_EXTRA:
		check(not ClassTree.node(id).is_empty(), "MID_EXTRA key is a class node id: " + id)
	for id in GodClasses.LIST:
		var from := String(GodClasses.LIST[id].get("from", ""))
		check(from == "" or not ClassTree.node(from).is_empty(), "god class %s grows from a class node id (%s)" % [id, from])

	# ---------- Every requirement key that names a boss, monster or class uses a real id ----------
	var keys: Array = []
	for a in Codex.ACHIEVEMENTS:
		keys.append(String(a["key"]))
	for id in Hidden.CLASSES:
		for n in Hidden.CLASSES[id]["need"]:
			keys.append(String(n[1]))
	for id in GodClasses.LIST:
		for d in GodClasses.LIST[id]["deeds"]:
			keys.append(String(d[1]))
	var boss_keys := 0
	for k in keys:
		if k.begins_with("boss:"):
			boss_keys += 1
			check(k.substr(5) in Monsters.all_bosses(), "requirement key names a boss id: " + k)
		elif k.begins_with("path:"):
			check(not ClassTree.node(k.substr(5)).is_empty(), "requirement key names a class node id: " + k)
	check(boss_keys >= 11, "boss requirement keys checked (%d)" % boss_keys)
	for r in Races.INFO:
		for rank in Races.ranks(r):
			var src: Dictionary = rank.get("key", {}).get("from", {})
			if src.has("boss"):
				check(String(src["boss"]) in Monsters.all_bosses(), "awakening key drops from a boss id: " + String(src["boss"]))
	for f in Races.FORMS:
		for b in Races.FORMS[f].get("biters", []):
			check(b in monsters, "%s biters are monster ids: %s" % [f, b])
		var lf: Dictionary = Races.FORMS[f].get("item_from", {})
		if lf.has("boss"):
			check(String(lf["boss"]) in Monsters.all_bosses(), "%s item drops from a boss id" % f)

	# ---------- Kills, the Bestiary and the collection go by id ----------
	var g := hero(12)
	g.spawn_enemy()
	while g.enemy_goblin:
		g.spawn_enemy()
	var sp := g.enemy_species
	check(not Monsters.by_id(sp).is_empty() and g.enemy_name.ends_with(Monsters.name_of(sp)), "the monster on screen is known by id, shown by name (%s / %s)" % [sp, g.enemy_name])
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.codex.kills(sp) == 1 and g.codex.bestiary.has(sp), "the kill is in the Bestiary under its id")
	g.floor_num = 25
	g.best_floor = 25
	g.spawn_enemy()
	check(g.enemy_species == "black_annis" and g.enemy_name == "Black Annis", "the mid boss on 25: id black_annis, shown as Black Annis")
	g.enemy_hp = 0
	g._enemy_defeated()
	check(g.codex.value("mids") == 1 and g.codex.kills("black_annis") == 1, "boss kill counts by id")
	var uq := GameData.make_unique(GameData.ZONES[0]["boss"]["uniques"][0], 50, g._new_id())
	check(uq["def"] == "hrunting" and uq["art"] == "u_hrunting", "a unique carries its def id")
	var uniques_before := g.codex.value("uniques")
	g.codex.found_item(uq)
	check(g.codex.collection.has("hrunting") and g.codex.value("uniques") == uniques_before + 1, "the collection keeps a unique by id")
	var sg := GameData.make_signature("kobold", 10, g._new_id())
	check(sg["def"] == "sig_kobold" and sg["sig_of"] == "kobold" and not Monsters.sig_by_art(sg["art"]).is_empty(), "a Signature carries its def id and its look by monster id")
	var sigs_before := g.codex.value("signatures")
	g.codex.found_item(sg)
	check(g.codex.collection.has("sig_kobold") and g.codex.value("signatures") == sigs_before + 1, "Signatures count by monster id")
	var piece := GameData.make_set_item("tidecaller", "Weapon", 50, g._new_id())
	check(piece["set"] == "tidecaller" and piece["def"] == "tidecaller_weapon" and piece["type"] == "spear", "a set piece carries its set id, def id and look")
	g.equipped["Weapon"] = piece
	check(g.set_counts().get("tidecaller", 0) == 1, "sets count by id")

	# ---------- Renaming a display name keeps everything working ----------
	# A monster: the Codex, pet book and lookups don't care what it's called.
	var kob := Monsters.by_id("kobold").duplicate()
	kob["name"] = "Renamed Mine Imp"
	Monsters.registry()["kobold"] = kob
	var kob_before := g.codex.kills("kobold")
	g.codex.record_kill("kobold", 0, "")
	g.codex.record_kill("kobold", 0, "")
	check(Monsters.name_of("kobold") == "Renamed Mine Imp", "the new name shows")
	check(g.codex.kills("kobold") == kob_before + 2 and g.codex.seen("kobold"), "Codex kills survive the rename")
	check(Monsters.id_of("Renamed Mine Imp") == "kobold" and Monsters.id_of("Kobold") == "", "the id stays, only the name moved")
	var pet := Menagerie.make_pet(g, "kobold", "kobold", 2, "egg")
	check(pet["species"] == "kobold" and pet["name"] == "Renamed Mine Imp", "a new pet is the same species, shown by its new name")
	check(g.codex.pet_book.has("kobold") and not g.codex.found_pet("kobold", 1), "the pet book still knows the species")
	check(Monsters.info("kobold").get("lore", "") != "" and Monsters.has_signature("kobold"), "lore and Signature are found by id")
	# A boss: its achievement and requirement keys don't use its name either.
	var annis := Monsters.by_id("black_annis").duplicate()
	annis["name"] = "The Hag of Dane Hills"
	Monsters.registry()["black_annis"] = annis
	check(g.codex.value("mids") == 1 and g.codex.kills("black_annis") == 1, "boss kills survive the rename")
	var grendel := Monsters.by_id("grendel").duplicate()
	grendel["name"] = "The Mere-Walker"
	Monsters.registry()["grendel"] = grendel
	g.codex.record_kill("grendel", 0, "zone")
	check(g.codex.value("boss:grendel") == 1, "boss:<id> achievement keys still count")
	check(g.codex.check(g).any(func(ach): return ach["id"] == "grendel"), "the Grendel achievement unlocks after the rename")
	Monsters._reg.clear()  # back to the real names
	check(Monsters.name_of("kobold") == "Kobold", "names come back from the data")
	# A class: picks, signatures, special stats and extras go by node id.
	var c := hero(20)
	c.level = 15
	var opts := ClassTree.options(c)
	var pick: Dictionary = opts[0]
	var pid := String(pick["id"])
	var skill_before := SkillData.skill_name(Signatures.id_of(pid))
	ClassTree.node(pid)["name"] = "Renamed Class"
	Signatures._cache.clear()
	check(ClassTree.pick(c, pid), "a renamed class can still be picked by id")
	check(c.class_path.size() == 1 and c.class_path[0] == pid and c.discovered.has(pid), "the pick is saved by id")
	check(ClassTree.title(c) == "Renamed Class", "the class shows its new name")
	check(SkillData.skill_name(Signatures.id_of(pid)) == skill_before, "its signature skill is found by id (%s)" % skill_before)
	check(ClassTree._final_stat("asura", "A Renamed Asura") == "Wrath", "FINAL_STATS keys by id")
	check(not ClassTree.node("skald").get("extra", {}).is_empty(), "MID_EXTRA keys by id")
	var saved := ClassTree.to_save(c)
	var c2 := hero(20)
	ClassTree.from_save(c2, saved)
	check(c2.class_path.size() == 1 and c2.class_path[0] == pid, "the class path loads back by id")
	ClassTree._nodes.clear()  # rebuild with the real names
	ClassTree._roots.clear()
	Signatures._cache.clear()
	check(String(ClassTree.node(pid)["name"]) != "Renamed Class", "class names come back from the data")
	var god_deeds: Array = GodClasses.LIST["god_titan"]["deeds"]
	check(god_deeds.any(func(dd): return String(dd[1]) == "path:weaponmaster"), "god deeds name class nodes by id")
	c.class_path.assign(["champion", "weaponmaster"])
	check(Hidden._have(c, "path:weaponmaster") == 1 and Hidden._have(c, "path:Weaponmaster") == 0, "path: keys match node ids, not names")

	# ---------- Old or unknown keys don't crash ----------
	var cx := Codex.new()
	cx.path = ""
	cx._from({"bestiary": {"Kobold": {"kills": 5, "tiers": [5, 0, 0, 0, 0, 0], "sig": false}, "gone_monster": {"kills": 120, "tiers": [120, 0, 0, 0, 0, 0], "sig": true}},
		"collection": {"Hrunting": "2026-01-01"}, "pet_book": {"Barghest": 3}, "achievements": {"no_such_deed": "2026-01-01"}, "junk": 1})
	check(cx.value("seen") == 0 and cx.value("uniques") == 0 and cx.value("signatures") == 0, "old name keys are simply not counted")
	check(cx.value("mons_100") == 1 and cx.value("top_kills") == 120 and cx.value("mids") == 0, "unknown monster ids don't crash the counters")
	check(cx.kills("Kobold") == 5 and Monsters.name_of("gone_monster") == "gone_monster", "an unknown id shows as itself")
	check(cx.titles() is Array and cx.check(g) is Array, "unknown achievement ids are ignored")
	var odd := hero(20)
	odd.equipped["Chest"] = {"id": 1, "base_name": "Old Thing", "name": "Old Thing", "type": "plate", "slot": "Chest", "stat": "DEF", "rarity": GameData.SET_RARITY,
		"bonus": 5, "level": 0, "floor": 1, "effect": "", "effect_value": 0, "set": "Grendel's Kin"}
	check(odd.set_bonuses() is Array and GameData.set_name_of("Grendel's Kin") == "Grendel's Kin", "an unknown set id gives no bonus and shows as itself")
	odd.pets.append({"id": 99, "name": "Rex", "species": "no_such_beast", "art": "", "tier": 1, "level": 1, "kills": 0, "hurt": 0, "from": "egg"})
	check(Monsters.name_of(String(odd.pets[0]["species"])) == "no_such_beast", "a pet of an unknown species still has a name to show")
	var c3 := hero(20)
	ClassTree.from_save(c3, {"path": ["berserker", "No Such Class", "Berserker"], "god": "Nope"})
	check(c3.class_path.size() == 1 and c3.class_path[0] == "berserker" and c3.god_class == "", "unknown class ids are dropped on load")

	print("STAGE6 ID TESTS DONE, failures: %d" % fails)
	quit()
