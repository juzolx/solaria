class_name Snik
extends RefCounted
## 0.13+ (Stage 3): Snik the goblin trader gets a personality and haggling. He warms
## to you the more you buy (codex stat merchant_buys), and once per visit you can try
## to talk him down: win and everything is cheaper, lose and he marks it all up.

const HAGGLE_WIN := 0.8    # prices x0.8 when you talk him down
const HAGGLE_LOSE := 1.1   # prices x1.1 when he's offended
## Friendship by purchases: [buys, name]
const LEVELS := [[0, "Stranger"], [5, "Customer"], [15, "Regular"], [35, "Pal"], [70, "Best customer"]]

static func friendship(g: GameState) -> int:
	var buys := g.codex.stat("merchant_buys")
	var lvl := 0
	for i in LEVELS.size():
		if buys >= int(LEVELS[i][0]):
			lvl = i
	return lvl

static func friendship_name(g: GameState) -> String:
	return String(LEVELS[friendship(g)][1])

## What Snik says when you walk up (a little warmer each friendship level).
static func greeting(g: GameState) -> String:
	var pools := [
		["Cheap, cheap! Only what's in your pockets, though.", "Don't touch what you can't pay for. That's a rule. Snik's rule.", "You look rich. Are you rich? You look rich."],
		["Oh, it's you! The one with the gold. Come, come.", "Back again? Snik saved the shiny ones. Mostly.", "Fresh stock! Fell off a skeleton. Totally legal."],
		["My regular! Snik tells the other goblins about you. Good things. Some good things.", "For you, Snik dusts the potions first.", "You keep coming back. Snik likes that. Snik likes gold more. But that too."],
		["Pal! Snik was worried. Snik is never worried. But a little.", "Sit, sit. Not there, that's a mimic. Snik is joking. Probably.", "Snik named a rat after you. It's a very brave rat."],
		["My best customer! Snik would sell you his own ears. For a fair price.", "Whatever you want. Snik will even pretend the prices are fair.", "Snik had a dream you got eaten. Then Snik woke up and you were here. Good morning!"],
	]
	var pool: Array = pools[friendship(g)]
	return "\"%s\"" % pool[randi() % pool.size()]

## Odds you talk him down (%): your luck and charm, plus friendship.
static func haggle_chance(g: GameState) -> float:
	return clampf(35.0 + g.luck_odds() * 0.5 + friendship(g) * 6.0, 10.0, 85.0)

static func can_haggle(g: GameState) -> bool:
	return g.merchant_who == "" and not g.merchant.is_empty() and g.merchant_haggle == ""

## One try per visit. Returns what Snik says.
static func haggle(g: GameState) -> String:
	if not can_haggle(g):
		return ""
	var won := randf() * 100.0 < haggle_chance(g)
	g.merchant_haggle = "won" if won else "lost"
	var mult := HAGGLE_WIN if won else HAGGLE_LOSE
	for e in g.merchant:
		if not e["sold"]:
			e["price"] = maxi(1, int(round(int(e["price"]) * mult)))
	g.codex.add("haggles_won" if won else "haggles_lost")
	if won:
		ClassTree.count(g, "haggles_won")
	var lines_won := ["Fine! FINE! Snik's children will starve. Snik has no children. Still!", "You drive a hard bargain. Snik respects that. Snik hates it, but respects it.", "Ugh. Twenty off. Don't tell the other goblins."]
	var lines_lost := ["Insulting! Snik's prices just went UP.", "Haggle with Snik? Snik invented haggling. Ten percent more.", "Snik is hurt. Snik's prices are also hurt. Upward."]
	var said: String = (lines_won if won else lines_lost).pick_random()
	g.say("[color=%s]%s[/color] \"%s\"" % ["#4ade80" if won else "#f87171", "You talk Snik down (20% off)!" if won else "Snik is offended (10% more).", said])
	g.save_game()
	return said

## A little line after a purchase.
static func thanks(g: GameState) -> String:
	var lines := ["Pleasure! Mostly Snik's.", "No refunds. No questions. No refunds.", "Good choice. Snik would have bought it. Snik did buy it. Now you did.", "Come back alive! Dead customers don't pay."]
	return "\"%s\"" % lines[randi() % lines.size()]

# =====================================================================
# 0.13+ (Juzo's notes): Snik is rarer now, and only he sells these curios
# =====================================================================

## Snik's exclusive unique items: one of these in every stock. ids are permanent.
const CURIOS := [
	{"id": "sniks_lucky_spoon", "name": "Snik's Lucky Spoon", "slot": "Weapon", "effect": "gold_find", "value": 40, "flavor": "He swears it was a sword once. It still finds gold."},
	{"id": "pocket_full_of_teeth", "name": "Pocket Full of Teeth", "slot": "Off Hand", "effect": "crit", "value": 22, "flavor": "Nobody asks whose. Snik doesn't say."},
	{"id": "the_hagglers_hat", "name": "The Haggler's Hat", "slot": "Helmet", "effect": "gold_find", "value": 35, "flavor": "Wear it and prices look worried."},
	{"id": "coat_of_many_pockets", "name": "Coat of Many Pockets", "slot": "Chest", "effect": "dodge", "value": 14, "flavor": "Some pockets are bigger on the inside. One of them bites."},
	{"id": "second_hand_greaves", "name": "Second-Hand Greaves", "slot": "Legs", "effect": "thorns", "value": 28, "flavor": "The first owner left the spikes in."},
	{"id": "boots_of_quick_exits", "name": "Boots of Quick Exits", "slot": "Feet", "effect": "dodge", "value": 15, "flavor": "Snik's own design. Mostly used for leaving."},
]

## A curio made for your depth (never below your average Gear Score).
static func curio(g: GameState) -> Dictionary:
	var def: Dictionary = CURIOS.pick_random()
	var item := GameData.make_unique(def, maxi(1, g.best_floor), g._new_id())
	var avg := g.average_gear_score()
	var gs := GameData.gear_score(item)
	if avg > 0 and gs < avg:
		item["bonus"] = int(ceil(int(item["bonus"]) * float(avg) / maxf(1.0, gs)))
	item["snik"] = true
	return item
