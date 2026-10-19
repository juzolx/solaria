extends SceneTree
## Snik: friendship grows with purchases; one haggle a visit moves every price.
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
	g.floor_num = 20
	g._make_merchant()
	check(Snik.friendship_name(g) == "Stranger" and Snik.greeting(g) != "", "a stranger at first, and he talks")
	g.codex.add("merchant_buys", 20)
	check(Snik.friendship_name(g) == "Regular", "twenty purchases: a regular")
	check(Snik.haggle_chance(g) > 35.0, "friends haggle better (%.0f%%)" % Snik.haggle_chance(g))
	var before: Array = g.merchant.map(func(e): return int(e["price"]))
	check(Snik.can_haggle(g), "can haggle once")
	Snik.haggle(g)
	var after: Array = g.merchant.map(func(e): return int(e["price"]))
	var won := g.merchant_haggle == "won"
	var moved := true
	for i in before.size():
		var want := int(round(int(before[i]) * (Snik.HAGGLE_WIN if won else Snik.HAGGLE_LOSE)))
		if int(after[i]) != maxi(1, want):
			moved = false
	check(moved, "every price moved the right way (%s)" % g.merchant_haggle)
	check(not Snik.can_haggle(g) and Snik.haggle(g) == "", "only once a visit")
	g._make_merchant()
	check(Snik.can_haggle(g), "a new visit, a new try")
	var wins := 0
	for i in 2000:
		g.merchant_haggle = ""
		Snik.haggle(g)
		if g.merchant_haggle == "won":
			wins += 1
	var want_pct := Snik.haggle_chance(g)
	check(absf(wins / 20.0 - want_pct) < 5.0, "the odds hold (%.1f%% vs %.0f%%)" % [wins / 20.0, want_pct])
	print("STAGE3 SNIK TESTS DONE, failures: ", fails)
	quit()
