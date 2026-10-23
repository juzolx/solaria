class_name LootRules
extends RefCounted
## 2.1: the one loot filter. Every rule for new drops lives here, and the one
## Loot filter screen (loot_filter.gd) edits it. Merged from: auto-salvage by
## rarity (GameState.auto_salvage), the slot filter, the "weaker than worn" rule
## and the Gear Score rule. Stored in GameState.loot_filter (saved with the hero);
## the rarity threshold stays in GameState.auto_salvage.
##
## Never touched, whatever the rules say: locked items, Legendary and better,
## Unique / Set / Signature rarities, upgrades (Juzo: always, not a setting), and
## (on by default) set pieces of any rarity.

const VERSION := 2
const RARITY_NAMES := ["Off", "Commons", "Uncommon and below", "Rare and below", "Epic and below"]
const ACTIONS := ["salvage", "sell"]

## Tests only: let rules match upgrades too, to test one rule on its own.
static var test_ignore_upgrades := false

static func defaults() -> Dictionary:
	return {
		"v": VERSION,
		"on": true,           # the master switch
		"slots": {},          # slot -> true: Common to Rare drops for that slot go
		"weaker": false,      # Common to Rare drops weaker than what you wear in that slot go
		"below_gs": false,    # Common to Epic drops below your average Gear Score go
		"keep_sets": true,    # set pieces are always kept
		"action": "salvage",  # what happens to a filtered drop: "salvage" (scrap) or "sell" (gold)
	}

## The rules, upgraded in place from older saves (0.13 and before) the first time.
static func rules(g: GameState) -> Dictionary:
	var lf: Dictionary = g.loot_filter
	if int(lf.get("v", 0)) < VERSION:
		var old := lf.duplicate(true)
		lf.clear()
		lf.merge(defaults())
		lf["slots"] = old.get("slots", {})
		lf["weaker"] = bool(old.get("weaker", false))
		lf["below_gs"] = bool(old.get("below_gs", false))
	if lf.size() < 7:  # a key missing (a save from a test build): fill it in
		var d := defaults()
		for k in d:
			if not lf.has(k):
				lf[k] = d[k]
	return lf

static func get_rule(g: GameState, key: String) -> Variant:
	return rules(g).get(key)

static func set_rule(g: GameState, key: String, value: Variant) -> void:
	rules(g)[key] = value
	g.save_game()

static func toggle(g: GameState, key: String) -> void:
	set_rule(g, key, not bool(get_rule(g, key)))

static func cycle_rarity(g: GameState) -> void:
	g.auto_salvage += 1
	if g.auto_salvage > GameData.LEGENDARY - 1:
		g.auto_salvage = -1
	g.save_game()

static func toggle_slot(g: GameState, slot: String) -> void:
	var slots: Dictionary = rules(g)["slots"]
	slots[slot] = not bool(slots.get(slot, false))
	g.save_game()

static func cycle_action(g: GameState) -> void:
	set_rule(g, "action", "sell" if String(get_rule(g, "action")) == "salvage" else "salvage")

## True if nothing (no rule, no setting) may ever filter this item.
static func protected(g: GameState, item: Dictionary) -> bool:
	if item.get("locked", false) or GameState.is_bound(item):
		return true
	if int(item["rarity"]) >= GameData.LEGENDARY:
		return true  # Legendary, Unique, Set, Signature, Mythic
	if String(item.get("set", "")) != "" and bool(get_rule(g, "keep_sets")):
		return true
	return false

## What the filter does with a new drop: "keep", "salvage" or "sell".
static func decide(g: GameState, item: Dictionary) -> String:
	var lf := rules(g)
	if not bool(lf["on"]) or protected(g, item):
		return "keep"
	if g.autoplay and not AutoDive.filter_in_auto(g):
		return "keep"
	if not test_ignore_upgrades and g.is_upgrade(item):
		return "keep"  # Juzo: upgrades are always kept
	if not _matches(g, lf, item):
		return "keep"
	return String(lf["action"]) if String(lf["action"]) in ACTIONS else "salvage"

static func _matches(g: GameState, lf: Dictionary, item: Dictionary) -> bool:
	var r := int(item["rarity"])
	if r <= g.auto_salvage:
		return true
	if bool(lf["below_gs"]) and not g.equipped.is_empty() and GameData.gear_score(item) < g.average_gear_score():
		return true
	if r <= 2:
		if bool((lf["slots"] as Dictionary).get(item["slot"], false)):
			return true
		var slot: String = item["slot"]
		if bool(lf["weaker"]) and g.equipped.has(slot) and GameData.item_power(item) <= GameData.item_power(g.equipped[slot]) and not g.is_upgrade(item):
			return true
	return false

## Carries out a filter decision on a new drop. Returns the log line.
static func carry_out(g: GameState, item: Dictionary, action: String) -> String:
	if action == "sell":
		var p := g.sell_price(item)
		g.gold += p  # carried gold, like any gold found down there
		ClassTree.count(g, "sold")
		return "Auto-sold %s (+%d gold)" % [g._tag(item), p]
	var s := int(GameData.scrap_value(item) * g.scrap_mult())
	g.scrap += s
	ClassTree.count(g, "scrapped")
	g._salvage_dust(item)
	return "Auto-salvaged %s (+%d scrap)" % [g._tag(item), s]

## One line for buttons: what the filter does right now.
static func summary(g: GameState) -> String:
	var lf := rules(g)
	if not bool(lf["on"]):
		return "off"
	var parts: Array = []
	if g.auto_salvage >= 0:
		parts.append(String(RARITY_NAMES[g.auto_salvage + 1]).to_lower())
	var n := 0
	for s in lf["slots"]:
		if bool(lf["slots"][s]):
			n += 1
	if n > 0:
		parts.append("%d slot%s" % [n, "" if n == 1 else "s"])
	if bool(lf["weaker"]):
		parts.append("weaker")
	if bool(lf["below_gs"]):
		parts.append("below GS %d" % g.average_gear_score())
	if parts.is_empty():
		return "keeps everything"
	return "%s %s" % ["sells" if String(lf["action"]) == "sell" else "salvages", ", ".join(parts)]
