class_name Smith
extends RefCounted
## 0.13+ (Juzo's notes): Hilde Ironbraid, the town's dwarf smith, runs a real shop.
## Her forged wares are made for how deep you've been (Epic, now and then Legendary,
## never below your average Gear Score) and she restocks each time you come home.

const NAME := "Hilde Ironbraid"
const STOCK := 3
const PRICE_MULT := 1.4        # forged work costs more than the shop's
const LEGENDARY_CHANCE := 12.0 # % per piece

## A new stock (called when you get home, and the first time you visit).
static func restock(g: GameState) -> void:
	g.smith_stock = []
	var slots: Array = GameData.SLOT_ORDER.duplicate()
	slots.shuffle()
	var avg := g.average_gear_score()
	for i in STOCK:
		var r := GameData.LEGENDARY if randf() * 100.0 < LEGENDARY_CHANCE else 3
		var item := GameData.make_item(String(slots[i]), r, maxi(1, g.best_floor), g._new_id())
		if r == GameData.LEGENDARY and not item.has("effect"):
			GameData.add_legendary_effect(item)
		var gs := GameData.gear_score(item)
		if avg > 0 and gs < avg:
			item["bonus"] = int(ceil(int(item["bonus"]) * float(avg) / maxf(1.0, gs)))
		item["forged"] = true
		g.smith_stock.append({"item": item, "price": g.price(int(GameData.shop_price(item) * PRICE_MULT)), "sold": false})

## Buy piece i. Returns true if bought.
static func buy(g: GameState, i: int) -> bool:
	if i < 0 or i >= g.smith_stock.size():
		return false
	var e: Dictionary = g.smith_stock[i]
	if e["sold"] or g.gold < int(e["price"]) or g.bag_full():
		return false
	g.gold -= int(e["price"])
	e["sold"] = true
	var item: Dictionary = e["item"]
	g.add_to_wardrobe(item)
	g.codex.found_item(item)
	g.bag.append(item)
	g.bag_version += 1
	g.codex.add("smith_buys")
	g.say("[color=#fbbf24]%s hands you %s.[/color] \"Mind the edge. I don't do refunds for fingers.\"" % [NAME, GameData.display_name(item)])
	g.events.append({"type": "loot", "name": GameData.display_name(item), "rarity": int(item["rarity"]), "item": item})
	g.save_game()
	return true
