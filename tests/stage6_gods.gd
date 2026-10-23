extends SceneTree
## 2.1 class rules (Juzo, Oct 20): the main route upgrades at 15, 35 and 75; God
## classes are unique classes outside the trees that answer the moment their
## secret deeds are done, and a hero can swap into one right then.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func titan_ready(g: GameState) -> void:
	g.level = 75
	g.class_path.assign(["champion", "weaponmaster", "colossus"])
	g.feats["kills_total"] = 25000
	g.feats["clean_best"] = 2000
	g.codex.stats["champions"] = 20

var _src := ""
## All game code except the data lists themselves (so a key only "exists" if the game really counts it).
func game_source() -> String:
	if _src != "":
		return _src
	var d := DirAccess.open("res://")
	for f in d.get_files():
		if not f.ends_with(".gd") or f == "god_classes.gd":
			continue
		for line in FileAccess.get_file_as_string("res://" + f).split("
"):
			var t := line.strip_edges()
			if f == "hidden.gd" and (t.contains("\"need\":") or t.begins_with("[\"")):
				continue  # hidden.gd's own requirement lists don't count, its counters do
			_src += line + "
"
	return _src

## True if Hidden._have can really read this key: a known special key, a real
## class / evolution / race / boss, or a counter the game actually adds to.
func deed_key_real(key: String) -> bool:
	if key in ["level", "befriended", "befriended_tiers", "wanderer_level", "hc_floor", "demon_top", "evil", "good", "floor", "top_rank", "class_kills"]:
		return true
	if key.begins_with("class:"):
		return key.substr(6) in Classes.ORDER
	if key.begins_with("path:"):
		return not ClassTree.node(key.substr(5)).is_empty()
	if key.begins_with("race:"):
		return key.substr(5) in Races.ORDER
	if key.begins_with("boss:"):
		return not Monsters.by_id(key.substr(5)).is_empty()
	var k := key.substr(6) if key.begins_with("codex:") else key
	return game_source().contains("\"%s\"" % k)

func _initialize() -> void:
	check(ClassTree.PICK_LEVELS == [15, 35, 75], "upgrades at 15, 35 and 75")
	check(Hidden.STAGE_LEVELS == [15, 35, 75], "hidden classes grow at 15, 35 and 75")
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	Hidden.check(g)
	check(g.god_offers.is_empty(), "no God class without the deeds")
	titan_ready(g)
	g.events.clear()
	Hidden.check(g)
	check("god_titan" in g.god_offers and g.events.any(func(e): return e.get("type", "") == "god_offer"), "the deeds done: the Titan answers")
	var atk := g.get_attack()
	check(GodClasses.take(g, "god_titan") and g.god_class == "god_titan", "swap into the Titan")
	check(g.title() == "Titan" and ClassTree.rank_of(ClassTree.current(g)) == "God", "the Titan is the hero's class, God rank (%s)" % g.title())
	check(g.get_attack() > atk, "a God class is stronger (%d vs %d)" % [g.get_attack(), atk])
	check(ClassTree.pick_tier(g) == -1 and ClassTree.options(g).is_empty(), "no more upgrades")
	check(not GodClasses.take(g, "god_titan"), "only once")
	var d := ClassTree.to_save(g)
	var h := GameState.new()
	h.codex.path = ""
	h.autosave = false
	h.choose_class("Warrior")
	ClassTree.from_save(h, d)
	check(h.god_class == "god_titan" and h.title() == "Titan", "a God class survives a save and load")
	# Most God classes only answer a hero who stayed on the main route
	var u := GameState.new()
	u.codex.path = ""
	u.autosave = false
	u.new_game()
	u.choose_class("Warrior")
	titan_ready(u)
	u.hidden_class = "jester"
	Hidden.check(u)
	check(u.god_offers.is_empty(), "the Titan won't answer a hero who took a hidden class")
	# A few answer either way
	check(not bool(GodClasses.info("god_phantom")["main_route"]), "the Phantom answers a hidden-class hero too")
	# Every God class is a real node with art, and none sit in the trees
	for id in GodClasses.LIST:
		var n := ClassTree.node(id)
		check(not n.is_empty() and n.get("god", false) and String(n["rank"]) == "God", "%s is a God class node" % id)
		check(ResourceLoader.exists("res://art/enemies/%s.png" % GodClasses.info(id)["art"]), "%s has reveal art" % id)
		for dd in GodClasses.info(id)["deeds"]:
			check(deed_key_real(String(dd[1])), "%s deed key is real: %s" % [id, dd[1]])
	for cls in Classes.ORDER:
		for r in ClassTree.roots(cls):
			for c in ClassTree.children(r):
				for f in ClassTree.children(c):
					check(String(ClassTree.node(f)["rank"]) != "God", "no God class inside the %s tree" % cls)
	# ---- Owner (Oct 23): a God class is about one rank step above SS, not ~3x
	check(is_equal_approx(float(ClassTree.RANKS["God"]), GodClasses.POWER), "the God rank and GodClasses.POWER agree")
	var sp := GameState.new()
	sp.codex.path = ""
	sp.autosave = false
	sp.new_game()
	sp.choose_class("Warrior")
	titan_ready(sp)
	Hidden.check(sp)
	var atk_s := sp.get_attack()
	var hp_s := sp.get_max_hp()
	var gods0 := sp.codex.stat("gods")
	check(GodClasses.take(sp, "god_titan"), "setup: Titan taken from the Colossus (S)")
	check(is_equal_approx(GodClasses.scale(sp, ClassTree.node("god_titan")), GodClasses.POWER - float(ClassTree.RANKS["S"])), "the God tops an S final up to POWER (scale %.2f)" % GodClasses.scale(sp, ClassTree.node("god_titan")))
	var ratio := float(sp.get_attack()) / float(atk_s)
	check(ratio > 1.03 and ratio < 1.35, "the Titan is a step above its S final, not ~3x (Attack x%.2f)" % ratio)
	check(float(sp.get_max_hp()) / float(hp_s) < 1.35, "and HP too (x%.2f)" % (float(sp.get_max_hp()) / float(hp_s)))
	check(sp.codex.stat("gods") == gods0 + 1, "the Codex counts a God swap once (%d)" % (sp.codex.stat("gods") - gods0))
	var gsrc := GodClasses.bonus_sources(sp)
	check(gsrc.size() == 1 and float((gsrc[0] as Dictionary).get("atk", 1.0)) < 1.5, "one God bonus, no flat x2.4 on top")
	for src in ClassTree.bonus_sources(sp):
		check(src != ClassTree.passive(ClassTree.node("god_titan")), "the God node's own rank passive doesn't stack")
	# An SS final only gets the half step on top
	var ssn := {}
	for r0 in ClassTree.roots("Wanderer"):
		for c0 in ClassTree.children(r0):
			for f0 in ClassTree.children(c0):
				if ClassTree.rank_of(ClassTree.node(f0)) == "SS" and ssn.is_empty():
					ssn = {"path": [r0, c0, f0]}
	if not ssn.is_empty():
		var w := GameState.new()
		w.codex.path = ""
		w.autosave = false
		w.choose_class("Wanderer")
		w.class_path.assign(ssn["path"])
		check(is_equal_approx(GodClasses.scale(w, ClassTree.node("god_sword_god")), GodClasses.MIN_STEP), "an SS final gets half a rank step from a God")
	# A hidden class drops main-route God offers, and take() re-checks the deeds
	var hx := GameState.new()
	hx.codex.path = ""
	hx.autosave = false
	hx.new_game()
	hx.choose_class("Warrior")
	titan_ready(hx)
	Hidden.check(hx)
	check("god_titan" in hx.god_offers, "setup: the Titan answers")
	hx.hidden_offer = ["jester"]
	Hidden._take(hx, "jester")
	check(not "god_titan" in hx.god_offers, "taking a hidden class drops main-route God offers")
	hx.god_offers.append("god_titan")  # e.g. an old save
	check(not GodClasses.take(hx, "god_titan") and hx.hidden_class == "jester", "a hidden-class hero can't swap into a main-route God")
	# Two levels in one go (14 -> 16) keep the level-15 hidden offer open
	var lv := GameState.new()
	lv.codex.path = ""
	lv.autosave = false
	lv.new_game()
	lv.choose_class("Warrior")
	lv.level = 14
	lv.xp = 0
	lv.hidden["jester"] = true
	lv.feats["wheel_best"] = 5
	check(Hidden.block_reason(lv, "jester") == "", "setup: the Jester can be offered (%s)" % Hidden.block_reason(lv, "jester"))
	if Hidden.block_reason(lv, "jester") == "":
		lv.gain_xp(int((GameData.xp_to_next(14) + GameData.xp_to_next(15) + 1) / maxf(0.01, float(lv.race_info().get("xp", 1.0)))))
		check(lv.level >= 16 and "jester" in lv.hidden_offer, "a hidden offer made at 15 survives the same fight's level 16 (level %d, offer %s)" % [lv.level, lv.hidden_offer])
		lv.gain_xp(GameData.xp_to_next(lv.level) * 2)
		check(lv.hidden_offer.is_empty(), "...and fades at the next level-up")
	print("STAGE6 GOD TESTS DONE, failures: ", fails)
	quit()
