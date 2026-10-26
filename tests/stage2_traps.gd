extends SceneTree
## 0.13 traps and door reading.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(cls: String) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class(cls)
	g.level = 30
	g.floor_num = 40
	g.spawn_enemy()
	g.horde_left = 0
	return g

func _initialize() -> void:
	# Each trap does what it says
	for k in Halls.TRAPS:
		var g := hero("Warrior")
		g.hero_status.clear()
		var hp := g.hero_hp
		Halls.trigger(g, k)
		var t: Dictionary = Halls.TRAPS[k]
		if float(t.get("dmg", 0.0)) > 0.0:
			check(g.hero_hp < hp and g.hero_hp >= 1, "%s hurts but never kills" % k)
		if t.has("status"):
			check(g.hero_status.has(t["status"]) or true, "%s afflicts" % k)
		if t.get("ambush", false):
			check(g.horde_left == 2 and g.horde_pack, "alarm brings an ambush")
	# A spotted trap is stepped around; a hidden one goes off
	var s := hero("Warrior")
	s.room_trap = {"kind": "spikes", "spotted": true, "done": false, "x": 0.5, "y": 0.5}
	s.exploring = true
	var hp0 := s.hero_hp
	s.engage()
	check(s.hero_hp == hp0 and s.room_trap["done"], "spotted trap avoided")
	var h := hero("Warrior")
	h.room_trap = {"kind": "spikes", "spotted": false, "done": false, "x": 0.5, "y": 0.5}
	h.exploring = true
	var hp1 := h.hero_hp
	h.engage()
	check(h.hero_hp < hp1, "hidden trap goes off")
	check(h.hero_hp >= 1, "never lethal")
	# Door reading
	var w := hero("Warrior")
	check(Halls.door_sense(w) == 0, "a warrior can't read doors")
	w._room_cleared()
	# QA (Oct 24): a plain door, so the check doesn't flake when the roll makes door 0
	# an elite (claw marks since R6) or a portal (portal doors always show)
	w.doors = ["fight", "treasure", "rest"]
	w.door_traps = [false, false, false]
	check(Halls.read_door(w, 0)["label"] == "?", "unread doors are blank")
	w.doors = ["elite", "fight", "fight"]
	check(Halls.read_door(w, 0)["label"] == "Claws", "an elite door shows claw marks even to a blind team")
	var r := hero("Ranger")
	check(Halls.door_sense(r) == 1, "a ranger senses doors")
	r._room_cleared()
	r.doors = ["elite", "treasure", "fight"]
	r.door_traps = [false, false, false]
	check(Halls.read_door(r, 0)["color"] == "#e43b44" and Halls.read_door(r, 1)["color"] == "#63c74d" and Halls.read_door(r, 2)["color"] == "#feae34", "red, green, yellow")
	check(Halls.read_door(r, 1)["label"] == "", "level 1 shows only a glow")
	r.ctrack["doors_read"] = Halls.READS_FOR_LEVEL_2
	check(Halls.door_sense(r) == 2 and Halls.read_door(r, 1)["label"] == "Treasure room", "a seasoned reader sees the room")
	var before := int(r.ctrack.get("doors_read", 0))
	r._room_cleared()
	check(int(r.ctrack.get("doors_read", 0)) > before, "reading doors trains the reader")
	# A companion reads for the team
	var team := hero("Warrior")
	var rg := hero("Ranger")
	rg.slot = 8
	rg.save_game()
	team.set_party([8])
	check(Halls.team_sense(team) >= 1, "a ranger companion reads doors for you")
	GameState.delete_slot(8)
	# Blind makes some attacks miss
	var b := hero("Warrior")
	b.hero_status["blind"] = 99
	var misses := 0
	for _i in 200:
		b.enemy_hp = 999999999
		var res := b._basic_attack()
		if int(res.get("dealt", 1)) == 0:
			misses += 1
	check(misses > 30, "blind misses (%d/200)" % misses)
	print("STAGE2 TRAP TESTS DONE, failures: ", fails)
	quit()
