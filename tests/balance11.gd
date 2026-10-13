extends SceneTree
## v0.11 balance: every class (and race) plays N turns with Equip Best and auto
## stats, over several seeds. Prints the average level, best floor and deaths.
## godot --headless --path . -s tests/balance11.gd -- classes|races [turns] [seeds]
func run(cls: String, race: String, turns: int, sd: int) -> Dictionary:
	seed(sd)
	var g := GameState.new()
	g.autosave = false
	g.codex = Codex.new()
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 1, "hair": "Short", "hair_color": 1, "eyes": 0, "race": race}
	g.new_game()
	g.choose_class(cls)
	g.class_auto = true
	g.auto_stats = true
	var deaths := 0
	for i in turns:
		var was := g.hero_hp
		var fl := g.floor_num
		g.take_turn()
		for e in g.events:
			if e.get("type", "") == "hero_dead":
				deaths += 1
		g.events.clear()
		g.messages.clear()
		if i % 40 == 0:
			g.equip_best()
	return {"lv": g.level, "best": g.best_floor, "deaths": deaths}

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var mode := a[0] if a.size() > 0 else "classes"
	var turns := int(a[1]) if a.size() > 1 else 6000
	var seeds := int(a[2]) if a.size() > 2 else 3
	var list: Array = Classes.ORDER if mode == "classes" else Races.ORDER
	if a.size() > 3:
		list = Array(a[3].split(","))
	for k in list:
		var lv := 0.0
		var best := 0.0
		var dt := 0.0
		for s in seeds:
			var r := run(k if mode == "classes" else "Warrior", "Human" if mode == "classes" else k, turns, 100 + s)
			lv += r["lv"]
			best += r["best"]
			dt += r["deaths"]
		print("%-10s lv %5.1f  best floor %5.1f  deaths %4.1f" % [k, lv / seeds, best / seeds, dt / seeds])
	quit()
