extends SceneTree
## Every race with every class (12 x 9 = 108 pairs): how deep each gets in
## TURNS turns (default 3600 = about an hour of play). Flags any race that
## lands far from the average, so no race is a trap pick.
## Run: TURNS=3600 godot --headless --path . --script res://tests/balance_races.gd

func play(race: String, cls: String, turns: int) -> int:
	var g := GameState.new()
	g.autosave = false
	g.codex.path = ""
	g.appearance["race"] = race
	g.new_game()
	g.choose_class(cls)
	var main_stat: String = Classes.CLASSES[cls]["stats"][0]
	for turn in turns:
		g.take_turn()
		g.messages.clear()
		g.events.clear()
		if not g.path_offer.is_empty():
			g.choose_path(g.auto_path())
		if turn % 20 == 0:
			while g.stat_points > 0:
				var side := "STR" if main_stat == "VIT" else "VIT"
				g.spend_point(main_stat if (g.stat(main_stat) <= g.stat(side) * 2) else side, 1)
			if g.class_auto == false:
				g.class_auto = true
				g._check_spec()
			if Lineage.awaken_block(g) == "":
				Lineage.awaken(g)
			g.equip_best()
			for it in g.bag.duplicate():
				if g.bag.size() <= 3:
					break
				if not it.get("locked", false):
					g.salvage(int(it["id"]))
			if g.potions < 3:
				g.buy_potion()
			for slot in g.equipped:
				g.upgrade(int(g.equipped[slot]["id"]))
	return g.best_floor

func _initialize() -> void:
	var turns := int(OS.get_environment("TURNS")) if OS.get_environment("TURNS") != "" else 3600
	var only := OS.get_environment("RACES")
	var per_race := {}
	var all := 0.0
	var n := 0
	for race in Races.ORDER:
		if only != "" and not race in only.split(","):
			continue
		var line := "%-10s" % race
		var sum := 0.0
		for cls in Classes.ORDER:
			seed(7)
			var f := play(race, cls, turns)
			line += " %s %3d" % [cls.substr(0, 3), f]
			sum += f
		per_race[race] = sum / Classes.ORDER.size()
		all += sum
		n += Classes.ORDER.size()
		print(line, "   avg %.1f" % per_race[race])
	var avg := all / maxf(1.0, n)
	print("overall average best floor: %.1f" % avg)
	for race in per_race:
		var off := (float(per_race[race]) - avg) / avg * 100.0
		if absf(off) > 12.0:
			print("CHECK: %s is %+.0f%% from average" % [race, off])
	quit()
