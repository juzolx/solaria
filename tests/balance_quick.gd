extends SceneTree

func play(cls: String, main_stat: String, turns: int) -> String:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var g := GameState.new()
	g.autosave = false
	g.codex.path = ""
	g.new_game()
	g.choose_class(cls)
	if OS.get_environment("PARTY") != "":
		for pair in [[2, "Cleric"], [3, "Knight"]]:
			var ph := GameState.new()
			ph.slot = int(pair[0])
			ph.codex.path = ""
			ph.new_game()
			ph.choose_class(pair[1])
			ph.save_game()
		g.slot = 1
		g.set_party([2, 3])
	var out := ""
	for turn in turns:
		g.take_turn()
		g.messages.clear()
		g.events.clear()
		if turn % 20 == 0:
			# 2 of every 3 points into the main stat, 1 into VIT (or STR for VIT builds)
			while g.stat_points > 0:
				var side := "STR" if main_stat == "VIT" else "VIT"
				g.spend_point(main_stat if (g.stat(main_stat) <= g.stat(side) * 2) else side, 1)
			if g.class_auto == false:
				g.class_auto = true
				g._check_spec()
			for set_name in GameData.SET_ORDER:
				for slot in GameData.SETS[set_name]["pieces"]:
					if g.set_block_reason(set_name) == "":
						g.craft_set_piece(set_name, slot)
			if g.bag_craft_block_reason() == "":
				g.craft_bag()
			g.equip_best()
			for item in g.bag.duplicate():
				if item.get("set", "") != "" and GameData.item_power(item) * 1.15 >= GameData.item_power(g.equipped.get(item["slot"], {"bonus": 0, "level": 0})):
					g.equip(int(item["id"]))
			for it in g.bag.duplicate():
				if g.bag.size() <= 3:
					break
				if not it.get("locked", false):
					g.salvage(int(it["id"]))
			if g.potions < 3:
				g.buy_potion()
			for slot in g.equipped:
				g.upgrade(int(g.equipped[slot]["id"]))
			g.messages.clear()
			g.events.clear()
		if turn + 1 in [3600, 10800, 36000]:
			out += "  %dh: floor %d (best %d, deaths %d)" % [(turn + 1) / 3600, g.floor_num, g.best_floor, g.codex.stat("deaths")]
	out += "  deaths %d, bosses %d, rare+ kills %d, mythic %d, sigs %d, uniques %d" % [g.codex.stat("deaths"), g.codex.stat("boss_kills"), g.codex.stat("rare_kills"), g.codex.stat("tier_5"), g.codex.value("signatures"), g.codex.value("uniques")]
	out += "  skills %d" % g.skill_book.size()
	return "%-20s%s   (lv %d, ATK %d DEF %d HP %d crit %d dodge %d, sets %s)" % [g.title(), out, g.level, g.get_attack(), g.get_defense(), g.get_max_hp(), g.effect_total("crit"), g.effect_total("dodge"), g.set_counts()]

func _initialize() -> void:
	var only := OS.get_environment("CLASSES")
	for cls in Classes.ORDER:
		if only != "" and not cls in only.split(","):
			continue
		seed(7)
		print(play(cls, Classes.CLASSES[cls]["stats"][0], int(OS.get_environment("TURNS")) if OS.get_environment("TURNS") != "" else 10800))
	quit()
