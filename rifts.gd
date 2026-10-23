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
## Next update (Juzo): bigger portals. A Deep Rift goes down DEEP_FLOORS pocket floors,
## each tougher; a short rest between them and a much bigger vault at the bottom.
const DEEP_CHANCE := 30.0   # % of rifts from DEEP_FROM
const DEEP_FROM := 30
const DEEP_FLOORS := 3
const DEEP_HP_STEP := 0.15  # extra monster HP per pocket floor down

## Maybe turns a rolled door into a rift door.
static func maybe_door(g: GameState, kind: String) -> String:
	if g.floor_num < FROM_FLOOR or GameData.is_boss_floor(g.floor_num + 1) or g.trial_active:
		return kind
	return "rift" if randf() * 100.0 < DOOR_CHANCE else kind

## Step through the rift.
static func enter(g: GameState) -> void:
	var deep := g.floor_num >= DEEP_FROM and randf() * 100.0 < DEEP_CHANCE
	g.portal = {"left": FIGHTS, "floor": 1, "floors": DEEP_FLOORS if deep else 1}
	g.doors = []
	g.path_offer = []
	g.codex.add("rifts_found")
	g.events.append({"type": "portal"})
	g.events.append({"type": "mini_event", "kind": "rift", "title": "DEEP RIFT" if deep else "HIDDEN PORTAL", "sub": ("%d floors of the rift, and a great vault at the bottom" % DEEP_FLOORS) if deep else "Three fights in the rift, and a vault at the end"})
	g.say("[color=#c4b5fd]You step through the rift. The dungeon folds shut behind you.[/color]")
	g.tip("rift", "A hidden portal: three fights you can't run from, then a vault. Floors don't change in here; you come back out where you went in.")
	_next(g)

## The next thing in the rift: rift-touched monsters, then the Vault Keeper.
static func _next(g: GameState) -> void:
	var last := int(g.portal.get("left", 0)) <= 1 and int(g.portal.get("floor", 1)) >= int(g.portal.get("floors", 1))
	g.exploring = false
	g.spawn_enemy()
	g.horde_left = 0
	g.horde_pack = false
	g.enemy_wanderer = false
	g.enemy_grave = false
	g.hazard = ""
	g.enemy_name = ("Vault Keeper " if last else "Rift-touched ") + Monsters.name_of(g.enemy_species)
	g._apply_tier(Monsters.LEGENDARY if last else Monsters.EPIC)
	g.enemy_max_hp = int(g.enemy_max_hp * (HP_MULT + DEEP_HP_STEP * (int(g.portal.get("floor", 1)) - 1)))
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
	var pf := int(g.portal.get("floor", 1))
	var floors := int(g.portal.get("floors", 1))
	if pf < floors:  # next update: a Deep Rift goes on down
		g.portal["floor"] = pf + 1
		g.portal["left"] = FIGHTS
		g.hero_hp = mini(g.get_max_hp(), g.hero_hp + g.get_max_hp() / 4)
		g.say("[color=#c4b5fd]A stair of light drops away under you. Rift floor %d of %d.[/color] You catch your breath on the way down." % [pf + 1, floors])
		g.events.append({"type": "mini_event", "kind": "rift", "title": "DEEPER", "sub": "Rift floor %d of %d" % [pf + 1, floors]})
		_next(g)
		return true
	# The vault (a Deep Rift's is much bigger, with one Legendary for sure)
	var gold := (10 + g.floor_num * 8) * 6 * floors
	g._add_gold(gold)
	var pieces := 2 + (floors - 1) * 2
	for i in pieces:
		var r := maxi(Monsters.EPIC, g._rarity(40 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS * 2.0))
		if floors > 1 and i == 0:
			r = maxi(r, GameData.LEGENDARY)
		g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
	g._give_materials(3 * floors)
	g.codex.add("rifts")
	if floors > 1:
		g.codex.add("deep_rifts")
	ClassTree.count(g, "rifts")
	g.say("[color=#fbbf24]The vault opens:[/color] +%d gold, %d fine pieces of gear and materials." % [gold, pieces])
	g.events.append({"type": "treasure"})
	g.events.append({"type": "mini_event", "kind": "rift", "title": "THE VAULT", "sub": "The rift lets you go"})
	Halls.leave_portal(g, true)
	g._room_cleared()
	return true
