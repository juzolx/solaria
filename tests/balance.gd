extends SceneTree

func play(greedy: bool, turns: int, cls: String) -> String:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var g := GameState.new()
	g.new_game()
	if cls != "":
		g.choose_class(cls)
	var out := ""
	var deaths := 0
	for turn in turns:
		g.take_turn()
		for m in g.messages:
			if m.contains("You were defeated") or m.contains("too strong"):
				deaths += 1
		g.messages.clear()
		g.events.clear()
		if turn % 20 == 0:
			for item in g.bag.duplicate():
				var slot: String = item["slot"]
				var cur := 0
				if g.equipped.has(slot):
					cur = GameData.item_power(g.equipped[slot])
				if GameData.item_power(item) > cur:
					g.equip(int(item["id"]))
			while g.bag.size() > 3:
				g.salvage(int(g.bag[0]["id"]))
			if g.potions < 3:
				g.buy_potion()
			if greedy:
				for slot in g.equipped:
					g.upgrade(int(g.equipped[slot]["id"]))
					if GameData.can_reroll(g.equipped[slot]):
						g.reroll(int(g.equipped[slot]["id"]))
			g.messages.clear()
		g.events.clear()
		if turn + 1 in [600, 3600, 10800, 36000]:
			out += "  %dm: floor %d lv %d" % [(turn + 1) / 60, g.floor_num, g.level]
	return out

func _initialize() -> void:
	for cls in ["", "Warrior", "Archer", "Mage"]:
		for sd in 1:
			seed(100 + sd)
			print("%-8s casual:" % (cls if cls != "" else "none"), play(false, 36000, cls))
			seed(100 + sd)
			print("%-8s greedy:" % (cls if cls != "" else "none"), play(true, 36000, cls))
	quit()
