class_name Grave
extends RefCounted
## 0.13+ (Stage 3): falling no longer destroys what you carried. It drops where you
## fell, and the monster that killed you guards it, wearing your gear. Reach that
## floor again and beat it to get everything back. One grave at a time: falling again
## somewhere else leaves a new grave and the old one crumbles (dying to the guardian
## itself keeps everything together in the new one). Bound items never drop at all.

const GOLD_PART := 0.5       # half the carried gold falls into the grave (the rest is gone)
const GUARD_HP := 1.4        # the guardian is tougher than it was
const GUARD_ATK := 1.15

## Called as you fall, before the losses are taken. Builds the grave.
static func on_death(g: GameState) -> void:
	if g.hardcore or g.trial_active or g.enemy_calamity > 0 or g.enemy_goblin:
		return
	var items: Array = []
	for it in g.bag:
		if not GameState.is_bound(it):
			items.append((it as Dictionary).duplicate(true))
	for s in g.equipped:
		var it: Dictionary = g.equipped[s]
		if not GameState.is_bound(it):
			items.append(it.duplicate(true))
	var gold := int(g.gold * GOLD_PART)
	var old: Dictionary = g.grave
	var by_guard := g.enemy_grave and not old.is_empty()
	if by_guard:
		# you fell to the guardian: everything stays together, it keeps guarding
		items.append_array(old.get("items", []))
		gold += int(old.get("gold", 0))
	elif not old.is_empty():
		g.say("[color=#9ca3af]Your old grave on floor %d crumbles to dust, and what was in it with it.[/color]" % int(old["floor"]))
	if items.is_empty() and gold <= 0:
		g.grave = {}
		return
	var killer := String(old["killer"]) if by_guard else g.enemy_species
	g.grave = {"floor": g.floor_num, "killer": killer, "name": String(old["name"]) if by_guard else g.enemy_name,
		"boss": bool(old["boss"]) if by_guard else g.enemy_is_boss,
		"art": String(old["art"]) if by_guard else g.enemy_art, "shape": String(old["shape"]) if by_guard else g.enemy_shape,
		"color": String(old["color"]) if by_guard else g.enemy_color, "items": items, "gold": gold}
	g.events.append({"type": "toast", "text": "Your things lie on floor %d. The %s guards them." % [g.floor_num, killer]})
	g.tip("grave", "When you fall, what you carried drops where you fell and your killer guards it. Come back to that floor and beat it to get it all back. Fall somewhere else first and the old grave is lost.")

## The grave's guardian is due on this floor's first fight (no pack rolls then).
static func due(g: GameState) -> bool:
	return not g.grave.is_empty() and int(g.grave["floor"]) == g.floor_num and g.fight == 1 and not bool(g.grave["boss"]) and not g.trial_active

## True when the grave is on this floor and its guardian should be the next monster.
static func guarding_here(g: GameState) -> bool:
	if g.grave.is_empty() or g.trial_active or g.enemy_goblin or g.horde_left > 0:
		return false
	if int(g.grave["floor"]) != g.floor_num:
		return false
	# A boss guards its grave in its own fight; anyone else steps in as the floor's first monster
	return g.enemy_is_boss if bool(g.grave["boss"]) else (g.fight == 1 and not g.enemy_is_boss)

## Turns the monster just spawned into the guardian (called at the end of spawn_enemy).
static func make_guard(g: GameState) -> void:
	if not guarding_here(g):
		return
	g.enemy_grave = true
	if not bool(g.grave["boss"]):
		g.enemy_species = String(g.grave["killer"])
		g.enemy_name = String(g.grave["name"])
		g.enemy_art = String(g.grave["art"])
		g.enemy_shape = String(g.grave["shape"])
		g.enemy_color = String(g.grave["color"])
		g._apply_tier(maxi(g.enemy_tier, Monsters.RARE))
	g.enemy_max_hp = int(g.enemy_max_hp * GUARD_HP)
	g.enemy_hp = g.enemy_max_hp
	g.enemy_attack = int(g.enemy_attack * GUARD_ATK)
	g.events.append({"type": "mini_event", "kind": "grave", "title": "YOUR KILLER", "sub": "It guards what you lost (%d items)" % (g.grave["items"] as Array).size()})
	g.say("[color=#f59e0b]The %s that killed you is here, wearing your gear. Beat it to take it all back.[/color]" % String(g.grave["killer"]))

## Beat the guardian: everything comes back (to the bag, or the Mailbox if it's full).
static func recover(g: GameState) -> void:
	if not g.enemy_grave or g.grave.is_empty():
		return
	g.enemy_grave = false
	var items: Array = g.grave.get("items", [])
	var gold := int(g.grave.get("gold", 0))
	var to_mail: Array = []
	for it in items:
		if g.bag_full():
			to_mail.append(it)
		else:
			g.bag.append(it)
	g.bag_version += 1
	if gold > 0:
		g._add_gold(gold)
	if not to_mail.is_empty():
		Mail.post(g, "Your grave", "What your bag couldn't hold", "Recovered from the %s on floor %d." % [String(g.grave["killer"]), int(g.grave["floor"])], {"items": to_mail})
	g.codex.add("graves")
	ClassTree.count(g, "graves_recovered")
	g.say("[color=#4ade80]You take back what you lost:[/color] %d item%s%s%s." % [items.size(), "" if items.size() == 1 else "s",
		(", %d gold" % gold) if gold > 0 else "", (" (%d sent to the Mailbox)" % to_mail.size()) if not to_mail.is_empty() else ""])
	g.events.append({"type": "mini_event", "kind": "grave", "title": "RECOVERED!", "sub": "%d items back from the %s" % [items.size(), String(g.grave["killer"])]})
	g.events.append({"type": "treasure"})
	g.grave = {}

## For the Next: line and the floor picker.
static func goal(g: GameState) -> Dictionary:
	if g.grave.is_empty():
		return {}
	return {"text": "Your gear: floor %d, guarded by the %s" % [int(g.grave["floor"]), String(g.grave["killer"])], "pct": -1.0, "color": Color("#f59e0b")}
