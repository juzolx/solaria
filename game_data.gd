class_name GameData
extends RefCounted
## All the fixed numbers and content for the game: rarities, gear, enemies,
## bosses, unique items and prices. Change numbers here to rebalance.

const SAVE_VERSION := 2

# ---------- Rarities ----------
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Unique", "Set", "Signature"]
const RARITY_COLORS := ["#bbbbbb", "#4ade80", "#60a5fa", "#c084fc", "#fb923c", "#fbbf24", "#2dd4bf", "#ff6b9d"]
const RARITY_MULTS := [1.0, 1.35, 1.85, 2.6, 3.6, 4.0, 3.4, 4.3]
const SELL_MULTS := [1, 2, 4, 8, 16, 40, 20, 80]
const SCRAP_VALUES := [1, 2, 4, 8, 16, 40, 20, 80]
const REROLL_CHANCES := [50, 40, 30, 5]  # % chance to go up a tier, by current rarity (Epic -> Legendary is brutal)
const LEGENDARY := 4
const UNIQUE := 5
const SET_RARITY := 6  # crafted set items
const SIGNATURE := 7   # a monster's 1-in-1,000 drop

# ---------- Dungeon ----------
const FIGHTS_PER_FLOOR := 3
const BOSS_LOOT_DROPS := 3
const BOSS_RARITY_BONUS := 8
const UNIQUE_DROP_CHANCE := 5.0  # % per boss kill to start with...
const UNIQUE_PITY_STEP := 5.0    # ...plus this much for every boss kill without one

# Legendary chance (%) per drop, rolled separately so bonuses don't make them common
const LEGENDARY_CHANCE_NORMAL := 0.4
const LEGENDARY_CHANCE_BOSS := 2.0
const LEGENDARY_CHANCE_SHOP := 0.5
const LEGENDARY_CHANCE_CRAFT := 1.0

# Every Legendary gets one of these (weaker than a unique's effect) and a matching title
const LEGENDARY_EFFECTS := [
	{"effect": "lifesteal", "value": 5, "title": "of the Vampire"},
	{"effect": "regen", "value": 1, "title": "of Renewal"},
	{"effect": "double_strike", "value": 8, "title": "of Fury"},
	{"effect": "gold_find", "value": 15, "title": "of Fortune"},
	{"effect": "thorns", "value": 12, "title": "of Thorns"},
	{"effect": "crit", "value": 10, "title": "of Precision"},
	{"effect": "dodge", "value": 5, "title": "of Shadows"},
	# 0.9: more ways for a Legendary to feel different
	{"effect": "execute", "value": 20, "title": "of the Executioner"},
	{"effect": "boss", "value": 15, "title": "of the Slayer"},
	{"effect": "rage", "value": 25, "title": "of Wrath"},
	{"effect": "stone_find", "value": 30, "title": "of Discovery"},
	{"effect": "xp", "value": 12, "title": "of Wisdom"},
	{"effect": "cdr", "value": 1, "title": "of Haste"},
	{"effect": "potion", "value": 30, "title": "of the Alchemist"},
]
## Item effects that work through the bonus totals (not effect_value's list)
const ITEM_BONUS_EFFECTS := ["execute", "boss", "rage", "stone_find", "xp", "cdr", "potion"]
const ENEMY_GROWTH := 1.025  # enemies get 2.5% stronger per floor on top of normal scaling

# ---------- Bag ----------
const BAG_START := 10
const BAG_STEP := 3
const BAG_MAX_LEVEL := 20
# Backpacks: rare dungeon finds. Carry one home and your bag grows for good.
const PACK_SLOTS := 2               # slots each backpack adds
const PACK_MAX := 10                # most backpacks that count
const PACK_CHANCE := 0.15           # % per kill
const PACK_CHANCE_BOSS := 4.0       # % per boss
const BAG_BASE_COST := 10.0
const BAG_COST_GROWTH := 1.5

# ---------- Potions ----------
const POTION_GOLD := 25
const POTION_SCRAP := 5
const POTION_HEAL := 0.4
const AUTO_POTION_AT := 0.3
const START_POTIONS := 2

# ---------- Crafting and shop ----------
const CRAFT_GEAR_SCRAP := 20
const CRAFT_RARITY_BONUS := 10
const SHOP_SIZE := 6
const SHOP_RARITY_BONUS := 5
const SHOP_PRICE_MULT := 4
const SHOP_RESTOCK_GOLD := 30
const MERCHANT_NAME := "Grimble's Wares"
const FEATURED_LEGENDARY_CHANCE := 4.0  # % the featured deal is Legendary instead of Epic
const FEATURED_PRICE_MULT := 3            # on top of the normal shop price
const GREATER_POTION_GOLD := 90           # heals to full
# Elixirs: temporary boosts that last a number of turns
const ELIXIRS := {
	"might": {"name": "Elixir of Might", "text": "+25% Attack for 30 turns", "atk": 1.25, "turns": 30, "gold": 120},
	"iron": {"name": "Elixir of Iron", "text": "+30% Defense for 30 turns", "def": 1.3, "turns": 30, "gold": 120},
	"rested": {"name": "Well Rested", "text": "+15% Attack for 20 turns", "atk": 1.15, "turns": 20, "gold": 0},
	"fortune": {"name": "Elixir of Fortune", "text": "+50% gold for 30 turns", "gold_find": 50, "turns": 30, "gold": 100},
	"altar": {"name": "Blood Pact", "text": "+30% Attack", "atk": 1.3, "turns": 40, "gold": 0},
	"hexed": {"name": "Hexed", "text": "-20% Defense", "def": 0.8, "turns": 40, "gold": 0},
}
const PATH_CHANCE := 30  # % chance after a floor that you get to choose the next room
const PATH_WAIT_TURNS := 10  # turns before it picks "Fight on" for you
const PATHS := {
	"fight": {"name": "Fight on", "text": "Business as usual.", "color": "#cbd5e1"},
	"treasure": {"name": "Treasure room", "text": "A chest with gold and an item (better odds).", "color": "#fbbf24"},
	"rest": {"name": "Campfire", "text": "Heal to full, abilities ready, +15% Attack for 20 turns.", "color": "#4ade80"},
	"elite": {"name": "Elite monster", "text": "The next monster is at least Epic: tougher, with modifiers, and much better loot.", "color": "#f87171"},
	"merchant": {"name": "Wandering merchant", "text": "Epic and Legendary gear, mystery boxes and rare scrolls.", "color": "#e8b14a"},
	"shrine": {"name": "Touch the shrine", "text": "Cursed for 40 turns: monsters 30% tougher, but double gold and much better loot.", "color": "#c084fc"},
	"leave": {"name": "Walk past", "text": "Leave it alone and keep going.", "color": "#cbd5e1"},
}

# ---------- Dungeon events (about every 10 floors) ----------
const EVENT_MIN_FLOOR := 6
const EVENT_GAP := 6            # floors with no event before one can happen...
const EVENT_CHANCE_STEP := 20.0 # ...then +20% chance every floor
const GOBLIN_TURNS := 8         # turns before the treasure goblin escapes
const GOBLIN_GOLD := 25         # x normal gold
const GOBLIN_ITEMS := 2
const GOBLIN_RARITY := 20
const HORDE_SIZE := 5
const HORDE_HP := 0.5
const HORDE_CHEST_GOLD := 4
const HORDE_RARITY := 15
const CURSE_TURNS := 40
const CURSE_POWER := 1.3
const CURSE_LOOT := 25
# ---------- Wandering merchant and scrolls ----------
const MERCHANT_LEGENDARY_CHANCE := 10.0
const MERCHANT_PRICE_MULT := 2.5
const LUCK_TURNS := 60
const LUCK_BONUS := 20
const HUNT_SPAWNS := 15
const HUNT_RARE_BOOST := 3.0
# ---------- Fortune's Wheel (gambling) ----------
# Bet an item: win and it comes back one rarity higher (upgrades kept),
# lose and it's gone. The rarer the item, the worse the odds.
const GAMBLE_CHANCES := [55, 40, 25, 10]  # % to win, by rarity Common..Epic
const GAMBLE_FEE := 0.5                   # gold fee = this x the item's sell value
const GAMBLE_UNLOCK_FLOOR := 10
static func gamble_fee(item: Dictionary) -> int:
	return maxi(1, int(sell_value(item) * GAMBLE_FEE))
static func can_gamble(item: Dictionary) -> bool:
	return int(item["rarity"]) < LEGENDARY and not item.get("locked", false)
# ---------- Loot ----------
const FAVORED_SLOT_CHANCE := 0.6  # a monster's drop is one of its 2 favorite slots this often
# ---------- Heroes ----------
const MAX_HEROES := 3
const SLOT_UNLOCKS := [0, 25, 50]  # deepest floor any hero has reached to open slot 1, 2, 3
const STASH_START := 20
const STASH_STEP := 5
const STASH_MAX_LEVEL := 8
static func stash_cost(level: int) -> int:
	return int(round(500.0 * pow(1.8, level)))

# ---------- Limited-time events (by the date on your computer) ----------
const EVENTS := {
	"golden": {"name": "Golden Weekend", "text": "+50% gold from monsters (Saturday and Sunday)", "gold": 1.5},
	"bloodmoon": {"name": "Blood Moon", "text": "Fridays: elite rooms twice as common, better drops", "elite": 2.0, "rarity": 5},
	"lucky": {"name": "Lucky Week", "text": "This week: better item drops", "rarity": 6},
	"scholar": {"name": "Scholar's Week", "text": "This week: +25% XP", "xp": 1.25},
	"merchant": {"name": "Merchant's Week", "text": "This week: shop prices 20% off", "shop": 0.8},
}
const WEEKLY_EVENTS := ["lucky", "scholar", "merchant"]

## Events running right now: a weekly one, plus weekend / Friday specials.
static func active_events() -> Array:
	var out := []
	var days := floori(Time.get_unix_time_from_system() / 86400.0)
	var week := floori((days + 3) / 7.0)  # weeks starting Monday
	out.append(WEEKLY_EVENTS[posmod(week, WEEKLY_EVENTS.size())])
	var wd := int(Time.get_datetime_dict_from_system()["weekday"])  # 0 = Sunday
	if wd == 0 or wd == 6:
		out.append("golden")
	elif wd == 5:
		out.append("bloodmoon")
	return out

## Combined bonus from active events: multipliers multiply, "rarity" adds.
static func event_bonus(key: String, default := 1.0) -> float:
	var v := default
	for id in active_events():
		var e: Dictionary = EVENTS[id]
		if e.has(key):
			v = v + float(e[key]) if key == "rarity" else v * float(e[key])
	return v

const ELIXIR_ORDER := ["might", "iron", "fortune"]
const MAX_UPGRADE := 10

# ---------- Tapping and unlocks ----------
const TAP_DAMAGE := 0.3        # a tap hits for 30% of your Attack
const TAP_COOLDOWN := 0.22     # seconds between taps (about 4 per second)
const SHOP_UNLOCK_FLOOR := 3
const CRAFT_UNLOCK_FLOOR := 5

# ---------- Classes ----------
# The 9 classes, their paths and skills live in classes.gd and skill_data.gd.
const BURN_TURNS := 3
const BURN_POWER := 0.4  # burn damage per turn, as a share of Attack

# ---------- Stats ----------
# You get STAT_POINTS_PER_LEVEL points each level to put into these.
# Eight stats, one job each. You get 5 points a level (the old game gave 3
# points for 4 stats; the per-point numbers were scaled by 3/5 so a hero who
# puts everything into one stat is exactly as strong as before).
const STAT_ORDER := ["STR", "VIT", "AGI", "DEX", "INT", "WIS", "LUK", "CHA"]
const STAT_POINTS_PER_LEVEL := 5
const OLD_STAT_POINTS := 3      # per level before v0.11 (for converting saves)
const STAT_SCALE := 5.0 / 3.0   # old points -> new points
const STAT_INFO := {
	"STR": {"name": "Strength", "short": "Attack", "color": "#f87171", "text": "+1.2 Attack and +2.4 HP per point."},
	"VIT": {"name": "Vitality", "short": "HP and Defense", "color": "#4ade80", "text": "+6 HP and +0.36 Defense per point."},
	"AGI": {"name": "Agility", "short": "Dodge and speed", "color": "#60a5fa", "text": "Dodge, a chance to strike first when a fight starts, and a chance at an extra attack each turn."},
	"DEX": {"name": "Dexterity", "short": "Crits and double hits", "color": "#38bdf8", "text": "Crit chance and double strike chance."},
	"INT": {"name": "Intelligence", "short": "Skills", "color": "#c084fc", "text": "+1.5% skill damage per point and shorter skill cooldowns."},
	"WIS": {"name": "Wisdom", "short": "Healing and resistance", "color": "#2dd4bf", "text": "Stronger heals and potions, HP regen, and resistance to burns, poison, chill and curses."},
	"LUK": {"name": "Luck", "short": "Loot and fortune", "color": "#fbbf24", "text": "Better loot, more gold, harder crits, and better odds on events and signature drops."},
	"CHA": {"name": "Charisma", "short": "People and songs", "color": "#f472b6", "text": "Lower shop prices, better sell prices, charmed enemies, stronger companions and Song skills."},
}
const STR_ATTACK := 1.2
const STR_HP := 2.4
const VIT_HP := 6.0
const VIT_DEFENSE := 0.36
const INT_ABILITY_DMG := 0.015
# Percent stats use diminishing returns: cap * (1 - e^(-points / softness))
const DEX_CRIT := [35.0, 117.0]      # [max %, softness]
const DEX_DOUBLE := [25.0, 150.0]
const AGI_DODGE := [25.0, 150.0]
const AGI_HASTE := [20.0, 200.0]     # chance of an extra attack each turn
const AGI_FIRST := [60.0, 120.0]     # chance to strike first when a fight starts
const INT_COOLDOWN := [40.0, 167.0]  # max % cooldown reduction
const WIS_HEAL := [60.0, 170.0]      # % stronger heals, potions and song regen
const WIS_REGEN := [1.5, 200.0]      # % of max HP healed every turn
const WIS_RESIST := [60.0, 170.0]    # % less from burns, poison, chill and curses
const LUK_LOOT := [12.0, 170.0]      # rarity bonus on drops
const LUK_GOLD := [60.0, 170.0]      # % more gold
const LUK_CRIT_DMG := [60.0, 170.0]  # % more crit damage (crits do 2x + this)
const LUK_EVENTS := [60.0, 170.0]    # % better odds of events, encounters and signature drops
const CHA_DISCOUNT := [35.0, 170.0]  # % off shop and merchant prices
const CHA_SELL := [50.0, 170.0]      # % more gold when selling
const CHA_CHARM := [15.0, 200.0]     # % chance a monster is charmed and skips its attack
const CHA_PARTY := [40.0, 170.0]     # % more companion damage
const CHA_SONG := [40.0, 170.0]      # % more Song skill power
const CRIT_CAP := 75   # nobody crits more than this %
const DODGE_CAP := 60  # or dodges more than this %

static func diminishing(points: int, curve: Array) -> float:
	return float(curve[0]) * (1.0 - exp(-points / float(curve[1])))

# ---------- Boss materials and crafting sets ----------
# Every boss drops its zone's material. Materials craft Set items (strong,
# with bonuses for wearing 2 or 3 pieces of the same set) and bigger bags.
const BOSS_MATERIAL_DROP := [5, 8]  # min, max per boss kill
const SALVAGE_MATERIALS := {3: 1, 4: 2}  # salvaging Epic / Legendary gear gives its zone's material
const SET_PIECE_MATERIALS := 10
const SET_PIECE_SCRAP := 40
const MATERIALS := ["Grendel's Claw", "Grave Silk", "Charybdis Pearl", "Surtr's Ember", "Typhon Scale"] + Realms.MATERIALS
const SETS := {
	"Grendel's Kin": {"material": 0, "pieces": {"Weapon": "Mere-Hag Cleaver", "Chest": "Hall-Breaker Hide", "Legs": "Moor Stalker Greaves"},
		"bonus2": {"hp": 1.1}, "bonus3": {"lifesteal": 6},
		"text": "2 pieces: +10% HP. 3 pieces: +6% lifesteal."},
	"Hel's Shroud": {"material": 1, "pieces": {"Helmet": "Shroud Veil", "Chest": "Deathless Mantle", "Feet": "Helroad Boots"},
		"bonus2": {"regen": 1}, "bonus3": {"dodge": 8},
		"text": "2 pieces: 1% regen. 3 pieces: +8% dodge."},
	"Tidecaller": {"material": 2, "pieces": {"Weapon": "Maelstrom Trident", "Off Hand": "Tide Ward", "Feet": "Seafoam Treads"},
		"bonus2": {"gold_find": 15}, "bonus3": {"double_strike": 10},
		"text": "2 pieces: +15% gold. 3 pieces: +10% double strike."},
	"Muspel Forge": {"material": 3, "pieces": {"Weapon": "Ember Greatsword", "Helmet": "Forgeborn Helm", "Legs": "Cinder Greaves"},
		"bonus2": {"crit": 6}, "bonus3": {"atk": 1.15},
		"text": "2 pieces: +6% crit. 3 pieces: +15% Attack."},
	"Titanborn": {"material": 4, "pieces": {"Off Hand": "Scaled Bulwark", "Chest": "Serpentcoil Plate", "Helmet": "Hundred-Eye Circlet"},
		"bonus2": {"thorns": 15}, "bonus3": {"def": 1.2},
		"text": "2 pieces: reflect 15%. 3 pieces: +20% Defense."},
	# The realms (floors 251-500)
	"Last Light of the Elves": {"material": 5, "pieces": {"Weapon": "Lastlight Bow", "Helmet": "Leafcrown of the Wardens", "Feet": "Hushstep Boots"},
		"bonus2": {"dodge": 8}, "bonus3": {"crit": 10},
		"text": "2 pieces: +8% dodge. 3 pieces: +10% crit."},
	"Court of Glamour": {"material": 6, "pieces": {"Off Hand": "Mirror of the Court", "Chest": "Glamourweave Gown", "Legs": "Revelry Leggings"},
		"bonus2": {"gold_find": 20}, "bonus3": {"skill": 1.15},
		"text": "2 pieces: +20% gold. 3 pieces: +15% skill damage."},
	"Undermountain Oath": {"material": 7, "pieces": {"Off Hand": "Oathstone Bulwark", "Chest": "Kingsguard Runeplate", "Feet": "Deepforge Sabatons"},
		"bonus2": {"thorns": 15}, "bonus3": {"def": 1.2},
		"text": "2 pieces: reflect 15%. 3 pieces: +20% Defense."},
	"Choir of Dawn": {"material": 8, "pieces": {"Weapon": "Dawnchoir Spear", "Helmet": "Halo of the Choir", "Chest": "Seraph-Feather Mantle"},
		"bonus2": {"regen": 1}, "bonus3": {"hp": 1.2},
		"text": "2 pieces: 1% regen. 3 pieces: +20% HP."},
	"Pact of the Abyss": {"material": 9, "pieces": {"Weapon": "Pactbound Cleaver", "Helmet": "Hornhelm of the Pact", "Legs": "Cinderchain Greaves"},
		"bonus2": {"lifesteal": 6}, "bonus3": {"atk": 1.15},
		"text": "2 pieces: +6% lifesteal. 3 pieces: +15% Attack."},
}
## Which look each set piece uses
const SET_TYPES := {
	"Mere-Hag Cleaver": "axe", "Hall-Breaker Hide": "tunic", "Moor Stalker Greaves": "greaves",
	"Shroud Veil": "hood", "Deathless Mantle": "robe", "Helroad Boots": "boots",
	"Maelstrom Trident": "spear", "Tide Ward": "shield", "Seafoam Treads": "sandals",
	"Ember Greatsword": "sword", "Forgeborn Helm": "helm", "Cinder Greaves": "greaves",
	"Scaled Bulwark": "tower", "Serpentcoil Plate": "plate", "Hundred-Eye Circlet": "crown",
	"Lastlight Bow": "bow", "Leafcrown of the Wardens": "crown", "Hushstep Boots": "boots",
	"Mirror of the Court": "orb", "Glamourweave Gown": "robe", "Revelry Leggings": "leggings",
	"Oathstone Bulwark": "tower", "Kingsguard Runeplate": "plate", "Deepforge Sabatons": "sabatons",
	"Dawnchoir Spear": "spear", "Halo of the Choir": "crown", "Seraph-Feather Mantle": "robe",
	"Pactbound Cleaver": "axe", "Hornhelm of the Pact": "helm", "Cinderchain Greaves": "greaves",
}
const SET_ORDER := ["Grendel's Kin", "Hel's Shroud", "Tidecaller", "Muspel Forge", "Titanborn",
	"Last Light of the Elves", "Court of Glamour", "Undermountain Oath", "Choir of Dawn", "Pact of the Abyss"]
# ---------- Evolution sets (v0.11) ----------
# One set for each family of classes. They drop from bosses and elite
# monsters (more often the ones that fit your class), never from crafting.
# "tag" bonuses make skills of those tags stronger.
const EVO_SETS := {
	"Crimson Covenant": {"tags": ["Blood"], "pieces": {"Weapon": "Covenant Bloodblade", "Chest": "Covenant Hauberk", "Legs": "Covenant Greaves"},
		"types": {"Weapon": "axe", "Chest": "plate", "Legs": "greaves"}, "mat": "dark", "trim": "#e43b44",
		"bonus2": {"lifesteal": 6}, "bonus3": {"tag": {"Blood": 0.2}, "rage": 15},
		"text": "2 pieces: +6% lifesteal. 3 pieces: Blood skills +20%, up to +15% damage when hurt."},
	"Dawnward Vestments": {"tags": ["Holy"], "pieces": {"Helmet": "Dawnward Circlet", "Chest": "Dawnward Robe", "Off Hand": "Dawnward Aegis"},
		"types": {"Helmet": "crown", "Chest": "robe", "Off Hand": "shield"}, "mat": "gold", "trim": "#fde68a",
		"bonus2": {"regen": 1}, "bonus3": {"tag": {"Holy": 0.2}, "heal": 15},
		"text": "2 pieces: +1% regen. 3 pieces: Holy skills +20%, heals +15%."},
	"Umbral Regalia": {"tags": ["Shadow"], "pieces": {"Helmet": "Umbral Cowl", "Legs": "Umbral Leggings", "Feet": "Umbral Treads"},
		"types": {"Helmet": "hood", "Legs": "leggings", "Feet": "boots"}, "mat": "dark", "trim": "#8b5cf6",
		"bonus2": {"dodge": 6}, "bonus3": {"tag": {"Shadow": 0.2}, "execute": 20},
		"text": "2 pieces: +6% dodge. 3 pieces: Shadow skills +20%, +20% damage to monsters under 30% HP."},
	"Elemental Concord": {"tags": ["Fire", "Frost", "Storm", "Arcane"], "pieces": {"Weapon": "Concord Staff", "Off Hand": "Concord Orb", "Helmet": "Concord Hood"},
		"types": {"Weapon": "staff", "Off Hand": "orb", "Helmet": "hood"}, "mat": "crystal", "trim": "#c084fc",
		"bonus2": {"skill": 1.08}, "bonus3": {"weakness": 25, "tag": {"Fire": 0.1, "Frost": 0.1, "Storm": 0.1, "Arcane": 0.1}},
		"text": "2 pieces: +8% skill damage. 3 pieces: hits on a weakness do 25% more, elemental skills +10%."},
	"Wildheart Garb": {"tags": ["Nature"], "pieces": {"Weapon": "Wildheart Bow", "Chest": "Wildheart Tunic", "Feet": "Wildheart Boots"},
		"types": {"Weapon": "bow", "Chest": "tunic", "Feet": "boots"}, "mat": "leather", "trim": "#63c74d",
		"bonus2": {"hp": 1.1}, "bonus3": {"tag": {"Nature": 0.2}, "regen": 1},
		"text": "2 pieces: +10% HP. 3 pieces: Nature skills +20%, +1% regen."},
	"Bladesworn Steel": {"tags": ["Blade", "Fist"], "pieces": {"Weapon": "Bladesworn Edge", "Helmet": "Bladesworn Helm", "Legs": "Bladesworn Greaves"},
		"types": {"Weapon": "sword", "Helmet": "helm", "Legs": "greaves"}, "mat": "steel", "trim": "#c0cbdc",
		"bonus2": {"crit": 6}, "bonus3": {"crit_dmg": 25, "tag": {"Blade": 0.15, "Fist": 0.15}},
		"text": "2 pieces: +6% crit. 3 pieces: +25% crit damage, Blade and Fist skills +15%."},
	"Minstrel's Finery": {"tags": ["Song", "Trick"], "pieces": {"Off Hand": "Finery Songbook", "Chest": "Finery Doublet", "Helmet": "Finery Cap"},
		"types": {"Off Hand": "tome", "Chest": "tunic", "Helmet": "cap"}, "mat": "cloth", "trim": "#f472b6",
		"bonus2": {"gold_find": 15}, "bonus3": {"tag": {"Song": 0.2, "Trick": 0.2}, "charm": 5},
		"text": "2 pieces: +15% gold. 3 pieces: Song and Trick skills +20%, +5% charm."},
	"Bulwark of Ages": {"tags": ["Holy", "Blade"], "pieces": {"Off Hand": "Ageless Bulwark", "Chest": "Ageless Plate", "Feet": "Ageless Sabatons"},
		"types": {"Off Hand": "tower", "Chest": "plate", "Feet": "sabatons"}, "mat": "iron", "trim": "#94a3b8",
		"bonus2": {"def": 1.1}, "bonus3": {"thorns": 15, "hp": 1.1},
		"text": "2 pieces: +10% Defense. 3 pieces: reflect 15% of damage, +10% HP."},
}
const EVO_SET_ORDER := ["Crimson Covenant", "Dawnward Vestments", "Umbral Regalia", "Elemental Concord", "Wildheart Garb", "Bladesworn Steel", "Minstrel's Finery", "Bulwark of Ages"]
const EVO_SET_BOSS_CHANCE := 25.0   # % a boss drops an evolution set piece
const EVO_SET_ELITE_CHANCE := 4.0   # % an Epic-or-better monster does
const EVO_SET_FIT := 0.7            # how often it's a set that fits your class's tags

## Set info for any set (crafted or evolution).
static func set_info(set_name: String) -> Dictionary:
	if SETS.has(set_name):
		return SETS[set_name]
	return EVO_SETS.get(set_name, {})

## Makes an evolution set piece.
static func make_evo_piece(set_name: String, slot: String, floor_num: int, id: int) -> Dictionary:
	var info: Dictionary = EVO_SETS[set_name]
	var piece: String = info["pieces"][slot]
	return {
		"id": id, "base_name": piece, "name": piece, "type": info["types"][slot], "slot": slot, "stat": SLOT_INFO[slot]["stat"],
		"rarity": SET_RARITY, "bonus": maxi(1, int(base_bonus(slot, floor_num) * float(RARITY_MULTS[SET_RARITY]) * 1.05)),
		"level": 0, "floor": floor_num, "effect": "", "effect_value": 0, "set": set_name,
		"flavor": "Part of the %s. %s" % [set_name, info["text"]],
	}

# ---------- Living items (v0.11) ----------
# Legendary, Unique and Signature gear grows with you: kills while it's worn
# fill its soul. Each soul level adds 4% to its power; at level 5 it awakens
# a second, hidden effect.
const SOUL_KILLS := [100, 300, 700, 1500, 3000]
const SOUL_POWER := 0.04
const SOUL_MAX := 5

static func is_living(item: Dictionary) -> bool:
	return int(item.get("rarity", 0)) in [LEGENDARY, UNIQUE, SIGNATURE]

static func soul_level(item: Dictionary) -> int:
	var k := int(item.get("soul", 0))
	var lv := 0
	for need in SOUL_KILLS:
		if k >= int(need):
			lv += 1
	return lv

# Crafting a bigger bag: any boss materials + scrap, cost grows with bag level
const BAG_CRAFT_MATERIALS := 5
const BAG_CRAFT_SCRAP := 30

# ---------- Levels ----------
const LEVEL_ATTACK := 1      # per level, on top of your stat points
const LEVEL_HP := 4          # per level
const LEVEL_DEFENSE := 0.25  # per level
const LEVEL_MASTERY := 0.006 # +0.6% Attack, Defense and HP per level (replaces the old skill tree's bonuses)

# ---------- Races (picked in the character creator) ----------
# The 12 races live in races.gd (with racial power, awakening and transformations).
const RACES := Races.ORDER
const RACE_INFO := Races.INFO

# ---------- Gear ----------
const SLOT_ORDER := ["Weapon", "Off Hand", "Helmet", "Chest", "Legs", "Feet"]
const SLOT_INFO := {
	"Weapon": {"stat": "Attack", "names": ["Sword", "Axe", "Dagger", "Mace", "Spear"], "base": 3.0, "per_floor": 2.0},
	"Off Hand": {"stat": "Defense", "names": ["Buckler", "Shield", "Tower Shield"], "base": 1.0, "per_floor": 0.5},
	"Helmet": {"stat": "HP", "names": ["Cap", "Helm", "Hood"], "base": 5.0, "per_floor": 4.0},
	"Chest": {"stat": "Defense", "names": ["Tunic", "Chestplate", "Robe"], "base": 1.0, "per_floor": 0.5},
	"Legs": {"stat": "HP", "names": ["Pants", "Greaves", "Leggings"], "base": 5.0, "per_floor": 4.0},
	"Feet": {"stat": "Defense", "names": ["Boots", "Sandals", "Sabatons"], "base": 1.0, "per_floor": 0.5},
}

# ---------- Zones, creatures and bosses ----------
# Every 50 floors is a zone with its own creatures from world mythology.
# A zone has 5 sub-areas of 10 floors. Each sub-area adds one creature of
# its own to the zone's 5. Floor 25 is the zone's mid boss, floor 50 its boss.
# After floor 250 the zones repeat with tougher "Elder", "Ancient" and
# "Primordial" versions.
# "shape" is the old fallback body; "art" names the sprite in art/enemies/.
const ZONE_FLOORS := 50
const SUB_FLOORS := 10
const MID_BOSS_FLOOR := 25          # inside each zone
const BOSS_EVERY := 25              # some boss every 25 floors (mid boss, then zone boss)
const MID_BOSS_HP := 3.0
const ZONE_BOSS_HP := 3.8
const BOSS_ATK := 1.2
const BOSS_COOLDOWN := {"mid": 15, "zone": 30}  # seconds before you can travel back to fight a boss again
const LOCAL_MONSTER_WEIGHT := 10.0  # the sub-area's own creature is a bit rarer than the zone's 5 (18 each)
const BASE_MONSTER_WEIGHT := 18.0
const ROOT_ZONES := [
	{"name": "Mossy Hollows", "color": "#4d7c0f", "enemies": [
		{"name": "Kobold", "shape": "humanoid", "color": "#b45309"},       # German folklore
		{"name": "Redcap", "shape": "humanoid", "color": "#dc2626"},       # Scottish border folklore
		{"name": "Boggart", "shape": "brute", "color": "#8a7f72"},         # English folklore
		{"name": "Will-o'-Wisp", "shape": "spirit", "color": "#7dd3fc"},   # European folklore
		{"name": "Barghest", "shape": "beast", "color": "#57534e"},        # Yorkshire black dog
	], "subs": [
		{"name": "Fernlight Glade", "monster": {"name": "Spriggan", "shape": "brute", "color": "#6b8e3a"}},        # Cornish
		{"name": "Toadstool Ring", "monster": {"name": "Pooka", "shape": "beast", "color": "#2b2b3a"}},            # Irish
		{"name": "Bramble Warren", "monster": {"name": "Wolpertinger", "shape": "beast", "color": "#b08a5a"}},     # Bavarian
		{"name": "Hollow Oak", "monster": {"name": "Leshy", "shape": "humanoid", "color": "#4a6b3a"}},            # Slavic
		{"name": "Wychwood Heart", "monster": {"name": "Woodwose", "shape": "brute", "color": "#7a5a3a"}},         # English
	], "mid": {"name": "Black Annis", "art": "boss_black_annis", "shape": "humanoid", "color": "#4a6fa5", "uniques": [  # English
		{"name": "Annis's Skinning Claw", "flavor": "Her iron nail, as long as a knife.", "slot": "Weapon", "effect": "lifesteal", "value": 12},
	]}, "boss": {"name": "Grendel", "art": "boss_grendel", "shape": "brute", "color": "#65a30d", "uniques": [  # Beowulf
		{"name": "Hrunting", "flavor": "Beowulf's borrowed blade. It failed him once. It won't fail you.", "slot": "Weapon", "effect": "lifesteal", "value": 10},
		{"name": "Grendel's Hide", "flavor": "Grendel's skin. No blade could cut it, and now none can cut you.", "slot": "Chest", "effect": "thorns", "value": 20},
	]}},
	{"name": "Sunken Catacombs", "color": "#475569", "enemies": [
		{"name": "Ghoul", "shape": "humanoid", "color": "#a3a3a3"},        # Arabian folklore
		{"name": "Draugr", "shape": "brute", "color": "#64748b"},          # Norse undead
		{"name": "Barrow-Wight", "shape": "spirit", "color": "#cbd5e1"},   # Norse / English
		{"name": "Banshee", "shape": "spirit", "color": "#e9d5ff"},        # Irish folklore
		{"name": "Strigoi", "shape": "humanoid", "color": "#9f1239"},      # Romanian folklore
	], "subs": [
		{"name": "Bone Stair", "monster": {"name": "Revenant", "shape": "humanoid", "color": "#8a8f7a"}},          # European
		{"name": "The Ossuary", "monster": {"name": "Gashadokuro", "shape": "brute", "color": "#e8e4d8"}},        # Japanese
		{"name": "Crypt of Candles", "monster": {"name": "Vetala", "shape": "spirit", "color": "#9a7fb0"}},       # Hindu
		{"name": "Weeping Halls", "monster": {"name": "Moroi", "shape": "spirit", "color": "#c0cbdc"}},          # Romanian
		{"name": "Hel's Gate", "monster": {"name": "Garmr", "shape": "beast", "color": "#6a2a2a"}},              # Norse
	], "mid": {"name": "The Dullahan", "art": "boss_dullahan", "shape": "humanoid", "color": "#2a2a3a", "uniques": [  # Irish
		{"name": "The Hollow Helm", "flavor": "There was never a head inside it. There never needed to be.", "slot": "Helmet", "effect": "dodge", "value": 10},
	]}, "boss": {"name": "Hel, Queen of the Dead", "art": "boss_hel", "shape": "spirit", "color": "#94a3b8", "uniques": [  # Norse
		{"name": "Helskor", "flavor": "Hel's own shoes. Death walks lightly.", "slot": "Feet", "effect": "dodge", "value": 10},
		{"name": "Mask of Half-Death", "flavor": "Half of Hel's face was living, half was dead. So is this mask.", "slot": "Helmet", "effect": "regen", "value": 3},
	]}},
	{"name": "Flooded Depths", "color": "#0e7490", "enemies": [
		{"name": "Kappa", "shape": "humanoid", "color": "#16a34a"},        # Japanese folklore
		{"name": "Kelpie", "shape": "beast", "color": "#0891b2"},          # Scottish water horse
		{"name": "Nuckelavee", "shape": "brute", "color": "#be123c"},      # Orkney folklore
		{"name": "Bunyip", "shape": "beast", "color": "#a16207"},          # Aboriginal Australian
		{"name": "Umibozu", "shape": "spirit", "color": "#4c6ef5"},        # Japanese sea spirit
	], "subs": [
		{"name": "Tidepools", "monster": {"name": "Selkie", "shape": "beast", "color": "#7a8a9a"}},                # Scottish / Irish
		{"name": "Drowned Village", "monster": {"name": "Vodyanoy", "shape": "humanoid", "color": "#5a7a4a"}},    # Slavic
		{"name": "Coral Maze", "monster": {"name": "Merrow", "shape": "humanoid", "color": "#3fa29a"}},           # Irish
		{"name": "Kelp Abyss", "monster": {"name": "Grindylow", "shape": "spirit", "color": "#4a7a5a"}},          # English
		{"name": "Whirlpool's Edge", "monster": {"name": "Ahuizotl", "shape": "beast", "color": "#2a4a6a"}},      # Aztec
	], "mid": {"name": "Scylla", "art": "boss_scylla", "shape": "serpent", "color": "#4a8a8a", "uniques": [  # Greek
		{"name": "Sailor's Bane", "flavor": "Six heads, six bites, one spear.", "slot": "Weapon", "effect": "double_strike", "value": 18},
	]}, "boss": {"name": "Charybdis", "art": "boss_charybdis", "shape": "serpent", "color": "#06b6d4", "uniques": [  # Greek
		{"name": "Scylla's Fang", "flavor": "Pulled from the six-headed monster across the strait.", "slot": "Weapon", "effect": "crit", "value": 20},
		{"name": "Drowned Captain's Boots", "flavor": "Every captain Charybdis swallowed left treasure behind. He left his boots.", "slot": "Feet", "effect": "gold_find", "value": 25},
	]}},
	{"name": "Ember Halls", "color": "#c2410c", "enemies": [
		{"name": "Salamander", "shape": "serpent", "color": "#ea580c"},    # alchemy / European
		{"name": "Ifrit", "shape": "spirit", "color": "#f97316"},          # Arabian djinn
		{"name": "Hellhound", "shape": "beast", "color": "#b91c1c"},       # many mythologies
		{"name": "Chimera", "shape": "beast", "color": "#ca8a04"},         # Greek
		{"name": "Manticore", "shape": "beast", "color": "#d9480f"},       # Persian
	], "subs": [
		{"name": "Cinder Steps", "monster": {"name": "Cherufe", "shape": "brute", "color": "#6a3a2a"}},           # Mapuche (Chile)
		{"name": "Forge of Ash", "monster": {"name": "Cyclops", "shape": "brute", "color": "#8a7a6a"}},           # Greek
		{"name": "Magma Galleries", "monster": {"name": "Firebird", "shape": "beast", "color": "#feae34"}},       # Slavic
		{"name": "Brimstone Vault", "monster": {"name": "Tatzelwurm", "shape": "serpent", "color": "#a87a4a"}},   # Alpine
		{"name": "Muspel Gate", "monster": {"name": "Basilisk", "shape": "serpent", "color": "#5a8a3a"}},         # European
	], "mid": {"name": "Fafnir", "art": "boss_fafnir", "shape": "serpent", "color": "#3e7a4a", "uniques": [  # Norse
		{"name": "Dragonblood Plate", "flavor": "Bathe in a dragon's blood and no blade can touch you. Almost.", "slot": "Chest", "effect": "regen", "value": 2},
	]}, "boss": {"name": "Surtr the Fire Giant", "art": "boss_surtr", "shape": "brute", "color": "#ef4444", "uniques": [  # Norse
		{"name": "Flame of Muspelheim", "flavor": "Surtr's sword, meant to set the world on fire at the end of days.", "slot": "Weapon", "effect": "double_strike", "value": 25},
		{"name": "Emberforged Greaves", "flavor": "Hammered on the anvil of the fire giants.", "slot": "Legs", "effect": "regen", "value": 2},
	]}},
	{"name": "The Shadow Deep", "color": "#6d28d9", "enemies": [
		{"name": "Wendigo", "shape": "brute", "color": "#d6d3d1"},         # Algonquian folklore
		{"name": "Jorogumo", "shape": "humanoid", "color": "#8b5cf6"},     # Japanese spider-woman
		{"name": "Rakshasa", "shape": "humanoid", "color": "#f59e0b"},     # Hindu mythology
		{"name": "Lamia", "shape": "serpent", "color": "#65a30d"},         # Greek
		{"name": "Gorgon", "shape": "serpent", "color": "#4d7c0f"},        # Greek
	], "subs": [
		{"name": "Gloamwood Edge", "monster": {"name": "Kitsune", "shape": "beast", "color": "#e07a3a"}},         # Japanese
		{"name": "Weeping Stars", "monster": {"name": "Tikbalang", "shape": "humanoid", "color": "#5a3a2a"}},     # Filipino
		{"name": "Mirror Hollow", "monster": {"name": "Doppelganger", "shape": "humanoid", "color": "#3a3a5a"}},  # German
		{"name": "Void Spire", "monster": {"name": "Krampus", "shape": "brute", "color": "#3a2a2a"}},             # Alpine
		{"name": "Abyssal Throne", "monster": {"name": "Bakunawa", "shape": "serpent", "color": "#3a5a8a"}},      # Filipino
	], "mid": {"name": "Echidna", "art": "boss_echidna", "shape": "serpent", "color": "#8a5a9a", "uniques": [  # Greek
		{"name": "Book of Every Monster", "flavor": "Echidna's list of her children. You've met most of them.", "slot": "Off Hand", "effect": "gold_find", "value": 25},
	]}, "boss": {"name": "Typhon, Father of Monsters", "art": "boss_typhon", "shape": "serpent", "color": "#7c3aed", "uniques": [  # Greek
		{"name": "Aegis Fragment", "flavor": "A shard of Zeus's shield, with Medusa's gaze still in it.", "slot": "Off Hand", "effect": "dodge", "value": 12},
		{"name": "Crown of a Hundred Heads", "flavor": "Typhon had a hundred dragon heads. This crown remembers all of them.", "slot": "Helmet", "effect": "thorns", "value": 30},
	]}},
]
## Floors 1-250 are the roots (above), 251-500 the race realms (realms.gd).
const ZONES := ROOT_ZONES + Realms.ZONES
const RANK_PREFIXES := ["", "Elder ", "Ancient ", "Primordial "]
## The order you chose the realms in (realm ids). Set from the hero playing.
static var realm_order: Array = []

# ---------- Helpers ----------

static func color_of(rarity: int) -> String:
	return RARITY_COLORS[rarity]

## Legendary is rolled on its own tiny chance; the bonus only improves Common..Epic odds.
# Base chance (%) of each rarity per drop, before bonuses. Base luck is bad on
# purpose: luck, gambling, crafting and deeper floors are how you beat it.
# A blue is exciting, a purple is crazy, a Legendary is lucky.
const EPIC_BASE := 0.4
const RARE_BASE := 2.5
const UNCOMMON_BASE := 22.0

## Chances (%) of Uncommon, Rare and Epic with a rarity bonus. Bonuses multiply:
## +10 doubles Rare and Epic odds, +20 triples them.
static func rarity_chances(bonus: int) -> Array:
	var m := maxf(0.0, 1.0 + bonus / 10.0)
	return [minf(60.0, UNCOMMON_BASE * (1.0 + bonus / 20.0)), minf(30.0, RARE_BASE * m), minf(15.0, EPIC_BASE * m)]

static func roll_rarity(bonus: int, legendary_chance: float) -> int:
	if randf() * 100.0 < legendary_chance:
		return LEGENDARY
	var c := rarity_chances(bonus)
	var roll := randf() * 100.0
	if roll < float(c[2]):
		return 3
	if roll < float(c[2]) + float(c[1]):
		return 2
	if roll < float(c[2]) + float(c[1]) + float(c[0]):
		return 1
	return 0

## Legendaries get likelier the deeper you are: rare early, normal by floor 200,
## twice as common at floor 400 and below.
static func depth_legendary(floor_num: int) -> float:
	return clampf(floor_num / 200.0, 0.1, 2.0)

## The real chance (%) of each rarity Common..Legendary for one drop (for the Bestiary).
static func rarity_odds(bonus: int, legendary_chance: float) -> Array:
	var rest := 1.0 - legendary_chance / 100.0
	var c := rarity_chances(bonus)
	var com := 100.0 - float(c[0]) - float(c[1]) - float(c[2])
	return [com * rest, float(c[0]) * rest, float(c[1]) * rest, float(c[2]) * rest, legendary_chance]

static func base_bonus(slot: String, floor_num: int) -> float:
	var info: Dictionary = SLOT_INFO[slot]
	return float(info["base"]) + floor_num * float(info["per_floor"])

static func make_item(slot: String, rarity: int, floor_num: int, id: int) -> Dictionary:
	var info: Dictionary = SLOT_INFO[slot]
	var pick: Array = ItemPool.pick(slot, zone_index(floor_num))
	var item := {
		"id": id,
		"base_name": pick[0],
		"name": pick[0],
		"type": pick[1],
		"flavor": pick[2],
		"slot": slot,
		"stat": info["stat"],
		"rarity": rarity,
		"bonus": maxi(1, int(base_bonus(slot, floor_num) * float(RARITY_MULTS[rarity]))),
		"level": 0,
		"floor": floor_num,
		"effect": "",
		"effect_value": 0,
	}
	if rarity == LEGENDARY:
		add_legendary_effect(item)
	return item

## The name an item should have for its rarity. Hand-made items keep their name;
## old generic items ("Sword") get the rarity in front ("Rare Sword").
static func item_name(item: Dictionary) -> String:
	var base: String = item.get("base_name", item.get("name", "Item"))
	if int(item["rarity"]) < LEGENDARY and ItemPool.OLD_NAMES.has(base):
		return "%s %s" % [RARITY_NAMES[int(item["rarity"])], base]
	return base

## Which sprite an item uses (works for old saves too).
static func item_type(item: Dictionary) -> String:
	if item.has("type"):
		return item["type"]
	var base: String = item.get("base_name", "")
	if ItemPool.OLD_NAMES.has(base):
		return ItemPool.OLD_NAMES[base]
	if ItemPool.SPECIAL_TYPES.has(base):
		return ItemPool.SPECIAL_TYPES[base]
	if SET_TYPES.has(base):
		return SET_TYPES[base]
	return ItemPool.TYPES[item["slot"]][0]

## Gives a Legendary a random special effect and a title like "of Fury".
static func add_legendary_effect(item: Dictionary) -> Dictionary:
	var fx: Dictionary = LEGENDARY_EFFECTS.pick_random()
	item["effect"] = fx["effect"]
	item["effect_value"] = fx["value"]
	item["name"] = "%s %s" % [item["base_name"], fx["title"]]
	return item

static func make_unique(def: Dictionary, floor_num: int, id: int) -> Dictionary:
	var slot: String = def["slot"]
	var info: Dictionary = SLOT_INFO[slot]
	return {
		"id": id,
		"base_name": def["name"],
		"name": def["name"],
		"type": ItemPool.SPECIAL_TYPES.get(def["name"], ItemPool.TYPES[slot][0]),
		"art": "u_" + str(def["name"]).to_lower().replace("'", "").replace(" ", "_"),
		"flavor": def.get("flavor", ""),
		"slot": slot,
		"stat": info["stat"],
		"rarity": UNIQUE,
		"bonus": maxi(1, int(base_bonus(slot, floor_num) * float(RARITY_MULTS[UNIQUE]))),
		"level": 0,
		"floor": floor_num,
		"effect": def["effect"],
		"effect_value": def["value"],
	}

## A monster's Signature item (1 in 1,000 kills). Stronger than a unique.
static func make_signature(monster: String, floor_num: int, id: int) -> Dictionary:
	var def: Dictionary = Monsters.signature_def(monster)
	var slot: String = def["slot"]
	var info: Dictionary = SLOT_INFO[slot]
	return {
		"id": id,
		"base_name": def["name"],
		"name": def["name"],
		"type": def["type"],
		"art": "s_" + art_key(def["name"]),
		"sig_of": monster,
		"flavor": def.get("flavor", ""),
		"slot": slot,
		"stat": info["stat"],
		"rarity": SIGNATURE,
		"bonus": maxi(1, int(base_bonus(slot, floor_num) * float(RARITY_MULTS[SIGNATURE]))),
		"level": 0,
		"floor": floor_num,
		"effect": def["effect"],
		"effect_value": def["value"],
		"locked": true,
	}

## Total stat bonus of an item, including its upgrade level.
static func item_power(item: Dictionary) -> int:
	var b := int(item["bonus"])
	var lvl := int(item["level"])
	var p := b + maxi(1, int(ceil(b * 0.1))) * lvl
	var sl := soul_level(item)
	return int(p * (1.0 + SOUL_POWER * sl)) if sl > 0 else p

static func display_name(item: Dictionary) -> String:
	var lvl := int(item["level"])
	var n: String = item["name"]
	if lvl > 0:
		n = "%s +%d" % [n, lvl]
	var sl := soul_level(item)
	if sl >= SOUL_MAX:
		n += " (Awakened)"
	elif sl > 0:
		n += " (Soul %d)" % sl
	if UI.colorblind:
		n = "[%s] %s" % [RARITY_NAMES[clampi(int(item.get("rarity", 0)), 0, RARITY_NAMES.size() - 1)].substr(0, 3), n]
	return n

static func sell_value(item: Dictionary) -> int:
	var r := int(item["rarity"])
	var f := int(item["floor"])
	return maxi(1, int(int(SELL_MULTS[r]) * (2.0 + f * 0.5) * (1.0 + 0.2 * int(item["level"]))))

static func scrap_value(item: Dictionary) -> int:
	return int(SCRAP_VALUES[int(item["rarity"])]) + int(item["level"]) * 2

static func upgrade_cost(item: Dictionary) -> int:
	return 5 * (int(item["level"]) + 1) * (mini(int(item["rarity"]), LEGENDARY) + 1)

static func can_reroll(item: Dictionary) -> bool:
	return int(item["rarity"]) < LEGENDARY

static func reroll_cost(item: Dictionary) -> int:
	return 10 * (int(item["rarity"]) + 1)

static func reroll_chance(item: Dictionary) -> int:
	if not can_reroll(item):
		return 0
	return REROLL_CHANCES[int(item["rarity"])]

static func bag_cost(level: int) -> int:
	return int(round(BAG_BASE_COST * pow(BAG_COST_GROWTH, level)))

static func shop_price(item: Dictionary) -> int:
	return int(sell_value(item) * SHOP_PRICE_MULT * event_bonus("shop"))

static func zone_index(floor_num: int) -> int:
	var raw := floori((maxi(1, floor_num) - 1) / float(ZONE_FLOORS)) % ZONES.size()
	if raw < Realms.BASE_ZONES:
		return raw
	return Realms.zone_for_id(realm_in_slot(raw - Realms.BASE_ZONES))

## The realm you meet in realm slot 0..4 (floors 251-300 is slot 0): the ones
## you picked, then the rest in their normal order.
static func realm_in_slot(k: int) -> String:
	if k < realm_order.size():
		return realm_order[k]
	var rest: Array = []
	for id in Realms.IDS:
		if not id in realm_order:
			rest.append(id)
	var j := k - realm_order.size()
	return rest[clampi(j, 0, rest.size() - 1)] if not rest.is_empty() else Realms.IDS[k % Realms.COUNT]

## Realm slot 0..4 for a floor, or -1 on the roots.
static func realm_slot(floor_num: int) -> int:
	var raw := floori((maxi(1, floor_num) - 1) / float(ZONE_FLOORS)) % ZONES.size()
	return raw - Realms.BASE_ZONES if raw >= Realms.BASE_ZONES else -1

## The realm id a floor is in ("" on the roots).
static func realm_of(floor_num: int) -> String:
	return Realms.id_for_zone(zone_index(floor_num))

static func zone_for_floor(floor_num: int) -> Dictionary:
	return ZONES[zone_index(floor_num)]

## How many times the zones have looped (0 for floors 1-250, 1 for 251-500...)
static func zone_rank(floor_num: int) -> int:
	return floori((maxi(1, floor_num) - 1) / float(ZONE_FLOORS * ZONES.size()))

static func rank_prefix(floor_num: int) -> String:
	return RANK_PREFIXES[mini(zone_rank(floor_num), RANK_PREFIXES.size() - 1)]

## Floor inside its zone, 1..50
static func zone_floor(floor_num: int) -> int:
	return ((maxi(1, floor_num) - 1) % ZONE_FLOORS) + 1

## Sub-area 0..4 inside the zone
static func sub_index(floor_num: int) -> int:
	return floori((zone_floor(floor_num) - 1) / float(SUB_FLOORS))

static func sub_area(floor_num: int) -> Dictionary:
	return zone_for_floor(floor_num)["subs"][sub_index(floor_num)]

static func sub_name(floor_num: int) -> String:
	return sub_area(floor_num)["name"]

## First floor of the sub-area a floor is in (where you go back to after losing to a boss).
static func sub_start(floor_num: int) -> int:
	return floor_num - ((zone_floor(floor_num) - 1) % SUB_FLOORS)

## "mid", "zone" or "" for a normal floor.
static func boss_kind(floor_num: int) -> String:
	var zf := zone_floor(floor_num)
	if zf == ZONE_FLOORS:
		return "zone"
	if zf == MID_BOSS_FLOOR:
		return "mid"
	return ""

static func is_boss_floor(floor_num: int) -> bool:
	return boss_kind(floor_num) != ""

static func boss_for_floor(floor_num: int) -> Dictionary:
	var z := zone_for_floor(floor_num)
	return z["mid"] if boss_kind(floor_num) == "mid" else z["boss"]

static func boss_name(floor_num: int) -> String:
	var base: String = boss_for_floor(floor_num)["name"]
	var rank := zone_rank(floor_num)
	if rank > 0:
		return "%s (Rank %d)" % [base, rank + 1]
	return base

## Every unique a zone's bosses can drop.
static func zone_uniques(zone_i: int) -> Array:
	var z: Dictionary = ZONES[zone_i]
	var out: Array = z["boss"]["uniques"].duplicate()
	out.append_array(z["mid"]["uniques"])
	return out

## The creatures you can meet on a floor: the zone's 5 plus the sub-area's own.
## Returns [[def, weight], ...]
static func floor_monsters(floor_num: int) -> Array:
	var out: Array = []
	for e in zone_for_floor(floor_num)["enemies"]:
		out.append([e, BASE_MONSTER_WEIGHT])
	out.append([sub_area(floor_num)["monster"], LOCAL_MONSTER_WEIGHT])
	return out

static func pick_monster(floor_num: int) -> Dictionary:
	var list := floor_monsters(floor_num)
	var total := 0.0
	for e in list:
		total += float(e[1])
	var roll := randf() * total
	for e in list:
		roll -= float(e[1])
		if roll < 0.0:
			return e[0]
	return list[0][0]

## Which zone and sub-area a monster lives in: {"zone": i, "sub": i or -1}
static func monster_home(monster: String) -> Dictionary:
	for zi in ZONES.size():
		var z: Dictionary = ZONES[zi]
		for e in z["enemies"]:
			if e["name"] == monster:
				return {"zone": zi, "sub": -1}
		for si in z["subs"].size():
			if z["subs"][si]["monster"]["name"] == monster:
				return {"zone": zi, "sub": si}
		if z["mid"]["name"] == monster:
			return {"zone": zi, "sub": 2, "boss": "mid"}
		if z["boss"]["name"] == monster:
			return {"zone": zi, "sub": 4, "boss": "zone"}
	return {}

## Sprite name for a creature (art/enemies/<key>.png).
static func art_key(monster: String) -> String:
	var out := ""
	for ch in monster.to_lower():
		out += ch if (ch >= "a" and ch <= "z") else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	return out.trim_suffix("_").trim_prefix("_")

static func effect_text(effect: String, value: int) -> String:
	match effect:
		"regen":
			return "Regenerate %d%% max HP every turn" % value
		"lifesteal":
			return "Heal for %d%% of damage dealt" % value
		"double_strike":
			return "%d%% chance to attack twice" % value
		"gold_find":
			return "+%d%% gold from enemies" % value
		"thorns":
			return "Reflect %d%% of damage taken" % value
		"crit":
			return "%d%% chance to deal double damage" % value
		"dodge":
			return "%d%% chance to dodge attacks" % value
		"execute":
			return "+%d%% damage to monsters under 30%% HP" % value
		"boss":
			return "+%d%% damage to bosses" % value
		"rage":
			return "Up to +%d%% damage the more you're hurt" % value
		"stone_find":
			return "+%d%% ability stones" % value
		"xp":
			return "+%d%% XP" % value
		"cdr":
			return "Skill cooldowns %d turn shorter" % value
		"potion":
			return "Potions heal %d%% more" % value
	return ""

static func xp_to_next(level: int) -> int:
	# The first levels come quickly so the first evolution (level 15) arrives
	# in the first session; from level 25 on it's the normal curve.
	var early := clampf(0.35 + 0.65 * (level - 1) / 24.0, 0.35, 1.0)
	return maxi(10, int(30 * pow(level, 1.8) * early))

static func xp_for_kill(floor_num: int, boss: bool) -> int:
	return (4 + floor_num * 2) * (8 if boss else 1)

static func make_set_item(set_name: String, slot: String, floor_num: int, id: int) -> Dictionary:
	var info: Dictionary = SLOT_INFO[slot]
	var piece: String = SETS[set_name]["pieces"][slot]
	return {
		"id": id,
		"base_name": piece,
		"name": piece,
		"type": SET_TYPES.get(piece, ItemPool.TYPES[slot][0]),
		"slot": slot,
		"stat": info["stat"],
		"rarity": SET_RARITY,
		"bonus": maxi(1, int(base_bonus(slot, floor_num) * float(RARITY_MULTS[SET_RARITY]))),
		"level": 0,
		"floor": floor_num,
		"effect": "",
		"effect_value": 0,
		"set": set_name,
	}

## Materials needed to craft the next bag size.
static func bag_craft_materials(bag_level: int) -> int:
	return BAG_CRAFT_MATERIALS + floori(bag_level / 4.0)

static func bag_craft_scrap(bag_level: int) -> int:
	return BAG_CRAFT_SCRAP + bag_level * 10


