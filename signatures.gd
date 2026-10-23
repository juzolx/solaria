class_name Signatures
extends RefCounted
## Signature skills: every class on the Evolution Tree (levels 15, 35, 75 and
## the branch-offs) teaches one skill of its own. They don't drop as stones;
## you get them by becoming the class. One goes in the Signature slot (the
## 4th skill button), and a new evolution puts its skill there by itself.
##
## Each one is built from a template (what it does) scaled by the class's
## tier and rank, and carries the class's element.

const PREFIX := "sig_"
const TIER_POWER := [1.0, 1.35, 1.75]   # level 15, 35, 75 classes
const RANK_POWER := {"C": 1.0, "B": 1.05, "A": 1.1, "S": 1.15, "SS": 1.25, "God": 1.4}
const COLOR := "#fde047"

# class node id -> [skill name, template]  (template "" = pick from the class's focus)
const NAMES := {
	# Warrior
	"berserker": ["Frenzied Cleave", "rage"], "bloodreaver": ["Reaver's Kiss", "drain"], "slaughter_king": ["Red Harvest", "execute"],
	"crimson_juggernaut": ["Crimson Tide", "drain"], "warlord": ["Warlord's Command", "strike"], "conqueror": ["Conquest", "crit"],
	"grand_marshal": ["Hold the Line", "bulwark"], "champion": ["Champion's Stand", "bulwark"], "crusader": ["Crusade", "burst"],
	"holy_avenger": ["Avenging Light", "crit"], "templar_lord": ["Oathwall", "bulwark"], "weaponmaster": ["Arsenal", "flurry"],
	"blademaster": ["Perfect Cut", "crit"], "god_titan": ["Titan's Fall", "strike"],
	# Knight
	"guardian": ["Bastion", "bulwark"], "paladin": ["Lay on Hands", "mend"], "holy_bulwark": ["Unbreakable", "bulwark"],
	"lightsworn": ["Dawnblade", "burst"], "juggernaut": ["Unstoppable", "strike"], "iron_colossus": ["Iron Avalanche", "bulwark"],
	"warden_of_ruin": ["Ruinguard", "bulwark"], "lancer": ["Lunge", "flurry"], "dragoon": ["Dragon Dive", "strike"],
	"god_sky_dragoon": ["Skyfall", "strike"], "wyrmlancer": ["Wyrmpiercer", "flurry"], "death_knight": ["Deathgrip", "drain"],
	"dread_lord": ["Dread", "drain"], "hellrider": ["Hellcharge", "burst"],
	# Wanderer
	"swordsman": ["Drawing Cut", "crit"], "sword_saint": ["Sword Saint's Truth", "crit"], "god_sword_god": ["Heaven-Splitting Sword", "crit"],
	"sword_immortal": ["Undying Edge", "crit"], "blade_phantom": ["Phantom Step", "veil"], "ghost_blade": ["Ghost Cut", "crit"],
	"thousand_edges": ["A Thousand Edges", "flurry"], "demonic_disciple": ["Demon Palm", "drain"], "demon_saint": ["Demon Saint's Palm", "drain"],
	"god_heavenly_demon": ["Heavenly Demon's Descent", "rage"], "asura": ["Asura's Wrath", "rage"], "blood_fiend": ["Blood Feast", "drain"],
	"blood_demon_king": ["Sea of Blood", "drain"], "poison_sovereign": ["Venom Throne", "execute"],
	# Cleric
	"priest": ["Prayer of Mending", "mend"], "high_priest": ["Holy Word", "mend"], "saint": ["Miracle", "mend"],
	"oracle": ["Foresight", "veil"], "inquisitor": ["Inquisition", "burst"], "zealot": ["Zeal", "crit"],
	"purifier": ["Purifying Flame", "burst"], "druid": ["Rejuvenate", "mend"], "grove_keeper": ["Thornwall", "bulwark"],
	"god_archdruid": ["World Tree's Bloom", "mend"], "lifebinder": ["Lifebind", "mend"], "storm_druid": ["Squall", "burst"],
	"thunder_shaman": ["Thunder Totem", "burst"], "wildshaper": ["Bear Form", "rage"],
	# Acolyte
	"dawn_disciple": ["First Light", "mend"], "templar": ["Sacred Shield", "bulwark"], "sun_templar": ["Sunstrike", "burst"],
	"god_saint_militant": ["Holy War", "strike"], "seer": ["Glimpse", "veil"], "prophet": ["Prophecy", "crit"],
	"star_seer": ["Falling Star", "burst"], "cultist": ["Dark Rite", "drain"], "warlock": ["Eldritch Blast", "burst"],
	"hexlord": ["Grand Hex", "execute"], "void_caller": ["Call the Void", "burst"], "blood_knight": ["Blood Oath", "drain"],
	"blood_lord": ["Blood Tithe", "drain"], "reaper": ["Harvest Souls", "execute"],
	# Mage
	"elementalist": ["Elemental Surge", "burst"], "pyromancer": ["Firestorm", "burst"], "inferno_archmage": ["Inferno", "burst"],
	"storm_sovereign": ["Sovereign Storm", "flurry"], "cryomancer": ["Deep Freeze", "burst"], "glacial_sage": ["Glacier", "bulwark"],
	"frost_witch": ["Witch's Winter", "burst"], "arcanist": ["Arcane Barrage", "flurry"], "lightbinder": ["Bound Light", "burst"],
	"archmage_of_dawn": ["Dawnbreak", "burst"], "god_chronomancer": ["Stop Time", "time"], "necromancer": ["Raise the Fallen", "summon"],
	"necrolord": ["Army of the Dead", "summon"], "bone_sovereign": ["Bone Storm", "flurry"],
	# Trickster
	"rogue": ["Backstab", "crit"], "assassin": ["Assassinate", "execute"], "nightblade": ["Nightfall", "crit"],
	"kingslayer": ["Regicide", "execute"], "shadowdancer": ["Shadow Dance", "veil"], "god_phantom": ["Phantom's Embrace", "veil"],
	"mirage": ["Hall of Mirrors", "veil"], "gambler": ["Double or Nothing", "fortune"], "illusionist": ["Bewilder", "charm"],
	"grand_illusionist": ["Grand Illusion", "charm"], "dreamweaver": ["Sweet Dreams", "charm"], "pirate": ["Plunder", "fortune"],
	"corsair_king": ["Broadside", "flurry"], "fortune_s_fool": ["Jackpot", "fortune"],
	# Ranger
	"hunter": ["Aimed Shot", "crit"], "beastmaster": ["Call the Pack", "summon"], "pack_lord": ["Alpha's Howl", "summon"],
	"wild_king": ["King of Beasts", "summon"], "deadeye": ["Deadeye", "crit"], "god_hawkeye": ["Eye of the Hawk", "crit"],
	"death_s_arrow": ["Last Arrow", "execute"], "warden": ["Warden's Watch", "bulwark"], "grove_ranger": ["Grove's Gift", "mend"],
	"sylvan_guardian": ["Sylvan Ward", "bulwark"], "moonbow": ["Moonlit Arrow", "burst"], "stormcaller": ["Call Lightning", "burst"],
	"tempest_archer": ["Tempest Volley", "flurry"], "sky_hunter": ["Thunder Dive", "strike"],
	# Bard
	"minstrel": ["Song of Rest", "song"], "troubadour": ["Troubadour's Tale", "song"], "god_songweaver": ["The Song That Weaves", "song"],
	"choir_saint": ["Hymn of the Choir", "mend"], "siren": ["Siren Song", "charm"], "dirge_singer": ["Dirge", "execute"],
	"doom_chanter": ["Chant of Doom", "burst"], "skald": ["Saga", "song"], "war_chanter": ["War Chant", "song"],
	"warhorn": ["Sound the Horn", "song"], "skald_king": ["Saga of Kings", "song"], "spellsinger": ["Spellsong", "burst"],
	"arcane_harpist": ["Harp of Stars", "flurry"], "echo_mage": ["Echo", "flurry"],
	# Sentinel
	"oathguard": ["Sworn Stand", "bulwark"], "aegis_bearer": ["Raise the Aegis", "bulwark"], "aegis_eternal": ["Eternal Aegis", "bulwark"],
	"dawnwall": ["Wall of Dawn", "mend"], "vowkeeper": ["Keep the Vow", "bulwark"], "oath_eternal": ["Undying Oath", "bulwark"],
	"last_vow": ["Last Stand of Vows", "mend"], "ironclad": ["Cold Iron", "bulwark"], "frostwall": ["Frostwall", "bulwark"],
	"glacier_lord": ["Glacial Advance", "bulwark"], "barrow_warden": ["Grave Watch", "drain"], "tomb_sentinel": ["Tomb Guard", "drain"],
	# Ironbark
	"thornback": ["Thorn Coat", "bulwark"], "briarheart": ["Briar Burst", "bulwark"], "bramble_king": ["Crown of Thorns", "bulwark"],
	"mossback": ["Moss Mend", "mend"], "elder_oak": ["Elder's Shade", "mend"], "stonefist": ["Stone Fist", "strike"],
	"rockbreaker": ["Rockbreak", "strike"], "cragborn": ["Crag Skin", "bulwark"], "granite_titan": ["Granite Wall", "bulwark"],
	# Nightstalker
	"stalker": ["Stalk", "veil"], "cutthroat": ["Cutthroat", "execute"], "night_reaper": ["Night Harvest", "execute"],
	"duskrunner": ["Dusk Dash", "veil"], "moonlit_ghost": ["Ghost Step", "veil"], "skirmisher": ["Skirmish", "flurry"],
	"knife_dancer": ["Knife Dance", "flurry"], "ambusher": ["Ambush", "crit"], "silent_death": ["Silent Kill", "crit"],
	# Conjurer
	"binder": ["Binding Circle", "summon"], "spiritcaller": ["Call Spirits", "summon"], "ancestor_speaker": ["Ancestors' Aid", "summon"],
	"golemwright": ["Raise Golem", "summon"], "stone_artificer": ["Stone Guardian", "summon"], "demonologist": ["Infernal Pact", "summon"],
	"imp_master": ["Imp Swarm", "summon"], "legion_lord": ["Legion", "summon"], "voidbinder": ["Void Chains", "summon"],
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
	var nm: Array = NAMES.get(String(n["id"]), [])
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
