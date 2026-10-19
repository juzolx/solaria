class_name Camp
extends RefCounted
## 0.13+ (Stage 3): dungeon towns, small ones. After every boss, one door opens on a
## Descenders' Camp: you rest by its fire, Snik has a stall, and a courier will carry
## your gold home to the Bank (for a cut) so a fall can't take it.

const COURIER_CUT := 0.1

## Walking in: the fire heals you, Snik sets up shop.
static func enter(g: GameState) -> void:
	g.hero_hp = g.get_max_hp()
	g.skill_cds.clear()
	g.hero_status.clear()
	g.hero_stacks.clear()
	g._make_merchant()
	g.codex.add("camps")
	g.say("[color=#fbbf24]A Descenders' Camp.[/color] Tents, a fire, a courier and Snik. You rest and feel whole again.")
	g.events.append({"type": "mini_event", "kind": "camp", "title": "DESCENDERS' CAMP", "sub": "Rest, trade, and send your gold home"})
	g.tip("camp", "Camps wait after bosses: rest, trade with Snik, and pay the courier to carry your gold home where a fall can't take it.")

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
