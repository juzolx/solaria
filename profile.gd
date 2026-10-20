class_name Profile
extends RefCounted
## Things shared by all your heroes: settings, which hero you played last,
## the shared stash, your Hardcore records and your online account.
## Saved in user://profile.dat.

const PATH := "user://profile.dat"
const MAX_RUNS := 20
## Bump this to wipe every hero for a fresh start (settings and the online login stay).
## 12 = Solaria 0.12: the dungeon revamp (Juzo said all saves can be reset).
const SAVE_EPOCH := 12

var last_mode := ""          # "regular", "hardcore" or "" before you've picked
var sound_on := true
var volume := 0.8
var music_volume := 0.5
var fullscreen := false
var dark_art := true          # the dark fantasy grade on monsters and backgrounds (dark_grade.gd)
var battery_saver := OS.has_feature("mobile")  # cap at 30 fps (a turn-based game needs no more; saves battery and heat)
var low_graphics := false     # simpler rooms and fewer particles for weak phones
var dev_mode := false
var hc_best := 0             # deepest floor a Hardcore hero reached
var hc_runs: Array = []      # past Hardcore heroes, newest first: {floor, level, title, race, date}
var player_name := ""        # online name
var online := {}             # online login (user id and tokens)
var path_choice := "ask"     # path rooms: "ask", or always pick "fight"
var active_slot := 1         # the hero you played last (1-3)
var max_floor := 0           # deepest floor any of your heroes has reached (opens hero slots)
var stash: Array = []        # shared stash items (Regular heroes only)
var stash_level := 0
var shake := true            # accessibility: screen shake
var damage_numbers := false  # floating damage numbers (off by default since the next update: the HP counter under the monster shows damage)
var flashes := true          # accessibility: bright flashes
var text_size := 1           # 0 small, 1 normal, 2 large
var notes_seen := ""         # last patch notes version shown
var skill_book := {}         # the skill book every Regular hero shares
var show_recap := true       # show what killed you after a defeat
var mail_seen: Array = []  # news letters (mail.gd NEWS) already delivered
var calamities := {}       # region index (str) -> {"hero", "slot", "date"}: Calamities this account has slain (the server owns this once online)
var colorblind := false      # spell out what colors mean (rarity, weak / resist)
var reduce_motion := false   # no idle bobbing, floating motes, shake or hit stop
var haptics := true          # short buzzes on phones for big hits, drops and moments
var high_contrast := false   # brighter secondary text
var save_epoch := 0          # the SAVE_EPOCH these saves were made under
# Next update (Juzo): a save is a town holding a roster of heroes. The fields in
# TOWN_KEYS fields belong to the town you're in; every town keeps its own copy here.
const TOWN_KEYS := ["active_slot", "max_floor", "stash", "stash_level", "skill_book", "calamities", "presets"]
const TOWN_NAMES := ["Emberfall", "Greyhollow", "Duskmere"]
const TOWN_NAME_MAX := 16
var town := 1                # the town you're in (1..GameData.MAX_TOWNS)
var towns := {}              # str(town) -> {"name", and every TOWN_KEYS field}
var towns_v1 := false        # old hero saves have been moved into towns
var presets: Array = [{}, {}, {}]  # next update: saved team line-ups, {"slots": [leader, companions...]} (this town)
var paid_slots := 0          # unused: hero slots are never sold (kept so old profiles load)
var owned_products: Array = []  # Stage 4: App Store products bought (store.gd; the store is switched off)

static func load_profile() -> Profile:
	var p := Profile.new()
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var d = f.get_var()
			if typeof(d) == TYPE_DICTIONARY:
				p._from(d)
	return p

func _from(d: Dictionary) -> void:
	last_mode = str(d.get("last_mode", ""))
	sound_on = bool(d.get("sound_on", true))
	volume = float(d.get("volume", 0.8))
	music_volume = float(d.get("music_volume", 0.5))
	fullscreen = bool(d.get("fullscreen", false))
	dark_art = bool(d.get("dark_art", true))
	battery_saver = bool(d.get("battery_saver", OS.has_feature("mobile")))
	low_graphics = bool(d.get("low_graphics", false))
	dev_mode = bool(d.get("dev_mode", false)) and OS.is_debug_build()  # never in store builds
	hc_best = int(d.get("hc_best", 0))
	hc_runs = d.get("hc_runs", [])
	player_name = str(d.get("player_name", ""))
	online = d.get("online", {})
	path_choice = str(d.get("path_choice", "ask"))
	active_slot = int(d.get("active_slot", 1))
	max_floor = int(d.get("max_floor", 0))
	stash = d.get("stash", [])
	stash_level = int(d.get("stash_level", 0))
	shake = bool(d.get("shake", true))
	# Next update (Juzo): one damage display, the counter under the bar. Old saves had this on by default.
	damage_numbers = bool(d.get("damage_numbers", false)) if d.has("dmgnum_v2") else false
	flashes = bool(d.get("flashes", true))
	text_size = int(d.get("text_size", 1))
	notes_seen = str(d.get("notes_seen", ""))
	skill_book = d.get("skill_book", {})
	show_recap = bool(d.get("show_recap", true))
	colorblind = bool(d.get("colorblind", false))
	reduce_motion = bool(d.get("reduce_motion", false))
	haptics = bool(d.get("haptics", true))
	high_contrast = bool(d.get("high_contrast", false))
	mail_seen = d.get("mail_seen", [])
	calamities = d.get("calamities", {})
	save_epoch = int(d.get("save_epoch", 0))
	towns = d.get("towns", {})
	towns_v1 = bool(d.get("towns_v1", false))
	paid_slots = int(d.get("paid_slots", 0))
	owned_products = d.get("owned_products", [])
	town = clampi(int(d.get("town", 1)), 1, GameData.MAX_TOWNS)
	if towns.has(str(town)):
		_load_town(town)
	GameState.town = town

## Copies the town you're in into towns (save does this every time).
func _store_town() -> void:
	var t: Dictionary = towns.get(str(town), {})
	t["name"] = town_name(town)
	for k in TOWN_KEYS:
		t[k] = get(k)
	towns[str(town)] = t

func _load_town(n: int) -> void:
	var t: Dictionary = towns.get(str(n), {})
	active_slot = int(t.get("active_slot", 1))
	max_floor = int(t.get("max_floor", 0))
	stash = t.get("stash", [])
	stash_level = int(t.get("stash_level", 0))
	skill_book = t.get("skill_book", {})
	calamities = t.get("calamities", {})
	presets = t.get("presets", [{}, {}, {}])

## Moves to another town: its heroes, stash, skill book and slots. Settings stay.
func switch_town(n: int) -> void:
	n = clampi(n, 1, GameData.MAX_TOWNS)
	_store_town()
	town = n
	_load_town(n)
	if not towns.has(str(n)):
		_store_town()
	GameState.town = n
	save()

func town_name(n: int) -> String:
	return str(towns.get(str(n), {}).get("name", TOWN_NAMES[(n - 1) % TOWN_NAMES.size()]))

## Juzo: a town is Regular or Hardcore, not each hero. Every hero raised there follows it.
func town_hardcore(n: int) -> bool:
	return bool(towns.get(str(n), {}).get("hardcore", false))

## Founds town n with a name (blank = its default) and a mode, and moves there.
func found_town(n: int, new_name: String, hardcore: bool) -> void:
	switch_town(n)
	towns[str(n)]["hardcore"] = hardcore
	rename_town(n, new_name)

func rename_town(n: int, new_name: String) -> void:
	new_name = new_name.strip_edges().left(TOWN_NAME_MAX)
	if new_name == "" or not towns.has(str(n)):
		return
	towns[str(n)]["name"] = new_name
	save()

## True if a town has been founded (it has a record or any hero).
func town_founded(n: int) -> bool:
	return GameState.town_heroes(n) > 0 or (towns.get(str(n), {}) as Dictionary).has("hardcore")  # founded: it has heroes, or was named and given a mode

func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	_store_town()
	f.store_var({
		"town": town, "towns": towns, "towns_v1": towns_v1, "paid_slots": paid_slots, "owned_products": owned_products,
		"last_mode": last_mode, "sound_on": sound_on, "volume": volume, "music_volume": music_volume,
		"fullscreen": fullscreen, "dark_art": dark_art, "battery_saver": battery_saver, "low_graphics": low_graphics, "dev_mode": dev_mode, "hc_best": hc_best, "hc_runs": hc_runs,
		"player_name": player_name, "online": online, "path_choice": path_choice,
		"active_slot": active_slot, "max_floor": max_floor, "stash": stash, "stash_level": stash_level,
		"shake": shake, "damage_numbers": damage_numbers, "dmgnum_v2": true, "flashes": flashes, "text_size": text_size, "notes_seen": notes_seen, "skill_book": skill_book, "show_recap": show_recap, "colorblind": colorblind, "reduce_motion": reduce_motion, "haptics": haptics, "high_contrast": high_contrast, "mail_seen": mail_seen, "calamities": calamities, "save_epoch": save_epoch,
	})

## True when saves from an older epoch exist and must be wiped.
func fresh_start_due() -> bool:
	return save_epoch < SAVE_EPOCH

## Clears all progress but keeps settings and the online login.
func reset_progress() -> void:
	hc_best = 0
	hc_runs = []
	active_slot = 1
	max_floor = 0
	stash = []
	stash_level = 0
	skill_book = {}
	mail_seen = []
	calamities = {}
	last_mode = ""
	notes_seen = ""
	save_epoch = SAVE_EPOCH
	town = 1
	towns = {}
	towns_v1 = true
	GameState.town = 1

## How many hero slots this town has open (Juzo: one until floor 100; five at most):
## all five are earned by depth (GameData.SLOT_UNLOCKS: start, floor 100, 250, 500, 750).
func slots_open() -> int:
	if not GameData.SLOT_LOCKS_ON:
		return GameData.MAX_HEROES
	return mini(earned_slots(), GameData.MAX_HEROES)

func earned_slots() -> int:
	var n := 0
	for need in GameData.SLOT_UNLOCKS:
		if max_floor >= int(need):
			n += 1
	return n

## Why slot n is shut ("" if it's open).
func slot_lock_note(n: int) -> String:
	if n <= slots_open():
		return ""
	if n <= GameData.SLOT_UNLOCKS.size():
		return "Slot %d opens when a hero in this town reaches floor %d." % [n, int(GameData.SLOT_UNLOCKS[n - 1])]
	return ("Slot %d: Menu > Supporter store." if Store.ENABLED else "Slot %d can be bought later.") % n

func stash_capacity() -> int:
	return GameData.STASH_START + stash_level * GameData.STASH_STEP

## Older versions kept settings in the save file; copy them over once.
func take_settings_from(state: GameState) -> void:
	sound_on = state.sound_on
	volume = state.volume
	music_volume = state.music_volume
	fullscreen = state.fullscreen
	dev_mode = state.dev_mode

## Records a fallen Hardcore hero. Returns true if it's a new best.
func record_hc_run(state: GameState) -> bool:
	var run := {"floor": state.floor_num, "best": state.best_floor, "level": state.level, "title": state.title(),
		"race": state.race(), "date": Time.get_date_string_from_system()}
	hc_runs.push_front(run)
	if hc_runs.size() > MAX_RUNS:
		hc_runs.resize(MAX_RUNS)
	var new_best := state.best_floor > hc_best
	hc_best = maxi(hc_best, state.best_floor)
	save()
	return new_best

static func delete() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

## Next update: turns the old shared profile into towns after GameState.migrate_to_towns
## moved the hero saves (main._migrate_towns). Every town gets a copy of the old
## skill book; the old stash goes to the town of the hero played last.
func build_towns(placed: Array) -> void:
	var home := 1
	var home_slot := 1
	for p in placed:
		if int(p["old"]) == active_slot:
			home = int(p["town"])
			home_slot = int(p["slot"])
	var book: Dictionary = skill_book
	var cal: Dictionary = calamities
	var old_stash: Array = stash
	var old_level := stash_level
	towns = {}
	for t in range(1, GameData.MAX_TOWNS + 1):
		if t != 1 and not placed.any(func(p): return int(p["town"]) == t):
			continue
		var best := 0
		var hc := false
		for p in placed:
			if int(p["town"]) == t:
				GameState.town = t
				var meta := GameState.slot_meta(int(p["slot"]))
				best = maxi(best, int(meta.get("best", 0)))
				if int(p["slot"]) == 1:
					hc = bool(meta.get("hardcore", false))  # the town plays the way its first hero did
		towns[str(t)] = {"name": town_name(t), "active_slot": home_slot if t == home else 1, "max_floor": best,
			"stash": old_stash if t == home else [], "stash_level": old_level if t == home else 0,
			"skill_book": book.duplicate(true), "calamities": cal.duplicate(true), "hardcore": hc}
	town = home
	_load_town(home)
	GameState.town = home
	towns_v1 = true
	save()

## Towns made before Regular / Hardcore belonged to the town take it from their heroes.
func fill_town_modes() -> void:
	var cur := GameState.town
	for k in towns:
		var rec: Dictionary = towns[k]
		if rec.has("hardcore"):
			continue
		GameState.town = int(k)
		var hc := false
		for n in range(1, GameData.MAX_HEROES + 1):
			var meta := GameState.slot_meta(n)
			if not meta.is_empty():
				hc = bool(meta.get("hardcore", false))
				break
		rec["hardcore"] = hc
	GameState.town = cur

## The first open, empty hero slot in this town (0 = none). New heroes are
## recruited at the Inn (Juzo: it's not a menu option).
func free_slot() -> int:
	for n in range(1, slots_open() + 1):
		if not GameState.has_slot(n):
			return n
	return 0

## Why you can't recruit right now ("" = you can).
func recruit_note() -> String:
	if free_slot() > 0:
		return ""
	if slots_open() >= GameData.MAX_HEROES:
		return "%s has all %d of its heroes. A town holds no more." % [town_name(town), GameData.MAX_HEROES]
	return slot_lock_note(slots_open() + 1)
