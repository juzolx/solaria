class_name SkillData
extends RefCounted
## Every skill in the game. Skills come from ability stones that monsters drop.
## Any class can use any skill; skills sharing a tag with your class hit harder.
## You equip 3 active and 5 passive skills (slots open as you level).
## A duplicate stone ranks a skill up (max 5). Past max it turns into dust,
## and dust crafts any skill you choose.
##
## Active keys: cd (turns), power (x Attack), hits, always_crit, def_scale,
## carry (leftover damage hits the next monster), burn (damage over 3 turns, x Attack),
## heal (% max HP), drain (% of damage healed), stun (turns), weaken + turns
## (enemy damage multiplier), buff {atk, def, crit, dodge, turns}, shield (% max HP),
## summon {power, turns} (a helper hits every turn), song {regen, turns},
## confuse (turns the monster hits itself), steal (gold x), wild (random effect),
## execute (extra x damage under 30% HP), hp_cost (% of your HP), reset (other cooldowns).
## Passive keys are per rank: atk / hp / def / skill (fractions, e.g. 0.04 = +4%),
## crit, dodge, lifesteal, regen, thorns, gold_find, double_strike, cdr, xp,
## stone_find, boss, execute, rage, potion (whole percents), tag {"Fire": 0.06}.

const MAX_RANK := 5
const RANK_POWER := 0.12        # each rank above 1 adds this much power to an active skill
const RARITY_NAMES := ["Common", "Rare", "Epic", "Signature"]
const RARITY_COLORS := ["#cbd5e1", "#60a5fa", "#c084fc", "#fde047"]
const DROP_WEIGHTS := [70.0, 25.0, 5.0]       # stone rarity odds from normal monsters
const BOSS_DROP_WEIGHTS := [40.0, 40.0, 20.0]
const STONE_CHANCE := 1.0                     # % per kill...
const STONE_TIER_MULT := [1.0, 1.5, 3.0, 6.0, 12.0, 25.0]  # ...times this by monster tier
const STONE_PITY := 150                       # a stone is guaranteed after this many kills without one
const DUST_PER_EXTRA := [10, 25, 60]          # dust from a stone of a maxed skill
const ACTIVE_SLOTS_AT := [1, 10, 25]          # level each active slot opens
const PASSIVE_SLOTS_AT := [1, 5, 15, 30, 45]

const SKILLS := {
	# ===== Blade =====
	"cleave": {"name": "Cleave", "kind": "active", "tags": ["Blade"], "rarity": 0, "cd": 5, "power": 3.0, "text": "A heavy cleave for 3x damage."},
	"shield_bash": {"name": "Shield Bash", "kind": "active", "tags": ["Blade", "Holy"], "rarity": 0, "cd": 6, "power": 1.6, "def_scale": 2.5, "stun": 1, "text": "Hits with your shield: 1.6x Attack plus 2.5x Defense, and stuns."},
	"whirlwind": {"name": "Whirlwind", "kind": "active", "tags": ["Blade"], "rarity": 1, "cd": 7, "power": 0.9, "hits": 4, "text": "Spin for 4 hits of 0.9x."},
	"executioner": {"name": "Executioner's Cut", "kind": "active", "tags": ["Blade", "Blood"], "rarity": 1, "cd": 8, "power": 2.5, "execute": 1.0, "text": "2.5x damage, doubled against a monster under 30% HP."},
	"iaido": {"name": "Iaido", "kind": "active", "tags": ["Blade"], "rarity": 2, "cd": 6, "power": 2.2, "always_crit": true, "text": "A lightning draw: a guaranteed crit for 4.4x."},
	"thousand_cuts": {"name": "Thousand Cuts", "kind": "active", "tags": ["Blade"], "rarity": 2, "cd": 10, "power": 0.8, "hits": 8, "text": "8 slashes of 0.8x, each can crit."},
	"earthshatter": {"name": "Earthshatter", "kind": "active", "tags": ["Blade", "Fist"], "rarity": 1, "cd": 10, "power": 5.0, "stun": 1, "text": "A 5x slam that stuns."},
	"wanderer_strike": {"name": "Wandering Strike", "kind": "active", "tags": ["Blade", "Fist"], "rarity": 0, "cd": 4, "power": 1.4, "hits": 2, "text": "A cut and a palm strike: 2 hits of 1.4x."},
	# ===== Fist =====
	"flurry": {"name": "Flurry of Blows", "kind": "active", "tags": ["Fist"], "rarity": 0, "cd": 5, "power": 0.9, "hits": 4, "text": "4 quick punches of 0.9x."},
	"heaven_palm": {"name": "Heaven Palm", "kind": "active", "tags": ["Fist", "Holy"], "rarity": 1, "cd": 7, "power": 3.0, "stun": 1, "text": "A 3x palm strike that stuns."},
	"demon_fist": {"name": "Demon Fist", "kind": "active", "tags": ["Fist", "Blood"], "rarity": 1, "cd": 6, "power": 2.6, "drain": 40, "text": "2.6x damage, heals you for 40% of it."},
	"hundred_fists": {"name": "Hundred Fists", "kind": "active", "tags": ["Fist"], "rarity": 2, "cd": 10, "power": 0.55, "hits": 10, "text": "10 punches of 0.55x."},
	# ===== Fire =====
	"fireball": {"name": "Fireball", "kind": "active", "tags": ["Fire"], "rarity": 0, "cd": 5, "power": 2.0, "burn": 0.4, "text": "2x damage and burns for 3 turns."},
	"flame_wave": {"name": "Flame Wave", "kind": "active", "tags": ["Fire"], "rarity": 1, "cd": 7, "power": 2.6, "burn": 0.6, "text": "2.6x damage and a strong burn."},
	"meteor": {"name": "Meteor", "kind": "active", "tags": ["Fire", "Arcane"], "rarity": 2, "cd": 10, "power": 5.0, "burn": 0.8, "text": "A 5x meteor and a heavy burn."},
	# ===== Frost =====
	"frost_nova": {"name": "Frost Nova", "kind": "active", "tags": ["Frost"], "rarity": 0, "cd": 8, "power": 1.5, "weaken": 0.5, "turns": 3, "text": "1.5x damage; the monster deals half damage for 3 turns."},
	"ice_lance": {"name": "Ice Lance", "kind": "active", "tags": ["Frost"], "rarity": 0, "cd": 5, "power": 2.6, "text": "A 2.6x lance of ice."},
	"blizzard": {"name": "Blizzard", "kind": "active", "tags": ["Frost", "Storm"], "rarity": 2, "cd": 10, "power": 0.8, "hits": 5, "weaken": 0.7, "turns": 3, "text": "5 hits of 0.8x; the monster deals 30% less for 3 turns."},
	"frozen_armor": {"name": "Frozen Armor", "kind": "active", "tags": ["Frost"], "rarity": 1, "cd": 10, "buff": {"def": 1.5, "turns": 5}, "text": "+50% Defense for 5 turns."},
	# ===== Storm =====
	"chain_lightning": {"name": "Chain Lightning", "kind": "active", "tags": ["Storm"], "rarity": 0, "cd": 6, "power": 1.0, "hits": 3, "text": "3 bolts of 1x."},
	"thunderclap": {"name": "Thunderclap", "kind": "active", "tags": ["Storm"], "rarity": 1, "cd": 8, "power": 2.0, "stun": 1, "text": "2x damage and stuns."},
	"call_storm": {"name": "Call the Storm", "kind": "active", "tags": ["Storm", "Nature"], "rarity": 2, "cd": 12, "power": 1.2, "hits": 6, "text": "6 lightning strikes of 1.2x."},
	# ===== Arcane =====
	"arcane_bolt": {"name": "Arcane Bolt", "kind": "active", "tags": ["Arcane"], "rarity": 0, "cd": 4, "power": 1.8, "text": "A quick 1.8x bolt."},
	"arcane_storm": {"name": "Arcane Storm", "kind": "active", "tags": ["Arcane"], "rarity": 2, "cd": 10, "power": 6.0, "text": "A 6x storm of pure magic."},
	"time_warp": {"name": "Time Warp", "kind": "active", "tags": ["Arcane"], "rarity": 2, "cd": 14, "reset": true, "power": 1.0, "text": "1x damage and every other skill is ready again."},
	"mana_shield": {"name": "Mana Shield", "kind": "active", "tags": ["Arcane"], "rarity": 1, "cd": 10, "shield": 25, "text": "A shield that soaks damage equal to 25% of your max HP."},
	# ===== Holy =====
	"holy_light": {"name": "Holy Light", "kind": "active", "tags": ["Holy"], "rarity": 0, "cd": 5, "power": 1.4, "heal": 18, "text": "1.4x damage and heals 18% HP."},
	"smite": {"name": "Smite", "kind": "active", "tags": ["Holy"], "rarity": 0, "cd": 5, "power": 2.4, "text": "A 2.4x bolt of holy light."},
	"judgment": {"name": "Judgment", "kind": "active", "tags": ["Holy", "Blade"], "rarity": 1, "cd": 9, "power": 4.0, "text": "A 4x holy blow."},
	"divine_shield": {"name": "Divine Shield", "kind": "active", "tags": ["Holy"], "rarity": 1, "cd": 12, "shield": 35, "text": "A shield worth 35% of your max HP."},
	"sanctuary": {"name": "Sanctuary", "kind": "active", "tags": ["Holy", "Nature"], "rarity": 2, "cd": 12, "song": {"regen": 4, "turns": 5}, "heal": 10, "text": "Heals 10% now and 4% a turn for 5 turns."},
	# ===== Shadow =====
	"shadowstrike": {"name": "Shadowstrike", "kind": "active", "tags": ["Shadow"], "rarity": 1, "cd": 5, "power": 2.0, "always_crit": true, "text": "From the dark: a guaranteed crit for 4x."},
	"curse": {"name": "Curse of Weakness", "kind": "active", "tags": ["Shadow"], "rarity": 0, "cd": 8, "power": 0.8, "weaken": 0.6, "turns": 4, "text": "0.8x damage; the monster deals 40% less for 4 turns."},
	"soul_drain": {"name": "Soul Drain", "kind": "active", "tags": ["Shadow", "Blood"], "rarity": 0, "cd": 5, "power": 2.2, "drain": 50, "text": "2.2x damage, heals you for half of it."},
	"raise_dead": {"name": "Raise Dead", "kind": "active", "tags": ["Shadow"], "rarity": 1, "cd": 12, "summon": {"power": 0.6, "turns": 6}, "text": "A skeleton fights beside you for 6 turns (0.6x a turn)."},
	# ===== Blood =====
	"war_cry": {"name": "War Cry", "kind": "active", "tags": ["Blood"], "rarity": 0, "cd": 8, "buff": {"atk": 1.4, "turns": 3}, "text": "+40% Attack for 3 turns."},
	"blood_rage": {"name": "Blood Rage", "kind": "active", "tags": ["Blood"], "rarity": 1, "cd": 9, "hp_cost": 10, "buff": {"atk": 1.6, "turns": 4}, "text": "Costs 10% HP: +60% Attack for 4 turns."},
	"bloodletting": {"name": "Bloodletting", "kind": "active", "tags": ["Blood", "Blade"], "rarity": 0, "cd": 6, "power": 1.8, "burn": 0.6, "text": "1.8x damage and the monster bleeds for 3 turns."},
	"crimson_feast": {"name": "Crimson Feast", "kind": "active", "tags": ["Blood"], "rarity": 2, "cd": 10, "power": 3.5, "drain": 60, "text": "3.5x damage, heals you for 60% of it."},
	# ===== Nature =====
	"piercing_shot": {"name": "Piercing Shot", "kind": "active", "tags": ["Nature"], "rarity": 0, "cd": 4, "power": 2.0, "carry": true, "text": "2x damage; leftover damage hits the next monster."},
	"thorn_lash": {"name": "Thorn Lash", "kind": "active", "tags": ["Nature"], "rarity": 0, "cd": 5, "power": 1.8, "burn": 0.5, "heal": 5, "text": "1.8x damage, the monster bleeds, and you heal 5%."},
	"call_beast": {"name": "Call of the Wild", "kind": "active", "tags": ["Nature"], "rarity": 1, "cd": 12, "summon": {"power": 0.8, "turns": 5}, "text": "A wolf fights beside you for 5 turns (0.8x a turn)."},
	"volley": {"name": "Volley", "kind": "active", "tags": ["Nature", "Storm"], "rarity": 1, "cd": 7, "power": 0.7, "hits": 5, "text": "5 arrows of 0.7x, each can crit."},
	"hawk_eye": {"name": "Hawk's Eye", "kind": "active", "tags": ["Nature"], "rarity": 2, "cd": 10, "buff": {"crit": 100, "turns": 3}, "text": "Every attack crits for 3 turns."},
	# ===== Song =====
	"battle_hymn": {"name": "Battle Hymn", "kind": "active", "tags": ["Song"], "rarity": 0, "cd": 6, "power": 1.8, "buff": {"atk": 1.15, "turns": 4}, "text": "1.8x damage and +15% Attack for 4 turns."},
	"war_song": {"name": "War Song", "kind": "active", "tags": ["Song"], "rarity": 0, "cd": 10, "buff": {"atk": 1.3, "turns": 6}, "text": "+30% Attack for 6 turns."},
	"lullaby": {"name": "Lullaby", "kind": "active", "tags": ["Song"], "rarity": 1, "cd": 9, "power": 0.5, "stun": 2, "text": "The monster falls asleep for 2 turns."},
	"ballad": {"name": "Ballad of Heroes", "kind": "active", "tags": ["Song", "Holy"], "rarity": 1, "cd": 12, "song": {"regen": 3, "turns": 6}, "buff": {"def": 1.2, "turns": 6}, "text": "Heal 3% a turn and +20% Defense for 6 turns."},
	"crescendo": {"name": "Crescendo", "kind": "active", "tags": ["Song"], "rarity": 2, "cd": 10, "power": 4.0, "text": "The big finish: 4x damage."},
	# ===== Trick =====
	"pocket_sand": {"name": "Pocket Sand", "kind": "active", "tags": ["Trick"], "rarity": 0, "cd": 7, "power": 0.8, "confuse": 2, "text": "0.8x damage; the monster hits itself for 2 turns."},
	"pickpocket": {"name": "Pickpocket", "kind": "active", "tags": ["Trick"], "rarity": 0, "cd": 6, "power": 1.2, "steal": 3.0, "text": "1.2x damage and steals gold (sometimes an item)."},
	"wild_card": {"name": "Wild Card", "kind": "active", "tags": ["Trick"], "rarity": 1, "cd": 6, "wild": true, "text": "Something random happens. Usually good. Usually."},
	"mirror_image": {"name": "Mirror Image", "kind": "active", "tags": ["Trick", "Arcane"], "rarity": 2, "cd": 11, "buff": {"dodge": 40, "turns": 3}, "text": "+40% dodge for 3 turns."},

	# ===== Passives =====
	"iron_will": {"name": "Iron Will", "kind": "passive", "tags": ["Blade"], "rarity": 0, "hp": 0.05, "text": "+5% max HP per rank."},
	"plate_mastery": {"name": "Plate Mastery", "kind": "passive", "tags": ["Holy"], "rarity": 0, "def": 0.06, "text": "+6% Defense per rank."},
	"inner_breath": {"name": "Inner Breath", "kind": "passive", "tags": ["Fist"], "rarity": 0, "dodge": 2.0, "regen": 0.2, "text": "+2% dodge and +0.2% HP regen a turn per rank."},
	"blessing": {"name": "Blessing", "kind": "passive", "tags": ["Holy"], "rarity": 0, "regen": 0.4, "text": "Regenerate 0.4% HP a turn per rank."},
	"devotion": {"name": "Devotion", "kind": "passive", "tags": ["Holy", "Shadow"], "rarity": 0, "skill": 0.05, "text": "+5% skill damage per rank."},
	"arcane_mind": {"name": "Arcane Mind", "kind": "passive", "tags": ["Arcane"], "rarity": 0, "skill": 0.06, "text": "+6% skill damage per rank."},
	"light_fingers": {"name": "Light Fingers", "kind": "passive", "tags": ["Trick"], "rarity": 0, "gold_find": 8.0, "text": "+8% gold per rank."},
	"keen_eye": {"name": "Keen Eye", "kind": "passive", "tags": ["Nature"], "rarity": 0, "crit": 2.0, "text": "+2% crit per rank."},
	"encore": {"name": "Encore", "kind": "passive", "tags": ["Song"], "rarity": 0, "atk": 0.02, "regen": 0.3, "text": "+2% Attack and +0.3% HP regen a turn per rank."},
	"sharpened_edge": {"name": "Sharpened Edge", "kind": "passive", "tags": ["Blade"], "rarity": 0, "atk": 0.04, "text": "+4% Attack per rank."},
	"toughness": {"name": "Toughness", "kind": "passive", "tags": ["Nature"], "rarity": 0, "hp": 0.05, "text": "+5% max HP per rank."},
	"iron_skin": {"name": "Iron Skin", "kind": "passive", "tags": ["Frost"], "rarity": 0, "def": 0.05, "text": "+5% Defense per rank."},
	"brutality": {"name": "Brutality", "kind": "passive", "tags": ["Blood"], "rarity": 0, "skill": 0.06, "text": "+6% skill damage per rank."},
	"vampirism": {"name": "Vampirism", "kind": "passive", "tags": ["Blood"], "rarity": 1, "lifesteal": 2.0, "text": "+2% lifesteal per rank."},
	"second_wind": {"name": "Second Wind", "kind": "passive", "tags": ["Holy"], "rarity": 1, "regen": 0.5, "text": "Regenerate 0.5% HP a turn per rank."},
	"quick_recovery": {"name": "Quick Recovery", "kind": "passive", "tags": ["Arcane"], "rarity": 2, "cdr": 0.4, "text": "Skill cooldowns -1 turn at rank 3, -2 at rank 5."},
	"fortune": {"name": "Fortune", "kind": "passive", "tags": ["Trick"], "rarity": 0, "gold_find": 6.0, "text": "+6% gold per rank."},
	"evasion": {"name": "Evasion", "kind": "passive", "tags": ["Shadow"], "rarity": 0, "dodge": 2.0, "text": "+2% dodge per rank."},
	"precision": {"name": "Precision", "kind": "passive", "tags": ["Blade"], "rarity": 0, "crit": 2.0, "text": "+2% crit per rank."},
	"twin_strikes": {"name": "Twin Strikes", "kind": "passive", "tags": ["Fist"], "rarity": 1, "double_strike": 2.5, "text": "+2.5% double strike per rank."},
	"bramble_hide": {"name": "Bramble Hide", "kind": "passive", "tags": ["Nature"], "rarity": 0, "thorns": 4.0, "text": "Reflect +4% damage per rank."},
	"pyromania": {"name": "Pyromania", "kind": "passive", "tags": ["Fire"], "rarity": 1, "tag": {"Fire": 0.06}, "text": "Fire skills +6% per rank."},
	"frostbite": {"name": "Frostbite", "kind": "passive", "tags": ["Frost"], "rarity": 1, "tag": {"Frost": 0.06}, "text": "Frost skills +6% per rank."},
	"static_charge": {"name": "Static Charge", "kind": "passive", "tags": ["Storm"], "rarity": 1, "tag": {"Storm": 0.06}, "text": "Storm skills +6% per rank."},
	"radiance": {"name": "Radiance", "kind": "passive", "tags": ["Holy"], "rarity": 1, "tag": {"Holy": 0.06}, "text": "Holy skills +6% per rank."},
	"umbral": {"name": "Umbral Pact", "kind": "passive", "tags": ["Shadow"], "rarity": 1, "tag": {"Shadow": 0.06}, "text": "Shadow skills +6% per rank."},
	"bloodlust": {"name": "Bloodlust", "kind": "passive", "tags": ["Blood"], "rarity": 1, "tag": {"Blood": 0.06}, "text": "Blood skills +6% per rank."},
	"wildheart": {"name": "Wildheart", "kind": "passive", "tags": ["Nature"], "rarity": 1, "tag": {"Nature": 0.06}, "text": "Nature skills +6% per rank."},
	"virtuoso": {"name": "Virtuoso", "kind": "passive", "tags": ["Song"], "rarity": 1, "tag": {"Song": 0.06}, "text": "Song skills +6% per rank."},
	"sleight": {"name": "Sleight of Hand", "kind": "passive", "tags": ["Trick"], "rarity": 1, "tag": {"Trick": 0.06}, "text": "Trick skills +6% per rank."},
	"martial_focus": {"name": "Martial Focus", "kind": "passive", "tags": ["Fist"], "rarity": 1, "tag": {"Fist": 0.06}, "text": "Fist skills +6% per rank."},
	"spellweaver": {"name": "Spellweaver", "kind": "passive", "tags": ["Arcane"], "rarity": 1, "tag": {"Arcane": 0.06}, "text": "Arcane skills +6% per rank."},
	"swordsmanship": {"name": "Swordsmanship", "kind": "passive", "tags": ["Blade"], "rarity": 1, "tag": {"Blade": 0.06}, "text": "Blade skills +6% per rank."},
	"scholar": {"name": "Scholar", "kind": "passive", "tags": ["Arcane"], "rarity": 0, "xp": 5.0, "text": "+5% XP per rank."},
	"treasure_hunter": {"name": "Treasure Hunter", "kind": "passive", "tags": ["Trick"], "rarity": 2, "stone_find": 10.0, "text": "Ability stones drop 10% more often per rank."},
	"giant_slayer": {"name": "Giant Slayer", "kind": "passive", "tags": ["Blade"], "rarity": 1, "boss": 6.0, "text": "+6% damage to bosses per rank."},
	"reaper_mark": {"name": "Reaper's Mark", "kind": "passive", "tags": ["Shadow"], "rarity": 1, "execute": 6.0, "text": "+6% damage to monsters under 30% HP per rank."},
	"last_stand": {"name": "Last Stand", "kind": "passive", "tags": ["Blood"], "rarity": 2, "rage": 6.0, "text": "Up to +6% damage per rank as your HP drops."},
	"herbalist": {"name": "Herbalist", "kind": "passive", "tags": ["Nature"], "rarity": 0, "potion": 10.0, "text": "Potions heal 10% more per rank."},
}

# Old Warrior/Archer/Mage heroes get these when they move to the new system
const OLD_CLASS_SKILLS := {
	"Warrior": ["cleave", "war_cry", "earthshatter", "iron_will", "sharpened_edge"],
	"Archer": ["piercing_shot", "volley", "hawk_eye", "keen_eye", "toughness"],
	"Mage": ["fireball", "frost_nova", "arcane_storm", "arcane_mind", "pyromania"],
}
const OLD_CLASS_MOVE := {"Archer": "Ranger"}

static func info(id: String) -> Dictionary:
	if id.begins_with(Signatures.PREFIX):
		return Signatures.info(id)
	return SKILLS.get(id, {})

static func skill_name(id: String) -> String:
	return str(info(id).get("name", id))

static func is_active(id: String) -> bool:
	return info(id).get("kind", "") == "active"

static func all_of(kind: String) -> Array:
	var out: Array = []
	for id in SKILLS:
		if SKILLS[id]["kind"] == kind:
			out.append(id)
	return out

## Picks a random skill for a stone. boss = better odds of rarer stones.
static func roll_stone(boss := false) -> String:
	var weights: Array = BOSS_DROP_WEIGHTS if boss else DROP_WEIGHTS
	var total := 0.0
	for w in weights:
		total += float(w)
	var roll := randf() * total
	var r := 0
	for i in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			r = i
			break
	var pool: Array = []
	for id in SKILLS:
		if int(SKILLS[id]["rarity"]) == r:
			pool.append(id)
	return pool.pick_random()

## Dust needed to craft a skill you don't have, or to rank one up.
static func craft_cost(id: String, current_rank: int) -> int:
	var r := int(SKILLS[id]["rarity"]) + 1
	if current_rank <= 0:
		return 60 * r * r
	return 20 * r * current_rank

## Rank multiplier for an active skill's numbers.
static func rank_mult(rank: int) -> float:
	return 1.0 + RANK_POWER * maxf(0.0, rank - 1)

## One line about the skill at a rank.
static func describe(id: String, rank: int) -> String:
	var s := info(id)
	if s.is_empty():
		return ""
	var t: String = s["text"]
	if s["kind"] == "active":
		t += "  (cooldown %d)" % int(s["cd"])
		if rank > 1:
			t += "  Rank %d: +%d%% power." % [rank, int(round((rank_mult(rank) - 1.0) * 100))]
	else:
		t += "  Now: rank %d." % rank
	return t
