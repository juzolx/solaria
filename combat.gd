class_name Combat
extends RefCounted
## Combat rules added in v0.11:
##  - Elements: every monster is weak to some elements and resists others.
##  - Status effects on monsters (burn, poison, chill, frozen, curse) and the
##    combos between them (Shatter, Conduct, Toxic Blaze, Purge, Frozen).
##  - Status effects on you (poison, burn, chill), lowered by Wisdom.
##  - Boss mechanics: shield phases, enrage timers, minions, breath attacks.
##  - The death recap: what killed you, and a tip.
## game_state.gd calls into here; the numbers live here.

# ---------- Elements ----------
# Skill tags that are elements. Basic attacks and Blade/Fist skills are "Physical".
const ELEMENTS := ["Physical", "Fire", "Frost", "Storm", "Holy", "Shadow", "Nature", "Arcane", "Blood"]
const PHYSICAL_TAGS := ["Blade", "Fist", "Trick", "Song"]
const WEAK_MULT := 1.4
const RESIST_MULT := 0.7
const RESIST_PHYSICAL := 0.85   # resisting plain hits is gentler, so melee classes never feel stuck
const ELEMENT_COLORS := {"Physical": "#c0cbdc", "Fire": "#f77622", "Frost": "#7fd0f0", "Storm": "#fee761", "Holy": "#fde68a",
	"Shadow": "#8b5cf6", "Nature": "#63c74d", "Arcane": "#c084fc", "Blood": "#e43b44"}
# Each zone's creatures share a nature. Realms are keyed by their realm id.
const ZONE_ELEMENTS := {
	"Mossy Hollows": {"weak": ["Fire"], "resist": ["Nature"]},
	"Sunken Catacombs": {"weak": ["Holy", "Fire"], "resist": ["Shadow", "Frost"]},
	"Flooded Depths": {"weak": ["Storm"], "resist": ["Fire", "Frost"]},
	"Ember Halls": {"weak": ["Frost"], "resist": ["Fire"]},
	"The Shadow Deep": {"weak": ["Holy"], "resist": ["Shadow", "Arcane"]},
	"elf": {"weak": ["Fire"], "resist": ["Nature", "Shadow"]},
	"fairy": {"weak": ["Physical", "Blood"], "resist": ["Arcane"]},
	"dwarf": {"weak": ["Frost", "Storm"], "resist": ["Fire"]},
	"angel": {"weak": ["Shadow"], "resist": ["Holy"]},
	"demon": {"weak": ["Holy", "Frost"], "resist": ["Fire", "Shadow"]},
}
# The creature's own body adds to its zone's nature.
const SHAPE_ELEMENTS := {
	"spirit": {"weak": ["Holy", "Arcane"], "resist": ["Physical"]},
	"brute": {"weak": ["Arcane"], "resist": []},
	"beast": {"weak": ["Fire"], "resist": []},
	"serpent": {"weak": ["Frost"], "resist": []},
}

## Works out what the monster on screen is weak to and resists.
static func profile(g: GameState) -> Dictionary:
	var weak: Array = []
	var resist: Array = []
	var key := GameData.realm_of(g.floor_num)
	if key == "":
		key = String(GameData.zone_for_floor(g.floor_num)["name"])
	var z: Dictionary = ZONE_ELEMENTS.get(key, {})
	for e in z.get("weak", []):
		weak.append(e)
	for e in z.get("resist", []):
		resist.append(e)
	var sh: Dictionary = SHAPE_ELEMENTS.get(g.enemy_shape, {})
	for e in sh.get("weak", []):
		if not e in weak and not e in resist:
			weak.append(e)
	for e in sh.get("resist", []):
		if not e in resist and not e in weak:
			resist.append(e)
	if g.has_mod("Elemental"):
		var all := ELEMENTS.filter(func(x): return not x in weak and not x in resist and x != "Physical")
		if not all.is_empty():
			resist.append(all[hash(g.enemy_name + str(g.floor_num)) % all.size()])
	# Bosses and trials are never weak to more than one thing
	if g.enemy_is_boss and weak.size() > 1:
		weak = weak.slice(0, 1)
	return {"weak": weak, "resist": resist}

## The elements a hit carries: skill tags that are elements, or Physical.
static func elements_of(tags: Array) -> Array:
	var out: Array = []
	for t in tags:
		if t in ELEMENTS and not t in out:
			out.append(t)
		elif t in PHYSICAL_TAGS and not "Physical" in out:
			out.append("Physical")
	if out.is_empty():
		out.append("Physical")
	return out

## Damage multiplier for a hit with these tags: weak wins over resist.
## Returns [multiplier, "weak" / "resist" / ""].
static func element_mult(g: GameState, tags: Array) -> Array:
	var els := elements_of(tags)
	for e in els:
		if e in g.enemy_weak:
			return [WEAK_MULT * (1.0 + g._flat("weakness") / 100.0), "weak"]
	for e in els:
		if e in g.enemy_resist:
			return [RESIST_PHYSICAL if e == "Physical" else RESIST_MULT, "resist"]
	return [1.0, ""]

# ---------- Status effects on the monster ----------
const CHILL_TURNS := 3
const FROZEN_TURNS := 1
const POISON_TURNS := 4
const CURSE_TURNS := 4
const SHATTER_MULT := 2.0
const CONDUCT_MULT := 1.5
const PURGE_MULT := 1.6
const TOXIC_MULT := 1.5
const COMBOS := {
	"frozen": {"name": "Frozen!", "color": "#bae6fd", "text": "Chilled twice: the monster freezes, skips its attack, and every hit on it is a crit."},
	"shatter": {"name": "Shatter!", "color": "#fb923c", "text": "Fire on a chilled or frozen monster: double damage."},
	"conduct": {"name": "Conduct!", "color": "#fde047", "text": "Storm on a chilled or frozen monster: +50% damage and a stun."},
	"toxic": {"name": "Toxic Blaze!", "color": "#a3e635", "text": "Burning and poisoned at once: both hurt 50% more."},
	"purge": {"name": "Purge!", "color": "#fef3c7", "text": "Holy on a cursed monster: +60% damage and you heal 5%."},
}

## Before a skill hits: combos that change its damage. Returns the multiplier.
static func before_skill(g: GameState, tags: Array, has_power: bool) -> float:
	if not has_power:
		return 1.0
	var m := 1.0
	var cold := g.enemy_chill > 0 or g.enemy_frozen > 0
	if "Fire" in tags and cold:
		m *= SHATTER_MULT
		g.enemy_chill = 0
		g.enemy_frozen = 0
		_combo(g, "shatter")
	elif "Storm" in tags and cold:
		m *= CONDUCT_MULT
		g.enemy_stun = maxi(g.enemy_stun, 1)
		_combo(g, "conduct")
	if "Holy" in tags and g.enemy_curse > 0:
		m *= PURGE_MULT
		g.enemy_curse = 0
		var heal := int(g.get_max_hp() * 0.05 * g.heal_mult())
		g.hero_hp = mini(g.get_max_hp(), g.hero_hp + heal)
		g.events.append({"type": "heal", "amount": heal})
		_combo(g, "purge")
	return m

## After a skill hits: the statuses it leaves behind.
static func after_skill(g: GameState, tags: Array, s: Dictionary, mult: float) -> void:
	if "Frost" in tags and s.has("power"):
		if g.enemy_chill > 0 and g.enemy_frozen <= 0:
			g.enemy_chill = 0
			g.enemy_frozen = FROZEN_TURNS
			_combo(g, "frozen")
		else:
			g.enemy_chill = CHILL_TURNS
	if "Shadow" in tags and (s.has("weaken") or s.has("power")) and not s.has("drain"):
		g.enemy_curse = CURSE_TURNS
	if float(s.get("burn", 0.0)) > 0.0 and ("Nature" in tags or "Shadow" in tags):
		# Nature and Shadow damage over time is poison, and it stacks
		g.enemy_poison_turns = POISON_TURNS
		g.enemy_poison_dmg += maxi(1, int(g.get_attack() * float(s["burn"]) * mult * 0.8))
	if g.burn_turns > 0 and g.enemy_poison_turns > 0:
		_combo(g, "toxic")

## A combo went off: tell the screen, count it (once per fight per combo for the popup).
static func _combo(g: GameState, id: String) -> void:
	ClassTree.count(g, "combo:" + id)
	g.codex.add("combos")
	var seen: Dictionary = g.cfight.get("combos", {})
	if seen.has(id) and id == "toxic":
		return
	seen[id] = true
	g.cfight["combos"] = seen
	g.events.append({"type": "combo", "id": id, "name": COMBOS[id]["name"], "color": COMBOS[id]["color"]})

## Damage over time on the monster each turn: burn and poison (Toxic Blaze makes both worse).
## Returns the total dealt.
static func tick_enemy(g: GameState) -> int:
	var total := 0
	var toxic := g.burn_turns > 0 and g.enemy_poison_turns > 0
	var tm := TOXIC_MULT if toxic else 1.0
	if g.burn_turns > 0:
		g.burn_turns -= 1
		var d := g._damage_enemy(int(g.burn_dmg * tm), [g.burn_tag])
		g.events.append({"type": "burn", "dmg": d})
		total += d
	if g.enemy_poison_turns > 0 and g.enemy_hp > 0:
		g.enemy_poison_turns -= 1
		var d := g._damage_enemy(int(g.enemy_poison_dmg * tm), ["Nature"])
		g.events.append({"type": "poison", "dmg": d})
		total += d
		if g.enemy_poison_turns <= 0:
			g.enemy_poison_dmg = 0
	if g.enemy_chill > 0:
		g.enemy_chill -= 1
	if g.enemy_curse > 0:
		g.enemy_curse -= 1
	return total

# ---------- Status effects on you (Wisdom resists them) ----------
const HERO_POISON := 0.025   # % of max HP a turn
const HERO_BURN := 0.03
const HERO_CHILL_ATK := 0.75 # your Attack while chilled
const STATUS_INFO := {
	"poison": {"name": "Poisoned", "color": "#a3e635"},
	"burn": {"name": "Burning", "color": "#fb923c"},
	"chill": {"name": "Chilled", "color": "#7fd0f0"},
}

## The monster puts a status on you. Wisdom shortens it.
static func afflict(g: GameState, kind: String, turns: int) -> void:
	var t := maxi(1, int(round(turns * g.status_mult())))
	if randf() < (1.0 - g.status_mult()) * 0.5:
		g.events.append({"type": "resisted", "kind": kind})
		return
	g.hero_status[kind] = maxi(int(g.hero_status.get(kind, 0)), t)
	g.events.append({"type": "afflicted", "kind": kind, "name": STATUS_INFO[kind]["name"], "color": STATUS_INFO[kind]["color"]})

## Your statuses hurt and count down. Returns damage taken.
static func tick_hero(g: GameState) -> int:
	var dmg := 0
	for kind in g.hero_status.keys():
		var pct := 0.0
		if kind == "poison":
			pct = HERO_POISON
		elif kind == "burn":
			pct = HERO_BURN
		if pct > 0.0:
			var d := maxi(1, int(g.get_max_hp() * pct * g.status_mult()))
			g.hero_hp -= d
			dmg += d
			note_damage(g, kind, d)
			g.events.append({"type": "enemy_hit", "dmg": d, "burning": kind == "burn", "poison": kind == "poison"})
		g.hero_status[kind] = int(g.hero_status[kind]) - 1
		if int(g.hero_status[kind]) <= 0:
			g.hero_status.erase(kind)
	return dmg

# ---------- Elite modifiers that use statuses ----------
## The monster's attack landed: modifiers that do something on a hit.
static func on_enemy_hit(g: GameState, dmg: int) -> void:
	if g.has_mod("Venomous") and randf() < 0.35:
		afflict(g, "poison", 3)
	if g.has_mod("Frigid") and randf() < 0.3:
		afflict(g, "chill", 2)
	var mech: Array = g.boss_mechanics
	if "breath" in mech and int(g.cfight.get("turns", 0)) % 4 == 0:
		afflict(g, String(g.cfight.get("breath", "burn")), 3)

## A monster died: Explosive monsters go off.
static func on_enemy_death(g: GameState) -> void:
	if g.has_mod("Explosive"):
		if randf() * 100.0 < g.effect_total("dodge"):
			g.events.append({"type": "dodge"})
			g.say("You dive away from the explosion!")
			return
		var d := maxi(1, int(g.get_max_hp() * 0.12))
		g.hero_hp = maxi(1, g.hero_hp - d)
		g.events.append({"type": "enemy_hit", "dmg": d, "burning": true})
		g.say("[color=#fb923c]The monster explodes! You take %d.[/color]" % d)

# ---------- Boss mechanics ----------
const MECHANICS := {
	"shield": {"name": "Shield Phase", "color": "#60a5fa", "text": "At half health it shields itself. Break the shield fast."},
	"enrage": {"name": "Enrage", "color": "#ef4444", "text": "After %d turns it enrages and hits harder every turn."},
	"minions": {"name": "Minions", "color": "#a3a3a3", "text": "It calls minions that soak your damage and bite you each turn."},
	"breath": {"name": "Breath", "color": "#fb923c", "text": "Every few turns it breathes poison, fire or frost on you (Wisdom helps)."},
}
const ENRAGE_TURNS := 18
const ENRAGE_STEP := 0.12   # +12% Attack every turn after it enrages
const SHIELD_PART := 0.25   # shield = 25% of its max HP
const MINION_HP := 0.08     # each minion: 8% of the boss's max HP
const MINION_BITE := 0.25   # each minion hits for 25% of the boss's Attack

## Picks a boss's mechanics: mid bosses get 1, zone bosses and trials get 2.
static func roll_mechanics(g: GameState) -> Array:
	var pool := ["shield", "enrage", "minions", "breath"]
	var h := absi(hash(g.enemy_species))
	var first: String = pool[h % pool.size()]
	var out: Array = [first]
	if g.enemy_boss_kind in ["zone", "trial"]:
		var rest := pool.filter(func(x): return x != first)
		out.append(rest[(h / 7) % rest.size()])
	return out

## Sets up a new boss fight.
static func start_boss(g: GameState) -> void:
	g.boss_mechanics = roll_mechanics(g)
	g.boss_phase = {}
	if "breath" in g.boss_mechanics:
		var key := GameData.realm_of(g.floor_num)
		var z := String(GameData.zone_for_floor(g.floor_num)["name"]) if key == "" else key
		g.cfight["breath"] = {"Ember Halls": "burn", "demon": "burn", "dwarf": "burn", "Flooded Depths": "chill", "angel": "chill",
			"Sunken Catacombs": "poison", "The Shadow Deep": "poison"}.get(z, ["burn", "poison", "chill"][absi(hash(g.enemy_species)) % 3])

## Every boss turn: shields, minions and the enrage clock. Returns a log line.
static func boss_turn(g: GameState) -> String:
	if not g.enemy_is_boss or g.boss_mechanics.is_empty() or g.enemy_hp <= 0:
		return ""
	var line := ""
	var frac := float(g.enemy_hp) / maxf(1.0, g.enemy_max_hp)
	var ph: Dictionary = g.boss_phase
	if "shield" in g.boss_mechanics and frac <= 0.5 and not ph.has("shield"):
		ph["shield"] = true
		g.enemy_shield += int(g.enemy_max_hp * SHIELD_PART)
		g.events.append({"type": "boss_mechanic", "id": "shield", "name": "%s shields itself!" % g.enemy_name, "color": MECHANICS["shield"]["color"]})
		line += ". [color=#60a5fa]%s raises a shield![/color]" % g.enemy_name
	if "minions" in g.boss_mechanics:
		for at in [0.66, 0.33]:
			var k := "minions_%d" % int(at * 100)
			if frac <= at and not ph.has(k):
				ph[k] = true
				g.boss_minions += 2
				g.minion_hp = int(g.enemy_max_hp * MINION_HP)
				g.events.append({"type": "boss_mechanic", "id": "minions", "name": "Minions join the fight!", "color": MECHANICS["minions"]["color"]})
				line += ". [color=#d4d4d4]Two minions join the fight![/color]"
		if g.boss_minions > 0:
			var bite := maxi(1, int(g.damage_taken() * MINION_BITE * g.boss_minions))
			if randf() * 100.0 < g.effect_total("dodge"):
				g.events.append({"type": "dodge"})
			else:
				g.hero_hp -= bite
				note_damage(g, "minions", bite)
				g.events.append({"type": "enemy_hit", "dmg": bite, "minion": true})
				line += ". The minions bite you for %d" % bite
	if "enrage" in g.boss_mechanics:
		var t := int(g.cfight.get("turns", 0))
		if t == ENRAGE_TURNS:
			g.events.append({"type": "boss_mechanic", "id": "enrage", "name": "%s is ENRAGED!" % g.enemy_name, "color": MECHANICS["enrage"]["color"]})
			line += ". [color=#ef4444]%s is enraged![/color]" % g.enemy_name
	g.boss_phase = ph
	return line

## The boss's attack multiplier from enrage.
static func enrage_mult(g: GameState) -> float:
	if not g.enemy_is_boss or not "enrage" in g.boss_mechanics:
		return 1.0
	var over := int(g.cfight.get("turns", 0)) - ENRAGE_TURNS
	return 1.0 if over < 0 else 1.5 + ENRAGE_STEP * over

## Turns left before the boss enrages (-1 if it doesn't).
static func enrage_left(g: GameState) -> int:
	if not g.enemy_is_boss or not "enrage" in g.boss_mechanics:
		return -1
	return maxi(0, ENRAGE_TURNS - int(g.cfight.get("turns", 0)))

## Minions soak damage before the boss does. Returns what's left for the boss.
static func soak_minions(g: GameState, dmg: int) -> int:
	while g.boss_minions > 0 and dmg > 0:
		if dmg >= g.minion_hp:
			dmg -= g.minion_hp
			g.boss_minions -= 1
			g.events.append({"type": "minion_dead"})
		else:
			g.minion_hp -= dmg
			dmg = 0
	return dmg

# ---------- Death recap ----------

## Keeps a tally of what's hurting you this fight (for the death recap).
static func note_damage(g: GameState, source: String, amount: int) -> void:
	var by: Dictionary = g.cfight.get("dmg_by", {})
	by[source] = int(by.get(source, 0)) + amount
	g.cfight["dmg_by"] = by
	if source == "hits":
		g.cfight["biggest"] = maxi(int(g.cfight.get("biggest", 0)), amount)

## What killed you, and what might help. Saved in g.last_death.
static func recap(g: GameState) -> Dictionary:
	var by: Dictionary = g.cfight.get("dmg_by", {})
	var total := 0
	for k in by:
		total += int(by[k])
	var top := ""
	for k in by:
		if top == "" or int(by[k]) > int(by[top]):
			top = k
	var dealt := g.enemy_max_hp - maxi(0, g.enemy_hp)
	var r := {"enemy": g.enemy_name, "tier": g.enemy_tier, "boss": g.enemy_is_boss, "mods": g.enemy_mods.duplicate(),
		"turns": int(g.cfight.get("turns", 0)), "taken": by.duplicate(), "total": total, "biggest": int(g.cfight.get("biggest", 0)),
		"dealt": dealt, "enemy_left": float(maxi(0, g.enemy_hp)) / maxf(1.0, g.enemy_max_hp), "floor": g.floor_num,
		"weak": g.enemy_weak.duplicate(), "resist": g.enemy_resist.duplicate(), "mechanics": g.boss_mechanics.duplicate()}
	r["tips"] = _tips(g, r, top)
	return r

static func _tips(g: GameState, r: Dictionary, top: String) -> Array:
	var tips: Array = []
	var by: Dictionary = r["taken"]
	var total := maxf(1.0, float(r["total"]))
	var dot := float(by.get("poison", 0) + by.get("burn", 0) + by.get("burning", 0))
	if dot / total > 0.25:
		tips.append("A lot of that was poison and burns. Wisdom resists them, and heals stronger.")
	if float(by.get("minions", 0)) / total > 0.2:
		tips.append("The minions did real damage. Skills that hit many times kill them fast.")
	if int(r["biggest"]) > g.get_max_hp() * 0.35:
		tips.append("Single hits took over a third of your HP. More Vitality, Defense or dodge would help.")
	var used: Dictionary = g.cfight.get("tags", {})
	for t in used:
		for e in elements_of([t]):
			if e in g.enemy_resist and not e == "Physical":
				tips.append("It resists %s. Try skills of another element (it's weak to %s)." % [e, ", ".join(g.enemy_weak) if not g.enemy_weak.is_empty() else "nothing in particular"])
				break
	if r.get("boss", false) and "enrage" in r["mechanics"] and int(r["turns"]) >= ENRAGE_TURNS:
		tips.append("It enraged before you won. More damage (Strength, Intelligence, better weapon) beats the clock.")
	if float(r["enemy_left"]) > 0.6:
		tips.append("It still had %d%% of its health. Go back a few floors for gear and levels, then return." % int(float(r["enemy_left"]) * 100))
	if g.potions == 0:
		tips.append("You were out of potions. The Shop sells them, and Auto-potion drinks them for you.")
	if g.stat_points > 0:
		tips.append("You have %d stat points waiting in Character > Hero." % g.stat_points)
	if g.upgrade_count() > 0:
		tips.append("Your bag has upgrades. Press Equip Best in Items > Gear.")
	if tips.is_empty():
		tips.append("Close one. A few more levels or a gear upgrade should do it.")
	return tips.slice(0, 3)
