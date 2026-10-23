class_name AutoDive
extends RefCounted
## 2.1: auto-dive settings, one panel (auto_dive_panel.gd). When Auto heads home,
## when it stops, what it drinks, and whether the loot filter runs while Auto plays.
## Works on top of Autoplay: "head home" uses the same trip home as tapping Town
## mid-floor (home once this floor is cleared). The pause rules stay in AutoRules.
## Stored in GameState.auto_rules["dive"], so it saves with the hero.

const DEFAULTS := {
	"bag_pct": 0,          # head home when the bag is this full (%), 0 = off
	"potions_at": -1,      # head home when you're down to this many potions, -1 = off
	"hp_pct": 0,           # head home when HP is below this % (0 = off)
	"stop_floor": 0,       # pause Auto when you reach this floor (0 = off)
	"downs": 0,            # head home when this many of your team are down at once (0 = off)
	"elixir_boss": false,  # drink a carried elixir when a boss fight starts
	"filter_in_auto": true,  # the loot filter also runs while Auto plays
}

const BAG_STEPS := [0, 75, 90, 100]
const POTION_STEPS := [-1, 0, 1, 3, 5]
const HP_STEPS := [0, 20, 30, 50]
const FLOOR_STEPS := [0, 25, 50, 75, 100, 150, 200, 250]
const DOWN_STEPS := [0, 1, 2]

static func settings(g: GameState) -> Dictionary:
	var d: Variant = g.auto_rules.get("dive")
	if not (d is Dictionary):
		d = {}
		g.auto_rules["dive"] = d
	for k in DEFAULTS:
		if not (d as Dictionary).has(k):
			d[k] = DEFAULTS[k]
	return d

static func value(g: GameState, key: String) -> Variant:
	return settings(g).get(key)

static func set_value(g: GameState, key: String, v: Variant) -> void:
	settings(g)[key] = v
	g.save_game()

## Moves a setting to its next step (wraps around).
static func step(g: GameState, key: String, steps: Array) -> void:
	var i := steps.find(int(value(g, key)))
	set_value(g, key, steps[(i + 1) % steps.size()])

static func filter_in_auto(g: GameState) -> bool:
	return bool(value(g, "filter_in_auto"))

## How many of your team are down right now.
static func team_down(g: GameState) -> int:
	var n := 0
	if g.party != null:
		for mem in g.party.members:
			if mem.knocked_out or mem.hp <= 0:
				n += 1
	return n

## Every go-home rule that holds right now, as [key, why], in order.
static func conditions(g: GameState) -> Array:
	var s := settings(g)
	var out: Array = []
	var bag_pct := int(s["bag_pct"])
	if bag_pct > 0 and g.bag.size() * 100 >= g.bag_capacity() * bag_pct:
		out.append(["bag", "your bag is full" if bag_pct >= 100 else "your bag is %d%% full" % bag_pct])
	var pot := int(s["potions_at"])
	if pot >= 0 and g.potions <= pot:
		out.append(["potions", "you're out of potions" if g.potions <= 0 else "you're down to %d potion%s" % [g.potions, "" if g.potions == 1 else "s"]])
	var hp := int(s["hp_pct"])
	if hp > 0 and g.hero_hp * 100 < g.get_max_hp() * hp:
		out.append(["hp", "your HP is below %d%%" % hp])
	var downs := int(s["downs"])
	if downs > 0 and team_down(g) >= downs:
		out.append(["downs", "%d of your team %s down" % [downs, "is" if downs == 1 else "are"]])
	return out

## Rules that already fired and wait to re-arm (key -> true). Saved with the settings.
static func _fired(g: GameState) -> Dictionary:
	var s := settings(g)
	if not (s.get("fired") is Dictionary):
		s["fired"] = {}
	return s["fired"]

## Why Auto should head home ("" = keep going): the first rule that holds and
## hasn't fired yet. A rule fires once, then re-arms only after its condition clears.
static func home_reason(g: GameState) -> String:
	var fired := _fired(g)
	for c in conditions(g):
		if not fired.has(c[0]):
			return String(c[1])
	return ""

## Floor N: Auto pauses there once ("" = keep going). It holds only on floor N
## itself, so resuming (or a later dive started past it) doesn't pause again;
## it re-arms when you're on another floor.
static func pause_reason(g: GameState) -> String:
	if not g.autoplay or g.in_town:
		return ""
	var fired := _fired(g)
	var fl := int(value(g, "stop_floor"))
	if fl <= 0 or g.floor_num != fl:
		fired.erase("floor")
		return ""
	if fired.has("floor"):
		return ""
	fired["floor"] = true
	return "you reached floor %d" % fl

## The first carried elixir that isn't already working ("" = none).
static func elixir_to_drink(g: GameState) -> String:
	for id in GameData.ELIXIR_ORDER:
		if g.supply_carried(id) > 0 and int(g.elixirs.get(id, 0)) <= 0:
			return id
	return ""

## Runs every game tick (from AutoRules.check, in town too): drinks before bosses
## and starts the trip home when a rule says so. Tells you with a toast; never pauses Auto.
static func tick(g: GameState) -> void:
	var fired := _fired(g)
	var said := _said(g)
	if g.in_town:
		fired.erase("floor")  # a new dive: the floor pause is armed again
		return
	if not g.autoplay or g.run_over:
		return
	var s := settings(g)
	if bool(s["elixir_boss"]) and g.enemy_is_boss and g.enemy_hp > 0:
		var id := elixir_to_drink(g)
		if id != "" and g.drink_elixir(id):
			g.events.append({"type": "toast", "text": "Auto drank %s before the boss." % GameData.ELIXIRS[id]["name"]})
	# re-arm rules whose condition has cleared
	var holding := {}
	for c in conditions(g):
		holding[c[0]] = true
	for k in fired.keys():
		if k != "floor" and not holding.has(k):
			fired.erase(k)
	for k in said.keys():
		if not holding.has(k):
			said.erase(k)
	if g.go_home_after:
		return
	var key := ""
	var why := ""
	for c in conditions(g):
		if not fired.has(c[0]):
			key = c[0]
			why = c[1]
			break
	if key == "":
		return
	var blocked := Town.blocked(g, true)
	if blocked != "":
		# not fired: it tries again once the way home is open; the note shows once
		if not said.has(key):
			said[key] = true
			g.say("[color=#fca5a5]Auto can't go home: %s[/color]" % blocked)
			g.events.append({"type": "toast", "text": "Auto can't go home: %s" % blocked})
			g.save_game()
		return
	g.go_home_after = true
	fired[key] = true
	said.erase(key)
	g.say("[color=#5eead4]Auto heads home after this floor: %s.[/color]" % why)
	g.events.append({"type": "toast", "text": "Heading home after this floor: %s." % why})
	g.save_game()

## Rules whose "can't go home" note was already shown (key -> true).
static func _said(g: GameState) -> Dictionary:
	var s := settings(g)
	if not (s.get("said") is Dictionary):
		s["said"] = {}
	return s["said"]

## Short words for the panel buttons.
static func label_for(key: String, v: int) -> String:
	match key:
		"bag_pct":
			return "Off" if v <= 0 else ("Full" if v >= 100 else "%d%% full" % v)
		"potions_at":
			return "Off" if v < 0 else ("Out of potions" if v == 0 else "%d or fewer" % v)
		"hp_pct":
			return "Off" if v <= 0 else "Below %d%%" % v
		"stop_floor":
			return "Off" if v <= 0 else "Floor %d" % v
		"downs":
			return "Off" if v <= 0 else ("1 hero down" if v == 1 else "%d heroes down" % v)
	return str(v)
