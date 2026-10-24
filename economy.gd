class_name Economy
extends RefCounted
## Solaria 2.1 (Juzo, decision D3 a): the game has exactly three currencies.
##   gold   from monsters, selling, rewards. Spent in town (shop, smith, rest, looks, wheel).
##   scrap  from salvaging and plain finds. Upgrades, rerolls, potions, mystery gear, bags.
##   dust   the magic one: maxed ability stones, bosses, rare monsters, Epic+ salvage,
##          vaults and deeds. Crafts skills, Set items, and the last upgrades and rerolls.
## The ten zone materials of 2.0 are gone: their sources now give dust (magic and
## rare) or scrap (plain chests), and their costs are paid in dust or scrap.
## Every number lives here; claude/economy.md lists them all by floor band.

const CURRENCIES := ["gold", "scrap", "dust"]

# ---- Sources (what used to give zone materials) ----
const BOSS_DUST := [5, 8]               # per boss kill (was 5-8 of the zone's material)
const CHAMPION_DUST := [2, 3]           # a milestone Champion's chest
const VAULT_DUST_PER_FLOOR := 3         # a rift vault: 3 per rift floor
const SALVAGE_DUST := {3: 1, 4: 2}      # salvaging Epic / Legendary gear
const BOX_DUST := 4                     # Mystery Box, the dust prize
const RAID_DUST_PER_ZONE := 2           # weekly raid: 2 per zone you have reached
const MAT_TO_SCRAP := 4                 # plain chests (treasure goblin, horde): 1 old material = 4 scrap
const CHEST_SCRAP := [2, 3]             # ...so 8-12 scrap (R5: was 4-8; scrap was the starved currency)
# ---- Scrap for upgrades (R6 balance pass: worn gear sat at +0-1, scrap was always gone) ----
const SALVAGE_FLOOR_STEP := 40          # salvage scrap grows with the item's floor: x(1 + floor/40), x3.5 on floor 100
const SALVAGE_UPGRADE_REFUND := 0.5     # salvaging gives back half the scrap its upgrades cost (was +2 per level)
const ELITE_DUST := 1                   # an elite room's monster pays a plain chest of scrap (x the floor step) and 1 dust

# ---- Sinks ----
const SET_PIECE_DUST := 10              # a Set piece of the first zone's set (was 10 Grendel's Claws)
const SET_PIECE_DUST_STEP := 5          # each zone deeper costs 5 more (rare sets cost more)
const BAG_CRAFT_MATS := 5               # 2.0's material part of a crafted bag, now paid in scrap
const BAG_CRAFT_SCRAP := 30
const RESTOCK_BASE := 30                # shop restock: 30 gold + 10 per best floor
const RESTOCK_PER_FLOOR := 10
const REROLL_DUST := [0, 0, 3, 10]      # extra dust per reroll try, by rarity (Rare 3, Epic 10)
const UPGRADE_DUST_FROM := 6            # upgrades to +6 and past also cost dust...
const UPGRADE_DUST_STEP := 2            # ...2 per level past +5 (+6: 2, +7: 4 ... +10: 10)

## Gives dust and says so (bosses, rare monsters, vaults...).
static func give_dust(g: GameState, n: int) -> void:
	if n <= 0:
		return
	g.dust += n
	g.say("[color=#c4b5fd]+%d dust[/color]" % n)
	g.tip("dust", "Dust! Use it to craft skills (Character > Skills), Set items (Town > Blacksmith) and the last upgrades of your best gear.")

## Dust from salvaging this item: Epic and Legendary finds only. Anything
## bought with gold (marked "bought") salvages for scrap only.
static func salvage_dust(item: Dictionary) -> int:
	if bool(item.get("bought", false)):
		return 0
	return int(SALVAGE_DUST.get(int(item["rarity"]), 0))

## Gives scrap and says so (plain chests).
static func give_scrap(g: GameState, n: int) -> void:
	if n <= 0:
		return
	g.scrap += n
	g.say("[color=#9fb0cc]+%d scrap[/color]" % n)

## A plain chest's scrap (what 1-2 materials used to be).
static func chest_scrap() -> int:
	return randi_range(CHEST_SCRAP[0], CHEST_SCRAP[1]) * MAT_TO_SCRAP

## How much deeper scrap is worth: x1 on floor 0, x3.5 on floor 100 (salvage and elite chests).
static func scrap_floor_mult(floor_num: int) -> float:
	return 1.0 + maxi(0, floor_num) / float(SALVAGE_FLOOR_STEP)

## Scrap from salvaging an item: its rarity's base, grown with its floor, plus half the
## scrap its upgrades cost (so upgrading worn gear isn't wasted when a better drop comes).
static func salvage_scrap(item: Dictionary) -> int:
	var base := float(GameData.SCRAP_VALUES[int(item["rarity"])]) * scrap_floor_mult(int(item.get("floor", 1)))
	return int(base) + int(upgrade_scrap_spent(item) * SALVAGE_UPGRADE_REFUND)

## Scrap all of an item's upgrades cost at the plain smith price (5 x L x rarity step each).
static func upgrade_scrap_spent(item: Dictionary) -> int:
	var lvl := int(item["level"])
	return int(2.5 * lvl * (lvl + 1)) * (mini(int(item["rarity"]), GameData.LEGENDARY) + 1)

## An elite room's monster fell: a plain chest of scrap (worth more deeper) and a little dust.
static func elite_reward(g: GameState) -> void:
	give_scrap(g, int(chest_scrap() * scrap_floor_mult(g.floor_num)))
	give_dust(g, ELITE_DUST)

## Dust for one Set piece: deeper zones' sets cost more.
static func set_piece_dust(set_id: String) -> int:
	return SET_PIECE_DUST + SET_PIECE_DUST_STEP * int(GameData.SETS[set_id]["zone"])

## True once you have reached the zone a set belongs to (you have to have been there).
static func set_zone_reached(g: GameState, set_id: String) -> bool:
	var want := int(GameData.SETS[set_id]["zone"])
	var zones := mini(GameData.ZONES.size(), floori((maxi(1, g.best_floor) - 1) / float(GameData.ZONE_FLOORS)) + 1)
	for k in zones:
		if k < Realms.BASE_ZONES:
			if k == want:
				return true
		elif k - Realms.BASE_ZONES < g.realm_order.size():
			# a realm counts only once this hero has chosen (and so entered) it
			if Realms.zone_for_id(String(g.realm_order[k - Realms.BASE_ZONES])) == want:
				return true
	return false

## Scrap for the next crafted bag (the old materials part is folded in).
static func bag_craft_scrap(bag_level: int) -> int:
	return BAG_CRAFT_SCRAP + bag_level * 10 + MAT_TO_SCRAP * (BAG_CRAFT_MATS + floori(bag_level / 4.0))

## Gold for a fresh shelf in the shop (before Charisma and town events).
static func restock_gold(best_floor: int) -> int:
	return RESTOCK_BASE + maxi(1, best_floor) * RESTOCK_PER_FLOOR

## Dust a reroll try costs on top of its scrap.
static func reroll_dust(item: Dictionary) -> int:
	var r := int(item["rarity"])
	return int(REROLL_DUST[r]) if r >= 0 and r < REROLL_DUST.size() else 0

## Dust the next upgrade costs on top of its scrap.
static func upgrade_dust(item: Dictionary) -> int:
	var next := int(item["level"]) + 1
	return maxi(0, next - UPGRADE_DUST_FROM + 1) * UPGRADE_DUST_STEP

## A cost line like "12 scrap" or "12 scrap + 4 dust".
static func cost_text(scrap: int, dust: int) -> String:
	return "%d scrap" % scrap + (" + %d dust" % dust if dust > 0 else "")

## Why the next upgrade can't be paid ("" = it can).
static func upgrade_short(g: GameState, item: Dictionary) -> String:
	var cost := GameData.upgrade_cost(item)
	if g.scrap < cost:
		return "Not enough scrap (need %d)." % cost
	if g.dust < upgrade_dust(item):
		return "Not enough dust (need %d)." % upgrade_dust(item)
	return ""

## Why a reroll try can't be paid ("" = it can).
static func reroll_short(g: GameState, item: Dictionary) -> String:
	var cost := GameData.reroll_cost(item)
	if g.scrap < cost:
		return "Not enough scrap (need %d)." % cost
	if g.dust < reroll_dust(item):
		return "Not enough dust (need %d)." % reroll_dust(item)
	return ""

# ---- Town buildings (2.1 G1-G3): levels 1-3, per town (buildings.gd) ----
const BUILDING_MAX := 3
## What it costs to reach a level (index = the level you're buying). Level 1 is free, except for
## buildings that start as an empty lot (Church, Trophy Cabin): building them costs what a level 2 does.
const BUILDING_COST := [{}, {"gold": 1500, "scrap": 60, "dust": 0}, {"gold": 1500, "scrap": 60, "dust": 0}, {"gold": 8000, "scrap": 200, "dust": 40}]
const BUILDING_L3_FLOOR := 100          # level 3 needs a hero of this town to have reached this floor
const INN_RECRUIT_CAP := 5              # only a town's first 5 recruits get the Inn's send-off
# What each level gives (index = level; index 0 unused). Small, steady steps.
const INN_REST_MULT := [1.0, 1.0, 0.5, 0.0]          # rest price
const INN_RECRUIT := [{}, {}, {}, {"potions": 3, "gold": 300}]  # what new recruits bring
const SMITH_UPGRADE_MULT := [1.0, 1.0, 0.95, 0.9]    # scrap for gear upgrades
const SHOP_PRICE_MULT := [1.0, 1.0, 0.95, 0.9]       # gear on the shop shelf
const TAVERN_FEE_MULT := [1.0, 1.0, 0.9, 0.8]        # the wheel's gold fee
const VAULT_EXTRA := [0, 0, 5, 10]                   # extra Vault spaces
const BOUNTY_TAKEN := [3, 3, 4, 5]                   # contracts you can carry
const GUILD_GOLD_MULT := [1.0, 1.0, 1.1, 1.2]        # gold in deed rewards
const CLINIC_HEAL_MULT := [1.0, 1.0, 0.75, 0.5]      # gold to patch up a pet
const CLINIC_HEAL_FLOORS := [10, 10, 8, 6]           # floors a hurt pet rests
# ---- The Church (G2): cursed loot ----
const CURSE_CHANCE := 2.0               # % a Rare, Epic or Legendary monster drop comes Cursed
const CURSE_MIN_RARITY := 2             # Rare and up (never Uniques, Sets, Signatures, Mythics)
const CURSE_MAX_RARITY := 4
const CURSE_POWER := 1.2                # a Cursed item's stat is 20% higher
const CLEANSE_CHANCE := [0, 70, 80, 90]  # % a cleanse works, by Church level
const CLEANSE_TRY_STEP := 15            # each failed try adds this much to that item's next try
const CLEANSE_GOLD_BASE := 60           # gold: (60 + 6 x item floor) x the Church's price step
const CLEANSE_GOLD_PER_FLOOR := 6
const CLEANSE_DUST := 3                 # and a little dust
const CHURCH_PRICE_MULT := [1.0, 1.0, 0.85, 0.7]
const BLESS_DUST := [0, 15, 12, 10]     # a blessing: dust...
const BLESS_GOLD_BASE := 100            # ...plus (100 + 10 x item floor) gold
const BLESS_GOLD_PER_FLOOR := 10
const BLESS_POWER := 1.03               # a blessed item you wear: +3% to its stat
# ---- The Trophy Cabin (G3): cosmetic only ----
const CABIN_SLOTS := [0, 6, 12, 20]     # trophies on display, by level
