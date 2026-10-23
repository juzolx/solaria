extends SceneTree
## Next update: four new base classes (Sentinel and Ironbark are tanks).
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _fresh(cls: String) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class(cls)
	return g

func _initialize() -> void:
	var new_classes := ["Sentinel", "Ironbark", "Nightstalker", "Conjurer"]
	var tanks := ["Sentinel", "Ironbark"]
	for cls in new_classes:
		check(cls in Classes.ORDER and Classes.CLASSES.has(cls), cls + " is in the class list")
		var info := Classes.info(cls)
		for sid in info["start"]:
			check(SkillData.SKILLS.has(sid), "%s start skill exists: %s" % [cls, sid])
		for t in info["tags"]:
			check(Classes.TAGS.has(t), "%s tag exists: %s" % [cls, t])
		for slot in info["look"]:
			check(info["look"][slot] in ItemPool.TYPES[slot], "%s look fits slot %s" % [cls, slot])
		var g := _fresh(cls)
		check(g.hero_class == cls, cls + ": choose_class works")
		check(g.skill_book.has(info["start"][0]), cls + ": starts with its first skill")
		# the tree: 2 / 4 / 8 nodes at levels 15 / 35 / 60
		var counts := [0, 0, 0]
		var stack: Array = ClassTree.roots(cls).duplicate()
		while not stack.is_empty():
			var id: String = stack.pop_back()
			var tier := int(ClassTree.node(id)["tier"])
			counts[tier - 1] += 1
			stack.append_array(ClassTree.children(id))
		check(counts == [2, 4, 8], "%s tree is 2/4/8 (%s)" % [cls, str(counts)])
		# auto_pick walks the whole tree
		g.level = 75
		ClassTree.auto_pick(g)
		check(g.class_path.size() == 3, "%s: auto_pick reaches level 75 (%d picks)" % [cls, g.class_path.size()])
	for cls in tanks:
		check(cls in Party.TANK_CLASSES, cls + " is in Party.TANK_CLASSES")
		check(cls in Synergies.FRONT, cls + " counts as a front-liner")
		check(Classes.info(cls)["role"] == "Tank", cls + " is a Tank")
		var t := _fresh(cls)
		var m := _fresh("Mage")
		for g in [t, m]:
			g.level = 40
			for s in ["Weapon", "Chest", "Helmet", "Legs"]:
				g.equipped[s] = GameData.make_item(s, 3, 40, g._new_id())
		check(t.get_max_hp() > m.get_max_hp(), "%s level 40 has more max HP than a Mage (%d vs %d)" % [cls, t.get_max_hp(), m.get_max_hp()])
		check(t.get_defense() > m.get_defense(), "%s level 40 has more Defense than a Mage (%d vs %d)" % [cls, t.get_defense(), m.get_defense()])
	for cls in new_classes:
		check(Bench.RATES.has(cls), cls + " has a bench job")
	print("STAGE5 BASE CLASS TESTS DONE, failures: ", fails)
	quit()
