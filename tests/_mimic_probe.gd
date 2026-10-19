extends SceneTree
## Diagnostic: repeats "beat a mimic" many times and reports what blocks the doors when they stay shut.
func room() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 30
	g.floor_num = 40
	g.spawn_enemy()
	g.horde_left = 0
	g._room_cleared()
	g.doors = ["treasure", "treasure", "treasure"]
	g.choose_path("door_m")
	return g

func _initialize() -> void:
	var fails := 0
	for i in 200:
		seed(i)
		var m := room()
		m.room_props[0]["mimic"] = true
		m.room_props[0]["spotted"] = false
		Halls.interact(m, 0)
		m.enemy_hp = 0
		m._enemy_defeated()
		if not m.door_pending():
			fails += 1
			if fails <= 5:
				print("seed %d: floor %d->%d fight %d horde_left %d pack %s path_offer %s enemy '%s' hp %d exploring %s room_kind %s portal %s class_enc '%s'" % [
					i, 40, m.floor_num, m.fight, m.horde_left, str(m.get("horde_pack")), str(m.path_offer), m.enemy_name, m.enemy_hp, m.exploring, m.room_kind, str(m.portal), m.class_encounter])
	print("PROBE: %d of 200 left the doors shut" % fails)
	quit()
