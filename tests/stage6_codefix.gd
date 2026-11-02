extends SceneTree
## Fable code review r1 (claude/research/fable-code-r1.md): regression tests for the save / realm fixes.
## godot --headless --path . -s tests/stage6_codefix.gd
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(n: int, cls: String, order: Array) -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.slot = n
	g.new_game()
	g.choose_class(cls)
	g.hero_name = cls
	g.realm_order.assign(order)
	g.save_game(true)
	return g

func raw(p: String) -> Variant:
	var f := FileAccess.open(p, FileAccess.READ)
	var d = f.get_var()
	f.close()
	return d

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1
	var ids: Array = Realms.IDS

	# --- #1: a companion's load_game must not leave its realm order in the static
	hero(2, "Trickster", [])                   # a companion who never went past floor 250
	hero(3, "Warrior", [ids[4], ids[0]])       # and one who picked other realms
	var lead_order := [ids[3], ids[1]]
	hero(1, "Ranger", lead_order)
	var lead := GameState.new()
	lead.codex.path = ""
	lead.slot = 1
	check(lead.load_game(), "the leader loads")
	check(GameData.realm_order == lead_order, "the leader's load sets the leader's realms")
	lead.set_party([2, 3])
	check(lead.party != null and lead.party.size() == 2, "both companions join (%d)" % (lead.party.size() if lead.party else -1))
	check(GameData.realm_order == lead_order, "after the party loads the realms are still the leader's (%s)" % str(GameData.realm_order))
	check(GameData.realm_of(251) == String(ids[3]), "floor 251 is the leader's first realm (%s)" % GameData.realm_of(251))
	check(GameData.zone_index(301) == Realms.zone_for_id(String(ids[1])), "floor 301 is the leader's second realm")

	# --- #2: a deleted companion is not written back by the party's saves
	var comp: GameState = lead.party.members[0].hero
	check(comp.slot == 2, "companion in slot 2 first")
	GameState.delete_slot(2)
	check(not GameState.has_slot(2), "slot 2 deleted")
	lead.party.save_all(true)                  # pause / quit: a forced save of every companion
	check(not GameState.has_slot(2), "a forced party save doesn't bring the deleted hero back")
	comp.save_game()                           # a new floor: the throttled save
	comp.save_pending = true
	lead.party.flush()
	check(not GameState.has_slot(2), "a throttled or flushed save doesn't either")
	check(not comp.save_pending, "nothing left pending for the deleted hero")
	check(GameState.has_slot(3), "the other companion's save is untouched")
	lead.set_party(lead.party_slots.filter(func(k): return int(k) != 2))   # what Heroes > Delete now does
	check(lead.party_slots == [3], "the deleted hero leaves the team (%s)" % str(lead.party_slots))
	check(not GameState.has_slot(2), "still deleted after the team changes")
	lead.gold = 4321
	lead.save_game(true)
	check(int(raw(GameState.slot_paths(1)[0])["gold"]) == 4321, "a hero that still exists keeps saving")
	# a brand-new hero (never on disk) still makes its first save
	var fresh := GameState.new()
	fresh.codex.path = ""
	fresh.slot = 6
	fresh.new_game()
	fresh.save_game(true)
	check(GameState.has_slot(6), "a new hero's first save is written")

	# --- #6: the title / loading screen read a hero's realms from its meta, before any hero loads
	check(GameState.slot_meta(1).get("realm_order", []) == lead_order, "meta carries the hero's realm order")
	var old_meta_path: String = GameState.slot_paths(7)[0]
	SaveIO.write(old_meta_path, {"version": GameData.SAVE_VERSION, "floor": 260, "hero_class": "Warrior", "level": 30,
		"meta": {"name": "Old", "floor": 260}, "lineage": {"realm_order": [ids[2]]}}, "hero")
	check(GameState.slot_meta(7).get("realm_order", []) == [ids[2]], "an older meta falls back to the lineage's realm order")

	# --- #7: hidden classes are recorded in the Codex on load (a pre-2.1 backup is repaired without it)
	var hid := String(Hidden.ORDER[0])
	var h := hero(4, "Warrior", [])
	h.hidden[hid] = true
	h.save_game(true)
	var h2 := GameState.new()
	h2.codex = Codex.new()
	h2.codex.path = ""
	h2.slot = 4
	check(not h2.codex.classes_found.has(hid), "an empty Codex to start")
	check(h2.load_game(), "the hero loads")
	check(h2.codex.classes_found.has(hid), "its hidden class is in the Codex after the load")

	# --- #9: a 2.1 hero file that lost its version key is loaded, not converted (and wiped)
	var v := hero(5, "Mage", [])
	v.level = 17
	v.gold = 777
	v.save_game(true)
	var d: Dictionary = raw(GameState.slot_paths(5)[0])
	d.erase("version")
	SaveIO.write(GameState.slot_paths(5)[0], d, "hero")
	var v2 := GameState.new()
	v2.codex.path = ""
	v2.slot = 5
	check(v2.load_game(), "the version-less file loads")
	check(v2.level == 17 and v2.hero_class == "Mage" and v2.gold == 777, "level, class and gold are kept (lv %d %s %d)" % [v2.level, v2.hero_class, v2.gold])

	# --- #8: a lost settings file: towns with heroes get their record (and Hardcore mode) back
	GameState.delete_saves()
	GameState.town = 2
	var hc := hero(1, "Warrior", [])
	hc.hardcore = true
	hc.save_game(true)
	GameState.town = 1
	hero(1, "Ranger", [])
	var p := Profile.new()
	p.towns = {}                               # what load_profile's "lost" branch starts with
	p.towns_v1 = true
	p.fill_town_modes()
	check(p.towns.has("2") and p.town_hardcore(2), "the Hardcore town is Hardcore again")
	check(p.towns.has("1") and not p.town_hardcore(1), "the Regular town is Regular")
	check(not p.towns.has("3"), "a town with no heroes gets no record")

	# --- #4: the loading screen's flat room never takes (or frees) the shared 3D room
	var hs := HallsScene.new()
	hs.flat = true
	var keep := Room3D.new()
	var was = HallsScene.shared
	HallsScene.shared = keep
	var ci := Control.new()
	check(not hs._draw_3d(ci, Vector2(430, 932)), "a flat view uses the 2D drawer")
	check(HallsScene.shared == keep and is_instance_valid(keep), "and leaves the shared room alone")
	check(not hs.is_3d(), "a flat view is never 3D")
	HallsScene.shared = was
	keep.free()
	ci.free()

	GameState.delete_saves()
	Profile.delete()
	GameState.town = 1
	GameData.realm_order = []
	print("STAGE6 CODEFIX TESTS DONE, failures: ", fails)
	quit()
