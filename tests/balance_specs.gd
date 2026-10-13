extends SceneTree

func play(cls: String, main_stat: String, turns: int) -> String:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var g := GameState.new()
	g.autosave = false
	g.new_game()
	g.choose_class(cls)
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
			for id in ["a2", "a3", "might1", "guard1", "cun1", "might2", "guard2", "cun2", "might3", "guard3", "cun3"]:
				while g.skill_block_reason(id) == "":
					g.learn_skill(id)
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
			out += "  %dh: floor %d" % [(turn + 1) / 3600, g.floor_num]
	return "%-14s%s   (lv %d, ATK %d DEF %d HP %d crit %d dodge %d, sets %s)" % [g.title(), out, g.level, g.get_attack(), g.get_defense(), g.get_max_hp(), g.effect_total("crit"), g.effect_total("dodge"), g.set_counts()]

func _initialize() -> void:
	for cls in GameData.CLASS_ORDER:
		for st in GameData.STAT_ORDER:
			seed(7)
			print(play(cls, st, 36000))
	quit()
