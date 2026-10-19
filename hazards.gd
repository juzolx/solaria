class_name Hazards
extends RefCounted
## 0.13+ (Stage 3): room hazards. Now and then a fight happens in a room that fights
## back: every few turns its hazard hits you AND the monster, so it can help or hurt.
## Each region has its own (spores in Mossy Hollows, a crumbling ceiling in the
## Catacombs, rising water in the Flooded Depths, falling embers in Ember Halls...).

const CHANCE := 12.0     # % of ordinary fights (not bosses, goblins or trials)
const FROM_FLOOR := 5    # the first floors stay simple
const EVERY := 3         # turns between bursts
const KINDS := {
	"spores": {"name": "Spore Cloud", "color": "#a3e635", "fx": "poison",
		"text": "Every few turns the spores burst: you and the monster are both poisoned."},
	"rubble": {"name": "Crumbling Ceiling", "color": "#d6c7a1", "fx": "impact",
		"text": "Stones fall every few turns, hurting you and the monster alike."},
	"flood": {"name": "Rising Water", "color": "#7fd0f0", "fx": "ice",
		"text": "Icy water surges every few turns: you and the monster are both chilled."},
	"embers": {"name": "Falling Embers", "color": "#fb923c", "fx": "fire",
		"text": "Embers rain down every few turns: you both catch fire."},
	"dark": {"name": "Grasping Dark", "color": "#8b5cf6", "fx": "shadow",
		"text": "Shadows lash out every few turns, hurting you and the monster alike."},
}
## Region (zone index) -> its hazard
const BY_ZONE := ["spores", "rubble", "flood", "embers", "dark", "spores", "dark", "embers", "rubble", "embers"]
const HIT_PART := 0.06   # falling stones and grasping dark: 6% of max HP to each side
const DOT_PART := 0.03   # poison and burn on the monster: 3% of its max HP a turn

## A new fight: does this room have a hazard? (A pack keeps its room's hazard.)
static func roll(g: GameState) -> void:
	if g.enemy_is_boss or g.enemy_goblin or g.trial_active or g.enemy_calamity > 0 or g.floor_num < FROM_FLOOR:
		g.hazard = ""
		return
	if g.horde_pack and g.horde_left > 0 and g.horde_left < g.horde_total and g.hazard != "":
		return
	g.hazard = ""
	if randf() * 100.0 < CHANCE:
		g.hazard = BY_ZONE[clampi(GameData.zone_index(g.floor_num), 0, BY_ZONE.size() - 1)]
		var k: Dictionary = KINDS[g.hazard]
		g.events.append({"type": "mini_event", "kind": "hazard", "title": String(k["name"]).to_upper(), "sub": String(k["text"])})
		g.tip("hazard", "Some rooms fight back: a hazard hits you and the monster every few turns (the countdown is under its name). Finish fast, or let it wear the monster down.")

## Turns until the next burst (1 = next turn), or -1 with no hazard.
static func turns_left(g: GameState) -> int:
	if g.hazard == "":
		return -1
	var t := int(g.cfight.get("turns", 0))
	return EVERY - t % EVERY

## Every turn: on every EVERY-th turn the hazard hits both sides. Returns a log line.
static func tick(g: GameState) -> String:
	if g.hazard == "" or g.enemy_hp <= 0 or not KINDS.has(g.hazard):
		return ""
	var t := int(g.cfight.get("turns", 0))
	if t <= 0 or t % EVERY != 0:
		return ""
	var k: Dictionary = KINDS[g.hazard]
	var say_it: String = {"spores": "The spores burst", "rubble": "Stones fall from the ceiling", "flood": "Icy water surges in",
		"embers": "Embers rain down", "dark": "The dark lashes out"}.get(g.hazard, String(k["name"]))
	var line := ". [color=%s]%s[/color]" % [k["color"], say_it]
	match g.hazard:
		"spores":
			Combat.afflict(g, "poison", 3)
			g.enemy_poison_turns = maxi(g.enemy_poison_turns, 3)
			g.enemy_poison_dmg = maxi(g.enemy_poison_dmg, maxi(1, int(g.enemy_max_hp * DOT_PART)))
		"flood":
			Combat.afflict(g, "chill", 2)
			g.enemy_chill = maxi(g.enemy_chill, 2)
		"embers":
			Combat.afflict(g, "burn", 2)
			g.burn_turns = maxi(g.burn_turns, 2)
			g.burn_dmg = maxi(g.burn_dmg, maxi(1, int(g.enemy_max_hp * DOT_PART)))
			g.burn_tag = "Fire"
		_:
			var dh := maxi(1, int(g.get_max_hp() * HIT_PART))
			g.hero_hp -= dh
			Combat.note_damage(g, "hazard", dh)
			g.events.append({"type": "enemy_hit", "dmg": dh, "hazard": true})
			var de := g._damage_enemy(maxi(1, int(g.enemy_max_hp * HIT_PART)), ["Shadow" if g.hazard == "dark" else "Physical"])
			line += " You take %d, the %s takes %d" % [dh, g.enemy_name, de]
	g.events.append({"type": "hazard", "id": g.hazard, "name": k["name"], "color": k["color"], "fx": k["fx"]})
	return line
