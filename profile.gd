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
var damage_numbers := true   # accessibility: floating damage numbers
var flashes := true          # accessibility: bright flashes
var text_size := 1           # 0 small, 1 normal, 2 large
var notes_seen := ""         # last patch notes version shown
var skill_book := {}         # the skill book every Regular hero shares
var show_recap := true       # show what killed you after a defeat
var mail_seen: Array = []  # news letters (mail.gd NEWS) already delivered
var calamities := {}       # region index (str) -> {"hero", "slot", "date"}: Calamities this account has slain (the server owns this once online)
var colorblind := false      # spell out what colors mean (rarity, weak / resist)
var save_epoch := 0          # the SAVE_EPOCH these saves were made under

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
	dev_mode = bool(d.get("dev_mode", false))
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
	damage_numbers = bool(d.get("damage_numbers", true))
	flashes = bool(d.get("flashes", true))
	text_size = int(d.get("text_size", 1))
	notes_seen = str(d.get("notes_seen", ""))
	skill_book = d.get("skill_book", {})
	show_recap = bool(d.get("show_recap", true))
	colorblind = bool(d.get("colorblind", false))
	mail_seen = d.get("mail_seen", [])
	calamities = d.get("calamities", {})
	save_epoch = int(d.get("save_epoch", 0))

func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({
		"last_mode": last_mode, "sound_on": sound_on, "volume": volume, "music_volume": music_volume,
		"fullscreen": fullscreen, "dark_art": dark_art, "battery_saver": battery_saver, "low_graphics": low_graphics, "dev_mode": dev_mode, "hc_best": hc_best, "hc_runs": hc_runs,
		"player_name": player_name, "online": online, "path_choice": path_choice,
		"active_slot": active_slot, "max_floor": max_floor, "stash": stash, "stash_level": stash_level,
		"shake": shake, "damage_numbers": damage_numbers, "flashes": flashes, "text_size": text_size, "notes_seen": notes_seen, "skill_book": skill_book, "show_recap": show_recap, "colorblind": colorblind, "mail_seen": mail_seen, "calamities": calamities, "save_epoch": save_epoch,
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

## How many hero slots are open (GameData.SLOT_UNLOCKS: the 2nd at floor 10, up to the 9th at 500).
func slots_open() -> int:
	var n := 0
	for need in GameData.SLOT_UNLOCKS:
		if max_floor >= int(need):
			n += 1
	return n

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
