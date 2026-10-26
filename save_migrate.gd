class_name SaveMigrate
extends RefCounted
## One-time move of Solaria 2.0 saves (Profile.save_epoch 12) into 2.1 (epoch 13).
## Juzo (Oct 24): old heroes must load in 2.1, no wipe. Every town, every hero,
## the stash and the Codex are kept; only what 2.1 no longer has is converted:
##
##  - The ten zone materials become dust (MATS_PER_DUST below), then the key goes.
##  - Everything 2.0 keyed by a display NAME is re-keyed by its stable id
##    (claude/stable-ids.md): Codex bestiary / collection / pet book / bounties,
##    pets and their species, item "set" / "def" / art, Signature owners,
##    wardrobe and transmog keys, contracts, the grave's killer, befriended
##    monsters and discovered classes.
##  - Class route: picks made earlier than the 2.1 levels (15 / 35 / 75) are
##    handed back and offered again when the hero gets there; the hero keeps
##    level, gear and everything else. Old tree fields (branch, items) go.
##
## Anything that can't be mapped is left as it was: unknown keys are harmless in
## 2.1 (counters iterate the data, name_of() falls back to the id). Nothing is
## deleted except the material counts (paid out as dust) and the obsolete
## class-tree fields. Before touching anything every file is copied to
## user://pre_2_1_backup, and SaveIO also keeps the 2.0 file as the first .bak.

const FROM_EPOCH := 12
## 2.0 materials -> 2.1 dust: 1 dust for every 10 materials (all zones added up),
## rounded up. 2.0 paid 1-8 materials where 2.1 pays the same number in dust
## (claude/economy.md), but 2.0 heroes also piled up hundreds from chests and
## goblins that 2.1 pays in scrap, so a 1:1 swap would flood the new dust economy.
const MATS_PER_DUST := 10
const BACKUP_DIR := "user://pre_2_1_backup"
## Hero keys that 2.1 no longer has.
const DROP_HERO_KEYS := ["materials", "class_branch", "class_items", "class_spec"]
const DROP_TREE_KEYS := ["branch", "items", "spec", "trials", "god_trial"]

## What the last run did (tests and the notice read it).
static var report := {}

## True when these saves were made by 2.0 and should be moved over.
## no_profile: the settings file is missing; 2.0 town hero files (no SaveIO
## "save_kind") with no settings file are 2.0 heroes too.
static func due(p: Profile, no_profile: bool) -> bool:
	if p.save_epoch == FROM_EPOCH:
		return true
	if no_profile and p.save_epoch < Profile.SAVE_EPOCH:
		return _has_old_town_heroes()
	return false

static func _has_old_town_heroes() -> bool:
	for path in hero_paths():
		if SaveIO.exists(path) and not SaveIO.made_by_save_io(path, "hero"):
			return true
	return false

## Every hero save this move touches: each town's slots, plus 2.0 files that
## haven't been moved into towns yet (hero_N.dat, save.dat, save_hc.dat: main
## moves those after this runs, already converted).
static func hero_paths() -> Array:
	var out: Array = []
	for t in range(1, GameData.MAX_TOWNS + 1):
		for n in range(1, GameData.MAX_HEROES + 1):
			out.append(GameState.town_slot_paths(t, n)[0])
	for n in range(1, GameData.MAX_HEROES + 1):
		out.append(GameState.OLD_SLOT_PATH % n)
	out.append_array([GameState.SAVE_PATH, GameState.HC_SAVE_PATH])
	return out

static var test_fail_backup := false  # tests: pretend the safety copy failed

## Runs the whole move. The profile and codex passed in are changed and saved.
## report["ok"] is true only when every file was written: otherwise save_epoch
## stays 12 and the move simply runs again next launch (every step is safe to
## repeat: materials are gone once paid, ids stay ids).
static func run(p: Profile, codex: Codex) -> Dictionary:
	report = {"ok": false, "heroes": 0, "dust": 0, "unmapped": [], "class_reset": 0, "pets": 0}
	# From here on any save of the profile says "2.0, not moved yet", so a failed run is
	# retried next launch and never mistaken for older saves (which are wiped).
	p.save_epoch = maxi(p.save_epoch, FROM_EPOCH)
	if not _backup_all():
		push_warning("SaveMigrate: the pre-2.1 safety copy failed; nothing was changed (it tries again next launch)")
		return report
	var all_ok := true
	for path in hero_paths():
		if not SaveIO.exists(path):
			continue
		var res := SaveIO.load_file(path, "hero")
		if res["data"] == null:
			continue  # unreadable: left exactly as it is
		var d: Dictionary = res["data"]
		migrate_hero(d, codex)
		if SaveIO.write(path, d, "hero"):
			report["heroes"] = int(report["heroes"]) + 1
			if not path.contains("town"):  # a pre-towns file: main moves .dat/.bak/.tmp into a town next,
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveIO.day_path(path)))  # so no stray daily copy stays behind
		else:
			all_ok = false
			push_warning("SaveMigrate: couldn't write %s; it is moved again next launch" % path)
	# Each town's stash (Profile.stash is the same array as the current town's)
	for k in p.towns:
		var tw: Dictionary = p.towns[k]
		_walk_items(tw.get("stash", []))
	_walk_items(p.stash)
	migrate_codex(codex)
	codex.save()  # the codex first: the profile's epoch is what says the move is done
	all_ok = all_ok and _codex_written(codex)
	if all_ok:
		p.save_epoch = Profile.SAVE_EPOCH
	p.save()
	report["ok"] = all_ok and _profile_written()
	return report

## Did the codex land on disk as it is now (read back, the bestiary keys match)?
static func _codex_written(codex: Codex) -> bool:
	if codex.path == "":
		return true  # a test codex that never saves
	var d = SaveIO.read(codex.path, "codex")
	return d is Dictionary and ((d as Dictionary).get("bestiary", {}) as Dictionary).keys() == codex.bestiary.keys()

## Did the profile land on disk marked as moved?
static func _profile_written() -> bool:
	var d = SaveIO.read(Profile.PATH, "profile")
	return d is Dictionary and int((d as Dictionary).get("save_epoch", 0)) == Profile.SAVE_EPOCH

## Copies every save file to user://pre_2_1_backup. False if any copy failed.
static func _backup_all() -> bool:
	if test_fail_backup:
		return false
	var bdir := ProjectSettings.globalize_path(BACKUP_DIR)
	if DirAccess.make_dir_recursive_absolute(bdir) != OK:
		return false
	var files: Array = [Profile.PATH, Codex.PATH]
	for path in hero_paths():
		files.append_array(SaveIO.all_paths(path))
	for f in files:
		if FileAccess.file_exists(f):
			var src := ProjectSettings.globalize_path(f)
			var dst := bdir.path_join(src.get_file())
			if FileAccess.file_exists(dst):
				continue  # never overwrite the first copy (a retry keeps the original 2.0 file)
			if DirAccess.copy_absolute(src, dst) != OK:
				return false
	return true
# ---------------------------------------------------------------------
# One hero file (the raw saved Dictionary, before GameState reads it)
# ---------------------------------------------------------------------

static func migrate_hero(d: Dictionary, codex: Codex = null) -> void:
	# Materials -> dust
	var mats := 0
	for v in d.get("materials", []):
		mats += maxi(0, int(v))
	var dust := ceili(float(mats) / MATS_PER_DUST)
	d["dust"] = int(d.get("dust", 0)) + dust
	report["dust"] = int(report.get("dust", 0)) + dust
	for k in DROP_HERO_KEYS:
		d.erase(k)
	# Every item anywhere in the save (bag, gear, shop, grave, mail, smith, merchant...)
	_walk_items(d)
	# Pets and the pet book
	for pet in d.get("pets", []):
		if pet is Dictionary:
			var sp := monster_id(String(pet.get("species", "")), String(pet.get("art", "")))
			if sp != "":
				pet["species"] = sp
			report["pets"] = int(report.get("pets", 0)) + 1
	for egg in d.get("eggs", []):
		if egg is Dictionary and egg.has("species"):
			var sp := monster_id(String(egg["species"]), String(egg.get("art", "")))
			if sp != "":
				egg["species"] = sp
	# Contracts (Bounty Board) and the grave
	for c in d.get("contracts", []):
		if c is Dictionary and String(c.get("monster", "")) != "":
			var mid := monster_id(String(c["monster"]))
			if mid != "":
				c["monster"] = mid
	var grave: Dictionary = d.get("grave", {})
	if grave.has("killer"):
		var kid := monster_id(String(grave["killer"]), String(grave.get("art", "")))
		if kid != "":
			grave["killer"] = kid
	# Lineage: befriended monsters
	var lin: Dictionary = d.get("lineage", {})
	var feats: Dictionary = lin.get("feats", {})
	if feats.get("befriended") is Dictionary:
		var out := {}
		for k in feats["befriended"]:
			var mid := monster_id(String(k))
			out[mid if mid != "" else String(k)] = feats["befriended"][k]
		feats["befriended"] = out
	# Wardrobe keys and transmog
	_migrate_wardrobe(d)
	# Retired races (Golem -> Dwarf): the hero keeps stats, level and gear
	# (also its skin, its standing with that race and the slot summary the menus show)
	Races.retire_look(d.get("appearance", {}))
	if d.get("meta") is Dictionary:
		Races.retire_look((d["meta"] as Dictionary).get("appearance", {}))
	Races.retire_rep(lin.get("rep", {}))
	# Class route
	_migrate_class(d, lin, codex)

static func _migrate_class(d: Dictionary, lin: Dictionary, codex: Codex) -> void:
	var ct: Dictionary = d.get("class_tree", {})
	for k in DROP_TREE_KEYS:
		ct.erase(k)
	var level := int(d.get("level", 1))
	var cls := String(d.get("hero_class", ""))
	var keep: Array = []
	for i in (ct.get("path", []) as Array).size():
		var id := String(ct["path"][i])
		var n := ClassTree.node(id)
		if n.is_empty() or String(n["cls"]) != cls or n.get("god", false):
			continue  # gone from 2.1: ClassTree.from_save would drop it anyway
		if i >= ClassTree.PICK_LEVELS.size() or level < int(ClassTree.PICK_LEVELS[i]):
			break  # picked before 2.1 allows it: offered again at the right level
		keep.append(id)
	if keep.size() < (ct.get("path", []) as Array).size():
		report["class_reset"] = int(report.get("class_reset", 0)) + 1
		# (a Signature skill of a handed-back class is swapped by load_game for one the hero still owns)
	ct["path"] = keep
	# A hidden class: its step follows the 2.1 levels (15 / 35 / 75)
	var hc := String(lin.get("hidden_class", ""))
	if hc != "" and not Hidden.info(hc).is_empty():
		var st := 1
		for i in Hidden.STAGE_LEVELS.size():
			if level >= int(Hidden.STAGE_LEVELS[i]):
				st = i + 1
		var stages: Dictionary = lin.get("hidden_stage", {})
		stages[hc] = st
		lin["hidden_stage"] = stages
	elif hc != "":
		lin["hidden_class"] = ""  # a hidden class 2.1 doesn't have: back to the main route
	if codex != null:
		for id in lin.get("hidden", {}):
			if not Hidden.info(String(id)).is_empty():
				Collections.found_class(codex, String(id))
	# Discovered classes: 2.1 records ids (class nodes, hidden and God classes)
	var disc := {}
	for k in d.get("discovered", {}):
		var id := class_id(String(k))
		disc[id if id != "" else String(k)] = true
	for id in keep:
		disc[id] = true
	d["discovered"] = disc

## A class node / hidden / God class id from an id or a 2.0 name ("" if unknown).
static func class_id(name_or_id: String) -> String:
	if not ClassTree.node(name_or_id).is_empty() or not Hidden.info(name_or_id).is_empty():
		return name_or_id
	var n := ClassTree.by_name(name_or_id)
	if not n.is_empty():
		return String(n["id"])
	for id in Hidden.CLASSES:
		var c: Dictionary = Hidden.CLASSES[id]
		if String(c.get("name", "")) == name_or_id or name_or_id in (c.get("stages", []) as Array):
			return String(id)
	return ""

static func _migrate_wardrobe(d: Dictionary) -> void:
	var ward: Dictionary = d.get("wardrobe", {})
	var renamed := {}
	var out := {}
	for k in ward:
		var w = ward[k]
		var key := String(k)
		if w is Dictionary:
			var nm := String(w.get("name", ""))
			var set_id := set_id_of(String(w.get("set", "")))
			if set_id != "":
				w["set"] = set_id
			if key.begins_with("set:"):
				var def := _set_piece_def(key.substr(4), String(w.get("slot", "")))
				if def != "":
					key = "set:" + def
			var art := String(w.get("art", ""))
			if art != "":
				var new_art := _new_art(art, nm, int(w.get("rarity", 0)))
				if new_art != art:
					w["art"] = new_art
					if key == art:
						key = new_art
		if out.has(key):
			continue
		out[key] = w
		renamed[String(k)] = key
	d["wardrobe"] = out
	var tm: Dictionary = d.get("transmog", {})
	for s in tm:
		if tm[s] is String and renamed.has(String(tm[s])):
			tm[s] = renamed[String(tm[s])]

# ---------------------------------------------------------------------
# Items
# ---------------------------------------------------------------------

## Converts every item found anywhere inside v (in place).
static func _walk_items(v) -> void:
	if v is Dictionary:
		if v.has("base_name") and v.has("slot") and v.has("rarity"):
			migrate_item(v)
			return
		for k in v:
			_walk_items(v[k])
	elif v is Array:
		for x in v:
			_walk_items(x)

## Gives a 2.0 item its 2.1 ids: "set" (set id), "def", Signature owner and art.
static func migrate_item(it: Dictionary) -> void:
	var bn := String(it.get("base_name", ""))
	var slot := String(it.get("slot", ""))
	var r := int(it.get("rarity", 0))
	var s := String(it.get("set", ""))
	if s != "" or r == GameData.SET_RARITY:
		var set_id := set_id_of(s) if s != "" else ""
		if set_id == "":
			set_id = _set_of_piece(bn)
		if set_id != "":
			it["set"] = set_id
			if not it.has("def"):
				it["def"] = GameData.piece_id(set_id, slot)
		return
	if it.has("def"):
		return
	if r == GameData.SIGNATURE:
		var owner := ""
		if String(it.get("sig_of", "")) != "":
			owner = monster_id(String(it["sig_of"]))
		if owner == "":
			owner = Monsters.signature_owner(bn)
		if owner != "":
			it["sig_of"] = owner
			it["def"] = GameData.sig_id(owner)
			it["art"] = "s_" + owner
		return
	if r == GameData.UNIQUE:
		var u := unique_def(bn)
		if not u.is_empty():
			it["def"] = String(u["id"])
			it["art"] = "u_" + String(u["id"])
			return
		for race in Races.RACE_GEAR:
			for g in Races.RACE_GEAR[race]:
				if String(g["name"]) == bn:
					it["def"] = String(g["id"])
					it["art"] = "r_" + String(g["id"])
					it["race_only"] = String(race)
					return

## A unique's def by its name (zone and realm bosses' uniques, Snik's curios), or {}.
static func unique_def(item_name: String) -> Dictionary:
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			if String(u["name"]) == item_name:
				return u
	for u in Snik.CURIOS:
		if String(u["name"]) == item_name:
			return u
	return {}

## A set id from a set id or its 2.0 name ("" if unknown).
static func set_id_of(name_or_id: String) -> String:
	if name_or_id == "":
		return ""
	if not GameData.set_info(name_or_id).is_empty():
		return name_or_id
	for table in [GameData.SETS, GameData.EVO_SETS]:
		for id in table:
			if String(table[id]["name"]) == name_or_id:
				return String(id)
	return ""

static func _set_of_piece(piece: String) -> String:
	for table in [GameData.SETS, GameData.EVO_SETS]:
		for id in table:
			if piece in (table[id]["pieces"] as Dictionary).values():
				return String(id)
	return ""

static func _set_piece_def(piece: String, slot: String) -> String:
	for table in [GameData.SETS, GameData.EVO_SETS]:
		for id in table:
			for sl in table[id]["pieces"]:
				if GameData.piece_id(String(id), String(sl)) == piece:
					return piece  # already a piece id
	var set_id := _set_of_piece(piece)
	if set_id == "":
		return ""
	if slot == "":
		var pieces: Dictionary = GameData.set_info(set_id)["pieces"]
		slot = String(pieces.find_key(piece))
	return GameData.piece_id(set_id, slot)

## The 2.1 art key for an item look (2.0 built Unique / Signature art from names).
static func _new_art(art: String, item_name: String, rarity: int) -> String:
	if art.begins_with("s_") and Monsters.sig_by_art(art).is_empty():
		var owner := Monsters.signature_owner(item_name)
		return "s_" + owner if owner != "" else art
	if art.begins_with("u_") and rarity == GameData.UNIQUE:
		var u := unique_def(item_name)
		if not u.is_empty():
			return "u_" + String(u["id"])
		for race in Races.RACE_GEAR:
			for g in Races.RACE_GEAR[race]:
				if String(g["name"]) == item_name:
					return "r_" + String(g["id"])
	return art

# ---------------------------------------------------------------------
# Monsters
# ---------------------------------------------------------------------

## A creature's stable id from a 2.0 name (or an id already), "" if unknown.
## art: the 2.0 art key when the save kept one (pets, the grave): a regular
## monster's id is its art key, a boss's is its art key minus "boss_".
static func monster_id(name_or_id: String, art := "") -> String:
	if name_or_id == "":
		return ""
	var reg := Monsters.registry()
	if reg.has(name_or_id):
		return name_or_id
	var id := Monsters.id_of(name_or_id)
	if id != "":
		return id
	for a in [art, art.trim_prefix("boss_")]:
		if a != "" and reg.has(a):
			return a
	var s := ClassTree.slug(name_or_id)
	if reg.has(s):
		return s
	var head := ClassTree.slug(name_or_id.split(",")[0])  # "Hel, Queen of the Dead" -> hel
	if reg.has(head):
		return head
	if not name_or_id in report.get("unmapped", []):
		(report.get("unmapped", []) as Array).append(name_or_id)
	return ""

# ---------------------------------------------------------------------
# The Codex
# ---------------------------------------------------------------------

static func migrate_codex(c: Codex) -> void:
	# Bestiary: entries of names that map to the same id are added together
	var best := {}
	for k in c.bestiary:
		var e = c.bestiary[k]
		var id := monster_id(String(k))
		var key := id if id != "" else String(k)
		if not e is Dictionary:
			continue
		if best.has(key):
			var b: Dictionary = best[key]
			b["kills"] = int(b.get("kills", 0)) + int(e.get("kills", 0))
			var bt: Array = b.get("tiers", [0, 0, 0, 0, 0, 0])
			var et: Array = e.get("tiers", [])
			for i in mini(bt.size(), et.size()):
				bt[i] = int(bt[i]) + int(et[i])
			b["sig"] = bool(b.get("sig", false)) or bool(e.get("sig", false))
		else:
			best[key] = e
	c.bestiary = best
	# Collection: item names -> def ids
	var coll := {}
	for k in c.collection:
		var key := item_def_of(String(k))
		coll[key if key != "" else String(k)] = c.collection[k]
	c.collection = coll
	# Pet book
	var book := {}
	for k in c.pet_book:
		var id := monster_id(String(k))
		var key := id if id != "" else String(k)
		book[key] = maxi(int(book.get(key, -1)), int(c.pet_book[k]))
	c.pet_book = book
	# Bounties that name a monster
	for list in [c.bounties.get("daily", []), c.bounties.get("weekly", [])]:
		for b in list:
			if b is Dictionary and String(b.get("monster", "")) != "":
				var id := monster_id(String(b["monster"]))
				if id != "":
					b["monster"] = id
	c.dirty = true

## A Unique / Signature / Set piece / race gear def id from its 2.0 name ("" if none).
static func item_def_of(item_name: String) -> String:
	var u := unique_def(item_name)
	if not u.is_empty():
		return String(u["id"])
	var set_id := _set_of_piece(item_name)
	if set_id != "":
		var pieces: Dictionary = GameData.set_info(set_id)["pieces"]
		return GameData.piece_id(set_id, String(pieces.find_key(item_name)))
	var owner := Monsters.signature_owner(item_name)
	if owner != "":
		return GameData.sig_id(owner)
	for race in Races.RACE_GEAR:
		for g in Races.RACE_GEAR[race]:
			if String(g["name"]) == item_name:
				return String(g["id"])
	return ""
