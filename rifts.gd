class_name Rifts
extends RefCounted
## Rifts, one kind of portal (portals.gd has the shared rules). Very rarely a door
## opens on a room with a rift in it. Its depth is rolled when you walk in and shown
## on its card: depth 1 is three rift-touched fights (no running), the last against
## the Vault Keeper, then its vault; depth 3 goes down three pocket floors, each
## tougher, with a short rest between and a much bigger vault at the bottom.
## Floors don't move while you're inside; you step back out to your doors.
## GameState.portal = {"kind": "rift", "depth": d, "floor": f, "left": fights to go}.
## (2.1 F3: Rifts and Deep Rifts are one rift type with a depth; the numbers are unchanged.)

const DOOR_CHANCE := 1.5   # % per door, from FROM_FLOOR
const FROM_FLOOR := 10
const FIGHTS := 3          # fights per rift floor
const HP_MULT := 1.25
const MAX_DEPTH := 3       # the deepest rift: this many pocket floors
const DEEP_CHANCE := 30.0  # % of rifts that are depth MAX_DEPTH, from DEEP_FROM
const DEEP_FROM := 30
const DEPTH_HP_STEP := 0.15  # extra monster HP per pocket floor down

## Maybe turns a rolled door into a rift door.
static func maybe_door(g: GameState, kind: String) -> String:
	if g.floor_num < FROM_FLOOR or GameData.is_boss_floor(g.floor_num + 1) or Portals.inside(g):
		return kind
	return "rift" if randf() * 100.0 < DOOR_CHANCE else kind

## How deep a new rift goes (rolled when its room is entered).
static func roll_depth(g: GameState) -> int:
	return MAX_DEPTH if g.floor_num >= DEEP_FROM and randf() * 100.0 < DEEP_CHANCE else 1

static func depth(g: GameState) -> int:
	return int(g.portal.get("depth", g.portal.get("floors", 1)))  # "floors": saves from before 2.1 F3

## Step through the rift (Portals.choose). d 0: roll the depth now.
static func enter(g: GameState, d := 0) -> void:
	if d <= 0:
		d = roll_depth(g)
	d = clampi(d, 1, MAX_DEPTH)
	g.portal = {"kind": "rift", "depth": d, "floor": 1, "left": FIGHTS}
	g.doors = []
	g.path_offer = []
	g.codex.add("rifts_found")
	g.events.append({"type": "mini_event", "kind": "rift", "title": "RIFT, DEPTH %d" % d,
		"sub": ("%d floors down, and a great vault at the bottom" % d) if d > 1 else "%d fights, and a vault at the end" % FIGHTS})
	g.say("[color=%s]You step through the rift. The dungeon folds shut behind you.[/color]" % Portals.COLOR)
	g.tip("rift", "A rift: fights you can't run from, then a vault. Deeper rifts go down more floors and hold bigger vaults. Floors don't change in here; you come back out where you went in.")
	_next(g)

## After loading a save inside a rift: the fight you were in starts again.
static func resume(g: GameState) -> void:
	if not g.portal.has("depth"):
		g.portal["depth"] = depth(g)
		g.portal.erase("floors")
	g.portal["kind"] = "rift"
	_next(g)

## The next thing in the rift: rift-touched monsters, then the Vault Keeper.
static func _next(g: GameState) -> void:
	var last := int(g.portal.get("left", 0)) <= 1 and int(g.portal.get("floor", 1)) >= depth(g)
	g.exploring = false
	g.spawn_enemy()
	g.horde_left = 0
	g.horde_pack = false
	g.enemy_wanderer = false
	g.enemy_grave = false
	g.hazard = ""
	g.enemy_name = ("Vault Keeper " if last else "Rift-touched ") + Monsters.name_of(g.enemy_species)
	g._apply_tier(Monsters.LEGENDARY if last else Monsters.EPIC)
	g.enemy_max_hp = int(g.enemy_max_hp * (HP_MULT + DEPTH_HP_STEP * (int(g.portal.get("floor", 1)) - 1)))
	g.enemy_hp = g.enemy_max_hp
	g.events.append({"type": "rare_monster", "tier": Monsters.LEGENDARY if last else Monsters.EPIC, "name": g.enemy_name, "mods": g.enemy_mods.duplicate()})
	if last:
		g.say("[color=%s]The Vault Keeper rises in front of a sealed door.[/color]" % Portals.COLOR)

## A fight in the rift is won. Returns true if the rift handled what comes next.
static func on_kill(g: GameState) -> bool:
	if g.portal.is_empty():
		return false
	g.portal["left"] = int(g.portal.get("left", 1)) - 1
	if int(g.portal["left"]) > 0:
		g.say("[color=%s]The rift shifts. %d more.[/color]" % [Portals.COLOR, int(g.portal["left"])])
		_next(g)
		return true
	var pf := int(g.portal.get("floor", 1))
	var d := depth(g)
	if pf < d:  # a deeper rift goes on down
		g.portal["floor"] = pf + 1
		g.portal["left"] = FIGHTS
		g.hero_hp = mini(g.get_max_hp(), g.hero_hp + g.get_max_hp() / 4)
		g.say("[color=%s]A stair of light drops away under you. Rift floor %d of %d.[/color] You catch your breath on the way down." % [Portals.COLOR, pf + 1, d])
		g.events.append({"type": "mini_event", "kind": "rift", "title": "DEEPER", "sub": "Rift floor %d of %d" % [pf + 1, d]})
		_next(g)
		return true
	# The vault (a deeper rift's is much bigger, with one Legendary for sure)
	var gold := (10 + g.floor_num * 8) * 6 * d
	g._add_gold(gold)
	var pieces := 2 + (d - 1) * 2
	for i in pieces:
		var r := maxi(Monsters.EPIC, g._rarity(40 + g._loot_bonus(), GameData.LEGENDARY_CHANCE_BOSS * 2.0))
		if d > 1 and i == 0:
			r = maxi(r, GameData.LEGENDARY)
		g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
	Economy.give_dust(g, Economy.VAULT_DUST_PER_FLOOR * d)
	g.codex.add("rifts")
	if d >= MAX_DEPTH:
		g.codex.add("deep_rifts")  # stable id; shown as "depth 3 rifts cleared"
	ClassTree.count(g, "rifts")
	g.say("[color=#fbbf24]The vault opens:[/color] +%d gold, %d fine pieces of gear and dust." % [gold, pieces])
	g.events.append({"type": "treasure"})
	g.events.append({"type": "mini_event", "kind": "rift", "title": "THE VAULT", "sub": "The rift lets you go"})
	Portals.leave(g, true)
	g._room_cleared()
	return true
