class_name Bench
## Next update (Juzo): heroes left at home while you dive bring back gold, scrap
## and now and then an item. Only while you play (no offline progress): every
## monster you beat gives each of them a roll. What they find depends on their
## class. The haul waits for you and is paid out when you get home.

const GOLD_SHARE := 0.08     # of a monster's base gold, per benched hero
const SCRAP_CHANCE := 0.10   # per benched hero per kill
const ITEM_CHANCE := 0.004   # per benched hero per kill
## Class -> what they're good at (multipliers) and what they do all day.
const RATES := {
	"Warrior": {"gold": 1.0, "scrap": 1.6, "item": 1.0, "job": "strips old gear for scrap"},
	"Knight": {"gold": 1.0, "scrap": 1.4, "item": 1.0, "job": "guards caravans for coin and scrap"},
	"Wanderer": {"gold": 1.0, "scrap": 1.0, "item": 1.6, "job": "roams the hills and finds things"},
	"Cleric": {"gold": 1.4, "scrap": 1.0, "item": 1.0, "job": "collects tithes"},
	"Acolyte": {"gold": 1.3, "scrap": 1.0, "item": 1.1, "job": "runs errands for the temple"},
	"Mage": {"gold": 1.0, "scrap": 1.3, "item": 1.3, "job": "unweaves broken enchantments"},
	"Trickster": {"gold": 1.9, "scrap": 0.8, "item": 1.0, "job": "lightens a few purses"},
	"Ranger": {"gold": 1.0, "scrap": 1.0, "item": 1.7, "job": "hunts the woods past the walls"},
	"Bard": {"gold": 1.7, "scrap": 0.8, "item": 1.0, "job": "plays the tavern every night"},
	"Sentinel": {"gold": 1.1, "scrap": 1.4, "item": 0.9, "job": "stands watch on the town gate"},
	"Ironbark": {"gold": 0.9, "scrap": 1.3, "item": 1.3, "job": "tends the woods and hauls timber"},
	"Nightstalker": {"gold": 1.5, "scrap": 0.9, "item": 1.3, "job": "walks the rooftops after dark"},
	"Conjurer": {"gold": 1.0, "scrap": 1.2, "item": 1.4, "job": "sends spirits to fetch lost things"},
}
const HIDDEN_RATE := {"gold": 1.3, "scrap": 1.3, "item": 1.3, "job": "knows paths no one else does"}

static func rate(cls: String) -> Dictionary:
	if RATES.has(cls):
		return RATES[cls]
	return HIDDEN_RATE if cls != "" else {"gold": 0.0, "scrap": 0.0, "item": 0.0, "job": "hasn't picked a class yet"}

## Rebuilds who's at home: Regular heroes in this town who aren't you or in your team.
static func refresh(g: GameState) -> void:
	g.bench_roster = []
	if g.hardcore:
		return
	for n in range(1, GameData.MAX_HEROES + 1):
		if n == g.slot or n in g.party_slots:
			continue
		var meta := GameState.slot_meta(n)
		if meta.is_empty() or meta.get("hardcore", false) or str(meta.get("class", "")) == "":
			continue
		g.bench_roster.append({"slot": n, "name": str(meta.get("name", "Hero")), "class": str(meta.get("class", "")), "level": int(meta.get("level", 1))})

## One roll per hero at home for a monster you beat.
static func on_kill(g: GameState) -> void:
	if g.hardcore or g.in_town or g.bench_roster.is_empty():
		return
	for h in g.bench_roster:
		var r := rate(str(h["class"]))
		var lvl_f := clampf(float(h["level"]) / maxf(1.0, g.floor_num * 0.5), 0.3, 1.0)  # a low-level hero finds less
		var gold := int(round((2 + g.floor_num) * GOLD_SHARE * float(r["gold"]) * lvl_f))
		g.bench_haul["gold"] = int(g.bench_haul.get("gold", 0)) + gold
		if randf() < SCRAP_CHANCE * float(r["scrap"]):
			g.bench_haul["scrap"] = int(g.bench_haul.get("scrap", 0)) + 1 + GameData.zone_index(g.floor_num)
		if randf() < ITEM_CHANCE * float(r["item"]) * lvl_f:
			var rar := mini(g._rarity(0, GameData.LEGENDARY_CHANCE_NORMAL), GameData.LEGENDARY - 1)  # up to Epic
			var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), rar, g.floor_num, g._new_id())
			var items: Array = g.bench_haul.get("items", [])
			items.append(item)
			g.bench_haul["items"] = items
			g.bench_haul["by"] = str(h["name"])

static func has_haul(g: GameState) -> bool:
	return int(g.bench_haul.get("gold", 0)) > 0 or int(g.bench_haul.get("scrap", 0)) > 0 or not g.bench_haul.get("items", []).is_empty()

## You got home: your heroes hand over what they found. Returns the line said, or "".
static func collect(g: GameState) -> String:
	if not has_haul(g):
		return ""
	var gold := int(g.bench_haul.get("gold", 0))
	var scrap := int(g.bench_haul.get("scrap", 0))
	var items: Array = g.bench_haul.get("items", [])
	g.gold += gold
	g.scrap += scrap
	var kept := 0
	for item in items:
		if g.bag.size() < g.bag_capacity() + GameState.OVERFLOW_MAX:
			g.bag.append(item)
			g.codex.found_item(item)
			kept += 1
		else:
			g.scrap += GameData.scrap_value(item, g.scrap_mult())
	if kept > 0:
		g.bag_version += 1
	g.bench_haul = {}
	var parts: Array = []
	if gold > 0:
		parts.append("%d gold" % gold)
	if scrap > 0:
		parts.append("%d scrap" % scrap)
	if kept > 0:
		parts.append("%d item%s" % [kept, "" if kept == 1 else "s"])
	for i in range(g.events.size() - 1, -1, -1):
		if g.events[i].get("type", "") == "home_tally":
			g.events[i]["bench"] = ", ".join(parts)  # shown on the welcome-home card
			break
	var line := "[color=#e8b14a]Your heroes at home[/color] brought in %s while you were down there." % ", ".join(parts)
	g.say(line)
	return line
