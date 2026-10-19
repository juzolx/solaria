class_name Milestones
extends RefCounted
## 0.13+ (Stage 3): milestone cutscenes. The first time you reach a big moment, the
## fight pauses for a full-screen card (moments.gd). Each plays once per account.

const FLOORS := {50: "Out of the Hollows", 100: "The First Hundred", 250: "A Quarter of the Way", 500: "Halfway to the Bottom", 1000: "The Bottom of the World"}
const COLOR := "#e8b14a"

static func _once(g: GameState, id: String, title: String, sub: String) -> void:
	var key := "moment_" + id
	if g.codex.stat(key) > 0:
		return
	g.codex.add(key)
	g.events.append({"type": "milestone_moment", "title": title, "sub": sub, "color": COLOR})

## Call when the deepest floor may have changed.
static func on_floor(g: GameState) -> void:
	for f in FLOORS:
		if g.best_floor == int(f) and g.floor_num == int(f):  # only as it happens (veterans get no backlog)
			_once(g, "floor_%d" % int(f), String(FLOORS[f]), "You reached floor %d. Few descenders ever see it." % int(f))

static func on_boss(g: GameState, boss_name: String) -> void:
	if g.codex.stat("boss_kills") == 1:
		_once(g, "first_boss", "Your First Boss", "%s falls. The deep has noticed you now." % boss_name)

static func on_item(g: GameState, item: Dictionary) -> void:
	if int(item.get("rarity", 0)) >= GameData.LEGENDARY:
		_once(g, "first_legendary", "A Legendary Find", "%s. Things like this are why people go down." % GameData.display_name(item))

static func on_home(g: GameState) -> void:
	if g.codex.stat("home_trips") == 1:
		_once(g, "first_home", "Home Safe", "You went down, and you came back with your loot. That's the whole trick.")
