class_name PetAbilities
extends RefCounted
## 2.1: what an owned pet can do besides hitting, by its rank. All data, no
## per-pet code:
##  - every pet has its family's PASSIVE (by the monster's shape), stronger at
##    each rank, Common to Mythic,
##  - Epic and up add the family's TRICK (a chance each turn), more often at
##    Legendary and up,
##  - Mythic adds its home region's SIGNATURE (once a fight, or every kill).
## A pet's rank never changes, so the Pet tab shows what a higher-ranked pet of
## the same kind would know as "locked". Pets on the run (Menagerie.out) count;
## hurt or home pets don't. Everything happens on its own, so Auto play uses it.
## See claude/pet-abilities.md.

const TRICK_RANK := 3      # Epic
const TRICK_UP_RANK := 4   # Legendary: the trick goes off more often and hits harder
const SIGNATURE_RANK := 5  # Mythic
const LOW_HP := 0.35       # "low" signatures wait until you're below this much health

## What each rank adds (shown in the Codex).
const RANK_TEXT := [
	"its family's passive",
	"a stronger passive",
	"a stronger passive",
	"its family's trick",
	"the trick more often, and stronger",
	"its region's signature",
]

## Families are the monster's shape. key: what the passive adds (multipliers are
## "hp"/"def" as 1.0 + value/100, the rest add up like gear effects).
## The trick's chance/value: [Epic, Legendary and up].
const FAMILIES := {
	"beast": {"name": "Beast",
		"passive": {"name": "Keen Eye", "key": "crit", "values": [1, 2, 3, 3.5, 4, 5], "text": "+{v}% crit chance"},
		"trick": {"name": "Pounce", "do": "strike", "chance": [15, 22], "value": [1.0, 1.5], "text": "{c}% chance each turn to pounce again for {v}x its hit"}},
	"brute": {"name": "Brute",
		"passive": {"name": "Thick Hide", "key": "hp", "values": [2, 3, 4, 5, 6, 7], "text": "+{v}% max HP"},
		"trick": {"name": "Guard", "do": "shield", "chance": [12, 18], "value": [5, 8], "text": "{c}% chance each turn to shield you for {v}% of your max HP"}},
	"spirit": {"name": "Spirit",
		"passive": {"name": "Soft Glow", "key": "regen", "values": [0.2, 0.3, 0.4, 0.5, 0.6, 0.7], "text": "you heal {v}% of your max HP every turn"},
		"trick": {"name": "Mend", "do": "heal", "chance": [15, 20], "value": [4, 6], "text": "{c}% chance each turn, when you're below half health, to heal you for {v}% of your max HP"}},
	"serpent": {"name": "Serpent",
		"passive": {"name": "Leech", "key": "lifesteal", "values": [1, 1.5, 2, 2.5, 3, 4], "text": "+{v}% lifesteal"},
		"trick": {"name": "Venom", "do": "poison", "chance": [15, 22], "value": [0.5, 0.8], "text": "{c}% chance each turn to poison the monster for {v}x its hit every turn"}},
	"humanoid": {"name": "Folk",
		"passive": {"name": "Sticky Fingers", "key": "gold_find", "values": [3, 5, 7, 8, 10, 12], "text": "+{v}% gold"},
		"trick": {"name": "Pickpocket", "do": "gold", "chance": [15, 22], "value": [25, 40], "text": "{c}% chance each turn to steal {v}% of the monster's gold on top, once a fight"}},
	"calamity": {"name": "Calamity",
		"passive": {"name": "Dread", "key": "def", "values": [6, 6, 6, 6, 6, 6], "text": "+{v}% Defense"},
		"trick": {"name": "Ruin", "do": "strike", "chance": [20, 25], "value": [2.0, 2.0], "text": "{c}% chance each turn to strike again for {v}x its hit"}},
}

## Mythic signatures by region id (claude/stable-ids.md). when: "start" (the
## pet's first turn of every fight; the texts say so), "low" (once a fight, when you drop below LOW_HP) or "kill".
const SIGNATURES := {
	"mossy_hollows": {"name": "Bramble Snare", "when": "start", "do": "stun", "value": 1, "text": "On its first turn each fight, roots hold the monster still for a turn"},
	"sunken_catacombs": {"name": "Grave Chill", "when": "start", "do": "weaken", "value": 25, "text": "On its first turn each fight, chills the monster: it hits {v}% softer for 3 turns"},
	"flooded_depths": {"name": "Undertow", "when": "low", "do": "heal", "value": 15, "text": "Once a fight, when you drop below 35% health, the tide pulls you back: heals {v}% of your max HP"},
	"ember_halls": {"name": "Ember Breath", "when": "start", "do": "burn", "value": 1.0, "text": "On its first turn each fight, breathes fire: the monster burns for {v}x its hit for 3 turns"},
	"the_shadow_deep": {"name": "Shadow Fang", "when": "start", "do": "strike", "value": 3.0, "text": "On its first turn each fight, strikes from the dark for {v}x its hit"},
	"elf": {"name": "Hush of the Wood", "when": "low", "do": "shield", "value": 20, "text": "Once a fight, when you drop below 35% health, the wood hides you: a shield of {v}% of your max HP"},
	"fairy": {"name": "Fairy Gold", "when": "kill", "do": "gold", "value": 100, "text": "Every kill drops its gold twice"},
	"dwarf": {"name": "Ironroot Wall", "when": "start", "do": "shield", "value": 10, "text": "On its first turn each fight, raises a shield of {v}% of your max HP"},
	"angel": {"name": "Gilded Grace", "when": "low", "do": "heal", "value": 25, "text": "Once a fight, when you drop below 35% health, a light heals {v}% of your max HP"},
	"demon": {"name": "Hellfire", "when": "start", "do": "burn", "value": 1.5, "text": "On its first turn each fight, calls hellfire: the monster burns for {v}x its hit for 3 turns"},
	"calamity": {"name": "Echo of the End", "when": "start", "do": "strike", "value": 4.0, "text": "On its first turn each fight, strikes with its parent's fury for {v}x its hit"},
	"": {"name": "Wild Heart", "when": "start", "do": "strike", "value": 2.0, "text": "On its first turn each fight, lunges wildly for {v}x its hit"},
}

static var _home := {}  # species id -> region id (built once)

# =====================================================================
# Who a pet is
# =====================================================================

static func is_calamity(species: String) -> bool:
	return species.begins_with("calamity_") and species.ends_with("_pet")

## The pet's family: its monster's shape ("beast" if unknown).
static func family(species: String) -> String:
	if is_calamity(species):
		return "calamity"
	var s := String(Monsters.by_id(species).get("shape", "beast"))
	return s if FAMILIES.has(s) else "beast"

## The region id a species lives in ("calamity" for a Calamity's pet, "" if none).
static func home(species: String) -> String:
	if is_calamity(species):
		return "calamity"
	if _home.is_empty():
		for z in GameData.ZONES:
			var zid := String(z["id"])
			for e in z["enemies"]:
				_home[String(e["id"])] = zid
			for s in z["subs"]:
				_home[String(s["monster"]["id"])] = zid
			_home[String(z["mid"]["id"])] = zid
			_home[String(z["boss"]["id"])] = zid
	return String(_home.get(species, ""))

static func signature_of(species: String) -> Dictionary:
	var h := home(species)
	return SIGNATURES[h] if SIGNATURES.has(h) else SIGNATURES[""]

static func _rank(p: Dictionary) -> int:
	return clampi(int(p.get("tier", 0)), 0, 5)

static func passive_value(species: String, rank: int) -> float:
	return float(FAMILIES[family(species)]["passive"]["values"][clampi(rank, 0, 5)])

static func _step(rank: int) -> int:
	return 1 if rank >= TRICK_UP_RANK else 0

static func has_trick(p: Dictionary) -> bool:
	return _rank(p) >= TRICK_RANK

static func has_signature(p: Dictionary) -> bool:
	return _rank(p) >= SIGNATURE_RANK

# =====================================================================
# Plain text for the Pet tab and the Codex
# =====================================================================

static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, round(v)) else "%.1f" % v

static func _fill(text: String, v: float, c := 0.0) -> String:
	return text.replace("{v}", _num(v)).replace("{c}", _num(c))

static func passive_text(species: String, rank: int) -> String:
	var a: Dictionary = FAMILIES[family(species)]["passive"]
	return "%s: %s" % [a["name"], _fill(String(a["text"]), passive_value(species, rank))]

static func trick_text(species: String, rank: int) -> String:
	return family_trick_text(family(species), rank)

static func family_trick_text(fam: String, rank: int) -> String:
	var a: Dictionary = FAMILIES[fam]["trick"]
	var st := _step(maxi(rank, TRICK_RANK))
	return "%s: %s" % [a["name"], _fill(String(a["text"]), float(a["value"][st]), float(a["chance"][st]))]

## "Keen Eye: +1 to 5% crit chance" (Common to Mythic)
static func family_passive_range(fam: String) -> String:
	var a: Dictionary = FAMILIES[fam]["passive"]
	var lo := _num(float(a["values"][0]))
	var hi := _num(float(a["values"][5]))
	return "%s: %s" % [a["name"], String(a["text"]).replace("{v}", lo if lo == hi else "%s to %s" % [lo, hi])]

static func signature_text(species: String) -> String:
	return region_signature_text(home(species))

static func region_signature_text(region: String) -> String:
	var a: Dictionary = SIGNATURES[region] if SIGNATURES.has(region) else SIGNATURES[""]
	return "%s: %s" % [a["name"], _fill(String(a["text"]), float(a["value"]))]

## What this pet knows now, and what a higher-ranked one of its kind would add.
## [{"text", "on": bool, "rank": the rank that unlocks it}]
static func lines(p: Dictionary) -> Array:
	var sp := String(p.get("species", ""))
	var r := _rank(p)
	var out: Array = [{"text": passive_text(sp, r), "on": true, "rank": 0}]
	if r < TRICK_RANK:
		out.append({"text": trick_text(sp, TRICK_RANK), "on": false, "rank": TRICK_RANK})
	else:
		out.append({"text": trick_text(sp, r), "on": true, "rank": TRICK_RANK})
		if r < TRICK_UP_RANK:
			out.append({"text": "Stronger %s: %s" % [FAMILIES[family(sp)]["trick"]["name"], trick_text(sp, TRICK_UP_RANK).get_slice(": ", 1)], "on": false, "rank": TRICK_UP_RANK})
	out.append({"text": signature_text(sp), "on": r >= SIGNATURE_RANK, "rank": SIGNATURE_RANK})
	return out

# =====================================================================
# Passives: bonus sources like gear and race (GameState._bonus_sources)
# =====================================================================

const REGEN_CAP := 1.5     # all pets together heal at most this % of max HP a turn
const SHIELD_CAP := 0.5    # pet shields never push your shield past half your max HP

## Pets' passives. Cached on the hero until the team (who's out, their rank) changes:
## this runs on every stat lookup.
static func bonus_sources(g: GameState) -> Array:
	if g.pets.is_empty():
		return []
	var team := Menagerie.out(g)
	var key: Array = []
	for p in team:
		key.append([int(p["id"]), _rank(p), String(p["species"])])
	var cached: Array = g.get_meta("pet_bonus", [])
	if not cached.is_empty() and cached[0] == key:
		return cached[1]
	var out: Array = []
	var regen := 0.0
	for p in team:
		var sp := String(p["species"])
		var k := String(FAMILIES[family(sp)]["passive"]["key"])
		var v := passive_value(sp, _rank(p))
		if k == "regen":
			v = minf(v, REGEN_CAP - regen)
			regen += v
			if v <= 0.0:
				continue
		out.append({k: 1.0 + v / 100.0} if k in ["hp", "def", "atk"] else {k: v})
	g.set_meta("pet_bonus", [key, out])
	return out

## How much regen (% of max HP a turn) this pet really adds once the team cap is applied,
## or -1 if it isn't a Spirit out on the run. The Pet tab says so when the cap cut it.
static func regen_share(g: GameState, p: Dictionary) -> float:
	var regen := 0.0
	for q in Menagerie.out(g):
		var sp := String(q["species"])
		if String(FAMILIES[family(sp)]["passive"]["key"]) != "regen":
			continue
		var v := maxf(0.0, minf(passive_value(sp, _rank(q)), REGEN_CAP - regen))
		regen += v
		if int(q["id"]) == int(p["id"]):
			return v
	return -1.0

## How much of your shield came from pets (auto play still casts its own shield over it).
static func pet_shield(g: GameState) -> int:
	return mini(g.shield_hp, int(g.get_meta("pet_shield", 0)))

# =====================================================================
# In the fight (called from Menagerie)
# =====================================================================

## A new fight: pet shields don't carry over from the last one. Called from
## ClassTree.on_fight_start for every fight (even when no pet came along), and
## again (harmlessly) on a pet's first turn.
static func _fight_start(g: GameState) -> void:
	if g.cfight.get("pet_fight", false):
		return
	g.cfight["pet_fight"] = true
	g.shield_hp -= pet_shield(g)
	g.set_meta("pet_shield", 0)

## After a pet's turn: its signature (once a fight) and its trick (a chance).
## hit: what its normal hit would deal.
static func on_pet_turn(g: GameState, p: Dictionary, hit: int) -> void:
	_fight_start(g)
	var r := _rank(p)
	var id := int(p["id"])
	if r >= SIGNATURE_RANK:
		var sig := signature_of(String(p["species"]))
		var used: Dictionary = g.cfight.get("pet_sig", {})
		var when := String(sig["when"])
		var low := g.hero_hp > 0 and g.hero_hp < int(g.get_max_hp() * LOW_HP)
		if not used.has(id) and (when == "start" or (when == "low" and low)):
			if apply(g, p, String(sig["do"]), float(sig["value"]), hit, String(sig["name"])) or when == "start":
				used[id] = true
				g.cfight["pet_sig"] = used
	if r >= TRICK_RANK and g.enemy_hp > 0:
		var t: Dictionary = FAMILIES[family(String(p["species"]))]["trick"]
		var st := _step(r)
		if String(t["do"]) == "heal" and g.hero_hp * 2 >= g.get_max_hp():
			return  # Mend waits until you need it
		var picked: Dictionary = g.cfight.get("pet_pick", {})
		if String(t["do"]) == "gold" and picked.has(id):
			return  # Pickpocket: once a fight
		if randf() * 100.0 < float(t["chance"][st]) and apply(g, p, String(t["do"]), float(t["value"][st]), hit, String(t["name"])):
			g.feats["pet_tricks"] = int(g.feats.get("pet_tricks", 0)) + 1
			if String(t["do"]) == "gold":
				picked[id] = true
				g.cfight["pet_pick"] = picked

## A kill: "kill" signatures go off.
static func on_kill(g: GameState) -> void:
	for p in Menagerie.out(g):
		if has_signature(p):
			var sig := signature_of(String(p["species"]))
			if String(sig["when"]) == "kill":
				apply(g, p, String(sig["do"]), float(sig["value"]), 0, String(sig["name"]))

## One effect. Returns false if it couldn't happen (you're down, the fight's over).
static func apply(g: GameState, p: Dictionary, what: String, value: float, hit: int, label: String) -> bool:
	var helps_you := what in ["heal", "shield"]
	if helps_you and (g.leader_down or g.hero_hp <= 0):
		return false
	if not helps_you and what != "gold" and g.enemy_hp <= 0:
		return false
	var maxhp := g.get_max_hp()
	match what:
		"strike":
			g.last_hit = "hit"
			var d := g._damage_enemy(maxi(1, int(hit * value)), ["Physical"])
			g.events.append({"type": "summon_hit", "dmg": d, "name": String(p["name"]), "pet": int(p["id"])})
		"shield":
			var add := mini(maxi(1, int(maxhp * value / 100.0)), int(maxhp * SHIELD_CAP) - g.shield_hp)
			if add <= 0:
				return false  # already well shielded
			g.shield_hp += add
			g.set_meta("pet_shield", pet_shield(g) + add)
		"heal":
			var h := maxi(1, int(maxhp * value / 100.0 * g.heal_mult()))
			g.hero_hp = mini(maxhp, g.hero_hp + h)
			g.events.append({"type": "heal", "amount": h})
		"stun":
			g.enemy_stun = maxi(g.enemy_stun, int(value))
			g.events.append({"type": "stunned"})
		"weaken":
			var m := 1.0 - value / 100.0
			g.enemy_weaken = minf(g.enemy_weaken, m) if g.enemy_weaken_turns > 0 else m
			g.enemy_weaken_turns = maxi(g.enemy_weaken_turns, 3)
		"burn":
			# a pet's weaker burn never keeps the hero's stronger one going: it only tops it up to 2 turns
			var bd := maxi(1, int(hit * value))
			if g.burn_turns <= 0 or bd >= g.burn_dmg:
				if g.burn_tag != "Blood" or g.burn_turns <= 0:
					g.burn_tag = "Fire"  # a Blood skill's bleed keeps its tag
				g.burn_dmg = bd
				g.burn_turns = GameData.BURN_TURNS
			else:
				g.burn_turns = maxi(g.burn_turns, 2)
		"poison":
			var pd := maxi(1, int(hit * value))  # pets don't stack it
			if g.enemy_poison_turns <= 0 or pd >= g.enemy_poison_dmg:
				g.enemy_poison_dmg = pd
				g.enemy_poison_turns = Combat.POISON_TURNS
			else:
				g.enemy_poison_turns = maxi(g.enemy_poison_turns, 2)
		"gold":
			# value % of what this kill pays (GameState.kill_gold: the real drop, multipliers and all)
			var gold := maxi(1, int(g.kill_gold() * value / 100.0))
			g._add_gold(gold)
			g.say("[color=#fbbf24]%s's %s: +%d gold.[/color]" % [p["name"], label, gold])
		_:
			return false
	if what != "gold":
		g.events.append({"type": "buff", "name": label})
	return true
