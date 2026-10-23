extends SceneTree
## 2.1 G4 collection rewards (owner D6 b: titles + cosmetics, never stats) and
## G8 the share card.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)

func ids(list: Array) -> Array:
	return list.map(func(m): return String(m["id"]))

func fresh_codex() -> Codex:
	var c := Codex.new()
	c.path = ""
	return c

func _initialize() -> void:
	_data()
	_grant_once()
	_tracks()
	_no_stats()
	_save_load()
	await _share_card()
	print("STAGE6 COLLECTIONS TESTS DONE, failures: ", fails)
	quit()

## The list itself: stable, unique, every milestone gives something, nothing else.
func _data() -> void:
	var all := Collections.all()
	check(all.size() >= 50, "plenty of milestones (%d)" % all.size())
	var seen := {}
	var titles := {}
	for m in all:
		var id := String(m["id"])
		check(not seen.has(id), "milestone ids are unique (%s)" % id)
		seen[id] = true
		check(m.has("title") or m.has("look"), "every milestone gives a title or a look (%s)" % id)
		for k in m:
			check(String(k) in ["id", "track", "need", "pct", "title", "look"], "a milestone only holds words and looks, no stats (%s: %s)" % [id, k])
		check(int(m["need"]) >= 1, "every milestone needs something (%s)" % id)
		if m.has("title"):
			check(not titles.has(m["title"]), "titles are unique (%s)" % m["title"])
			titles[m["title"]] = true
	for a in Codex.ACHIEVEMENTS:
		if a.has("title"):
			check(not titles.has(a["title"]), "a Codex title doesn't repeat a deed title (%s)" % a["title"])
	for e in Cosmetics.SHOP_TITLES:
		check(not titles.has(e["name"]), "nor a shop title (%s)" % e["name"])
	for z in GameData.ZONES:
		check(Collections.on_track("zone:" + String(z["id"])).size() == 3, "every region has 25/50/100%% rewards (%s)" % z["id"])
		check(Collections.ZONE_REWARDS.has(String(z["id"])), "every region has its own reward names (%s)" % z["id"])
		check(Collections.total("zone:" + String(z["id"])) == Collections.zone_monsters(String(z["id"])).size() and Collections.total("zone:" + String(z["id"])) > 0, "a region's Bestiary has monsters")
	for sid in GameData.SET_ORDER:
		check(Collections.SET_TITLES.has(sid), "every set has a title (%s)" % sid)
	for list in [Collections.colors(), Collections.frames()]:
		var lids := {}
		for e in list:
			check(not lids.has(e["id"]), "look ids are unique (%s)" % e["id"])
			lids[e["id"]] = true
			check(String(e["need"]).begins_with("coll:") and not Collections.milestone(String(e["need"]).substr(5)).is_empty(), "each look points at its milestone (%s)" % e["id"])
			check(Cosmetics.need_name(e) != "", "each look says how to earn it (%s)" % e["name"])
	for e in Collections.colors():
		for o in Cosmetics.COLORS + Cosmetics.SHOP_COLORS:
			check(String(o["id"]) != String(e["id"]), "Codex colors don't reuse an id (%s)" % e["id"])
	for e in Collections.frames():
		for o in Cosmetics.FRAMES:
			check(String(o["id"]) != String(e["id"]), "Codex frames don't reuse an id (%s)" % e["id"])
	check(Collections.tracks().size() == ids(all).map(func(i): return String(Collections.milestone(i)["track"])).reduce(func(acc, t): return acc if t in acc else acc + [t], []).size(), "every track shows in the Rewards tab")

## A region's Bestiary: each step grants its title and look exactly once.
func _grant_once() -> void:
	var c := fresh_codex()
	check(Collections.check(c).is_empty(), "nothing earned on a new Codex")
	var mons := Collections.zone_monsters("mossy_hollows")
	var quarter := ceili(mons.size() * 0.25)
	for i in quarter:
		c.entry(mons[i])["kills"] = 1
	var got := ids(Collections.check(c))
	check(got == ["best_mossy_hollows_25"], "25%% of the Mossy Hollows earns its first reward (%s)" % str(got))
	check(Collections.check(c).is_empty(), "and only once")
	c.name_color = "z_mossy_hollows"
	check(Cosmetics.name_color(c) == Color(String(Collections.colors()[0]["color"])), "the region's name color can be worn")
	check(not "Warden of the Hollows" in c.titles(), "no title yet at 25%")
	for id in mons:
		c.entry(id)["kills"] = 1
	got = ids(Collections.check(c))
	check(got == ["best_mossy_hollows_50", "best_mossy_hollows_100"], "100%% earns the 50%% and 100%% rewards together (%s)" % str(got))
	check(Collections.check(c).is_empty(), "still only once")
	check("Warden of the Hollows" in c.titles() and "Heart of the Moss" in c.titles(), "both titles are yours")
	c.frame = "z_mossy_hollows"
	check(String(Cosmetics.frame(c)["id"]) == "z_mossy_hollows", "the region's frame can be worn")
	c.frame = "z_sunken_catacombs"
	check(String(Cosmetics.frame(c)["id"]) == "", "an unearned region frame doesn't show")
	var seen_only := fresh_codex()
	for id in mons:
		seen_only.meet(id)
	check(Collections.check(seen_only).is_empty(), "meeting monsters isn't enough: they must be defeated")

## Items, pets, classes and trophies.
func _tracks() -> void:
	var c := fresh_codex()
	for slot in GameData.SETS["grendels_kin"]["pieces"]:
		c.collection[GameData.piece_id("grendels_kin", slot)] = "x"
	var got := ids(Collections.check(c))
	check("set_grendels_kin" in got and "Heir of Grendel's Kin" in c.titles(), "a whole set earns its title (%s)" % str(got))
	check(Collections.count(c, "slots") == 3, "set pieces fill their slots (%d)" % Collections.count(c, "slots"))
	var mons := Monsters.all_monsters()
	for i in 5:
		c.found_pet(mons[i], 0)
	check("pets_5" in ids(Collections.check(c)), "5 kinds of pet earn the kennel color")
	c.found_pet(mons[6], 5)
	check("pet_myth" in ids(Collections.check(c)), "a Mythic pet earns Mythtamer")
	Trophies.data = {}
	for i in 5:
		Trophies.data["t%d" % i] = {"kind": "boss", "name": "x", "n": i}
	check("troph_5" in ids(Collections.check(c)), "5 trophies in the cabin earn a reward")
	Trophies.data = {}
	# Secret and God classes, through the real unlocks
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	Hidden.unlock(g, "jester")
	check(g.codex.classes_found.has("jester"), "a secret class found is recorded by id")
	g.level = 75
	g.class_path.assign(["champion", "weaponmaster", "colossus"])
	g.feats["kills_total"] = 25000
	g.feats["clean_best"] = 2000
	g.codex.stats["champions"] = 20
	g.events.clear()
	Hidden.check(g)
	check(g.codex.classes_found.has("god_titan"), "a God class that answers is recorded")
	check(Collections.count(g.codex, "secret") == g.codex.classes_found.size() - 1 and Collections.count(g.codex, "god") == 1, "secret and God classes count apart (%s)" % str(g.codex.classes_found.keys()))
	g.events.clear()
	g._check_codex()
	var toasts := g.events.filter(func(e): return e.get("type", "") == "toast" and e.has("collection"))
	var tids := toasts.map(func(e): return String(e["collection"]))
	check("secret_1" in tids and "god_1" in tids, "the game hands out Codex rewards with a toast (%s)" % str(tids))
	for e in toasts:
		check(not String(e["text"]).contains("Jester") and not String(e["text"]).contains("Titan"), "the toast never names a secret class")

## Owner D6 b: rewards are titles and looks, never power.
func _no_stats() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Warrior")
	g.level = 40
	var before := [g.get_attack(), g.get_defense(), g.get_max_hp(), g.gold, g.scrap, g.dust, g.potions]
	for m in Collections.all():
		g.codex.coll_earned[m["id"]] = "x"
	g.codex.title = "Heart of the Moss"
	g.codex.name_color = "z_elf"
	g.codex.frame = "c_godlight"
	g._check_codex()
	var after := [g.get_attack(), g.get_defense(), g.get_max_hp(), g.gold, g.scrap, g.dust, g.potions]
	check(before == after, "every reward earned and worn: no stat, gold or item changes (%s vs %s)" % [str(before), str(after)])
	check(String(Cosmetics.frame(g.codex)["id"]) == "c_godlight" and Cosmetics.name_color(g.codex) != Color("#e5e7eb"), "and the looks show")

func _save_load() -> void:
	var path := "user://test_collections_codex.dat"
	var c := Codex.new()
	c.path = path
	c.coll_earned = {"best_elf_25": "2026-10-23", "set_tidecaller": "2026-10-23", "secret_1": "2026-10-23"}
	c.classes_found = {"jester": "2026-10-23"}
	c.title = "The Tidecaller"
	c.save()
	var d := Codex.load_codex(path)
	check(d.coll_earned.has("best_elf_25") and d.coll_earned.has("set_tidecaller"), "earned rewards are saved with the Codex")
	check(d.classes_found.has("jester"), "found classes are saved")
	check(d.title == "The Tidecaller" and "The Tidecaller" in d.titles(), "a Codex title stays picked after loading")
	check(Collections.check(d).is_empty(), "loading never grants a reward twice")
	var e := fresh_codex()
	e._from({"coll_earned": {"no_such_milestone": "x"}})
	check(Collections.titles(e).is_empty() and Collections.check(e).is_empty(), "an unknown milestone id in a save is harmless")
	SaveIO.delete_all(path)

## G8: what's on the card, its size, and (only with a real window) the PNG itself.
func _share_card() -> void:
	var g := GameState.new()
	g.codex.path = ""
	g.autosave = false
	g.new_game()
	g.choose_class("Mage")
	g.hero_name = "Ari/../Vel"
	g.level = 33
	g.best_floor = 120
	g.codex.coll_earned["best_mossy_hollows_50"] = "x"
	g.codex.title = "Warden of the Hollows"
	Menagerie.make_pet(g, "kobold", "kobold", 4, "egg")
	var p := Profile.new()
	Trophies.data = {"boss:grendel": {"kind": "boss", "name": "Slew Grendel", "n": 0}, "floor:100": {"kind": "floor", "name": "Reached floor 100", "n": 1},
		"calamity:0": {"kind": "calamity", "name": "Ended the Calamity of Ash", "n": 2}}
	var f := ShareCard.facts(g, g.codex, p)
	check(String(f["pet"]).begins_with("Kobold") and (f["trophies"] as Array).size() == 3 and String(f["trophies"][0]).contains("Calamity"), "the pet and the proudest trophies (Calamities first): %s %s" % [f["pet"], str(f["trophies"])])
	check(f["name"] == "Ari/../Vel" and f["title"] == "Warden of the Hollows" and int(f["level"]) == 33 and int(f["deepest"]) == 120, "the card shows name, title, level and depth")
	check(String(f["class"]) == g.title() and String(f["race"]) == g.race() and String(f["town"]) != "", "class, race and town")
	var fn := ShareCard.file_name(g.hero_name)
	check(fn.begins_with("solaria_arivel_") and fn.ends_with(".png") and not fn.contains("/") and not fn.contains(".."), "the file name is safe (%s)" % fn)
	check(ShareCard.W * ShareCard.SCALE == 1080 and ShareCard.H * ShareCard.SCALE == 1350, "the card is 1080 x 1350")
	var vp := ShareCard.build(g, g.codex, p)
	check(vp is SubViewport and vp.size == Vector2i(1080 / ShareCard.SCALE, 1350 / ShareCard.SCALE), "the card is laid out at its small size")
	if not ShareCard.can_render():
		vp.free()
		var none = await ShareCard.render(root, g, g.codex, p)
		check(none == null, "headless: rendering is skipped safely")
		print("share card: PNG render skipped (headless)")
		Trophies.data = {}
		return
	vp.free()
	var img: Image = await ShareCard.render(root, g, g.codex, p)
	check(img != null and img.get_width() == 1080 and img.get_height() == 1350, "the card renders at 1080 x 1350")
	var path := ShareCard.save(img, g.hero_name)
	check(path != "" and FileAccess.file_exists(path), "the card is saved as a PNG")
	var back := Image.load_from_file(path)
	check(back != null and back.get_size() == Vector2i(1080, 1350), "the saved PNG is 1080 x 1350")
	print("share card saved: ", ProjectSettings.globalize_path(path))
	Trophies.data = {}
