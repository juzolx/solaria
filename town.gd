class_name Town
## The town: the safe hub you return to between dives. No fighting happens here.
## Buildings (art/town/town.json hotspots) open the Town pages: Shop, Blacksmith,
## Tavern (Fortune's Wheel), Inn (rest), Vault (stash), Bounty Board, Guild Hall.
##
## Bounty Board (contracts): monster-specific hunts posted for the zone you're in,
## with the reward shown up front (gold, gear, or a weapon for your class). Take
## up to MAX_TAKEN and hunt in the dungeon; finished contracts pay into the Mailbox (mail.gd).
## Guild Hall (deeds): achievement rewards are mailed when earned (mail.gd).

const MAX_TAKEN := 3
const POSTED := 4
const REROLL_COST := 150        # times (1 + best floor / 25)
const RARE := 2
const EPIC := 3
const REST_COST := 4            # gold per level for a full night's rest (free under level 6)

## How the town looks in each zone: art season, color grade and weather.
## tint multiplies colors, sat 0..1+ is saturation, dark 0..1 is how close to night it is.
const LOOKS := [
	{"season": "summer", "tint": Color(1.0, 1.0, 0.96), "sat": 1.0, "dark": 0.0, "weather": "motes", "name": "Mossy Hollows"},
	{"season": "autumn", "tint": Color(0.84, 0.9, 0.86), "sat": 0.55, "dark": 0.45, "weather": "fog", "name": "Sunken Catacombs"},
	{"season": "spring", "tint": Color(0.82, 0.92, 1.0), "sat": 0.85, "dark": 0.3, "weather": "rain", "name": "Flooded Depths"},
	{"season": "autumn", "tint": Color(1.0, 0.78, 0.62), "sat": 1.0, "dark": 0.55, "weather": "embers", "name": "Ember Halls"},
	{"season": "summer", "tint": Color(0.7, 0.66, 0.95), "sat": 0.7, "dark": 0.75, "weather": "wisps", "name": "The Shadow Deep"},
	{"season": "autumn", "tint": Color(0.86, 0.86, 0.84), "sat": 0.35, "dark": 0.4, "weather": "leaves", "name": "The Hushwood"},
	{"season": "spring", "tint": Color(1.0, 0.86, 1.0), "sat": 1.1, "dark": 0.35, "weather": "sparkles", "name": "The Glimmer Court"},
	{"season": "summer", "tint": Color(1.0, 0.86, 0.7), "sat": 0.75, "dark": 0.5, "weather": "smoke", "name": "The Ironroot Deeps"},
	{"season": "spring", "tint": Color(1.08, 1.0, 0.82), "sat": 1.0, "dark": 0.0, "weather": "motes", "name": "The Gilded Spire"},
	{"season": "winter", "tint": Color(0.9, 0.72, 0.68), "sat": 0.45, "dark": 0.6, "weather": "ash", "name": "The Cinder Abyss"},
]

## Building id -> [Town page index, short line shown when you tap it]
const BUILDINGS := {
	"shop": [0, "Buy gear and potions"],
	"market": [0, "Today's wares from this zone"],
	"smith": [1, "Craft sets, upgrade your bag"],
	"tavern": [2, "Try your luck on Fortune's Wheel"],
	"inn": [3, "Rest and heal"],
	"stash": [4, "Your Vault (shared stash)"],
	"bounty": [5, "Monster contracts"],
	"guild": [6, "Your deeds"],
	"mail": [7, "Your letters and rewards"],
}

static func look(g: GameState) -> Dictionary:
	return LOOKS[clampi(GameData.zone_index(maxi(1, g.floor_num)), 0, LOOKS.size() - 1)]

# =====================================================================
# Going in and out
# =====================================================================

## Why you can't go to town right now ("" if you can).
static func blocked(g: GameState) -> String:
	if g.trial_active:
		return "Finish the trial first."
	if g.run_over:
		return "This hero's run is over."
	if not g.shop_unlocked():
		return "The town opens once you reach floor %d." % GameData.SHOP_UNLOCK_FLOOR
	return ""

static func enter(g: GameState) -> bool:
	if g.in_town:
		return true
	var why := blocked(g)
	if why != "":
		g.say(why)
		return false
	g.in_town = true
	g.path_offer.clear()
	g.buffs.clear()
	g.hero_status.clear()
	g.shield_hp = 0
	g.kill_streak = 0
	refresh_board(g)
	# Traders follow the roads: new zone, new wares
	if g.shop_zone != GameData.zone_index(maxi(1, g.floor_num)):
		g.restock_shop()
	g.say("[color=#e8b14a]You head back to town.[/color] Nothing can attack you here.")
	g.tip("town", "Welcome to town! Tap a building to go in. Take contracts at the Bounty Board, collect your rewards from the Mailbox, and rest at the Inn. Head back down through the cave when you're ready.")
	g.events.append({"type": "town", "in": true})
	g.save_game()
	return true

static func leave(g: GameState) -> void:
	if not g.in_town:
		return
	g.in_town = false
	g.fight = 1
	g.spawn_enemy()
	g.say("[color=#e8b14a]Back into the dungeon: floor %d.[/color]" % g.floor_num)
	g.events.append({"type": "town", "in": false})
	g.save_game()

## Shop stock is made in the style of the zone you're in (power still follows your best floor).
static func local_goods(g: GameState, item: Dictionary) -> Dictionary:
	if int(item["rarity"]) >= GameData.LEGENDARY:
		return item
	var pick: Array = ItemPool.pick(String(item["slot"]), GameData.zone_index(maxi(1, g.floor_num)))
	item["base_name"] = pick[0]
	item["name"] = pick[0]
	item["type"] = pick[1]
	item["flavor"] = pick[2]
	return item

# =====================================================================
# Inn
# =====================================================================

static func rest_cost(g: GameState) -> int:
	return 0 if g.level < 6 else REST_COST * g.level

static func rest(g: GameState) -> bool:
	if g.hero_hp >= g.get_max_hp():
		g.say("You're already rested.")
		return false
	var cost := rest_cost(g)
	if g.gold < cost:
		g.say("A room costs %d gold." % cost)
		return false
	g.gold -= cost
	g.hero_hp = g.get_max_hp()
	g.hero_status.clear()
	if g.party != null:
		g.party.heal_all()
	g.say("[color=#4ade80]You sleep well and wake at full health.[/color]" + (" (-%d gold)" % cost if cost > 0 else ""))
	g.save_game()
	return true

# =====================================================================
# Bounty Board
# =====================================================================

## Keeps POSTED contracts on the board. A new day replaces the ones you haven't taken.
static func refresh_board(g: GameState) -> void:
	var today := Time.get_date_string_from_system()
	if g.board_day != today:
		g.board_day = today
		g.contracts = g.contracts.filter(func(c): return c.get("taken", false))
	var posted := 0
	for c in g.contracts:
		if not c.get("taken", false):
			posted += 1
	var tries := 0
	while posted < POSTED and tries < 20:
		tries += 1
		var c := _new_contract(g)
		if c.is_empty():
			continue
		g.contracts.append(c)
		posted += 1

static func _monsters_here(g: GameState) -> Array:
	var seen: Array = []
	var all: Array = []
	for m in GameData.floor_monsters(maxi(1, g.floor_num)):
		var n: String = m[0]["name"]
		if n in all:
			continue
		all.append(n)
		if g.codex.seen(n):
			seen.append(n)
	return seen if seen.size() >= 2 else all

static func _taken_targets(g: GameState) -> Array:
	var out: Array = []
	for c in g.contracts:
		out.append(String(c.get("monster", "")) + String(c.get("kind", "")))
	return out

static func _new_contract(g: GameState) -> Dictionary:
	var zi := GameData.zone_index(maxi(1, g.floor_num))
	var z: Dictionary = GameData.ZONES[zi]
	var roll := randf()
	var c := {"id": randi(), "zone": zi, "have": 0, "taken": false, "done": false}
	if roll < 0.55:
		var pool := _monsters_here(g)
		if pool.is_empty():
			return {}
		c["kind"] = "hunt"
		c["monster"] = pool.pick_random()
		c["need"] = [10, 15, 20, 25].pick_random()
		c["text"] = "Hunt %d %s" % [c["need"], c["monster"]]
		if randf() < 0.35:
			c["reward"] = {"item": {"slot": GameData.SLOT_ORDER.pick_random(), "rarity": RARE + (1 if c["need"] >= 20 else 0)}}
		else:
			c["reward"] = {"gold": 40 * int(c["need"])}
	elif roll < 0.82:
		c["kind"] = "elite"
		c["monster"] = ""
		c["need"] = [3, 4, 5].pick_random()
		c["text"] = "Slay %d Rare-or-stronger monsters in %s" % [c["need"], z["name"]]
		c["reward"] = {"item": {"slot": "Weapon" if randf() < 0.5 else GameData.SLOT_ORDER.pick_random(), "rarity": EPIC}}
	else:
		var boss: Dictionary = z["mid"] if randf() < 0.6 else z["boss"]
		c["kind"] = "wanted"
		c["monster"] = boss["name"]
		c["need"] = 1
		c["text"] = "WANTED: %s" % boss["name"]
		var leg: bool = boss == z["boss"]
		c["reward"] = {"gold": 600 if leg else 300, "item": {"slot": "Weapon", "rarity": GameData.LEGENDARY if leg else EPIC}}
	if (String(c.get("monster", "")) + String(c["kind"])) in _taken_targets(g):
		return {}
	return c

static func taken_count(g: GameState) -> int:
	var n := 0
	for c in g.contracts:
		if c.get("taken", false):
			n += 1
	return n

static func ready_count(g: GameState) -> int:
	var n := 0
	for c in g.contracts:
		if c.get("done", false):
			n += 1
	return n

static func take(g: GameState, id: int) -> bool:
	if taken_count(g) >= MAX_TAKEN:
		g.say("You can carry %d contracts at once. Finish one first." % MAX_TAKEN)
		return false
	for c in g.contracts:
		if int(c["id"]) == id and not c.get("taken", false):
			c["taken"] = true
			g.say("Contract taken: %s" % c["text"])
			g.save_game()
			return true
	return false

static func drop(g: GameState, id: int) -> void:
	g.contracts = g.contracts.filter(func(c): return int(c["id"]) != id)
	refresh_board(g)
	g.save_game()

static func reroll_cost(g: GameState) -> int:
	return int(REROLL_COST * (1.0 + g.best_floor / 25.0))

## New postings for gold (taken contracts stay).
static func reroll(g: GameState) -> bool:
	var cost := reroll_cost(g)
	if g.gold < cost:
		g.say("New postings cost %d gold." % cost)
		return false
	g.gold -= cost
	g.contracts = g.contracts.filter(func(c): return c.get("taken", false))
	refresh_board(g)
	g.save_game()
	return true

## Called on every kill (game_state._enemy_defeated).
static func on_kill(g: GameState, species: String, tier: int, was_boss: bool, zone_i: int) -> void:
	for c in g.contracts:
		if not c.get("taken", false) or c.get("done", false):
			continue
		var hit := false
		match String(c["kind"]):
			"hunt":
				hit = species == c["monster"]
			"elite":
				hit = not was_boss and tier >= Monsters.RARE and zone_i == int(c["zone"])
			"wanted":
				hit = was_boss and species == c["monster"]
		if hit:
			c["have"] = int(c["have"]) + 1
			if int(c["have"]) >= int(c["need"]):
				c["done"] = true
	# Finished contracts pay out by mail right away
	for c in g.contracts.duplicate():
		if c.get("done", false):
			_pay(g, c)
			g.say("[color=#fbbf24]Contract complete:[/color] %s. The reward is in your Mailbox." % c["text"])

static func reward_text(r: Dictionary, g: GameState) -> String:
	var parts: Array = []
	if r.has("gold"):
		parts.append("%d gold" % int(float(r["gold"]) * (1.0 + g.best_floor / 25.0)))
	if r.has("item"):
		var it: Dictionary = r["item"]
		var slot := String(it["slot"])
		var what: String = {"Weapon": "weapon for your class", "Chest": "body armor", "Legs": "leg armor", "Feet": "boots",
			"Helmet": "helmet", "Off Hand": "off-hand"}.get(slot, slot.to_lower())
		parts.append("%s %s" % [GameData.RARITY_NAMES[int(it["rarity"])], what])
	return " + ".join(parts)

## Pays a finished contract into the Mailbox and takes it off the board.
static func _pay(g: GameState, c: Dictionary) -> void:
	g.contracts.erase(c)
	Mail.post(g, "The Bounty Board", "Bounty paid: %s" % String(c["text"]).trim_prefix("WANTED: "),
		"Contract done. Here is what you were promised.", c["reward"])
	g.codex.add("bounties")
	g._faith(Classes.FAITH["bounty"])
	refresh_board(g)
	g._check_codex()
	g.codex.save()

## Turns in a finished contract (older saves can still hold some). Returns its letter's title.
static func claim(g: GameState, id: int) -> String:
	for c in g.contracts:
		if int(c["id"]) == id and c.get("done", false):
			_pay(g, c)
			g.save_game()
			return "Bounty paid"
	return ""

# =====================================================================
# Rewards
# =====================================================================

## A reward item: gear at your level; weapons are your class's kind when possible.
static func reward_item(g: GameState, slot: String, rarity: int) -> Dictionary:
	var want := String(g.class_info().get("look", {}).get("Weapon", ""))
	var item := GameData.make_item(slot, rarity, g.best_floor, g._new_id())
	if slot == "Weapon" and want != "":
		for i in 16:
			if String(item.get("type", "")) == want:
				break
			item = GameData.make_item(slot, rarity, g.best_floor, g._new_id())
	return item

# =====================================================================
# Guild Hall: deeds (achievement rewards are claimed here)
# =====================================================================

## The full reward for an achievement: its gold/potions/etc. plus gear by how hard it was.
static func deed_reward(a: Dictionary) -> Dictionary:
	var r: Dictionary = (a["reward"] as Dictionary).duplicate()
	var gold := int(r.get("gold", 0))
	var rarity := RARE
	if a.has("title") or gold >= 4000:
		rarity = GameData.LEGENDARY
	elif gold >= 1500 or int(r.get("scrap", 0)) >= 100:
		rarity = EPIC
	var slots := ["Weapon", "Chest", "Helmet", "Legs", "Feet"]
	r["item"] = {"slot": slots[absi(hash(a["id"])) % slots.size()], "rarity": rarity}
	return r

static func claim_deed(g: GameState, id: String) -> String:
	if not id in g.codex.deeds:
		return ""
	var a := {}
	for x in Codex.ACHIEVEMENTS:
		if x["id"] == id:
			a = x
	if a.is_empty():
		g.codex.deeds.erase(id)
		return ""
	g.codex.deeds.erase(id)
	g.codex.dirty = true
	var l := Mail.post(g, "The Guild Hall", "Deed: %s" % a["name"], "%s. Well done! Here is your reward." % a["text"], deed_reward(a))
	g.codex.save()
	g.save_game()
	return String(l["title"])
