extends SceneTree
## Next update: travelers in the dungeon, and Deep Rifts (multi-floor portals).
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(fl := 40) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 60
	g.floor_num = fl
	g.best_floor = fl
	g.in_town = false
	g.spawn_enemy()
	g.horde_left = 0
	return g

func _initialize() -> void:
	# Travelers
	var g := hero()
	var seen := 0
	for i in 400:
		if "traveler" in g.roll_doors():
			seen += 1
	check(seen > 10, "travelers turn up behind doors (%d of 400 rolls)" % seen)
	var low := hero(2)
	var low_seen := 0
	for i in 400:
		if "traveler" in low.roll_doors():
			low_seen += 1
	check(low_seen == 0, "not on the first floors")
	g._room_cleared()
	g.doors = ["traveler", "traveler", "traveler"]
	g.choose_path("door_m")
	check(g.exploring and String(g.room_props[0]["kind"]) == "traveler" and Travelers.LIST.has(String(g.room_props[0]["who"])), "the room holds a traveler")
	var p: Dictionary = g.room_props[0]
	p["who"] = "cartographer"
	g.gold = 0
	check(not Travelers.can_pay(g, Travelers.info("cartographer")["offers"][0]), "can't buy with no gold")
	check(Travelers.choose(g, p, 0) == "" and not p["used"], "and nothing happens")
	g.gold = 100000
	var scrolls := g.return_scrolls
	check(Travelers.choose(g, p, 0) != "" and g.return_scrolls == scrolls + 1 and p["used"], "buy the map: a Return Scroll")
	check(g.gold == 100000 - Travelers.price(g, Travelers.info("cartographer")["offers"][0]), "paid for it")
	check(Travelers.choose(g, p, 0) == "", "only once")
	var q := {"kind": "traveler", "who": "cartographer", "used": false}
	g.gold = Travelers.price(g, Travelers.info("cartographer")["offers"][0]) * 2
	Travelers.auto_choose(g, q)
	check(g.return_scrolls == scrolls + 1 and q["used"], "Auto won't spend half your gold on a map")
	var s := {"kind": "traveler", "who": "smith", "used": false}
	g.equipped["Weapon"] = GameData.make_item("Weapon", 2, 40, g._new_id())
	g.scrap = 1000
	var lv := int(g.equipped["Weapon"]["level"])
	Travelers.choose(g, s, 0)
	check(int(g.equipped["Weapon"]["level"]) == lv + 1, "the dwarf hones your weapon")
	# Deep Rifts
	var d := hero(60)
	var deep_found := false
	for i in 200:
		Rifts.enter(d)
		if int(d.portal.get("floors", 1)) > 1:
			deep_found = true
			break
		d.portal = {}
	check(deep_found, "deep rifts happen from floor 30")
	var bag0 := d.bag.size()
	var kills := 0
	while not d.portal.is_empty() and kills < 20:
		var pf := int(d.portal.get("floor", 1))
		d.enemy_hp = 0
		d._enemy_defeated()
		kills += 1
	check(kills == Rifts.FIGHTS * Rifts.DEEP_FLOORS, "three floors of three fights (%d)" % kills)
	check(d.bag.size() >= bag0 + 2 + (Rifts.DEEP_FLOORS - 1) * 2 or d.scrap > 0, "a big vault at the bottom")
	var shallow := hero(20)
	Rifts.enter(shallow)
	check(int(shallow.portal.get("floors", 1)) == 1, "shallow floors: ordinary rifts")
	print("STAGE5 WORLD TESTS DONE, failures: ", fails)
	quit()
