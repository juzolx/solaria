class_name Lineage
extends RefCounted
## Who your hero is beyond their class: racial power and awakening,
## transformations (bites, the fall, the Lich ritual), reputation with the
## races, escaping and sparing. The data lives in races.gd; this file is the
## rules, working on a GameState.

# =====================================================================
# Racial power
# =====================================================================

static func power(g: GameState) -> float:
	return g.race_power + g.race_power_points * Races.POWER_POINT

## An action happened: grow racial power if your race cares about it.
static func gain(g: GameState, action: String, amount := 1.0) -> void:
	var gains: Dictionary = Races.power_info(g.race())["gains"]
	if gains.has(action):
		g.race_power += float(gains[action]) * amount
	Hidden.gain(g, action, amount)

static func spend_power(g: GameState, amount := 1) -> void:
	amount = mini(amount, g.stat_points)
	if amount <= 0:
		return
	g.race_power_points += amount
	g.stat_points -= amount
	g.save_game()

## Every bonus your lineage gives: racial power, awakening ranks, your form.
static func bonus_sources(g: GameState) -> Array:
	var out: Array = [Races.power_bonus(g.race(), power(g))]
	var rk := Races.ranks(g.race())
	for i in mini(g.awaken, rk.size()):
		out.append(rk[i]["bonus"])
	if g.form != "":
		out.append(Races.FORMS[g.form]["passive"])
		if g.form == "Werewolf" and full_moon(g.floor_num):
			out.append({"atk": 1.2})
	return out

static func full_moon(floor_num: int) -> bool:
	return floor_num % int(Races.FORMS["Werewolf"]["moon"]) == 0

# =====================================================================
# Awakening
# =====================================================================

## The next rank ({} at the top).
static func next_rank(g: GameState) -> Dictionary:
	var rk := Races.ranks(g.race())
	return rk[g.awaken] if g.awaken < rk.size() else {}

static func rank_name(g: GameState) -> String:
	return Races.ranks(g.race())[g.awaken - 1]["name"] if g.awaken > 0 else g.race()

## Why you can't awaken yet ("" = you can, "trial" = win the trial first).
static func awaken_block(g: GameState) -> String:
	var nr := next_rank(g)
	if nr.is_empty():
		return "You're at the top"
	if g.level < int(nr["level"]):
		return "Reach level %d" % int(nr["level"])
	var need := float(nr["power"])
	if power(g) < need:
		return "Need %d %s (you have %d)" % [int(need), Races.power_info(g.race())["name"], int(power(g))]
	var key: Dictionary = nr["key"]
	if key.has("item") and not String(key["item"]) in g.race_keys:
		return "Find %s" % key["item"]
	if key.has("trial"):
		return "trial"
	return ""

static func awaken(g: GameState) -> bool:
	if awaken_block(g) != "":
		return false
	_rank_up(g)
	return true

static func _rank_up(g: GameState) -> void:
	var nr := next_rank(g)
	var key: Dictionary = nr["key"]
	if key.has("item"):
		g.race_keys.erase(key["item"])
	g.awaken += 1
	update_look(g)
	g.discovered[nr["name"]] = true
	g.codex.add("awakenings")
	g.events.append({"type": "awaken", "name": nr["name"], "race": g.race(), "color": Races.power_info(g.race())["color"], "text": nr["text"]})
	g.say("[color=%s]You awaken: %s![/color] %s" % [Races.power_info(g.race())["color"], nr["name"], nr["text"]])
	g.hero_hp = g.get_max_hp()
	g.save_game()

## Keeps the hero's look in step with their form and awakening.
static func update_look(g: GameState) -> void:
	g.appearance["form"] = g.form
	var look := ""
	var rk := Races.ranks(g.race())
	for i in mini(g.awaken, rk.size()):
		look = String(rk[i].get("look", look))
	g.appearance["look"] = look

## A key item might drop (bosses, realm monsters, treasure goblins).
static func roll_keys(g: GameState, boss_kind: String, species: String, was_goblin: bool) -> void:
	var nr := next_rank(g)
	if not nr.is_empty() and g.level >= int(nr["level"]) - 10:
		var key: Dictionary = nr["key"]
		if key.has("item") and not String(key["item"]) in g.race_keys and _source_matches(g, key["from"], boss_kind, species, was_goblin):
			if randf() * 100.0 < float(key["from"]["chance"]):
				_give_key(g, String(key["item"]))
	# The Lich's phylactery
	var lich: Dictionary = Races.FORMS["Lich"]
	if g.form == "" and g.hero_class in lich["need"]["classes"] and g.level >= int(lich["need"]["level"]) - 10 and not "Phylactery" in g.race_keys:
		if _source_matches(g, lich["item_from"], boss_kind, species, was_goblin) and randf() * 100.0 < float(lich["item_from"]["chance"]):
			_give_key(g, "Phylactery")
			g.say("[color=#7fd0f0]A cold voice whispers: a soul could be kept safe in this...[/color]")
	# The werewolf cure's flower
	if g.form == "Werewolf" and g.cure_active and g.cure_kills >= int(Races.FORMS["Werewolf"]["cure"]["kills"]) and not "Silver Moonbloom" in g.race_keys:
		var src: Dictionary = Races.FORMS["Werewolf"]["cure"]["from"]
		if _source_matches(g, src, boss_kind, species, was_goblin) and randf() * 100.0 < float(src["chance"]):
			_give_key(g, "Silver Moonbloom")

static func _give_key(g: GameState, item: String) -> void:
	g.race_keys.append(item)
	g.events.append({"type": "key_item", "name": item})
	g.say("[color=#fbbf24]*** You found %s! ***[/color]" % item)

static func _source_matches(g: GameState, src: Dictionary, boss_kind: String, species: String, was_goblin: bool) -> bool:
	if src.get("goblin", false):
		return was_goblin
	if src.has("boss"):
		return species == String(src["boss"])
	if src.has("realm"):
		if GameData.realm_of(g.floor_num) != String(src["realm"]) or was_goblin:
			return false
		match String(src.get("kind", "any")):
			"mid":
				return boss_kind == "mid"
			"zone":
				return boss_kind == "zone"
		return true
	return false

# =====================================================================
# Transformations
# =====================================================================

## A monster hit you: maybe it was a bite.
static func on_hit(g: GameState) -> void:
	gain(g, "hit")
	if g.form != "" or g.lycan_pending:
		return
	for f in ["Vampire", "Werewolf"]:
		var fd: Dictionary = Races.FORMS[f]
		if g.race() in fd["from"] and g.enemy_species in fd["biters"] and randf() * 100.0 < float(fd["bite_chance"]):
			if f == "Vampire":
				transform(g, "Vampire")
				g.say("[color=#b8263a]The %s's teeth sink into your neck. Your blood runs cold... and then it hungers. You are a Vampire.[/color]" % Monsters.name_of(g.enemy_species))
			else:
				g.lycan_pending = true
				g.say("[color=#8b9bb4]The %s's bite burns. Something in your blood is waiting for the full moon...[/color]" % Monsters.name_of(g.enemy_species))
				g.events.append({"type": "bitten"})
			return

## A new floor: the moon may be full.
static func on_floor(g: GameState) -> void:
	g.phylactery_used = false
	if g.lycan_pending and full_moon(g.floor_num):
		g.lycan_pending = false
		transform(g, "Werewolf")
		g.say("[color=#8b9bb4]The full moon rises. Your bones crack and stretch. You are a Werewolf.[/color]")
	elif g.form == "Werewolf" and full_moon(g.floor_num):
		g.say("[color=#8b9bb4]Full moon. The wolf in you is strongest tonight (+20% Attack this floor).[/color]")

## Faith moved: an Angel who falls too far becomes a Fallen Angel.
static func on_faith(g: GameState) -> void:
	if g.race() == "Angel" and g.form == "" and g.faith <= float(Races.FORMS["Fallen Angel"]["fall_at"]):
		transform(g, "Fallen Angel")
		g.say("[color=#5a6988]Your halo cracks. Your wings turn black. There is no going back: you are a Fallen Angel.[/color]")

static func transform(g: GameState, f: String) -> void:
	g._page("transform")
	g.form = f
	g.cure_active = false
	g.cure_kills = 0
	update_look(g)
	g.discovered[f] = true
	g.codex.add("transformations")
	g.events.append({"type": "transform", "form": f, "color": Races.FORMS[f]["color"]})
	g.hero_hp = mini(g.hero_hp, g.get_max_hp())
	g.save_game()

## Lich: why the ritual can't start ("" = it can).
static func lich_block(g: GameState) -> String:
	var need: Dictionary = Races.FORMS["Lich"]["need"]
	if g.form != "":
		return "You are already a %s" % g.form
	if not g.hero_class in need["classes"]:
		return "Only a %s can do it" % " or ".join(need["classes"])
	if g.level < int(need["level"]):
		return "Reach level %d" % int(need["level"])
	if g.top_tag() != String(need["tag"]):
		return "Your skills must lean to Shadow"
	if not String(need["item"]) in g.race_keys:
		return "You need a Phylactery (%s)" % Races.source_text(Races.FORMS["Lich"]["item_from"])
	return ""

static func lich_ritual(g: GameState) -> bool:
	if lich_block(g) != "":
		return false
	g.race_keys.erase("Phylactery")
	transform(g, "Lich")
	g.say("[color=#7fd0f0]You seal your soul in the phylactery. Your heart stops. You don't need it anymore. You are a Lich.[/color]")
	return true

## Once per floor, a Lich survives a killing blow.
static func save_from_death(g: GameState) -> bool:
	if g.form == "Lich" and not g.phylactery_used:
		g.phylactery_used = true
		g.hero_hp = 1
		g.events.append({"type": "phylactery"})
		g.say("[color=#7fd0f0]Your phylactery pulls you back from death![/color]")
		return true
	return false

# ---------- Cures (Vampire and Werewolf only, and only if you want one) ----------

static func cure_info(g: GameState) -> Dictionary:
	return Races.FORMS.get(g.form, {}).get("cure", {})

static func start_cure(g: GameState) -> void:
	if cure_info(g).is_empty() or g.cure_active:
		return
	g.cure_active = true
	g.cure_kills = 0
	g.say("[color=#e8b14a]You begin the search for a cure.[/color]")
	g.save_game()

static func on_kill_cure(g: GameState, species: String) -> void:
	if g.cure_active and species in Races.FORMS[g.form].get("biters", []):
		g.cure_kills += 1

## What's left of the cure ("" = ready to finish).
static func cure_block(g: GameState) -> String:
	var c := cure_info(g)
	if c.is_empty() or not g.cure_active:
		return "No cure started"
	if g.cure_kills < int(c["kills"]):
		return "%d / %d hunted" % [g.cure_kills, int(c["kills"])]
	if c.has("item") and not String(c["item"]) in g.race_keys:
		return "Find a %s" % c["item"]
	return ""

## Finish the cure: a trial (Vampire) or using the item (Werewolf).
static func finish_cure(g: GameState) -> bool:
	if cure_block(g) != "":
		return false
	var c := cure_info(g)
	if c.has("trial"):
		return g.start_special_trial(c["trial"], "cure", {})
	g.race_keys.erase(c["item"])
	cured(g)
	return true

static func cured(g: GameState) -> void:
	var was := g.form
	g.form = ""
	g.cure_active = false
	g.cure_kills = 0
	update_look(g)
	g.codex.add("cures")
	ClassTree.count(g, "cures")
	g.events.append({"type": "cured", "form": was})
	g.say("[color=#4ade80]You are cured. You are no longer a %s.[/color]" % was)
	g.save_game()

# =====================================================================
# Reputation
# =====================================================================

static func rep(g: GameState, race: String) -> float:
	if g.rep.is_empty():
		g.rep = Races.start_rep(g.race())
	return float(g.rep.get(race, 0.0))

## Changes standing with a race; its rivals feel the opposite (half as much).
static func change_rep(g: GameState, race: String, amount: float, linked := true) -> void:
	if race == "" or amount == 0.0:
		return
	var before := Races.rep_index(rep(g, race))
	g.rep[race] = clampf(rep(g, race) + amount, Races.REP_MIN, Races.REP_MAX)
	if linked:
		for rv in Races.RIVALS.get(race, []):
			change_rep(g, rv, -amount * Races.RIVAL_SHARE, false)
	var after := Races.rep_index(rep(g, race))
	g.tip("reputation", "Your standing with a race changed! Check Hero › Race. Sparing a race's people raises it; killing them lowers it.")
	if after != before:
		var lv := Races.rep_level(rep(g, race))
		g.say("[color=%s]The %s now see you as %s.[/color]" % [lv[1], race_plural(race), lv[0]])
		g.events.append({"type": "rep", "race": race, "level": lv[0], "color": lv[1], "up": after > before})

static func race_plural(race: String) -> String:
	match race:
		"Dwarf":
			return "Dwarves"
		"Elf":
			return "Elves"
		"Fairy":
			return "Fairies"
		"Beastkin", "Dragonkin", "Undead":
			return race
	return race + "s"

static func on_kill(g: GameState, species: String, tier: int, boss_kind: String, was_goblin: bool) -> void:
	gain(g, "kill")
	if tier >= Monsters.RARE:
		gain(g, "rare_kill")
	if boss_kind != "":
		gain(g, "boss")
	if g.hero_hp < g.get_max_hp() * 0.3:
		gain(g, "low_hp_kill")
	if was_goblin:
		gain(g, "goblin")
	var realm := GameData.realm_of(g.floor_num)
	if realm != "":
		gain(g, "realm:" + realm)
	if g.enemy_people != "":
		change_rep(g, g.enemy_people, Races.REP_KILL * (10.0 if boss_kind != "" else 1.0))
	on_kill_cure(g, species)
	roll_keys(g, boss_kind, species, was_goblin)

## Their people hit harder when they hate you.
static func enemy_attack_mult(g: GameState) -> float:
	if g.enemy_people != "" and Races.rep_index(rep(g, g.enemy_people)) == 0:
		return Races.REP_HATED_ATK
	return 1.0

# =====================================================================
# Escaping and sparing
# =====================================================================

## Chance (%) to get away from this fight, or 0 if you can't run.
static func escape_chance(g: GameState) -> float:
	if g.enemy_calamity > 0 or g.enemy_is_boss or g.enemy_hp <= 0 or g.enemy_goblin or g.horde_left > 0:
		return 0.0
	var c := Races.ESCAPE_BASE + g.stat("AGI") * Races.ESCAPE_PER_AGI - g.enemy_tier * Races.ESCAPE_PER_TIER
	if g.enemy_people != "" and Races.rep_index(rep(g, g.enemy_people)) >= 3:
		c += 20.0  # friendly people let you go
	c += ClassTree.escape_bonus(g)
	return clampf(c, Races.ESCAPE_MIN, Races.ESCAPE_MAX + ClassTree.escape_bonus(g) * 0.5)

static func escape_block(g: GameState) -> String:
	if Portals.inside(g):
		return Portals.no_run_text(g)
	if g.enemy_calamity > 0:
		return "There's no running now"
	if g.enemy_is_boss:
		return "You can't run from a boss"
	if g.enemy_goblin:
		return "It's running from you"
	if g.horde_left > 0:
		return "The horde surrounds you"
	if g.enemy_hp <= 0 or g.hero_hp <= 0:
		return "Not now"
	return ""

## Try to run. Returns true if you got away.
static func try_escape(g: GameState) -> bool:
	if escape_block(g) != "":
		return false
	g.feats["escapes"] = int(g.feats.get("escapes", 0)) + 1
	g.feats["clean_streak"] = 0
	var sure := escape_chance(g) >= 100.0
	if randf() * 100.0 < escape_chance(g):
		if sure:
			Hidden.count(g, "sure_escapes")
		g.say("[color=#a3e635]You slip away from the %s.[/color] (No XP or loot from it.)" % g.enemy_name)
		ClassTree.count(g, "escapes")
		g.events.append({"type": "escaped"})
		g.codex.add("escapes")
		g.kill_streak = 0
		gain(g, "flee")
		if g.enemy_people != "":
			change_rep(g, g.enemy_people, Races.REP_SPARE * 0.5)
		_move_on(g)
		return true
	g.say("[color=#f87171]You try to run, but the %s blocks your way![/color]" % g.enemy_name)
	g.events.append({"type": "escape_failed"})
	g.free_hit()
	return false

## A beaten monster (under 25% HP) can be let go: it becomes a friend.
static func can_spare(g: GameState) -> bool:
	if Portals.inside(g):  # no sparing in a rift or a trial
		return false
	return g.enemy_calamity == 0 and not g.enemy_is_boss and not g.enemy_goblin and g.enemy_hp > 0 and g.enemy_hp <= g.enemy_max_hp * Races.SPARE_AT and g.horde_left <= 0

static func spare(g: GameState) -> bool:
	if not can_spare(g):
		return false
	var befriended: Dictionary = g.feats.get("befriended", {})
	var key := g.enemy_species
	var tiers: Dictionary = g.feats.get("befriended_tiers", {})
	befriended[key] = true
	tiers[str(g.enemy_tier)] = true
	g.feats["befriended"] = befriended
	g.feats["befriended_tiers"] = tiers
	g.codex.add("spared")
	ClassTree.on_spare(g)
	g.say("[color=#4ade80]You lower your weapon. The %s looks at you a long moment, then slinks away. A friend, maybe.[/color]" % g.enemy_name)
	g.events.append({"type": "spared", "name": g.enemy_name})
	gain(g, "spare")
	if g.enemy_people != "":
		change_rep(g, g.enemy_people, Races.REP_SPARE)
	g.xp += int(GameData.xp_for_kill(g.floor_num, false) * 0.5)
	g.gain_xp(0)  # QA r2 #26: a full bar levels up now, not at the next kill
	_move_on(g)
	return true

static func _move_on(g: GameState) -> void:
	g.fight += 1
	if g.fight > GameData.FIGHTS_PER_FLOOR:
		g.next_floor()
	g.spawn_enemy()
	g.save_game()

# =====================================================================
# Saving
# =====================================================================

static func to_save(g: GameState) -> Dictionary:
	return {"race_power": g.race_power, "race_power_points": g.race_power_points, "awaken": g.awaken, "race_keys": g.race_keys,
		"form": g.form, "lycan_pending": g.lycan_pending, "cure_active": g.cure_active, "cure_kills": g.cure_kills,
		"rep": g.rep, "feats": g.feats, "realm_order": g.realm_order, "hidden": g.hidden, "hidden_class": g.hidden_class,
		"hidden_stage": g.hidden_stage, "hidden_offer": g.hidden_offer, "hidden_offer_level": g.hidden_offer_level, "hidden_seen": g.hidden_seen, "hidden_v2": true,
		"quest": g.quest, "merchant_who": g.merchant_who}

static func from_save(g: GameState, d: Dictionary) -> void:
	g.race_power = float(d.get("race_power", 0.0))
	g.race_power_points = int(d.get("race_power_points", 0))
	g.awaken = int(d.get("awaken", 0))
	g.race_keys.assign(d.get("race_keys", []))
	g.form = String(d.get("form", ""))
	g.lycan_pending = bool(d.get("lycan_pending", false))
	g.cure_active = bool(d.get("cure_active", false))
	g.cure_kills = int(d.get("cure_kills", 0))
	g.rep = d.get("rep", {})
	if g.rep.is_empty():
		g.rep = Races.start_rep(g.race())
	g.feats = d.get("feats", {})
	g.realm_order.assign(d.get("realm_order", []))
	if not d.has("realm_order") and g.best_floor > Realms.FIRST_FLOOR:
		Realms.fill_order(g)  # an old save already past floor 250
	g.hidden = d.get("hidden", {})
	g.hidden_class = String(d.get("hidden_class", ""))
	g.hidden_stage = d.get("hidden_stage", {})
	g.hidden_offer = d.get("hidden_offer", [])
	g.hidden_offer_level = int(d.get("hidden_offer_level", 0))
	g.hidden_seen = d.get("hidden_seen", {})
	if not d.has("hidden_v2"):
		g.hidden_class = ""  # before the rework a hidden class sat on top of your class; now taking one is a choice at 15, 35 or 60
	g.quest = d.get("quest", {})
	g.merchant_who = String(d.get("merchant_who", ""))
	update_look(g)
