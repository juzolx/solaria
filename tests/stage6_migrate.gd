extends SceneTree
const TestHero := preload("res://tests/test_hero.gd")
## Juzo's 2.0 heroes load in 2.1 (save_migrate.gd): his real 2.0 files (a read-only
## backup) are copied into the TEST user folder, the game starts on them, and
## every hero in every town, the stash and the Codex must come through.
## godot --headless --path . -s tests/stage6_migrate.gd
const SRC := "C:/gamedev/solaria_saves_backup_20261023_221457/"
const FILES := ["profile.dat", "codex.dat", "town1_hero_1.dat", "town2_hero_1.dat", "town3_hero_1.dat"]
var fails := 0

func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func _wipe() -> void:
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	var bdir := ProjectSettings.globalize_path(SaveMigrate.BACKUP_DIR)
	if DirAccess.dir_exists_absolute(bdir):
		for f in DirAccess.get_files_at(bdir):
			DirAccess.remove_absolute(bdir.path_join(f))

func _raw(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	var d = f.get_var() if f != null else {}
	return d if d is Dictionary else {}

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	_wipe()
	if not FileAccess.file_exists(SRC + "profile.dat"):
		print("(no 2.0 backup on this machine: only the synthetic checks run)")
		_synthetic()
		print("STAGE6 MIGRATE DONE, failures: ", fails)
		quit()
		return
	# Copy the 2.0 files into the test folder only (the backup itself is only read)
	var user := OS.get_user_data_dir()
	for f in FILES:
		DirAccess.copy_absolute(SRC + f, user.path_join(f))
	var old := {}
	for t in [1, 2, 3]:
		old[t] = _raw(SRC + "town%d_hero_1.dat" % t)
	var old_codex := _raw(SRC + "codex.dat")
	check(int(_raw(SRC + "profile.dat").get("save_epoch", 0)) == 12, "setup: the files are from 2.0 (epoch 12)")

	# --- First launch: the migration runs instead of the wipe ---
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var rep: Dictionary = SaveMigrate.report
	print("migrate report: ", rep)
	check(main.profile.save_epoch == Profile.SAVE_EPOCH, "epoch is 13 after the move")
	check(not main.fresh_start_notice and main.get_children().any(func(c): return c is WhatsNew), "a friendly notice, not the fresh start")
	var notice: Array = main.get_children().filter(func(c): return c is WhatsNew)
	if not notice.is_empty():
		check(str(notice[0].content.get_children().map(func(c): return c.text if "text" in c else "")).contains("made it into 2.1"), "the notice says the heroes made it")
	check(int(rep.get("heroes", 0)) == 3, "all three heroes moved")
	check((rep.get("unmapped", []) as Array).size() <= 3, "almost every old name maps to an id: %s" % [rep.get("unmapped", [])])
	check(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SaveMigrate.BACKUP_DIR)), "a pre-2.1 copy was kept")
	for t in [1, 2, 3]:
		check(GameState.town_heroes(t) == 1, "town %d still has its hero" % t)

	# --- Every hero in every town loads and keeps everything ---
	var codex: Codex = main.codex
	var expected_dust := {}
	for t in [1, 2, 3]:
		var o: Dictionary = old[t]
		var raw := _raw(user.path_join("town%d_hero_1.dat" % t))
		check(not raw.has("materials"), "town %d: materials key is gone" % t)
		check(not (raw.get("class_tree", {}) as Dictionary).has("branch") and not (raw.get("class_tree", {}) as Dictionary).has("items"), "town %d: old class-tree fields dropped" % t)
		var mats := 0
		for v in o.get("materials", []):
			mats += int(v)
		expected_dust[t] = int(o.get("dust", 0)) + ceili(mats / 10.0)
		GameState.town = t
		var g := GameState.new()
		g.codex = codex
		g.slot = 1
		check(g.load_game(), "town %d: hero loads" % t)
		check(g.level == int(o["level"]) and g.hero_class == String(o["hero_class"]), "town %d: level and class kept (%d %s)" % [t, g.level, g.hero_class])
		check(g.gold == int(o["gold"]) and g.bank == int(o["bank"]) and g.scrap == int(o["scrap"]), "town %d: gold, bank and scrap kept" % t)
		check(g.dust == int(expected_dust[t]) and g.dust > int(o.get("dust", 0)), "town %d: dust %d -> %d (materials %d)" % [t, int(o.get("dust", 0)), g.dust, mats])
		check(g.best_floor == int(o["best_floor"]), "town %d: best floor kept" % t)
		var old_eq: Dictionary = o["equipped"]
		for s in old_eq:
			check(g.equipped.has(s) and int(g.equipped[s]["id"]) == int(old_eq[s]["id"]), "town %d: %s still worn" % [t, s])
		check(g.bag.size() == (o["bag"] as Array).size(), "town %d: bag kept" % t)
		check(g.pets.size() == (o["pets"] as Array).size() and g.pets.size() > 0, "town %d: no pet lost (%d)" % [t, g.pets.size()])
		for p in g.pets:
			check(not Monsters.by_id(String(p["species"])).is_empty(), "town %d: pet species is an id: %s" % [t, p["species"]])
		for s in g.equipped:
			var it: Dictionary = g.equipped[s]
			if String(it.get("set", "")) != "":
				check(not GameData.set_info(String(it["set"])).is_empty() and String(it.get("def", "")) != "", "town %d: set item has a set id and def: %s" % [t, it["base_name"]])
		for it in g.bag:
			if int(it["rarity"]) == GameData.SIGNATURE:
				check(String(it.get("def", "")).begins_with("sig_") and not Monsters.by_id(String(it["sig_of"])).is_empty(), "town %d: Signature has an owner id: %s" % [t, it["base_name"]])
		for c in g.contracts:
			if String(c.get("monster", "")) != "":
				check(not Monsters.by_id(String(c["monster"])).is_empty(), "town %d: contract target is an id: %s" % [t, c["monster"]])
		for k in g.wardrobe:
			if String(k).begins_with("set:"):
				check(String(k).find(" ") < 0, "town %d: wardrobe set key is an id: %s" % [t, k])
		check(g.equipped.get("Ring", {}).is_empty() and g.equipped.get("Necklace", {}).is_empty(), "town %d: new jewelry slots start empty" % t)
		check(g.get_max_hp() > 0 and g.hero_hp > 0, "town %d: hero is alive and sane" % t)
		Presets.migrate(g)
		if t == 1:
			check(g.hidden_class == "fool" and Hidden.stage(g) == 2, "hidden class kept at the 2.1 step")
			check(String(g.grave.get("killer", "")) == "ankou", "grave killer is an id")
			check(g.discovered.has("rogue") and g.discovered.has("fool"), "discovered classes are ids")
			check((g.feats.get("befriended", {}) as Dictionary).has("will_o_wisp"), "befriended monsters are ids")
			# Set items from the town stash give their set bonus
			var plate := {}
			var bulwark := {}
			for it in main.profile.stash:
				check(String(it.get("set", "")) == "" or not GameData.set_info(String(it["set"])).is_empty(), "stash set item has a set id: %s" % it["base_name"])
				if String(it.get("def", "")) == "bulwark_of_ages_chest":
					plate = it
				if String(it.get("def", "")) == "bulwark_of_ages_off_hand":
					bulwark = it
			check(not plate.is_empty() and not bulwark.is_empty(), "stash set pieces found by def")
			var before := g.set_bonuses().size()
			g.equipped["Chest"] = plate
			g.equipped["Off Hand"] = bulwark
			check(g.set_bonuses().size() > before and g.set_counts().get("bulwark_of_ages", 0) >= 2, "migrated set items give set bonuses")
			# Saving and reloading
			g.save_game(true)
			var g2 := GameState.new()
			g2.codex = codex
			g2.slot = 1
			check(g2.load_game() and g2.level == g.level and g2.dust == g.dust and g2.pets.size() == g.pets.size() and g2.set_counts().get("bulwark_of_ages", 0) >= 2, "save and reload keeps it all")
		if t == 3:
			check(g.class_path.size() == 1 and g.class_path[0] == "demonic_disciple", "a pick allowed by 2.1 is kept")

	# --- The Codex ---
	var ob: Dictionary = old_codex["bestiary"]
	check(codex.kills("redcap") == int(ob["Redcap"]["kills"]), "bestiary kills kept under the id")
	check(codex.kills("will_o_wisp") == int(ob["Will-o'-Wisp"]["kills"]), "names with punctuation map")
	check(codex.kills("grendel") == int(ob.get("Grendel", {}).get("kills", 0)) and codex.kills("grendel") > 0, "boss kills keyed by id (boss:grendel)")
	var id_keys := 0
	for k in codex.bestiary:
		if not Monsters.by_id(String(k)).is_empty():
			id_keys += 1
	check(id_keys >= ob.size() - 3, "bestiary is id-keyed (%d of %d)" % [id_keys, ob.size()])
	var want_seen := 0
	for k in ob:
		if Monsters.id_of(String(k)) in Monsters.all_monsters():
			want_seen += 1
	check(want_seen > 10 and codex.value("seen") == want_seen, "monsters seen are counted (%d of %d)" % [codex.value("seen"), want_seen])
	check(codex.value("signatures") >= 2, "Signatures counted")
	check(codex.collection.has("umbral_regalia_feet") and codex.collection.has("anniss_skinning_claw") and codex.collection.has("sig_draugr"), "collection keyed by def ids")
	check(codex.value("uniques") >= 1, "uniques counted")
	for k in codex.pet_book:
		check(not Monsters.by_id(String(k)).is_empty(), "pet book key is an id: %s" % k)
	check(codex.pet_book.size() == (old_codex["pet_book"] as Dictionary).size(), "pet book kept")
	for b in codex.bounties.get("daily", []):
		if String(b.get("monster", "")) != "":
			check(not Monsters.by_id(String(b["monster"])).is_empty(), "bounty target is an id")
	check(codex.achievements.size() == (old_codex["achievements"] as Dictionary).size(), "achievements kept")
	main.queue_free()
	await process_frame

	# --- Second launch: nothing runs twice ---
	var main2 = load("res://main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	check(not main2.migrate_notice and not main2.fresh_start_notice and main2.profile.save_epoch == Profile.SAVE_EPOCH, "the move happens once")
	check(main2.codex.kills("redcap") == int(ob["Redcap"]["kills"]), "codex survives the next launch")
	main2.queue_free()
	await process_frame

	# --- A title-screen start with the moved saves ---
	TitleScreen.pending = {"play": 1}
	var main3 = load("res://main.tscn").instantiate()
	root.add_child(main3)
	for i in 30:
		await process_frame
	check(main3.started and main3.state.level == int(old[main3.profile.town]["level"]), "the game starts on a moved hero from the title screen")
	for i in 20:
		main3._on_tick()
		await process_frame
	check(main3.state.hero_hp > 0 or main3.state.in_town or main3.state.floor_num >= 1, "the moved hero plays")
	main3.queue_free()
	await process_frame
	_synthetic()
	_wipe()
	print("STAGE6 MIGRATE DONE, failures: ", fails)
	quit()

## Rules that Juzo's files don't exercise: a class picked earlier than 2.1 allows.
func _synthetic() -> void:
	var cls := "Wanderer"
	var a := String(ClassTree.roots(cls)[0])
	var b := String(ClassTree.children(a)[0])
	var c := String(ClassTree.children(b)[0])
	var d := {"level": 60, "hero_class": cls, "materials": [5, 0, 1], "dust": 2,
		"class_tree": {"path": [a, b, c], "branch": "x", "items": ["y"]},
		"discovered": {String(ClassTree.node(a)["name"]): true},
		"pets": [{"id": 1, "name": "Redcap", "species": "Redcap", "art": "redcap", "tier": 1}],
		"bag": [{"id": 2, "base_name": "Helroad Boots", "name": "Helroad Boots", "slot": "Feet", "rarity": 6, "set": "Hel's Shroud"}]}
	SaveMigrate.migrate_hero(d)
	check((d["class_tree"]["path"] as Array) == [a, b], "a final picked at 60 is handed back (offered again at 75)")
	check(not d.has("materials") and int(d["dust"]) == 3, "6 materials -> 1 dust (rounded up)")
	check(not d["class_tree"].has("branch") and not d["class_tree"].has("items"), "obsolete class fields removed")
	check(d["pets"][0]["species"] == "redcap" and d["bag"][0]["set"] == "hels_shroud" and d["bag"][0]["def"] == "hels_shroud_feet", "pets and set items re-keyed")
	check(d["discovered"].has(a), "discovered names become ids")
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class(cls)
	g.class_path.assign(d["class_tree"]["path"])
	g.level = 74
	check(ClassTree.pick_tier(g) == -1, "not before 75")
	g.level = 75
	check(ClassTree.pick_tier(g) == 2 and ClassTree.options(g).any(func(o): return String(o["id"]) == c), "the final is offered again at 75")
	# Nothing unknown crashes
	var junk := {"level": 3, "hero_class": "Nobody", "class_tree": {"path": ["gone"]}, "pets": [{"species": "Long Gone Beast"}],
		"bag": [{"base_name": "Mystery", "slot": "Weapon", "rarity": 7, "sig_of": "Nobody"}, {"base_name": "Lost Set Piece", "slot": "Legs", "rarity": 6, "set": "Gone Set"}],
		"contracts": [{"monster": "Nobody"}], "grave": {"killer": "Nobody"}}
	SaveMigrate.migrate_hero(junk)
	check(junk["pets"][0]["species"] == "Long Gone Beast" and (junk["class_tree"]["path"] as Array).is_empty(), "unknown names are kept harmlessly, unknown classes dropped")
