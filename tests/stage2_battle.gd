extends SceneTree
## 0.13 battle checks: back-to-front layout, packs.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	g.floor_num = 20
	var packs := 0
	for i in 400:
		g.horde_left = 0
		g.horde_pack = false
		g.spawn_enemy()
		if g.horde_pack:
			packs += 1
			check(g.horde_left >= 2 and g.horde_left <= 3, "packs are 2-3")
	check(packs > 8 and packs < 70, "packs show up sometimes (%d/400)" % packs)
	g.horde_left = 1
	g.horde_pack = true
	var gold0 := g.gold
	g._finish_horde()
	check(g.gold > gold0 and not g.horde_pack, "a beaten pack pays a little gold")
	var back := Sprites.hero_back(g.appearance, g.hero_looks())
	check(back.has("anims") and (back["anims"] as Dictionary).has("combat_idle"), "the hero has a back view for fights")
	print("STAGE2 BATTLE TESTS DONE, failures: ", fails)
	quit()
