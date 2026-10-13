class_name Party
extends RefCounted
## Your party: the hero you're playing plus up to 2 of your other Regular
## heroes as companions. Companions fight with their own gear, stats and
## skills, earn XP alongside you, and get knocked out (not killed) if they
## fall; they get back up on the next floor. Monsters get tougher with a
## bigger party, and they aim mostly at tanks.
## Hardcore heroes always fight alone.

const MAX_COMPANIONS := 2
const HP_PER_MEMBER := 0.45    # monster HP +45% for each companion
const ATK_PER_MEMBER := 0.1    # monster Attack +10% for each companion
const LOOT_PER_MEMBER := 0.3   # chance of an extra drop per companion
const TANK_CLASSES := ["Warrior", "Knight"]
const TANK_WEIGHT := 3.0       # monsters attack tanks this many times more often
const SUPPORT_HEAL_AT := 0.6   # healers heal party members under 60% HP
const REVIVE_HP := 0.4         # knocked-out companions get up with 40% HP on the next floor

class Member:
	var slot := 0
	var hero: GameState
	var hp := 0
	var cds := {}
	var knocked_out := false
	var name := ""

	func max_hp() -> int:
		return hero.get_max_hp()

	func role() -> String:
		return Classes.info(hero.hero_class).get("role", "")

	func is_tank() -> bool:
		return hero.hero_class in Party.TANK_CLASSES or hero.class_path.any(func(id): return id in ["guardian", "juggernaut", "templar", "paladin", "champion"])

var members: Array = []  # of Member

func size() -> int:
	return members.size()

func living() -> Array:
	return members.filter(func(m): return not m.knocked_out)

## Loads companions from their save slots.
func load_members(slots: Array, leader: GameState) -> void:
	members.clear()
	for n in slots:
		if int(n) == leader.slot or not GameState.has_slot(int(n)) or members.size() >= MAX_COMPANIONS:
			continue
		var g := GameState.new()
		g.slot = int(n)
		g.codex = Codex.new()
		g.codex.path = ""
		if not g.load_game() or g.hardcore or g.hero_class == "":
			continue
		# The party shares one skill book: merge in this hero's skills
		for id in g.skill_book:
			leader.skill_book[id] = maxi(int(leader.skill_book.get(id, 0)), int(g.skill_book[id]))
		g.skill_book = leader.skill_book
		var m := Member.new()
		m.slot = int(n)
		m.hero = g
		m.hp = g.get_max_hp()
		m.name = g.hero_name if g.hero_name != "" else g.hero_class
		members.append(m)

## Saves every companion (their XP, levels and stat points).
func save_all() -> void:
	for m in members:
		m.hero.save_game()

func hp_mult() -> float:
	return 1.0 + HP_PER_MEMBER * members.size()

func atk_mult() -> float:
	return 1.0 + ATK_PER_MEMBER * members.size()

## Who the monster swings at: "" = the leader, otherwise a Member.
func pick_target(leader: GameState) -> Variant:
	var options: Array = [[null, TANK_WEIGHT if leader.hero_class in TANK_CLASSES else 1.0]]
	for m in living():
		options.append([m, TANK_WEIGHT if m.is_tank() else 1.0])
	var total := 0.0
	for o in options:
		total += float(o[1])
	var roll := randf() * total
	for o in options:
		roll -= float(o[1])
		if roll < 0.0:
			return o[0]
	return null

## The monster hits a companion. Returns a log line.
func hit_member(leader: GameState, m: Member) -> String:
	var g: GameState = m.hero
	if randf() * 100.0 < g.effect_value("dodge"):
		leader.events.append({"type": "party_dodge", "slot": m.slot})
		return ". %s dodges" % m.name
	var atk := float(leader.enemy_attack)
	var dmg := maxi(1, int(round(atk * atk / (atk + g.get_defense()))))
	if leader.enemy_weaken_turns > 0:
		dmg = maxi(1, int(dmg * leader.enemy_weaken))
	m.hp -= dmg
	leader.events.append({"type": "party_hit", "slot": m.slot, "dmg": dmg})
	var thorns := int(dmg * g.effect_value("thorns") / 100.0)
	if thorns > 0:
		leader.enemy_hp -= thorns
	if m.hp <= 0:
		m.hp = 0
		m.knocked_out = true
		leader.events.append({"type": "party_down", "slot": m.slot})
		return ". The %s knocks out %s!" % [leader.enemy_name, m.name]
	return ". The %s hits %s for %d" % [leader.enemy_name, m.name, dmg]

## Each living companion attacks and uses skills. Returns log text.
func act(leader: GameState) -> String:
	var parts: Array = []
	for m in living():
		if leader.enemy_hp <= 0:
			break
		var g: GameState = m.hero
		for id in m.cds:
			if int(m.cds[id]) > 0:
				m.cds[id] = int(m.cds[id]) - 1
		var used := _use_a_skill(leader, m)
		if used != "":
			parts.append(used)
			continue
		# A normal attack
		var hits := 2 if randf() * 100.0 < g.effect_value("double_strike") else 1
		var total := 0
		var crit := false
		for _h in hits:
			var d := float(g.get_attack()) * leader.party_mult()
			if randf() * 100.0 < g.effect_value("crit"):
				d *= g.crit_mult()
				crit = true
			total += int(d)
		total = leader._damage_enemy(total, ["Physical"])
		leader.events.append({"type": "party_attack", "slot": m.slot, "dmg": total, "crit": crit})
		var steal := int(total * g.effect_value("lifesteal") / 100.0)
		m.hp = mini(m.max_hp(), m.hp + steal)
		# Regeneration
		m.hp = mini(m.max_hp(), m.hp + int(m.max_hp() * g.effect_value("regen") / 100.0))
	return "" if parts.is_empty() else ". " + ". ".join(parts)

## A companion's skill: damage hits the monster, heals and shields go to whoever needs them.
func _use_a_skill(leader: GameState, m: Member) -> String:
	var g: GameState = m.hero
	for id in g.equipped_actives():
		if int(m.cds.get(id, 0)) > 0:
			continue
		var s := SkillData.info(id)
		var lowest := _lowest(leader)
		var heals := s.has("heal") or s.has("song")
		var only_support := not s.has("power")
		if only_support and heals and lowest[1] > SUPPORT_HEAL_AT:
			continue
		if s.has("buff") and leader.buffs.has("party_" + id):
			continue
		if s.has("shield") and leader.shield_hp > 0:
			continue
		m.cds[id] = g.skill_cd(id)
		var mult := g.skill_mult(id)
		var rk := SkillData.rank_mult(g.skill_rank(id))
		var bits: Array = []
		if s.has("power"):
			var total := 0
			for _i in int(s.get("hits", 1)):
				var d := (g.get_attack() * float(s["power"]) * mult + g.get_defense() * float(s.get("def_scale", 0.0)) * rk) * leader.party_mult()
				if s.get("always_crit", false) or randf() * 100.0 < g.effect_value("crit"):
					d *= g.crit_mult()
				total += int(d)
			total = leader._damage_enemy(total, s.get("tags", []))
			bits.append("%d damage" % total)
			if s.has("drain"):
				m.hp = mini(m.max_hp(), m.hp + int(total * float(s["drain"]) / 100.0))
		if heals:
			var pct := (float(s.get("heal", 0)) + float(s.get("song", {}).get("regen", 0)) * 3.0) * rk * g.heal_mult()
			_heal(leader, lowest[0], pct)
			bits.append("heals %s" % ("you" if lowest[0] == null else lowest[0].name))
		if s.has("shield"):
			leader.shield_hp += int(leader.get_max_hp() * float(s["shield"]) * rk / 100.0)
			bits.append("shields you")
		if s.has("buff"):
			var b: Dictionary = (s["buff"] as Dictionary).duplicate()
			leader.buffs["party_" + id] = b
			bits.append("buffs you")
		if s.has("stun"):
			leader.enemy_stun = maxi(leader.enemy_stun, int(s["stun"]))
		if s.has("weaken"):
			leader.enemy_weaken = float(s["weaken"])
			leader.enemy_weaken_turns = int(s["turns"])
		if s.has("confuse"):
			leader.confuse_turns = maxi(leader.confuse_turns, int(s["confuse"]))
		if float(s.get("burn", 0.0)) > 0.0:
			leader.burn_turns = GameData.BURN_TURNS
			leader.burn_dmg = maxi(leader.burn_dmg, int(g.get_attack() * float(s["burn"]) * mult))
		if s.has("summon") and leader.summon_turns <= 0:
			leader.summon_turns = int(s["summon"]["turns"])
			leader.summon_power = float(s["summon"]["power"]) * mult * g.get_attack() / maxf(1.0, leader.get_attack())
			leader.summon_name = "Skeleton" if "Shadow" in s["tags"] else "Wolf"
		leader.events.append({"type": "party_skill", "slot": m.slot, "name": s["name"], "color": Classes.tag_color(s["tags"][0])})
		return "%s uses %s (%s)" % [m.name, s["name"], ", ".join(bits)]
	return ""

## [member or null for the leader, HP fraction] of whoever is hurt the most.
func _lowest(leader: GameState) -> Array:
	var best: Variant = null
	var frac := float(leader.hero_hp) / maxf(1.0, leader.get_max_hp())
	for m in living():
		var f := float(m.hp) / maxf(1.0, m.max_hp())
		if f < frac:
			frac = f
			best = m
	return [best, frac]

func _heal(leader: GameState, who: Variant, pct: float) -> void:
	if who == null:
		var amt := int(leader.get_max_hp() * pct / 100.0)
		leader.hero_hp = mini(leader.get_max_hp(), leader.hero_hp + amt)
		leader.events.append({"type": "heal", "amount": amt})
	else:
		var m: Member = who
		m.hp = mini(m.max_hp(), m.hp + int(m.max_hp() * pct / 100.0))
		leader.events.append({"type": "party_heal", "slot": m.slot})

## After a kill: companions share the XP (and spend their points sensibly).
func on_kill(xp: int) -> void:
	for m in members:
		var g: GameState = m.hero
		var before := g.level
		g.gain_xp(xp)
		g.events.clear()
		g.messages.clear()
		if g.level > before:
			m.hp = mini(m.max_hp(), m.hp + int(m.max_hp() * 0.3))
			auto_spend(g)

## Companions put their stat points into their class's recommended build.
static func auto_spend(g: GameState) -> void:
	g.auto_spend()

## New floor: knocked-out companions get back up.
func on_floor() -> void:
	for m in members:
		if m.knocked_out:
			m.knocked_out = false
			m.hp = int(m.max_hp() * REVIVE_HP)
		else:
			m.hp = mini(m.max_hp(), m.hp + int(m.max_hp() * 0.2))

## The leader fell: everyone is patched up for the retry.
func on_wipe() -> void:
	for m in members:
		m.knocked_out = false
		m.hp = m.max_hp()
		m.cds.clear()
