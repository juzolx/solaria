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
	check(g.get_attack() > atk * 2.0, "a God class is far stronger (%d vs %d)" % [g.get_attack(), atk])
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
			check(Hidden._have(g, String(dd[1])) >= 0, "%s deed key works: %s" % [id, dd[1]])
	for cls in Classes.ORDER:
		for r in ClassTree.roots(cls):
			for c in ClassTree.children(r):
				for f in ClassTree.children(c):
					check(String(ClassTree.node(f)["rank"]) != "God", "no God class inside the %s tree" % cls)
	print("STAGE6 GOD TESTS DONE, failures: ", fails)
	quit()
