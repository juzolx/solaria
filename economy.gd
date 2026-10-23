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
const CHEST_SCRAP := [1, 2]             # ...so 4-8 scrap

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
	g.tip("dust", "Dust! Use it to craft skills (Character > Skills), Set items (Town > Smith) and the last upgrades of your best gear.")

## Gives scrap and says so (plain chests).
static func give_scrap(g: GameState, n: int) -> void:
	if n <= 0:
		return
	g.scrap += n
	g.say("[color=#9fb0cc]+%d scrap[/color]" % n)

## A plain chest's scrap (what 1-2 materials used to be).
static func chest_scrap() -> int:
	return randi_range(CHEST_SCRAP[0], CHEST_SCRAP[1]) * MAT_TO_SCRAP

## Dust for one Set piece: deeper zones' sets cost more.
static func set_piece_dust(set_id: String) -> int:
	return SET_PIECE_DUST + SET_PIECE_DUST_STEP * int(GameData.SETS[set_id]["zone"])

## True once you have reached the zone a set belongs to (you have to have been there).
static func set_zone_reached(g: GameState, set_id: String) -> bool:
	var want := int(GameData.SETS[set_id]["zone"])
	var zones := mini(GameData.ZONES.size(), floori((maxi(1, g.best_floor) - 1) / float(GameData.ZONE_FLOORS)) + 1)
	for k in zones:
		if GameData.zone_index(k * GameData.ZONE_FLOORS + 1) == want:
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
