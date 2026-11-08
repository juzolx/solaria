class_name TownEvents
extends RefCounted
## 0.13+ (Stage 3): the town has its own life. Sometimes when you get home something
## is going on: a fair, a bard, a bounty day... Each one lasts until you next come
## home (so through your next dive) and does one small, real thing.

const CHANCE := 35.0        # % each time you get home (once a dive has counted as a trip home)
const EVENTS := {
	"fair": {"name": "Harvest Fair", "where": "shop", "color": "#fbbf24",
		"text": "Stalls in the square: everything costs 20% less until you're next home (Snik too, he hates it)."},
	"bard": {"name": "A Bard at the Tavern", "where": "tavern", "color": "#c084fc",
		"text": "Songs of your deeds fire you up: +25% XP until you're next home."},
	"bounty": {"name": "Bounty Day", "where": "bounty", "color": "#f59e0b",
		"text": "The town pays extra for every monster: +25% gold from the dungeon until you're next home."},
	"pilgrims": {"name": "Pilgrims' Blessing", "where": "inn", "color": "#fde68a",
		"text": "Passing pilgrims bless your pack: two potions, on the house."},
	"moon": {"name": "Wanderers' Moon", "where": "gate", "color": "#93c5fd",
		"text": "A pale moon: the old wanderers walk more often (4x) until you're next home."},
}
const FAIR_MULT := 0.8
const XP_MULT := 1.25
const GOLD_MULT := 1.25
const MOON_MULT := 4.0

## Getting home: the last event ends, maybe a new one starts.
static func on_home(g: GameState) -> void:
	g.town_event = ""
	if g.codex.stat("home_trips") < 1 or randf() * 100.0 >= CHANCE:
		return
	var id: String = EVENTS.keys().pick_random()
	g.town_event = id
	var e: Dictionary = EVENTS[id]
	if id == "pilgrims":
		g.potions += 2
	g.codex.add("town_events")
	g.events.append({"type": "toast", "text": "%s! %s" % [e["name"], e["text"]]})
	g.say("[color=%s]%s![/color] %s" % [e["color"], e["name"], e["text"]])

## Multipliers the rest of the game asks for.
static func price_mult(g: GameState) -> float:
	return FAIR_MULT if g.town_event == "fair" else 1.0

static func xp_mult(g: GameState) -> float:
	return XP_MULT if g.town_event == "bard" else 1.0

static func gold_mult(g: GameState) -> float:
	return GOLD_MULT if g.town_event == "bounty" and not g.in_town else 1.0

static func wanderer_mult(g: GameState) -> float:
	return MOON_MULT if g.town_event == "moon" else 1.0

## The building it shows on in the town map, and its line there.
static func note(g: GameState) -> Array:
	if g.town_event == "" or not EVENTS.has(g.town_event):
		return []
	var e: Dictionary = EVENTS[g.town_event]
	return [String(e["where"]), String(e["name"])]
