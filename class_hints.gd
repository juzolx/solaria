class_name ClassHints
extends RefCounted
## 2.1 G7: gentle, mysterious hints that hidden and God classes EXIST and how one
## might chase them, without ever naming a class you haven't earned or saying how
## many there are. All data-driven:
##  * hidden classes: their own rumor line (Hidden.CLASSES[id]["rumor"]);
##  * God classes: a riddle built from their secret deeds (GodClasses.LIST[id]["deeds"])
##    through DEED_PHRASES, so a new God class gets riddles for free.
## Shown sparingly and only after milestones: a stranger at the Inn now and then,
## a whisper in the log when a hero first passes a milestone floor, and riddles in
## Character > Class that open a few at a time as the hero goes deeper.

## Deed key -> a vague phrase ("one who ..."). Keys that would point at a route
## (class:, path:, race:) or are too plain (level) are left out on purpose.
const DEED_PHRASES := {
	"clean_best": "never runs, never drinks and never falls, fight after fight",
	"kills_total": "has slain more than anyone can count",
	"codex:champions": "breaks champions like kindling",
	"floor": "has walked deeper than the old maps go",
	"codex:deep_rifts": "keeps coming back out of the deepest rifts",
	"skill_kills_elite": "ends the fiercest beasts with a single art",
	"skill_kills": "lets their arts finish every fight",
	"evil": "has let their heart go fully dark",
	"good": "keeps a heart of pure light",
	"codex:graves": "goes back for what the dead left behind",
	"codex:stones": "has gathered stones by the hundred",
	"codex:sets_crafted": "forges whole sets at the anvil",
	"codex:pets": "keeps a whole menagerie",
	"codex:pilgrims_helped": "helps every pilgrim on the road",
	"codex:spared": "shows mercy to beaten foes",
	"codex:skills_sold": "trades away their own arts",
	"sure_escapes": "walks away from fights they could win",
	"codex:traps_spotted": "sees every trap before it bites",
	"confuses": "turns monsters with a song",
	"codex:travelers": "stops to talk with every traveler",
}

const OPENERS := ["Some say a God answers one who %s.", "An old priest swears the Gods watch for one who %s.",
	"They say something far above the ranks listens for one who %s."]
const STRANGERS := ["A hooded stranger mutters:", "An old soldier by the fire says:", "A tired pilgrim whispers:"]

## Hints open after the first milestone (the boss on floor 25, or level 10).
const OPEN_FLOOR := 25
const OPEN_LEVEL := 10
## God riddles need a deeper milestone (a region boss, or level 35 / a hidden class).
const GOD_FLOOR := 100
const GOD_LEVEL := 35
const WHISPER_EVERY := 50   # a log whisper at most once per this many new best floors
const INN_CHANCE := 0.25    # how often the Inn's overheard line is a hint
const RIDDLE_START := 25    # Class tab riddles: the first at this floor...
const RIDDLE_EVERY := 75    # ...one more every this many floors...
const RIDDLE_MAX := 6       # ...up to this many

static func hints_open(g: GameState) -> bool:
	return g.best_floor >= OPEN_FLOOR or g.level >= OPEN_LEVEL

static func gods_open(g: GameState) -> bool:
	return g.best_floor >= GOD_FLOOR or g.level >= GOD_LEVEL or not g.hidden.is_empty() or g.hidden_class != ""

## A God class's riddle: two of its deeds, in vague words. The same every time.
static func god_riddle(id: String, opener := 0) -> String:
	var parts: Array = []
	for d in GodClasses.info(id).get("deeds", []):
		var ph := String(DEED_PHRASES.get(String(d[1]), ""))
		if ph != "" and not ph in parts:
			parts.append(ph)
		if parts.size() == 2:
			break
	if parts.is_empty():
		return ""
	return String(OPENERS[opener % OPENERS.size()]) % " and ".join(parts)

## Every hint this hero could hear right now (rumors of unearned hidden classes,
## and riddles of God classes once the deeper milestone is passed).
static func pool(g: GameState) -> Array:
	var out: Array = []
	if not hints_open(g):
		return out
	for id in Hidden.ORDER:
		if g.hidden.has(id) or g.hidden_class == id:
			continue
		var r := String(Hidden.info(id).get("rumor", ""))
		if r != "":
			out.append(r)
	if gods_open(g) and g.god_class == "":
		var i := 0
		for id in GodClasses.LIST:
			if id in g.god_offers:
				continue
			var r := god_riddle(id, i)
			i += 1
			if r != "":
				out.append(r)
	return out

## The Inn's overheard line: now and then a stranger's hint instead of a regular's chat.
static func inn_line(g: GameState, rng: RandomNumberGenerator = null) -> String:
	if g == null:
		return ""
	var rr := rng if rng else RandomNumberGenerator.new()
	if rng == null:
		rr.randomize()
	var p := pool(g)
	if p.is_empty() or rr.randf() >= INN_CHANCE:
		return ""
	return "%s \"%s\"" % [STRANGERS[rr.randi() % STRANGERS.size()], p[rr.randi() % p.size()]]

## A whisper in the log the first time a hero passes each WHISPER_EVERY floors
## (from OPEN_FLOOR). Remembered per hero in feats. Returns what was said ("" if nothing).
static func on_progress(g: GameState) -> String:
	if g == null or g.in_town or not hints_open(g):
		return ""
	var next := int(g.feats.get("hint_floor", OPEN_FLOOR))
	if g.best_floor < next:
		return ""
	g.feats["hint_floor"] = (floori(g.best_floor / float(WHISPER_EVERY)) + 1) * WHISPER_EVERY
	var p := pool(g)
	if p.is_empty():
		return ""
	var line := "[color=#c084fc]%s[/color] \"%s\"" % [STRANGERS.pick_random(), p.pick_random()]
	g.say(line)
	return line

## The riddles the Class tab shows: a few, opening slowly with depth, in an order
## fixed for this hero (so they don't reshuffle every time you look).
static func riddles(g: GameState) -> Array:
	if g.best_floor < RIDDLE_START:
		return []
	var n := mini(RIDDLE_MAX, 1 + floori((g.best_floor - RIDDLE_START) / float(RIDDLE_EVERY)))
	var p := pool(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s" % [g.slot, g.hero_name])
	for i in range(p.size() - 1, 0, -1):  # a seeded shuffle
		var j := rng.randi_range(0, i)
		var tmp = p[i]
		p[i] = p[j]
		p[j] = tmp
	return p.slice(0, n)

## Every name a hint must never say: hidden class names and their stage names,
## and God class names. For tests (and anyone adding hint text).
static func secret_names() -> Array:
	var out: Array = []
	for id in Hidden.CLASSES:
		var c: Dictionary = Hidden.CLASSES[id]
		out.append(String(c["name"]))
		for s in c.get("stages", []):
			out.append(String(s))
	for id in GodClasses.LIST:
		out.append(String(GodClasses.LIST[id]["name"]))
	return out

## The secret names a text gives away ([] = none). Whole words, any case.
static func leaks(text: String) -> Array:
	var found: Array = []
	var low := " " + text.to_lower() + " "
	for nm in secret_names():
		var re := RegEx.create_from_string("(?<![a-z])" + String(nm).to_lower().replace("the ", "") + "(?![a-z])")
		if re.search(low) != null:
			found.append(nm)
	return found
