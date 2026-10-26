extends SceneTree
## Phase 11: races, awakening, transformations, reputation, escaping,
## realms and hidden classes.
## Run: godot --headless --path . --script res://tests/test_phase11.gd

var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)

## A plain monster: a spawn can roll a horde, goblin or Calamity, which you can't run from or spare.
func _plain(g: GameState) -> void:
	g.horde_left = 0
	g.horde_pack = false
	g.enemy_goblin = false
	g.enemy_calamity = 0
	g.enemy_is_boss = false

func hero(race := "Human", cls := "Warrior") -> GameState:
	var g := GameState.new()
	g.autosave = false
	g.codex = Codex.new()
	g.codex.path = ""
	g.appearance["race"] = race
	g.rep = Races.start_rep(race)
	g.new_game()
	g.choose_class(cls)
	return g

func _initialize() -> void:
	GameData.realm_order = []
	# ---------- Races ----------
	check(Races.ORDER.size() == 11 and "Human" in Races.ORDER and not "Golem" in Races.ORDER and not "Merfolk" in Races.ORDER, "12 races with a Human")
	for r in Races.ORDER:
		var inf := Races.info(r)
		check(inf.has("power") and inf["ranks"].size() >= 3 and inf["ranks"].size() <= 5, "race data " + r)
		var lv := 0
		var pw := 0.0
		for rank in inf["ranks"]:
			check(int(rank["level"]) > lv and float(rank["power"]) > pw, "ranks climb " + r)
			lv = int(rank["level"])
			pw = float(rank["power"])
		check(not Races.skins(r).is_empty(), "skins " + r)
		var app := {"race": r, "body": "masc", "skin": Races.skins(r)[0], "hair": "Short", "hair_color": 1, "eyes": 0}
		check(Sprites.hero(app, {})["body"] != null, "sprite " + r)
	var counts := {}
	for r in Races.ORDER:
		counts[Races.ranks(r).size()] = true
	check(counts.size() >= 3, "awakening ranks vary by race")
	for f in Races.FORMS:
		check(Sprites.hero({"race": "Angel" if f == "Fallen Angel" else "Human", "form": f}, {})["body"] != null, "form sprite " + f)

	# ---------- Racial power and awakening ----------
	var a := hero("Angel", "Cleric")
	check(Lineage.power(a) == 0.0 and a.awaken == 0, "starts unawakened")
	Lineage.gain(a, "skill:Holy", 100.0)
	check(Lineage.power(a) >= 1.5, "Holy skills grow Divine Power")
	a.stat_points = 10
	var before := Lineage.power(a)
	Lineage.spend_power(a, 5)
	check(absf(Lineage.power(a) - before - 5 * Races.POWER_POINT) < 0.001 and a.stat_points == 5, "stat points into power are Races.POWER_POINT each")
	check(Lineage.awaken_block(a).begins_with("Reach level"), "awakening needs a level")
	a.level = 40
	a.race_power = 100.0
	check(Lineage.awaken_block(a) == "", "Archangel needs only power and level")
	var hp0 := a.get_max_hp()
	check(Lineage.awaken(a) and a.awaken == 1 and a.appearance["look"] == "wings2", "awakened: second pair of wings")
	check(a.get_max_hp() > hp0, "awakening makes you stronger")
	var d := hero("Dwarf")
	d.level = 30
	d.race_power = 30.0
	check(Lineage.awaken_block(d) == "Find Ancestor's Rune", "dwarf needs a key item")
	Lineage._give_key(d, "Ancestor's Rune")
	check(Lineage.awaken(d) and not "Ancestor's Rune" in d.race_keys, "the key is used up")
	var o := hero("Orc")
	o.level = 30
	o.race_power = 30.0
	check(Lineage.awaken_block(o) == "trial", "orc rank needs a trial")
	check(o.start_race_trial() and o.trial_active and o.trial_kind == "race", "race trial starts")
	o.enemy_hp = 0
	o._enemy_defeated()
	check(o.awaken == 1 and not o.trial_active, "winning the trial awakens")

	# ---------- Transformations ----------
	var v := hero("Human")
	v.enemy_species = "strigoi"   # monster ids, not shown names
	var bitten := false
	for _i in 40000:
		Lineage.on_hit(v)
		if v.form == "Vampire":
			bitten = true
			break
	check(bitten and v.appearance["form"] == "Vampire", "a strigoi bite can make a vampire")
	check(v.effect_value("regen") <= 0.0 and v.effect_value("lifesteal") >= 8.0, "vampires drink, don't regenerate")
	Lineage.start_cure(v)
	check(v.cure_active and Lineage.cure_block(v).ends_with("hunted"), "cure started")
	v.cure_kills = 100
	check(Lineage.cure_block(v) == "" and Lineage.finish_cure(v) and v.trial_kind == "cure", "cure trial")
	v.enemy_hp = 0
	v._enemy_defeated()
	check(v.form == "", "the Elder Vampire's death cures you")
	var w := hero("Beastkin")
	w.enemy_species = "barghest"
	for _i in 40000:
		Lineage.on_hit(w)
		if w.lycan_pending:
			break
	check(w.lycan_pending and w.form == "", "bitten, waiting for the moon")
	w.floor_num = 29
	w.next_floor()
	check(w.form == "Werewolf" and not w.lycan_pending, "the full moon turns you")
	var fa := hero("Angel")
	for _i in 30:
		fa._faith(-2.0)
	check(fa.form == "Fallen Angel" and fa.appearance["form"] == "Fallen Angel", "an angel falls when faith breaks")
	check(not Races.FORMS["Fallen Angel"]["curable"] and Lineage.cure_info(fa).is_empty(), "no cure for the fall")
	check(fa.effect_value("regen") < 1.0, "fallen angels lose the healing light")
	var li := hero("Human", "Mage")
	li.level = 60
	check(Lineage.lich_block(li) != "", "lich needs a lot")
	li.skill_book["shadow_bolt"] = 1
	for i in 3:
		li.active_slots[i] = ""
	for id in SkillData.SKILLS:
		if "Shadow" in SkillData.info(id)["tags"] and SkillData.is_active(id):
			li.skill_book[id] = 5
			li.active_slots[0] = id
			break
	Lineage._give_key(li, "Phylactery")
	check(Lineage.lich_block(li) == "" and Lineage.lich_ritual(li) and li.form == "Lich", "the lich ritual")
	li.hero_hp = 0
	check(Lineage.save_from_death(li) and li.hero_hp == 1 and not Lineage.save_from_death(li), "phylactery saves you once per floor")

	# ---------- Reputation ----------
	var r := hero("Elf")
	check(Lineage.rep(r, "Elf") > 0 and Lineage.rep(r, "Orc") < 0, "own race friendly, rivals hostile")
	var orc0 := Lineage.rep(r, "Orc")
	Lineage.change_rep(r, "Elf", 20.0)
	check(Lineage.rep(r, "Orc") < orc0, "helping a race annoys its rivals")
	check(Races.rep_level(-80.0)[0] == "Hated" and Races.rep_level(95.0)[0] == "Exalted", "rep levels")

	# ---------- Escaping and sparing ----------
	var e := hero("Elf")
	e.floor_num = 20
	e.spawn_enemy()
	_plain(e)
	var c := Lineage.escape_chance(e)
	check(c >= Races.ESCAPE_MIN and c <= Races.ESCAPE_MAX, "escape chance in range")
	e.stats["AGI"] = 200
	check(Lineage.escape_chance(e) == Races.ESCAPE_MAX, "AGI helps you run")
	var f0 := e.fight
	var got := false
	for _i in 20:
		if Lineage.try_escape(e):
			got = true
			break
	check(got and e.fight > f0 and e.feats.get("clean_streak", 0) == 0, "escaped: on to the next fight")
	e.best_floor = 30
	e.go_to_floor(25)
	check(Lineage.escape_block(e) != "" and not Lineage.try_escape(e), "no running from bosses")
	e.floor_num = 21
	e.spawn_enemy()
	_plain(e)
	check(not Lineage.can_spare(e), "can't spare a healthy monster")
	e.enemy_hp = int(e.enemy_max_hp * 0.2)
	var sp := e.enemy_species
	check(Lineage.spare(e) and e.feats["befriended"].has(sp), "spared and befriended")

	# ---------- Realms ----------
	GameData.realm_order = []
	check(GameData.zone_index(251) == 5 and GameData.realm_of(251) == "elf" and GameData.realm_of(250) == "", "default realm order")
	GameData.realm_order = ["demon"]
	check(GameData.realm_of(251) == "demon" and GameData.realm_of(301) == "elf", "chosen realms come first")
	GameData.realm_order = []
	var p := hero("Angel")
	p.best_floor = 250
	p.floor_num = 250
	p.faith = 80.0
	var opts := Realms.portal_options(p)
	check(opts.size() == 3 and not "demon" in opts and opts[0] == "angel", "portals: angels see the Spire first, the Abyss is locked")
	p.floor_num = 249
	p.fight = 3
	p.next_floor()
	check(p.floor_num == 250, "floor 250")
	p.floor_num = 250
	p.next_floor()
	check(p.path_offer.size() >= 2 and String(p.path_offer[0]).begins_with("portal:"), "portals offered at 251")
	var pick: String = p.path_offer[1]
	p.choose_path(pick)
	check(p.realm_order.size() == 1 and p.realm_order[0] == pick.substr(7) and GameData.realm_of(251) == pick.substr(7), "entered the chosen realm")
	check(GameData.zone_for_floor(251)["name"] == Realms.realm_name(pick.substr(7)), "the zone is that realm")
	# Every realm: monsters, art, events, camps
	for id in Realms.IDS:
		GameData.realm_order = [id]
		var g := hero("Human")
		g.realm_order.assign([id])
		g.best_floor = 300
		g.floor_num = 255
		g.spawn_enemy()
		check(GameData.realm_of(g.floor_num) == id and g.enemy_art != "" and Sprites.enemy_by_key(g.enemy_art) != null, "realm monster art " + id)
		for k in 30:
			g.spawn_enemy()
			if g.enemy_people != "":
				break
		check(g.enemy_people == Realms.info(id)["race"], "realm people " + id)
		var rep0 := Lineage.rep(g, Realms.info(id)["race"])
		g.enemy_hp = 0
		g._enemy_defeated()
		check(Lineage.rep(g, Realms.info(id)["race"]) < rep0, "killing their people costs rep " + id)
		Realms.start_realm_event(g)
		check(g.path_offer.size() == 2, "realm event " + id)
		g.gold = 1000
		g.choose_path("revent_yes")
		Realms.start_encounter(g)
		check("talk" in g.path_offer and "attack" in g.path_offer, "encounter " + id)
		g.choose_path("attack")
		check(g.enemy_tier >= Monsters.EPIC and g.enemy_people != "", "attacking makes an elite fight " + id)
		Realms.camp(g)
		check(g.merchant.size() >= 3 and g.merchant_who == Realms.info(id)["race"] and not g.quest.is_empty(), "camp merchant and quest " + id)
		check(Realms.completion(g, id) > 0 and Realms.completion(g, id) <= 100, "completion " + id)
		g.stats["STR"] = 3000
		g.stats["VIT"] = 3000
		g.hero_hp = g.get_max_hp()
		g.path_offer = []
		var f_start := g.floor_num
		seed(1100 + id.hash() % 1000)   # the same path picks every run (QA: failed 1 in 6 unseeded)
		for turn in 300:
			if not g.path_offer.is_empty():
				g.choose_path(g.path_offer.pick_random())
			g.enemy_hp = mini(g.enemy_hp, 1)
			g.enemy_attack = 0
			g.enemy_shield = 0
			g.hero_hp = g.get_max_hp()
			g.take_turn()
		check(g.floor_num > f_start and g.enemy_max_hp > 0, "playing in %s works (floor %d -> %d)" % [id, f_start, g.floor_num])
	GameData.realm_order = []
	# An old save already past floor 250 keeps its realms in place
	var old := hero("Human")
	old.autosave = true
	old.slot = 3
	old.best_floor = 330
	old.floor_num = 320
	old.save_game()
	var od := FileAccess.open(GameState.slot_paths(3)[0], FileAccess.READ)
	var raw: Dictionary = od.get_var()
	od.close()
	raw.erase("lineage")
	var ow := FileAccess.open(GameState.slot_paths(3)[0], FileAccess.WRITE)
	ow.store_var(raw)
	ow.close()
	var old2 := GameState.new()
	old2.slot = 3
	old2.codex = old.codex
	old2.load_game()
	check(old2.realm_order == ["elf", "fairy"] and GameData.realm_of(320) == "fairy", "old deep save: realms filled in (%s)" % str(old2.realm_order))
	GameState.delete_slot(3)
	GameData.realm_order = []
	# Race gear
	var rg := hero("Dwarf")
	var plate := Races.make_race_gear(Races.gear_for("Dwarf")[0], 100, rg._new_id())
	rg.bag.append(plate)
	rg.equip(int(plate["id"]))
	check(rg.equipped.get("Chest", {}).get("name", "") == plate["name"], "a dwarf can wear dwarf gear")
	var rh := hero("Human")
	rh.bag.append(plate)
	rh.equip(int(plate["id"]))
	check(rh.equipped.get("Chest", {}).get("name", "") != plate["name"], "a human can't")

	# ---------- Hidden classes ----------
	var h := hero("Goblin")
	for _i in 5:
		Hidden.on_wheel(h, true)
	check(h.hidden.has("jester") and h.hidden_class == "", "5 wheel wins in a row: Jester is earned, quietly (a surprise until 15, 35 or 60)")
	h.hidden_class = "jester"
	check("Luck" in h.unique_stats(), "Jester's special stat")
	var c0 := h.effect_value("crit")
	h.unique["Luck"] = 50.0
	check(h.effect_value("crit") > c0, "Luck adds crit")
	for _i in 4:
		Hidden.on_wheel(h, true)
	Hidden.on_wheel(h, false)
	check(h.feats["wheel_streak"] == 0, "a loss breaks the streak")
	var gl := hero("Human")
	gl.level = 75
	gl.feats["clean_best"] = 1000
	Hidden.check(gl)
	check(gl.hidden.has("gladiator") and gl.hidden_class == "", "Gladiator earned (the arena trial comes when you take it)")
	Hidden.on_level(gl)
	check("gladiator" in gl.hidden_offer, "level 75: it's on offer")
	check(Hidden.take(gl, "gladiator") and gl.trial_kind == "hidden" and gl.hidden_class == "", "taking it starts the arena trial")
	gl.enemy_hp = 0
	gl._enemy_defeated()
	check(gl.hidden_class == "gladiator" and Hidden.title(gl) == "The Undefeated", "won: The Undefeated at level 75 (%s)" % Hidden.title(gl))
	var cp := hero("Human")
	check(Hidden.closeness(cp, "fool") == 0.0, "no progress yet")
	cp.feats["deaths"] = 125
	check(absf(Hidden.closeness(cp, "fool") - 0.5) < 0.01, "halfway to The Fool")
	# One per account
	var hc := hero("Human")
	hc.hardcore = true
	hc.slot = 2
	hc.best_floor = 500
	Hidden.check(hc)
	check(hc.hidden.has("chosen_hero") and hc.codex.stat("legend_chosen_hero") == 2, "Chosen Hero at floor 500 on Hardcore")

	# ---------- Saving ----------
	var s := hero("Demon")
	s.autosave = true
	s.slot = 3
	s.race_power = 12.5
	s.awaken = 2
	s.form = "Vampire"
	s.rep["Angel"] = -77.0
	s.realm_order.assign(["fairy", "elf"])
	s.hidden["fool"] = true
	s.hidden_class = "fool"
	s.quest = {"realm": "elf", "need": 30, "have": 3}
	s.save_game()
	var s2 := GameState.new()
	s2.slot = 3
	s2.codex = s.codex
	check(s2.load_game(), "loads")
	check(s2.race_power == 12.5 and s2.awaken == 2 and s2.form == "Vampire" and float(s2.rep["Angel"]) == -77.0
		and s2.realm_order == ["fairy", "elf"] and s2.hidden_class == "fool" and int(s2.quest["have"]) == 3, "lineage saved")
	check(GameData.realm_order == ["fairy", "elf"], "loading sets the realm order")
	GameState.delete_slot(3)
	GameData.realm_order = []
	print("PHASE 11 TESTS DONE, failures: ", fails)
	quit(1 if fails > 0 else 0)
