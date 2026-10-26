extends SceneTree
## Bug sweep fixes (Oct 25): Hardcore deaths can't be undone by quitting, a full bag never
## eats a Legendary, the fall card fits a phone, 2.0 backups are converted when restored,
## the title screen's zone cycle wraps, Golem heroes become proper Dwarves, a trial cut short
## by closing the app gives its gate back.
## godot --headless --path . -s tests/stage6_sweep.gd
const TestHero := preload("res://tests/test_hero.gd")
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func hero(n: int) -> GameState:
	var g := GameState.new()
	g.slot = n
	g.codex = Codex.new()
	g.codex.path = ""
	g.new_game()
	g.choose_class("Warrior")
	return g

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	SaveIO.notices.clear()

	# --- HIGH 1: a Hardcore death deletes the save at once (not when the farewell shows)
	var hc := hero(4)
	hc.hardcore = true
	hc.floor_num = 12
	hc.save_game(true)
	check(GameState.has_slot(4), "the Hardcore hero is saved before the fall")
	hc.hero_hp = 0
	hc._hero_died()
	check(hc.run_over, "the Hardcore run is over")
	check(not GameState.has_slot(4), "the fallen Hardcore hero's save is gone right away (quitting can't bring it back)")
	var hc2 := GameState.new()
	hc2.slot = 4
	hc2.codex = Codex.new()
	hc2.codex.path = ""
	check(not hc2.load_game(), "there is nothing left to load")
	# A simulation (autosave off) never deletes a real slot
	var sim := hero(5)
	sim.save_game(true)
	sim.autosave = false
	sim.hardcore = true
	sim.hero_hp = 0
	sim._hero_died()
	check(GameState.has_slot(5), "a hero without autosave (simulations) leaves slot files alone")
	GameState.delete_slot(5)

	# --- HIGH 2: past the overflow, Legendaries still reach the bag
	var b := hero(6)
	b.autosave = false
	while b.bag.size() < b.bag_capacity() + GameState.OVERFLOW_MAX:
		b.bag.append(GameData.make_item("Chest", 0, 5, b._new_id()))
	var before := b.bag.size()
	var leg := GameData.make_item("Weapon", GameData.LEGENDARY, 5, b._new_id())
	b._give_item(leg)
	check(b.bag.size() == before + 1 and b.bag.has(leg), "a Legendary drop is kept even when the bag overflows")
	var com := GameData.make_item("Feet", 0, 5, b._new_id())
	b.loot_filter = {"v": LootRules.VERSION, "on": false, "slots": {}, "weaker": false, "below_gs": false, "keep_sets": true, "action": "salvage"}
	b._give_item(com)
	check(not b.bag.has(com), "a Common drop past the overflow still turns into scrap")

	# --- HIGH 3: the fall card fits a phone's fight view, with OK on screen
	var holder := Control.new()
	holder.size = Vector2(488, 474)
	root.add_child(holder)
	var r := {"floor": 30, "enemy": "Grendel's Mother, the Drowned", "woke": 26, "total": 800, "enemy_left": 0.4,
		"lost": "Your bag (12 items), your worn gear (7 items) and 1,234 gold (your gear and bag lie here, guarded by your killer)",
		"taken": {"hits": 500, "burning": 200, "poison": 100},
		"tips": ["Your Defense is low for this floor: upgrade your armour at the Blacksmith.", "Burning hurt a lot: a Fire resist elixir helps."]}
	var card := DeathScreen.regular(r, func(): pass, func(): pass)
	holder.add_child(card)
	card.custom_minimum_size.x = 464
	await process_frame
	DeathScreen.fit_regular(card, 474.0 - 40.0 - 8.0)
	await process_frame
	await process_frame
	check(card.size.y <= 474.0 - 40.0 - 8.0 + 1.0, "the fall card fits the fight view (%d px tall)" % int(card.size.y))
	var row := card.find_child("Buttons", true, false) as Control
	check(row != null and row.get_global_rect().end.y <= card.get_global_rect().end.y + 0.5, "the OK row is inside the card")
	holder.queue_free()

	# --- MED 4: a 2.0 backup restored after the 2.1 move is converted too
	var path: String = GameState.town_slot_paths(1, 7)[0]
	SaveIO.delete_all(path)
	var old := {"version": GameData.SAVE_VERSION, "floor": 9, "level": 5, "hero_class": "Warrior", "dust": 1, "materials": [15, 5, 0, 0, 0, 0, 0, 0, 0, 0],
		"appearance": {"race": "Golem", "skin": 10}}
	var f := FileAccess.open(SaveIO.backup_path(path, 1), FileAccess.WRITE)
	f.store_var(old)
	f.close()
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("broken by a phone that shut down mid-save")
	f.close()
	var res := SaveIO.load_file(path, "hero")
	var d: Dictionary = res["data"] if res["data"] is Dictionary else {}
	check(bool(res["restored"]), "the backup was used")
	check(not d.has("materials") and int(d.get("dust", 0)) == 3, "the 2.0 backup's materials became dust (got %s)" % str(d.get("dust")))
	check(String((d.get("appearance", {}) as Dictionary).get("race", "")) == "Dwarf", "the 2.0 backup's Golem is a Dwarf")
	SaveIO.delete_all(path)
	SaveIO.notices.clear()

	# --- MED 8: the title screen's zone cycle never runs off the end
	var ts := TitleScreen.new()
	for zi in GameData.ZONES.size():
		ts.bg_keys.append(zi)
	ts.bg_index = GameData.ZONES.size() * 3 + 2
	ts._pick_monster()
	check(not ts.monster.is_empty() or GameData.ZONES[ts.bg_keys[ts.bg_index % ts.bg_keys.size()]]["enemies"].is_empty(), "a monster is picked after many fades")
	ts.free()

	# --- LOW 10-12: Golem heroes become proper Dwarves
	var gd := {"version": GameData.SAVE_VERSION, "floor": 3, "level": 20, "appearance": {"race": "Golem", "skin": 11, "body": "masc"},
		"meta": {"appearance": {"race": "Golem", "skin": 11}}, "lineage": {"rep": {"Golem": 25.0, "Dwarf": 5.0, "Elf": -10.0}}}
	SaveMigrate.migrate_hero(gd)
	var look: Dictionary = gd["appearance"]
	check(look["race"] == "Dwarf" and int(look["skin"]) in Races.skins("Dwarf"), "a Golem's look becomes a Dwarf with a Dwarf skin")
	check(String(gd["meta"]["appearance"]["race"]) == "Dwarf", "the slot summary says Dwarf too")
	var rep: Dictionary = gd["lineage"]["rep"]
	check(not rep.has("Golem") and float(rep["Dwarf"]) == 25.0 and float(rep["Elf"]) == -10.0, "Golem standing moved to the Dwarves")
	check(HeroArt.art_race({"race": "Golem"}) == "Dwarf", "an old summary that still says Golem draws a Dwarf")
	# ...and on every load (2.1 saves made before Golem was retired)
	var gl := hero(8)
	gl.appearance["race"] = "Golem"
	gl.appearance["skin"] = 10
	gl.rep = {"Golem": 30.0, "Dwarf": 0.0}
	gl.save_game(true)
	var gl2 := GameState.new()
	gl2.slot = 8
	gl2.codex = Codex.new()
	gl2.codex.path = ""
	check(gl2.load_game(), "the Golem hero loads")
	check(gl2.race() == "Dwarf" and int(gl2.appearance["skin"]) in Races.skins("Dwarf"), "loads as a Dwarf with a Dwarf skin")
	check(not gl2.rep.has("Golem") and float(gl2.rep.get("Dwarf", 0.0)) == 30.0, "loads with its standing moved to the Dwarves")
	GameState.delete_slot(8)

	# --- LOW 15: a trial cut short by closing the app gives its champion's gate back
	var tr := hero(9)
	tr.floor_num = 14
	tr.best_floor = 14
	tr.room_kind = "trial"
	tr.doors = []
	tr.room_props = [{"kind": "gate", "used": true, "trial": {"kind": "race", "id": "x", "name": "The Test Champion", "goal": ""}}]
	tr.trial_active = true
	tr.trial_return = 14
	tr.trial_data = {"gate": true}
	tr.save_game(true)
	var tr2 := GameState.new()
	tr2.slot = 9
	tr2.codex = Codex.new()
	tr2.codex.path = ""
	check(tr2.load_game(), "the hero who left mid-trial loads")
	check(not tr2.trial_active and tr2.floor_num == 14, "back on the floor the trial started from")
	check(not bool(tr2.room_props[0].get("used", false)), "the champion's gate stands again")
	GameState.delete_slot(9)

	GameState.delete_saves()
	print("STAGE6 SWEEP TESTS DONE, failures: %d" % fails)
	quit()
