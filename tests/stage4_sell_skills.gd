extends SceneTree
## Selling skills: unequipped skills sell for gold and leave your book.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _initialize() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.best_floor = 40
	var spare := ""
	for id in SkillData.SKILLS:
		if not g.skill_book.has(id):
			spare = id
			break
	g.skill_book[spare] = 3
	var equipped_id: String = g.active_slots[0]
	check(g.skill_sell_block(equipped_id) != "", "an equipped skill can't be sold")
	var dust0 := g.dust
	var price := g.skill_sell_price(spare)
	check(price > 0, "a skill has a price (%d)" % price)
	check(g.sell_skill(spare) == price and g.dust == dust0 + price, "selling pays its price in dust")
	check(not g.skill_book.has(spare), "and it leaves your book")
	print("STAGE4 SELL SKILL TESTS DONE, failures: ", fails)
	quit()
