extends SceneTree
## How long the first levels take (turns at 1 turn/second).
func _initialize() -> void:
	for cls in ["Warrior", "Mage", "Ranger"]:
		var tot := {}
		for run in 4:
			seed(100 + run)
			var g := GameState.new()
			g.autosave = false
			g.codex = Codex.new()
			g.codex.path = ""
			g.new_game()
			g.choose_class(cls)
			g.class_auto = true
			g.auto_stats = true
			var marks := {}
			for i in 4000:
				g.take_turn()
				g.events.clear()
				g.messages.clear()
				if i % 15 == 0:
					g.equip_best()
				for L in [5, 10, 15, 20]:
					if g.level >= L and not marks.has(L):
						marks[L] = i
			for L in marks:
				tot[L] = int(tot.get(L, 0)) + int(marks[L])
		var line: String = cls
		for L in [5, 10, 15, 20]:
			line += "  L%d: %.1f min" % [L, tot.get(L, 16000) / 4.0 / 60.0]
		print(line)
	quit()
