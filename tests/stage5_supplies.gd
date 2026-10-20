extends SceneTree
## Next update: supplies (home vs carried, elixirs drunk in the dungeon) and front / back rows.
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
	g.in_town = true
	g.gold = 100000
	g.buy_elixir("might")
	check(g.supply_home("might") == 1 and g.supply_carried("might") == 0 and not g.elixirs.has("might"), "bought in town: stored at home, not drunk")
	check(g.move_supply("might", 1) and g.supply_carried("might") == 1 and g.supply_home("might") == 0, "take it down")
	check(not g.move_supply("might", 1), "can't take what isn't there")
	g.potions = 3
	check(g.move_supply("potion", -2) and g.potions == 1 and g.supply_home("potion") == 2, "leave two potions safe at home")
	g.in_town = false
	check(not g.move_supply("potion", 1), "you pick supplies in town, not down there")
	check(g.drink_elixir("might") and int(g.elixirs.get("might", 0)) > 0 and g.supply_carried("might") == 0, "drink it in the dungeon")
	check(not g.drink_elixir("might"), "and it's gone")
	g.buy_elixir("iron")
	check(g.supply_carried("iron") == 1, "bought down there: it's in your pack")
	var lost := g._death_losses()
	check(lost.contains("elixir") and g.supply_carried("iron") == 0, "a fall loses the carried elixir (%s)" % lost)
	check(g.supply_home("potion") == 2, "home supplies are never at risk")
	# Rows
	check(g.row_of("0", true) == "front" and g.row_of("2", false) == "back", "tanks start in front, others behind")
	g.set_row("2", "front")
	check(g.row_of("2", false) == "front", "move a hero to the front")
	check(Party.row_weight("front") > Party.row_weight("back") * 2.0, "the front row draws far more attacks")
	print("STAGE5 SUPPLY TESTS DONE, failures: ", fails)
	quit()
