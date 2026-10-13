extends SceneTree
func _initialize() -> void:
	seed(9)
	var g := GameState.new()
	g.autosave = false
	g.codex = Codex.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	g.auto_stats = true
	var crush := 0
	var stag := 0
	var wind := 0
	for i in 20000:
		var was_boss := g.enemy_is_boss
		g.take_turn()
		if g.enemy_is_boss and not was_boss:
			print("boss ", g.enemy_name, " ", g.boss_mechanics)
		for e in g.events:
			if e.get("type", "") == "boss_mechanic":
				match String(e["id"]):
					"crush": crush += 1
					"stagger": stag += 1
					"windup": wind += 1
		g.events.clear()
		g.messages.clear()
		if i % 40 == 0:
			g.equip_best()
	print("windups %d crushes %d staggers %d floor %d" % [wind, crush, stag, g.best_floor])
	quit()
