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
		"passive": {"name": "Keen Eye", "key": "crit", "values": [1, 2, 3, 3, 4, 5], "text": "+{v}% crit chance"},
		"trick": {"name": "Pounce", "do": "strike", "chance": [15, 22], "value": [1.0, 1.5], "text": "{c}% chance each turn to pounce again for {v}x its hit"}},
	"brute": {"name": "Brute",
		"passive": {"name": "Thick Hide", "key": "hp", "values": [2, 3, 4, 5, 6, 7], "text": "+{v}% max HP"},
		"trick": {"name": "Guard", "do": "shield", "chance": [12, 18], "value": [5, 8], "text": "{c}% chance each turn to shield you for {v}% of your max HP"}},
	"spirit": {"name": "Spirit",
		"passive": {"name": "Soft Glow", "key": "regen", "values": [0.2, 0.3, 0.4, 0.5, 0.6, 0.7], "text": "you heal {v}% of your max HP every turn"},
		"trick": {"name": "Mend", "do": "heal", "chance": [20, 30], "value": [5, 8], "text": "{c}% chance each turn, when you're below half health, to heal you for {v}% of your max HP"}},
	"serpent": {"name": "Serpent",
		"passive": {"name": "Leech", "key": "lifesteal", "values": [1, 1, 2, 2, 3, 3], "text": "+{v}% lifesteal"},
		"trick": {"name": "Venom", "do": "poison", "chance": [15, 22], "value": [0.5, 0.8], "text": "{c}% chance each turn to poison the monster for {v}x its hit every turn"}},
	"humanoid": {"name": "Folk",
		"passive": {"name": "Sticky Fingers", "key": "gold_find", "values": [3, 5, 7, 8, 10, 12], "text": "+{v}% gold"},
		"trick": {"name": "Pickpocket", "do": "gold", "chance": [15, 22], "value": [3, 5], "text": "{c}% chance each turn to steal a little gold ({v}x the floor's coin)"}},
	"calamity": {"name": "Calamity",
		"passive": {"name": "Dread", "key": "def", "values": [6, 6, 6, 6, 6, 6], "text": "+{v}% Defense"},
		"trick": {"name": "Ruin", "do": "strike", "chance": [20, 25], "value": [2.0, 2.0], "text": "{c}% chance each turn to strike again for {v}x its hit"}},
}

## Mythic signatures by region id (claude/stable-ids.md). when: "start" (its
## first turn of every fight), "low" (once a fight, when you drop low) or "kill".
const SIGNATURES := {
	"mossy_hollows": {"name": "Bramble Snare", "when": "start", "do": "stun", "value": 1, "text": "Roots hold every monster still for its first turn"},
	"sunken_catacombs": {"name": "Grave Chill", "when": "start", "do": "weaken", "value": 25, "text": "Every monster starts the fight chilled: it hits {v}% softer for 3 turns"},
	"flooded_depths": {"name": "Undertow", "when": "low", "do": "heal", "value": 15, "text": "Once a fight, when you drop low, the tide pulls you back: heals {v}% of your max HP"},
	"ember_halls": {"name": "Ember Breath", "when": "start", "do": "burn", "value": 1.0, "text": "Opens every fight with fire: the monster burns for {v}x its hit for 3 turns"},
	"the_shadow_deep": {"name": "Shadow Fang", "when": "start", "do": "strike", "value": 3.0, "text": "Opens every fight from the dark for {v}x its hit"},
	"elf": {"name": "Hush of the Wood", "when": "low", "do": "shield", "value": 20, "text": "Once a fight, when you drop low, the wood hides you: a shield of {v}% of your max HP"},
	"fairy": {"name": "Fairy Gold", "when": "kill", "do": "gold", "value": 3, "text": "Every kill shakes loose extra gold ({v}x the floor's coin)"},
	"dwarf": {"name": "Ironroot Wall", "when": "start", "do": "shield", "value": 10, "text": "Every fight starts behind a shield of {v}% of your max HP"},
	"angel": {"name": "Gilded Grace", "when": "low", "do": "heal", "value": 25, "text": "Once a fight, when you drop low, a light heals {v}% of your max HP"},
	"demon": {"name": "Hellfire", "when": "start", "do": "burn", "value": 1.5, "text": "Opens every fight with hellfire: the monster burns for {v}x its hit for 3 turns"},
	"calamity": {"name": "Echo of the End", "when": "start", "do": "strike", "value": 4.0, "text": "Opens every fight with its parent's fury for {v}x its hit"},
	"": {"name": "Wild Heart", "when": "start", "do": "strike", "value": 2.0, "text": "Opens every fight with a wild lunge for {v}x its hit"},
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

static func bonus_sources(g: GameState) -> Array:
	var out: Array = []
	if g.pets.is_empty():
		return out
	for p in Menagerie.out(g):
		var sp := String(p["species"])
		var key := String(FAMILIES[family(sp)]["passive"]["key"])
		var v := passive_value(sp, _rank(p))
		out.append({key: 1.0 + v / 100.0} if key in ["hp", "def", "atk"] else {key: v})
	return out

# =====================================================================
# In the fight (called from Menagerie)
# =====================================================================

## After a pet's turn: its signature (once a fight) and its trick (a chance).
## hit: what its normal hit would deal.
static func on_pet_turn(g: GameState, p: Dictionary, hit: int) -> void:
	var r := _rank(p)
	var id := int(p["id"])
	if r >= SIGNATURE_RANK:
		var sig := signature_of(String(p["species"]))
		var used: Dictionary = g.cfight.get("pet_sig", {})
		var when := String(sig["when"])
		var low := g.hero_hp > 0 and g.hero_hp < int(g.get_max_hp() * LOW_HP)
		if not used.has(id) and (when == "start" or (when == "low" and low)):
			used[id] = true
			g.cfight["pet_sig"] = used
			apply(g, p, String(sig["do"]), float(sig["value"]), hit, String(sig["name"]))
	if r >= TRICK_RANK and g.enemy_hp > 0:
		var t: Dictionary = FAMILIES[family(String(p["species"]))]["trick"]
		var st := _step(r)
		if String(t["do"]) == "heal" and g.hero_hp * 2 >= g.get_max_hp():
			return  # Mend waits until you need it
		if randf() * 100.0 < float(t["chance"][st]):
			apply(g, p, String(t["do"]), float(t["value"][st]), hit, String(t["name"]))
			g.feats["pet_tricks"] = int(g.feats.get("pet_tricks", 0)) + 1

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
			g.events.append({"type": "summon_hit", "dmg": d, "name": String(p["name"])})
		"shield":
			g.shield_hp += maxi(1, int(maxhp * value / 100.0))
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
			g.burn_dmg = maxi(g.burn_dmg if g.burn_turns > 0 else 0, maxi(1, int(hit * value)))
			g.burn_turns = GameData.BURN_TURNS
			g.burn_tag = "Fire"
		"poison":
			g.enemy_poison_dmg = maxi(g.enemy_poison_dmg, maxi(1, int(hit * value)))  # pets don't stack it
			g.enemy_poison_turns = Combat.POISON_TURNS
		"gold":
			var gold := maxi(1, int((2 + g.floor_num) * value))
			g._add_gold(gold)
			g.say("[color=#fbbf24]%s's %s: +%d gold.[/color]" % [p["name"], label, gold])
		_:
			return false
	if what != "gold":
		g.events.append({"type": "buff", "name": label})
	return true
