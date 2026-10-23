extends SceneTree
## 2.1 G6: the Wheel's Legendary table. Locked before floor 250, opens at 250
## (and stays open), the odds screen shows exactly what the code rolls,
## Luck/goblins raise the top prizes up to a cap, and rolls match the odds.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _fresh() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	return g

func _initialize() -> void:
	# ---- Locked before 250 ----
	var g := _fresh()
	g.best_floor = 249
	g.floor_num = 249
	g.gold = 100000000
	check(not WheelTables.legendary_unlocked(g), "locked at floor 249")
	check(WheelTables.lock_text(g).contains("250"), "the locked text says how to open it")
	var gold_before := g.gold
	var r := WheelTables.spin_legendary(g)
	check(not r.get("ok", false), "no spins while locked")
	check(g.gold == gold_before, "a locked spin costs nothing")

	# ---- Opens at 250, through the floor code, and stays open ----
	g.floor_num = 250
	g.best_floor = 250
	WheelTables.on_floor(g)
	check(WheelTables.legendary_unlocked(g), "opens at floor 250")
	check(g.codex.stat(WheelTables.UNLOCK_KEY) == 1, "the unlock is saved in the codex")
	g.best_floor = 10  # e.g. a fresh hero in the same account
	check(WheelTables.legendary_unlocked(g), "stays open once earned (deepest floor ever)")
	var g2 := _fresh()
	g2.codex.at_least("best_floor", 300)
	check(WheelTables.legendary_unlocked(g2), "the account's deepest floor counts")

	# ---- Spinning delivers a prize through the reward code ----
	g.best_floor = 250
	g.gold = 100000000
	var bag0 := g.bag.size()
	var got_any := false
	for _i in 30:
		var s := WheelTables.spin_legendary(g)
		check(s.get("ok", false), "an open table spins")
		if s.get("ok", false):
			got_any = got_any or String(s["text"]) != ""
	check(got_any, "prizes are handed out")
	check(g.gold < 100000000, "spins cost gold")
	check(g.codex.stat(WheelTables.SPINS_KEY) == 30, "spins are counted")
	var cache: Dictionary = WheelTables.LEGENDARY_PRIZES.filter(func(p): return p["id"] == "legend_cache")[0]
	var b1 := g.bag.size()
	WheelTables.deliver(g, cache)
	check(g.bag.size() == b1 + 3, "the Cache of Legends gives 3 items")
	check(int(g.bag[g.bag.size() - 1]["rarity"]) == GameData.LEGENDARY, "and they are Legendary")
	check(bag0 <= g.bag.size(), "bag only grows from prizes")

	# ---- Displayed odds equal the roll table ----
	for fort in [0.0, 12.5, 40.0, 500.0]:
		var w := WheelTables.weights_for(fort)
		var tw := 0.0
		for x in w:
			tw += float(x)
		var rows := WheelTables.legendary_rows(fort)
		check(rows.size() == w.size() and w.size() == WheelTables.LEGENDARY_PRIZES.size(), "one row per prize")
		var sum := 0.0
		for i in rows.size():
			check(rows[i]["id"] == WheelTables.LEGENDARY_PRIZES[i]["id"], "rows in roll order")
			check(is_equal_approx(float(rows[i]["pct"]), 100.0 * float(w[i]) / tw), "shown %% = rolled %% (%s @ %s)" % [rows[i]["id"], fort])
			sum += float(rows[i]["pct"])
		check(absf(sum - 100.0) < 0.0001, "odds add up to 100%% (fortune %s)" % fort)
	var base_sum := 0
	for p in WheelTables.LEGENDARY_PRIZES:
		base_sum += int(p["weight"])
	check(base_sum == 1000000, "base weights are out of 1,000,000 (%d)" % base_sum)
	var nrows := WheelTables.normal_rows()
	for i in nrows.size():
		var it := GameData.make_item("Feet", i, 5, 9000 + i)
		check(int(nrows[i]["pct"]) == g.gamble_chance(it), "item Wheel odds shown = gamble_chance (%s)" % nrows[i]["name"])
	# The player's own Fortune is what both the screen and the roll use
	check(WheelTables.weights(g) == WheelTables.weights_for(WheelTables.fortune(g)), "roll uses the player's Fortune")

	# ---- Luck raises the top odds, within the cap ----
	var base_top := WheelTables.top_pct(0.0)
	check(base_top > 0.0 and base_top < 0.05, "top prizes almost never hit (%.4f%%)" % base_top)
	var lucky := _fresh()
	lucky.stat_points = 0
	var f0 := WheelTables.fortune(lucky)
	lucky.stats["LUK"] = int(lucky.stats.get("LUK", 0)) + 300
	var f1 := WheelTables.fortune(lucky)
	check(f1 > f0 + 20.0, "Luck raises Fortune (%.1f -> %.1f)" % [f0, f1])
	check(WheelTables.top_pct(f1) > WheelTables.top_pct(f0) * 2.0, "and the top odds meaningfully (%.4f%% -> %.4f%%)" % [WheelTables.top_pct(f0), WheelTables.top_pct(f1)])
	lucky.codex.add("goblins", 75)
	lucky.luck_turns = 10
	var f2 := WheelTables.fortune(lucky)
	check(f2 > f1, "goblins caught and a Scroll of Luck add Fortune (%.1f)" % f2)
	var capped := WheelTables.top_pct(100000.0)
	check(capped <= base_top * WheelTables.TOP_CAP + 0.0001, "top odds are capped (%.4f%%)" % capped)
	check(capped < 1.0, "never reliable: under 1%% even at the cap (%.4f%%)" % capped)
	check(WheelTables.tier_mult("top", 100000.0) == WheelTables.TOP_CAP, "top multiplier stops at the cap")
	check(WheelTables.tier_mult("rare", 100000.0) == WheelTables.RARE_CAP, "rare multiplier stops at its cap")
	check(WheelTables.tier_mult("common", 100000.0) == 1.0, "common prizes never change")

	# ---- Statistical roll test: rolls match the shown odds ----
	var rng := RandomNumberGenerator.new()
	rng.seed = 2101
	for fort in [0.0, 1000.0]:
		var w := WheelTables.weights_for(fort)
		var rows := WheelTables.legendary_rows(fort)
		var counts: Array = []
		counts.resize(w.size())
		counts.fill(0)
		var n := 400000
		for _i in n:
			counts[WheelTables.roll_index(w, rng)] += 1
		for i in rows.size():
			var p := float(rows[i]["pct"]) / 100.0
			var expect := p * n
			var sd := sqrt(n * p * (1.0 - p))
			check(absf(counts[i] - expect) <= 5.0 * sd + 2.0, "rolls match odds for %s @ %s (%d vs %.1f)" % [rows[i]["id"], fort, counts[i], expect])
	print("STAGE6 WHEEL LEGENDARY TESTS DONE, failures: ", fails)
	quit()
