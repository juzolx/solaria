class_name Rifts
extends RefCounted
## 0.13+ (Stage 3): hidden portals. Very rarely a door opens on a room with a rift
## in it. Step through and you're in a pocket of the dungeon that isn't on any map:
## three rift-touched fights (no running), the last against the Vault Keeper, then
## its vault. Floors don't move while you're inside; you step back out to your doors.
## GameState.portal = {"left": fights still to go} while you're in one.

const DOOR_CHANCE := 1.5   # % per door, from FROM_FLOOR
const FROM_FLOOR := 10
const FIGHTS := 3
const HP_MULT := 1.25

## Maybe turns a rolled door into a rift door.
static func maybe_door(g: GameState, kind: String) -> String:
	if g.floor_num < FROM_FLOOR or GameData.is_boss_floor(g.floor_num + 1) or g.trial_active:
		return kind
	return "rift" if randf() * 100.0 < DOOR_CHANCE else kind

## Step through the rift.
static func enter(g: GameState) -> void:
	g.portal = {"left": FIGHTS}
	g.doors = []
	g.path_offer = []
	g.codex.add("rifts_found")
	g.events.append({"type": "portal"})
	g.events.append({"type": "mini_event", "kind": "rift", "title": "HIDDEN PORTAL", "sub": "Three fights in the rift, and a vault at the end"})
	g.say("[color=#c4b5fd]You step through the rift. The dungeon folds shut behind you.[/color]")
	g.tip("rift", "A hidden portal: three fights you can't run from, then a vault. Floors don't change in here; you come back out where you went in.")
	_next(g)

## The next thing in the rift: rift-touched monsters, then the Vault Keeper.
static func _next(g: GameState) -> void:
	var last := int(g.portal.get("left", 0)) <= 1
	g.exploring = false
	g.spawn_enemy()
	g.horde_left = 0
	g.horde_pack = false
	g.enemy_wanderer = false
	g.enemy_grave = false
	g.hazard = ""
	g.enemy_name = ("Vault Keeper " if last else "Rift-touched ") + g.enemy_species
	g._apply_tier(Monsters.LEGENDARY if last else Monsters.EPIC)
	g.enemy_max_hp = int(g.enemy_max_hp * HP_MULT)
	g.enemy_hp = g.enemy_max_hp
	g.events.append({"type": "rare_monster", "tier": Monsters.LEGENDARY if last else Monsters.EPIC, "name": g.enemy_name, "mods": g.enemy_mods.duplicate()})
	if last:
		g.say("[color=#c4b5fd]The Vault Keeper rises in front of a sealed door.[/color]")

## A fight in the rift is won. Returns true if the rift handled what comes next.
static func on_kill(g: GameState) -> bool:
	if g.portal.is_empty():
		return false
	g.portal["left"] = int(g.portal.get("left", 1)) - 1
	if int(g.portal["left"]) > 0:
		g.say("[color=#c4b5fd]The rift shifts. %d more.[/color]" % int(g.portal["left"]))
		_next(g)
		return true
	# The vault
	var gold := (10 + g.floor_num * 8) * 6
	g._add_gold(gold)
	for i in 2:
		var r := maxi(Monsters.EPIC, g._rarity(40 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS * 2.0))
		g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
	g._give_materials(3)
	g.codex.add("rifts")
	ClassTree.count(g, "rifts")
	g.say("[color=#fbbf24]The vault opens:[/color] +%d gold, two fine pieces of gear and materials." % gold)
	g.events.append({"type": "treasure"})
	g.events.append({"type": "mini_event", "kind": "rift", "title": "THE VAULT", "sub": "The rift lets you go"})
	Halls.leave_portal(g, true)
	g._room_cleared()
	return true
