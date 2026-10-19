class_name Synergies
extends RefCounted
## 0.13+ (Stage 3): team synergies and the Team Strike. Who you bring matters: certain
## mixes of classes fight better together, and a whole team builds up to a combined
## attack. Shown in Character > Party and on the fight screen.

## id -> {name, text, test(classes) via _has}
const LIST := {
	"shield_prayer": {"name": "Shield and Prayer", "color": "#fde68a",
		"text": "A front-liner (Warrior, Knight, Wanderer) and a believer (Cleric, Acolyte, Bard): the whole team takes 10% less damage."},
	"spellweave": {"name": "Spellweave", "color": "#c084fc",
		"text": "Two spell-slingers (Mage, Trickster, Acolyte, Bard): skills hit 15% harder."},
	"three_paths": {"name": "Three Paths", "color": "#4ade80",
		"text": "Three different classes: +10% XP and gold."},
	"hunting_pair": {"name": "Hunting Pair", "color": "#86efac",
		"text": "A Ranger with a Wanderer or Trickster: +8% crit chance for the team."},
}
const FRONT := ["Warrior", "Knight", "Wanderer"]
const FAITH := ["Cleric", "Acolyte", "Bard"]
const SPELL := ["Mage", "Trickster", "Acolyte", "Bard"]
const DAMAGE_CUT := 0.9
const SKILL_BOOST := 1.15
const REWARD_BOOST := 1.1
const CRIT_BONUS := 8.0
const STRIKE_EVERY := 6       # turns between Team Strikes
const STRIKE_MULT := 1.2      # x the sum of everyone's Attack

## The classes on your team (you first), living or not.
static func classes(g: GameState) -> Array:
	var out: Array = [g.hero_class]
	if g.party != null:
		for m in g.party.members:
			out.append(m.hero.hero_class)
	return out

static func _count(cl: Array, group: Array) -> int:
	return cl.filter(func(c): return c in group).size()

## Which synergies your team has now (ids).
static func active(g: GameState) -> Array:
	var cl := classes(g)
	if cl.size() < 2:
		return []
	var out: Array = []
	if _count(cl, FRONT) >= 1 and _count(cl, FAITH) >= 1:
		out.append("shield_prayer")
	if _count(cl, SPELL) >= 2:
		out.append("spellweave")
	var unique := {}
	for c in cl:
		unique[c] = true
	if cl.size() >= 3 and unique.size() >= 3:
		out.append("three_paths")
	if "Ranger" in cl and ("Wanderer" in cl or "Trickster" in cl):
		out.append("hunting_pair")
	return out

static func has(g: GameState, id: String) -> bool:
	return g.party != null and g.party.size() > 0 and id in active(g)

static func damage_mult(g: GameState) -> float:
	return DAMAGE_CUT if has(g, "shield_prayer") else 1.0

static func skill_mult(g: GameState) -> float:
	return SKILL_BOOST if has(g, "spellweave") else 1.0

static func reward_mult(g: GameState) -> float:
	return REWARD_BOOST if has(g, "three_paths") else 1.0

static func crit_bonus(g: GameState) -> float:
	return CRIT_BONUS if has(g, "hunting_pair") else 0.0

## Turns until the next Team Strike (-1 with no team standing).
static func strike_left(g: GameState) -> int:
	if g.party == null or g.party.living().is_empty() or g.leader_down:
		return -1
	var t := int(g.cfight.get("turns", 0))
	return STRIKE_EVERY - t % STRIKE_EVERY

## Every STRIKE_EVERY turns of a fight, the whole team hits together. Returns a log line.
static func team_strike(g: GameState) -> String:
	if strike_left(g) != STRIKE_EVERY or int(g.cfight.get("turns", 0)) <= 0 or g.enemy_hp <= 0:
		return ""
	var total := float(g.get_attack())
	for m in g.party.living():
		total += float(m.hero.get_attack())
	var dmg := g._damage_enemy(int(total * STRIKE_MULT * g.party_mult()), ["Physical"])
	g.codex.add("team_strikes")
	ClassTree.count(g, "team_strikes")
	g.events.append({"type": "team_strike", "dmg": dmg, "count": g.party.living().size() + 1})
	return ". [color=#fbbf24]TEAM STRIKE![/color] Your whole team hits together for %d" % dmg
