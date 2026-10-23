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
	"stop_floor": 0,       # head home once you've cleared this floor (0 = off)
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

## Why Auto should head home ("" = keep going). Pure check: tick() acts on it.
static func home_reason(g: GameState) -> String:
	var s := settings(g)
	var bag_pct := int(s["bag_pct"])
	if bag_pct > 0 and g.bag.size() * 100 >= g.bag_capacity() * bag_pct:
		return "your bag is full" if bag_pct >= 100 else "your bag is %d%% full" % bag_pct
	var pot := int(s["potions_at"])
	if pot >= 0 and g.potions <= pot:
		return "you're out of potions" if g.potions <= 0 else "you're down to %d potion%s" % [g.potions, "" if g.potions == 1 else "s"]
	var hp := int(s["hp_pct"])
	if hp > 0 and g.hero_hp * 100 < g.get_max_hp() * hp:
		return "your HP is below %d%%" % hp
	var fl := int(s["stop_floor"])
	if fl > 0 and g.floor_num >= fl:
		return "you reached floor %d" % fl
	var downs := int(s["downs"])
	if downs > 0 and team_down(g) >= downs:
		return "%d of your team %s down" % [downs, "is" if downs == 1 else "are"]
	return ""

## The first carried elixir that isn't already working ("" = none).
static func elixir_to_drink(g: GameState) -> String:
	for id in GameData.ELIXIR_ORDER:
		if g.supply_carried(id) > 0 and int(g.elixirs.get(id, 0)) <= 0:
			return id
	return ""

## Runs every Auto tick (from AutoRules.check): drinks before bosses and starts the
## trip home when a rule says so. Tells you with a toast; never pauses Auto.
static func tick(g: GameState) -> void:
	if not g.autoplay or g.in_town or g.run_over:
		return
	var s := settings(g)
	if bool(s["elixir_boss"]) and g.enemy_is_boss and g.enemy_hp > 0 and g.elixirs.is_empty():
		var id := elixir_to_drink(g)
		if id != "" and g.drink_elixir(id):
			g.events.append({"type": "toast", "text": "Auto drank %s before the boss." % GameData.ELIXIRS[id]["name"]})
	if g.go_home_after:
		return
	var why := home_reason(g)
	if why == "":
		return
	g.go_home_after = true
	g.say("[color=#5eead4]Auto heads home after this floor: %s.[/color]" % why)
	g.events.append({"type": "toast", "text": "Heading home after this floor: %s." % why})

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
