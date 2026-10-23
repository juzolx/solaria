extends SceneTree
## 2.1: the one loot filter, auto-dive settings and the one presets screen.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _hero() -> GameState:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.floor_num = 60
	return g

func _initialize() -> void:
	_filter()
	_auto_dive()
	_presets()
	_save_load()
	print("STAGE6 LOOT PRESETS TESTS DONE, failures: ", fails)
	quit()

# ---------------------------------------------------------------- loot filter
func _filter() -> void:
	var g := _hero()
	for s in ["Weapon", "Chest", "Helmet"]:
		g.equipped[s] = GameData.make_item(s, 3, 60, g._new_id())
	check(int(g.loot_filter.get("v", 0)) == LootRules.VERSION, "a new hero starts on the new filter rules")
	var common := GameData.make_item("Legs", 0, 5, g._new_id())
	var rare := GameData.make_item("Legs", 2, 5, g._new_id())
	check(LootRules.decide(g, common) == "keep", "filter with no rules: keeps everything")
	g.auto_salvage = 1
	LootRules.test_ignore_upgrades = true  # test the rules on their own
	check(LootRules.decide(g, common) == "salvage", "rarity rule: a Common goes to scrap")
	check(LootRules.decide(g, rare) == "keep", "rarity rule: a Rare above the line is kept")
	LootRules.test_ignore_upgrades = false
	check(LootRules.decide(g, common) == "keep", "upgrades always kept: a drop for an empty slot stays")
	check(not LootRules.defaults().has("keep_better"), "keeping upgrades isn't a setting")
	LootRules.test_ignore_upgrades = true
	# never touched: locked, set pieces, Legendary and up
	common["locked"] = true
	check(LootRules.decide(g, common) == "keep", "locked items are never touched")
	common["locked"] = false
	var piece := GameData.make_item("Legs", 0, 5, g._new_id())
	piece["set"] = "grendels_kin"
	check(LootRules.decide(g, piece) == "keep", "set pieces are kept")
	LootRules.set_rule(g, "keep_sets", false)
	check(LootRules.decide(g, piece) == "salvage", "set pieces can be let go if you turn that off")
	LootRules.set_rule(g, "keep_sets", true)
	var legend := GameData.make_item("Legs", GameData.LEGENDARY, 5, g._new_id())
	g.auto_salvage = 3
	check(LootRules.decide(g, legend) == "keep", "Legendary is always kept")
	var set_r := GameData.make_item("Legs", GameData.SET_RARITY, 5, g._new_id())
	check(LootRules.decide(g, set_r) == "keep", "Set rarity is always kept")
	g.auto_salvage = 1
	# slot and smart rules
	var helm := GameData.make_item("Helmet", 1, 5, g._new_id())
	g.auto_salvage = -1
	check(LootRules.decide(g, helm) == "keep", "no slot marked: kept")
	LootRules.toggle_slot(g, "Helmet")
	check(LootRules.decide(g, helm) == "salvage", "slot rule: a marked slot goes")
	LootRules.toggle_slot(g, "Helmet")
	LootRules.toggle(g, "weaker")
	check(LootRules.decide(g, helm) == "salvage", "weaker rule: weaker than the worn helmet goes")
	LootRules.toggle(g, "weaker")
	# sell vs salvage, done for real on a drop
	g.auto_salvage = 0
	LootRules.cycle_action(g)
	check(LootRules.decide(g, GameData.make_item("Legs", 0, 5, g._new_id())) == "sell", "sell action")
	var drop := GameData.make_item("Legs", 0, 5, g._new_id())
	var gold0 := g.gold
	var price := g.sell_price(drop)
	var bag0 := g.bag.size()
	g._give_item(drop)
	check(g.gold == gold0 + price and g.bag.size() == bag0, "a filtered drop is sold for gold (+%d)" % price)
	LootRules.cycle_action(g)
	var scrap0 := g.scrap
	var drop2 := GameData.make_item("Legs", 0, 5, g._new_id())
	g._give_item(drop2)
	check(g.scrap == scrap0 + int(GameData.scrap_value(drop2) * g.scrap_mult()) and g.bag.size() == bag0, "a filtered drop is salvaged for scrap (with your scrap bonus)")
	var locked_drop := GameData.make_item("Legs", 0, 5, g._new_id())
	locked_drop["locked"] = true
	g._give_item(locked_drop)
	check(g.bag.size() == bag0 + 1, "a locked drop lands in the bag")
	# master switch and Auto
	LootRules.toggle(g, "on")
	check(LootRules.decide(g, GameData.make_item("Legs", 0, 5, g._new_id())) == "keep", "filter off: kept")
	LootRules.toggle(g, "on")
	g.autoplay = true
	AutoDive.set_value(g, "filter_in_auto", false)
	check(LootRules.decide(g, GameData.make_item("Legs", 0, 5, g._new_id())) == "keep", "filter skipped during Auto when that's off")
	var bag1 := g.bag.size()
	g._give_item(GameData.make_item("Legs", 0, 5, g._new_id()))
	check(g.bag.size() == bag1 + 1, "...a real drop during Auto lands in the bag")
	AutoDive.set_value(g, "filter_in_auto", true)
	g._give_item(GameData.make_item("Legs", 0, 5, g._new_id()))
	check(g.bag.size() == bag1 + 1, "filter on during Auto: a real drop is dealt with")
	AutoDive.set_value(g, "filter_in_auto", false)
	g.autoplay = false
	check(LootRules.decide(g, GameData.make_item("Legs", 0, 5, g._new_id())) == "salvage", "...but still runs when you play yourself")
	# old rules move over
	g.loot_filter = {"slots": {"Chest": true}, "weaker": true, "below_gs": true}
	var lf := LootRules.rules(g)
	check(int(lf["v"]) == LootRules.VERSION and bool(lf["slots"]["Chest"]) and bool(lf["weaker"]) and bool(lf["below_gs"]), "old filter rules carry over")
	check(bool(lf["keep_sets"]) and String(lf["action"]) == "salvage", "old saves get the new keep rules")
	check(g.filter_salvages(GameData.make_item("Chest", 1, 5, g._new_id())), "filter_salvages still answers for old callers")
	check(LootRules.summary(g) != "", "summary line")
	LootRules.test_ignore_upgrades = false

# ---------------------------------------------------------------- auto-dive
func _auto_dive() -> void:
	var g := _hero()
	g.in_town = false
	g.autoplay = true
	g.floor_num = 12
	g.best_floor = 60  # the town is open, so Auto may head home
	g.spawn_enemy()
	g.potions = 5
	g.hero_hp = g.get_max_hp()
	check(AutoDive.home_reason(g) == "", "default settings: never heads home by itself")
	check(AutoRules.check(g) == "" and not g.go_home_after, "default settings: Auto carries on")
	# bag
	AutoDive.set_value(g, "bag_pct", 90)
	while g.bag.size() < g.bag_capacity():
		g.bag.append(GameData.make_item("Legs", 0, 5, g._new_id()))
	check(AutoDive.home_reason(g).contains("bag"), "bag full: head home")
	AutoDive.tick(g)
	check(g.go_home_after, "tick starts the trip home")
	g.go_home_after = false  # (home and back, bag still full)
	check(AutoDive.home_reason(g) == "", "bag rule fired once: doesn't fire again while the bag stays full")
	AutoDive.tick(g)
	check(not g.go_home_after, "...so the next dive isn't sent straight home")
	g.bag.clear()
	AutoDive.tick(g)
	while g.bag.size() < g.bag_capacity():
		g.bag.append(GameData.make_item("Legs", 0, 5, g._new_id()))
	check(AutoDive.home_reason(g).contains("bag"), "bag emptied then full again: the rule is back")
	# the trip home is refused: one clear note, once
	g.portal = {"kind": "test"}
	var said := g.messages.size()
	AutoDive.tick(g)
	check(not g.go_home_after and g.messages.size() == said + 1 and String(g.messages[-1]).contains("can't go home"), "blocked trip: one note why")
	AutoDive.tick(g)
	AutoDive.tick(g)
	check(g.messages.size() == said + 1, "...and only once")
	g.portal = {}
	AutoDive.tick(g)
	check(g.go_home_after, "way home open again: the rule tries again and Auto heads home")
	g.go_home_after = false
	g.bag.clear()
	AutoDive.tick(g)
	AutoDive.set_value(g, "bag_pct", 0)
	# potions
	AutoDive.set_value(g, "potions_at", 1)
	check(AutoDive.home_reason(g) == "", "5 potions, rule at 1: keep going")
	g.potions = 1
	check(AutoDive.home_reason(g).contains("potion"), "down to 1 potion: head home")
	AutoDive.set_value(g, "potions_at", -1)
	# HP
	AutoDive.set_value(g, "hp_pct", 30)
	g.hero_hp = int(g.get_max_hp() * 0.2)
	check(AutoDive.home_reason(g).contains("HP"), "low HP: head home")
	g.hero_hp = g.get_max_hp()
	check(AutoDive.home_reason(g) == "", "full HP: keep going")
	AutoDive.set_value(g, "hp_pct", 0)
	# floor N pauses Auto, once
	AutoDive.set_value(g, "stop_floor", 25)
	check(AutoDive.pause_reason(g) == "", "floor 12 of 25: keep going")
	g.floor_num = 25
	check(AutoRules.check(g).contains("25"), "reached floor 25: Auto pauses")
	check(AutoDive.pause_reason(g) == "", "resume on floor 25: no second pause")
	check(AutoDive.home_reason(g) == "", "floor rule never sends you home")
	g.floor_num = 26
	check(AutoDive.pause_reason(g) == "", "past it: keep going")
	g.floor_num = 25
	check(AutoDive.pause_reason(g).contains("25"), "back on floor 25 another dive: pauses again")
	check(AutoDive.pause_reason(g) == "", "(paused once)")
	g.in_town = true
	AutoDive.tick(g)  # a town visit re-arms it
	g.in_town = false
	check(AutoDive.pause_reason(g).contains("25"), "after a town visit, a dive that starts on floor 25 pauses there")
	AutoDive.set_value(g, "stop_floor", 0)
	AutoDive.step(g, "stop_floor", AutoDive.FLOOR_STEPS)
	check(int(AutoDive.value(g, "stop_floor")) == 25, "steps move to the next value")
	AutoDive.set_value(g, "stop_floor", 0)
	# team down
	var pt := Party.new()
	for n in 2:
		var mem := Party.Member.new()
		mem.slot = 20 + n
		mem.hp = 50
		pt.members.append(mem)
	g.party = pt
	AutoDive.set_value(g, "downs", 1)
	check(AutoDive.home_reason(g) == "", "team all up: keep going")
	pt.members[0].knocked_out = true
	pt.members[0].hp = 0
	check(AutoDive.team_down(g) == 1 and AutoDive.home_reason(g).contains("1 of your team"), "one down: head home")
	AutoDive.set_value(g, "downs", 2)
	check(AutoDive.home_reason(g) == "", "rule at 2, one down: keep going")
	AutoDive.set_value(g, "downs", 0)
	g.party = null
	# no trips home from town or with Auto off
	g.potions = 0
	AutoDive.set_value(g, "potions_at", 0)
	g.autoplay = false
	AutoDive.tick(g)
	check(not g.go_home_after, "Auto off: settings do nothing")
	g.autoplay = true
	AutoDive.set_value(g, "potions_at", -1)
	# elixir before a boss
	g.spawn_enemy()
	check(g.enemy_is_boss, "floor 25 has a boss")
	g.elixir_pack = {"might": 1}
	g.elixirs = {}
	AutoDive.tick(g)
	check(g.elixirs.is_empty(), "elixir rule off: nothing drunk")
	AutoDive.set_value(g, "elixir_boss", true)
	AutoDive.tick(g)
	check(int(g.elixirs.get("might", 0)) > 0 and g.supply_carried("might") == 0, "elixir rule: drinks one before the boss")
	g.elixir_pack = {"iron": 1, "fortune": 1}
	AutoDive.tick(g)
	AutoDive.tick(g)
	check(g.supply_carried("iron") == 1 and g.supply_carried("fortune") == 1, "only one elixir per boss, the rest stay in the pack")
	# the pause rules still pause (before bosses)
	AutoRules.toggle(g, "stop_boss")
	check(AutoRules.check(g).begins_with("a boss"), "stop before bosses still pauses Auto")
	check(AutoDive.label_for("bag_pct", 100) == "Full" and AutoDive.label_for("potions_at", -1) == "Off", "button words")

# ---------------------------------------------------------------- presets
func _presets() -> void:
	var g := _hero()
	g.in_town = true
	Presets.ensure(g)
	check(g.builds.size() == Presets.SLOTS, "four preset slots")
	check(not Presets.is_saved(g, 0) and Presets.summary(g, 0) == "Empty", "empty slot")
	var a := GameData.make_item("Weapon", 2, 30, 9100)
	var b := GameData.make_item("Weapon", 3, 30, 9101)
	g.bag.append(a)
	g.bag.append(b)
	g.equip(9100)
	g.stat_points = 10
	g.stats["STR"] = 5
	g.stat_points -= 5
	g.skill_book["test_skill"] = 1
	g.active_slots[2] = "test_skill"
	g.potions = 0
	g.supplies_home = {"potion": 5}
	g.move_supply("potion", 3)
	Presets.save(g, 0, "Boss")
	check(Presets.is_saved(g, 0) and Presets.name_of(g, 0) == "Boss", "saved and named")
	check(Presets.summary(g, 0).contains("gear") and Presets.summary(g, 0).contains("supplies"), "summary says what's in it")
	# change everything
	g.equip(9101)
	g.stats["STR"] = 0
	g.stats["VIT"] = 5
	g.active_slots[2] = ""
	g.move_supply("potion", -3)
	check(g.potions == 0, "test setup: potions back home")
	var notes := Presets.apply(g, 0)
	check(int(g.equipped["Weapon"]["id"]) == 9100, "preset puts the gear back on")
	check(int(g.stats["STR"]) == 5 and int(g.stats["VIT"]) == 0, "preset moves stat points back")
	check(String(g.active_slots[2]) == "test_skill", "preset puts the skill back")
	check(g.potions == 3, "preset takes the supplies down (%d potions)" % g.potions)
	check(notes.is_empty(), "nothing skipped when everything's there")
	# things that are gone are skipped, with a note
	g.equip(9101)
	for i in g.bag.size():
		if int(g.bag[i]["id"]) == 9100:
			g.bag.remove_at(i)
			break
	g.skill_book.erase("test_skill")
	g.active_slots[2] = ""
	g.move_supply("potion", -3)
	g.supplies_home["potion"] = 1
	g.builds[0]["party"] = [99]
	notes = Presets.apply(g, 0)
	var all := "\n".join(notes)
	check(int(g.equipped["Weapon"]["id"]) == 9101, "gone gear: what you wear stays on")
	check(all.contains("gone") and all.contains(GameData.display_name(a)), "note names the missing item")
	check(all.contains("skill book") and String(g.active_slots[2]) == "", "missing skill skipped with a note")
	check(all.contains("hero is gone") and g.party_slots.is_empty(), "missing team member skipped with a note")
	check(g.potions == 1 and all.contains("Only 1"), "short on supplies: takes what's home and says so")
	# vault, can't wear, doubles, supplies in the dungeon
	var c := GameData.make_item("Weapon", 2, 30, 9200)
	g.builds[1] = {"name": "V", "gear": {"Weapon": 9200}, "gear_names": {"Weapon": "Vault Blade"}, "party": [99, 99]}
	notes = Presets.apply(g, 1, [c])
	all = "\n".join(notes)
	check(all.contains("Vault Blade") and all.contains("vault") and not all.contains("Vault Blade: it's gone"), "gear in the vault says so")
	check(notes.count("Skipped a team member: that hero is gone.") == 1, "doubles in a team are dropped")
	var elf := GameData.make_item("Weapon", 2, 30, 9300)
	elf["race_only"] = "nobody"
	g.bag.append(elf)
	g.builds[1] = {"name": "E", "gear": {"Weapon": 9300}, "gear_names": {"Weapon": "Odd Blade"}}
	notes = Presets.apply(g, 1)
	check("\n".join(notes).contains("can't wear") and int(g.equipped["Weapon"]["id"]) == 9101, "gear this hero can't wear: skipped with a note")
	g.in_town = false
	g.builds[1] = {"name": "S", "supplies": {"potion": 4}}
	notes = Presets.apply(g, 1)
	check("\n".join(notes).contains("Supplies skipped"), "supplies in the dungeon: skipped with a note")
	g.in_town = true
	# old loadouts move into presets
	var h := _hero()
	h.loadouts[1] = {"Weapon": 1234}
	Presets.migrate(h)
	check(h.loadouts[1].is_empty() and Presets.name_of(h, 0) == "Gear set 2", "old gear loadouts become presets")
	Presets.migrate(h)
	check(not Presets.is_saved(h, 1), "moving them twice doesn't copy twice")
	Presets.rename(h, 0, "  Farming  ")
	check(Presets.name_of(h, 0) == "Farming", "rename")
	Presets.clear(h, 0)
	check(not Presets.is_saved(h, 0), "clear")
	# a full set of presets: old loadouts wait, nothing is dropped
	for k in Presets.SLOTS:
		h.builds[k] = {"name": "P%d" % k}
	h.loadouts[2] = {"Weapon": 555}
	Presets.migrate(h)
	check(h.loadouts[2].size() == 1, "presets full: the old gear set waits")
	Presets.clear(h, 3)
	Presets.migrate(h)
	check(h.loadouts[2].is_empty() and Presets.name_of(h, 3) == "Gear set 3", "...and moves over once a slot is free")
	_teams()

# ---------------------------------------------------------------- team line-ups (any hero)
func _teams() -> void:
	for n in [9, 10]:
		var s := _hero()
		s.autosave = true
		s.slot = n
		s.hero_name = "T%d" % n
		s.save_game(true)
	var g := _hero()
	g.slot = 9
	g.in_town = true
	var p := Profile.new()
	p.presets = [{"slots": [10, 9, 9, 77]}, {"slots": [9, 77]}, {}]
	var plan := Presets.team_plan(p, 0)
	check(int(plan["leader"]) == 10 and plan["comps"] == [9] and (plan["notes"] as Array).size() == 1, "team plan: leader, no doubles, gone hero noted")
	var out := Presets.apply_team(g, p, 0)
	check(int(out["switch"]) == 10 and out["comps"] == [9], "another leader: switch to that hero with the team")
	g.in_town = false
	out = Presets.apply_team(g, p, 0)
	check(int(out["switch"]) == -1 and "\n".join(out["notes"]).contains("in town"), "away from town: no switch, says why")
	g.in_town = true
	out = Presets.apply_team(g, p, 1)
	check(int(out["switch"]) == -1 and g.party_slots.is_empty() and "\n".join(out["notes"]).contains("gone"), "same leader: team set here, gone hero skipped")
	p.presets[2] = {"slots": [77, 9]}
	out = Presets.apply_team(g, p, 2)
	check(int(out["switch"]) == -1 and "\n".join(out["notes"]).contains("leader"), "leader gone: nothing happens, says why")
	check(Presets.team_label(p, 2).contains("(gone)"), "line-up names show a gone hero")
	# after switching heroes (main.gd): the team joins only in town
	var away := _hero()
	away.slot = 10
	away.hero_name = "Bryn"
	away.in_town = false
	var why := Presets.apply_pending_team(away, [9])
	check(why.contains("Bryn is in the dungeon") and away.party_slots.is_empty(), "leader in the dungeon: no team change, says so")
	away.in_town = true
	away.run_over = true
	check(Presets.apply_pending_team(away, [9]) != "" and away.party_slots.is_empty(), "run over: no team change")
	away.run_over = false
	away.hardcore = true
	check(Presets.apply_pending_team(away, [9]).contains("Hardcore") and away.party_slots.is_empty(), "Hardcore: no team")
	away.hardcore = false
	check(Presets.apply_pending_team(away, [9, 9, 10, 77]) == "" and away.party_slots == [9], "in town: the team joins (no doubles, not yourself, no gone heroes)")
	away.set_party([])
	check(Presets.team_leader_gone(p, 2) and not Presets.team_leader_gone(p, 0), "a line-up with a gone leader is marked")
	GameState.delete_slot(9)
	GameState.delete_slot(10)

# ---------------------------------------------------------------- save and load
func _save_load() -> void:
	var g := _hero()
	g.autosave = true
	g.slot = 8
	g.auto_salvage = 2
	LootRules.cycle_action(g)
	LootRules.toggle_slot(g, "Helmet")
	AutoDive.set_value(g, "bag_pct", 75)
	AutoDive.set_value(g, "elixir_boss", true)
	Presets.save(g, 3, "Slot four")
	g.save_game(true)
	var ld := GameState.new()
	ld.codex.path = ""
	ld.slot = 8
	check(ld.load_game(), "loads")
	check(ld.auto_salvage == 2 and String(LootRules.get_rule(ld, "action")) == "sell" and bool(LootRules.rules(ld)["slots"].get("Helmet", false)), "filter rules survive a save")
	check(int(AutoDive.value(ld, "bag_pct")) == 75 and bool(AutoDive.value(ld, "elixir_boss")), "auto-dive settings survive a save")
	check(ld.builds.size() == 4 and Presets.name_of(ld, 3) == "Slot four", "the fourth preset survives a save")
	GameState.delete_slot(8)
