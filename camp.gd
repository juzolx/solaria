class_name Camp
extends RefCounted
## 0.13+ (Stage 3): dungeon towns, small ones. After every boss, one door opens on a
## Descenders' Camp: you rest by its fire, Snik has a stall, and a courier will carry
## your gold home to the Bank (for a cut) so a fall can't take it.

const COURIER_CUT := 0.1

## Walking in: the fire heals you (Snik no longer comes to camps: he is rarer now).
static func enter(g: GameState) -> void:
	g.hero_hp = g.get_max_hp()
	g.skill_cds.clear()
	g.hero_status.clear()
	g.hero_stacks.clear()
	g.codex.add("camps")
	g.say("[color=#fbbf24]A Descenders' Camp.[/color] Tents, a fire, a quartermaster and a courier. You rest and feel whole again.")
	g.events.append({"type": "mini_event", "kind": "camp", "title": "DESCENDERS' CAMP", "sub": "Rest, restock potions, send your gold home"})
	g.tip("camp", "Camps wait after bosses: rest, buy potions from the quartermaster, and pay the courier to carry your gold home where a fall can't take it.")

## What the courier would bank (after the cut).
static func courier_amount(g: GameState) -> int:
	return int(g.gold * (1.0 - COURIER_CUT))

## Send the gold you carry home. Returns what reached the Bank.
static func send_home(g: GameState) -> int:
	if g.gold <= 0:
		return 0
	var safe := courier_amount(g)
	g.bank += safe
	g.say("[color=#4ade80]The courier sets off with your gold.[/color] %d reaches the Bank (%d was his cut)." % [safe, g.gold - safe])
	g.gold = 0
	g.codex.add("couriers")
	g.save_game()
	return safe

const POTION_PACK := 3
## The quartermaster's potions (Snik doesn't come to camps any more: he's rarer now).
static func potion_price(g: GameState) -> int:
	return g.price(GameData.POTION_GOLD * POTION_PACK)

static func buy_potions(g: GameState) -> bool:
	var p := potion_price(g)
	if g.gold < p:
		return false
	g.gold -= p
	g.potions += POTION_PACK
	g.say("The quartermaster hands over %d potions." % POTION_PACK)
	g.save_game()
	return true
