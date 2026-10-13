class_name Signatures
extends RefCounted
## Signature skills: every class on the Evolution Tree (levels 15, 35, 60 and
## the branch-offs) teaches one skill of its own. They don't drop as stones;
## you get them by becoming the class. One goes in the Signature slot (the
## 4th skill button), and a new evolution puts its skill there by itself.
##
## Each one is built from a template (what it does) scaled by the class's
## tier and rank, and carries the class's element.

const PREFIX := "sig_"
const TIER_POWER := [1.0, 1.35, 1.75]   # level 15, 35, 60 classes
const RANK_POWER := {"C": 1.0, "B": 1.05, "A": 1.1, "S": 1.15, "SS": 1.25, "God": 1.4}
const COLOR := "#fde047"

# class name -> [skill name, template]  (template "" = pick from the class's focus)
const NAMES := {
	# Warrior
	"Berserker": ["Frenzied Cleave", "rage"], "Bloodreaver": ["Reaver's Kiss", "drain"], "Slaughter King": ["Red Harvest", "execute"],
	"Crimson Juggernaut": ["Crimson Tide", "drain"], "Warlord": ["Warlord's Command", "strike"], "Conqueror": ["Conquest", "crit"],
	"Grand Marshal": ["Hold the Line", "bulwark"], "Champion": ["Champion's Stand", "bulwark"], "Crusader": ["Crusade", "burst"],
	"Holy Avenger": ["Avenging Light", "crit"], "Templar Lord": ["Oathwall", "bulwark"], "Weaponmaster": ["Arsenal", "flurry"],
	"Blademaster": ["Perfect Cut", "crit"], "Titan": ["Titan's Fall", "strike"],
	# Knight
	"Guardian": ["Bastion", "bulwark"], "Paladin": ["Lay on Hands", "mend"], "Holy Bulwark": ["Unbreakable", "bulwark"],
	"Lightsworn": ["Dawnblade", "burst"], "Juggernaut": ["Unstoppable", "strike"], "Iron Colossus": ["Iron Avalanche", "bulwark"],
	"Warden of Ruin": ["Ruinguard", "bulwark"], "Lancer": ["Lunge", "flurry"], "Dragoon": ["Dragon Dive", "strike"],
	"Sky Dragoon": ["Skyfall", "strike"], "Wyrmlancer": ["Wyrmpiercer", "flurry"], "Death Knight": ["Deathgrip", "drain"],
	"Dread Lord": ["Dread", "drain"], "Hellrider": ["Hellcharge", "burst"],
	# Wanderer
	"Swordsman": ["Drawing Cut", "crit"], "Sword Saint": ["Sword Saint's Truth", "crit"], "Sword God": ["Heaven-Splitting Sword", "crit"],
	"Sword Immortal": ["Undying Edge", "crit"], "Blade Phantom": ["Phantom Step", "veil"], "Ghost Blade": ["Ghost Cut", "crit"],
	"Thousand Edges": ["A Thousand Edges", "flurry"], "Demonic Disciple": ["Demon Palm", "drain"], "Demon Saint": ["Demon Saint's Palm", "drain"],
	"Heavenly Demon": ["Heavenly Demon's Descent", "rage"], "Asura": ["Asura's Wrath", "rage"], "Blood Fiend": ["Blood Feast", "drain"],
	"Blood Demon King": ["Sea of Blood", "drain"], "Poison Sovereign": ["Venom Throne", "execute"],
	# Cleric
	"Priest": ["Prayer of Mending", "mend"], "High Priest": ["Holy Word", "mend"], "Saint": ["Miracle", "mend"],
	"Oracle": ["Foresight", "veil"], "Inquisitor": ["Inquisition", "burst"], "Zealot": ["Zeal", "crit"],
	"Purifier": ["Purifying Flame", "burst"], "Druid": ["Rejuvenate", "mend"], "Grove Keeper": ["Thornwall", "bulwark"],
	"Archdruid": ["World Tree's Bloom", "mend"], "Lifebinder": ["Lifebind", "mend"], "Storm Druid": ["Squall", "burst"],
	"Thunder Shaman": ["Thunder Totem", "burst"], "Wildshaper": ["Bear Form", "rage"],
	# Acolyte
	"Dawn Disciple": ["First Light", "mend"], "Templar": ["Sacred Shield", "bulwark"], "Sun Templar": ["Sunstrike", "burst"],
	"Saint Militant": ["Holy War", "strike"], "Seer": ["Glimpse", "veil"], "Prophet": ["Prophecy", "crit"],
	"Star Seer": ["Falling Star", "burst"], "Cultist": ["Dark Rite", "drain"], "Warlock": ["Eldritch Blast", "burst"],
	"Hexlord": ["Grand Hex", "execute"], "Void Caller": ["Call the Void", "burst"], "Blood Knight": ["Blood Oath", "drain"],
	"Blood Lord": ["Blood Tithe", "drain"], "Reaper": ["Harvest Souls", "execute"],
	# Mage
	"Elementalist": ["Elemental Surge", "burst"], "Pyromancer": ["Firestorm", "burst"], "Inferno Archmage": ["Inferno", "burst"],
	"Storm Sovereign": ["Sovereign Storm", "flurry"], "Cryomancer": ["Deep Freeze", "burst"], "Glacial Sage": ["Glacier", "bulwark"],
	"Frost Witch": ["Witch's Winter", "burst"], "Arcanist": ["Arcane Barrage", "flurry"], "Lightbinder": ["Bound Light", "burst"],
	"Archmage of Dawn": ["Dawnbreak", "burst"], "Chronomancer": ["Stop Time", "time"], "Necromancer": ["Raise the Fallen", "summon"],
	"Necrolord": ["Army of the Dead", "summon"], "Bone Sovereign": ["Bone Storm", "flurry"],
	# Trickster
	"Rogue": ["Backstab", "crit"], "Assassin": ["Assassinate", "execute"], "Nightblade": ["Nightfall", "crit"],
	"Kingslayer": ["Regicide", "execute"], "Shadowdancer": ["Shadow Dance", "veil"], "Phantom": ["Phantom's Embrace", "veil"],
	"Mirage": ["Hall of Mirrors", "veil"], "Gambler": ["Double or Nothing", "fortune"], "Illusionist": ["Bewilder", "charm"],
	"Grand Illusionist": ["Grand Illusion", "charm"], "Dreamweaver": ["Sweet Dreams", "charm"], "Pirate": ["Plunder", "fortune"],
	"Corsair King": ["Broadside", "flurry"], "Fortune's Fool": ["Jackpot", "fortune"],
	# Ranger
	"Hunter": ["Aimed Shot", "crit"], "Beastmaster": ["Call the Pack", "summon"], "Pack Lord": ["Alpha's Howl", "summon"],
	"Wild King": ["King of Beasts", "summon"], "Deadeye": ["Deadeye", "crit"], "Hawkeye": ["Eye of the Hawk", "crit"],
	"Death's Arrow": ["Last Arrow", "execute"], "Warden": ["Warden's Watch", "bulwark"], "Grove Ranger": ["Grove's Gift", "mend"],
	"Sylvan Guardian": ["Sylvan Ward", "bulwark"], "Moonbow": ["Moonlit Arrow", "burst"], "Stormcaller": ["Call Lightning", "burst"],
	"Tempest Archer": ["Tempest Volley", "flurry"], "Sky Hunter": ["Thunder Dive", "strike"],
	# Bard
	"Minstrel": ["Song of Rest", "song"], "Troubadour": ["Troubadour's Tale", "song"], "Songweaver": ["The Song That Weaves", "song"],
	"Choir Saint": ["Hymn of the Choir", "mend"], "Siren": ["Siren Song", "charm"], "Dirge Singer": ["Dirge", "execute"],
	"Doom Chanter": ["Chant of Doom", "burst"], "Skald": ["Saga", "song"], "War Chanter": ["War Chant", "song"],
	"Warhorn": ["Sound the Horn", "song"], "Skald King": ["Saga of Kings", "song"], "Spellsinger": ["Spellsong", "burst"],
	"Arcane Harpist": ["Harp of Stars", "flurry"], "Echo Mage": ["Echo", "flurry"],
}
const KEY_TEMPLATE := {"atk": "strike", "crit": "crit", "double_strike": "flurry", "lifesteal": "drain", "def": "bulwark",
	"thorns": "bulwark", "hp": "bulwark", "regen": "mend", "skill": "burst", "dodge": "veil", "execute": "execute", "rage": "rage",
	"boss": "execute", "gold_find": "fortune", "charm": "charm", "potion": "mend", "escape": "crit", "scout": "veil", "xp": "strike",
	"scrap": "strike", "stone_find": "fortune"}
const NOUNS := {"strike": "Blow", "crit": "Edge", "flurry": "Flurry", "drain": "Hunger", "bulwark": "Ward", "mend": "Grace",
	"burst": "Burst", "veil": "Veil", "execute": "End", "rage": "Fury", "fortune": "Gamble", "charm": "Charm", "summon": "Call",
	"song": "Anthem", "time": "Moment"}
const TEMPLATE_TEXT := {
	"strike": "A huge blow for %sx damage.",
	"crit": "A guaranteed crit for %sx damage.",
	"flurry": "%d hits of %sx damage.",
	"drain": "%sx damage, and you heal for %d%% of it.",
	"bulwark": "A shield worth %d%% of your max HP, then a %sx bash that scales with Defense.",
	"mend": "Heals %d%% HP now and %s%% a turn for 5 turns.",
	"burst": "%sx %s damage, with its element's effect.",
	"veil": "+%d%% dodge for 3 turns, and a %sx strike from the shadows.",
	"execute": "%sx damage, doubled against monsters under 30%% HP.",
	"rage": "Costs 8%% HP: +%d%% Attack for 4 turns and a %sx hit.",
	"fortune": "%sx damage and steals a lot of gold.",
	"charm": "%sx damage; the monster is charmed and hits itself for %d turns.",
	"summon": "Summons help for %d turns (%sx your Attack each turn).",
	"song": "+%d%% Attack and %s%% healing a turn for 6 turns, and a %sx note.",
	"time": "%sx damage, and every other skill is ready again.",
}

static var _cache := {}

static func id_of(node_id: String) -> String:
	return PREFIX + node_id

static func is_signature(id: String) -> bool:
	return id.begins_with(PREFIX)

static func node_of(id: String) -> Dictionary:
	return ClassTree.node(id.trim_prefix(PREFIX))

## The skill dict (same keys as SkillData.SKILLS) for a signature id.
static func info(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var n := node_of(id)
	if n.is_empty():
		return {}
	var s := _build(n)
	_cache[id] = s
	return s

static func _element(n: Dictionary) -> String:
	for t in n.get("tags", []):
		if t in Combat.ELEMENTS:
			return t
	for t in Classes.info(String(n["cls"])).get("tags", []):
		if t in Combat.ELEMENTS:
			return t
	return ""

static func _tags(n: Dictionary) -> Array:
	var out: Array = []
	for t in n.get("tags", []):
		out.append(t)
	if out.is_empty():
		out = (Classes.info(String(n["cls"])).get("tags", ["Blade"]) as Array).slice(0, 1)
	return out

static func _f(v: float) -> String:
	return str(snappedf(v, 0.1)).trim_suffix(".0")

static func _build(n: Dictionary) -> Dictionary:
	var nm: Array = NAMES.get(String(n["name"]), [])
	var tpl := String(nm[1]) if nm.size() > 1 and String(nm[1]) != "" else String(KEY_TEMPLATE.get(ClassTree._main_key(n), "strike"))
	var skill_name := String(nm[0]) if not nm.is_empty() else "%s's %s" % [n["name"], NOUNS.get(tpl, "Art")]
	var t := clampi(int(n["tier"]), 1, 3)
	var p := float(TIER_POWER[t - 1]) * float(RANK_POWER.get(ClassTree.rank_of(n), 1.0))
	var tags := _tags(n)
	var el := _element(n)
	var s := {"name": skill_name, "kind": "active", "tags": tags, "rarity": 3, "signature": true, "class": n["name"], "tier": t}
	match tpl:
		"strike":
			s["cd"] = 7
			s["power"] = 3.4 * p
			s["text"] = TEMPLATE_TEXT[tpl] % _f(s["power"])
		"crit":
			s["cd"] = 6
			s["power"] = 1.7 * p
			s["always_crit"] = true
			s["text"] = TEMPLATE_TEXT[tpl] % _f(s["power"] * 2.0)
		"flurry":
			s["cd"] = 7
			s["hits"] = 3 + t
			s["power"] = 0.85 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [s["hits"], _f(s["power"])]
		"drain":
			s["cd"] = 6
			s["power"] = 2.6 * p
			s["drain"] = 45 + 5 * t
			s["text"] = TEMPLATE_TEXT[tpl] % [_f(s["power"]), s["drain"]]
		"bulwark":
			s["cd"] = 10
			s["shield"] = 18 + 6 * t
			s["power"] = 1.2 * p
			s["def_scale"] = 1.5 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [s["shield"], _f(s["power"])]
		"mend":
			s["cd"] = 10
			s["heal"] = 12 + 5 * t
			s["song"] = {"regen": 1.5 + t, "turns": 5}
			s["power"] = 0.8 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [s["heal"], _f(1.5 + t)]
		"burst":
			s["cd"] = 7
			s["power"] = 3.0 * p
			match el:
				"Fire":
					s["burn"] = 0.5 * p
				"Frost":
					s["weaken"] = 0.6
					s["turns"] = 3
				"Storm":
					s["stun"] = 1
				"Shadow":
					s["weaken"] = 0.7
					s["turns"] = 4
				"Holy":
					s["heal"] = 8
				"Nature":
					s["burn"] = 0.5 * p
				"Blood":
					s["burn"] = 0.5 * p
					s["drain"] = 20
				"Arcane":
					s["power"] = 3.6 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [_f(s["power"]), el if el != "" else "pure"]
		"veil":
			s["cd"] = 9
			s["buff"] = {"dodge": 25 + 10 * t, "turns": 3}
			s["power"] = 1.4 * p
			s["always_crit"] = t >= 3
			s["text"] = TEMPLATE_TEXT[tpl] % [25 + 10 * t, _f(s["power"] * (2.0 if t >= 3 else 1.0))]
		"execute":
			s["cd"] = 7
			s["power"] = 2.8 * p
			s["execute"] = 1.0
			s["text"] = TEMPLATE_TEXT[tpl] % _f(s["power"])
		"rage":
			s["cd"] = 9
			s["hp_cost"] = 8
			s["buff"] = {"atk": 1.3 + 0.1 * t, "turns": 4}
			s["power"] = 2.0 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [int(round((0.3 + 0.1 * t) * 100)), _f(s["power"])]
		"fortune":
			s["cd"] = 7
			s["power"] = 1.8 * p
			s["steal"] = 4.0 + 2.0 * t
			s["text"] = TEMPLATE_TEXT[tpl] % _f(s["power"])
		"charm":
			s["cd"] = 8
			s["power"] = 1.2 * p
			s["confuse"] = 2 + (1 if t >= 2 else 0)
			s["text"] = TEMPLATE_TEXT[tpl] % [_f(s["power"]), s["confuse"]]
		"summon":
			s["cd"] = 12
			s["summon"] = {"power": 0.55 * p, "turns": 5 + t}
			s["text"] = TEMPLATE_TEXT[tpl] % [5 + t, _f(0.55 * p)]
		"song":
			s["cd"] = 10
			s["buff"] = {"atk": 1.15 + 0.07 * t, "turns": 6}
			s["song"] = {"regen": 1.0 + 0.5 * t, "turns": 6}
			s["power"] = 1.4 * p
			s["text"] = TEMPLATE_TEXT[tpl] % [int(round((0.15 + 0.07 * t) * 100)), _f(1.0 + 0.5 * t), _f(s["power"])]
		"time":
			s["cd"] = 12
			s["power"] = 2.4 * p
			s["reset"] = true
			s["text"] = TEMPLATE_TEXT[tpl] % _f(s["power"])
	return s

## Every signature skill this hero knows: one per class on their path.
static func owned(g: GameState) -> Array:
	var out: Array = []
	for n in ClassTree.path_nodes(g):
		out.append(id_of(String(n["id"])))
	return out

## Signature skills don't rank up: their strength comes from the class's tier.
static func rank(_id: String) -> int:
	return 1
