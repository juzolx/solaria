extends SceneTree
## Lists the deepest controls wider than the window (layout overflow finder).
var main
func walk(n: Node, limit: float, depth: int) -> void:
	for c in n.get_children():
		if c is Control and (c as Control).is_visible_in_tree():
			var w := (c as Control).get_combined_minimum_size().x
			if w > limit:
				var deeper := false
				for k in c.get_children():
					if k is Control and (k as Control).is_visible_in_tree() and (k as Control).get_combined_minimum_size().x > limit:
						deeper = true
				if not deeper:
					print("%d  %s  %s  '%s'" % [int(w), c.get_class(), c.get_path(), (c as Object).get("text") if c.get("text") != null else ""])
		walk(c, limit, depth + 1)

func _initialize() -> void:
	GameState.delete_saves()
	Profile.delete()
	var g := GameState.new()
	g.slot = 1
	g.codex.path = ""
	g.appearance = {"body": "masc", "skin": 2, "hair": "Spiky", "hair_color": 6, "eyes": 0, "race": "Human"}
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.save_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is TitleScreen:
			c.queue_free()
	main.play_slot(1)
	main.timer.stop()
	for i in 200:
		main.state.take_turn()
	main.state.equip_best()
	for grp in 4:
		for sub in 6:
			main.show_tab(grp, sub)
			main.refresh()
			await process_frame
			await process_frame
			print("--- tab ", grp, ",", sub)
			walk(main, 600.0, 0)
	GameState.delete_saves()
	Profile.delete()
	quit()
