extends SceneTree
## More hidden classes (Juzo, Oct 20): race-only and class-only secrets, and the
## requirement keys race:, class:, path:, codex:, good, floor, top_rank.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(cls := "Warrior", race := "Human", lv := 10) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.appearance["race"] = race
	g.choose_class(cls)
	g.level = lv
	return g

const KEYS := ["level", "befriended", "befriended_tiers", "wanderer_level", "hc_floor", "demon_top", "evil", "good", "floor", "top_rank", "class_kills"]
const FEATS := ["kills_total", "goblins", "skill_kills", "skill_kills_elite", "boss_skill_finish", "burn_kills", "burn_boss", "clean_best",
	"deaths", "potions_drunk", "potions_crafted", "wheel_best", "sure_escapes", "confuses", "trial"]

func _initialize() -> void:
	check(Hidden.ORDER.size() >= 30, "at least 30 hidden classes (%d)" % Hidden.ORDER.size())
	check(Hidden.ORDER.size() == Hidden.CLASSES.size(), "every class is in ORDER")
	var tiers := [0, 0, 0, 0]
	for id in Hidden.ORDER:
		var c := Hidden.info(id)
		check(not c.is_empty(), "%s exists" % id)
		tiers[int(c["tier"])] += 1
		check(c["stages"].size() == 3 and c["stage_bonus"].size() == 3, "%s has 3 stages and 3 bonuses" % id)
		check(String(c.get("rumor", "")) != "" and String(c.get("lore", "")) != "", "%s has lore and a rumor" % id)
		check(not (c["need"] as Array).is_empty(), "%s has requirements" % id)
		for n in c["need"]:
			var k := String(n[1])
			var ok: bool = k in KEYS or k in FEATS or k.begins_with("boss:") or k.begins_with("race:") or k.begins_with("class:") \
				or k.begins_with("path:") or k.begins_with("codex:")
			check(ok, "%s: unknown requirement key %s" % [id, k])
			if k.begins_with("race:"):
				check(Races.ORDER.has(k.substr(5)), "%s: real race %s" % [id, k])
			if k.begins_with("class:"):
				check(Classes.CLASSES.has(k.substr(6)), "%s: real class %s" % [id, k])
			if k.begins_with("path:"):
				var found := false
				for nd in ClassTree.all_nodes().values():
					if String(nd.get("name", "")) == k.substr(5):
						found = true
				check(found, "%s: real evolution %s" % [id, k])
		var b: Array = c["stage_bonus"]
		check(b[2].size() >= 1 and b[1].size() >= 1, "%s has a specialty at each step" % id)
	check(tiers[1] >= 12 and tiers[2] >= 11 and tiers[3] >= 5, "a spread of tiers: %s" % str(tiers))

	# A race-only class: an Elf earns it, a Human with the same deeds does not
	var elf := hero("Ranger", "Elf")
	var hum := hero("Ranger", "Human")
	for g in [elf, hum]:
		g.codex.stats["traps_spotted"] = 30
		g.feats["befriended"] = {"a": true, "b": true, "c": true, "d": true, "e": true}
		g.events.clear()
	Hidden.check(elf)
	Hidden.check(hum)
	check(elf.hidden.has("moon_sentinel"), "an Elf earns the Moon Sentinel")
	check(not hum.hidden.has("moon_sentinel"), "a Human with the same deeds does not")
	check(elf.hidden_class == "" and elf.hidden_offer.is_empty(), "banked quietly: no hidden_class, no offer")
	check(not elf.events.any(func(e): return e.get("type", "") in ["hidden_class", "hidden_offer"]), "no popup, it's a surprise")

	# Another race, and a class-only one
	var orc := hero("Warrior", "Orc")
	orc.codex.stats["hordes"] = 10
	orc.feats["clean_best"] = 100
	Hidden.check(orc)
	check(orc.hidden.has("warchief") and not orc.hidden.has("moon_sentinel"), "an Orc earns the Warchief")
	var elf2 := hero("Warrior", "Elf")
	elf2.codex.stats["hordes"] = 10
	elf2.feats["clean_best"] = 100
	Hidden.check(elf2)
	check(not elf2.hidden.has("warchief"), "an Elf cannot be a Warchief")

	var kn := hero("Knight", "Human")
	var wa := hero("Warrior", "Human")
	for g in [kn, wa]:
		g.faith = -60.0
		g.feats["kills_total"] = 1500
		Hidden.check(g)
	check(kn.hidden.has("fallen_knight"), "a Knight turned evil earns the Fallen Knight")
	check(not wa.hidden.has("fallen_knight"), "a Warrior turned evil does not")

	# Evolution-bound: only after taking that path
	var rg := hero("Trickster", "Human", 35)
	rg.level = 35
	rg.feats["skill_kills_elite"] = 40
	rg.feats["clean_best"] = 150
	Hidden.check(rg)
	check(not rg.hidden.has("quiet_death"), "Quiet Death needs the Assassin path")
	rg.class_path.append("assassin")
	check(Hidden._have(rg, "path:Assassin") == 1 and Hidden._have(rg, "path:Paladin") == 0, "path: checks your evolutions")
	Hidden.check(rg)
	check(rg.hidden.has("quiet_death"), "taking the Assassin path earns it")

	# Alignment, floor, rank
	var an := hero("Cleric", "Angel", 35)
	an.faith = 85.0
	check(Hidden._have(an, "good") == 85 and Hidden._have(an, "evil") == -85, "good and evil read your faith")
	an.best_floor = 260
	check(Hidden._have(an, "floor") == 260, "floor reads your best floor")
	check(Hidden._have(an, "top_rank") == 0, "not awakened to the top")
	an.awaken = Races.ranks("Angel").size()
	check(Hidden._have(an, "top_rank") == 1, "top rank")
	check(Hidden._have(an, "codex:spared") == 0, "codex counters start empty")
	an.codex.stats["spared"] = 61
	check(Hidden._have(an, "codex:spared") == 61, "codex: reads the account counter")

	# Taking one works, and its steps grow
	var w := hero("Warrior", "Orc", 15)
	w.hidden["warchief"] = true
	w.hidden_offer = ["warchief"]
	check(Hidden.take(w, "warchief") and w.hidden_class == "warchief", "take a new class")
	var s1 := Hidden.stage_text("warchief", 1)
	var s3 := Hidden.stage_text("warchief", 3)
	check(s1 != "" and s3 != "" and s1 != s3, "stage text grows: %s | %s" % [s1, s3])
	print("STAGE5 HIDDEN MORE TESTS DONE, failures: ", fails)
	quit()
