class_name Collections
extends RefCounted
## 2.1 G4: collection rewards. Filling in the Codex (each region's Bestiary,
## Uniques, Signatures, sets, the Pet book, secret and God classes, the Trophy
## Cabin) earns titles and looks: name colors and plate frames (cosmetics.gd).
## Owner decision D6 b: titles + cosmetics, NEVER stats. Nothing here touches power.
##
## Account-wide, like the rest of the Codex: every hero in every town adds to the
## same Bestiary and collection, so the rewards are shared too. Earned milestones
## live in Codex.coll_earned (milestone id -> date), secret and God classes found
## in Codex.classes_found (class id -> date). Trophies count the town you're in
## (the cabin belongs to a town), but a reward, once earned, stays for the account.
## Everything is keyed by stable ids (zone, set, monster, class ids; see stable-ids.md).
## A reward is granted the moment its milestone is reached (no claim step to forget);
## a toast says what you got and the Codex > Rewards tab lists them all.

const ENABLED := true  # the feature's on/off switch (build plan: one per big feature)

## A region's Bestiary: share of its monsters (incl. mid and zone boss) defeated at least once.
const ZONE_STEPS := [25, 50, 100]

## zone id -> [title at 50%, title at 100%, name color (25%), frame (100%)]. Names only: ids are fixed.
const ZONE_REWARDS := {
	"mossy_hollows": ["Warden of the Hollows", "Heart of the Moss", "Hollow Green", "Mossbound"],
	"sunken_catacombs": ["Warden of the Catacombs", "Ossuary Keeper", "Catacomb Slate", "Catacomb Stone"],
	"flooded_depths": ["Warden of the Depths", "Drowned Sage", "Deepwater Teal", "Tidewall"],
	"ember_halls": ["Warden of the Ember Halls", "Ashen Lorekeeper", "Ember Orange", "Emberwrought"],
	"the_shadow_deep": ["Warden of the Shadow Deep", "Eye in the Dark", "Shadow Violet", "Shadowcut"],
	"elf": ["Warden of the Hushwood", "Leafwise", "Hushwood Sage", "Hushwood Bough"],
	"fairy": ["Warden of the Glimmer Court", "Glamour-Sighted", "Glimmer Pink", "Glimmerlace"],
	"dwarf": ["Warden of the Ironroot", "Deepdelver", "Ironroot Copper", "Ironroot Rivets"],
	"angel": ["Warden of the Spire", "Spire-Sworn", "Spire Gold", "Gilded Halo"],
	"demon": ["Warden of the Abyss", "Abyss-Gazer", "Abyss Crimson", "Abyssal Chain"],
}

## set id -> the title for owning every piece of it
const SET_TITLES := {
	"grendels_kin": "Heir of Grendel's Kin",
	"hels_shroud": "Heir of Hel's Shroud",
	"tidecaller": "The Tidecaller",
	"muspel_forge": "Forged in Muspel",
	"titanborn": "Titanborn",
	"last_light_of_the_elves": "Last Light",
	"court_of_glamour": "Glamour's Darling",
	"undermountain_oath": "Oathsworn",
	"choir_of_dawn": "Voice of the Dawn",
	"pact_of_the_abyss": "Pactbound",
}

## The other milestones: {id, track, need, title?, color? / frame?}. need is a count, or a
## percent of the track's total when "pct" is true. color/frame: [look id, name, hex(, studs)].
const OTHER := [
	{"id": "uniq_25", "track": "uniques", "need": 25, "pct": true, "color": ["c_curio", "Curio Amber", "#f5b041"]},
	{"id": "uniq_50", "track": "uniques", "need": 50, "pct": true, "title": "Relic Hunter"},
	{"id": "uniq_100", "track": "uniques", "need": 100, "pct": true, "title": "Keeper of Relics", "frame": ["c_reliquary", "Reliquary", "#fcd34d", true]},
	{"id": "sig_10", "track": "signatures", "need": 10, "pct": true, "color": ["c_keepsake", "Keepsake Rose", "#f9a8d4"]},
	{"id": "sig_25", "track": "signatures", "need": 25, "pct": true, "title": "Trophy Hunter"},
	{"id": "sig_50", "track": "signatures", "need": 50, "pct": true, "frame": ["c_keepsake", "Keepsake Case", "#ff6b9d", true]},
	{"id": "sig_100", "track": "signatures", "need": 100, "pct": true, "title": "The Thousandfold"},
	{"id": "slots_all", "track": "slots", "need": 6, "title": "Fully Kitted"},
	{"id": "sets_3", "track": "sets", "need": 3, "color": ["c_smith", "Smith's Bronze", "#d6a35c"]},
	{"id": "sets_all", "track": "sets", "need": 10, "title": "Master of Sets", "frame": ["c_anvil", "Anvil-Struck", "#b8a07a", true]},
	{"id": "pets_5", "track": "pets", "need": 5, "color": ["c_kennel", "Kennel Tan", "#d9b38c"]},
	{"id": "pets_25", "track": "pets", "need": 25, "pct": true, "title": "Beastfriend"},
	{"id": "pets_50", "track": "pets", "need": 50, "pct": true, "frame": ["c_menagerie", "Menagerie", "#a3e635", false]},
	{"id": "pets_100", "track": "pets", "need": 100, "pct": true, "title": "Keeper of All Beasts"},
	{"id": "pet_epic5", "track": "pet_epic", "need": 5, "color": ["c_epicpet", "Beastlord Purple", "#c084fc"]},
	{"id": "pet_myth", "track": "pet_myth", "need": 1, "title": "Mythtamer"},
	{"id": "secret_1", "track": "secret", "need": 1, "color": ["c_whisper", "Whisper Lilac", "#d8b4fe"]},
	{"id": "secret_5", "track": "secret", "need": 5, "title": "Many-Masked"},
	{"id": "secret_15", "track": "secret", "need": 15, "frame": ["c_veiled", "Veiled", "#a78bfa", true]},
	{"id": "god_1", "track": "god", "need": 1, "frame": ["c_godlight", "Godlight", "#fde047", true]},
	{"id": "god_3", "track": "god", "need": 3, "title": "Chosen of the Gods"},
	{"id": "god_6", "track": "god", "need": 6, "color": ["c_radiant", "Radiant", "#fff7c2"]},
	{"id": "troph_5", "track": "trophies", "need": 5, "color": ["c_oak", "Cabin Oak", "#c19a6b"]},
	{"id": "troph_15", "track": "trophies", "need": 15, "title": "Collector of Glories"},
	{"id": "troph_30", "track": "trophies", "need": 30, "frame": ["c_trophy", "Trophy Gilt", "#eab308", true]},
]

## Tracks in the order the Rewards tab shows them (zone tracks are "zone:<zone id>").
const GROUPS := [
	["Bestiary", "Defeat every kind of monster in a region (bosses too)."],
	["Items", "Fill the Collection: Uniques, Signatures and whole sets."],
	["Pets", "Own pets of every kind (Codex > Pets)."],
	["Classes", "Secret classes and God classes found by any of your heroes."],
	["Trophies", "Trophies in this town's cabin."],
]

static var _all: Array = []
static var _colors: Array = []
static var _frames: Array = []
static var _slots: Dictionary = {}  # collection def id -> slot

# =====================================================================
# The list
# =====================================================================

## Every milestone: {id, track, need (a count), title, look: {kind "color"/"frame", id, name, color, studs}}.
static func all() -> Array:
	if not _all.is_empty():
		return _all
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var zid := String(z["id"])
		var r: Array = ZONE_REWARDS.get(zid, ["Warden of " + String(z["name"]), "Master of " + String(z["name"]), String(z["name"]), String(z["name"])])
		var track := "zone:" + zid
		var hue := Color(String(z["color"])).lightened(0.35)
		for p in ZONE_STEPS:
			var m := {"id": "best_%s_%d" % [zid, p], "track": track, "need": _need(track, p, true), "pct": p}
			if p == 25:
				m["look"] = {"kind": "color", "id": "z_" + zid, "name": r[2], "color": "#" + hue.to_html(false)}
			elif p == 50:
				m["title"] = r[0]
			else:
				m["title"] = r[1]
				m["look"] = {"kind": "frame", "id": "z_" + zid, "name": r[3], "color": String(z["color"]), "studs": zi >= Realms.BASE_ZONES}  # realm frames get corner studs
			_all.append(m)
	for sid in GameData.SET_ORDER:
		_all.append({"id": "set_" + sid, "track": "set:" + sid, "need": (GameData.SETS[sid]["pieces"] as Dictionary).size(), "title": SET_TITLES.get(sid, "Heir of " + GameData.set_name_of(sid))})
	for o in OTHER:
		var m := {"id": o["id"], "track": o["track"], "need": _need(o["track"], int(o["need"]), bool(o.get("pct", false)))}
		if bool(o.get("pct", false)):
			m["pct"] = int(o["need"])
		if o.has("title"):
			m["title"] = o["title"]
		if o.has("color"):
			m["look"] = {"kind": "color", "id": o["color"][0], "name": o["color"][1], "color": o["color"][2]}
		elif o.has("frame"):
			m["look"] = {"kind": "frame", "id": o["frame"][0], "name": o["frame"][1], "color": o["frame"][2], "studs": o["frame"][3]}
		_all.append(m)
	return _all

static func _need(track: String, n: int, pct: bool) -> int:
	return maxi(1, ceili(total(track) * n / 100.0)) if pct else n

static func milestone(id: String) -> Dictionary:
	for m in all():
		if String(m["id"]) == id:
			return m
	return {}

static func on_track(track: String) -> Array:
	return all().filter(func(m): return String(m["track"]) == track)

## Which Rewards group a track belongs to.
static func group_of(track: String) -> String:
	if track.begins_with("zone:"):
		return "Bestiary"
	if track in ["uniques", "signatures", "slots", "sets"] or track.begins_with("set:"):
		return "Items"
	if track.begins_with("pet"):
		return "Pets"
	if track in ["secret", "god"]:
		return "Classes"
	return "Trophies"

## Tracks in display order.
static func tracks() -> Array:
	var out: Array = []
	for m in all():
		if not String(m["track"]) in out:
			out.append(String(m["track"]))
	var sorted: Array = []
	for g in GROUPS:
		for t in out:
			if group_of(t) == String(g[0]):
				sorted.append(t)
	return sorted

# =====================================================================
# Counting (from the Codex only, plus this town's trophies)
# =====================================================================

## The monsters of a region's Bestiary: its monsters, sub-area monsters, mid and zone boss.
static func zone_monsters(zone_id: String) -> Array:
	for z in GameData.ZONES:
		if String(z["id"]) == zone_id:
			var ids: Array = []
			for e in z["enemies"]:
				ids.append(e["id"])
			for s in z["subs"]:
				ids.append(s["monster"]["id"])
			ids.append(z["mid"]["id"])
			ids.append(z["boss"]["id"])
			return ids
	return []

## How big a track is (what 100% means).
static func total(track: String) -> int:
	if track.begins_with("zone:"):
		return zone_monsters(track.substr(5)).size()
	if track.begins_with("set:"):
		return (GameData.SETS.get(track.substr(4), {}).get("pieces", {}) as Dictionary).size()
	match track:
		"uniques":
			var n := 0
			for zi in GameData.ZONES.size():
				n += GameData.zone_uniques(zi).size()
			return n
		"signatures", "pets":
			return Monsters.all_monsters().size()
		"slots":
			return GameData.SLOT_ORDER.size()
		"sets":
			return GameData.SET_ORDER.size()
	return 0  # open-ended (secret, god, trophies, pet_epic, pet_myth): no total is shown

static func count(codex: Codex, track: String) -> int:
	if track.begins_with("zone:"):
		var n := 0
		for id in zone_monsters(track.substr(5)):
			if codex.kills(id) > 0:
				n += 1
		return n
	if track.begins_with("set:"):
		var sid := track.substr(4)
		var n := 0
		for slot in GameData.SETS.get(sid, {}).get("pieces", {}):
			if codex.collection.has(GameData.piece_id(sid, slot)):
				n += 1
		return n
	match track:
		"uniques", "signatures":
			return codex.value(track)
		"slots":
			var have := {}
			for def in codex.collection:
				var s := String(_slot_map().get(def, ""))
				if s != "":
					have[s] = true
			return have.size()
		"sets":
			var n := 0
			for sid in GameData.SET_ORDER:
				if count(codex, "set:" + sid) >= total("set:" + sid):
					n += 1
			return n
		"pets":
			var n := 0
			for m in Monsters.all_monsters():
				if codex.pet_book.has(m):
					n += 1
			return n
		"pet_epic":
			return codex.pet_book.values().filter(func(t): return int(t) >= 3).size()
		"pet_myth":
			return codex.pet_book.values().filter(func(t): return int(t) >= 5).size()
		"secret":
			return codex.classes_found.keys().filter(func(k): return not String(k).begins_with("god_")).size()
		"god":
			return codex.classes_found.keys().filter(func(k): return String(k).begins_with("god_")).size()
		"trophies":
			return Trophies.data.size()
	return 0

## Collection def id (Unique id, sig_<monster id>, set piece id) -> its gear slot.
static func _slot_map() -> Dictionary:
	if not _slots.is_empty():
		return _slots
	for zi in GameData.ZONES.size():
		for u in GameData.zone_uniques(zi):
			_slots[String(u["id"])] = String(u["slot"])
	for m in Monsters.all_monsters():
		if Monsters.has_signature(m):
			_slots["sig_" + String(m)] = String(Monsters.signature_def(m).get("slot", ""))
	for sid in GameData.SETS:
		for slot in GameData.SETS[sid]["pieces"]:
			_slots[GameData.piece_id(sid, slot)] = String(slot)
	return _slots

static func has(codex: Codex, id: String) -> bool:
	return codex != null and codex.coll_earned.has(id)

## The next milestone on a track you haven't earned, or {}.
static func next_on(codex: Codex, track: String) -> Dictionary:
	for m in on_track(track):
		if not has(codex, String(m["id"])):
			return m
	return {}

# =====================================================================
# Granting
# =====================================================================

## Grants every milestone that's newly reached. Returns them (each once, ever).
## Titles and looks only: this never changes a stat.
static func check(codex: Codex) -> Array:
	var out: Array = []
	if not ENABLED or codex == null:
		return out
	var counts := {}
	for m in all():
		var id := String(m["id"])
		if codex.coll_earned.has(id):
			continue
		var track := String(m["track"])
		if not counts.has(track):
			counts[track] = count(codex, track)
		if int(counts[track]) >= int(m["need"]):
			codex.coll_earned[id] = Time.get_date_string_from_system()
			out.append(m)
	if not out.is_empty():
		codex.dirty = true
	return out

## A secret (hidden) or God class found by any hero (hidden.gd / god_classes.gd call this).
static func found_class(codex: Codex, class_id: String) -> void:
	if codex != null and not codex.classes_found.has(class_id):
		codex.classes_found[class_id] = Time.get_date_string_from_system()
		codex.dirty = true

## Titles from earned milestones, in list order.
static func titles(codex: Codex) -> Array:
	var out: Array = []
	for m in all():
		if m.has("title") and has(codex, String(m["id"])):
			out.append(String(m["title"]))
	return out

## Looks in Cosmetics' format: need "coll:<milestone id>" (Cosmetics.has checks it).
static func colors() -> Array:
	if _colors.is_empty():
		_build_looks()
	return _colors

static func frames() -> Array:
	if _frames.is_empty() and _colors.is_empty():
		_build_looks()
	return _frames

static func _build_looks() -> void:
	for m in all():
		if not m.has("look"):
			continue
		var lk: Dictionary = m["look"]
		var e := {"id": String(lk["id"]), "name": String(lk["name"]), "color": String(lk["color"]), "need": "coll:" + String(m["id"])}
		if String(lk["kind"]) == "frame":
			e["studs"] = bool(lk.get("studs", false))
			_frames.append(e)
		else:
			_colors.append(e)

# =====================================================================
# Words
# =====================================================================

static func track_name(track: String) -> String:
	if track.begins_with("zone:"):
		var zid := track.substr(5)
		for z in GameData.ZONES:
			if String(z["id"]) == zid:
				return String(z["name"]) + " Bestiary"
	if track.begins_with("set:"):
		return GameData.set_name_of(track.substr(4)) + " set"
	return {"uniques": "Uniques", "signatures": "Signatures", "slots": "A rare find for every slot", "sets": "Whole sets",
		"pets": "Pet kinds owned", "pet_epic": "Pet kinds at Epic or better", "pet_myth": "Mythic pets",
		"secret": "Secret classes found", "god": "God classes found", "trophies": "Trophies in this town"}.get(track, track)

## What reaching it takes, in plain words: "Defeat 50% (7 / 14)".
static func need_text(m: Dictionary) -> String:
	var track := String(m["track"])
	var n := int(m["need"])
	if m.has("pct"):
		return "%d%% (%d of %d)" % [int(m["pct"]), n, total(track)]
	if track.begins_with("set:"):
		return "all %d pieces" % n
	return str(n)

## What it gives: 'title "X", name color "Y"'.
static func reward_text(m: Dictionary) -> String:
	var parts: Array = []
	if m.has("title"):
		parts.append("title \"%s\"" % m["title"])
	if m.has("look"):
		parts.append("%s \"%s\"" % ["frame" if String(m["look"]["kind"]) == "frame" else "name color", m["look"]["name"]])
	return ", ".join(parts)

## The toast line for a new reward.
static func toast_text(m: Dictionary) -> String:
	return "Codex reward! %s: %s. You got %s (looks only)." % [track_name(String(m["track"])), need_text(m), reward_text(m)]

# =====================================================================
# UI: a progress card per track (Codex tabs)
# =====================================================================

## A small card: track name, count, a bar and the next reward.
static func track_card(codex: Codex, track: String) -> PanelContainer:
	var have := count(codex, track)
	var nxt := next_on(codex, track)
	var tot := total(track)
	var goal := tot if tot > 0 else (int(nxt["need"]) if not nxt.is_empty() else have)
	var card := UI.panel(UI.INSET, UI.GOLD.darkened(0.45) if nxt.is_empty() else UI.BORDER, 6, 8, 1)
	var v := UI.vbox(3)
	card.add_child(v)
	var top := UI.hbox(8)
	v.add_child(top)
	var nl := UI.label(track_name(track), UI.FONT_CAPTION, UI.TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	top.add_child(nl)
	top.add_child(UI.label(("%d / %d" % [have, goal]) if goal > 0 else str(have), UI.FONT_CAPTION, UI.GOLD))
	var bar := UI.bar(UI.GOLD, 6)
	bar.max_value = maxi(1, goal)
	bar.value = mini(have, maxi(1, goal))
	v.add_child(bar)
	var nt := UI.wrap(("Next at %s: %s" % [need_text(nxt), reward_text(nxt)]) if not nxt.is_empty() else "Every reward here is yours.", UI.FONT_CAPTION, UI.DIM)
	v.add_child(nt)
	return card

## Progress cards for several tracks, two to a row.
static func cards(codex: Codex, list: Array) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for t in list:
		var c := track_card(codex, String(t))
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.custom_minimum_size = Vector2(150, 0)
		g.add_child(c)
	return g
