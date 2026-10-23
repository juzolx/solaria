class_name Presets
extends RefCounted
## 2.1: one presets system. A preset bundles your stat spread, skills, worn gear,
## team and rows, and the supplies you take down. Merged from: builds (stats,
## skills, gear: Hero tab), gear loadouts (Gear tab) and team presets (Party tab;
## kept town-wide as team line-ups any hero can use, see the end of this file).
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
## stash: the shared vault (Profile.stash), so gear put away there is named as such.
static func apply(g: GameState, i: int, stash: Array = []) -> Array:
	var p := get_preset(g, i)
	var notes: Array = []
	if p.is_empty():
		return notes
	if p.has("stats"):
		_apply_stats(g, p["stats"])
	_apply_skills(g, p, notes)
	_apply_gear(g, p, notes, stash)
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
		var next: Array = slots.duplicate()
		for k in slots.size():
			var id: String = String(want[k]) if k < want.size() else ""
			if id == "" or g.skill_book.has(id):
				next[k] = id
			else:
				notes.append("Skipped %s: it's not in your skill book." % SkillData.skill_name(id))
		# skills leaving their slot come off properly (their buffs end)
		for old in slots.duplicate():
			if String(old) != "" and not next.has(old):
				g.unequip_skill(String(old))
		for k in slots.size():
			slots[k] = next[k]

static func _apply_gear(g: GameState, p: Dictionary, notes: Array, stash: Array) -> void:
	var gear: Dictionary = p.get("gear", {})
	var names: Dictionary = p.get("gear_names", {})
	for s in gear:
		var id := int(gear[s])
		var nm := String(names.get(s, "your old " + String(s).to_lower()))
		var found := g.find_item(id)
		if found.is_empty():
			var in_vault := false
			for it in stash:
				if int((it as Dictionary).get("id", -1)) == id:
					in_vault = true
					break
			notes.append("Skipped %s: it's in the vault." % nm if in_vault else "Skipped %s: it's gone." % nm)
		elif found["where"] == "bag":
			var item: Dictionary = found["item"]
			if not Races.can_wear(g, item):
				notes.append("Skipped %s: this hero can't wear it." % nm)
				continue
			if g.over_limit(id):
				notes.append("Skipped %s: it's over your bag's limit." % nm)
				continue
			g.equip(id)
			var after := g.find_item(id)
			if after.is_empty() or after["where"] != "equipped":
				notes.append("Skipped %s: it couldn't be put on." % nm)

static func _apply_party(g: GameState, want: Array, notes: Array) -> void:
	if g.hardcore:
		return
	var comps: Array = []
	var seen: Array = []
	for n in want:
		if int(n) == g.slot or seen.has(int(n)):
			continue  # no doubles, and you can't be your own companion
		seen.append(int(n))
		if GameState.has_slot(int(n)):
			comps.append(int(n))
		else:
			notes.append("Skipped a team member: that hero is gone.")
	if comps == g.party_slots:
		return
	if not g.in_town:
		notes.append("Team skipped: you pick that in town.")
		return
	if g.party != null:
		g.party.save_all()
	g.set_party(comps)

static func _apply_supplies(g: GameState, want: Dictionary, notes: Array) -> void:
	if not g.in_town:
		var any := false
		for k in want:
			if int(want[k]) != g.supply_carried(String(k)):
				any = true
		if any:
			notes.append("Supplies skipped: you pick those in town.")
		return
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

## Moves old gear loadouts (Gear tab) into empty preset slots. Ones that don't fit
## stay where they are (nothing is dropped) and move over once a slot is free.
## Safe to call any number of times.
static func migrate(g: GameState) -> void:
	ensure(g)
	var moved := false
	var left := 0
	for li in g.loadouts.size():
		var lo: Dictionary = g.loadouts[li]
		if lo.is_empty():
			continue
		var j := _first_empty(g)
		if j < 0:
			left += 1
			continue
		g.builds[j] = {"name": "Gear set %d" % (li + 1), "gear": lo.duplicate()}
		g.loadouts[li] = {}
		moved = true
	if left > 0 and not g.tips_seen.has("presets_full"):
		g.tips_seen["presets_full"] = true
		g.say("%d old gear set%s didn't fit in Presets. Clear a preset to bring %s over." % [left, "" if left == 1 else "s", "it" if left == 1 else "them"])
		moved = true
	if moved:
		g.save_game()

static func _first_empty(g: GameState) -> int:
	for j in g.builds.size():
		if (g.builds[j] as Dictionary).is_empty():
			return j
	return -1

# ---------- Team line-ups: shared by every hero in this town (Profile.presets) ----------
# A line-up is a leader plus companions. Use it from any hero: the same leader just
# changes the team; another leader means switching to that hero (in town). Every
# hero keeps their own gear and skills: nothing is copied or moved between heroes.

const TEAM_SLOTS := 3

static func teams(profile: Profile) -> Array:
	while profile.presets.size() < TEAM_SLOTS:
		profile.presets.append({})
	return profile.presets

static func team_saved(profile: Profile, i: int) -> bool:
	return not (teams(profile)[i] as Dictionary).get("slots", []).is_empty()

static func save_team(g: GameState, profile: Profile, i: int) -> void:
	teams(profile)[i] = {"slots": [g.slot] + g.party_slots}
	profile.save()

static func clear_team(profile: Profile, i: int) -> void:
	teams(profile)[i] = {}
	profile.save()

## Who a line-up would field now: {"leader": slot (-1 = gone), "comps": [...], "notes": [...]}.
## Heroes that are gone are skipped, doubles dropped.
static func team_plan(profile: Profile, i: int) -> Dictionary:
	var slots: Array = (teams(profile)[i] as Dictionary).get("slots", [])
	var notes: Array = []
	var leader := -1
	var comps: Array = []
	var seen: Array = []
	for k in slots.size():
		var n := int(slots[k])
		if seen.has(n):
			continue
		seen.append(n)
		if not GameState.has_slot(n):
			notes.append("The leader of that team is gone." if k == 0 else "Skipped a team member: that hero is gone.")
			continue
		if k == 0:
			leader = n
		else:
			comps.append(n)
	return {"leader": leader, "comps": comps.slice(0, Party.MAX_COMPANIONS), "notes": notes}

## Names for a line-up button: "Mara + Fen".
static func team_label(profile: Profile, i: int) -> String:
	var slots: Array = (teams(profile)[i] as Dictionary).get("slots", [])
	var names: Array = []
	for n in slots:
		names.append(str(GameState.slot_meta(int(n)).get("name", "Hero")) if GameState.has_slot(int(n)) else "(gone)")
	return " + ".join(names) if not names.is_empty() else "Empty"

## Uses line-up i from hero g. Returns {"ok": something happened, "switch": leader slot
## to switch to (-1 = none), "comps": [...], "notes": [...]}. Same leader: the team
## changes right away.
static func apply_team(g: GameState, profile: Profile, i: int) -> Dictionary:
	var plan := team_plan(profile, i)
	var notes: Array = plan["notes"]
	var out := {"ok": false, "switch": -1, "comps": plan["comps"], "notes": notes}
	if g.hardcore:
		notes.append("Hardcore heroes fight alone.")
		return out
	if int(plan["leader"]) < 0:
		return out
	if not g.in_town:
		notes.append("Teams change in town.")
		return out
	out["ok"] = true
	if int(plan["leader"]) != g.slot:
		out["switch"] = int(plan["leader"])
		return out
	if plan["comps"] != g.party_slots:
		if g.party != null:
			g.party.save_all()
		g.set_party(plan["comps"])
	return out

## After switching heroes for a line-up (main.gd): the team joins only if that hero
## is in town and can have one. Returns a note ("" = the team is set).
static func apply_pending_team(g: GameState, comps: Array) -> String:
	var who := g.hero_name if g.hero_name != "" else "Your hero"
	if g.hardcore:
		return "%s is Hardcore and fights alone." % who
	if not g.in_town or g.run_over:
		return "%s is in the dungeon: the team changes once they're back in town." % who
	var keep: Array = []
	for n in comps:
		if int(n) != g.slot and not keep.has(int(n)) and GameState.has_slot(int(n)):
			keep.append(int(n))
	g.set_party(keep)
	return ""

static func team_leader_gone(profile: Profile, i: int) -> bool:
	return team_saved(profile, i) and int(team_plan(profile, i)["leader"]) < 0
