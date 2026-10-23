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
	if not u.is_empty() and (u.get("util", {}) as Dictionary).has("scout"):
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
	var safe := kind in ["treasure", "rest", "merchant", "altar", "stranger", "beast", "traveler"]
	var col := "#f87171" if danger else ("#4ade80" if safe else "#fbbf24")
	if lvl == 1:
		var word := "danger" if danger else ("safe" if safe else "a fight")
		return {"color": col, "label": "", "text": "Your reader senses %s behind it." % word}
	var name: String = String(ROOM_NAMES.get(kind, kind))
	if lvl >= 3 and trapped:
		name += " (trapped)"
	return {"color": col, "label": name, "text": "Your reader knows: %s." % name}

## Reading the doors trains the reader.
static func on_doors_shown(g: GameState) -> void:
	if team_sense(g) > 0:
		ClassTree.count(g, "doors_read", 3)

# =====================================================================
# One-thing rooms (Juzo, Oct 18): each door leads to ONE thing. A fight starts by
# itself; otherwise the room holds a single thing: a chest (about 1 in 8 is a
# mimic), a campfire, Snik's stall, a shrine, a nest, a stranger in need, or a
# dying beast. Tap it (Auto does it after a moment), then pick the next door.
# =====================================================================

## door kind -> the one thing standing in that room
const EVENT_ROOMS := {"treasure": "chest", "rest": "campfire", "merchant": "merchant", "altar": "altar",
	"nest": "nest", "stranger": "npc", "beast": "beast", "rift": "rift", "camp": "camp", "traveler": "traveler"}
const ROOM_NAMES := {"fight": "Monsters", "elite": "Elite monster", "treasure": "Treasure room", "rest": "Campfire",
	"merchant": "Goblin trader", "altar": "Shrine", "nest": "Nest", "stranger": "A stranger", "beast": "Dying beast", "rift": "A shimmer in the air", "camp": "Descenders' Camp", "traveler": "A traveler"}
const MIMIC_CHANCE := 12.5         # % of chests (about 1 in 8)
const PROP_NAMES := {"chest": "Chest", "altar": "Shrine", "nest": "Nest", "npc": "Wounded adventurer",
	"beast": "Dying beast", "merchant": "Snik", "campfire": "Campfire", "rift": "Rift", "camp": "Camp", "traveler": "Traveler"}
const PROP_HINTS := {"chest": "Tap the chest", "camp": "Tap the camp to trade or send gold home", "rift": "Tap the rift to step through", "altar": "Tap the shrine to pray", "nest": "Tap the nest",
	"npc": "Tap to help them", "beast": "Tap to go to it", "merchant": "Tap Snik to trade", "campfire": "You rest by the fire", "traveler": "Tap to talk"}

## Walk into a room that holds one thing instead of monsters.
static func enter_event_room(g: GameState, kind: String) -> void:
	g.room_kind = kind
	g.horde_left = 0   # an ambush from the door doesn't follow you into a quiet room
	g.fight = GameData.FIGHTS_PER_FLOOR   # a monster here (a mimic) ends the room
	var p := {"kind": String(EVENT_ROOMS[kind]), "used": false, "x": 0.5, "y": 0.5}
	if kind == "treasure":
		p["mimic"] = randf() * 100.0 < MIMIC_CHANCE
		p["spotted"] = p["mimic"] and randf() * 100.0 < spot_chance(g)
		if p["spotted"]:
			g.say("[color=#fbbf24]Something about that chest isn't right...[/color]")
	if kind == "traveler":
		p["who"] = Travelers.pick()  # next update: someone else is down here
	g.room_props = [p]
	g.exploring = true
	g.explore_wait = 0
	g.events.append({"type": "room", "kind": kind})
	match kind:
		"rest":
			p["used"] = true
			g._apply_path("rest")
			_done(g)
		"merchant":
			g._apply_path("merchant")
			_done(g)
		"camp":
			Camp.enter(g)
			_done(g)
		"treasure":
			if p["spotted"]:
				_done(g)   # you can leave it be: the doors are open already

## The room's one thing is dealt with: on to the doors.
static func _done(g: GameState) -> void:
	g.exploring = false
	g.explore_wait = 0
	if not g.door_pending():
		g._room_cleared()

static func can_interact(g: GameState) -> bool:
	return not g.in_town and (g.exploring or g.door_pending())

## Auto (or waiting too long): deal with the room's thing the sensible way.
static func auto_room(g: GameState) -> void:
	if g.room_props.is_empty():
		_done(g)
		return
	var p: Dictionary = g.room_props[0]
	if p.get("spotted", false):
		p["used"] = true
		g.say("You leave the mimic alone.")
		_done(g)
		return
	if String(p["kind"]) == "traveler" and not p.get("used", false):  # next update: Auto talks to travelers too
		if g.autoplay:
			Travelers.auto_choose(g, p)
		else:
			p["used"] = true  # waited too long: walk past, never spend your gold for you
			g.say("You nod to the traveler and move on.")
		_done(g)
		return
	interact(g, 0)

## Tap the room's thing. Returns what happened (for the log).
static func interact(g: GameState, i: int) -> String:
	if i < 0 or i >= g.room_props.size() or not can_interact(g):
		return ""
	var p: Dictionary = g.room_props[i]
	if p.get("used", false) and not String(p["kind"]) in ["merchant", "camp"]:
		return ""
	var out := ""
	match String(p["kind"]):
		"merchant":
			g.events.append({"type": "merchant"})
			return ""
		"traveler":
			g.events.append({"type": "traveler"})
			return ""
		"camp":
			g.events.append({"type": "descender_camp"})
			return ""
		"chest":
			p["used"] = true
			if p.get("mimic", false):
				g.doors = []
				g.path_offer = []
				_monster(g, "Mimic", "mimic", "[color=#f87171]The chest snaps open... it's a Mimic![/color]")
				return "The chest grows teeth!"
			var gold := (5 + g.floor_num * 6) * 3
			g._add_gold(gold)
			g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), g._rarity(20 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS), g.floor_num, g._new_id()))
			out = "You open the chest: +%d gold and some gear." % gold
			Lore.maybe_find(g, Lore.CHEST_CHANCE)
			g.events.append({"type": "treasure"})
		"altar":
			p["used"] = true
			match randi() % 3:
				0:
					g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
					out = "You pray at the shrine. Strength flows into you (+15% Attack for a while)."
				1:
					g.luck_turns += 30
					out = "You pray at the shrine. Luck smiles on you (better loot for 30 turns)."
				_:
					g.hero_hp = g.get_max_hp()
					out = "You pray at the shrine. Your wounds close."
			g._faith(3)
			g.events.append({"type": "buff", "name": "Shrine"})
		"rift":
			p["used"] = true
			Rifts.enter(g)
			return "You step through the rift!"
		"nest":
			p["used"] = true
			Menagerie.give_egg(g, "nest")
			out = "Among the twigs: an egg."
		"npc":
			p["used"] = true
			if g.potions <= 0:
				out = "A wounded adventurer begs for a potion. You have none to give, and leave them be."
			else:
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
			out = "You ease the beast's last moments. It doesn't fight you."
		_:
			return ""
	g.codex.add("room_things")
	if out != "":
		g.say(out)
	_done(g)
	g.save_game()
	return out

## Something in the room fights back: an Epic monster (better loot). name "" = this floor's own kind.
static func _monster(g: GameState, name: String, art: String, line: String) -> void:
	g.exploring = false
	g.spawn_enemy()
	# A room's own monster (a mimic) comes alone: spawn_enemy can
	# roll a pack, which left ordinary monsters stepping out of a treasure room after it
	g.horde_left = 0
	g.horde_pack = false
	if name != "":
		g.enemy_name = name
		g.enemy_species = name
		g.enemy_art = art
		g.enemy_people = ""
	g._apply_tier(Monsters.EPIC)
	g.events.append({"type": "rare_monster", "tier": Monsters.EPIC, "name": g.enemy_name, "mods": g.enemy_mods.duplicate()})
	g.say(line)

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
