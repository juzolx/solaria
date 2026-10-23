class_name Church
extends RefCounted
## 2.1 G2: cursed loot and the Church. Now and then a Rare, Epic or Legendary
## monster drop comes Cursed: its stat is higher (Economy.CURSE_POWER) and it
## carries a real downside you can see plus a hidden upside (shown as "???").
## Both work while you wear it. The Church cleanses it for gold and a little dust:
## the downside goes, the upside is revealed and stays. A cleanse can fail (the
## Church's level sets the odds); every failed try makes the next one likelier.
## The Church also blesses any item once, for dust: +3% to its stat while worn.
## Item fields: "curse" {down, up, known, tries} (down "" = cleansed), "blessed".

const DOWNS := {
	"frail": {"text": "-12% max HP", "bonus": {"hp": 0.88}, "key": "hp"},
	"brittle": {"text": "-12% Defense", "bonus": {"def": 0.88}, "key": "def"},
	"dull": {"text": "-8% Attack", "bonus": {"atk": 0.92}, "key": "atk"},
}
const UPS := {
	"wrath": {"text": "+8% Attack", "bonus": {"atk": 1.08}, "key": "atk"},
	"ward": {"text": "+10% Defense", "bonus": {"def": 1.1}, "key": "def"},
	"vigor": {"text": "+10% max HP", "bonus": {"hp": 1.1}, "key": "hp"},
	"keen": {"text": "+5% critical hit chance", "bonus": {"crit": 5.0}, "key": "crit"},
	"leech": {"text": "+4% life steal", "bonus": {"lifesteal": 4.0}, "key": "lifesteal"},
	"greed": {"text": "+15% gold found", "bonus": {"gold_find": 15.0}, "key": "gold_find"},
}
const COLOR := "#a855f7"
## Which bonus key a slot's stat is (for blessings).
const STAT_KEYS := {"Attack": "atk", "Defense": "def", "HP": "hp"}

static func is_cursed(item: Dictionary) -> bool:
	return item.has("curse") and String((item["curse"] as Dictionary).get("down", "")) != ""

static func was_cursed(item: Dictionary) -> bool:
	return item.has("curse")

## A fresh monster drop: sometimes it comes Cursed. Returns the item (for chaining).
static func maybe_curse(g: GameState, item: Dictionary, chance := -1.0) -> Dictionary:
	var r := int(item.get("rarity", 0))
	if r < Economy.CURSE_MIN_RARITY or r > Economy.CURSE_MAX_RARITY or item.has("curse"):
		return item
	if randf() * 100.0 >= (Economy.CURSE_CHANCE if chance < 0.0 else chance):
		return item
	curse(item)
	g.tip("cursed", "A Cursed item! It's stronger than it looks and hides a secret power, but it has a downside too. The Church in town can lift the curse and keep the power.")
	return item

## Makes an item Cursed (a downside and a hidden upside on a different stat).
static func curse(item: Dictionary) -> void:
	var down: String = DOWNS.keys().pick_random()
	var ups: Array = UPS.keys().filter(func(u): return String(UPS[u]["key"]) != String(DOWNS[down]["key"]))
	item["curse"] = {"down": down, "up": ups.pick_random(), "known": false, "tries": 0}
	item["bonus"] = maxi(1, int(round(int(item["bonus"]) * Economy.CURSE_POWER)))

## Bonus dicts for game_state._bonus_sources: curses, their upsides, blessings.
static func bonus_sources(g: GameState) -> Array:
	var out: Array = []
	for slot in g.equipped:
		var it: Dictionary = g.equipped[slot]
		if it.has("curse"):
			var c: Dictionary = it["curse"]
			if is_cursed(it) and DOWNS.has(String(c["down"])):
				out.append(DOWNS[String(c["down"])]["bonus"])
			if UPS.has(String(c.get("up", ""))):
				out.append(UPS[String(c["up"])]["bonus"])
		if it.get("blessed", false) and STAT_KEYS.has(String(it.get("stat", ""))):
			out.append({STAT_KEYS[String(it["stat"])]: Economy.BLESS_POWER})
	return out

## "Cursed " in front of the name while the curse holds (game_data.display_name).
static func name_tag(item: Dictionary) -> String:
	if is_cursed(item):
		return "Cursed "
	if item.get("blessed", false):
		return "Blessed "
	return ""

## Lines for ItemText.describe.
static func describe(item: Dictionary) -> String:
	var t := ""
	if item.has("curse"):
		var c: Dictionary = item["curse"]
		var up: String = UPS[String(c["up"])]["text"] if UPS.has(String(c.get("up", ""))) else "?"
		if is_cursed(item):
			t += "\n[color=%s][b]CURSED[/b][/color] [color=#f87171]Downside: %s[/color]" % [COLOR, String(DOWNS.get(String(c["down"]), {}).get("text", "?"))]
			t += "\n[color=%s]Hidden power: %s[/color]" % [COLOR, up if bool(c.get("known", false)) else "??? (the Church can reveal it)"]
		else:
			t += "\n[color=%s]Cleansed: %s[/color]" % [COLOR, up]
	if item.get("blessed", false):
		t += "\n[color=#fde68a]Blessed: +%d%% %s while worn[/color]" % [int(round((Economy.BLESS_POWER - 1.0) * 100.0)), String(item.get("stat", ""))]
	return t

# =====================================================================
# Cleansing and blessing
# =====================================================================

## % this cleanse works (the Church's level, plus every failed try on this item).
static func cleanse_chance(item: Dictionary) -> int:
	var tries := int((item.get("curse", {}) as Dictionary).get("tries", 0))
	return mini(100, int(Buildings.pick("church", Economy.CLEANSE_CHANCE)) + Economy.CLEANSE_TRY_STEP * tries)

static func cleanse_gold(item: Dictionary) -> int:
	var base := Economy.CLEANSE_GOLD_BASE + Economy.CLEANSE_GOLD_PER_FLOOR * int(item.get("floor", 1))
	return maxi(1, int(round(base * Buildings.mult("church", Economy.CHURCH_PRICE_MULT))))

static func cleanse_dust(_item: Dictionary) -> int:
	return Economy.CLEANSE_DUST

static func bless_gold(item: Dictionary) -> int:
	return Economy.BLESS_GOLD_BASE + Economy.BLESS_GOLD_PER_FLOOR * int(item.get("floor", 1))

static func bless_dust() -> int:
	return int(Buildings.pick("church", Economy.BLESS_DUST))

static func can_bless(item: Dictionary) -> bool:
	return not item.is_empty() and not item.get("blessed", false) and not is_cursed(item) and STAT_KEYS.has(String(item.get("stat", "")))

## Why a cleanse can't be paid ("" = it can).
static func cleanse_short(g: GameState, item: Dictionary) -> String:
	if not is_cursed(item):
		return "That item isn't cursed."
	if g.gold < cleanse_gold(item):
		return "Not enough gold (need %d)." % cleanse_gold(item)
	if g.dust < cleanse_dust(item):
		return "Not enough dust (need %d)." % cleanse_dust(item)
	return ""

static func bless_short(g: GameState, item: Dictionary) -> String:
	if not can_bless(item):
		return "That item can't be blessed." if not is_cursed(item) else "Lift the curse first."
	if g.gold < bless_gold(item):
		return "Not enough gold (need %d)." % bless_gold(item)
	if g.dust < bless_dust():
		return "Not enough dust (need %d)." % bless_dust()
	return ""

## Tries to lift a curse. Paid either way; the hidden power is revealed either way.
## roll: 0-99 for tests (-1 = random). Returns true if the curse is gone.
static func cleanse(g: GameState, item: Dictionary, roll := -1) -> bool:
	var why := cleanse_short(g, item)
	if why != "":
		g.say(why)
		return false
	g.gold -= cleanse_gold(item)
	g.dust -= cleanse_dust(item)
	var c: Dictionary = item["curse"]
	var chance := cleanse_chance(item)
	c["known"] = true
	var up := String(UPS.get(String(c["up"]), {}).get("text", ""))
	var r := randi() % 100 if roll < 0 else roll
	if r < chance:
		c["down"] = ""
		g.say("[color=%s]The curse lifts from %s.[/color] Its hidden power stays: %s." % [COLOR, String(item.get("name", "the item")), up])
		g.codex.add("cleansed")
		ok_save(g)
		return true
	c["tries"] = int(c.get("tries", 0)) + 1
	g.say("[color=%s]The curse holds on %s.[/color] The priest saw its hidden power (%s). Next time: %d%%." % [COLOR, String(item.get("name", "the item")), up, cleanse_chance(item)])
	ok_save(g)
	return false

static func bless(g: GameState, item: Dictionary) -> bool:
	var why := bless_short(g, item)
	if why != "":
		g.say(why)
		return false
	g.gold -= bless_gold(item)
	g.dust -= bless_dust()
	item["blessed"] = true
	g.say("[color=#fde68a]%s is blessed.[/color] +%d%% %s while you wear it." % [String(item.get("name", "The item")), int(round((Economy.BLESS_POWER - 1.0) * 100.0)), String(item.get("stat", ""))])
	ok_save(g)
	return true

static func ok_save(g: GameState) -> void:
	g.bag_version += 1
	g.save_game()

## Items the Church can work on: everything you wear and carry (worn first).
static func items_here(g: GameState) -> Array:
	var out: Array = []
	for slot in GameData.SLOT_ORDER:
		if g.equipped.has(slot):
			out.append(g.equipped[slot])
	out.append_array(g.bag)
	return out
