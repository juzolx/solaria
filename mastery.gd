class_name Mastery
extends RefCounted
## Weapon mastery: every kill with a kind of weapon (swords, bows, staves...)
## levels up your mastery of it, up to level 10. Each level adds a small
## passive that only works while you hold that kind of weapon.
## Kills are counted in ClassTree's tracker ("kill_w:<type>").

const MAX_LEVEL := 10
const KILLS := [20, 60, 150, 300, 500, 800, 1200, 1700, 2400, 3200]  # kills for levels 1..10
# per level: key -> amount (multipliers like "skill" are +x per level)
const TYPES := {
	"sword": {"name": "Sword", "per": {"crit": 1.0}, "text": "+1% crit"},
	"axe": {"name": "Axe", "per": {"atk": 0.012}, "text": "+1.2% Attack"},
	"dagger": {"name": "Dagger", "per": {"double_strike": 1.0}, "text": "+1% double strike"},
	"mace": {"name": "Mace", "per": {"boss": 2.0}, "text": "+2% damage to bosses"},
	"spear": {"name": "Spear", "per": {"first": 2.5}, "text": "+2.5% chance to strike first"},
	"bow": {"name": "Bow", "per": {"crit_dmg": 3.0}, "text": "+3% crit damage"},
	"staff": {"name": "Staff", "per": {"skill": 0.012}, "text": "+1.2% skill damage"},
	"": {"name": "Unarmed", "per": {"dodge": 0.8, "double_strike": 0.8}, "text": "+0.8% dodge and double strike"},
}

static func weapon_type(g: GameState) -> String:
	var w: Dictionary = g.equipped.get("Weapon", {})
	var t := GameData.item_type(w) if not w.is_empty() else ""
	return t if TYPES.has(t) else "sword"

static func kills(g: GameState, t: String) -> int:
	return int(g.ctrack.get("kill_unarmed" if t == "" else "kill_w:" + t, 0))

static func level_for(k: int) -> int:
	var lv := 0
	for need in KILLS:
		if k >= int(need):
			lv += 1
	return lv

static func level(g: GameState, t: String) -> int:
	return level_for(kills(g, t))

## The bonus from mastery of the weapon in your hand.
static func bonus(g: GameState) -> Dictionary:
	var t := weapon_type(g)
	var lv := level(g, t)
	if lv <= 0:
		return {}
	var out := {}
	var per: Dictionary = TYPES[t]["per"]
	for k in per:
		if k in ["atk", "hp", "def", "skill"]:
			out[k] = 1.0 + float(per[k]) * lv
		else:
			out[k] = float(per[k]) * lv
	return out

## "Sword mastery 3 (+3% crit). 120 / 150 kills to level 4."
static func text(g: GameState, t: String) -> String:
	var info: Dictionary = TYPES[t]
	var lv := level(g, t)
	var k := kills(g, t)
	var s := "%s mastery %d" % [info["name"], lv]
	if lv > 0:
		s += " (%s each level)" % info["text"]
	if lv < MAX_LEVEL:
		s += ". %d / %d kills to level %d." % [k, int(KILLS[lv]), lv + 1]
	else:
		s += ". Mastered!"
	return s

## After a kill: tell the player if their mastery went up.
static func on_kill(g: GameState) -> void:
	var t := weapon_type(g)
	var k := kills(g, t)
	if level_for(k) > level_for(k - 1):
		var lv := level_for(k)
		g.say("[color=#e8b14a]%s mastery %d![/color] %s while you hold a %s." % [TYPES[t]["name"], lv, TYPES[t]["text"], String(TYPES[t]["name"]).to_lower()])
		g.events.append({"type": "mastery", "name": "%s mastery %d" % [TYPES[t]["name"], lv]})
