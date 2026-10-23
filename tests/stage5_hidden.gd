extends SceneTree
## Hidden classes (Juzo, Oct 20): earned quietly by how you play, a surprise at
## 15, 35 and 60, open until your next level-up, for good once taken, and three
## clear power steps.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(lv := 10) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = lv
	return g

func level_to(g: GameState, lv: int) -> void:
	while g.level < lv:
		g.gain_xp(GameData.xp_to_next(g.level) - g.xp)

func _initialize() -> void:
	var g := hero(10)
	g.class_auto = false
	g.events.clear()
	for i in 5:
		Hidden.on_wheel(g, true)
	check(g.hidden.has("jester"), "earned by playing")
	check(g.hidden_class == "" and g.hidden_offer.is_empty(), "but nothing is offered yet")
	check(not g.events.any(func(e): return e.get("type", "") in ["hidden_class", "hidden_offer"]), "no popup: it's a surprise")
	level_to(g, 14)
	check(g.hidden_offer.is_empty(), "not at level 14")
	level_to(g, 15)
	check("jester" in g.hidden_offer and g.events.any(func(e): return e.get("type", "") == "hidden_offer"), "level 15: the surprise, beside your evolution")
	check(ClassTree.pick_tier(g) == 0, "the normal choice is there too")
	level_to(g, 16)
	check(g.hidden_offer.is_empty(), "passed by: the offer closes at the next level-up")
	level_to(g, 35)
	check("jester" in g.hidden_offer, "level 35: offered again")
	ClassTree.auto_pick(g)
	check(g.class_path.size() >= 1, "picked a normal evolution meanwhile")
	check("jester" in g.hidden_offer, "the hidden path is still open until the next level")
	var before := g.class_path.size()
	check(Hidden.take(g, "jester") and g.hidden_class == "jester", "take it")
	check(g.title() == "Grand Jester", "at 35 it's already the second step (%s)" % g.title())
	check(ClassTree.pick_tier(g) < 0 and ClassTree.options(g).is_empty(), "the main route is over")
	level_to(g, 75)
	check(g.class_path.size() == before, "no evolution at 75")
	check(g.title() == "The Laughing Fate" and g.events.any(func(e): return e.get("type", "") == "hidden_class"), "level 75: the last step, with its moment")
	check(not Hidden.take(g, "fool"), "can't switch: it's for good")
	# Power steps
	var p1: float = Hidden.stage_bonuses("jester", 1)[0]["atk"]
	var p2: float = Hidden.stage_bonuses("jester", 2)[0]["atk"]
	var p3: float = Hidden.stage_bonuses("jester", 3)[0]["atk"]
	check(p1 > 1.1 and p2 > p1 * 1.2 and p3 > p2 * 1.3, "clear jumps: x%.2f, x%.2f, x%.2f" % [p1, p2, p3])
	for id in Hidden.ORDER:
		check(Hidden.info(id)["stages"].size() == 3, "%s has three steps" % id)
	var a := hero(40)
	var atk0 := a.get_attack()
	a.hidden_class = "gladiator"
	check(a.get_attack() > atk0 * 1.4, "a hidden class hits much harder (%d vs %d)" % [a.get_attack(), atk0])
	# Past 75 a newly earned hidden class never shows up: only God classes answer then
	var late := hero(80)
	late.class_auto = false
	late.feats["deaths"] = 250
	Hidden.check(late)
	check(late.hidden.has("fool") and late.hidden_offer.is_empty(), "earned at 80, still hidden")
	level_to(late, 81)
	check(late.hidden_offer.is_empty(), "not offered after 75")
	level_to(late, 82)
	check(late.hidden_offer.is_empty(), "still not offered")
	# Old saves: a hidden class used to sit on top of your class
	var old := hero(20)
	var d := Lineage.to_save(old)
	d.erase("hidden_v2")
	d["hidden_class"] = "jester"
	Lineage.from_save(old, d)
	check(old.hidden_class == "", "an old save's add-on hidden class is undone (choose it at the next turning point)")
	print("STAGE5 HIDDEN TESTS DONE, failures: ", fails)
	quit()
