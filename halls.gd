class_name Halls
extends RefCounted
## 0.13 The Halls Below: traps and door reading.
##
## Traps sit in rooms and behind doors. Spikes, darts, flame jets, frost runes,
## smoke and alarms: damage, statuses (poison, burn, chill, blind) or an ambush.
## Sharp eyes (DEX, door readers, scouting classes) spot them and step around.
##
## Doors are blank. Door readers (the Ranger line, scouting classes, the new
## Wayfinder) sense what's behind them, and get better with every door they read:
##   level 1: a glow  - green (safe), yellow (a fight), red (danger)
##   level 2: the room itself (treasure, campfire, elite, Snik...)
##   level 3: ...and whether the door is trapped

const TRAPS := {
	"spikes": {"name": "Spike trap", "text": "Spikes shoot up from the floor!", "dmg": 0.12},
	"darts": {"name": "Dart trap", "text": "Poisoned darts hiss out of the walls!", "dmg": 0.05, "status": "poison", "turns": 4},
	"flames": {"name": "Flame jet", "text": "A jet of fire bursts from the floor!", "dmg": 0.1, "status": "burn", "turns": 3},
	"frost": {"name": "Frost rune", "text": "A rune flares and frost locks your joints!", "dmg": 0.04, "status": "chill", "turns": 4},
	"smoke": {"name": "Smoke trap", "text": "Black smoke fills the room. You can barely see!", "dmg": 0.0, "status": "blind", "turns": 4},
	"alarm": {"name": "Alarm", "text": "A bell rings somewhere above. Something is coming!", "dmg": 0.0, "ambush": true},
}
const ROOM_TRAP_CHANCE := 14.0     # % per room, +5 per 100 floors
const DOOR_TRAP_CHANCE := 8.0      # % per door
const TRAP_FROM := 4               # no traps on the first floors
const READS_FOR_LEVEL_2 := 60      # doors read before a reader sees the room itself
const BLIND_MISS := 0.3            # blinded: 30% of your attacks miss

## Spotting chance (%): DEX, door readers and scouts see more.
static func spot_chance(g: GameState) -> float:
	var c := 15.0 + g.stat("DEX") * 0.25
	var lvl := team_sense(g)
	c += [0.0, 20.0, 35.0, 60.0][lvl]
	return clampf(c, 5.0, 95.0)

static func roll_trap() -> String:
	return String(TRAPS.keys().pick_random())

## A new room: maybe a trap waits in it.
static func roll_room_trap(g: GameState) -> void:
	g.room_trap = {}
	if g.floor_num < TRAP_FROM or GameData.is_boss_floor(g.floor_num) or g.trial_active:
		return
	if randf() * 100.0 >= ROOM_TRAP_CHANCE + g.floor_num / 100.0 * 5.0:
		return
	g.room_trap = {"kind": roll_trap(), "spotted": randf() * 100.0 < spot_chance(g), "done": false,
		"x": randf_range(0.3, 0.7), "y": randf_range(0.45, 0.7)}
	if g.room_trap["spotted"]:
		g.say("[color=#fbbf24]You spot a %s in the room and mark it.[/color]" % String(TRAPS[g.room_trap["kind"]]["name"]).to_lower())
		g.codex.add("traps_spotted")

## Walking up to the monsters: a hidden trap goes off, a spotted one is stepped around.
static func on_engage(g: GameState) -> void:
	var tr: Dictionary = g.room_trap
	if tr.is_empty() or tr.get("done", false):
		return
	tr["done"] = true
	if tr.get("spotted", false):
		g.say("You step around the %s." % String(TRAPS[tr["kind"]]["name"]).to_lower())
		g.xp += maxi(1, int(GameData.xp_for_kill(g.floor_num, false) * 0.3))
		return
	trigger(g, String(tr["kind"]))

static func trigger(g: GameState, kind: String) -> void:
	var t: Dictionary = TRAPS[kind]
	g.codex.add("traps_hit")
	g.say("[color=#f87171]%s[/color]" % t["text"])
	g.events.append({"type": "trap", "kind": kind, "name": t["name"]})
	var dmg := int(g.get_max_hp() * float(t.get("dmg", 0.0)))
	if dmg > 0:
		g.hero_hp = maxi(1, g.hero_hp - dmg)   # a trap never kills on its own
		g.events.append({"type": "enemy_hit", "dmg": dmg})
	if t.has("status"):
		Combat.afflict(g, String(t["status"]), int(t["turns"]))
	if t.get("ambush", false) and not g.enemy_is_boss and g.horde_left <= 0:
		g.horde_left = 2
		g.horde_total = 2
		g.horde_pack = true

# =====================================================================
# Door reading
# =====================================================================

## How well this hero reads doors: 0 (can't), 1 glow, 2 the room, 3 the room and traps.
static func door_sense(g: GameState) -> int:
	var lvl := 0
	var u := ClassTree.unique_class(g)
	if g.class_branch == "wayfinder":
		lvl = 3
	elif not u.is_empty() and (u.get("util", {}) as Dictionary).has("scout"):
		lvl = 2
	if g.hero_class == "Ranger":
		lvl = maxi(lvl, 1)
		if int(g.ctrack.get("doors_read", 0)) >= READS_FOR_LEVEL_2 or g.class_path.size() >= 2:
			lvl = maxi(lvl, 2)
		if g.class_path.size() >= 3:
			lvl = 3
	return lvl

## The best door reader on your team (companions read for you).
static func team_sense(g: GameState) -> int:
	var lvl := door_sense(g)
	if g.party != null:
		for m in g.party.members:
			if not m.knocked_out:
				lvl = maxi(lvl, door_sense(m.hero))
	return lvl

## What your reader senses behind door i: {"color", "label", "text"} ("" color = nothing sensed).
static func read_door(g: GameState, i: int) -> Dictionary:
	var lvl := team_sense(g)
	if lvl == 0 or i >= g.doors.size():
		return {"color": "", "label": "?", "text": "A blank door. Who knows what's behind it."}
	var kind: String = g.doors[i]
	var trapped: bool = i < g.door_traps.size() and bool(g.door_traps[i])
	var danger := kind == "elite" or (trapped and lvl < 3)
	var safe := kind in ["treasure", "rest", "merchant"]
	var col := "#f87171" if danger else ("#4ade80" if safe else "#fbbf24")
	if lvl == 1:
		var word := "danger" if danger else ("safe" if safe else "a fight")
		return {"color": col, "label": "", "text": "Your reader senses %s behind it." % word}
	var name: String = GameData.PATHS.get(kind, {}).get("name", kind) if kind != "fight" else "Monsters"
	if lvl >= 3 and trapped:
		name += " (trapped)"
	return {"color": col, "label": name, "text": "Your reader knows: %s." % name}

## Reading the doors trains the reader.
static func on_doors_shown(g: GameState) -> void:
	if team_sense(g) > 0:
		ClassTree.count(g, "doors_read", 3)
