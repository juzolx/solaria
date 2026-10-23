class_name Presets
extends RefCounted
## 2.1: one presets system. A preset bundles your stat spread, skills, worn gear,
## team and rows, and the supplies you take down. Merged from: builds (stats,
## skills, gear: Hero tab), gear loadouts (Gear tab) and team presets (Party tab).
## Stored in GameState.builds (saved with the hero). Screen: presets_screen.gd;
## quick swap in Into the dungeon (floor_picker.gd).
## Things in a preset you no longer have are skipped, with a note saying so.

const SLOTS := 4

static func ensure(g: GameState) -> void:
	while g.builds.size() < SLOTS:
		g.builds.append({})

static func get_preset(g: GameState, i: int) -> Dictionary:
	ensure(g)
	return g.builds[i] if i >= 0 and i < g.builds.size() else {}

static func is_saved(g: GameState, i: int) -> bool:
	return not get_preset(g, i).is_empty()

static func name_of(g: GameState, i: int) -> String:
	return String(get_preset(g, i).get("name", "Preset %d" % (i + 1)))

static func rename(g: GameState, i: int, new_name: String) -> void:
	var p := get_preset(g, i)
	new_name = new_name.strip_edges().left(20)
	if p.is_empty() or new_name == "":
		return
	p["name"] = new_name
	g.save_game()

## Saves everything you're running now into preset i.
static func save(g: GameState, i: int, preset_name := "") -> void:
	ensure(g)
	var gear := {}
	var gear_names := {}
	for s in g.equipped:
		gear[s] = int(g.equipped[s]["id"])
		gear_names[s] = GameData.display_name(g.equipped[s])
	var supplies := {}
	for k in GameState.supply_keys():
		var n := g.supply_carried(k)
		if n > 0:
			supplies[k] = n
	var keep_name := preset_name.strip_edges() if preset_name.strip_edges() != "" else name_of(g, i)
	g.builds[i] = {
		"name": keep_name.left(20),
		"stats": g.stats.duplicate(),
		"active": g.active_slots.duplicate(),
		"passive": g.passive_slots.duplicate(),
		"gear": gear,
		"gear_names": gear_names,
		"party": g.party_slots.duplicate(),
		"formation": g.formation.duplicate(),
		"supplies": supplies,
	}
	g.say("Saved preset %d: %s." % [i + 1, keep_name])
	g.save_game()

static func clear(g: GameState, i: int) -> void:
	ensure(g)
	g.builds[i] = {}
	g.save_game()

## Puts preset i on. Returns notes about anything skipped (gone, missing, can't do here).
static func apply(g: GameState, i: int) -> Array:
	var p := get_preset(g, i)
	var notes: Array = []
	if p.is_empty():
		return notes
	if p.has("stats"):
		_apply_stats(g, p["stats"])
	_apply_skills(g, p, notes)
	_apply_gear(g, p, notes)
	if p.has("party"):
		_apply_party(g, p["party"], notes)
	if p.has("formation"):
		var f: Dictionary = p["formation"]
		for k in f:
			g.formation[k] = f[k]
	if p.has("supplies"):
		_apply_supplies(g, p["supplies"], notes)
	g.hero_hp = mini(g.hero_hp, g.get_max_hp())
	g._check_spec()
	g.say("Switched to %s." % name_of(g, i))
	for n in notes:
		g.say("[color=#9ca3af]%s[/color]" % n)
	g.save_game()
	return notes

## Your points move to the saved spread for free (scaled down if you have fewer now).
static func _apply_stats(g: GameState, want: Dictionary) -> void:
	var pool := g.stat_points
	var want_total := 0
	for st in GameData.STAT_ORDER:
		pool += int(g.stats.get(st, 0))
		want_total += int(want.get(st, 0))
	var f := 1.0 if want_total <= pool else float(pool) / maxf(1.0, want_total)
	var used := 0
	for st in GameData.STAT_ORDER:
		g.stats[st] = int(floor(int(want.get(st, 0)) * f))
		used += int(g.stats[st])
	g.stat_points = pool - used

static func _apply_skills(g: GameState, p: Dictionary, notes: Array) -> void:
	var lists := [["active", g.active_slots], ["passive", g.passive_slots]]
	for pair in lists:
		if not p.has(pair[0]):
			continue
		var want: Array = p[pair[0]]
		var slots: Array = pair[1]
		for k in slots.size():
			var id: String = String(want[k]) if k < want.size() else ""
			if id == "" or g.skill_book.has(id):
				slots[k] = id
			else:
				notes.append("Skipped %s: it's not in your skill book." % SkillData.skill_name(id))

static func _apply_gear(g: GameState, p: Dictionary, notes: Array) -> void:
	var gear: Dictionary = p.get("gear", {})
	var names: Dictionary = p.get("gear_names", {})
	for s in gear:
		var found := g.find_item(int(gear[s]))
		if found.is_empty():
			notes.append("Skipped %s: it's gone." % String(names.get(s, "your old " + String(s).to_lower())))
		elif found["where"] == "bag":
			g.equip(int(gear[s]))

static func _apply_party(g: GameState, want: Array, notes: Array) -> void:
	if g.hardcore:
		return
	var comps: Array = []
	for n in want:
		if GameState.has_slot(int(n)) and int(n) != g.slot:
			comps.append(int(n))
		else:
			notes.append("Skipped a team member: that hero is gone.")
	if comps == g.party_slots:
		return
	if not g.in_town:
		notes.append("Your team changes when you're back in town.")
		return
	if g.party != null:
		g.party.save_all()
	g.set_party(comps)

static func _apply_supplies(g: GameState, want: Dictionary, notes: Array) -> void:
	if not g.in_town:
		return  # supplies are picked in town (Into the dungeon)
	for k in GameState.supply_keys():
		var diff := int(want.get(k, 0)) - g.supply_carried(k)
		if diff > 0:
			var n := mini(diff, g.supply_home(k))
			if n > 0:
				g.move_supply(k, n)
			if n < diff:
				notes.append("Only %d more %s at home (wanted %d)." % [n, GameState.supply_name(k), diff])
		elif diff < 0:
			g.move_supply(k, diff)

## A short line about what's in preset i.
static func summary(g: GameState, i: int) -> String:
	var p := get_preset(g, i)
	if p.is_empty():
		return "Empty"
	var parts: Array = []
	if p.has("stats"):
		parts.append("stats")
	var sk := 0
	for id in p.get("active", []) + p.get("passive", []):
		if String(id) != "":
			sk += 1
	if sk > 0:
		parts.append("%d skill%s" % [sk, "" if sk == 1 else "s"])
	var gn := (p.get("gear", {}) as Dictionary).size()
	if gn > 0:
		parts.append("%d gear" % gn)
	var team := (p.get("party", []) as Array).size()
	if p.has("party"):
		parts.append("solo" if team == 0 else "team of %d" % (team + 1))
	var sup := 0
	for k in p.get("supplies", {}):
		sup += int(p["supplies"][k])
	if sup > 0:
		parts.append("%d supplies" % sup)
	return ", ".join(parts) if not parts.is_empty() else "Empty"

## Moves old gear loadouts (Gear tab) and this hero's team presets (Party tab)
## into empty preset slots. Safe to call any number of times.
static func migrate(g: GameState, profile: Profile = null) -> void:
	ensure(g)
	var moved := false
	for li in g.loadouts.size():
		var lo: Dictionary = g.loadouts[li]
		if lo.is_empty():
			continue
		var j := _first_empty(g)
		if j < 0:
			break
		g.builds[j] = {"name": "Gear set %d" % (li + 1), "gear": lo.duplicate()}
		g.loadouts[li] = {}
		moved = true
	if profile != null:
		var pmoved := false
		for pi in profile.presets.size():
			var pr: Dictionary = profile.presets[pi]
			var slots: Array = pr.get("slots", [])
			if slots.is_empty() or int(slots[0]) != g.slot:
				continue
			var j := _first_empty(g)
			if j < 0:
				break
			g.builds[j] = {"name": "Team %d" % (pi + 1), "party": slots.slice(1)}
			profile.presets[pi] = {}
			pmoved = true
		if pmoved:
			profile.save()
			moved = true
	if moved:
		g.save_game()

static func _first_empty(g: GameState) -> int:
	for j in g.builds.size():
		if (g.builds[j] as Dictionary).is_empty():
			return j
	return -1
