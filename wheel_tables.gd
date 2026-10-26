class_name WheelTables
extends RefCounted
## Fortune's Wheel tables: the ONE place the Wheel's odds live.
## The odds screen reads these same functions, so what the player sees is
## exactly what the code rolls (2.1, G6).
##
## Normal table: put an item on the Wheel; win and it comes back one rarity
## higher (GameData.GAMBLE_CHANCES, read by GameState.gamble_chance).
## Legendary table: opens at floor 250, account-wide (once any hero gets there,
## the codex flag UNLOCK_KEY keeps it open for every hero). Pay game gold
## for one spin, win one prize from LEGENDARY_PRIZES. Its top prizes almost
## never hit; Luck and goblin builds raise them, up to a hard cap.
## Spins are only ever paid for with gold earned in the dungeon: never sold
## for real money.

const LEGENDARY_UNLOCK_FLOOR := 250
const UNLOCK_KEY := "wheel_legendary"     # codex flag: the table stays open once earned
const SPINS_KEY := "wheel_legendary_spins"
const SPIN_COST := 2500                   # gold, x (1 + deepest floor / 25): 27,500 at floor 250

# Prize ids are permanent (stable ids; "nest_egg" was removed in 2.1: pets come
# only from nests). "tier": common / rare / top.
# Weights are out of 1,000,000 before Fortune. "reward" goes through
# GameState.give_reward (gold and scrap scale with depth there);
# "legendary" is a count of Legendary items made for your depth.
const LEGENDARY_PRIZES := [
	{"id": "gold_purse", "name": "Purse of gold", "tier": "common", "weight": 425000, "reward": {"gold": 600}},
	{"id": "scrap_heap", "name": "Heap of scrap", "tier": "common", "weight": 250000, "reward": {"scrap": 600}},
	{"id": "potion_crate", "name": "Crate of potions", "tier": "common", "weight": 150000, "reward": {"potions": 8}},
	{"id": "luck_scroll", "name": "Scroll of Luck", "tier": "common", "weight": 100000, "reward": {"keep_scroll": "luck"}},
	{"id": "gold_hoard", "name": "Hoard of gold", "tier": "common", "weight": 60000, "reward": {"gold": 5000}},
	{"id": "legendary_item", "name": "A Legendary item", "tier": "rare", "weight": 14850, "legendary": 1},
	{"id": "kings_ransom", "name": "King's Ransom (a mountain of gold)", "tier": "top", "weight": 100, "reward": {"gold": 150000}},
	{"id": "legend_cache", "name": "Cache of Legends (3 Legendary items)", "tier": "top", "weight": 50, "legendary": 3},
]

# Fortune: Luck and goblin builds tilt the Legendary table.
# Each point of Fortune adds 10% to top-prize weights (max x10) and 2% to
# rare-prize weights (max x3). Common weights never change.
const TOP_PER_POINT := 0.10
const TOP_CAP := 10.0
const RARE_PER_POINT := 0.02
const RARE_CAP := 3.0
const GOBLIN_RACE_FORTUNE := 10.0
const GOBLINS_PER_POINT := 5.0     # treasure goblins caught per Fortune point...
const GOBLIN_CATCH_MAX := 15.0     # ...up to this many points
const GOLD_FIND_PER_POINT := 5.0   # % gold find per Fortune point...
const GOLD_FIND_MAX := 15.0        # ...up to this many points
const LUCK_SCROLL_FORTUNE := 10.0

# ---------- Normal table ----------

## [{rarity, name, pct}] for the item Wheel: the same GAMBLE_CHANCES gamble() rolls.
static func normal_rows() -> Array:
	var out: Array = []
	for r in GameData.GAMBLE_CHANCES.size():
		out.append({"rarity": r, "name": GameData.RARITY_NAMES[r], "to": GameData.RARITY_NAMES[r + 1], "pct": float(GameData.GAMBLE_CHANCES[r])})
	return out

# ---------- Unlock ----------

static func deepest_floor(g: GameState) -> int:
	return maxi(g.best_floor, g.codex.stat("best_floor"))

static func legendary_unlocked(g: GameState) -> bool:
	return g.codex.stat(UNLOCK_KEY) > 0 or deepest_floor(g) >= LEGENDARY_UNLOCK_FLOOR

## Called when a floor is reached: opens the table (once, for good) at floor 250.
static func on_floor(g: GameState) -> void:
	if g.codex.stat(UNLOCK_KEY) > 0 or deepest_floor(g) < LEGENDARY_UNLOCK_FLOOR:
		return
	g.codex.at_least(UNLOCK_KEY, 1)
	g.say("[color=#e8b14a]The Legendary table on Fortune's Wheel is open![/color] Find it in Town › Tavern.")
	g.events.append({"type": "toast", "text": "Floor %d: the Wheel's Legendary table is open." % LEGENDARY_UNLOCK_FLOOR})

static func lock_text(g: GameState) -> String:
	return "Locked. Reach floor %d to open the Legendary table (deepest floor so far: %d)." % [LEGENDARY_UNLOCK_FLOOR, deepest_floor(g)]

# ---------- Fortune ----------

## Where your Fortune comes from: [[label, points]].
static func fortune_parts(g: GameState) -> Array:
	var parts: Array = []
	parts.append(["Luck", g.luck_odds()])
	if g.race() == "Goblin":
		parts.append(["Goblin blood", GOBLIN_RACE_FORTUNE])
	var caught := float(g.codex.stat("goblins"))
	if caught > 0.0:
		parts.append(["Treasure goblins caught", minf(GOBLIN_CATCH_MAX, caught / GOBLINS_PER_POINT)])
	var gf := float(g.effect_total("gold_find"))
	if gf > 0.0:
		parts.append(["Gold find", minf(GOLD_FIND_MAX, gf / GOLD_FIND_PER_POINT)])
	if g.luck_turns > 0:
		parts.append(["Scroll of Luck", LUCK_SCROLL_FORTUNE])
	return parts

static func fortune(g: GameState) -> float:
	var t := 0.0
	for p in fortune_parts(g):
		t += float(p[1])
	return maxf(0.0, t)

static func tier_mult(tier: String, fort: float) -> float:
	match tier:
		"top":
			return minf(TOP_CAP, 1.0 + fort * TOP_PER_POINT)
		"rare":
			return minf(RARE_CAP, 1.0 + fort * RARE_PER_POINT)
	return 1.0

## The weights the Legendary table rolls with at this much Fortune.
static func weights_for(fort: float) -> Array:
	var w: Array = []
	for p in LEGENDARY_PRIZES:
		w.append(float(p["weight"]) * tier_mult(String(p["tier"]), fort))
	return w

static func weights(g: GameState) -> Array:
	return weights_for(fortune(g))

## The odds screen's rows: [{id, name, tier, pct (yours), base_pct}].
## Built from weights_for(), the same numbers roll_index() picks from.
static func legendary_rows(fort: float) -> Array:
	var w := weights_for(fort)
	var base := weights_for(0.0)
	var tw := _sum(w)
	var tb := _sum(base)
	var out: Array = []
	for i in LEGENDARY_PRIZES.size():
		var p: Dictionary = LEGENDARY_PRIZES[i]
		out.append({"id": p["id"], "name": p["name"], "tier": p["tier"], "pct": 100.0 * float(w[i]) / tw, "base_pct": 100.0 * float(base[i]) / tb})
	return out

## Chance (%) of any top prize at this much Fortune.
static func top_pct(fort: float) -> float:
	var t := 0.0
	for row in legendary_rows(fort):
		if row["tier"] == "top":
			t += float(row["pct"])
	return t

static func _sum(a: Array) -> float:
	var t := 0.0
	for x in a:
		t += float(x)
	return t

## Picks an index from weights (rng optional, for tests).
static func roll_index(w: Array, rng: RandomNumberGenerator = null) -> int:
	var total := _sum(w)
	var x := (rng.randf() if rng else randf()) * total
	for i in w.size():
		x -= float(w[i])
		if x < 0.0:
			return i
	return w.size() - 1

## "0.015%  (1 in 6,667)" style text for the odds screen.
static func pct_text(pct: float) -> String:
	if pct >= 10.0:
		return "%.1f%%" % pct
	if pct >= 1.0:
		return "%.2f%%" % pct
	var s := "%.4f%%" % pct if pct >= 0.001 else "%.6f%%" % pct
	return "%s  (1 in %s)" % [s, _commas(int(round(100.0 / pct)))] if pct > 0.0 else "0%"

static func _commas(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

# ---------- Spinning ----------

static func spin_cost(g: GameState) -> int:
	return int(round(SPIN_COST * (1.0 + deepest_floor(g) / 25.0)))

## One spin of the Legendary table for game gold.
## Returns {"ok", "index", "prize", "text", "cost"}.
static func spin_legendary(g: GameState, rng: RandomNumberGenerator = null) -> Dictionary:
	if not legendary_unlocked(g):
		g.say(lock_text(g))
		return {"ok": false}
	if g.bag_capacity() - g.bag.size() < bag_room_needed():  # like the item Wheel: prizes need bag room
		g.say("Make room in your bag first: the Legendary table needs %d free slots (its best prize is %d items)." % [bag_room_needed(), bag_room_needed()])
		return {"ok": false}
	var cost := spin_cost(g)
	if g.gold < cost:
		g.say("Not enough gold (a Legendary spin costs %d)." % cost)
		return {"ok": false}
	g.gold -= cost
	var idx := roll_index(weights(g), rng)
	var prize: Dictionary = LEGENDARY_PRIZES[idx]
	var text := deliver(g, prize)
	g.codex.add(SPINS_KEY)
	g.codex.add("gambles")
	Lineage.gain(g, "gamble")
	if prize["tier"] == "top":
		g.codex.add("wheel_legendary_top")
		g.say("[color=#facc15][b]FORTUNE SMILES![/b][/color] %s: %s" % [prize["name"], text])
	else:
		g.say("[color=#e8b14a]The Legendary table gives:[/color] %s: %s" % [prize["name"], text])
	g.save_game()
	return {"ok": true, "index": idx, "prize": prize, "text": text, "cost": cost}

## Free bag slots a spin needs: the most Legendary items any prize gives.
static func bag_room_needed() -> int:
	var n := 1
	for p in LEGENDARY_PRIZES:
		n = maxi(n, int(p.get("legendary", 0)))
	return n

## What a prize pays at this hero's depth, exactly as deliver() will hand it
## over (gold and scrap scale with depth in GameState.give_reward).
static func prize_amount(g: GameState, prize: Dictionary) -> String:
	var parts: Array = []
	var r: Dictionary = prize.get("reward", {})
	if r.has("gold"):
		parts.append("%s gold" % _commas(g.reward_gold(int(r["gold"]))))
	if r.has("scrap"):
		parts.append("%s scrap" % _commas(g.reward_scrap(int(r["scrap"]))))
	if r.has("potions"):
		parts.append("%d potions" % int(r["potions"]))
	if r.has("keep_scroll"):
		parts.append("1 Scroll of Luck, kept for later")
	var n := int(prize.get("legendary", 0))
	if n > 0:
		parts.append("%d Legendary item%s for floor %d" % [n, "" if n == 1 else "s", g.best_floor])
	return ", ".join(parts)

## Hands a prize over through the usual reward code. Returns what you got.
static func deliver(g: GameState, prize: Dictionary) -> String:
	var parts: Array = []
	if prize.has("reward"):
		parts.append(g.give_reward(prize["reward"]))
	for _i in int(prize.get("legendary", 0)):
		var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.LEGENDARY, g.best_floor, g._new_id())
		item["locked"] = true  # never lost to the loot filter or a slip of the thumb
		g.add_to_wardrobe(item)
		g._note_find(item)
		g.bag.append(item)
		g.bag_version += 1
		parts.append(GameData.display_name(item))
	return ", ".join(parts)
