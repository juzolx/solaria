class_name Buildings
extends RefCounted
## 2.1 G1 (Juzo: "I want the town to be a place where there's building"): every town
## building has levels 1-3. You pay gold and scrap (and dust for level 3) and the
## building does its job a little better. Each town keeps its own levels
## (Profile.buildings, one of its TOWN_KEYS); `levels` points at the town you're in,
## so the small static helpers (prices, costs) can read it.
## Numbers live in economy.gd. Placeholder map art: ART (one table, swap for the new set).

## The town you're in: building id -> level (missing = 1). Profile binds this.
static var levels: Dictionary = {}

## id -> name, Town page, and what each level gives (index = level).
const LIST := {
	"inn": {"name": "Inn", "page": 3, "levels": ["",
		"A room costs 4 gold per hero level.",
		"Rooms cost half.",
		"Rooms are free, and new recruits bring 3 potions and 300 gold."]},
	"smith": {"name": "Blacksmith", "page": 1, "levels": ["",
		"Gear upgrades cost full scrap.",
		"Gear upgrades cost 5% less scrap.",
		"Gear upgrades cost 10% less scrap."]},
	"shop": {"name": "Shop", "page": 0, "levels": ["",
		"Gear on the shelf at full price.",
		"Gear on the shelf costs 5% less.",
		"Gear on the shelf costs 10% less."]},
	"tavern": {"name": "Tavern", "page": 2, "levels": ["",
		"The wheel's fee is full price.",
		"The wheel's fee is 10% lower.",
		"The wheel's fee is 20% lower."]},
	"stash": {"name": "Vault", "page": 4, "levels": ["",
		"The Vault as it is.",
		"5 more Vault spaces.",
		"10 more Vault spaces."]},
	"bounty": {"name": "Bounty Board", "page": 5, "levels": ["",
		"Carry 3 contracts at once.",
		"Carry 4 contracts at once.",
		"Carry 5 contracts at once."]},
	"guild": {"name": "Guild Hall", "page": 6, "levels": ["",
		"Deed rewards as written.",
		"Deed rewards pay 10% more gold.",
		"Deed rewards pay 20% more gold."]},
	"clinic": {"name": "Clinic", "page": 8, "levels": ["",
		"Hurt pets rest 10 floors.",
		"Hurt pets rest 8 floors and healing costs 25% less.",
		"Hurt pets rest 6 floors and healing costs half."]},
	"church": {"name": "Church", "page": 9, "levels": ["",
		"Cleansing works 70% of the time.",
		"Cleansing works 80% of the time and costs 15% less; blessings cost less dust.",
		"Cleansing works 90% of the time and costs 30% less; blessings cost less dust."]},
	"cabin": {"name": "Trophy Cabin", "page": 10, "levels": ["",
		"6 trophies on display.",
		"12 trophies on display.",
		"20 trophies on display."]},
}

## Placeholder art for buildings the town picture doesn't have yet: a copy of an
## existing building (its rect on the town picture), scaled into the new spot's
## rect and recoloured. The new town art set replaces this table.
const ART := {
	"church": {"from": [64, 160, 208, 201], "tint": Color(1.05, 1.02, 1.12)},  # the Guild Hall, washed pale
	"cabin": {"from": [64, 384, 160, 160], "tint": Color(0.86, 0.66, 0.46)},   # the Shop, in warm wood
}

## The Town page each building opens, to find which building a page belongs to.
static func id_for_page(page: int) -> String:
	for id in LIST:
		if int(LIST[id]["page"]) == page:
			return id
	return ""

static func level(id: String) -> int:
	return clampi(int(levels.get(id, 1)), 1, Economy.BUILDING_MAX)

## A number from one of Economy's per-level tables, for this town.
static func pick(id: String, table: Array) -> Variant:
	return table[clampi(level(id), 0, table.size() - 1)]

static func mult(id: String, table: Array) -> float:
	return float(pick(id, table))

static func name_of(id: String) -> String:
	return String(LIST.get(id, {}).get("name", id))

static func benefit(id: String, lvl: int) -> String:
	var l: Array = LIST.get(id, {}).get("levels", [])
	return String(l[lvl]) if lvl >= 0 and lvl < l.size() else ""

static func next_cost(id: String) -> Dictionary:
	var n := level(id) + 1
	return Economy.BUILDING_COST[n] if n <= Economy.BUILDING_MAX else {}

static func cost_text(c: Dictionary) -> String:
	var parts: Array = ["%s gold" % UI.short(int(c.get("gold", 0)))]
	if int(c.get("scrap", 0)) > 0:
		parts.append("%d scrap" % int(c["scrap"]))
	if int(c.get("dust", 0)) > 0:
		parts.append("%d dust" % int(c["dust"]))
	return " + ".join(parts)

## The deepest floor any hero of this town has reached.
static func deepest(g: GameState, p: Profile) -> int:
	return maxi(g.best_floor, p.max_floor if p != null else 0)

## Why the next level can't be bought ("" = it can).
static func blocked(g: GameState, p: Profile, id: String) -> String:
	if not LIST.has(id):
		return "No such building."
	if level(id) >= Economy.BUILDING_MAX:
		return "%s is fully built." % name_of(id)
	if level(id) + 1 >= 3 and deepest(g, p) < Economy.BUILDING_L3_FLOOR:
		return "Level 3 needs a hero of this town to reach floor %d." % Economy.BUILDING_L3_FLOOR
	var c := next_cost(id)
	if g.gold < int(c.get("gold", 0)):
		return "Not enough gold (need %s)." % UI.short(int(c["gold"]))
	if g.scrap < int(c.get("scrap", 0)):
		return "Not enough scrap (need %d)." % int(c["scrap"])
	if g.dust < int(c.get("dust", 0)):
		return "Not enough dust (need %d)." % int(c["dust"])
	return ""

## Builds the next level of a building in this town. The hero you're playing pays.
static func upgrade(g: GameState, p: Profile, id: String) -> bool:
	var why := blocked(g, p, id)
	if why != "":
		g.say(why)
		return false
	var c := next_cost(id)
	g.gold -= int(c.get("gold", 0))
	g.scrap -= int(c.get("scrap", 0))
	g.dust -= int(c.get("dust", 0))
	levels[id] = level(id) + 1
	g.say("[color=#e8b14a]The %s is now level %d.[/color] %s" % [name_of(id), level(id), benefit(id, level(id))])
	if p != null:
		p.save()
	g.save_game()
	return true

## A new hero joins this town (main._start): a well-built Inn sends them off better stocked.
static func on_recruit(g: GameState) -> void:
	var r: Dictionary = pick("inn", Economy.INN_RECRUIT)
	g.potions += int(r.get("potions", 0))
	g.gold += int(r.get("gold", 0))
	if not r.is_empty():
		g.say("[color=#e8b14a]The Inn sends you off with %d potions and %d gold.[/color]" % [int(r.get("potions", 0)), int(r.get("gold", 0))])
