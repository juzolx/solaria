class_name Peoples
extends RefCounted
## 0.13+ (Stage 3): race friendliness you can feel. When you meet one of a race's
## people (elves, dwarves, orcs... in their realms), how they see you matters: a race
## that likes you may lower its weapons, leave a small gift and let you pass. The
## better your standing, the more often. (Hated races already hit harder: races.gd.)

## Reputation level index (Races.REP_LEVELS) -> % chance they let you pass
const PASS_CHANCE := {3: 25.0, 4: 45.0, 5: 70.0}   # Friendly, Honored, Exalted
const REP_GAIN := 0.3

## After a monster spawns: are these friends?
static func on_spawn(g: GameState) -> void:
	g.enemy_peaceful = false
	if g.enemy_people == "" or g.enemy_is_boss or g.enemy_wanderer or g.enemy_grave or g.horde_left > 0 or Portals.inside(g):
		return
	var idx := Races.rep_index(Lineage.rep(g, g.enemy_people))
	if randf() * 100.0 < float(PASS_CHANCE.get(idx, 0.0)):
		g.enemy_peaceful = true
		var lv: Array = Races.rep_level(Lineage.rep(g, g.enemy_people))
		g.events.append({"type": "mini_event", "kind": "peaceful", "title": "THEY KNOW YOU", "sub": "The %s lower their weapons (%s)." % [Lineage.race_plural(g.enemy_people), lv[0]]})

## Your next turn with friends: they wish you well and step aside.
static func part_ways(g: GameState) -> bool:
	if not g.enemy_peaceful:
		return false
	g.enemy_peaceful = false
	var race := g.enemy_people
	var gift := ""
	if randf() < 0.5:
		g.potions += 1
		gift = "a potion"
	else:
		var gold := (5 + g.floor_num * 4) * 2
		g._add_gold(gold)
		gift = "%d gold" % gold
	Lineage.change_rep(g, race, REP_GAIN, false)
	g.codex.add("peaceful_meetings")
	ClassTree.count(g, "peaceful")
	g.say("[color=#4ade80]The %s nod to you and step aside.[/color] They press %s into your hands." % [Lineage.race_plural(race), gift])
	g.events.append({"type": "escaped"})
	Lineage._move_on(g)
	return true
