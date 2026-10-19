extends SceneTree
## Town events: one may start when you get home and lasts until you're home again.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 20
	g.floor_num = 20
	g.in_town = false
	return g

func _initialize() -> void:
	var g := hero()
	var base := g.price(1000)
	g.town_event = "fair"
	check(g.price(1000) == int(round(base * TownEvents.FAIR_MULT)), "the fair takes 20% off (%d vs %d)" % [g.price(1000), base])
	g.town_event = ""
	var x0 := g.xp
	g.gain_xp(100)
	var plain := g.xp - x0
	g.town_event = "bard"
	x0 = g.xp
	g.gain_xp(100)
	check(g.xp - x0 > plain, "the bard: more XP")
	g.town_event = "bounty"
	var gd := g.gold
	g._add_gold(100)
	check(g.gold - gd == 125, "bounty day: +25% gold in the dungeon")
	g.in_town = true
	gd = g.gold
	g._add_gold(100)
	check(g.gold - gd == 100, "but not in town")
	# Getting home ends the old event; new ones come and go
	var h := hero()
	h.codex.add("home_trips", 3)
	var started := 0
	var potions_ok := true
	for i in 400:
		var p0 := h.potions
		TownEvents.on_home(h)
		if h.town_event != "":
			started += 1
		if h.town_event == "pilgrims" and h.potions != p0 + 2:
			potions_ok = false
	check(started > 400 * 0.25 and started < 400 * 0.45, "about a third of homecomings (%d of 400)" % started)
	check(potions_ok, "the pilgrims leave two potions")
	var n := hero()
	TownEvents.on_home(n)
	check(n.town_event == "", "nothing on your very first homecoming")
	print("STAGE3 TOWN EVENT TESTS DONE, failures: ", fails)
	quit()
