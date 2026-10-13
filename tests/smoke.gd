extends SceneTree
## Quick check: every class fights a few thousand turns without errors.
func _initialize() -> void:
	seed(5)
	for cls in Classes.ORDER:
		var g := GameState.new()
		g.autosave = false
		g.codex = Codex.new()
		g.codex.path = ""
		g.new_game()
		g.choose_class(cls)
		g.class_auto = true
		g.auto_stats = true
		for i in 3000:
			g.take_turn()
			g.events.clear()
			g.messages.clear()
		print("%s lv %d floor %d stats %s weak %s" % [cls, g.level, g.floor_num, str(g.stats), str(g.enemy_weak)])
	quit()
