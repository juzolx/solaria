class_name Menagerie
extends RefCounted
## Owned pets (0.12). Separate from the class companion (World.PETS), which some
## classes get for free. Owned pets come from:
##  - a Beast Tamer catching a monster whose run-away chance is over 80%,
##  - hatching an egg (eggs come mostly from quests; the pet inside is random),
##  - later: killing a Calamity.
## A Beast Tamer brings up to 3 pets on a run, anyone else 1. Pets are never
## lost: when they go down they come home hurt and rest (or get healed at the
## Clinic) before they can fight again.
##
## A pet: {"id", "name", "species", "art", "tier", "level", "kills", "hurt": floors left to rest (0 = fine), "from"}
## An egg: {"id", "floors": floors left until it hatches, "from"}

const TAMER_OUT := 3
const OTHERS_OUT := 1
const CATCH_AT := 80.0          # the monster's run-away chance must be over this
const CATCH_BASE := 12.0        # % to catch right at the line, +3% per point above it (next update: rarer)
const CATCH_PER_POINT := 3.0
const WHISPER_CATCH := 20.0     # a Beast Whisperer on the team calms the beast first
const WHISPER_POWER := 1.25     # and pets fight harder with their song
const HEAL_FLOORS := 10         # a hurt pet rests this many cleared floors
const HEAL_COST := 40           # gold per floor of rest left, x the pet's level (Clinic)
const EGG_FLOORS := 10          # an egg hatches after this many cleared floors
const MAX_LEVEL := 50
const KILLS_PER_LEVEL := 40
const POWER_BASE := 0.08        # x your Attack per hit
const POWER_PER_TIER := 0.03
const POWER_PER_LEVEL := 0.004
const EGG_SPARE_CHANCE := 0.15  # % chance a spared beast leaves an egg behind (next update: pets are a real find)
const EGG_SNIK_CHANCE := 1.0    # % chance Snik has an egg for sale
const EGG_BOUNTY_CHANCE := 1.5  # % chance a WANTED poster pays with an egg too

static func is_tamer(g: GameState) -> bool:
	return g.hidden_class == "beast_tamer"

static func is_whisperer(g: GameState) -> bool:
	return g.hidden_class == "beast_tamer" and Hidden.stage(g) >= 2  # Beast Lord and up (the old branch-off was cut, Oct 20)

## A Beast Whisperer is you, or fights beside you.
static func whisperer_near(g: GameState) -> bool:
	if is_whisperer(g):
		return true
	if g.party != null:
		for m in g.party.members:
			if is_whisperer(m.hero):
				return true
	return false

static func max_out(g: GameState) -> int:
	return TAMER_OUT if is_tamer(g) else OTHERS_OUT

static func find(g: GameState, id: int) -> Dictionary:
	for p in g.pets:
		if int(p["id"]) == id:
			return p
	return {}

## Pets coming on this run (healthy and picked).
static func out(g: GameState) -> Array:
	var list: Array = []
	for id in g.pets_out:
		var p := find(g, int(id))
		if not p.is_empty() and int(p["hurt"]) <= 0:
			list.append(p)
	return list.slice(0, max_out(g))

static func toggle_out(g: GameState, id: int) -> bool:
	var p := find(g, id)
	if p.is_empty():
		return false
	if id in g.pets_out:
		g.pets_out.erase(id)
		return true
	if int(p["hurt"]) > 0:
		return false
	# 0.13+ (Juzo): pets swap: with every spot taken, the one out longest goes home
	while g.pets_out.size() >= max_out(g) and not g.pets_out.is_empty():
		g.pets_out.remove_at(0)
	g.pets_out.append(id)
	return true

static func make_pet(g: GameState, monster: String, art: String, tier: int, from: String) -> Dictionary:
	var p := {"id": g._new_id(), "name": monster, "species": monster, "art": art, "tier": clampi(tier, 0, 5),
		"level": 1, "kills": 0, "hurt": 0, "from": from}
	g.pets.append(p)
	if g.pets_out.size() < max_out(g):
		g.pets_out.append(int(p["id"]))
	g.codex.add("pets")
	if g.codex.found_pet(str(p["species"]), int(p["tier"])):  # next update: the first of its kind gets a fanfare
		if from == "egg":
			p["new_kind"] = true  # hatch() shows the fanfare itself
		else:
			g.events.append({"type": "first_find", "kind": "pet", "name": str(p["species"]), "tier": int(p["tier"]), "art": art})
	return p

static func power(p: Dictionary) -> float:
	return POWER_BASE + POWER_PER_TIER * int(p["tier"]) + POWER_PER_LEVEL * int(p["level"])

# =====================================================================
# Catching (Beast Tamer only)
# =====================================================================

## Why you can't try to catch this monster ("" = you can).
static func catch_block(g: GameState) -> String:
	if not is_tamer(g):
		return "Only a tamer can catch monsters"
	if g.enemy_hp <= 0 or g.hero_hp <= 0 or g.leader_down:
		return "Not now"
	if g.enemy_calamity > 0 or g.enemy_is_boss or g.enemy_goblin or g.horde_left > 0:
		return "It won't be caught"
	if g.enemy_people != "":
		return "People can't be tamed"
	if Lineage.escape_chance(g) <= CATCH_AT:
		return "It's too strong to catch. Get stronger first"
	return ""

## Shows the Catch button: a tamer facing a monster that could be caught.
static func can_catch(g: GameState) -> bool:
	return catch_block(g) == ""

static func catch_chance(g: GameState) -> float:
	var c := CATCH_BASE + (Lineage.escape_chance(g) - CATCH_AT) * CATCH_PER_POINT
	if whisperer_near(g):
		c += WHISPER_CATCH
	return clampf(c, 5.0, 95.0)

## Try to catch the monster. Returns true if it joins you.
static func try_catch(g: GameState) -> bool:
	if not can_catch(g):
		return false
	var helper := whisperer_near(g)
	if randf() * 100.0 < catch_chance(g):
		var p := make_pet(g, g.enemy_species if g.enemy_species != "" else g.enemy_name, g.enemy_art, g.enemy_tier, "caught")
		g.say("[color=#d9a066]%sThe %s stops fighting and follows you.[/color] It's your pet now%s." % [
			"Your Beast Whisperer hums it calm. " if helper else "", p["species"], "" if int(p["id"]) in g.pets_out else " (waiting at home: your team is full)"])
		g.events.append({"type": "mini_event", "kind": "pet", "title": "CAUGHT!", "sub": "%s joins you" % p["species"]})
		g.feats["caught"] = int(g.feats.get("caught", 0)) + 1
		g.tip("caught", "Pets fight beside you and grow with every kill. Pick who comes along in Hero > Pets. Pets are never lost: when they go down they come home hurt and rest.")
		Lineage._move_on(g)
		return true
	g.say("[color=#f87171]The %s slips your grip and lashes out![/color]" % g.enemy_name)
	g.events.append({"type": "escape_failed"})
	g.free_hit()
	return false

# =====================================================================
# In the fight
# =====================================================================

## Each healthy pet on the run attacks. Called once per turn.
static func turn(g: GameState) -> void:
	if g.enemy_hp <= 0:
		return
	var song := WHISPER_POWER if whisperer_near(g) else 1.0
	for p in out(g):
		if g.enemy_hp <= 0:
			break
		g.last_hit = "hit"
		var d := g._damage_enemy(maxi(1, int(g.get_attack() * power(p) * song * g.party_mult())), ["Physical"])
		g.events.append({"type": "summon_hit", "dmg": d, "name": String(p["name"])})

## A kill: every pet on the run learns from it.
static func on_kill(g: GameState) -> void:
	for p in out(g):
		p["kills"] = int(p["kills"]) + 1
		if int(p["level"]) < MAX_LEVEL and int(p["kills"]) >= int(p["level"]) * KILLS_PER_LEVEL:
			p["level"] = int(p["level"]) + 1
			g.say("[color=#d9a066]%s grows stronger (level %d).[/color]" % [p["name"], int(p["level"])])

## The team went down (or you fell): pets on the run come home hurt. Never lost.
static func on_wipe(g: GameState) -> String:
	var hurt: Array = []
	for p in out(g):
		p["hurt"] = HEAL_FLOORS
		hurt.append(String(p["name"]))
	return "" if hurt.is_empty() else "%s came home hurt" % ", ".join(hurt)

## A cleared floor: hurt pets rest, eggs get closer to hatching.
static func on_floor(g: GameState) -> void:
	for p in g.pets:
		if int(p["hurt"]) > 0:
			p["hurt"] = int(p["hurt"]) - 1
			if int(p["hurt"]) == 0:
				g.say("[color=#4ade80]%s has rested and is ready to fight again.[/color]" % p["name"])
	for e in g.eggs.duplicate():
		e["floors"] = int(e["floors"]) - 1
		if int(e["floors"]) <= 0:
			g.eggs.erase(e)
			hatch(g, e)

# =====================================================================
# Eggs
# =====================================================================

static func give_egg(g: GameState, from: String) -> void:
	var egg := {"id": g._new_id(), "floors": EGG_FLOORS, "from": from}
	EggQuests.assign(egg)  # a little care before it hatches
	g.eggs.append(egg)
	g.say("[color=#fde68a]You got an egg![/color] Something inside is moving. It hatches after %d floors." % EGG_FLOORS)
	g.events.append({"type": "toast", "text": "An egg! It hatches in %d floors." % EGG_FLOORS})
	g.tip("egg", "Eggs hatch after a few cleared floors, and anything could be inside. Any hero can keep the pet.")

## A random pet: any monster from the zones (most eggs don't care what's inside).
static func hatch(g: GameState, egg := {}) -> Dictionary:
	var pool := Monsters.all_monsters()
	var name := ""
	var art := ""
	for _try in 12:
		name = String(pool.pick_random())
		art = Sprites.enemy_key(name, false)
		if not Sprites.enemy_by_key(art).is_empty():
			break
	var roll := randf() * 100.0
	var tier := roll_tier()
	var cherished := EggQuests.done(egg)
	if cherished:
		tier = mini(5, maxi(tier + 1, Monsters.RARE))  # its quest was done: it hatches stronger (a Legendary can turn Mythic)
	var p := make_pet(g, name, art, tier, "egg")
	if cherished:
		p["cherished"] = true
		g.codex.add("cherished_pets")
	g.say("[color=#fde68a]Your egg hatches: a %sbaby %s![/color]" % ["Cherished " if cherished else "", name])
	g.events.append({"type": "hatch_moment", "name": name, "art": art, "cherished": cherished, "tier": tier, "first": p.has("new_kind")})
	p.erase("new_kind")
	g.events.append({"type": "mini_event", "kind": "pet", "title": "IT HATCHED!", "sub": ("A Cherished baby %s" if cherished else "A baby %s") % name})
	return p

# =====================================================================
# The Clinic
# =====================================================================

static func heal_cost(p: Dictionary) -> int:
	return int(p["hurt"]) * HEAL_COST * maxi(1, int(p["level"]))

static func heal(g: GameState, id: int) -> bool:
	var p := find(g, id)
	if p.is_empty() or int(p["hurt"]) <= 0:
		return false
	var cost := heal_cost(p)
	if g.gold < cost:
		return false
	g.gold -= cost
	p["hurt"] = 0
	g.say("[color=#4ade80]The Clinic patches up %s.[/color] (%d gold)" % [p["name"], cost])
	g.save_game()
	return true

static func rename(g: GameState, id: int, new_name: String) -> void:
	var p := find(g, id)
	new_name = new_name.strip_edges().left(18)
	if not p.is_empty() and new_name != "":
		p["name"] = new_name
		g.save_game()

## Anyone with a pet (or an egg) sees the Clinic in town.
static func has_any(g: GameState) -> bool:
	return not g.pets.is_empty() or not g.eggs.is_empty()

## The picture for a pet (its monster art), or null.
static func texture(p: Dictionary) -> Texture2D:
	var e := Sprites.enemy_by_key(String(p.get("art", "")))
	return e.get("tex", null)

const TIER_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]

## Next update: hatch odds. Pets are a real find, and a Mythic is a legend.
const HATCH_ODDS := [50.0, 28.0, 14.0, 6.0, 1.7, 0.3]   # Common .. Mythic, in %

static func roll_tier() -> int:
	var roll := randf() * 100.0
	for t in HATCH_ODDS.size():
		roll -= float(HATCH_ODDS[t])
		if roll < 0.0:
			return t
	return 0

## Next update (Juzo): let a pet go. It's gone from your pets for good, but the
## Codex remembers you had one. Returns false if it isn't yours.
static func release(g: GameState, id: int) -> bool:
	var p := find(g, id)
	if p.is_empty():
		return false
	g.pets.erase(p)
	g.pets_out.erase(id)
	g.say("[color=#d9a066]%s looks back once, then runs off into the wild.[/color]" % p["name"])
	g.save_game()
	return true

const TIER_COLORS := ["#cbd5e1", "#4ade80", "#60a5fa", "#c084fc", "#f59e0b", "#f43f5e"]
