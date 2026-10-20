extends SceneTree
## Next update: rare pets, tiers to Mythic, release, the Codex pet book, first-find fanfares.
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
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 20000:
		counts[Menagerie.roll_tier()] += 1
	check(counts[0] > counts[1] and counts[1] > counts[2] and counts[3] > counts[4] and counts[4] > counts[5], "each tier rarer than the last %s" % str(counts))
	check(counts[5] > 0 and counts[5] < 200, "Mythic is a legend (%d in 20000)" % counts[5])
	g.events.clear()
	var p := Menagerie.make_pet(g, "Cave Rat", "", 2, "caught")
	check(g.codex.pet_book.get("Cave Rat", -1) == 2, "the Codex remembers the pet")
	check(g.events.any(func(e): return e.get("type", "") == "first_find" and e.get("kind", "") == "pet"), "first of its kind: fanfare")
	g.events.clear()
	Menagerie.make_pet(g, "Cave Rat", "", 1, "caught")
	check(not g.events.any(func(e): return e.get("type", "") == "first_find"), "a second one: no fanfare")
	check(g.codex.pet_book["Cave Rat"] == 2, "keeps the best tier")
	g.events.clear()
	var hp := Menagerie.hatch(g, {})
	var hm: Array = g.events.filter(func(e): return e.get("type", "") == "hatch_moment")
	check(hm.size() == 1 and not g.events.any(func(e): return e.get("type", "") == "first_find"), "a hatch shows one moment, not two")
	check(not hp.has("new_kind"), "no leftover flag on the pet")
	var n := g.pets.size()
	check(Menagerie.release(g, int(p["id"])) and g.pets.size() == n - 1, "release a pet")
	check(not int(p["id"]) in g.pets_out, "released pet isn't coming along")
	check(g.codex.pet_book.has("Cave Rat"), "the Codex still remembers it")
	check(not Menagerie.release(g, 999999), "can't release what you don't have")
	g.events.clear()
	var u := GameData.make_unique(GameData.zone_uniques(0)[0], 10, g._new_id())
	g._note_find(u)
	check(g.events.any(func(e): return e.get("type", "") == "first_find" and e.get("kind", "") == "unique"), "first Unique: fanfare")
	g.events.clear()
	g._note_find(u.duplicate())
	check(g.events.is_empty(), "the same Unique again: no fanfare")
	check(Menagerie.EGG_SNIK_CHANCE <= 1.0 and Menagerie.EGG_SPARE_CHANCE <= 0.2, "eggs are rare")
	print("STAGE5 PET TESTS DONE, failures: ", fails)
	quit()
