class_name Codex
extends RefCounted
## Things shared by every hero on this computer: the Bestiary (who you've met
## and how many you've killed), lifetime stats, the trophy collection,
## achievements, bounties, the daily login streak and the guide book.
## Saved in user://codex.dat. A fallen Hardcore hero's kills still count.

const PATH := "user://codex.dat"

# ---------- Achievements ----------
# key: what's counted (see value()), target: how much. Rewards are small;
# some give a title you can show off. Gold rewards grow with how deep you've been.
const ACHIEVEMENTS := [
	# Depth
	{"id": "f10", "name": "First Steps", "text": "Reach floor 10", "key": "best_floor", "target": 10, "reward": {"potions": 2}},
	{"id": "f25", "name": "Halfway Down", "text": "Reach floor 25", "key": "best_floor", "target": 25, "reward": {"gold": 300}},
	{"id": "f50", "name": "Out of the Woods", "text": "Reach floor 50", "key": "best_floor", "target": 50, "reward": {"gold": 600}, "title": "Hollow-Walker"},
	{"id": "f100", "name": "Grave Matters", "text": "Reach floor 100", "key": "best_floor", "target": 100, "reward": {"gold": 1000}},
	{"id": "f150", "name": "Deep Water", "text": "Reach floor 150", "key": "best_floor", "target": 150, "reward": {"gold": 1500}, "title": "Tidebreaker"},
	{"id": "f200", "name": "Trial by Fire", "text": "Reach floor 200", "key": "best_floor", "target": 200, "reward": {"gold": 2000}},
	{"id": "f250", "name": "Into the Dark", "text": "Reach floor 250", "key": "best_floor", "target": 250, "reward": {"gold": 3000}, "title": "Shadowborn"},
	# Levels and class
	{"id": "lv10", "name": "Getting Stronger", "text": "Reach level 10", "key": "best_level", "target": 10, "reward": {"potions": 3}},
	{"id": "lv25", "name": "Seasoned", "text": "Reach level 25", "key": "best_level", "target": 25, "reward": {"gold": 500}},
	{"id": "lv50", "name": "Veteran", "text": "Reach level 50", "key": "best_level", "target": 50, "reward": {"gold": 1500}, "title": "Veteran"},
	{"id": "lv100", "name": "Living Legend", "text": "Reach level 100", "key": "best_level", "target": 100, "reward": {"gold": 5000}, "title": "Legend"},
	{"id": "spec", "name": "Specialist", "text": "Get a specialization", "key": "specs", "target": 1, "reward": {"scrap": 50}},
	{"id": "evo", "name": "Evolved", "text": "Evolve your class", "key": "evos", "target": 1, "reward": {"scrap": 150}, "title": "Ascendant"},
	# Killing
	{"id": "k100", "name": "Monster Hunter", "text": "Defeat 100 monsters", "key": "kills", "target": 100, "reward": {"potions": 2}},
	{"id": "k1000", "name": "Seasoned Hunter", "text": "Defeat 1,000 monsters", "key": "kills", "target": 1000, "reward": {"gold": 800}},
	{"id": "k10000", "name": "Slayer", "text": "Defeat 10,000 monsters", "key": "kills", "target": 10000, "reward": {"gold": 3000}, "title": "Slayer"},
	{"id": "rare1", "name": "Rare Find", "text": "Defeat a Rare monster", "key": "tier_2", "target": 1, "reward": {"scrap": 20}},
	{"id": "epic1", "name": "Epic Encounter", "text": "Defeat an Epic monster", "key": "tier_3", "target": 1, "reward": {"scrap": 40}},
	{"id": "leg1", "name": "Legend Slain", "text": "Defeat a Legendary monster", "key": "tier_4", "target": 1, "reward": {"mats": 3}},
	{"id": "myth1", "name": "Mythbreaker", "text": "Defeat a Mythic monster", "key": "tier_5", "target": 1, "reward": {"mats": 5}, "title": "Mythbreaker"},
	{"id": "rare100", "name": "Big Game Hunter", "text": "Defeat 100 Rare or better monsters", "key": "rare_kills", "target": 100, "reward": {"gold": 1500}, "title": "Big Game Hunter"},
	# Bosses
	{"id": "mid1", "name": "Midway Menace", "text": "Defeat a mid boss", "key": "mids", "target": 1, "reward": {"potions": 3}},
	{"id": "grendel", "name": "Grendel's Bane", "text": "Defeat Grendel", "key": "boss:Grendel", "target": 1, "reward": {"mats": 3}, "title": "Grendel's Bane"},
	{"id": "hel", "name": "Hel-Breaker", "text": "Defeat Hel, Queen of the Dead", "key": "boss:Hel, Queen of the Dead", "target": 1, "reward": {"mats": 3}, "title": "Hel-Breaker"},
	{"id": "charybdis", "name": "Whirlpool Survivor", "text": "Defeat Charybdis", "key": "boss:Charybdis", "target": 1, "reward": {"mats": 3}, "title": "Stormrider"},
	{"id": "surtr", "name": "Giant-Felled", "text": "Defeat Surtr the Fire Giant", "key": "boss:Surtr the Fire Giant", "target": 1, "reward": {"mats": 3}, "title": "Flamebreaker"},
	{"id": "typhon", "name": "Father-Slayer", "text": "Defeat Typhon, Father of Monsters", "key": "boss:Typhon, Father of Monsters", "target": 1, "reward": {"mats": 5}, "title": "Monsterbane"},
	{"id": "allmids", "name": "Five Terrors", "text": "Defeat all 5 mid bosses", "key": "mids", "target": 5, "reward": {"gold": 2500}},
	{"id": "boss25", "name": "Boss Rush", "text": "Defeat 25 bosses", "key": "boss_kills", "target": 25, "reward": {"gold": 1500}},
	{"id": "boss100", "name": "Bossbreaker", "text": "Defeat 100 bosses", "key": "boss_kills", "target": 100, "reward": {"gold": 4000}, "title": "Bossbreaker"},
	# Bestiary
	{"id": "seen10", "name": "Field Notes", "text": "Meet 10 kinds of monster", "key": "seen", "target": 10, "reward": {"scrap": 20}},
	{"id": "seen25", "name": "Naturalist", "text": "Meet 25 kinds of monster", "key": "seen", "target": 25, "reward": {"gold": 800}},
	{"id": "seen50", "name": "Monster Scholar", "text": "Meet 50 kinds of monster", "key": "seen", "target": 50, "reward": {"gold": 3000}, "title": "Scholar"},
	{"id": "m100", "name": "Know Your Enemy", "text": "Defeat 100 of 10 different monsters", "key": "mons_100", "target": 10, "reward": {"gold": 1500}},
	{"id": "m1000", "name": "Obsessed", "text": "Defeat 1,000 of one monster", "key": "top_kills", "target": 1000, "reward": {"gold": 2000}, "title": "The Obsessed"},
	# Loot
	{"id": "leg_item", "name": "Orange Glow", "text": "Find a Legendary item", "key": "legendaries", "target": 1, "reward": {"scrap": 30}},
	{"id": "leg25", "name": "Legendary Hoard", "text": "Find 25 Legendary items", "key": "legendaries", "target": 25, "reward": {"gold": 2000}},
	{"id": "uniq1", "name": "One of a Kind", "text": "Find a Unique item", "key": "uniques", "target": 1, "reward": {"potions": 3}},
	{"id": "uniq5", "name": "Collector", "text": "Find 5 different Unique items", "key": "uniques", "target": 5, "reward": {"gold": 1500}},
	{"id": "uniq15", "name": "Curator", "text": "Find 15 different Unique items", "key": "uniques", "target": 15, "reward": {"gold": 6000}, "title": "Curator"},
	{"id": "sig1", "name": "One in a Thousand", "text": "Find a Signature item", "key": "signatures", "target": 1, "reward": {"mats": 5}, "title": "The Lucky"},
	{"id": "sig5", "name": "Monster Keepsakes", "text": "Find 5 different Signature items", "key": "signatures", "target": 5, "reward": {"gold": 5000}, "title": "Keepsake Keeper"},
	# Crafting
	{"id": "set1", "name": "Apprentice Smith", "text": "Craft a Set item", "key": "sets_crafted", "target": 1, "reward": {"scrap": 40}},
	{"id": "setfull", "name": "Matching Outfit", "text": "Wear a full 3-piece set", "key": "set_worn", "target": 3, "reward": {"gold": 1500}, "title": "Well-Dressed"},
	{"id": "up10", "name": "Overclocked", "text": "Upgrade an item to +10", "key": "max_upgrade", "target": 10, "reward": {"scrap": 100}},
	{"id": "reroll10", "name": "Gambler", "text": "Win 10 rerolls", "key": "rerolls_won", "target": 10, "reward": {"scrap": 60}},
	# Dungeon events
	{"id": "gob1", "name": "Goblin Mugger", "text": "Catch a treasure goblin", "key": "goblins", "target": 1, "reward": {"potions": 2}},
	{"id": "gob10", "name": "Goblin Hunter", "text": "Catch 10 treasure goblins", "key": "goblins", "target": 10, "reward": {"gold": 1500}, "title": "Goblin Hunter"},
	{"id": "horde1", "name": "Horde Breaker", "text": "Survive a monster horde", "key": "hordes", "target": 1, "reward": {"scrap": 30}},
	{"id": "shrine1", "name": "Touched by Darkness", "text": "Accept a cursed shrine's deal", "key": "shrines", "target": 1, "reward": {"scrap": 30}},
	{"id": "merch5", "name": "Good Customer", "text": "Buy 5 things from the wandering merchant", "key": "merchant_buys", "target": 5, "reward": {"gold": 800}},
	# Gold and everything else
	{"id": "g10k", "name": "Pocket Money", "text": "Earn 10,000 gold", "key": "gold_earned", "target": 10000, "reward": {"potions": 3}},
	{"id": "g1m", "name": "Tycoon", "text": "Earn 1,000,000 gold", "key": "gold_earned", "target": 1000000, "reward": {"mats": 5}, "title": "Tycoon"},
	{"id": "streak7", "name": "Dedicated", "text": "Log in 7 days in a row", "key": "streak_best", "target": 7, "reward": {"gold": 1000}, "title": "Dedicated"},
	{"id": "bounty10", "name": "Bounty Hunter", "text": "Finish 10 bounties", "key": "bounties", "target": 10, "reward": {"gold": 1000}},
	{"id": "bounty50", "name": "Marshal", "text": "Finish 50 bounties", "key": "bounties", "target": 50, "reward": {"gold": 4000}, "title": "Marshal"},
	{"id": "ward25", "name": "Fashionista", "text": "Collect 25 looks in the Wardrobe", "key": "wardrobe", "target": 25, "reward": {"gold": 800}, "title": "Fashionable"},
	{"id": "hc50", "name": "Brave", "text": "Reach floor 50 with a Hardcore hero", "key": "hc_floor", "target": 50, "reward": {"gold": 1500}},
	{"id": "hc100", "name": "Deathless", "text": "Reach floor 100 with a Hardcore hero", "key": "hc_floor", "target": 100, "reward": {"gold": 4000}, "title": "Deathless"},
	{"id": "party", "name": "Full Party", "text": "Have 3 heroes at once", "key": "heroes", "target": 3, "reward": {"gold": 1000}},
	# Realms, races and hidden classes (0.9)
	{"id": "f350", "name": "Halfway to Nowhere", "text": "Reach floor 350", "key": "best_floor", "target": 350, "reward": {"gold": 4000}},
	{"id": "f500", "name": "The Bottom of the World", "text": "Reach floor 500", "key": "best_floor", "target": 500, "reward": {"gold": 8000}, "title": "Rootbreaker"},
	{"id": "realm1", "name": "Through the Roots", "text": "Step into a realm", "key": "realms_entered", "target": 1, "reward": {"mats": 3}},
	{"id": "realm5", "name": "Walker of Realms", "text": "Enter all 5 realms", "key": "realms_entered", "target": 5, "reward": {"gold": 5000}, "title": "Realmwalker"},
	{"id": "queen", "name": "The Last Leaf", "text": "Defeat the Withered Queen", "key": "boss:The Withered Queen", "target": 1, "reward": {"mats": 5}, "title": "Leafbane"},
	{"id": "fairyq", "name": "Game Over", "text": "Defeat the Fairy Queen", "key": "boss:The Fairy Queen", "target": 1, "reward": {"mats": 5}, "title": "Unglamoured"},
	{"id": "thrandor", "name": "Kingslayer Under the Mountain", "text": "Defeat High King Thrandor", "key": "boss:High King Thrandor", "target": 1, "reward": {"mats": 5}, "title": "Mountainbreaker"},
	{"id": "seraphiel", "name": "Put Out the Light", "text": "Defeat Seraphiel, the First Light", "key": "boss:Seraphiel, the First Light", "target": 1, "reward": {"mats": 5}, "title": "Dawnbreaker"},
	{"id": "azgaroth", "name": "Abyss-Lord's End", "text": "Defeat Azgaroth, Lord of the Abyss", "key": "boss:Azgaroth, Lord of the Abyss", "target": 1, "reward": {"mats": 5}, "title": "Hellwalker"},
	{"id": "aw1", "name": "Awakened", "text": "Awaken your race once", "key": "awakenings", "target": 1, "reward": {"gold": 1500}, "title": "Awakened"},
	{"id": "aw5", "name": "Blood Will Tell", "text": "Awaken 5 times (any heroes)", "key": "awakenings", "target": 5, "reward": {"gold": 4000}},
	{"id": "changed", "name": "Not Quite Yourself", "text": "Be transformed", "key": "transformations", "target": 1, "reward": {"potions": 5}},
	{"id": "hid1", "name": "A Secret Class", "text": "Unlock a hidden class", "key": "hidden_classes", "target": 1, "reward": {"gold": 1000}, "title": "The Unexpected"},
	{"id": "hid5", "name": "Many Faces", "text": "Unlock 5 hidden classes (any heroes)", "key": "hidden_classes", "target": 5, "reward": {"gold": 5000}, "title": "The Unseen"},
	{"id": "branch1", "name": "A New Branch", "text": "Choose your first class branch", "key": "class_picks", "target": 1, "reward": {"gold": 500}},
	{"id": "unique1", "name": "One of a Kind", "text": "Become a unique class", "key": "unique_classes", "target": 1, "reward": {"gold": 5000}, "title": "The Unique"},
	{"id": "branchoff1", "name": "Off the Beaten Path", "text": "Take a branch-off class", "key": "branch_offs", "target": 1, "reward": {"gold": 5000}, "title": "The Wayward"},
	{"id": "god1", "name": "Godhood", "text": "Become a God rank class", "key": "gods", "target": 1, "reward": {"gold": 20000}, "title": "Godlike"},
	{"id": "spare50", "name": "Mercy", "text": "Spare 50 monsters", "key": "spared", "target": 50, "reward": {"gold": 1500}, "title": "The Merciful"},
	{"id": "run25", "name": "Live to Fight Another Day", "text": "Escape 25 fights", "key": "escapes", "target": 25, "reward": {"potions": 5}},
	{"id": "secret10", "name": "Secret Keeper", "text": "Find 10 realm secrets", "key": "secrets", "target": 10, "reward": {"gold": 4000}, "title": "Secret Keeper"},
	{"id": "quest10", "name": "Good Neighbor", "text": "Finish 10 camp quests", "key": "quests", "target": 10, "reward": {"gold": 3000}},
	{"id": "done_elf", "name": "The Hushwood, Whole", "text": "Do 100% of the Hushwood", "key": "realmdone:elf", "target": 100, "reward": {"gold": 6000, "look": "elf"}, "title": "Friend of the Hushwood"},
	{"id": "done_fairy", "name": "The Glimmer Court, Whole", "text": "Do 100% of the Glimmer Court", "key": "realmdone:fairy", "target": 100, "reward": {"gold": 6000, "look": "fairy"}, "title": "Darling of the Court"},
	{"id": "done_dwarf", "name": "The Ironroot Deeps, Whole", "text": "Do 100% of the Ironroot Deeps", "key": "realmdone:dwarf", "target": 100, "reward": {"gold": 6000, "look": "dwarf"}, "title": "Oathkeeper"},
	{"id": "done_angel", "name": "The Gilded Spire, Whole", "text": "Do 100% of the Gilded Spire", "key": "realmdone:angel", "target": 100, "reward": {"gold": 6000, "look": "angel"}, "title": "Choir-Blessed"},
	{"id": "done_demon", "name": "The Cinder Abyss, Whole", "text": "Do 100% of the Cinder Abyss", "key": "realmdone:demon", "target": 100, "reward": {"gold": 6000, "look": "demon"}, "title": "Pact-Breaker"},
]

# ---------- Bounties ----------
# kind: what counts; n: how many for a daily (weeklies need WEEKLY_MULT times more)
const BOUNTY_KINDS := [
	{"kind": "kill_zone", "n": 40, "text": "Defeat %d monsters in %s"},
	{"kind": "kill_monster", "n": 12, "text": "Defeat %d %s"},
	{"kind": "rare", "n": 5, "text": "Defeat %d Rare or better monsters"},
	{"kind": "floors", "n": 10, "text": "Clear %d floors"},
	{"kind": "epic_items", "n": 3, "text": "Find %d Epic or better items"},
	{"kind": "boss", "n": 1, "text": "Defeat %d boss"},
	{"kind": "event", "n": 2, "text": "Finish %d dungeon events"},
]
const DAILY_BOUNTIES := 3
const WEEKLY_BOUNTIES := 2
const WEEKLY_MULT := 6

# ---------- Daily login ----------
# Day 1..7 of a streak, then it repeats
const LOGIN_REWARDS := [
	{"text": "Gold", "gold": 200},
	{"text": "3 potions", "potions": 3},
	{"text": "Scrap", "scrap": 40},
	{"text": "Scroll of Luck", "scroll": "luck"},
	{"text": "3 materials", "mats": 3},
	{"text": "Hunter's Scroll", "scroll": "hunt"},
	{"text": "Mystery Box", "scroll": "box"},
]

var bestiary := {}      # monster name -> {"kills": n, "tiers": [6 counts], "sig": bool}
var stats := {}         # counter name -> number (see value())
var collection := {}    # Unique / Signature / Set item name -> date found
var achievements := {}  # id -> date unlocked
var title := ""         # the achievement title you're showing ("" = your class)
var bounties := {"day": "", "daily": [], "week": "", "weekly": []}
var deeds: Array = []   # achievement ids whose rewards wait at the Guild Hall
var login := {"last": "", "streak": 0}
var guide := {}         # guide page id -> true (unlocked)
var guide_queue: Array = []  # pages unlocked this session that haven't popped up yet
var new_unlocks: Array = []  # achievements that just unlocked (main shows them)
var path := PATH        # "" = never save (tests)
var dirty := false

static func load_codex(p := PATH) -> Codex:
	var c := Codex.new()
	c.path = p
	if p != "" and FileAccess.file_exists(p):
		var f := FileAccess.open(p, FileAccess.READ)
		if f:
			var d = f.get_var()
			if typeof(d) == TYPE_DICTIONARY:
				c._from(d)
	return c

func _from(d: Dictionary) -> void:
	bestiary = d.get("bestiary", {})
	stats = d.get("stats", {})
	collection = d.get("collection", {})
	achievements = d.get("achievements", {})
	title = str(d.get("title", ""))
	bounties = d.get("bounties", bounties)
	login = d.get("login", login)
	guide = d.get("guide", {})
	deeds = d.get("deeds", [])

func save() -> void:
	dirty = false
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({"bestiary": bestiary, "stats": stats, "collection": collection, "achievements": achievements,
		"title": title, "bounties": bounties, "login": login, "guide": guide, "deeds": deeds})

static func delete() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

# =====================================================================
# Counting
# =====================================================================

func add(key: String, n := 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n
	dirty = true

func at_least(key: String, v: int) -> void:
	if v > int(stats.get(key, 0)):
		stats[key] = v
		dirty = true

func stat(key: String) -> int:
	return int(stats.get(key, 0))

func entry(monster: String) -> Dictionary:
	if not bestiary.has(monster):
		bestiary[monster] = {"kills": 0, "tiers": [0, 0, 0, 0, 0, 0], "sig": false}
	return bestiary[monster]

func seen(monster: String) -> bool:
	return bestiary.has(monster)

func meet(monster: String) -> void:
	if not bestiary.has(monster):
		entry(monster)
		dirty = true

func kills(monster: String) -> int:
	return int(bestiary.get(monster, {}).get("kills", 0))

func record_kill(monster: String, tier: int, boss: String) -> void:
	var e := entry(monster)
	e["kills"] = int(e["kills"]) + 1
	var t: Array = e["tiers"]
	t[clampi(tier, 0, 5)] = int(t[clampi(tier, 0, 5)]) + 1
	add("kills")
	if tier >= Monsters.RARE:
		add("rare_kills")
	if tier > 0:
		add("tier_%d" % tier)
	if boss != "":
		add("boss_kills")
	dirty = true

func found_item(item: Dictionary) -> void:
	var r := int(item["rarity"])
	add("items")
	add("items_r%d" % r)
	if r == GameData.LEGENDARY:
		add("legendaries")
	if r in [GameData.UNIQUE, GameData.SIGNATURE, GameData.SET_RARITY]:
		if not collection.has(item["base_name"]):
			collection[item["base_name"]] = Time.get_date_string_from_system()
	if r == GameData.SIGNATURE and item.get("sig_of", "") != "":
		entry(item["sig_of"])["sig"] = true

## A number for an achievement or the stats page.
func value(key: String, state: GameState = null) -> int:
	if key.begins_with("boss:"):
		return kills(key.substr(5))
	if key.begins_with("realmdone:"):
		return Realms.completion(state, key.substr(10)) if state else 0
	match key:
		"seen":
			var n := 0
			for m in Monsters.all_monsters():
				if bestiary.has(m):
					n += 1
			return n
		"mons_100":
			var n := 0
			for m in bestiary:
				if int(bestiary[m]["kills"]) >= 100 and not Monsters.info(m).get("boss", false):
					n += 1
			return n
		"top_kills":
			var best := 0
			for m in bestiary:
				if not Monsters.info(m).get("boss", false):
					best = maxi(best, int(bestiary[m]["kills"]))
			return best
		"mids":
			var n := 0
			for z in GameData.ZONES:
				if kills(z["mid"]["name"]) > 0:
					n += 1
			return n
		"uniques":
			var n := 0
			for zi in GameData.ZONES.size():
				for u in GameData.zone_uniques(zi):
					if collection.has(u["name"]):
						n += 1
			return n
		"signatures":
			var n := 0
			for m in Monsters.all_monsters():
				if bool(bestiary.get(m, {}).get("sig", false)):
					n += 1
			return n
		"streak_best":
			return maxi(stat("streak_best"), int(login.get("streak", 0)))
		"wardrobe":
			return state.wardrobe.size() if state else stat("wardrobe")
		"set_worn":
			return state.best_set_count() if state else 0
	return stat(key)

# =====================================================================
# Achievements
# =====================================================================

static func achievement(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return a
	return {}

## Unlocks anything newly earned. Returns the newly unlocked achievements.
func check(state: GameState) -> Array:
	var out: Array = []
	for a in ACHIEVEMENTS:
		if achievements.has(a["id"]):
			continue
		if value(a["key"], state) >= int(a["target"]):
			achievements[a["id"]] = Time.get_date_string_from_system()
			out.append(a)
	if not out.is_empty():
		dirty = true
	return out

func titles() -> Array:
	var out: Array = []
	for a in ACHIEVEMENTS:
		if achievements.has(a["id"]) and a.has("title"):
			out.append(a["title"])
	return out

# =====================================================================
# Bounties
# =====================================================================

static func week_id(unix: float) -> String:
	var days := floori(unix / 86400.0)
	var monday := days - ((days + 3) % 7)
	return Time.get_date_string_from_unix_time(monday * 86400)

## Makes new bounties when a new day or week starts. zone_i: where the hero is.
func refresh_bounties(state: GameState) -> void:
	var now := Time.get_unix_time_from_system()
	var today := Time.get_date_string_from_unix_time(int(now))
	var week := week_id(now)
	if bounties.get("day", "") != today:
		bounties["day"] = today
		bounties["daily"] = _make_bounties(state, DAILY_BOUNTIES, 1)
		dirty = true
	if bounties.get("week", "") != week:
		bounties["week"] = week
		bounties["weekly"] = _make_bounties(state, WEEKLY_BOUNTIES, WEEKLY_MULT)
		dirty = true

func _make_bounties(state: GameState, count: int, mult: int) -> Array:
	var kinds := BOUNTY_KINDS.duplicate()
	kinds.shuffle()
	var out: Array = []
	var zi := GameData.zone_index(state.floor_num)
	for k in kinds:
		if out.size() >= count:
			break
		var b := {"kind": k["kind"], "need": int(k["n"]) * mult, "have": 0, "done": false, "claimed": false, "weekly": mult > 1}
		match k["kind"]:
			"kill_zone":
				b["zone"] = zi
				b["text"] = k["text"] % [b["need"], GameData.ZONES[zi]["name"]]
			"kill_monster":
				var pool: Array = []
				for m in GameData.floor_monsters(state.floor_num):
					if seen(m[0]["name"]):
						pool.append(m[0]["name"])
				if pool.is_empty():
					continue
				b["monster"] = pool.pick_random()
				b["text"] = k["text"] % [b["need"], b["monster"]]
			"boss":
				b["need"] = 1 if mult == 1 else 5
				b["text"] = ("Defeat %d boss" if b["need"] == 1 else "Defeat %d bosses") % b["need"]
			_:
				b["text"] = k["text"] % b["need"]
		out.append(b)
	return out

## Counts progress. kind: "kill" (info: monster, zone, tier), "floor", "item" (rarity), "boss", "event".
func bounty_progress(kind: String, info := {}) -> void:
	for list_name in ["daily", "weekly"]:
		for b in bounties.get(list_name, []):
			if b["done"]:
				continue
			var hit := false
			match b["kind"]:
				"kill_zone":
					hit = kind == "kill" and int(info.get("zone", -1)) == int(b["zone"])
				"kill_monster":
					hit = kind == "kill" and info.get("monster", "") == b["monster"]
				"rare":
					hit = kind == "kill" and int(info.get("tier", 0)) >= Monsters.RARE
				"floors":
					hit = kind == "floor"
				"epic_items":
					hit = kind == "item" and int(info.get("rarity", 0)) >= 3 and int(info.get("rarity", 0)) != GameData.SET_RARITY
				"boss":
					hit = kind == "boss"
				"event":
					hit = kind == "event"
			if hit:
				b["have"] = int(b["have"]) + 1
				if int(b["have"]) >= int(b["need"]):
					b["done"] = true
				dirty = true

func bounties_ready() -> int:
	var n := 0
	for list_name in ["daily", "weekly"]:
		for b in bounties.get(list_name, []):
			if b["done"] and not b["claimed"]:
				n += 1
	return n

# =====================================================================
# Daily login
# =====================================================================

## Call once when the game starts. Returns the streak day (1-7) to reward, or 0 if already rewarded today.
func check_login() -> int:
	var now := Time.get_unix_time_from_system()
	var today := Time.get_date_string_from_unix_time(int(now))
	if login.get("last", "") == today:
		return 0
	var yesterday := Time.get_date_string_from_unix_time(int(now) - 86400)
	if login.get("last", "") == yesterday:
		login["streak"] = int(login.get("streak", 0)) + 1
	else:
		login["streak"] = 1
	login["last"] = today
	at_least("streak_best", int(login["streak"]))
	dirty = true
	return ((int(login["streak"]) - 1) % LOGIN_REWARDS.size()) + 1

# =====================================================================
# Guide book
# =====================================================================

func unlock_page(id: String) -> bool:
	if guide.has(id) or not Guide.has_page(id):
		return false
	guide[id] = true
	guide_queue.append(id)
	dirty = true
	return true
