class_name Classes
extends RefCounted
## The 9 starting classes. What they grow into (the family trees, unique
## classes, branch-offs and ranks) is in class_tree.gd.
##
## Passive keys: atk / hp / def multiply; crit, dodge, lifesteal, regen,
## thorns, gold_find, double_strike add; skill = +x skill damage (multiplier);
## tag_power = {"Fire": 0.25} extra power for skills with that tag.

const SPEC_LEVEL := 15
const EVO_LEVEL := 35
const GOD_LEVEL := 60

# ---------- Skill tags ----------
const TAGS := {
	"Blade": {"color": "#c0cbdc", "prefix": "Steel", "bonus": {"crit": 5}},
	"Fist": {"color": "#e8b896", "prefix": "Iron Fist", "bonus": {"double_strike": 8}},
	"Fire": {"color": "#f77622", "prefix": "Inferno", "bonus": {"atk": 1.06}},
	"Frost": {"color": "#7fd0f0", "prefix": "Frost", "bonus": {"def": 1.1}},
	"Storm": {"color": "#fee761", "prefix": "Storm", "bonus": {"double_strike": 5, "crit": 3}},
	"Arcane": {"color": "#c084fc", "prefix": "Arcane", "bonus": {"skill": 1.1}},
	"Holy": {"color": "#fde68a", "prefix": "Radiant", "bonus": {"regen": 1}},
	"Shadow": {"color": "#8b5cf6", "prefix": "Shadow", "bonus": {"dodge": 6}},
	"Blood": {"color": "#e43b44", "prefix": "Blood", "bonus": {"lifesteal": 5}},
	"Nature": {"color": "#63c74d", "prefix": "Wild", "bonus": {"hp": 1.1}},
	"Song": {"color": "#f472b6", "prefix": "Echoing", "bonus": {"regen": 1, "atk": 1.03}},
	"Trick": {"color": "#a8ca58", "prefix": "Mad", "bonus": {"dodge": 4, "gold_find": 10}},
}
const AFFINITY_POWER := 0.15  # skills with one of your class's tags hit this much harder

# ---------- The 9 classes ----------
# start: the skill stones a new hero starts with (active, passive).
# look: the outfit a new hero starts in (item types for each slot).
const ORDER := ["Warrior", "Knight", "Wanderer", "Cleric", "Acolyte", "Mage", "Trickster", "Ranger", "Bard"]
const CLASSES := {
	"Warrior": {"color": "#dc2626", "role": "Fighter", "atk": 1.0, "hp": 1.3, "def": 1.2, "dodge": 0,
		"tags": ["Blade", "Blood"], "start": ["cleave", "iron_will"], "build": {"STR": 3, "VIT": 1, "DEX": 1},
		"look": {"Weapon": "sword", "Chest": "plate", "Legs": "greaves", "Feet": "boots"},
		"blurb": "A tough front-line fighter. +30% HP, +20% Defense. Big hits, lots of health."},
	"Knight": {"color": "#94a3b8", "role": "Tank", "atk": 0.95, "hp": 1.25, "def": 1.35, "dodge": 0,
		"tags": ["Blade", "Holy"], "start": ["shield_bash", "plate_mastery"], "build": {"VIT": 3, "STR": 1, "WIS": 1},
		"look": {"Weapon": "spear", "Off Hand": "shield", "Helmet": "helm", "Chest": "plate", "Legs": "greaves", "Feet": "sabatons"},
		"blurb": "A wall of steel. +35% Defense, +25% HP. Stuns and shields; the party's tank later."},
	"Wanderer": {"color": "#e8b14a", "role": "Martial artist", "atk": 1.1, "hp": 1.1, "def": 1.0, "dodge": 5,
		"tags": ["Blade", "Fist"], "start": ["wanderer_strike", "inner_breath"], "build": {"AGI": 2, "DEX": 2, "STR": 1},
		"look": {"Weapon": "sword", "Chest": "robe", "Legs": "pants", "Feet": "sandals"},
		"blurb": "A roaming martial artist, always Neutral. Two roads: the Sword, or the Demon. Its best classes need special items.",
		"special": true},
	"Cleric": {"color": "#fde68a", "role": "Healer", "atk": 1.0, "hp": 1.15, "def": 1.1, "dodge": 0,
		"tags": ["Holy", "Nature"], "start": ["holy_light", "blessing"], "build": {"WIS": 2, "INT": 2, "VIT": 1},
		"look": {"Weapon": "mace", "Off Hand": "tome", "Chest": "robe", "Feet": "sandals"},
		"blurb": "Heals, shields and holy damage. Hard to kill, steady to play."},
	"Acolyte": {"color": "#a78bfa", "role": "Faith fighter", "atk": 1.05, "hp": 1.05, "def": 1.0, "dodge": 0,
		"tags": ["Holy", "Shadow"], "start": ["smite", "devotion"], "build": {"INT": 3, "STR": 1, "WIS": 1},
		"look": {"Weapon": "staff", "Helmet": "hood", "Chest": "robe", "Feet": "sandals"},
		"blurb": "A priest still finding their faith. Its tree splits into a holy Dawn Disciple or an evil Cultist."},
	"Mage": {"color": "#8b5cf6", "role": "Spellcaster", "atk": 1.3, "hp": 0.85, "def": 0.9, "dodge": 0,
		"tags": ["Fire", "Frost", "Storm", "Arcane"], "start": ["fireball", "arcane_mind"], "build": {"INT": 3, "VIT": 1, "WIS": 1},
		"look": {"Weapon": "staff", "Helmet": "hood", "Chest": "robe", "Feet": "boots"},
		"blurb": "Fragile but deadly. +30% Attack, -15% HP. Every element, or pure arcane light and death."},
	"Trickster": {"color": "#a8ca58", "role": "Chaos", "atk": 1.1, "hp": 0.95, "def": 0.95, "dodge": 8,
		"tags": ["Trick", "Shadow"], "start": ["pocket_sand", "light_fingers"], "build": {"AGI": 2, "LUK": 2, "DEX": 1},
		"look": {"Weapon": "dagger", "Helmet": "cap", "Chest": "tunic", "Legs": "leggings", "Feet": "boots"},
		"blurb": "Confuses monsters, steals gold and loves a gamble. 8% dodge, +gold."},
	"Ranger": {"color": "#16a34a", "role": "Marksman", "atk": 1.15, "hp": 1.05, "def": 1.0, "dodge": 6,
		"tags": ["Nature", "Storm"], "start": ["piercing_shot", "keen_eye"], "build": {"DEX": 3, "AGI": 1, "STR": 1},
		"look": {"Weapon": "bow", "Helmet": "hood", "Chest": "tunic", "Legs": "leggings", "Feet": "boots"},
		"blurb": "Steady ranged damage; leftover damage flies into the next monster. +15% Attack, 6% dodge."},
	"Bard": {"color": "#f472b6", "role": "Support", "atk": 1.05, "hp": 1.05, "def": 1.0, "dodge": 3,
		"tags": ["Song", "Trick"], "start": ["battle_hymn", "encore"], "build": {"CHA": 2, "INT": 2, "AGI": 1},
		"look": {"Weapon": "dagger", "Off Hand": "tome", "Helmet": "cap", "Chest": "tunic", "Feet": "boots"},
		"blurb": "Songs that buff you for many turns and charm monsters. A great support for parties later."},
}

# ---------- Faith (every hero) ----------
# -100 (evil) .. +100 good. Your deeds move it, and it decides which classes you can take.
const FAITH := {"holy_skill": 0.05, "heal": 0.02, "bounty": 2.0, "leave_shrine": 3.0, "boss": 1.0,
	"shadow_skill": -0.05, "drain": -0.02, "shrine": -6.0, "goblin": -1.0}

static func info(cls: String) -> Dictionary:
	return CLASSES.get(cls, {})

## The class's recommended stat spread: points out of every 5 a level.
static func build(cls: String) -> Dictionary:
	return info(cls).get("build", {"STR": 2, "VIT": 2, "DEX": 1})

## The class's stats from most to least wanted (then the rest in the usual order).
static func stat_order(cls: String) -> Array:
	var b := build(cls)
	var out: Array = b.keys()
	out.sort_custom(func(a, c): return int(b[a]) > int(b[c]))
	for st in GameData.STAT_ORDER:
		if not st in out:
			out.append(st)
	return out

static func tag_color(tag: String) -> String:
	return TAGS.get(tag, {"color": "#cbd5e1"})["color"]

## "+6% Attack, 5% lifesteal" from a bonus dict.
static func bonus_text(d: Dictionary) -> String:
	var names := {"atk": "Attack", "hp": "HP", "def": "Defense", "skill": "skill damage", "crit": "crit", "dodge": "dodge",
		"lifesteal": "lifesteal", "regen": "HP regen a turn", "thorns": "damage reflected", "gold_find": "gold",
		"double_strike": "double strike", "execute": "damage to weak monsters", "rage": "rage damage", "scrap": "scrap from salvaging",
		"stone_find": "stone finds", "potion": "potion healing", "xp": "XP", "boss": "damage to bosses", "escape": "escape chance",
		"scout": "scouting", "charm": "charm chance", "cdr": "cooldown turns"}
	var parts: Array = []
	for k in d:
		var v := float(d[k])
		if k in ["atk", "hp", "def", "skill"]:
			parts.append("%+d%% %s" % [int(round((v - 1.0) * 100)), names[k]])
		elif names.has(k):
			parts.append("%s%s%% %s" % ["+" if v >= 0.0 else "", str(snappedf(v, 0.1)).trim_suffix(".0"), names[k]])
	return ", ".join(parts) + "."
