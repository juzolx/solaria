class_name Trophies
extends RefCounted
## 2.1 G3: the Trophy Cabin. Each town remembers its proudest moments: the first
## kill of every boss, Calamities slain, God classes that answered, rare finds
## (Uniques, Signatures, Mythics) and how deep its heroes went. Purely for show:
## trophies never give any power. The cabin's level sets how many are on display.
## `data` is the town you're in (Profile.trophies, bound by Profile._bind).

static var data: Dictionary = {}

const FLOOR_MARKS := [50, 100, 250, 500, 750, 1000]
## kind -> [icon text, color] for the shelves.
const KINDS := {
	"boss": ["Boss", "#fbbf24"],
	"calamity": ["Calamity", "#e43b44"],
	"god": ["God class", "#fde047"],
	"find": ["Rare find", "#ff6b9d"],
	"floor": ["Depth", "#60a5fa"],
}

static func has(id: String) -> bool:
	return data.has(id)

## Records a trophy once. Returns true if it's new.
static func record(g: GameState, id: String, kind: String, title: String) -> bool:
	if data.has(id):
		return false
	data[id] = {"kind": kind, "name": title, "hero": g.hero_name if g.hero_name != "" else g.hero_class, "date": Time.get_date_string_from_system(), "n": data.size()}
	g.say("[color=#e8b14a]New trophy for the cabin:[/color] %s" % title)
	if g.profile_ref != null and g.autosave:
		g.profile_ref.save()  # trophies are rare: keep each one safe right away
	return true

static func on_boss(g: GameState, species: String) -> void:
	record(g, "boss:" + species, "boss", "Slew %s" % Monsters.name_of(species))

static func on_calamity(g: GameState, index: int, title: String) -> void:
	record(g, "calamity:%d" % index, "calamity", "Ended the Calamity %s" % title)

static func on_god(g: GameState, id: String, title: String) -> void:
	record(g, "god:" + id, "god", "Answered by %s" % title)

static func on_find(g: GameState, item: Dictionary) -> void:
	var r := int(item.get("rarity", 0))
	if not r in [GameData.UNIQUE, GameData.SIGNATURE, GameData.UNIQUE_MYTHIC]:  # plain Mythics come with a Calamity trophy
		return
	var key := String(item.get("def", item.get("base_name", "")))
	if r == GameData.SIGNATURE:
		key = "sig_" + String(item.get("sig_of", ""))
	elif r == GameData.UNIQUE_MYTHIC:
		key = "mythic_%d" % int(item.get("id", 0))
	record(g, "find:" + key, "find", "Found %s (%s)" % [String(item.get("name", "?")), GameData.RARITY_NAMES[r]])

static func on_floor(g: GameState) -> void:
	for f in FLOOR_MARKS:
		if g.best_floor >= int(f):
			record(g, "floor:%d" % int(f), "floor", "Reached floor %d" % int(f))

## Every trophy, newest first: [{id, kind, name, hero, date}].
static func all() -> Array:
	var out: Array = []
	for id in data:
		var t: Dictionary = (data[id] as Dictionary).duplicate()
		t["id"] = id
		out.append(t)
	out.sort_custom(func(a, b): return int(a.get("n", 0)) > int(b.get("n", 0)))
	return out

## Shelf space in this town's cabin.
static func slots() -> int:
	return int(Buildings.pick("cabin", Economy.CABIN_SLOTS))

## What's on display (the newest that fit) and how many wait in the back room.
static func shown() -> Array:
	return all().slice(0, slots())
