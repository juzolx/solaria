class_name BattleView
extends Control
## Draws the fight: background, pixel-art hero and monster, health bars,
## attack swings, projectiles, hit flashes, screen shake and floating damage numbers.
## The hero and monster pictures come from Sprites (art/ folder); the small
## built-in shapes below are only used if a picture is missing.

# ---------- Pixel art (16x16) ----------
# K outline, B body, D body shadow, L body highlight, W white, R red,
# S steel, s dark steel, G gold, H skin, C cape. "." is see-through.
const HERO_ART := [
	"................",
	"......KKKK......",
	".....KSSSSK.....",
	"....KSLSSSSK....",
	"....KSKKKKSK..K.",
	"....KSSSSSSK.KSK",
	".....KSSSSK.KSK.",
	"...KKCKKKKCKKSK.",
	"..KCCKSSSSKHSK..",
	"..KCKSSGGSSKKK..",
	"..KCKSSSSSSK....",
	"..KCKsSSSSsK....",
	"...KKKsKKsKK....",
	".....KsK.KsK....",
	"....KssK.KssK...",
	"....KKKK.KKKK...",
]

const SHAPES := {
	"humanoid": [
		"................",
		"......KKKK......",
		".....KBBBBK.....",
		"...KKBRBBRBK....",
		"..KBKBBBBBBKK...",
		"....KBKWWKBK....",
		".....KBBBBK.....",
		"...KKKDDDDKKK...",
		"..KBKDDDDDDKBK..",
		".KBK.KDDDDK.KBK.",
		".KK..KDDDDK..KK.",
		".....KDKKDK.....",
		".....KBK.KBK....",
		".....KBK.KBK....",
		"....KKK...KKK...",
		"................",
	],
	"beast": [
		"................",
		"................",
		"................",
		"..KK............",
		".KBBK...........",
		"KRBBBKKKKKKKKK..",
		"KBBBBBBBBBBBBBK.",
		".KWKBBLLLLBBBBBK",
		"..KKBBBBBBBBBDK.",
		"...KBBBBBBBBBDK.",
		"...KDBKKKKKKBDK.",
		"...KDK.....KDK..",
		"...KBK.....KBK..",
		"...KBK.....KBK..",
		"..KKK.....KKK...",
		"................",
	],
	"brute": [
		"....KKKKKKK.....",
		"...KBBBBBBBK....",
		"..KBRBBBBRBBK...",
		"..KBBBBBBBBBK...",
		"..KBKWKKKWKBK...",
		"...KBBBBBBBK....",
		".KKKDDDDDDDKKK..",
		"KBBKDLLLLLDKBBK.",
		"KBBKDDDDDDDKBBK.",
		"KBBKDDDDDDDKBBK.",
		".KKKDDDDDDDKKK..",
		"...KDDDKDDDK....",
		"...KBBK.KBBK....",
		"...KBBK.KBBK....",
		"..KKKKK.KKKKK...",
		"................",
	],
	"spirit": [
		"................",
		"......KKKK......",
		"....KKLLBBKK....",
		"...KLLBBBBBBK...",
		"..KLBBBBBBBBBK..",
		"..KBWWBBBWWBBK..",
		".KBBWRBBBWRBBBK.",
		".KBBBBBBBBBBBBK.",
		".KBBBBKKKKBBBBK.",
		".KBBBBBBBBBBBDK.",
		"..KBBBBBBBBBDK..",
		"..KDBBBBBBBDDK..",
		"...KDBDBDBDDK...",
		"...K.KDK.KDK....",
		"......K...K.....",
		"................",
	],
	"serpent": [
		"................",
		"......KKKK......",
		".....KBBBBK.....",
		"....KRWBBBBK....",
		"...KRBBBBBBK....",
		"....KKKKBBBK....",
		".......KBBK.....",
		"......KBLK......",
		".....KBBK.......",
		".....KBLK.......",
		"......KBBKKKK...",
		".......KBBBBBK..",
		"..KKK...KKKBBK..",
		".KBBBKKKKKBBBK..",
		".KDBBBBBBBBBK...",
		"..KKKKKKKKKK....",
	],
}

signal tapped

var state: GameState
var sfx: Sfx
var profile: Profile  # accessibility settings (shake, damage numbers, flashes)
var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var toasts: Array[String] = []
var toast_text := ""
var toast_life := 0.0

var hero_tex: ImageTexture
var tex_cache := {}

# Animation values (tweened)
var hero_lunge := 0.0
var enemy_lunge := 0.0
var hero_flash := 0.0
var enemy_flash := 0.0
var hero_alpha := 1.0
var enemy_alpha := 1.0
var dying := {}  # the enemy that just died, fading out
var shake := 0.0
var bob := 0.0
var floaters: Array[Dictionary] = []
var banner_text := ""
var banner_sub := ""
var banner_alpha := 0.0
var banner_color := Color("#fbbf24")
var last_floor := -1
var hero_white: ImageTexture
var cape := Color("#2563eb")
var _off := Vector2.ZERO
var hero_art := {}       # from Sprites.hero()
var hero_art_key := ""
var swing := 0.0         # weapon swing: -1 wind-up, +1 strike
var lpc_anim := "combat_idle"  # LPC heroes: the animation playing (lpc.gd)
var lpc_t := 0.0
var pet_lunge := 0.0
var chest_t := -1.0   # chest-opening moment: seconds since it appeared (-1 = none)
static var _chest_tex: Array = []  # [closed, open]
const CHEST_ART := [
	["....KKKKKKKKKKKK....", "..KKbbbbbbbbbbbbKK..", ".KbbBBBBBBBBBBBBbbK.", ".KbBBBBBBBBBBBBBBbK.", "KbBBBBBBBBBBBBBBBBbK",
	 "KGGGGGGGGGGGGGGGGGGK", "KGggggggKYYKggggggGK", "KbBBBBBBKyyKBBBBBBbK", "KbBBBBBBBKKBBBBBBBbK", "KbBBBBBBBBBBBBBBBBbK",
	 "KbBBBBBBBBBBBBBBBBbK", "KGGGGGGGGGGGGGGGGGGK", "KbbbbbbbbbbbbbbbbbbK", ".KKKKKKKKKKKKKKKKKK."],
	["..KKKKKKKKKKKKKKKK..", ".KbbbbbbbbbbbbbbbbK.", "KbBBBBBBBBBBBBBBBBbK", "KGGGGGGGGGGGGGGGGGGK", "KYYYYYYYYYYYYYYYYYYK",
	 "KGGGGGGGGGGGGGGGGGGK", "KGggggggKYYKggggggGK", "KbBBBBBBKyyKBBBBBBbK", "KbBBBBBBBKKBBBBBBBbK", "KbBBBBBBBBBBBBBBBBbK",
	 "KbBBBBBBBBBBBBBBBBbK", "KGGGGGGGGGGGGGGGGGGK", "KbbbbbbbbbbbbbbbbbbK", ".KKKKKKKKKKKKKKKKKK."],
]
var beams: Array = []   # loot beams: {"x", "color", "t", "life", "w"} (Rare and better)
var fx_sprites: Array = []   # sprite effects: {"name", "pos", "t", "scale", "flip"} (art/fx)
static var _fx_tex := {}
static var _fx_frames := {}
const FX_FPS := 26.0
var enemy_lpc_anim := "combat_idle"  # LPC monsters: the animation playing
var enemy_lpc_t := 0.0
var recoil := 0.0        # hero knocked back when hit
var enemy_recoil := 0.0
var projectiles: Array[Dictionary] = []
const MELEE_REST := 45.0
# Pose animation: a queue of [pose name, seconds]; idle breathing when empty
var cast_glow := 0.0       # the magic circle under the hero when a skill is cast
var cast_color := Color.WHITE
var party_fx := {}        # companion index -> {"lunge", "flash"} for their little animations
var hero_seq: Array = []
var enemy_seq: Array = []
var hero_pose := "idle0"
var enemy_pose := "idle0"
var hero_pose_t := 0.0
var enemy_pose_t := 0.0
const IDLE_HOLD := 0.45  # seconds per breathing frame

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	hero_tex = _make_tex(HERO_ART, Color.WHITE)
	hero_white = _make_tex(HERO_ART, Color.WHITE, true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

## Tapping or clicking anywhere in the fight attacks.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(mb.position)
	elif touch != null and touch.pressed:
		tapped.emit(touch.position)

## Recolors the hero's cape to match the class.
func set_cape(color: Color) -> void:
	cape = color
	hero_tex = _make_tex(HERO_ART, Color.WHITE)

func _sfx(sound_name: String, pitch := 1.0) -> void:
	if sfx:
		sfx.play(sound_name, pitch)

func toast(text: String) -> void:
	toasts.append(text)

func tap_ring(pos: Vector2) -> void:
	rings.append({"pos": pos, "life": 0.25})

# =====================================================================
# Playing events from GameState
# =====================================================================

func play(events: Array[Dictionary]) -> void:
	_update_hero_art()
	if last_floor != state.floor_num:
		if last_floor != -1:
			_show_banner()
		last_floor = state.floor_num

	var delay := 0.0
	for e in events:
		match e["type"]:
			"hero_hit":
				_later(delay, _hero_attack.bind(e))
				delay += 0.35
			"enemy_hit":
				_later(delay, _enemy_attack.bind(e))
				delay += 0.3
			"dodge":
				_later(delay, func():
					_sfx("dodge", randf_range(0.9, 1.15))
					_float("DODGE", _hero_center(), Color("#e5e7eb"), 18))
				delay += 0.3
			"heal":
				_later(delay, func():
					_float("+%d" % e["amount"], _hero_center() + Vector2(-20, 20), Color("#4ade80"), 16)
					if int(e["amount"]) > 0:
						_fx("heal", _hero_center(), 0.9))
			"potion":
				_sfx("potion")
				_float("+%d" % e["amount"], _hero_center() + Vector2(0, 10), Color("#f472b6"), 20)
			"thorns":
				_later(delay, func(): _float("%d" % e["dmg"], _enemy_center() + Vector2(25, 15), Color("#c084fc"), 14))
			"tap_hit":
				_sfx("tap", randf_range(0.95, 1.1))
				enemy_flash = 1.0
				create_tween().tween_property(self, "enemy_flash", 0.0, 0.1)
				shake = maxf(shake, 2.0)
				_float("%d" % e["dmg"], _enemy_center() + Vector2(randf_range(-30, 30), -20), Color("#93c5fd"), 16)
				_burst(_enemy_center(), Color("#93c5fd"), 6, 160.0)
			"ability":
				_ability_fx(e)
			"buff":
				_sfx("buff")
				_float(str(e["name"]).to_upper() + "!", _hero_center() + Vector2(0, -30), Color("#c4b5fd"), 20)
				_burst(_hero_center(), Color("#a78bfa"), 24, 260.0)
			"stunned":
				_later(delay, func():
					_sfx("stun")
					_float("STUNNED", _enemy_center() + Vector2(0, -36), Color("#fde68a"), 16))
			"burn":
				_later(delay + 0.1, func():
					_sfx("burn", randf_range(0.9, 1.1))
					_float("%d" % e["dmg"], _enemy_center() + Vector2(randf_range(-25, 25), 10), Color("#fb923c"), 15)
					_burst(_enemy_center(), Color("#fb923c"), 6, 120.0))
			"pierce":
				_later(delay + 0.6, func():
					_float("PIERCE %d" % e["dmg"], _enemy_center(), Color("#4ade80"), 18)
					_burst(_enemy_center(), Color("#4ade80"), 12, 240.0))
			"level_up":
				_later(delay + 0.3, _level_up_fx.bind(e))
			"spec":
				_later(delay + 1.2, func():
					_sfx("spec")
					banner_text = str(e["name"]).to_upper()
					banner_sub = "You specialized: %s" % e["role"]
					banner_alpha = 2.6
					_burst(_hero_center(), Color("#e8b14a"), 40, 360.0))
			"loot":
				_later(delay + 0.15, _loot_pop.bind(e))
				delay += 0.12
			"tip", "toast":
				toast(e["text"])
			"elite":
				_sfx("boss_intro", 1.2)
				banner_text = "ELITE!"
				banner_sub = state.enemy_name
				banner_alpha = 1.6
				enemy_flash = 1.0
				create_tween().tween_property(self, "enemy_flash", 0.0, 0.3)
			"treasure":
				_open_chest()
			"rare_monster":
				_later(delay + 0.4, func():
					var t: int = e["tier"]
					_sfx("rare_spawn")
					banner_text = "%s MONSTER!" % Monsters.tier_name(t).to_upper()
					banner_sub = "%s  -  %s" % [e["name"], ", ".join(e["mods"])]
					banner_color = Color(Monsters.tier_color(t))
					banner_alpha = 2.2
					_burst(_enemy_center(), banner_color, 20 + t * 6, 300.0))
			"signature":
				_later(delay + 0.5, func():
					_sfx("signature")
					banner_text = "SIGNATURE DROP!"
					banner_sub = "%s  (from the %s)" % [e["name"], e["monster"]]
					banner_color = Color(GameData.color_of(GameData.SIGNATURE))
					banner_alpha = 3.5
					shake = 12.0
					_burst(_enemy_center(), banner_color, 60, 460.0)
					_hit_stop(0.15))
			"achievement":
				_later(delay + 0.8, func():
					_sfx("achievement")
					toast("Achievement unlocked: %s! %s" % [e["name"], e["text"]] + (("  New title: " + str(e["title"])) if str(e["title"]) != "" else "")))
			"mini_event":
				_sfx({"milestone": "milestone", "pet": "pet", "chest": "curse"}.get(String(e["kind"]), "event"))
				banner_text = str(e["title"])
				banner_sub = str(e["sub"])
				banner_color = Color("#c084fc") if e["kind"] == "shrine" else Color("#fbbf24")
				banner_alpha = 2.0
			"party_attack":
				_later(delay + 0.12, _party_anim.bind(e, "attack"))
			"party_skill":
				_later(delay + 0.12, _party_anim.bind(e, "skill"))
			"party_hit":
				_later(delay, _party_anim.bind(e, "hit"))
				delay += 0.25
			"party_heal":
				_later(delay, func(): _float("HEAL", _member_center(int(e["slot"])) + Vector2(0, -20), Color("#4ade80"), 15))
			"party_dodge":
				_later(delay, func(): _float("DODGE", _member_center(int(e["slot"])), Color("#e5e7eb"), 14))
			"party_down":
				_later(delay + 0.2, func(): _float("KNOCKED OUT", _member_center(int(e["slot"])) + Vector2(0, -24), Color("#f87171"), 15))
			"stone":
				_later(delay + 0.2, func():
					_sfx("legendary" if int(e["rarity"]) >= 2 else "loot_3")
					var col := Color(SkillData.RARITY_COLORS[int(e["rarity"])])
					floaters.append({"text": ("NEW SKILL: " if e["new"] else "") + str(e["name"]), "pos": _enemy_center() + Vector2(0, -10), "color": col, "size": 18, "life": 2.2, "keep": true, "t": 0.0, "lane": 0, "base": _enemy_center() + Vector2(0, -10)})
					_burst(_enemy_center(), Color("#c4b5fd"), 24, 280.0))
			"summon":
				_sfx("buff")
				_float(str(e["name"]).to_upper() + "!", _hero_center() + Vector2(30, -20), Color("#c4b5fd"), 18)
			"summon_hit":
				if e.has("name") and state.pet_on and World.pet_stage(state) >= 0:
					var pt := create_tween()
					pt.tween_property(self, "pet_lunge", 1.0, 0.1)
					pt.tween_property(self, "pet_lunge", 0.0, 0.2)
				_later(delay + 0.15, func():
					_fx("claw", _enemy_center() + Vector2(-16, 12), 0.7)
					_float("%d" % e["dmg"], _enemy_center() + Vector2(-20, 20), Color("#c4b5fd"), 15)
					_burst(_enemy_center() + Vector2(-20, 10), Color("#c4b5fd"), 6, 160.0))
			"confused":
				_later(delay, func():
					_float("CONFUSED %d" % e["dmg"], _enemy_center() + Vector2(0, -30), Color("#a8ca58"), 16)
					enemy_flash = 1.0
					create_tween().tween_property(self, "enemy_flash", 0.0, 0.12))
				delay += 0.3
			"shield_soak":
				_later(delay, func(): _float("BLOCKED %d" % e["dmg"], _hero_center() + Vector2(0, -20), Color("#93c5fd"), 15))
			"trial":
				_sfx("boss_intro")
				banner_text = "GOD TRIAL"
				banner_sub = str(e["name"])
				banner_color = Color("#e8b14a")
				banner_alpha = 3.0
			"goblin_escaped":
				_float("ESCAPED!", _enemy_center(), Color("#fbbf24"), 20)
			"illusion":
				_float("ILLUSION!", _enemy_center(), Color("#f9a8d4"), 20)
				_sfx("dodge")
			"escaped":
				_float("GOT AWAY", _hero_center() + Vector2(0, -20), Color("#a3e635"), 18)
			"escape_failed":
				_float("BLOCKED!", _hero_center() + Vector2(0, -20), Color("#f87171"), 18)
			"spared":
				_float("SPARED", _enemy_center(), Color("#4ade80"), 20)
			"phylactery":
				_float("PHYLACTERY!", _hero_center(), Color("#7fd0f0"), 22)
				_sfx("buff")
			"bitten":
				_float("BITTEN", _hero_center(), Color("#8b9bb4"), 16)
			"rep":
				_float("%s: %s" % [e["race"], e["level"]], _hero_center() + Vector2(0, -36), Color(e["color"]), 13)
			"key_item":
				_float(String(e["name"]).to_upper(), _hero_center() + Vector2(0, -30), Color("#fbbf24"), 16)
			"blink":
				_later(delay, func(): _float("BLINK", _enemy_center() + Vector2(0, -20), Color("#c084fc"), 16))
				delay += 0.3
			"shield_break":
				_later(delay, func():
					_float("SHIELD BROKEN", _enemy_center() + Vector2(0, -30), Color("#60a5fa"), 16)
					_burst(_enemy_center(), Color("#60a5fa"), 16, 260.0))
			"enemy_dead":
				# Keep the dead enemy on screen to fade it out; the new one fades in after
				var dart := Sprites.enemy_by_key(e.get("art", ""))
				var dtex: Texture2D = dart.get("tex", _enemy_tex(e["shape"], e["color"]))
				if not dart.is_empty():
					dtex = Sprites.poses_for("e" + str(e.get("art", "")), (dart["tex"] as Texture2D).get_image(), -1)["kneel2"]["tex"]
				dying = {"tex": dtex, "boss": e["boss"], "alpha": 1.0, "color": e["color"],
					"art": e.get("art", ""), "scale": e.get("scale", 1.0)}
				enemy_alpha = 0.0
				_later(delay + 0.05, _enemy_died)
			"hero_dead":
				_later(delay, _hero_died)
			"leader_down":
				_later(delay, func():
					_sfx("death")
					_pose_hero([["hit1", 0.08], ["kneel1", 0.16], ["kneel2", 0.7]])
					shake = maxf(shake, 8.0)
					_float("YOU'RE DOWN", _hero_rect().get_center() + Vector2(0, -40), Color("#f87171"), 18))
			"element":
				var weak: bool = e["kind"] == "weak"
				var ec := Color(Combat.ELEMENT_COLORS.get(e["element"], "#ffffff"))
				_later(delay, func(): _sfx("weak_hit" if weak else "resisted", randf_range(0.95, 1.08)))
				if weak:
					_later(delay + 0.08, func(): _fx(ELEMENT_FX.get(String(e["element"]), "burst"), _enemy_center(), 1.3))
				_later(delay, func(): _float("WEAK!" if weak else "RESISTED", _enemy_center() + Vector2(34, -44), ec.lightened(0.2) if weak else Color("#94a3b8"), 14 if weak else 12))
			"combo":
				_later(delay + 0.1, func():
					_sfx({"frozen": "freeze", "shatter": "shatter"}.get(e["id"], "combo"))
					var cc := Color(e["color"])
					floaters.append({"text": String(e["name"]).to_upper(), "pos": _enemy_center() + Vector2(0, -64), "color": cc, "size": 24, "life": 1.6, "keep": true, "t": 0.0, "lane": 0, "base": _enemy_center() + Vector2(0, -64)})
					_burst(_enemy_center(), cc, 26, 320.0)
					_fx({"frozen": "ice", "shatter": "shatter", "conduct": "lightning", "toxic": "poison", "purge": "holy"}.get(String(e["id"]), "burst"), _enemy_center(), 1.5)
					shake = maxf(shake, 5.0))
			"poison":
				_later(delay + 0.12, func():
					_float("%d" % e["dmg"], _enemy_center() + Vector2(randf_range(-25, 25), 18), Color("#a3e635"), 15)
					_burst(_enemy_center(), Color("#a3e635"), 5, 100.0)
					_fx("poison", _enemy_center() + Vector2(0, 10), 0.8))
			"first_strike":
				_later(delay, func(): _float("FIRST STRIKE", _hero_center() + Vector2(0, -42), Color("#93c5fd"), 15))
			"haste":
				_later(delay, func(): _float("EXTRA ATTACK", _hero_center() + Vector2(0, -42), Color("#93c5fd"), 14))
			"afflicted":
				_later(delay, func(): _float(String(e["name"]).to_upper(), _hero_center() + Vector2(0, -36), Color(e["color"]), 15))
			"resisted":
				_later(delay, func(): _float("RESISTED", _hero_center() + Vector2(0, -36), Color("#2dd4bf"), 14))
			"boss_mechanic":
				_later(delay + 0.2, func():
					var mid := String(e["id"])
					_sfx({"enrage": "enrage", "windup": "enrage", "crush": "crit", "stagger": "shatter"}.get(mid, "boss_intro"), 1.0 if mid != "shield" and mid != "minions" else 1.3)
					if mid == "crush":
						shake = 14.0
						_hit_stop(0.12)
						_fx("impact_red", _hero_center(), 1.8)
					elif mid == "stagger":
						_fx("shatter", _enemy_center(), 1.6)
					banner_text = String(e["name"]).to_upper()
					banner_sub = String(Combat.MECHANICS[e["id"]]["text"]).replace("%d", str(Combat.ENRAGE_TURNS))
					banner_color = Color(e["color"])
					banner_alpha = 2.0
					shake = maxf(shake, 6.0))
			"minion_dead":
				_later(delay, func(): _float("MINION DOWN", _enemy_center() + Vector2(-30, -10), Color("#d4d4d4"), 13))
			"mastery":
				_later(delay + 0.4, func():
					_sfx("achievement")
					toast(String(e["name"]) + "!"))

## Rebuilds the hero picture when the look or gear changes.
func _update_hero_art() -> void:
	var looks := state.hero_looks()
	var key := str(state.appearance) + str(looks)
	if key != hero_art_key:
		hero_art_key = key
		hero_art = Sprites.hero_back(state.appearance, looks)

## A companion's attack, skill or getting hit.
func _party_anim(e: Dictionary, kind: String) -> void:
	var i := _member_index(int(e["slot"]))
	if i < 0:
		return
	if not party_fx.has(i):
		party_fx[i] = {"lunge": 0.0, "flash": 0.0}
	var fx: Dictionary = party_fx[i]
	match kind:
		"attack", "skill":
			var t := create_tween()
			t.tween_method(func(v: float): fx["lunge"] = v, 0.0, 1.0, 0.07)
			t.tween_method(func(v: float): fx["lunge"] = v, 1.0, 0.0, 0.16)
			if kind == "skill":
				_float(str(e["name"]).to_upper(), _enemy_center() + Vector2(0, -44), Color(e.get("color", "#ffffff")), 16)
				_burst(_enemy_center(), Color(e.get("color", "#ffffff")), 14, 260.0)
				_sfx("ability", 1.15)
			else:
				_sfx("hit", randf_range(1.05, 1.2))
				_float("%d" % e["dmg"], _enemy_center() + Vector2(randf_range(-30, 30), 16), Color("#e5e7eb") if not e.get("crit", false) else Color("#fbbf24"), 15)
			_pose_enemy([["hit2", 0.1]])
		"hit":
			fx["flash"] = 1.0
			create_tween().tween_method(func(v: float): fx["flash"] = v, 1.0, 0.0, 0.15)
			_pose_enemy([["windup", 0.1], ["strike", 0.07], ["follow", 0.1]])
			_sfx("hurt", 1.1)
			_float("-%d" % e["dmg"], _member_center(int(e["slot"])), Color("#f87171"), 16)

## Plays a pose sequence: [["windup", 0.1], ["strike", 0.06], ...]
func _pose_hero(seq: Array) -> void:
	hero_seq = seq.duplicate()
	hero_pose_t = 0.0
	if not hero_seq.is_empty():
		hero_pose = hero_seq[0][0]

func _pose_enemy(seq: Array) -> void:
	enemy_seq = seq.duplicate()
	enemy_pose_t = 0.0
	if not enemy_seq.is_empty():
		enemy_pose = enemy_seq[0][0]

func _step_pose(seq: Array, pose: String, t: float, delta: float, offset: float) -> Array:
	t += delta
	if seq.is_empty():
		var idle := "idle1" if fmod(bob + offset, IDLE_HOLD * 2.0) > IDLE_HOLD else "idle0"
		return [seq, idle, 0.0]
	if t >= float(seq[0][1]):
		seq.pop_front()
		t = 0.0
		if not seq.is_empty():
			pose = seq[0][0]
		else:
			pose = "idle0"
	return [seq, pose, t]

func _later(delay: float, fn: Callable) -> void:
	if delay <= 0.0:
		fn.call()
	else:
		get_tree().create_timer(delay).timeout.connect(fn)

## A treasure chest pops up, rattles, and bursts open in a shower of gold.
func _open_chest() -> void:
	chest_t = 0.0
	_sfx("event")
	_later(0.55, func():
		_sfx("legendary", 1.1)
		var p := _chest_pos()
		_burst(p, Color("#fbbf24"), 34, 320.0)
		_fx("burst", p, 1.2)
		beams.append({"x": p.x, "color": Color("#fbbf24"), "t": 0.0, "life": 1.4, "w": 4.0})
		shake = maxf(shake, 5.0))

func _chest_pos() -> Vector2:
	return Vector2(size.x * 0.5, _ground() - 10.0 * _u())

func _draw_chest() -> void:
	if chest_t < 0.0:
		return
	if _chest_tex.is_empty():
		var pal := {"K": Color("#1c1526"), "b": Color("#5a3a2a"), "B": Color("#8a5a3a"), "G": Color("#c8902a"), "g": Color("#8a5a1a"), "Y": Color("#fde68a"), "y": Color("#e8b14a")}
		for art in CHEST_ART:
			var img := Image.create(20, 14, false, Image.FORMAT_RGBA8)
			for y in art.size():
				for x in String(art[y]).length():
					var ch := String(art[y])[x]
					if pal.has(ch):
						img.set_pixel(x, y, pal[ch])
			_chest_tex.append(ImageTexture.create_from_image(img))
	var u := float(maxi(2, _unit() + 1)) / _scr()
	var open := chest_t > 0.55
	var a := clampf(chest_t * 5.0, 0.0, 1.0) * clampf((2.2 - chest_t) * 2.5, 0.0, 1.0)
	var rattle := 0.0 if open or chest_t < 0.15 else sin(chest_t * 60.0) * u
	var pop := minf(1.0, chest_t * 6.0)
	var sz := Vector2(20, 14) * u
	var base := _chest_pos()
	var pos := Vector2(base.x - sz.x / 2.0 + rattle, base.y - sz.y * pop + 6.0 * u)
	if open:
		var glow := clampf(1.0 - (chest_t - 0.55) / 1.4, 0.0, 1.0)
		draw_circle(base + Vector2(0, -sz.y * 0.6), sz.x * (0.6 + 0.4 * (1.0 - glow)), Color(1.0, 0.85, 0.4, 0.25 * glow * a))
	draw_texture_rect(_chest_tex[1 if open else 0], Rect2(_snap(pos), sz), false, Color(1, 1, 1, a))

## Plays a sprite effect from art/fx (see tools/fx_extract.py) centered on pos.
func _fx(fx_name: String, pos: Vector2, scale_mult := 1.0, flip := false) -> void:
	if not _fx_tex.has(fx_name):
		if _fx_frames.is_empty():
			var j := load("res://art/fx/fx.json") as JSON
			if j:
				_fx_frames = j.data
		var path := "res://art/fx/%s.png" % fx_name
		_fx_tex[fx_name] = load(path) if ResourceLoader.exists(path) else null
	if _fx_tex[fx_name] == null:
		return
	fx_sprites.append({"name": fx_name, "pos": pos, "t": 0.0, "scale": scale_mult, "flip": flip})
	if fx_sprites.size() > 12:
		fx_sprites.pop_front()

const ELEMENT_FX := {"Fire": "fire", "Ice": "ice", "Lightning": "lightning", "Poison": "poison", "Holy": "holy",
	"Dark": "shadow", "Shadow": "shadow", "Nature": "nature", "Arcane": "arcane", "Storm": "lightning"}

## LPC heroes play a real animation (slash, thrust, cast, shoot).
func _lpc_play(anim: String) -> void:
	if hero_art.has("lpc") and (hero_art["lpc"] as Dictionary).has(anim):
		lpc_anim = anim
		lpc_t = 0.0

func _hero_attack(e: Dictionary) -> void:
	_lpc_play(Lpc.attack_anim(_weapon_type()))
	var ranged := _weapon_type() in ["bow", "staff"]
	if ranged:
		_pose_hero([["crouch", 0.08], ["follow", 0.16]])
	else:
		_pose_hero([["windup", 0.1], ["strike", 0.06], ["follow", 0.12]])
	_later(0.1, func(): _pose_enemy([["hit1", 0.07], ["hit2", 0.12]]))
	var t := create_tween()
	if ranged:
		t.tween_property(self, "swing", -0.6, 0.07)
		t.tween_property(self, "swing", 0.0, 0.2)
		_shoot(Color("#a78bfa") if _weapon_type() == "staff" else Color("#e5e7eb"))
	else:
		t.set_parallel(true)
		t.tween_property(self, "hero_lunge", 1.0, 0.08)
		t.tween_property(self, "swing", -0.9, 0.06)
		t.chain().tween_property(self, "swing", 1.2, 0.07)
		t.chain().tween_property(self, "hero_lunge", 0.0, 0.18)
		t.parallel().tween_property(self, "swing", 0.0, 0.2)
	var kb := create_tween()
	kb.tween_property(self, "enemy_recoil", 1.0, 0.06)
	kb.tween_property(self, "enemy_recoil", 0.0, 0.2)
	enemy_flash = 1.0
	create_tween().tween_property(self, "enemy_flash", 0.0, 0.1)
	var target := _enemy_center()
	var wt := _weapon_type()
	var hit_fx := "pierce" if wt in ["spear", "bow"] else ("impact" if wt in ["staff", "mace"] else "slash")
	_later(0.06 if not ranged else 0.16, func():
		_fx("slash_crit" if e["crit"] and hit_fx == "slash" else hit_fx, target, 1.25 if e["crit"] else 1.0)
		if e["crit"]:
			_fx("crit", target, 1.4))
	_sfx("crit" if e["crit"] else "hit", randf_range(0.92, 1.08))
	if e["crit"]:
		shake = 10.0
		_float("CRIT %d" % e["dmg"], target, Color("#fbbf24"), 26)
		_burst(target, Color("#fbbf24"), 22, 320.0)
		_hit_stop(0.07)
	else:
		# Heavy weapons land heavy: more shake and a tiny freeze; light ones stay snappy
		var weight: float = {"axe": 1.0, "mace": 1.0, "spear": 0.6, "sword": 0.5, "staff": 0.35, "bow": 0.25, "dagger": 0.2}.get(wt, 0.4)
		shake = maxf(shake, 2.0 + 4.0 * weight)
		if weight >= 0.9:
			_hit_stop(0.035)
		_float("%d" % e["dmg"], target, Color.WHITE, 20)
		_burst(target, Color(state.enemy_color), 10, 220.0)
	if e["double"]:
		_float("x2", target + Vector2(40, -10), Color("#fbbf24"), 16)

func _enemy_attack(e: Dictionary) -> void:
	var eart := _enemy_art(state.enemy_is_boss)
	if eart.has("lpc"):
		var an: String = eart.get("attack", "slash")
		if (eart["lpc"] as Dictionary).has(an):
			enemy_lpc_anim = an
			enemy_lpc_t = 0.0
	_pose_enemy([["windup", 0.1], ["strike", 0.07], ["follow", 0.12]])
	_later(0.08, func(): _pose_hero([["hit1", 0.07], ["hit2", 0.14]]))
	var t := create_tween()
	t.tween_property(self, "enemy_lunge", 1.0, 0.08)
	t.tween_property(self, "enemy_lunge", 0.0, 0.18)
	_sfx("hurt", randf_range(0.92, 1.08))
	var kb := create_tween()
	kb.tween_property(self, "recoil", 1.0, 0.06)
	kb.tween_property(self, "recoil", 0.0, 0.22)
	hero_flash = 1.0
	create_tween().tween_property(self, "hero_flash", 0.0, 0.1)
	shake = maxf(shake, 4.0)
	_burst(_hero_center(), Color("#f87171"), 8, 200.0)
	_fx("claw", _hero_center(), 1.0, true)
	_float("-%d" % e["dmg"], _hero_center(), Color("#f87171"), 20)

func _ability_fx(e: Dictionary) -> void:
	var c := Color(e.get("color", "#ffffff"))
	_sfx("ability", randf_range(0.95, 1.05))
	_pose_hero([["crouch", 0.1], ["cast", 0.18], ["strike", 0.06], ["follow", 0.14]])
	_lpc_play("spellcast" if _weapon_type() in ["staff", "", "orb", "tome"] else Lpc.attack_anim(_weapon_type()))
	cast_color = c
	cast_glow = 1.0
	create_tween().tween_property(self, "cast_glow", 0.0, 0.6)
	_later(0.3, func(): _pose_enemy([["hit1", 0.08], ["hit2", 0.14]]))
	var els := Combat.elements_of([String(e.get("tag", ""))])
	var sfx_name: String = ELEMENT_FX.get(String(els[0]) if not els.is_empty() else "", "arcane" if String(e.get("tag", "")) in ["Arcane", "Song", "Trick"] else "burst")
	_later(0.28, func(): _fx(sfx_name, _enemy_center(), 1.6))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "hero_lunge", 1.4, 0.07)
	t.tween_property(self, "swing", -1.2, 0.07)
	t.chain().tween_property(self, "swing", 1.5, 0.08)
	t.chain().tween_property(self, "hero_lunge", 0.0, 0.2)
	t.parallel().tween_property(self, "swing", 0.0, 0.25)
	if _weapon_type() in ["bow", "staff"]:
		_shoot(c, true)
	enemy_flash = 1.0
	create_tween().tween_property(self, "enemy_flash", 0.0, 0.12)
	shake = 9.0
	_float("%s %d" % [str(e["name"]).to_upper(), e["dmg"]], _enemy_center() + Vector2(0, -24), c, 22)
	_burst(_enemy_center(), c, 26, 360.0)
	_hit_stop(0.06)

func _level_up_fx(e: Dictionary) -> void:
	_sfx("level_up")
	banner_text = "LEVEL UP!"
	banner_sub = "You're now level %d" % e["level"]
	banner_alpha = 2.0
	_burst(_hero_center(), Color("#fbbf24"), 30, 300.0)
	_float("LEVEL %d" % e["level"], _hero_center() + Vector2(0, -30), Color("#fbbf24"), 22)


var halls := HallsScene.new()

## The old painted backdrop (town and trials still use it).
func _draw_old_bg(w: float, h: float) -> void:
	var zone := GameData.zone_for_floor(state.floor_num)
	var tint := Color(zone["color"])
	var bg := _bg_tex(GameData.zone_index(state.floor_num), GameData.sub_index(state.floor_num))
	if bg:
		var gy := _ground()
		var ss := _scr()
		# Whole screen pixels per background pixel, so the scene stays crisp at any window size
		var sc := maxf(maxf(ceilf(w * ss / BG_SIZE.x), ceilf(gy * ss / BG_GROUND)), ceilf((h - gy) * ss / (BG_SIZE.y - BG_GROUND))) / ss
		var bw := BG_SIZE.x * sc
		var dim := 0.62
		draw_texture_rect(bg, Rect2(_snap(Vector2((w - bw) / 2.0, gy - BG_GROUND * sc)), Vector2(bw, BG_SIZE.y * sc)), false, Color(dim, dim, dim * 1.05))
		# Vignette: the edges fall into shadow so the fighters read first
		for i in 8:
			var t := float(i) / 8.0
			var va := 0.05 * (1.0 - t)
			draw_rect(Rect2(0, 0, w * 0.18 * (1.0 - t), h), Color(0.0, 0.0, 0.02, va))
			draw_rect(Rect2(w - w * 0.18 * (1.0 - t), 0, w * 0.18 * (1.0 - t), h), Color(0.0, 0.0, 0.02, va))
			draw_rect(Rect2(0, 0, w, h * 0.22 * (1.0 - t)), Color(0.0, 0.0, 0.02, va))
		_draw_mood(w, h, gy)
	else:
		draw_rect(Rect2(0, 0, w, h), tint.darkened(0.82))
		draw_rect(Rect2(0, _ground(), w, h - _ground()), tint.darkened(0.6))

const BG_SIZE := Vector2(320, 180)
const BG_GROUND := 136.0
var _bgs := {}

## The area's own background (art/bg/zone_Z_S.png), or the zone's if missing.
func _bg_tex(zone: int, sub := -1) -> Texture2D:
	var key := "%d_%d" % [zone, sub]
	if not _bgs.has(key):
		var path := "res://art/bg/zone_%d_%d.png" % [zone, sub]
		if sub < 0 or not ResourceLoader.exists(path):
			path = "res://art/bg/zone_%d.png" % zone
		_bgs[key] = load(path) if ResourceLoader.exists(path) else null
	return _bgs[key]

func _weapon_type() -> String:
	return str(hero_art.get("weapon_type", ""))

## Fires an arrow (bow) or a magic bolt (staff) from the hero's hand to the enemy.
func _shoot(color: Color, big := false) -> void:
	var from := _hand_screen()
	var to := _enemy_center()
	projectiles.append({"pos": from, "from": from, "to": to, "t": 0.0, "color": color,
		"kind": "arrow" if _weapon_type() == "bow" else "bolt", "big": big})

## Freezes the action for a split second so big hits feel heavy.
func _hit_stop(seconds: float) -> void:
	if profile and not profile.flashes:
		return
	Engine.time_scale = 0.05
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _burst(pos: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		var angle := randf() * TAU
		var v := Vector2(cos(angle), sin(angle)) * speed * randf_range(0.4, 1.0)
		particles.append({"pos": pos, "vel": v + Vector2(0, -80), "color": color, "life": randf_range(0.4, 0.8), "size": randf_range(3.0, 6.0)})

## The dropped item's name pops out of the enemy in its rarity color.
func _loot_pop(e: Dictionary) -> void:
	var r: int = e["rarity"]
	if r == GameData.SIGNATURE:
		pass  # the signature event plays its own fanfare
	elif r == GameData.UNIQUE:
		_sfx("unique")
	elif r >= GameData.LEGENDARY:
		_sfx("legendary")
	else:
		_sfx("loot_%d" % clampi(r, 0, 3), randf_range(0.97, 1.03))
	var color := Color(GameData.color_of(r))
	var pos := _enemy_center() + Vector2(0, 20)
	# Only Epic and better get their name in the air (the log lists everything);
	# the rest just sparkle in their rarity color
	if r >= 3:
		var lp := _lane_for(pos, 14 + mini(r, 5) * 2, true)
		floaters.append({"text": e["name"], "pos": lp[0], "base": lp[0], "t": 0.0, "lane": lp[1], "color": color, "size": 14 + mini(r, 5) * 2, "life": 1.8, "keep": true})
	_burst(pos, color, 8 + r * 6, 140.0 + r * 50.0)
	# A beam of light marks good drops; the rarer, the wider and longer
	if r >= 2:
		beams.append({"x": pos.x + randf_range(-12, 12), "color": color, "t": 0.0, "life": 0.9 + 0.35 * mini(r, 5), "w": 2.0 + mini(r, 5)})
		if beams.size() > 6:
			beams.pop_front()
	# Better than what you wear? Say so right away, whatever the rarity
	var up := float(e.get("up", 0.0))
	if up >= 0.5:
		var txt := "UPGRADE!" if up >= 99.0 else "UPGRADE +%d%%" % maxi(1, int(round(up)))
		var hp := _hero_center() + Vector2(0, -52)
		floaters.append({"text": txt, "pos": hp, "base": hp, "t": 0.0, "lane": 0, "color": Color("#4ade80"), "size": 15, "life": 1.6, "keep": true})
	if r >= GameData.LEGENDARY and r != GameData.SIGNATURE and r != GameData.SET_RARITY:
		shake = 9.0
		banner_color = Color("#fbbf24")
		banner_text = "UNIQUE DROP!" if r == GameData.UNIQUE else "LEGENDARY DROP!"
		banner_sub = e["name"]
		banner_alpha = 2.2
		_burst(pos, Color("#fbbf24"), 30, 380.0)
		_hit_stop(0.1)

func _set_dying_alpha(v: float) -> void:
	if dying.has("tex"):
		dying["alpha"] = v

func _enemy_died() -> void:
	_sfx("kill", randf_range(0.9, 1.1))
	if dying.has("tex"):
		_burst(_dying_rect().get_center(), Color(dying["color"]), 24, 300.0)
	var t := create_tween()
	t.tween_method(_set_dying_alpha, 1.0, 0.0, 0.35)
	t.tween_callback(func(): dying = {})
	t.tween_property(self, "enemy_alpha", 1.0, 0.25)

func _hero_died() -> void:
	_sfx("death")
	_pose_hero([["hit1", 0.08], ["kneel1", 0.16], ["kneel2", 0.7]])
	shake = 12.0
	banner_text = "DEFEATED"
	banner_color = Color("#f87171")
	banner_sub = "Try again"
	banner_alpha = 1.6
	var t := create_tween()
	t.tween_property(self, "hero_alpha", 0.15, 0.3)
	t.tween_property(self, "hero_alpha", 1.0, 0.5)

func _show_banner() -> void:
	_sfx("boss_intro" if state.enemy_is_boss else "floor")
	var zone := GameData.zone_for_floor(state.floor_num)
	banner_text = "FLOOR %d" % state.floor_num
	banner_color = Color("#fbbf24")
	var boss_word := "MID BOSS: " if state.enemy_boss_kind == "mid" else "BOSS: "
	if GameData.wall_mult(state.floor_num) > 1.0:
		boss_word = "THE WALL: "
	elif GameData.is_region_boss(state.floor_num):
		boss_word = "REGION BOSS: "
	banner_sub = (boss_word + state.enemy_name) if state.enemy_is_boss else "%s  -  %s" % [zone["name"], GameData.sub_name(state.floor_num)]
	banner_alpha = 1.8

## Where a new floating text goes: [position, lane]. Texts near each other take
## the next free lane, fanning out sideways (big sprites leave little room above).
func _lane_for(pos: Vector2, font_size: int, stack := false) -> Array:
	var taken := {}
	for f in floaters:
		if (f.get("base", f["pos"]) as Vector2).distance_to(pos) < 90.0 and float(f.get("t", 1.0)) < 0.9:
			taken[int(f.get("lane", 0))] = true
	var lane := 0
	while taken.has(lane) and lane < 8:
		lane += 1
	var side := -1.0 if lane % 2 == 1 else 1.0
	var base := pos + Vector2(side * 46.0 * ceilf(lane / 2.0), -lane * float(font_size) * 0.45)
	if stack:
		base = pos - Vector2(0, lane * (font_size + 3.0))  # long texts (loot names) stack in rows, upward
	base.y = maxf(base.y, 64.0)
	return [base, lane]

## "crit" (CRIT 123), "num" (123, -45, +60) or "word" (DODGE, STUNNED...).
func _float_kind(text: String) -> String:
	if text.begins_with("CRIT ") and text.substr(5).is_valid_int():
		return "crit"
	var t := text.trim_prefix("-").trim_prefix("+")
	return "num" if t.is_valid_int() else "word"

## A floating number or word. Numbers near each other stack into lanes so they
## never pile on top of each other; each one pops in, holds so you can read it,
## then drifts up and fades (see _process).
func _float(text: String, pos: Vector2, color: Color, font_size: int) -> void:
	if profile and not profile.damage_numbers and (text.is_valid_int() or text.begins_with("-") or text.begins_with("+") or text.begins_with("CRIT")):
		return
	var lp := _lane_for(pos, font_size)
	var base: Vector2 = lp[0]
	var lane: int = lp[1]
	var kind := _float_kind(text)
	var f := {"text": text, "base": base, "pos": base, "color": color, "size": font_size, "life": 1.15, "t": 0.0, "lane": lane, "kind": kind}
	if kind == "crit":
		# Crits split into a small CRIT tag over a big number, tilt and shake for a beat
		f["text"] = text.substr(5)
		f["tag"] = "CRIT"
		f["size"] = font_size + 6
		f["life"] = 1.4
		f["tilt"] = randf_range(-0.12, -0.05)
	elif kind == "num":
		# Numbers fly a little sideways in an arc, away from the middle of the fight
		f["vx"] = randf_range(10.0, 26.0) * (1.0 if base.x >= size.x * 0.5 else -1.0)
	floaters.append(f)
	if floaters.size() > 16:
		for i in floaters.size():
			if not floaters[i].get("keep", false):
				floaters.remove_at(i)
				break

# =====================================================================
# Drawing
# =====================================================================

func _process(delta: float) -> void:
	bob += delta
	shake = move_toward(shake, 0.0, delta * 40.0)
	lpc_t += delta
	if chest_t >= 0.0:
		chest_t += delta
		if chest_t > 2.2:
			chest_t = -1.0
	for bm in beams:
		bm["t"] = float(bm["t"]) + delta
	beams = beams.filter(func(bm): return float(bm["t"]) < float(bm["life"]))
	for fx in fx_sprites:
		fx["t"] = float(fx["t"]) + delta
	fx_sprites = fx_sprites.filter(func(fx): return float(fx["t"]) * FX_FPS < float(_fx_frames.get(fx["name"], 1)))
	enemy_lpc_t += delta
	if enemy_lpc_anim != "combat_idle":
		var ea: Dictionary = _enemy_art(state.enemy_is_boss).get("lpc", {}).get(enemy_lpc_anim, {}) if state != null else {}
		if ea.is_empty() or enemy_lpc_t >= float((ea["tex"] as Array).size()) / float(ea["fps"]):
			enemy_lpc_anim = "combat_idle"
			enemy_lpc_t = 0.0
	if lpc_anim != "combat_idle" and hero_art.has("lpc"):
		var la: Dictionary = hero_art["lpc"].get(lpc_anim, {})
		if la.is_empty() or lpc_t >= float((la["tex"] as Array).size()) / float(la["fps"]):
			lpc_anim = "combat_idle"
			lpc_t = 0.0
	var hs := _step_pose(hero_seq, hero_pose, hero_pose_t, delta, 0.0)
	hero_seq = hs[0]
	hero_pose = hs[1]
	hero_pose_t = hs[2]
	var es := _step_pose(enemy_seq, enemy_pose, enemy_pose_t, delta, 0.3)
	enemy_seq = es[0]
	enemy_pose = es[1]
	enemy_pose_t = es[2]
	banner_alpha = move_toward(banner_alpha, 0.0, delta * 0.9)
	for f in floaters:
		f["life"] -= delta
		f["t"] = float(f["t"]) + delta
		var ft: float = f["t"]
		# fast rise, a short hold, then a slow drift
		var rise := 26.0 * (1.0 - pow(1.0 - minf(ft / 0.22, 1.0), 3.0)) + maxf(0.0, ft - 0.5) * 34.0
		var side := float(f.get("vx", 0.0)) * minf(ft, 0.9)
		f["pos"] = (f["base"] as Vector2) - Vector2(-side, rise)
	floaters = floaters.filter(func(f): return f["life"] > 0.0)
	for p in particles:
		p["life"] -= delta
		p["vel"] += Vector2(0, 600 * delta)
		p["pos"] += p["vel"] * delta
	particles = particles.filter(func(p): return p["life"] > 0.0)
	for r in rings:
		r["life"] -= delta
	rings = rings.filter(func(r): return r["life"] > 0.0)
	for pr in projectiles:
		pr["t"] += delta / 0.16
		pr["pos"] = (pr["from"] as Vector2).lerp(pr["to"], minf(pr["t"], 1.0))
	projectiles = projectiles.filter(func(pr): return pr["t"] < 1.0)
	if toast_life > 0.0:
		toast_life -= delta
	elif not toasts.is_empty():
		toast_text = toasts.pop_front()
		toast_life = 6.0
	queue_redraw()

## Screen pixels per art pixel (whole numbers keep pixel art crisp).
## (The art is HD: 64x64 bodies, so a unit is half what it was at 32x32.)
## Pixel-perfect sizing: how many REAL screen pixels each art pixel covers.
## The window may be scaled by any amount (phones, resized windows), so the
## count is worked out in screen pixels and kept a whole number: every art
## pixel is then exactly the same size, with no uneven or blurred pixels.
func _unit() -> int:
	var sc := _scr()
	var by_h := (_ground() - 34.0) * sc / (32.0 * Sprites.HD)
	var by_w := size.x * 0.4 * sc / (32.0 * Sprites.HD)
	return clampi(floori(minf(by_h, by_w)), 1, 12)

## Screen pixels per design pixel (the window's stretch factor).
func _scr() -> float:
	var sc := get_global_transform_with_canvas().get_scale().x
	return sc if sc > 0.01 else 1.0

## One art pixel, in this control's (design) units.
func _u() -> float:
	return float(_unit()) / _scr()

func _hu() -> float:
	return float(_hero_unit()) / _scr()

## Snaps a position to the real screen pixel grid.
func _snap(v: Vector2) -> Vector2:
	var sc := _scr()
	return (v * sc).round() / sc

## Screen pixels per old 32x32-grid pixel (for distances that shouldn't change with HD).
func _px() -> float:
	return _u() * Sprites.HD

## Where the monsters stand (the back of the scene). 0.13: fights are back to front.
func _ground() -> float:
	return size.y * 0.58

## Where your team stands (the front, close to you, seen from behind).
func _team_ground() -> float:
	return size.y * 0.9

func _sprite_size(boss: bool) -> float:
	return 32.0 * _px() * (1.5 if boss else 1.0)

## The hero's whole 48x48 picture; the feet sit on the ground line.
func _hero_canvas() -> Rect2:
	var u := _hu()
	var s := Sprites.CANVAS * u
	var x := size.x * _leader_x() - s / 2.0
	var y := _team_ground() - (Sprites.HERO_FOOT + 1) * u + roundf(sin(bob * 3.0)) * u - hero_lunge * size.y * 0.14 + recoil * u * 4.0 * Sprites.HD
	return Rect2(_snap(Vector2(x, y)), Vector2(s, s))

## With companions around, everyone is drawn a size smaller so the group fits.
func _hero_unit() -> int:
	var un := maxi(1, _unit() - (1 if _party_members().size() > 0 and _unit() > 2 else 0))
	# LPC heroes are drawn smaller (about 48 of 64 pixels tall): one size up
	# keeps them as big as the monsters while staying on whole pixels
	if hero_art.has("lpc"):
		un = maxi(un, roundi(un * 4.0 / 3.0))
	# Your leader is closest to you (back-to-front): a size bigger than everyone else
	return un + 1

func _party_members() -> Array:
	return state.party.members if state != null and state.party != null else []

## With a party the leader stands a little further forward.
func _leader_x() -> float:
	return 0.5

## Companions stand behind the leader, a size smaller (they're further back).
func _member_canvas(i: int) -> Rect2:
	var u := float(maxi(1, _unit() - 1)) / _scr()
	var s := Sprites.CANVAS * u
	var fx: Dictionary = party_fx.get(i, {})
	var x := size.x * (0.19 if i % 2 == 0 else 0.81) - s / 2.0
	var y := _team_ground() - size.y * (0.05 + 0.03 * floorf(i / 2.0)) - (Sprites.HERO_FOOT + 1) * u + roundf(sin(bob * 3.0 + i + 1.0)) * u - float(fx.get("lunge", 0.0)) * size.y * 0.1
	return Rect2(x, y, s, s)

func _member_center(slot: int) -> Vector2:
	var members := _party_members()
	for i in members.size():
		if members[i].slot == slot:
			var c := _member_canvas(i)
			return c.position + Vector2(24, 26) * Sprites.HD * (c.size.x / Sprites.CANVAS)
	return _hero_center()

func _member_index(slot: int) -> int:
	var members := _party_members()
	for i in members.size():
		if members[i].slot == slot:
			return i
	return -1

func _draw_members() -> void:
	var members := _party_members()
	for i in range(members.size() - 1, -1, -1):
		var m = members[i]
		var g: GameState = m.hero
		var art := Sprites.hero_back(g.appearance, g.hero_looks())
		var c := _member_canvas(i)
		var u := c.size.x / Sprites.CANVAS
		var a := 0.35 if m.knocked_out else 1.0
		var body_r := Rect2(c.position + Vector2(8, 12) * Sprites.HD * u, Vector2(32, 32) * Sprites.HD * u)
		draw_ellipse_shadow(body_r)
		var fx0: Dictionary = party_fx.get(i, {})
		if art.has("lpc"):
			# Seen from behind, like the leader: a real LPC frame (kneeling = faded)
			var anims: Dictionary = art["lpc"]
			var striking := float(fx0.get("lunge", 0.0)) > 0.3
			var an: Dictionary = anims.get("slash" if striking and anims.has("slash") else "combat_idle", {})
			if not an.is_empty():
				var n: int = (an["tex"] as Array).size()
				var fi := (int(bob * float(an["fps"]) + i * 3) % n) if not striking else mini(n - 1, int((1.0 - float(fx0.get("lunge", 0.0))) * n))
				var sz: int = an["size"]
				var off := Vector2(Sprites.BODY_OFFSET) - Vector2((sz - Lpc.CORE) / 2, (sz - Lpc.CORE) / 2)
				var r := Rect2(c.position + off * u, Vector2(sz, sz) * u)
				draw_texture_rect(an["white"][fi], Rect2(r.position + Vector2(0, -u), r.size), false, Color(_rim_color(), 0.42 * a))
				draw_texture_rect(an["tex"][fi], r, false, Color(1, 1, 1, a))
				if float(fx0.get("flash", 0.0)) > 0.0:
					draw_texture_rect(an["white"][fi], r, false, Color(1.0, 0.2, 0.2, float(fx0["flash"]) * 0.75))
			_member_plate(m, g, c, u)
			continue
		var poses := Sprites.poses_for("m" + str((str(g.appearance) + str(g.hero_looks())).hash()), art["body_img"], 1, int(art["hand"].y))
		var fx: Dictionary = party_fx.get(i, {})
		var pose_name := "kneel2" if m.knocked_out else ("strike" if float(fx.get("lunge", 0.0)) > 0.3 else ("idle1" if fmod(bob + i * 0.2, 0.9) > 0.45 else "idle0"))
		var pose: Dictionary = poses[pose_name]
		draw_texture_rect(pose["tex"], c, false, Color(1, 1, 1, a))
		if float(fx.get("flash", 0.0)) > 0.0:
			draw_texture_rect(pose["white"], c, false, Color(1.0, 0.2, 0.2, float(fx["flash"]) * 0.75))
		if art["weapon"] != null and not m.knocked_out:
			var hand: Vector2 = c.position + ((art["hand"] as Vector2) + Vector2(int(pose["dx"]), int(pose["dy"]))) * u
			var ang := deg_to_rad(MELEE_REST - 40.0 * float(fx.get("lunge", 0.0)) if not art["weapon_type"] in ["bow", "staff"] else 12.0)
			draw_set_transform(_off + hand, ang, Vector2(u, u))
			draw_texture(art["weapon"], -(art["pivot"] as Vector2), Color(1, 1, 1, a))
			draw_set_transform(_off)
		_member_plate(m, g, c, u)

## A companion's small health bar and name over their head.
func _member_plate(m, g: GameState, c: Rect2, u: float) -> void:
	if true:
		var bw := 32.0 * Sprites.HD * u
		var bx := c.position.x + 8.0 * Sprites.HD * u
		var by := c.position.y + 8.0 * Sprites.HD * u
		draw_rect(Rect2(bx, by, bw, 5), Color(0.03, 0.03, 0.05, 0.85))
		draw_rect(Rect2(bx + 1, by + 1, (bw - 2) * clampf(float(m.hp) / maxf(1.0, m.max_hp()), 0.0, 1.0), 3), Color("#22c55e") if not m.knocked_out else Color("#64748b"))
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(bx - 20, by - 3), m.name, HORIZONTAL_ALIGNMENT_CENTER, bw + 40, 11, 3, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(bx - 20, by - 3), m.name, HORIZONTAL_ALIGNMENT_CENTER, bw + 40, 11, Color(g.class_info().get("color", "#ffffff")).lightened(0.4))

## The visible body part of the hero (for bars, effects and centering).
func _hero_rect() -> Rect2:
	var c := _hero_canvas()
	var u := _hu()
	return Rect2(c.position + Vector2(8, 12) * Sprites.HD * u, Vector2(32, 32) * Sprites.HD * u)

func _hand_screen() -> Vector2:
	var c := _hero_canvas()
	var p: Dictionary = _hero_poses().get(hero_pose, {})
	var off := Vector2(int(p.get("dx", 0)), int(p.get("dy", 0)))
	return c.position + ((hero_art.get("hand", Vector2(32, 31) * Sprites.HD) as Vector2) + off) * _hu()

func _hero_poses() -> Dictionary:
	if hero_art.is_empty() or not hero_art.has("body_img"):
		return {}
	var hand: Vector2 = hero_art.get("hand", Vector2(32, 31) * Sprites.HD)
	return Sprites.poses_for("h" + str(hero_art_key.hash()), hero_art["body_img"], 1, int(hand.y))

func _enemy_poses(art: Dictionary) -> Dictionary:
	if art.is_empty():
		return {}
	var key := state.enemy_art if state.enemy_art != "" else str(state.enemy_name.hash())
	return Sprites.poses_for("e" + key, (art["tex"] as Texture2D).get_image(), -1)

func _enemy_art(boss: bool, enemy_name := "") -> Dictionary:
	if enemy_name == "" and state.enemy_art != "":
		var a := Sprites.enemy_by_key(state.enemy_art)
		if not a.is_empty():
			return a
	return Sprites.enemy(enemy_name if enemy_name != "" else state.enemy_name, boss)

func _dying_rect() -> Rect2:
	return _rect_for(Sprites.enemy_by_key(dying.get("art", "")), dying["boss"], float(dying.get("scale", 1.0)))

func _enemy_rect(boss: bool, enemy_name := "") -> Rect2:
	return _rect_for(_enemy_art(boss, enemy_name), boss, state.enemy_scale())

## Rarer monsters are drawn bigger (by whole art pixels so they stay crisp).
func _rect_for(art: Dictionary, boss: bool, scale_mult: float) -> Rect2:
	var sc := _scr()
	var ui := float(_unit())
	if scale_mult > 1.0:
		# Whole screen pixels only, so the sprite stays crisp; Legendary and up are always a size bigger
		ui = maxf(ui + (1.0 if scale_mult >= 1.28 else 0.0), roundf(ui * scale_mult))
	var u := ui / sc
	var x := size.x * 0.5
	var gy := _ground() + enemy_lunge * size.y * 0.16 - enemy_recoil * u * 3.0 * Sprites.HD
	if art.is_empty():
		var s := _sprite_size(boss)
		return Rect2(x - s / 2.0, gy - s + sin(bob * 2.4 + 1.0) * 2.0, s, s)
	# LPC monsters are drawn smaller (about 48 of 64 pixels): one size up, on whole pixels
	if art.has("lpc"):
		ui = maxf(ui, roundf(ui * (2.0 if art.get("lpc_boss", false) else 4.0 / 3.0)))
	# Big bosses never take more than ~45% of the width
	# (LPC frames are padded for big weapon swings, so measure the ~48-pixel body instead)
	var span: float = Lpc.CORE * 0.75 if art.has("lpc") else (art["size"] as Vector2).x
	ui = maxf(1.0, minf(ui, floorf(size.x * 0.56 * sc / maxf(1.0, span))))
	# ...and never taller than the space above the team
	ui = maxf(1.0, minf(ui, floorf(_ground() * 0.92 * sc / maxf(1.0, float(art["foot"]) + 1.0))))
	u = ui / sc
	var sz: Vector2 = art["size"] * u
	var foot: float = art["foot"]
	return Rect2(_snap(Vector2(x - sz.x / 2.0, gy - (foot + 1.0) * u)), sz)

func _hero_center() -> Vector2:
	var r := _hero_rect()
	return Vector2(r.get_center().x, r.position.y + r.size.y * 0.35)

func _enemy_center() -> Vector2:
	var r := _enemy_rect(state.enemy_is_boss)
	return Vector2(r.get_center().x, r.position.y + r.size.y * 0.35)

func _draw() -> void:
	if state == null:
		return
	var w := size.x
	var h := size.y
	var zone := GameData.zone_for_floor(state.floor_num)
	var tint := Color(zone["color"])
	var font := ThemeDB.fallback_font

	# Background (0.13): the room you walked into, first-person (HallsScene), same as between fights
	if state.in_town or state.trial_active:
		_draw_old_bg(w, h)
	else:
		halls.t = Time.get_ticks_msec() / 1000.0
		halls.build(state, size)
		halls.draw_shell(self, size)
		halls.draw_doors(self, null, {}, font)
		var things: Array = halls.scenery()
		things.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
		for th in things:
			halls.draw_scenery(self, th)
		halls.vignette(self, size)
		_draw_mood(w, h, _ground())
	draw_string(font, Vector2(14, 24), "%s  -  %s  -  Floor %d" % [zone["name"], GameData.sub_name(state.floor_num), state.floor_num], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.55))
	_draw_status(font)

	var sh := shake if (profile == null or profile.shake) else 0.0
	_off = Vector2(randf_range(-sh, sh), randf_range(-sh, sh))
	draw_set_transform(_off)

	var hr := _hero_rect()

	# Dying enemy fading out
	if dying.has("tex"):
		var dr := _dying_rect()
		dr.position.y += (1.0 - float(dying["alpha"])) * 20.0
		draw_texture_rect(dying["tex"], dr, false, Color(1, 1, 1, dying["alpha"]))

	# A pack (horde): the ones still waiting stand behind, either side
	if state.horde_left > 1 and enemy_alpha > 0.0 and not state.enemy_is_boss:
		var pr := _enemy_rect(false)
		var part := _enemy_art(false)
		if part.has("tex"):
			for k in mini(2, state.horde_left - 1):
				var side := -1.0 if k == 0 else 1.0
				var rr := Rect2(pr.position + Vector2(side * pr.size.x * 0.62, -pr.size.y * 0.1), pr.size * 0.78)
				rr.position.x += pr.size.x * 0.11
				draw_ellipse_shadow(rr)
				draw_texture_rect(part["tex"], rr, false, Color(0.62, 0.6, 0.66, 0.9 * enemy_alpha))
	# Current enemy
	if enemy_alpha > 0.0:
		var boss := state.enemy_is_boss
		var er := _enemy_rect(boss)
		var art := _enemy_art(boss)
		var etex: Texture2D = art.get("tex", _enemy_tex(state.enemy_shape, state.enemy_color))
		var ewhite: Texture2D = art.get("white", _enemy_tex(state.enemy_shape, state.enemy_color, true))
		if state.enemy_calamity > 0:
			# The world dims around it; a slow crimson pulse
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.0, 0.03, 0.45 * enemy_alpha))
			var cp := 0.18 + 0.1 * sin(bob * 1.6)
			for i in 3:
				draw_circle(er.get_center(), er.size.x * (0.5 + 0.12 * i), Color(0.89, 0.23, 0.27, cp * (1.0 - i * 0.3) * enemy_alpha))
		elif boss:
			var pulse := 0.10 + 0.05 * sin(bob * 3.0)
			draw_circle(er.get_center(), er.size.x * 0.55, Color(0.98, 0.75, 0.14, pulse * enemy_alpha))
		elif (state.enemy_tier > 0 and not Realms.hides_tier(state)) or state.enemy_goblin:
			_draw_aura(er, Color("#fbbf24") if state.enemy_goblin else Color(Monsters.tier_color(state.enemy_tier)), state.enemy_tier)
		draw_ellipse_shadow(er)
		# Pose frames (breathing, attacking, getting hit) are made from whole pixels
		var local := er
		if art.has("lpc"):
			# LPC monsters play real frames (bigger frames for weapon swings are centered on the body)
			var anims: Dictionary = art["lpc"]
			var an: Dictionary = anims.get(enemy_lpc_anim, anims.get("combat_idle", {}))
			if not an.is_empty():
				var n := (an["tex"] as Array).size()
				var fi := int(enemy_lpc_t * float(an["fps"]))
				fi = fi % n if enemy_lpc_anim == "combat_idle" else mini(fi, n - 1)
				etex = an["tex"][fi]
				ewhite = an["white"][fi]
				var fs := float(an["size"])
				var uu := er.size.x / (art["size"] as Vector2).x
				local = Rect2(er.position - Vector2(fs - (art["size"] as Vector2).x, fs - (art["size"] as Vector2).y) * 0.5 * uu, Vector2(fs, fs) * uu)
		else:
			var epose: Dictionary = _enemy_poses(art).get(enemy_pose, {})
			if not epose.is_empty():
				etex = epose["tex"]
				ewhite = epose["white"]
		var etint := Color(1, 1, 1, enemy_alpha)
		var rank := GameData.zone_rank(state.floor_num)
		if rank > 0:
			etint = Color(1.0 - 0.08 * rank, 0.9 - 0.1 * rank, 1.0 - 0.02 * rank, enemy_alpha)
		if state.enemy_calamity > 0:
			# A shape of darkness with a burning crimson edge
			etint = Color(0.16, 0.05, 0.12, enemy_alpha)
			var glow := Color(0.95, 0.2, 0.25, (0.55 + 0.25 * sin(bob * 2.4)) * enemy_alpha)
			for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				draw_texture_rect(ewhite, Rect2(local.position + off, local.size), false, glow)
		else:
			draw_texture_rect(ewhite, Rect2(local.position + Vector2(0, -er.size.y / maxf(1.0, (art.get("size", Vector2(64, 64)) as Vector2).y)), local.size), false, Color(_rim_color(), 0.38 * enemy_alpha))
		draw_texture_rect(etex, local, false, etint)
		if enemy_flash > 0.0:
			draw_texture_rect(ewhite, local, false, Color(1, 1, 1, enemy_flash * 0.85 * enemy_alpha))
		var name_color := Color("#fbbf24") if boss else Color("#fca5a5")
		if not boss and state.enemy_tier > 0:
			name_color = Color(Monsters.tier_color(state.enemy_tier)).lightened(0.15)
		if state.enemy_goblin:
			name_color = Color("#fde68a")
		var bar_color := Color("#d97706") if boss else Color("#ef4444")
		var label := state.enemy_name
		var veiled := Realms.hides_tier(state) and not boss
		if veiled:
			name_color = Color("#f9a8d4")
			label = "??? " + state.enemy_name
		elif state.enemy_calamity > 0:
			label = "CALAMITY: " + state.enemy_name
			name_color = Color("#ff6b6b")
		elif state.enemy_tier > 0 and not boss:
			label = "%s %s" % [Monsters.tier_name(state.enemy_tier), state.enemy_name]
		if state.enemy_goblin:
			label += "  (%d turns)" % state.goblin_turns
		if state.horde_left > 0 and not boss:
			label += "  [%s %d/%d]" % ["Pack" if state.horde_pack else "Horde", state.horde_total - state.horde_left + 1, state.horde_total]
		_draw_bar(er, label, state.enemy_hp, state.enemy_max_hp, bar_color, Color(name_color, enemy_alpha))
		if state.enemy_shield > 0:
			_draw_shield(er)
		if not state.enemy_mods.is_empty() and not veiled:
			_draw_mods(er)
		_draw_enemy_info(er, font)
	# Your team, in front (drawn after the monster)
	draw_ellipse_shadow(hr)
	if cast_glow > 0.0 and (profile == null or profile.flashes):
		var cc := Vector2(hr.get_center().x, hr.end.y) + _off
		draw_set_transform(cc, 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, hr.size.x * (0.5 + 0.2 * (1.0 - cast_glow)), 0.0, TAU, 32, Color(cast_color, cast_glow), 3.0)
		draw_arc(Vector2.ZERO, hr.size.x * (0.35 + 0.15 * (1.0 - cast_glow)), 0.0, TAU, 24, Color(cast_color, cast_glow * 0.6), 2.0)
		draw_set_transform(_off)
	_draw_members()
	_draw_pet()
	_draw_hero()
	var hero_name := "HERO" if state.hero_class == "" else "%s  Lv %d" % [state.title(), state.level]
	_draw_bar(hr, hero_name, state.hero_hp, state.get_max_hp(), Color("#22c55e"), Color("#e5e7eb"))
	# Thin XP bar under the health bar
	var xbr := _bar_rect(hr)
	var xbw := xbr.size.x
	var xbx := xbr.position.x
	var xby := xbr.end.y + 1.0
	var xp_pct := clampf(float(state.xp) / maxf(1.0, GameData.xp_to_next(state.level)), 0.0, 1.0)
	draw_rect(Rect2(xbx, xby, xbw, 5), Color(0.03, 0.03, 0.05, 0.9))
	draw_rect(Rect2(xbx + 1, xby + 1, (xbw - 2) * xp_pct, 3), Color("#e8b14a"))
	_draw_hero_status(hr, font)

	_draw_chest()
	# Loot beams: a column of light that grows in, pulses and fades
	for bm in beams:
		var bt: float = float(bm["t"]) / float(bm["life"])
		var a := minf(1.0, bt * 6.0) * (1.0 - bt)
		var bw := float(bm["w"]) * _u() * 2.0
		var bx := float(bm["x"])
		var gy2 := _ground()
		var top := gy2 - (gy2 - 20.0) * minf(1.0, bt * 4.0)
		var bc: Color = bm["color"]
		draw_rect(Rect2(_snap(Vector2(bx - bw * 1.5, top)), Vector2(bw * 3.0, gy2 - top)), Color(bc, 0.16 * a))
		draw_rect(Rect2(_snap(Vector2(bx - bw / 2.0, top)), Vector2(bw, gy2 - top)), Color(bc.lightened(0.4), 0.55 * a))
		draw_rect(Rect2(_snap(Vector2(bx - bw * 2.5, gy2 - _u() * 2.0)), Vector2(bw * 5.0, _u() * 3.0)), Color(bc.lightened(0.5), 0.7 * a))
	# Sprite effects (slashes, bursts, spells) over the fighters
	for fx in fx_sprites:
		var tex: Texture2D = _fx_tex.get(fx["name"])
		if tex == null:
			continue
		var fi := mini(int(float(fx["t"]) * FX_FPS), int(_fx_frames[fx["name"]]) - 1)
		var sz := 64.0 * _u() * float(fx["scale"])
		var dst := Rect2(_snap(fx["pos"] - Vector2(sz, sz) / 2.0), Vector2(sz, sz))
		if fx.get("flip", false):
			dst = Rect2(dst.position + Vector2(sz, 0), Vector2(-sz, sz))
		draw_texture_rect_region(tex, dst, Rect2(fi * 64, 0, 64, 64))
	# Particles and tap rings
	for p in particles:
		var pc: Color = p["color"]
		var ps: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(ps, ps) / 2.0, Vector2(ps, ps)), Color(pc, clampf(p["life"] * 2.0, 0.0, 1.0)))
	for r in rings:
		var t: float = 1.0 - r["life"] / 0.25
		draw_arc(r["pos"], 8.0 + t * 26.0, 0.0, TAU, 24, Color(0.58, 0.77, 0.99, 1.0 - t), 3.0)

	# Arrows and magic bolts
	for pr in projectiles:
		var pc: Color = pr["color"]
		var pp: Vector2 = pr["pos"]
		var dir: Vector2 = ((pr["to"] as Vector2) - (pr["from"] as Vector2)).normalized()
		var u := _px()
		if pr["kind"] == "arrow":
			draw_line(pp - dir * u * 7.0, pp, Color("#d6b88a"), maxf(2.0, u * 0.8))
			draw_line(pp - dir * u * 2.0, pp, pc, maxf(2.0, u))
		else:
			var r := u * (3.5 if pr["big"] else 2.2)
			draw_circle(pp, r * 1.8, Color(pc, 0.25))
			draw_circle(pp, r, pc)
			draw_circle(pp, r * 0.5, Color.WHITE)

	# Damage numbers: flash white, pop in big, settle, fade. Numbers get a bevel
	# (a darker copy just below the fill); crits tilt, shake and carry a CRIT tag.
	for f in floaters:
		var a := clampf(f["life"] * 2.2, 0.0, 1.0)
		var c: Color = f["color"]
		var ft := float(f["t"])
		var kind := String(f.get("kind", "word"))
		var crit := kind == "crit"
		var pop := 1.0 + (0.7 if crit else 0.45 if kind == "num" else 0.25) * maxf(0.0, 1.0 - ft / (0.16 if crit else 0.12))
		var fs := int(float(f["size"]) * pop)
		var flash := clampf(1.0 - ft / 0.09, 0.0, 1.0) if kind != "word" else 0.0
		var fill := c.lerp(Color.WHITE, flash)
		var ctr: Vector2 = (f["pos"] as Vector2).round()
		if crit and ft < 0.22:
			ctr += Vector2(randf_range(-2.0, 2.0), randf_range(-1.5, 1.5)).round()
		var tilt := float(f.get("tilt", 0.0)) * clampf(ft / 0.1, 0.0, 1.0)
		draw_set_transform(ctr + _off, tilt)
		var p := Vector2(-200, 0)
		draw_string_outline(font, p + Vector2(0, 2), f["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, fs, 7 if crit else 6, Color(0, 0, 0, a * 0.6))
		draw_string_outline(font, p, f["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, fs, 6 if crit else 5, Color(0.04, 0.03, 0.06, a))
		if kind != "word":
			draw_string(font, p + Vector2(0, maxf(1.0, fs / 14.0)), f["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, fs, Color(c.darkened(0.45), a))
		draw_string(font, p, f["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, fs, Color(fill, a))
		if crit:
			var ts := maxi(11, int(fs * 0.5))
			var tp := Vector2(-200, -fs * 0.82)
			draw_string_outline(font, tp, String(f["tag"]), HORIZONTAL_ALIGNMENT_CENTER, 400, ts, 4, Color(0.04, 0.03, 0.06, a))
			draw_string(font, tp, String(f["tag"]), HORIZONTAL_ALIGNMENT_CENTER, 400, ts, Color(Color("#fff1c2"), a))
	draw_set_transform(_off)

	draw_set_transform(Vector2.ZERO)

	# Floor / defeat banner
	if banner_alpha > 0.0:
		var a := clampf(banner_alpha, 0.0, 1.0)
		# A slim band that slides in under the title line
		var slide := (1.0 - clampf((1.8 - banner_alpha) / 0.2, 0.0, 1.0)) * 40.0
		# Just the words, heavily outlined: a band would hide the fighters' heads
		var big_color := banner_color
		draw_string_outline(font, Vector2(slide, 62), banner_text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, 6, Color(0, 0, 0, a))
		draw_string(font, Vector2(slide, 62), banner_text, HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color(big_color, a))
		draw_string(font, Vector2(-slide, 79), banner_sub, HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(1, 1, 1, 0.85 * a))

	# Tip toast at the top
	if toast_life > 0.0:
		# A slim strip along the bottom edge: never over the fighters or their plates
		var ta := clampf(minf(toast_life, 6.0 - toast_life) * 4.0, 0.0, 1.0)
		var tw := w - 16.0
		var lines := minf(font.get_multiline_string_size(toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw - 24, 12).y, 32.0)
		var box := Rect2(8, h - lines - 14.0, tw, lines + 10.0)
		draw_rect(box, Color(0.04, 0.05, 0.10, 0.92 * ta))
		draw_rect(Rect2(box.position, Vector2(3, box.size.y)), Color(0.91, 0.69, 0.29, ta))
		draw_multiline_string(font, Vector2(box.position.x + 12, box.position.y + 5 + 11), toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw - 24, 12, 2, Color(1, 1, 1, ta))

## Draws the hero picture and the weapon (rotated around the hand for swings).
func _draw_hero() -> void:
	var c := _hero_canvas()
	var u := _hu()
	var a := hero_alpha
	if state.leader_down:
		# Fallen: kneeling and faded while the team fights on
		a *= 0.4
		if hero_seq.is_empty():
			hero_pose = "kneel2"
	if hero_art.is_empty():
		draw_texture_rect(hero_tex, _hero_rect(), false, Color(1, 1, 1, a))
		return
	var wt := _weapon_type()
	var angle := 0.0
	match wt:
		"bow":
			angle = deg_to_rad(swing * 12.0)
		"staff":
			angle = deg_to_rad(12.0 + swing * 40.0)
		_:
			angle = deg_to_rad(MELEE_REST + swing * 75.0)
	# Awakened heroes glow in their race's color; hidden classes add a tier ring
	if state.awaken > 0:
		var ac := Color(Races.power_info(state.race())["color"])
		var hr := _hero_rect()
		var pulse := 0.5 + 0.5 * sin(bob * 2.0)
		for i in 3:
			draw_circle(hr.get_center() + Vector2(0, hr.size.y * 0.1), hr.size.x * (0.36 + 0.08 * i + 0.02 * pulse),
				Color(ac, (0.035 + 0.012 * state.awaken) * (1.0 - i * 0.3) * a))
	if state.hidden_class != "":
		var tc := Color(Hidden.TIER_COLORS[int(Hidden.info(state.hidden_class)["tier"])])
		var hr2 := _hero_rect()
		draw_arc(Vector2(hr2.get_center().x, hr2.end.y - hr2.size.y * 0.04), hr2.size.x * 0.32, 0.0, TAU, 28, Color(tc, 0.35 * a), 2.0)
	# Unique classes glow by rank (a God rank class burns gold); the Wanderer's
	# roads keep their blade aura (Sword) or red demonic qi (Demon)
	var fists := false
	var uc := ClassTree.unique_class(state)
	if not uc.is_empty():
		var ri := ClassTree.RANK_ORDER.find(ClassTree.rank_of(uc))
		_draw_road_aura(_hero_rect(), Color(ClassTree.RANK_COLORS[ClassTree.rank_of(uc)]), 0.6 + ri * 0.55)
		if state.hero_looks().has("Aura"):
			_draw_god_aura(_hero_rect(), Color(ClassTree.RANK_COLORS["God"]), a)
	elif state.hero_class == "Wanderer" and not state.class_path.is_empty():
		var demon := state.class_path[0] == "demonic_disciple"
		_draw_road_aura(_hero_rect(), Color("#e43b44") if demon else Color("#7fe9ff"), float(state.class_path.size()))
	fists = state.hero_class == "Wanderer" and not state.class_path.is_empty() and state.class_path[0] == "demonic_disciple" and (state.equipped.get("Weapon", {}) as Dictionary).is_empty()
	# Weapon glow (Legendary, Unique) sits behind everything
	var glow: Color = hero_art.get("glow", Color(0, 0, 0, 0))
	var hand := _hand_screen()
	if glow.a > 0.0 and hero_art["weapon"] != null:
		var pulse := 0.25 + 0.12 * sin(bob * 4.0)
		draw_set_transform(_off + hand, angle, Vector2(u, u))
		var wtex: Texture2D = hero_art["weapon"]
		var piv: Vector2 = hero_art["pivot"]
		draw_texture_rect(hero_art["weapon_white"], Rect2(-piv - Vector2(2, 2), wtex.get_size() + Vector2(4, 4)), false, Color(glow, pulse))
		draw_set_transform(_off)
	if hero_art.has("lpc"):
		_draw_lpc_hero(c, u, a, glow)
		return
	var poses := _hero_poses()
	var pose: Dictionary = poses.get(hero_pose, {})
	# Rim light: the zone's light catches the top edge of the silhouette
	draw_texture_rect(pose.get("white", hero_art["body_white"]), Rect2(c.position + Vector2(0, -u), c.size), false, Color(_rim_color(), 0.42 * a))
	draw_texture_rect(pose.get("tex", hero_art["body"]), c, false, Color(1, 1, 1, a))
	if hero_flash > 0.0:
		draw_texture_rect(pose.get("white", hero_art["body_white"]), c, false, Color(1.0, 0.2, 0.2, hero_flash * 0.75))
	if fists:
		# The demon road fights barehanded: a burst of red qi around the fist
		var pulse := 0.5 + 0.5 * sin(bob * 6.0)
		draw_circle(hand + _off, u * Sprites.HD * (2.0 + pulse), Color(0.89, 0.23, 0.27, 0.45 * a))
		draw_circle(hand + _off, u * Sprites.HD * 1.2, Color(1.0, 0.6, 0.5, 0.8 * a))
	elif hero_art["weapon"] != null:
		var wtex: Texture2D = hero_art["weapon"]
		var piv: Vector2 = hero_art["pivot"]
		draw_set_transform(_off + hand, angle, Vector2(u, u))
		draw_texture(wtex, -piv, Color(1, 1, 1, a))
		if hero_flash > 0.0:
			draw_texture(hero_art["weapon_white"], -piv, Color(1.0, 0.2, 0.2, hero_flash * 0.75))
		draw_set_transform(_off)

## The companion stands behind the hero (art/pets, tools/art_pets.py), a size smaller.
func _draw_pet() -> void:
	if state == null or not state.pet_on or World.pet_stage(state) < 0:
		return
	var tex := Pets.portrait(state)
	if tex == null:
		return
	var pu := float(maxi(1, _unit() - 1)) / _scr()
	var s := 64.0 * pu
	var hc := _hero_canvas()
	var x := hc.position.x + hc.size.x * 0.62
	var y := _team_ground() - 70.0 * pu + roundf(sin(bob * 3.4 + 1.3)) * pu - pet_lunge * size.y * 0.1
	draw_texture_rect(tex, Rect2(_snap(Vector2(x, y)), Vector2(s, s)), false, Color(1, 1, 1, hero_alpha))

## An LPC hero: the current animation frame, with rim light, weapon glow and hit flash.
func _draw_lpc_hero(c: Rect2, u: float, a: float, glow: Color) -> void:
	var anims: Dictionary = hero_art["lpc"]
	var an: Dictionary = anims.get(lpc_anim, anims.get("combat_idle", {}))
	if an.is_empty():
		return
	var tex: Array = an["tex"]
	var n := tex.size()
	var fi := int(lpc_t * float(an["fps"]))
	fi = fi % n if lpc_anim == "combat_idle" else mini(fi, n - 1)
	var s: int = an["size"]
	var off := Vector2(Sprites.BODY_OFFSET) - Vector2((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2)
	var r := Rect2(c.position + off * u, Vector2(s, s) * u)
	var white: Texture2D = an["white"][fi]
	if glow.a > 0.0:
		var pulse := 0.22 + 0.1 * sin(bob * 4.0)
		for d in [Vector2(-u, 0), Vector2(u, 0), Vector2(0, -u), Vector2(0, u)]:
			draw_texture_rect(white, Rect2(r.position + d, r.size), false, Color(glow, pulse * a))
	draw_texture_rect(white, Rect2(r.position + Vector2(0, -u), r.size), false, Color(_rim_color(), 0.42 * a))
	draw_texture_rect(tex[fi], r, false, Color(1, 1, 1, a))
	if hero_flash > 0.0:
		draw_texture_rect(white, r, false, Color(1.0, 0.2, 0.2, hero_flash * 0.75))

## God rank: a slow ring of golden motes circling the hero and a soft halo.
func _draw_god_aura(r: Rect2, c: Color, a: float) -> void:
	var u := _u()
	var ctr := r.get_center() + _off
	var rx := r.size.x * 0.48
	var ry := r.size.y * 0.16
	for i in 14:
		var ang := bob * 0.9 + i * TAU / 14.0
		var p := ctr + Vector2(cos(ang) * rx, sin(ang) * ry + r.size.y * 0.1)
		var front := sin(ang) > 0.0
		var sz := u * (2.0 if front else 1.0)
		draw_rect(Rect2(_snap(p), Vector2(sz, sz)), Color(c.lightened(0.3 if front else 0.0), (0.85 if front else 0.4) * a))
	draw_arc(ctr + Vector2(0, -r.size.y * 0.44), r.size.x * 0.16, 0.0, TAU, 24, Color(c, (0.55 + 0.2 * sin(bob * 2.0)) * a), maxf(2.0, u))

## The Wanderer's aura: rising streaks of light (sword) or flame (demon).
func _draw_road_aura(r: Rect2, c: Color, strength: float) -> void:
	var u := _u()
	var n := int(4 + strength * 4)
	for i in n:
		var ph := fmod(bob * (0.5 + 0.15 * strength) + i * 0.29, 1.0)
		var x := r.position.x + r.size.x * (0.15 + 0.7 * fmod(i * 0.618, 1.0))
		var y := r.end.y - ph * r.size.y * (0.8 + 0.2 * strength)
		var sz := u * (1.0 if strength < 3.0 else 1.5)
		draw_rect(Rect2(roundf(x / u) * u + _off.x, roundf(y / u) * u + _off.y, sz, sz * 2.0), Color(c, (1.0 - ph) * 0.35 * strength / 2.0))
	if strength >= 3.0:
		draw_circle(r.get_center() + _off, r.size.x * 0.6, Color(c, 0.08 + 0.04 * sin(bob * 3.0)))

## A pulsing glow behind rare monsters, stronger for higher tiers.
func _draw_aura(r: Rect2, c: Color, tier: int) -> void:
	var pulse := 0.5 + 0.5 * sin(bob * (2.5 + tier * 0.4))
	var base := r.get_center() + Vector2(0, r.size.y * 0.08)
	for i in 3:
		var rad := r.size.x * (0.42 + 0.1 * i + 0.03 * pulse)
		draw_circle(base, rad, Color(c, (0.05 + 0.025 * tier) * (1.0 - i * 0.3) * enemy_alpha))
	# Rising sparks for Epic and up
	if tier >= Monsters.EPIC:
		for i in 4 + tier * 2:
			var ph := fmod(bob * 0.6 + i * 0.37, 1.0)
			var x := r.position.x + r.size.x * fmod(i * 0.618, 1.0)
			var y := r.end.y - ph * r.size.y * 1.1
			draw_rect(Rect2(x, y, 3, 3), Color(c, (1.0 - ph) * 0.8 * enemy_alpha))

## The blue shield bar on top of a Shielded monster's health.
func _draw_shield(r: Rect2) -> void:
	var b := _bar_rect(r)
	var pct := clampf(float(state.enemy_shield) / maxf(1.0, state.enemy_max_hp * 0.25), 0.0, 1.0)
	draw_rect(Rect2(b.position.x, b.position.y - 5.0, b.size.x * pct, 4), Color("#60a5fa"))

## Modifier names under the monster's feet.
func _draw_mods(r: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var x := r.get_center().x
	var y := _ground() - 6.0
	var total := 0.0
	var widths: Array = []
	for m in state.enemy_mods:
		var wdt := font.get_string_size(str(m), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		widths.append(wdt)
		total += wdt + 4.0
	var cx := clampf(x - total / 2.0, 4.0, size.x - total - 4.0)
	for i in state.enemy_mods.size():
		var m: String = state.enemy_mods[i]
		var c := Color(Monsters.MODS[m]["color"])
		var box := Rect2(cx, y - 13.0, widths[i], 17.0)
		draw_rect(box, Color(0.03, 0.04, 0.08, 0.85 * enemy_alpha))
		draw_rect(box, Color(c, 0.8 * enemy_alpha), false, 1.0)
		draw_string(font, Vector2(cx + 6.0, y), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(c, enemy_alpha))
		cx += widths[i] + 4.0

## Small status chips: shrine curse, scroll of luck, hunter's scroll.
func _draw_status(font: Font) -> void:
	var chips: Array = []
	if state.curse_turns > 0:
		chips.append(["Cursed %d" % state.curse_turns, Color("#c084fc")])
	if state.luck_turns > 0:
		chips.append(["Luck %d" % state.luck_turns, Color("#4ade80")])
	if state.hunt_spawns > 0:
		chips.append(["Hunting %d" % state.hunt_spawns, Color("#fb923c")])
	var x := 14.0
	for c in chips:
		var wdt := font.get_string_size(c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		draw_rect(Rect2(x, 32, wdt, 18), Color(0.03, 0.04, 0.08, 0.8))
		draw_rect(Rect2(x, 32, wdt, 18), c[1], false, 1.0)
		draw_string(font, Vector2(x + 6, 46), c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c[1])
		x += wdt + 6.0

## The light color of the current zone (for rim lights).
## Mood: slow light shafts from above and two layers of drifting ground fog,
## in the zone's light. Pixel-sized blocks so it matches the art.
static var _fog_tex: ImageTexture
func _draw_mood(w: float, h: float, gy: float) -> void:
	var lc := _rim_color()
	# Light shafts
	for i in 3:
		var sway := sin(bob * 0.25 + i * 2.1) * w * 0.03
		var x0 := w * (0.18 + 0.3 * i) + sway
		var top := 0.0
		var pts := PackedVector2Array([Vector2(x0, top), Vector2(x0 + w * 0.07, top), Vector2(x0 + w * 0.17, gy), Vector2(x0 + w * 0.06, gy)])
		draw_colored_polygon(pts, Color(lc, 0.06 + 0.02 * sin(bob * 0.6 + i)))
	# Fog
	if _fog_tex == null:
		var n := FastNoiseLite.new()
		n.seed = 7
		n.frequency = 0.06
		var img := Image.create(96, 12, false, Image.FORMAT_RGBA8)
		for y in 12:
			for x in 96:
				# tileable in x: blend the noise with its wrapped copy
				var t := float(x) / 96.0
				var v := lerpf(n.get_noise_2d(x, y * 2.0), n.get_noise_2d(x - 96, y * 2.0), t) * 0.5 + 0.5
				var fall := 1.0 - absf(float(y) - 6.0) / 6.0
				var al := snappedf(clampf(v * fall * 1.4 - 0.25, 0.0, 1.0), 0.25)
				img.set_pixel(x, y, Color(1, 1, 1, al))
		_fog_tex = ImageTexture.create_from_image(img)
	var u := _u()
	var fw := 96.0 * u * 4.0
	var fh := 12.0 * u * 4.0
	var fog_c := Color(lc.lerp(Color("#8a93a8"), 0.5), 0.3)
	for layer in 2:
		var speed := 6.0 + layer * 5.0
		var off := fmod(bob * speed * u, fw)
		var y := gy - fh * (0.75 - layer * 0.3)
		var x := -off
		while x < w:
			draw_texture_rect(_fog_tex, Rect2(_snap(Vector2(x, y)), Vector2(fw, fh)), false, Color(fog_c, fog_c.a * (1.0 - layer * 0.35)))
			x += fw

func _rim_color() -> Color:
	var zc := Color(GameData.zone_for_floor(state.floor_num)["color"])
	return zc.lerp(Color("#fff4d6"), 0.55)

func draw_ellipse_shadow(r: Rect2) -> void:
	var c := Vector2(r.get_center().x, (_ground() + 2.0) if r.get_center().y < size.y * 0.62 else r.end.y)
	draw_set_transform(c + _off, 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, r.size.x * 0.38, Color(0, 0, 0, 0.35))
	draw_set_transform(_off)

## The fighter's plate under its feet: health bar, then the name. Keeping it
## below the ground line means it never covers the art, banners or numbers.
func _bar_rect(r: Rect2) -> Rect2:
	var bw := clampf(r.size.x * 0.85, 130.0, size.x * 0.4)
	var bx := clampf(r.get_center().x - bw / 2.0, 6.0, size.x - bw - 6.0)
	# Monsters (at the back) get theirs under their feet; your team (in front) above their heads
	if r.get_center().y > size.y * 0.62:
		return Rect2(bx, minf(r.end.y + 8.0, size.y - 34.0), bw, 12.0)
	return Rect2(bx, _ground() + 9.0, bw, 12.0)

func _draw_bar(r: Rect2, label: String, value: int, max_value: int, fill: Color, label_color: Color) -> void:
	var font := ThemeDB.fallback_font
	var b := _bar_rect(r)
	var a := label_color.a
	var pct := clampf(float(value) / maxf(1.0, max_value), 0.0, 1.0)
	# frame, track, fill with a lighter top line, then a recent-damage ghost
	draw_rect(b.grow(1.0), Color(0.0, 0.0, 0.0, 0.85 * a))
	draw_rect(b, Color(0.08, 0.09, 0.14, 0.95 * a))
	var fw := (b.size.x) * pct
	draw_rect(Rect2(b.position, Vector2(fw, b.size.y)), Color(fill.darkened(0.15), a))
	draw_rect(Rect2(b.position, Vector2(fw, 3.0)), Color(fill.lightened(0.35), a))
	draw_string_outline(font, Vector2(b.position.x, b.end.y - 2.0), "%s / %s" % [_short(maxi(value, 0)), _short(max_value)], HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 10, 3, Color(0, 0, 0, a))
	draw_string(font, Vector2(b.position.x, b.end.y - 2.0), "%s / %s" % [_short(maxi(value, 0)), _short(max_value)], HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 10, Color(1, 1, 1, a))
	var ny := b.end.y + 15.0
	draw_string_outline(font, Vector2(b.position.x - 60, ny), label, HORIZONTAL_ALIGNMENT_CENTER, b.size.x + 120, 13, 4, Color(0, 0, 0, a))
	draw_string(font, Vector2(b.position.x - 60, ny), label, HORIZONTAL_ALIGNMENT_CENTER, b.size.x + 120, 13, label_color)

## 1234567 -> "1.23M" so bars stay readable.
func _short(v: int) -> String:
	if v >= 10000000:
		return "%.1fM" % (v / 1000000.0)
	if v >= 1000000:
		return "%.2fM" % (v / 1000000.0)
	if v >= 100000:
		return "%dk" % int(v / 1000.0)
	return str(v)

# =====================================================================
# Making textures from the pixel art
# =====================================================================

## white = a solid white silhouette, used for hit flashes
func _enemy_tex(shape: String, color_hex: String, white := false) -> ImageTexture:
	var key := shape + color_hex + ("_w" if white else "")
	if not tex_cache.has(key):
		var art: Array = SHAPES.get(shape, SHAPES["humanoid"])
		tex_cache[key] = _make_tex(art, Color(color_hex), white)
	return tex_cache[key]

func _make_tex(art: Array, tint: Color, white := false) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in mini(art.size(), 16):
		var row: String = art[y]
		for x in mini(row.length(), 16):
			var c := _pixel_color(row[x], tint)
			if white and c.a > 0.0:
				c = Color.WHITE
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

func _pixel_color(ch: String, tint: Color) -> Color:
	match ch:
		"K":
			return Color("#0b0b10")
		"B":
			return tint
		"D":
			return tint.darkened(0.35)
		"L":
			return tint.lightened(0.35)
		"W":
			return Color("#f5f5f5")
		"R":
			return Color("#ef4444")
		"S":
			return Color("#c0c8d4")
		"s":
			return Color("#6b7280")
		"G":
			return Color("#fbbf24")
		"H":
			return Color("#e0b08a")
		"C":
			return cape
	return Color(0, 0, 0, 0)

# =====================================================================
# v0.11: elements, statuses and boss mechanics on screen
# =====================================================================

## A row of small chips: [label, color]. Centered on x, at y (top).
func _chip_row(chips: Array, x: float, y: float, font: Font, fs := 11) -> void:
	if chips.is_empty():
		return
	var widths: Array = []
	var total := 0.0
	for c in chips:
		var wdt := font.get_string_size(String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 10.0
		widths.append(wdt)
		total += wdt + 4.0
	var cx := clampf(x - total / 2.0, 4.0, size.x - total - 4.0)
	for i in chips.size():
		var col: Color = chips[i][1]
		var box := Rect2(cx, y, widths[i], fs + 6.0)
		draw_rect(box, Color(0.03, 0.04, 0.08, 0.82))
		draw_rect(box, Color(col, 0.85), false, 1.0)
		draw_string(font, Vector2(cx + 5.0, y + fs + 1.0), String(chips[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		cx += widths[i] + 4.0

## What the monster is weak to and resists, its statuses, and its boss clock.
func _draw_enemy_info(r: Rect2, font: Font) -> void:
	var chips: Array = []
	for el in state.enemy_weak:
		chips.append(["Weak: " + String(el), Color(Combat.ELEMENT_COLORS.get(el, "#ffffff")).lightened(0.15)])
	for el in state.enemy_resist:
		chips.append(["Resists: " + String(el), Color("#94a3b8")])
	var st: Array = []
	if state.burn_turns > 0:
		st.append(["Burning", Color("#fb923c")])
	if state.enemy_poison_turns > 0:
		st.append(["Poisoned", Color("#a3e635")])
	if state.enemy_frozen > 0:
		st.append(["FROZEN", Color("#bae6fd")])
	elif state.enemy_chill > 0:
		st.append(["Chilled", Color("#7fd0f0")])
	if state.enemy_curse > 0:
		st.append(["Cursed", Color("#a78bfa")])
	if state.enemy_stun > 0:
		st.append(["Stunned", Color("#fde68a")])
	if state.boss_phase.get("windup", false):
		st.append(["WINDING UP! Use a skill", Color("#f59e0b")])
	var el := Combat.enrage_left(state)
	if el > 0:
		st.append(["Enrage in %d" % el, Color("#ef4444")])
	elif el == 0:
		st.append(["ENRAGED", Color("#ef4444")])
	if state.boss_minions > 0:
		st.append(["Minions x%d" % state.boss_minions, Color("#d4d4d4")])
	var top := maxf(34.0, r.position.y - 6.0)
	_chip_row(st, r.get_center().x, top - 20.0, font)
	_chip_row(chips, r.get_center().x, top, font, 10)

## Your statuses (poison, burns, chill) over your head.
func _draw_hero_status(r: Rect2, font: Font) -> void:
	var chips: Array = []
	for k in state.hero_status:
		var info: Dictionary = Combat.STATUS_INFO.get(k, {})
		if not info.is_empty():
			chips.append(["%s %d" % [info["name"], int(state.hero_status[k])], Color(info["color"])])
	_chip_row(chips, r.get_center().x, maxf(34.0, r.position.y - 4.0), font)
