extends SceneTree
## 0.13 rooms: one room per floor, three blank doors.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func fresh() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.floor_num = 7
	g.best_floor = 7
	g.horde_left = 0
	g.spawn_enemy()
	g.horde_left = 0
	g.horde_pack = false
	return g

func _initialize() -> void:
	var g := fresh()
	for k in GameData.FIGHTS_PER_FLOOR:
		check(not g.door_pending(), "no doors mid-room (%d)" % k)
		g.enemy_hp = 0
		g._enemy_defeated()
		g.horde_left = 0
	check(g.door_pending() and g.floor_num == 7, "cleared room: three doors, same floor")
	check(g.path_info("door_m")["name"] == "Middle door", "doors are blank")
	g.doors = ["fight", "fight", "fight"]
	g.choose_path("door_r")
	check(g.floor_num == 8 and not g.door_pending() and g.fight == 1, "a door leads to the next floor")
	# Autoplay picks a door by itself after a while
	var a := fresh()
	a.autoplay = true
	a.auto_paths = true
	a._room_cleared()
	for _t in GameData.PATH_WAIT_TURNS + 1:
		a.take_turn()
	check(a.floor_num == 8, "autoplay walks through a door")
	# Behind the door
	var t := fresh()
	t._room_cleared()
	t.doors = ["treasure", "treasure", "treasure"]
	var g0 := t.gold
	t.choose_path("door_l")
	t.room_props[0]["mimic"] = false
	Halls.interact(t, 0)
	check(t.gold > g0 and t.door_pending(), "a treasure room pays, then the doors open")
	var r := fresh()
	r._room_cleared()
	r.doors = ["rest", "rest", "rest"]
	r.hero_hp = 1
	r.choose_path("door_m")
	check(r.hero_hp == r.get_max_hp(), "a campfire door heals")
	var e := fresh()
	e._room_cleared()
	e.doors = ["elite", "elite", "elite"]
	e.choose_path("door_m")
	check(e.enemy_tier >= Monsters.EPIC or e.enemy_is_boss or e.enemy_goblin or e.enemy_calamity > 0, "an elite door")
	# Heading home skips the doors
	var h := fresh()
	h.go_home_after = true
	h._room_cleared()
	check(not h.door_pending(), "heading home: no doors")
	var counts := {}
	for i in 300:
		for d in h.roll_doors():
			counts[d] = int(counts.get(d, 0)) + 1
	check(counts.get("fight", 0) > counts.get("treasure", 0) and counts.has("elite") and counts.has("rest"), "door contents vary: %s" % str(counts))
	print("STAGE2 ROOM TESTS DONE, failures: ", fails)
	quit()
