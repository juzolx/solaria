extends SceneTree
## Lore pages turn up in order; the town's keepers talk.
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
	g.floor_num = 10
	check(Lore.maybe_find(g, 100.0) and g.codex.lore == [0], "the first page first")
	for i in Lore.PAGES.size() + 3:
		Lore.maybe_find(g, 100.0)
	check(g.codex.lore.size() == Lore.PAGES.size(), "every page, once each")
	var ordered := true
	for i in g.codex.lore.size():
		if int(g.codex.lore[i]) != i:
			ordered = false
	check(ordered, "in order")
	check(not Lore.maybe_find(g, 100.0), "nothing past the last page")
	var e := GameState.new()
	e.codex.path = ""
	e.floor_num = 1
	check(not Lore.maybe_find(e, 100.0), "not on the first floors")
	for page in Lore.KEEPERS:
		check(Lore.talk(g, page).contains(": \""), "keeper %d talks" % page)
	g.grave = {"floor": 33, "killer": "barghest", "items": [], "gold": 0, "boss": false}
	var mentions := false
	for trip in 40:
		g.codex.stats["home_trips"] = trip
		if Lore.talk(g, 2).contains("floor 33"):
			mentions = true
	check(mentions, "the keepers know about your grave")
	var d := Codex.new()
	d.path = ""
	d._from({"lore": [0, 1, 2]})
	check(d.lore.size() == 3, "pages are saved with the Codex")
	print("STAGE3 LORE TESTS DONE, failures: ", fails)
	quit()
