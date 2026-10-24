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
	{"season": "summer", "tint": Color(1.0, 1.0, 0.96), "sat": 1.0, "dark": 0.0, "weather": "motes", "zone": "mossy_hollows"},
	{"season": "autumn", "tint": Color(0.84, 0.9, 0.86), "sat": 0.55, "dark": 0.45, "weather": "fog", "zone": "sunken_catacombs"},
	{"season": "spring", "tint": Color(0.82, 0.92, 1.0), "sat": 0.85, "dark": 0.3, "weather": "rain", "zone": "flooded_depths"},
	{"season": "autumn", "tint": Color(1.0, 0.78, 0.62), "sat": 1.0, "dark": 0.55, "weather": "embers", "zone": "ember_halls"},
	{"season": "summer", "tint": Color(0.7, 0.66, 0.95), "sat": 0.7, "dark": 0.75, "weather": "wisps", "zone": "the_shadow_deep"},
	{"season": "autumn", "tint": Color(0.86, 0.86, 0.84), "sat": 0.35, "dark": 0.4, "weather": "leaves", "zone": "elf"},
	{"season": "spring", "tint": Color(1.0, 0.86, 1.0), "sat": 1.1, "dark": 0.35, "weather": "sparkles", "zone": "fairy"},
	{"season": "summer", "tint": Color(1.0, 0.86, 0.7), "sat": 0.75, "dark": 0.5, "weather": "smoke", "zone": "dwarf"},
	{"season": "spring", "tint": Color(1.08, 1.0, 0.82), "sat": 1.0, "dark": 0.0, "weather": "motes", "zone": "angel"},
	{"season": "winter", "tint": Color(0.9, 0.72, 0.68), "sat": 0.45, "dark": 0.6, "weather": "ash", "zone": "demon"},
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
	"clinic": [8, "Heal and keep your pets"],
	"church": [9, "Lift curses, bless your gear"],
	"cabin": [10, "Your town's trophies"],
}

static func look(g: GameState) -> Dictionary:
	return LOOKS[clampi(GameData.zone_index(maxi(1, g.floor_num)), 0, LOOKS.size() - 1)]

# =====================================================================
# Going in and out
# =====================================================================

## Why you can't go to town right now ("" if you can).
## scroll: a Return Scroll ignores the between-floors rule and any portal (portals.gd).
static func blocked(g: GameState, floor_done := false, scroll := false) -> String:
	if g.run_over:
		return "This hero's run is over."
	if not g.shop_unlocked():
		return "The town opens once you reach floor %d." % GameData.SHOP_UNLOCK_FLOOR
	if g.in_town or scroll:
		return ""
	if Portals.inside(g):
		return Portals.hold_text(g)  # rifts and trials: one rule, one line
	if not floor_done and not floor_clear(g):
		return FLOOR_BLOCK
	return ""

const FLOOR_BLOCK := "You can only head home between floors."

## True when you're between floors: nothing on this floor has been fought yet
## (you just cleared the last one, woke at a checkpoint, or came down from town).
static func floor_clear(g: GameState) -> bool:
	return g.door_pending() or (g.fight == 1 and g.enemy_hp >= g.enemy_max_hp)

## Reads a Return Scroll: home right now, even mid-fight. Returns false if you have none.
static func use_return(g: GameState) -> bool:
	if g.return_scrolls <= 0 or g.in_town:
		return false
	if blocked(g, true, true) != "":
		return false
	g.return_scrolls -= 1
	g.go_home_after = false
	g.say("[color=%s]You read a Return Scroll.[/color] The dungeon fades away..." % Portals.COLOR)
	Portals.leave_for_scroll(g)  # out of any rift or trial first, with no reward
	return enter(g, true)

## floor_done: you just cleared a floor, so the between-floors rule is met.
static func enter(g: GameState, floor_done := false) -> bool:
	if g.in_town:
		return true
	var why := blocked(g, floor_done)
	if why != "":
		g.say(why)
		return false
	g.in_town = true
	g.get_up(1.0)
	# Everything you carried home goes back in the Bank (in town all your gold is in one purse)
	var carried := g.gold
	g.gold += g.bank
	g.bank = 0
	# Backpacks you got home are yours for good
	if g.packs_carried > 0:
		g.bonus_bag = mini(GameData.PACK_MAX, g.bonus_bag + g.packs_carried)
		g.say("[color=#60a5fa]You brought %d backpack%s home.[/color] Your bag now holds %d." % [g.packs_carried, "" if g.packs_carried == 1 else "s", g.bag_capacity()])
		g.packs_carried = 0
		g.bag_version += 1
	_home_tally(g, carried)
	Bench.collect(g)  # next update: what your heroes at home found
	TownEvents.on_home(g)  # a fair, a bard, a bounty day...
	Smith.restock(g)  # Hilde forges new pieces while you're away
	Milestones.on_home(g)
	g.path_offer.clear()
	g.doors.clear()
	g.room_props.clear()  # the room you left (an untouched rift too) stays behind
	g.room_kind = "fight"
	g.exploring = false
	g.buffs.clear()
	g.hero_status.clear()
	g.hero_stacks.clear()
	g.shield_hp = 0
	g.kill_streak = 0
	refresh_board(g)
	# 0.13+ (Juzo): new wares every time you come home, made for how deep you have been
	g.restock_shop()
	g.say("[color=#e8b14a]You head back to town.[/color] Nothing can attack you here.%s" % (" You bank the %d gold you carried home." % carried if carried > 0 else ""))
	g.tip("town", "Welcome to town! Tap a building to go in. Take contracts at the Bounty Board, collect your rewards from the Mailbox, and rest at the Inn. Head back down through the cave when you're ready.")
	g.events.append({"type": "town", "in": true})
	g.save_game()
	return true

## How much of your gold each carry choice takes down (the rest stays in the Bank).
const CARRY_SHARES := [0.0, 0.25, 0.5, 1.0]
const CARRY_NAMES := ["None", "A quarter", "Half", "All"]

static func carry_amount(g: GameState, pick: int) -> int:
	return int(floor(float(g.total_gold()) * float(CARRY_SHARES[clampi(pick, 0, CARRY_SHARES.size() - 1)])))

static func leave(g: GameState) -> void:
	if not g.in_town:
		return
	g.in_town = false
	# Split your purse: what you carry is at risk down there, the rest is safe in the Bank
	var total := g.total_gold()
	var carry := carry_amount(g, g.carry_pick)
	g.gold = carry
	g.bank = total - carry
	g.fight = 1
	g.spawn_enemy()
	start_dive(g)
	g.say("[color=#e8b14a]Back into the dungeon: floor %d.[/color] You carry %d gold; %d stays safe in the Bank." % [g.floor_num, g.gold, g.bank])
	g.tip("bank", "Gold you carry into the dungeon can be lost if you fall. Gold in the Bank is always safe. Everything you carry home is banked for you.")
	g.events.append({"type": "town", "in": false})
	Portals.resume(g)  # a realm gate you walked away from opens again
	g.save_game()

## Remembers what a dive set off with (also after a fall, when it starts over).
static func start_dive(g: GameState) -> void:
	var ids: Array = []
	for it in g.bag:
		ids.append(int(it.get("id", -1)))
	g.dive = {"gold": g.gold, "floor": g.floor_num, "kills": g.codex.stat("kills"), "items": ids}

## Getting home safe: what this dive brought back, for the "Made it home" card.
static func _home_tally(g: GameState, carried: int) -> void:
	if g.dive.is_empty():
		return
	g.codex.add("home_trips")  # a dive that ended safely at home (the first one is the tutorial goal)
	var before: Array = g.dive.get("items", [])
	var found := 0
	var best: Dictionary = {}
	for it in g.bag:
		if not int(it.get("id", -1)) in before:
			found += 1
			if best.is_empty() or int(it.get("rarity", 0)) > int(best.get("rarity", 0)):
				best = it
	RunLog.add(g, "home", maxi(0, carried - int(g.dive.get("gold", 0))), found)
	g.events.append({"type": "home_tally", "gold": maxi(0, carried - int(g.dive.get("gold", 0))), "items": found, "best": best,
		"floors": maxi(0, g.floor_num - int(g.dive.get("floor", g.floor_num))), "kills": maxi(0, g.codex.stat("kills") - int(g.dive.get("kills", 0)))})
	g.dive = {}

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
	return 0 if g.level < 6 else int(round(REST_COST * g.level * Buildings.mult("inn", Economy.INN_REST_MULT)))  # 2.1: the Inn building

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
	g.hero_stacks.clear()
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
		var n: String = m[0]["id"]
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
		c["text"] = "Hunt %d %s" % [c["need"], Monsters.name_of(c["monster"])]
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
		c["monster"] = boss["id"]
		c["need"] = 1
		c["text"] = "WANTED: %s" % boss["name"]
		var leg: bool = boss == z["boss"]
		c["reward"] = {"gold": 600 if leg else 300, "item": {"slot": "Weapon", "rarity": GameData.LEGENDARY if leg else EPIC}}
	if (String(c.get("monster", "")) + String(c["kind"])) in _taken_targets(g):
		return {}
	return c

## How many contracts you can carry (2.1: more with a bigger Bounty Board).
static func max_taken() -> int:
	return int(Buildings.pick("bounty", Economy.BOUNTY_TAKEN))

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
	if taken_count(g) >= max_taken():
		g.say("You can carry %d contracts at once. Finish one first." % max_taken())
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
		for i in 64:
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
	if gold > 0:  # 2.1: a bigger Guild Hall pays more
		r["gold"] = int(round(gold * Buildings.mult("guild", Economy.GUILD_GOLD_MULT)))
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

## Gear found this dive that a fall would drop (for the "at risk" line in the top bar).
static func dive_finds(g: GameState) -> int:
	if g.dive.is_empty():
		return 0
	var before: Array = g.dive.get("items", [])
	var n := 0
	for it in g.bag:
		if not int(it.get("id", -1)) in before and not GameState.is_bound(it):
			n += 1
	return n
