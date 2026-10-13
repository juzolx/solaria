class_name Hidden
extends RefCounted
## Hidden classes: secret classes you unlock by how you play, in 3 tiers.
##
##  * Discoveries (easy): found by accident, 1 stage. A hint that more exist.
##  * Masteries (hard, level 60+): a long feat plus a trial, 2 stages.
##  * Legends (level 100+): pull from several systems at once, 3 stages.
##    Some can only be held by one hero on your account at a time.
##
## A hidden class sits on top of your class: you keep your class, skills and
## path, and the hidden class adds its title, bonuses and its own special
## stat (grows from actions, or 0.1 per stat point). Higher tiers aren't
## stronger at the same level. They grow further (more stages, a stat that
## scales further) and show off more (a tier badge and a glow).
##
## Story text here is a placeholder until the lore is written.

const TIER_NAMES := ["", "Discovery", "Mastery", "Legend"]
const TIER_COLORS := ["", "#4ade80", "#38bdf8", "#e8b14a"]
const STAT_SCALE := [0.0, 1.0, 1.4, 2.0]  # how far a tier's special stat scales

# need: [label, feat key or special, amount]. Special keys are worked out in _have().
# stages: names; stage_bonus: added at each stage; stage_need: what each later stage needs.
# grow: action -> special stat per action (only while this is your hidden class).
# per_point: bonus per point of its special stat.
const CLASSES := {
	"jester": {"name": "Jester", "tier": 1, "stat": "Luck", "color": "#a8ca58",
		"lore": "Fortune favors the foolish. You've noticed.",
		"rumor": "They say the Wheel loves someone who keeps winning...",
		"need": [["Win the Wheel 5 times in a row", "wheel_best", 5]],
		"stages": ["Jester"], "stage_bonus": [{"crit": 5, "gold_find": 10, "dodge": 3}],
		"grow": {"gamble": 1.0, "crit": 0.005}, "per_point": {"crit": 0.04, "gold_find": 0.1}},
	"treasure_hunter": {"name": "Treasure Hunter", "tier": 1, "stat": "Fortune", "color": "#facc15",
		"lore": "Some people hear a goblin's coins jingle three floors away.",
		"rumor": "Catch enough of those little thieves and you start thinking like one...",
		"need": [["Catch 25 treasure goblins", "goblins", 25]],
		"stages": ["Treasure Hunter"], "stage_bonus": [{"gold_find": 20, "stone_find": 10}],
		"grow": {"goblin": 2.0, "rare_kill": 0.2}, "per_point": {"gold_find": 0.15, "stone_find": 0.05}},
	"fool": {"name": "The Fool", "tier": 1, "stat": "Folly", "color": "#f472b6",
		"lore": "Fall down two hundred and fifty times. Get up once more.",
		"rumor": "Some say dying enough times teaches you something...",
		"need": [["Fall 250 times on this hero", "deaths", 250]],
		"stages": ["The Fool"], "stage_bonus": [{"hp": 1.1, "rage": 10}],
		"grow": {"death": 0.1, "hit": 0.001}, "per_point": {"hp": 0.001, "regen": 0.002}},
	"alchemist": {"name": "Alchemist", "tier": 1, "stat": "Elixir", "color": "#2dd4bf",
		"lore": "You've drunk enough potions to know what's really in them.",
		"rumor": "Drink enough potions and you start to taste the recipe...",
		"need": [["Craft 200 potions", "potions_crafted", 200], ["Drink 300 potions", "potions_drunk", 300]],
		"stages": ["Alchemist"], "stage_bonus": [{"potion": 30, "regen": 1}],
		"grow": {"potion": 0.5, "craft": 0.2}, "per_point": {"potion": 0.5, "regen": 0.01}},

	"gladiator": {"name": "Gladiator", "tier": 2, "stat": "Glory", "color": "#dc2626",
		"lore": "A thousand fights. No running, no potions, no excuses.",
		"rumor": "The arena only respects those who never run and never drink...",
		"need": [["Reach level 60", "level", 60], ["Win 1,000 fights in a row without escaping, dying or a potion", "clean_best", 1000],
			["Beat the Arena Champion", "trial", 1]],
		"trial": {"name": "The Arena Champion", "art": "boss_grendel", "lore": "Undefeated in nine hundred fights. Ten if you count the ones he lost."},
		"stages": ["Gladiator", "Arena Lord"], "stage_bonus": [{"atk": 1.06, "def": 1.06}, {"atk": 1.1, "hp": 1.1}],
		"stage_need": [[], [["Reach level 100", "level", 100], ["3,000 kills as a Gladiator", "class_kills", 3000]]],
		"grow": {"kill": 0.01, "boss": 1.0}, "per_point": {"atk": 0.001, "def": 0.001}},
	"executioner": {"name": "Executioner", "tier": 2, "stat": "Dread", "color": "#8b5cf6",
		"lore": "You don't fight monsters anymore. You end them.",
		"rumor": "They say a hero who finishes enough fights with a skill earns a darker name...",
		"need": [["Reach level 60", "level", 60], ["Finish 5,000 monsters with a skill", "skill_kills", 5000],
			["Finish 25 Legendary or Mythic monsters with a skill", "skill_kills_elite", 25], ["Finish a zone boss with a skill", "boss_skill_finish", 1]],
		"stages": ["Executioner", "Headsman of Kings"], "stage_bonus": [{"execute": 25, "crit": 4}, {"execute": 25, "atk": 1.08}],
		"stage_need": [[], [["Reach level 100", "level", 100], ["3,000 kills as an Executioner", "class_kills", 3000]]],
		"grow": {"skill_kill": 0.05}, "per_point": {"execute": 0.2, "crit": 0.02}},
	"plague_doctor": {"name": "Plague Doctor", "tier": 2, "stat": "Miasma", "color": "#84cc16",
		"lore": "You don't kill them. The rot does. You just help it along.",
		"rumor": "Burn enough monsters to ash and the smoke starts to talk...",
		"need": [["Reach level 60", "level", 60], ["5,000 kills from burns", "burn_kills", 5000], ["Kill a zone boss with a burn", "burn_boss", 1]],
		"stages": ["Plague Doctor", "Pestilence"], "stage_bonus": [{"skill": 1.08, "regen": 1}, {"skill": 1.1, "hp": 1.08}],
		"stage_need": [[], [["Reach level 100", "level", 100], ["3,000 kills as a Plague Doctor", "class_kills", 3000]]],
		"grow": {"burn_kill": 0.05}, "per_point": {"skill": 0.002, "lifesteal": 0.02}, "burn_power": 0.5},
	"beast_tamer": {"name": "Beast Tamer", "tier": 2, "stat": "Bond", "color": "#d9a066",
		"lore": "Every monster you let go remembers you. Some of them come back.",
		"rumor": "Spare enough beaten monsters and one day they'll fight for you...",
		"need": [["Reach level 60", "level", 60], ["Befriend 60 kinds of monster (spare them)", "befriended", 60],
			["Befriend at least one of every tier, Common to Mythic", "befriended_tiers", 6]],
		"stages": ["Beast Tamer", "Beast Lord"], "stage_bonus": [{"hp": 1.06, "dodge": 3}, {"atk": 1.06, "hp": 1.08}],
		"stage_need": [[], [["Reach level 100", "level", 100], ["Befriend 90 kinds of monster", "befriended", 90]]],
		"grow": {"spare": 1.0, "kill": 0.005}, "per_point": {"hp": 0.001, "dodge": 0.02}, "companion": 0.2},

	"chosen_hero": {"name": "Chosen Hero", "tier": 3, "stat": "Destiny", "color": "#fde68a", "one_per_account": true,
		"lore": "Nobody chose you. You reached the bottom of the world anyway, with one life.",
		"rumor": "They say only one hero, with only one life, will ever reach the deepest realm...",
		"need": [["Reach floor 500 on Hardcore", "hc_floor", 500]],
		"stages": ["Chosen Hero", "Hero of the Realms", "The Hero of Legend"],
		"stage_bonus": [{"atk": 1.08, "hp": 1.08, "xp": 10}, {"atk": 1.08, "hp": 1.08}, {"atk": 1.1, "hp": 1.1, "def": 1.08}],
		"stage_need": [[], [["Reach floor 600 on Hardcore", "hc_floor", 600]], [["Reach floor 750 on Hardcore", "hc_floor", 750]]],
		"grow": {"boss": 1.0, "floor": 0.05}, "per_point": {"atk": 0.001, "hp": 0.001}},
	"demon_king": {"name": "Demon King", "tier": 3, "stat": "Dominion", "color": "#e43b44", "one_per_account": true,
		"lore": "The Abyss has had many lords. It has only ever had one king at a time.",
		"rumor": "A demon lord who takes the Abyss's throne with a heart of pure evil...",
		"need": [["A Demon at the top Demonic rank", "demon_top", 1], ["Defeat the ruler of the Cinder Abyss", "boss:Azgaroth, Lord of the Abyss", 1],
			["Evil faith of 95 or more", "evil", 95]],
		"stages": ["Demon King", "Abyssal Sovereign", "The Demon God"],
		"stage_bonus": [{"atk": 1.1, "lifesteal": 4}, {"atk": 1.08, "hp": 1.08}, {"atk": 1.1, "hp": 1.1, "lifesteal": 3}],
		"stage_need": [[], [["Reach level 175", "level", 175]], [["Reach level 200", "level", 200], ["10,000 kills as Demon King", "class_kills", 10000]]],
		"grow": {"kill": 0.01, "evil": 0.3, "low_hp_kill": 0.1}, "per_point": {"atk": 0.001, "lifesteal": 0.02}},
}
const ORDER := ["jester", "treasure_hunter", "fool", "alchemist", "gladiator", "executioner", "plague_doctor", "beast_tamer",
	"chosen_hero", "demon_king"]

static func info(id: String) -> Dictionary:
	return CLASSES.get(id, {})

# ---------- Counting what you do ----------

static func count(g: GameState, key: String, n := 1) -> void:
	g.feats[key] = int(g.feats.get(key, 0)) + n

static func best(g: GameState, key: String, value: int) -> void:
	g.feats[key] = maxi(int(g.feats.get(key, 0)), value)

static func flag(g: GameState, key: String) -> void:
	g.feats[key] = 1

## How much of a requirement you have.
static func _have(g: GameState, key: String) -> int:
	match key:
		"level":
			return g.level
		"befriended":
			return (g.feats.get("befriended", {}) as Dictionary).size()
		"befriended_tiers":
			return (g.feats.get("befriended_tiers", {}) as Dictionary).size()
		"wanderer_level":
			return g.level if g.hero_class == "Wanderer" else 0
		"hc_floor":
			return g.best_floor if g.hardcore else 0
		"demon_top":
			return 1 if g.race() == "Demon" and g.awaken >= Races.ranks("Demon").size() else 0
		"evil":
			return int(-g.faith)
		"class_kills":
			return int((g.feats.get("class_kills", {}) as Dictionary).get(g.hidden_class, 0))
	if key.begins_with("boss:"):
		return g.codex.kills(key.substr(5))
	return int(g.feats.get(key, 0))

## [[label, have, need], ...] for what unlocks a class.
static func progress(g: GameState, id: String) -> Array:
	var out: Array = []
	for n in info(id)["need"]:
		if n[1] == "trial":
			out.append([n[0], 1 if g.feats.get("trial_" + id, 0) else 0, 1])
		else:
			out.append([n[0], _have(g, n[1]), int(n[2])])
	return out

## 0..1: how close you are (used for ??? hints).
static func closeness(g: GameState, id: String) -> float:
	var p := progress(g, id)
	var t := 0.0
	for line in p:
		t += clampf(float(line[1]) / maxf(1.0, float(line[2])), 0.0, 1.0)
	return t / maxf(1.0, p.size())

## Everything but the trial is done.
static func ready_for_trial(g: GameState, id: String) -> bool:
	for line in progress(g, id):
		if line[0] != "" and int(line[1]) < int(line[2]) and not String(line[0]).begins_with("Beat"):
			return false
	return info(id).has("trial") and not g.feats.get("trial_" + id, 0)

## Who holds a one-per-account Legend (a slot number, 0 = nobody).
static func holder(g: GameState, id: String) -> int:
	var slot := g.codex.stat("legend_" + id)
	if slot > 0 and slot != g.slot and not GameState.has_slot(slot):
		return 0
	return slot

static func block_reason(g: GameState, id: String) -> String:
	if g.hidden.has(id):
		return ""
	var c := info(id)
	if c.get("one_per_account", false):
		var h := holder(g, id)
		if h > 0 and h != g.slot:
			return "Another of your heroes already holds this title"
	for line in progress(g, id):
		if int(line[1]) < int(line[2]):
			return line[0]
	return ""

## Checks every hidden class and unlocks any you've earned.
static func check(g: GameState) -> void:
	for id in ORDER:
		if g.hidden.has(id):
			_check_stage(g, id)
			continue
		if block_reason(g, id) == "":
			unlock(g, id)

static func unlock(g: GameState, id: String) -> void:
	g._page("hidden")
	var c := info(id)
	g.hidden[id] = true
	g.hidden_stage[id] = 1
	if c.get("one_per_account", false):
		g.codex.stats["legend_" + id] = g.slot
		g.codex.dirty = true
	g.discovered[c["name"]] = true
	g.codex.add("hidden_classes")
	g.events.append({"type": "hidden_class", "id": id, "name": c["name"], "tier": int(c["tier"]), "color": c["color"], "lore": c["lore"]})
	g.say("[color=%s]*** HIDDEN CLASS UNLOCKED: %s ***[/color] %s" % [c["color"], c["name"], c["lore"]])
	if g.hidden_class == "":
		g.hidden_class = id
	g.save_game()

static func _check_stage(g: GameState, id: String) -> void:
	var c := info(id)
	var st := int(g.hidden_stage.get(id, 1))
	var needs: Array = c.get("stage_need", [])
	if st >= c["stages"].size() or st >= needs.size():
		return
	for n in needs[st]:
		if _have(g, n[1]) < int(n[2]):
			return
	g.hidden_stage[id] = st + 1
	var nm: String = c["stages"][st]
	g.discovered[nm] = true
	g.events.append({"type": "hidden_class", "id": id, "name": nm, "tier": int(c["tier"]), "color": c["color"], "lore": "Your %s grows: you are now %s." % [c["name"], nm]})
	g.say("[color=%s]Your hidden class grows: %s![/color]" % [c["color"], nm])

## What the next stage needs, as [[label, have, need]] ([] at the top).
static func stage_progress(g: GameState, id: String) -> Array:
	var c := info(id)
	var st := int(g.hidden_stage.get(id, 1))
	var needs: Array = c.get("stage_need", [])
	if st >= needs.size():
		return []
	var out: Array = []
	for n in needs[st]:
		out.append([n[0], _have(g, n[1]), int(n[2])])
	return out

## A camp-fire rumor about a hidden class you don't have yet.
static func rumor(g: GameState) -> String:
	var opts: Array = []
	for id in ORDER:
		if not g.hidden.has(id):
			opts.append(info(id)["rumor"])
	return opts.pick_random() if not opts.is_empty() else ""

static func use(g: GameState, id: String) -> void:
	if id == "" or g.hidden.has(id):
		g.hidden_class = id
		g.save_game()

## Your current hidden-class title ("" if none).
static func title(g: GameState) -> String:
	if g.hidden_class == "":
		return ""
	var c := info(g.hidden_class)
	return c["stages"][clampi(int(g.hidden_stage.get(g.hidden_class, 1)) - 1, 0, c["stages"].size() - 1)]

static func stat_name(g: GameState) -> String:
	return info(g.hidden_class).get("stat", "") if g.hidden_class != "" else ""

static func bonus_sources(g: GameState) -> Array:
	if g.hidden_class == "":
		return []
	var c := info(g.hidden_class)
	var out: Array = []
	for i in clampi(int(g.hidden_stage.get(g.hidden_class, 1)), 1, c["stage_bonus"].size()):
		out.append(c["stage_bonus"][i])
	var v := g.unique_value(c["stat"]) * float(STAT_SCALE[int(c["tier"])])
	var per: Dictionary = c["per_point"]
	var d := {}
	for k in per:
		d[k] = 1.0 + float(per[k]) * v if k in ["atk", "hp", "def", "skill"] else float(per[k]) * v
	out.append(d)
	return out

## What your hidden class's special stat gives now, and what grows it.
static func stat_text(g: GameState) -> String:
	if g.hidden_class == "":
		return ""
	var c := info(g.hidden_class)
	var b := bonus_sources(g)
	var gives := Classes.bonus_text(b[b.size() - 1]) if not b.is_empty() else ""
	var acts: Array = []
	for k in (c.get("grow", {}) as Dictionary):
		acts.append(String(k).replace("_", " "))
	return "Gives %s\nGrows from: %s." % [gives.trim_suffix("."), ", ".join(acts)]

## Your hidden class's special stat grows from an action.
static func gain(g: GameState, action: String, amount := 1.0) -> void:
	if g.hidden_class == "":
		return
	var c := info(g.hidden_class)
	var gr: Dictionary = c.get("grow", {})
	if gr.has(action):
		var n: String = c["stat"]
		g.unique[n] = float(g.unique.get(n, 0.0)) + float(gr[action]) * amount

# ---------- Hooks from the game ----------

static func on_kill(g: GameState, _species: String, tier: int, boss_kind: String, was_goblin: bool) -> void:
	count(g, "kills_total")
	if was_goblin:
		count(g, "goblins")
	if g.last_hit == "skill":
		count(g, "skill_kills")
		gain(g, "skill_kill")
		if tier >= Monsters.LEGENDARY:
			count(g, "skill_kills_elite")
		if boss_kind == "zone":
			flag(g, "boss_skill_finish")
	elif g.last_hit == "burn":
		count(g, "burn_kills")
		gain(g, "burn_kill")
		if boss_kind == "zone":
			flag(g, "burn_boss")
	count(g, "clean_streak")
	best(g, "clean_best", int(g.feats.get("clean_streak", 0)))
	if g.hidden_class != "":
		var ck: Dictionary = g.feats.get("class_kills", {})
		ck[g.hidden_class] = int(ck.get(g.hidden_class, 0)) + 1
		g.feats["class_kills"] = ck
	if int(g.feats.get("kills_total", 0)) % 25 == 0 or boss_kind != "":
		check(g)

static func on_death(g: GameState) -> void:
	count(g, "deaths")
	g.feats["clean_streak"] = 0
	check(g)

static func on_potion(g: GameState) -> void:
	count(g, "potions_drunk")
	g.feats["clean_streak"] = 0
	gain(g, "potion")

static func on_craft_potion(g: GameState) -> void:
	count(g, "potions_crafted")
	gain(g, "craft")
	check(g)

static func on_wheel(g: GameState, won: bool) -> void:
	if won:
		count(g, "wheel_streak")
		best(g, "wheel_best", int(g.feats.get("wheel_streak", 0)))
	else:
		g.feats["wheel_streak"] = 0
	check(g)

## Gladiator-style trial for a hidden class.
static func start_trial(g: GameState, id: String) -> bool:
	if not ready_for_trial(g, id):
		return false
	return g.start_special_trial(info(id)["trial"], "hidden", {"id": id})

static func trial_won(g: GameState, data: Dictionary) -> void:
	g.feats["trial_" + String(data.get("id", ""))] = 1
	check(g)

## Beast Tamer: a befriended beast fights beside you. Returns its damage (0 = none).
static func companion_power(g: GameState) -> float:
	if g.hidden_class == "":
		return 0.0
	var c := info(g.hidden_class)
	if not c.has("companion"):
		return 0.0
	return float(c["companion"]) + g.unique_value(c["stat"]) * 0.002
