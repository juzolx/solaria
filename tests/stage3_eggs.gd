extends SceneTree
## Egg quests: a little care before hatching makes a Cherished pet.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 20
	g.floor_num = 20
	return g

func _initialize() -> void:
	var g := hero()
	Menagerie.give_egg(g, "test")
	var egg: Dictionary = g.eggs[0]
	check(egg.has("quest") and EggQuests.QUESTS.has(String(egg["quest"])), "every egg gets a quest")
	check(EggQuests.text(egg).contains("0/"), "with its progress shown (%s)" % EggQuests.text(egg))
	egg["quest"] = "hunt"
	egg["prog"] = 0
	for i in 20:
		EggQuests.on_kill(g, 0, false)
	check(EggQuests.done(egg), "twenty kills finish a hunt quest")
	var tiers: Array = []
	for i in 30:
		var p := Menagerie.hatch(g, {"quest": "hunt", "prog": 20})
		tiers.append(int(p["tier"]))
		check(p.get("cherished", false), "a done quest hatches Cherished")
	check(tiers.min() >= Monsters.RARE, "Cherished pets are Rare or better (lowest %d)" % tiers.min())
	var q := hero()
	Menagerie.give_egg(q, "test")
	q.eggs[0]["quest"] = "fire"
	q.eggs[0]["prog"] = 0
	EggQuests.on_rest(q)
	check(EggQuests.done(q.eggs[0]), "a campfire rest finishes a fire quest")
	var old := {"id": 1, "floors": 3, "from": "old"}
	check(EggQuests.text(old) != "" and old.has("quest"), "old eggs get a quest too")
	var plain := Menagerie.hatch(g, {})
	check(not plain.get("cherished", false), "no quest done: an ordinary hatch")
	print("STAGE3 EGG TESTS DONE, failures: ", fails)
	quit()
