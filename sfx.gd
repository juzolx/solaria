class_name Sfx
extends Node
## Sound effects and music. Loads the recorded sounds from res://sounds/ and
## falls back to simple generated beeps for any file that's missing.
## To use your own sounds, replace a file in the sounds folder with the same name.

const RATE := 22050
const VOICES := 12
const SOUND_DIR := "res://sounds/"
const MUSIC_FADE := 1.2
const EXPECTED_FILES := 73  # sound + music files in the sounds folder

var enabled := true
var sfx_db := 0.0
var music_linear := 0.5
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_a := AudioStreamPlayer.new()
var music_b := AudioStreamPlayer.new()
var music_current := ""
var music_streams := {}
var files_found := 0  # how many sound files loaded from the sounds folder
var ambience := AudioStreamPlayer.new()   # 0.13+: the room you stand in (wind, drips, fire...)
var ambience_current := ""
var amb_streams := {}
var haptics := true       # short buzzes on phones for big hits, drops and moments
## Region mood kind (HallsScene.MOODS) -> ambience loop
const AMBIENCE := {"fireflies": "forest", "leaves": "forest", "dust": "crypt", "motes": "crypt", "drips": "water",
	"embers": "fire", "sparks": "fire", "shadows": "void", "sparkles": "void"}
## Sound -> buzz length in ms (phones only)
const HAPTIC := {"crit": 15, "hurt": 20, "kill": 12, "legendary": 45, "unique": 60, "signature": 60, "level_up": 35,
	"boss_intro": 70, "death": 90, "trap": 40, "evolve": 80, "shatter": 25, "enrage": 50}

func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	add_child(music_a)
	add_child(music_b)
	add_child(ambience)
	ambience.volume_db = -80.0
	for k in ["forest", "crypt", "water", "fire", "void"]:
		var ap: String = SOUND_DIR + "amb_" + k + ".wav"
		if ResourceLoader.exists(ap):
			var ast: AudioStreamWAV = load(ap)
			ast.loop_mode = AudioStreamWAV.LOOP_FORWARD
			ast.loop_begin = 0
			ast.loop_end = int(ast.get_length() * ast.mix_rate)
			amb_streams[k] = ast
			files_found += 1
	for p in [music_a, music_b]:
		p.volume_db = -80.0

	# Simple generated fallbacks: [seconds, start Hz, end Hz, wave, noise 0-1, volume 0-1]
	var fallback := {
		"hit": [[0.07, 240, 90, "square", 0.45, 0.35]],
		"crit": [[0.14, 420, 70, "square", 0.5, 0.5]],
		"hurt": [[0.09, 150, 70, "square", 0.55, 0.32]],
		"tap": [[0.045, 700, 380, "tri", 0.2, 0.3]],
		"kill": [[0.22, 320, 60, "square", 0.6, 0.4]],
		"loot": [[0.07, 880, 880, "tri", 0.0, 0.3], [0.12, 1320, 1320, "tri", 0.0, 0.3]],
		"legendary": [[0.09, 523, 523, "square", 0.0, 0.22], [0.09, 659, 659, "square", 0.0, 0.22], [0.09, 784, 784, "square", 0.0, 0.22], [0.35, 1047, 1047, "square", 0.0, 0.25]],
		"potion": [[0.16, 380, 900, "sine", 0.05, 0.4]],
		"floor": [[0.1, 392, 392, "tri", 0.0, 0.35], [0.2, 523, 523, "tri", 0.0, 0.35]],
		"death": [[0.5, 330, 55, "square", 0.25, 0.4]],
		"click": [[0.025, 1100, 900, "tri", 0.0, 0.18]],
		"equip": [[0.06, 300, 300, "square", 0.3, 0.25], [0.08, 600, 600, "tri", 0.0, 0.25]],
		"buy": [[0.05, 1200, 1200, "tri", 0.0, 0.25], [0.1, 1600, 1600, "tri", 0.0, 0.25]],
		"sell": [[0.05, 900, 900, "tri", 0.0, 0.25], [0.1, 1200, 1200, "tri", 0.0, 0.25]],
		"salvage": [[0.12, 200, 80, "square", 0.7, 0.3]],
		"craft": [[0.04, 900, 900, "square", 0.5, 0.3], [0.2, 1400, 1300, "tri", 0.0, 0.25]],
	}
	for n in fallback:
		sounds[n] = _synth(fallback[n])
	# Recorded sounds override the fallbacks when present
	for n in ["hit", "crit", "hurt", "tap", "kill", "loot_0", "loot_1", "loot_2", "loot_3", "loot", "legendary", "unique",
			"potion", "floor", "death", "click", "equip", "buy", "sell", "salvage", "craft", "level_up", "spec",
			"boss_intro", "dodge", "burn", "stun", "buff", "ability", "error",
			"rare_spawn", "signature", "achievement", "event", "page",
			"awaken", "transform", "hidden", "escape", "portal",
			"evolve", "weak_hit", "resisted", "freeze", "shatter", "combo", "milestone", "pet", "curse", "enrage",
			"drop", "door", "trap", "whoosh"]:
		var path: String = SOUND_DIR + n + ".wav"
		if ResourceLoader.exists(path):
			sounds[n] = load(path)
			files_found += 1
	# If a newer sound file is missing, borrow the closest older one
	var aliases := {"loot_0": "loot", "loot_1": "loot", "loot_2": "loot", "loot_3": "loot", "unique": "legendary",
		"level_up": "legendary", "spec": "legendary", "boss_intro": "floor", "dodge": "tap", "burn": "hit",
		"stun": "crit", "buff": "potion", "ability": "crit", "error": "click",
		"rare_spawn": "boss_intro", "signature": "unique", "achievement": "level_up", "event": "floor", "page": "click",
		"awaken": "level_up", "transform": "rare_spawn", "hidden": "signature", "escape": "dodge", "portal": "event",
		"evolve": "spec", "weak_hit": "crit", "resisted": "hit", "freeze": "stun", "shatter": "crit", "combo": "ability", "milestone": "level_up", "pet": "buff", "curse": "boss_intro", "enrage": "boss_intro",
		"drop": "loot", "door": "tap", "trap": "hurt", "whoosh": "tap"}
	for n in aliases:
		if not sounds.has(n):
			sounds[n] = sounds[aliases[n]]
	for track in ["zone_0", "zone_1", "zone_2", "zone_3", "zone_4", "zone_5", "zone_6", "zone_7", "zone_8", "zone_9", "boss", "boss2", "menu", "town"]:
		var path: String = SOUND_DIR + "music_" + track + ".wav"
		if ResourceLoader.exists(path):
			var stream: AudioStreamWAV = load(path)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			music_streams[track] = stream
			files_found += 1

func set_volumes(effects: float, music: float) -> void:
	sfx_db = linear_to_db(maxf(effects, 0.001))
	music_linear = music
	var active := music_a if music_a.playing and music_a.volume_db > -40.0 else music_b
	if active.playing:
		active.volume_db = _music_db()
	if ambience.playing:
		ambience.volume_db = _amb_db()

func _music_db() -> float:
	return linear_to_db(maxf(music_linear * 0.6, 0.0001)) if enabled and music_linear > 0.0 else -80.0

func play(sound_name: String, pitch := 1.0) -> void:
	if not enabled or not sounds.has(sound_name):
		return
	var p := players[next_player]
	next_player = (next_player + 1) % VOICES
	p.stream = sounds[sound_name]
	p.pitch_scale = pitch
	p.volume_db = sfx_db
	p.play()
	if haptics and HAPTIC.has(sound_name) and OS.has_feature("mobile"):
		Input.vibrate_handheld(int(HAPTIC[sound_name]), 0.6)

## Picks the zone music (or the boss theme) and crossfades when it changes.
func update_music(state: GameState) -> void:
	if state.in_town:
		play_ambience("")
		play_music("town" if music_streams.has("town") else "menu")
	elif state.enemy_is_boss:
		# The boss theme gets faster and heavier for the second half of the fight (or once it enrages)
		var late := state.enemy_hp * 2 < state.enemy_max_hp or Combat.enrage_left(state) == 0
		play_music("boss2" if late and music_streams.has("boss2") else "boss")
	else:
		play_music("zone_%d" % GameData.zone_index(state.floor_num))
	if not state.in_town:
		var kind: String = HallsScene.MOODS[clampi(GameData.zone_index(state.floor_num), 0, 9)]["kind"]
		play_ambience(String(AMBIENCE.get(kind, "crypt")))

## Crossfades to a music track ("menu", "boss", "zone_0"...).
func play_music(want: String) -> void:
	if music_streams.is_empty():
		return
	if not music_streams.has(want):
		return
	if want == music_current:
		var active := music_a if music_a.stream == music_streams[want] else music_b
		active.volume_db = _music_db()
		return
	music_current = want
	var incoming := music_b if music_a.playing else music_a
	var outgoing := music_a if incoming == music_b else music_b
	incoming.stream = music_streams[want]
	incoming.volume_db = -60.0
	incoming.play()
	var t := create_tween().set_parallel(true)
	t.tween_property(incoming, "volume_db", _music_db(), MUSIC_FADE)
	if outgoing.playing:
		t.tween_property(outgoing, "volume_db", -60.0, MUSIC_FADE)
		t.chain().tween_callback(outgoing.stop)

## Builds a beep from segments of simple waves with a quick fade-out each.
func _synth(segments: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	for seg in segments:
		var dur: float = seg[0]
		var f0: float = seg[1]
		var f1: float = seg[2]
		var wave: String = seg[3]
		var noise: float = seg[4]
		var vol: float = seg[5]
		var n := int(dur * RATE)
		var start := data.size()
		data.resize(start + n * 2)
		for i in n:
			var t := float(i) / n
			phase += lerpf(f0, f1, t) / RATE
			var x := fmod(phase, 1.0)
			var s := 0.0
			match wave:
				"sine":
					s = sin(x * TAU)
				"square":
					s = 1.0 if x < 0.5 else -1.0
				_:
					s = 1.0 - 4.0 * absf(x - 0.5)
			s = lerpf(s, randf() * 2.0 - 1.0, noise)
			var env := minf(1.0, i / (RATE * 0.003)) * pow(1.0 - t, 1.6)
			data.encode_s16(start + i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav

func _amb_db() -> float:
	return sfx_db - 15.0 if enabled else -80.0

## Fades the room ambience to `kind` ("forest", "crypt", "water", "fire", "void"; "" for silence).
func play_ambience(kind: String) -> void:
	if kind == ambience_current:
		if ambience.playing:
			ambience.volume_db = _amb_db()
		return
	ambience_current = kind
	var t := create_tween()
	if ambience.playing:
		t.tween_property(ambience, "volume_db", -60.0, 0.6)
		t.tween_callback(ambience.stop)
	if kind != "" and amb_streams.has(kind):
		t.tween_callback(func():
			ambience.stream = amb_streams[kind]
			ambience.volume_db = -60.0
			ambience.play())
		t.tween_property(ambience, "volume_db", _amb_db(), 1.2)
