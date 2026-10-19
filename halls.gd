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

# =====================================================================
# Room interactions (manual play: tap them; Auto walks past)
# =====================================================================

const PROP_WEIGHTS := {"chest": 25, "pot": 30, "altar": 12, "lever": 10, "nest": 8, "npc": 8, "key": 7}
const MIMIC_CHANCE := 12.5         # % of chests (about 1 in 8)
const NEST_EGG_CHANCE := 25.0      # % a nest holds an egg
const PROP_NAMES := {"chest": "Chest", "pot": "Old pot", "altar": "Altar", "lever": "Lever", "nest": "Nest",
	"npc": "Wounded adventurer", "key": "Rusty key", "locked": "Locked chest", "beast": "Dying beast"}

static func _pick_prop() -> String:
	var total := 0
	for k in PROP_WEIGHTS:
		total += int(PROP_WEIGHTS[k])
	var r := randi() % total
	for k in PROP_WEIGHTS:
		r -= int(PROP_WEIGHTS[k])
		if r < 0:
			return k
	return "pot"

## A new room: 1-3 things to poke at (none on boss floors).
static func roll_props(g: GameState) -> void:
	g.room_props = []
	g.room_key = false
	if GameData.is_boss_floor(g.floor_num) or g.trial_active:
		return
	var n := randi_range(1, 3)
	var xs := [0.2, 0.8, 0.35, 0.65]
	xs.shuffle()
	for i in n:
		var k := _pick_prop()
		var p := {"kind": k, "used": false, "x": xs[i], "y": randf_range(0.5, 0.72)}
		if k == "chest":
			p["mimic"] = randf() * 100.0 < MIMIC_CHANCE
			p["spotted"] = p["mimic"] and randf() * 100.0 < spot_chance(g)
		if k == "npc" and randf() < 0.35:
			p["kind"] = "beast"   # a dying beast and its young (an egg quest)
		g.room_props.append(p)
		if k == "key":
			# the key opens a locked chest somewhere in the same room
			g.room_props.append({"kind": "locked", "used": false, "x": xs[(i + 1) % xs.size()] if n < 4 else 0.5, "y": 0.42})

static func can_interact(g: GameState) -> bool:
	return not g.in_town and (g.exploring or g.door_pending())

## Tap something in the room. Returns what happened (for the log).
static func interact(g: GameState, i: int) -> String:
	if i < 0 or i >= g.room_props.size() or not can_interact(g):
		return ""
	var p: Dictionary = g.room_props[i]
	if p.get("used", false):
		return ""
	var out := ""
	match String(p["kind"]):
		"chest":
			if p.get("mimic", false):
				p["used"] = true
				_mimic(g)
				return "The chest grows teeth!"
			p["used"] = true
			var gold := (5 + g.floor_num * 4) * 2
			g._add_gold(gold)
			g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), g._rarity(10 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_NORMAL * 2.0), g.floor_num, g._new_id()))
			out = "You open the chest: +%d gold and some gear." % gold
			g.events.append({"type": "treasure"})
		"locked":
			if not g.room_key:
				return "It's locked. The key must be somewhere in this room."
			p["used"] = true
			var gold2 := (5 + g.floor_num * 4) * 4
			g._add_gold(gold2)
			g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), maxi(2, g._rarity(25 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS)), g.floor_num, g._new_id()))
			out = "The rusty key turns. Inside: +%d gold and something good." % gold2
			g.events.append({"type": "treasure"})
		"key":
			p["used"] = true
			g.room_key = true
			out = "You pick up a rusty key."
		"pot":
			p["used"] = true
			var roll := randf()
			if roll < 0.45:
				var gp := 2 + g.floor_num
				g._add_gold(gp)
				out = "You smash the pot: +%d gold." % gp
			elif roll < 0.65:
				g.potions += 1
				out = "You smash the pot: a potion!"
			elif roll < 0.75:
				Combat.afflict(g, "poison", 3)
				out = "A snake was coiled inside. It bites!"
			else:
				out = "Just dust."
		"altar":
			p["used"] = true
			match randi() % 3:
				0:
					g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
					out = "You pray at the altar. Strength flows into you (+15% Attack for a while)."
				1:
					g.luck_turns += 30
					out = "You pray at the altar. Luck smiles on you (better loot for 30 turns)."
				_:
					g.hero_hp = g.get_max_hp()
					out = "You pray at the altar. Your wounds close."
			g.events.append({"type": "buff", "name": "Altar"})
		"lever":
			p["used"] = true
			if randf() < 0.6:
				var gl := (5 + g.floor_num * 3) * 2
				g._add_gold(gl)
				g._give_materials(1)
				out = "A hidden alcove grinds open: +%d gold and some materials." % gl
			else:
				trigger(g, roll_trap())
				out = "Click. That was a trap."
		"nest":
			p["used"] = true
			if randf() * 100.0 < NEST_EGG_CHANCE:
				Menagerie.give_egg(g, "nest")
				out = "Among the twigs: an egg."
			else:
				g.horde_left = maxi(g.horde_left, 2)
				g.horde_total = g.horde_left
				g.horde_pack = true
				out = "Something angry was sitting on that nest. A pack comes for you!"
		"npc":
			if g.potions <= 0:
				return "A wounded adventurer begs for a potion. You have none to give."
			p["used"] = true
			g.potions -= 1
			g._faith(5)
			var gn := (5 + g.floor_num * 4) * 3
			g._add_gold(gn)
			if randf() < 0.35:
				g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), 3, g.floor_num, g._new_id()))
			out = "You give the adventurer a potion. Grateful, they press their purse into your hands (+%d gold)." % gn
		"beast":
			p["used"] = true
			g._faith(5)
			if randf() < 0.6:
				Menagerie.give_egg(g, "beast")
				out = "The dying beast nudges something toward you before it goes still: its egg. Look after it."
			else:
				out = "You ease the beast's last moments. It doesn't fight you."
	g.codex.add("room_things")
	if out != "":
		g.say(out)
	g.save_game()
	return out

## A mimic: the chest was a monster all along (Epic, better loot).
static func _mimic(g: GameState) -> void:
	g.exploring = false
	g.spawn_enemy()
	g.enemy_name = "Mimic"
	g.enemy_species = "Mimic"
	g.enemy_art = "mimic"
	g.enemy_people = ""
	g._apply_tier(Monsters.EPIC)
	g.events.append({"type": "rare_monster", "tier": Monsters.EPIC, "name": "Mimic", "mods": g.enemy_mods.duplicate()})
	g.say("[color=#f87171]The chest snaps open... it's a Mimic![/color]")

# =====================================================================
# Hidden dungeon portals (part 9, in progress)
# =====================================================================

## Leave the portal (cleared = reached the end).
static func leave_portal(g: GameState, cleared: bool) -> void:
	if g.portal.is_empty():
		return
	g.portal = {}
	if not cleared:
		g.say("[color=#c4b5fd]The portal snaps shut behind you.[/color]")
