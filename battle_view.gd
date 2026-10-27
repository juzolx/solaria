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
var toast_room := 0.0  # the tip strip's text height last frame (team plates rise above it)
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
var walk_in := 0.0   # 1 = still at the doors, 0 = in its place (the next monster stepping in)
var dying := {}  # the enemy that just died, fading out
var shake := 0.0
var freeze_left := 0.0  # hit stop: seconds the fight picture stays frozen
var bar_ghost := {}   # HP bar label -> the pale "just lost" level that drains toward the real one
var bar_target := {}
var bob := 0.0
var floaters: Array[Dictionary] = []
var banner_text := ""
var banner_sub := ""
var banner_alpha := 0.0
var intro_t := -1.0       # 0.13+: boss entrance running (seconds), -1 when none
var intro_key := ""
var intro_title := ""
var intro_name := ""
var intro_color := Color.WHITE
const INTRO_LEN := 2.4
const INTRO_REVEAL := 0.75  # when the boss bursts out of its silhouette
var banner_color := Color("#fbbf24")
var last_floor := -1
var hero_white: ImageTexture
var cape := Color("#2563eb")
var _off := Vector2.ZERO
var hero_art := {}       # from Sprites.hero()
var hero_has_aura := false  # a God class's golden aura (set with hero_art, not looked up every frame)
var hero_art_key := ""
var swing := 0.0         # weapon swing: -1 wind-up, +1 strike
var hero_anim := "combat_idle"  # the hero's animation playing (HeroArt frames)
var hero_anim_t := 0.0
var pet_lunge := 0.0
var summon_lunge := 0.0   # 0.13+: the skeleton or wolf you called steps in to hit
var summon_in := 0.0      # fades the summon in and out
var pet_hits := {}        # 0.13+: menagerie pet id -> seconds of its lunge left
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
var drops: Array = []   # 0.13+: loot that falls out of the monster: {"tex", "color", "r", "from", "to", "t", "life"}
var fx_sprites: Array = []   # sprite effects: {"name", "pos", "t", "scale", "flip"} (art/fx)
static var _fx_tex := {}
static var _fx_frames := {}
const FX_FPS := 26.0
var recoil := 0.0        # hero knocked back when hit
var enemy_recoil := 0.0
var hero_squash := 0.0   # A6: hit squash (see _squash)
var enemy_squash := 0.0
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
				if e.has("pet"):
					_pet_trick(e, delay)
					continue
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
				banner_color = Color("#c084fc") if e["kind"] == "shrine" else (Color(Portals.COLOR) if e["kind"] in ["rift", "trial"] else Color("#fbbf24"))
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
				# Fable pets R4: one after another, each pet hops on its own hit, its number in its rank colour
				var who := who_lunges(e, state.summon_name, state.summon_turns, state.pet_on and World.pet_stage(state) >= 0)
				var col := Color(Menagerie.TIER_COLORS[clampi(int(e["tier"]), 0, 5)]) if e.has("tier") else Color("#c4b5fd")
				_later(delay, func():
					if e.has("pet"):
						pet_hits[int(e["pet"])] = 0.3
					if who != "":
						var pt := create_tween()
						pt.tween_property(self, who, 1.0, 0.1)
						pt.tween_property(self, who, 0.0, 0.2))
				_later(delay + 0.15, func():
					_fx("claw", _enemy_center() + Vector2(-16, 12), 0.7)
					_float("%d" % e["dmg"], _enemy_center() + Vector2(-20, 20), col, 15)
					_burst(_enemy_center() + Vector2(-20, 10), col, 6, 160.0))
				delay += 0.12
			"pet_gold":
				_later(delay, func():
					var gh := _pet_head(int(e["pet"]))
					if gh != Vector2.INF:   # gone home before this played: the log line names it
						_sfx("loot")
						_float("+%d" % int(e["amount"]), gh, UI.GOLD, 15))
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
				var dimg: Image = null
				# its own flags (fable r4: Calamity.on_slain clears the state's before the view sees this)
				var dcal := bool(e.get("calamity", false))
				var dbig := bool(e["boss"]) or dcal or _is_tall(dart)
				if not dart.is_empty():
					# the boss stage's monsters reel back instead of kneeling (their top third sank before the burn)
					var dpose := "hit1" if dbig else "kneel2"
					var dp: Dictionary = Sprites.poses_for("e" + str(e.get("art", "")), dart["img"], -1)[dpose]
					dtex = dp["tex"]
					dimg = dp["img"]
				# the burn edge: the zone's light for commons, the monster's own colour for bosses
				var edge: String = "e43b44" if dcal else (e["color"] if bool(e["boss"]) else _rim_color().to_html(false))
				dying = {"tex": dtex, "img": dimg, "edge": edge, "boss": e["boss"], "alpha": 1.0, "color": e["color"],
					"art": e.get("art", ""), "calamity": dcal, "big": dbig}
				dying["rect"] = _dying_rect()
				_burn_setup()
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
					if mid == "crush" and not state.enemy_is_boss:
						banner_sub = "It hit with everything it had (2x). Stagger the next one with a skill."
					banner_color = Color(e["color"])
					banner_alpha = 2.0
					shake = maxf(shake, 6.0))
			"hazard":
				_later(delay + 0.1, func():
					_sfx({"spores": "curse", "rubble": "hurt", "flood": "freeze", "embers": "burn", "dark": "curse"}.get(String(e["id"]), "hurt"), 1.1)
					_fx(String(e["fx"]), _enemy_center(), 1.4)
					_fx(String(e["fx"]), _hero_center(), 1.2)
					_float(String(e["name"]).to_upper() + "!", Vector2(size.x / 2.0, size.y * 0.47), Color(e["color"]), 16)
					shake = maxf(shake, 5.0))
			"team_strike":
				_later(delay + 0.3, func():
					_sfx("combo")
					banner_text = "TEAM STRIKE!"
					banner_sub = "%d heroes hit as one: %d damage" % [int(e["count"]), int(e["dmg"])]
					banner_color = Color("#fbbf24")
					banner_alpha = 1.8
					_fx("impact", _enemy_center(), 1.8)
					_burst(_enemy_center(), Color("#fbbf24"), 30, 340.0)
					shake = maxf(shake, 9.0)
					_hit_stop(0.08))
			"minion_dead":
				_later(delay, func(): _float("MINION DOWN", _enemy_center() + Vector2(-30, -10), Color("#d4d4d4"), 13))
			"mastery":
				_later(delay + 0.4, func():
					_sfx("achievement")
					toast(String(e["name"]) + "!"))

## Rebuilds the hero picture when the look or gear changes.
func _update_hero_art() -> void:
	var looks := state.hero_looks()
	hero_has_aura = looks.has("Aura")  # read by the per-frame draw
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

## Plays a sprite effect from art/fx (drawn by tools/make_fx.gd) centered on pos.
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

## The hero plays a real animation (slash, thrust, cast, shoot).
func _hero_play(anim: String) -> void:
	if hero_art.has("anims") and (hero_art["anims"] as Dictionary).has(anim):
		hero_anim = anim
		hero_anim_t = 0.0

## The hit frame, unless a swing is still playing (getting hit never cuts an attack short).
func _hero_hurt() -> void:
	if hero_anim == "combat_idle":
		_hero_play("hurt")

func _hero_attack(e: Dictionary) -> void:
	_hero_play(HeroArt.attack_anim(_weapon_type()))
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
	_squash("enemy_squash", 1.4 if e["crit"] else 1.0)
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
	_later(0.08, _hero_hurt)  # 2.1 heroes have a hit frame
	shake = maxf(shake, 4.0)
	_squash("hero_squash")
	_burst(_hero_center(), Color("#f87171"), 8, 200.0)
	_fx("claw", _hero_center(), 1.0, true)
	_float("-%d" % e["dmg"], _hero_center(), Color("#f87171"), 20)

func _ability_fx(e: Dictionary) -> void:
	var c := Color(e.get("color", "#ffffff"))
	_sfx("ability", randf_range(0.95, 1.05))
	_pose_hero([["crouch", 0.1], ["cast", 0.18], ["strike", 0.06], ["follow", 0.14]])
	_hero_play("spellcast" if _weapon_type() in ["staff", "", "orb", "tome"] else HeroArt.attack_anim(_weapon_type()))
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
	# A6: a short flourish: a crouch-and-rise, a golden glow and a ring of light
	_pose_hero([["crouch", 0.08], ["cast", 0.3], ["follow", 0.1]])
	cast_color = Color("#fbbf24")
	cast_glow = 1.0
	create_tween().tween_property(self, "cast_glow", 0.0, 0.7)
	rings.append({"pos": _hero_center(), "life": 0.55, "max": 0.55, "grow": 74.0, "color": Color("#fde68a")})


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
	var key := "%d_%d_%s" % [zone, sub, DarkGrade.enabled]
	if not _bgs.has(key):
		var path := "res://art/bg/zone_%d_%d.png" % [zone, sub]
		if sub < 0 or not ResourceLoader.exists(path):
			path = "res://art/bg/zone_%d.png" % zone
		_bgs[key] = DarkGrade.texture(path, DarkGrade.SCENE, false)
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
## Freezes the fight picture for a moment so big hits land heavy. Only this view
## stops: the turn timer, menus and sound keep going (slowing Engine.time_scale
## would slow the game's own clock too). Follows the Screen shake setting.
func _hit_stop(seconds: float) -> void:
	if profile and (not profile.shake or profile.reduce_motion):
		return
	freeze_left = maxf(freeze_left, seconds)

## A6: true unless the player turned on Reduce motion.
func _motion_ok() -> bool:
	return profile == null or not profile.reduce_motion

## A6: a hit flash is one hard frame (white on monsters, hot red on the team) instead
## of a fading pink tint (art critique). Flashing effects OFF: a soft, dim blink instead.
func _flash_col(v: float, red: bool, a := 1.0) -> Color:
	var c := Color(1.0, 0.3, 0.22) if red else Color(1, 1, 1)
	if profile != null and not profile.flashes:
		return Color(c, v * 0.25 * a)
	return Color(c, a if v > 0.55 else 0.0)

## A6: a quick squash on whoever got hit ("hero_squash" / "enemy_squash"). Pose-frame
## art squashes by whole pixel rows (Sprites.POSES hit1); frame-animated (HeroArt) art
## squashes its rect here, so any sprite gets it. Off with Reduce motion.
func _squash(prop: String, amount := 1.0) -> void:
	if not _motion_ok():
		return
	set(prop, amount)
	create_tween().tween_property(self, prop, 0.0, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## The rect squashed wider and shorter, feet kept on the ground.
static func squashed(r: Rect2, amount: float) -> Rect2:
	if amount == 0.0:
		return r
	var sx := 1.0 + 0.12 * amount
	var sy := 1.0 - 0.10 * amount
	var ns := Vector2(r.size.x * sx, r.size.y * sy)
	return Rect2(Vector2(r.position.x - (ns.x - r.size.x) * 0.5, r.end.y - ns.y), ns)

const MAX_PARTICLES := 140  # R6: bursts never pile up past this (half with Low graphics)

func _burst(pos: Vector2, color: Color, count: int, speed: float) -> void:
	var cap := int(MAX_PARTICLES * 0.5) if profile != null and profile.low_graphics else MAX_PARTICLES
	count = mini(count, cap - particles.size())
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
	_drop_item(e, pos, color, r)
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

## The item itself falls out: it arcs to the ground, bounces, lies there glowing in its
## rarity color (longer for rarer finds), then flies to your hero.
func _drop_item(e: Dictionary, pos: Vector2, color: Color, r: int) -> void:
	var item: Dictionary = e.get("item", {})
	if item.is_empty():
		return
	var tex: Texture2D = Sprites.item_icon(item)
	if tex == null:
		return
	var fy := lerpf(_ground(), _team_ground(), 0.22) + _u() * randf_range(-3.0, 4.0)
	var land := Vector2(clampf(pos.x + randf_range(-1.0, 1.0) * _u() * 40.0, size.x * 0.12, size.x * 0.88), fy)
	var still := profile != null and profile.reduce_motion
	drops.append({"tex": tex, "white": _white_of(tex), "color": color, "r": r, "from": pos, "to": land, "t": 0.0,
		"life": 1.5 + 0.45 * mini(r, 5), "still": still, "spin": randf_range(-1.0, 1.0)})
	if drops.size() > 5:
		drops.pop_front()
	_later(0.0 if still else DROP_FALL, func(): _sfx("drop", randf_range(0.92, 1.08) + 0.04 * mini(r, 5)))

var _whites := {}
## A plain white silhouette of a texture (tinted for outlines).
func _white_of(tex: Texture2D) -> Texture2D:
	var id := tex.get_rid().get_id()
	if not _whites.has(id):
		var img := tex.get_image().duplicate() as Image  # a copy: never paint on the icon itself
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y, Color(1, 1, 1, 1.0 if img.get_pixel(x, y).a > 0.5 else 0.0))
		_whites[id] = ImageTexture.create_from_image(img)
	return _whites[id]

const DROP_FALL := 0.45   # seconds in the air
const DROP_FLY := 0.35    # seconds to fly to the hero at the end

func _draw_drops() -> void:
	var u := _u()
	var hero := _hero_center()
	for dp in drops:
		var t: float = dp["t"]
		var life: float = dp["life"]
		var r: int = dp["r"]
		var col: Color = dp["color"]
		var tex: Texture2D = dp["tex"]
		var from: Vector2 = dp["from"]
		var to: Vector2 = dp["to"]
		var side := u * (13.0 + 2.0 * mini(r, 5))
		var p := to
		var rot := 0.0
		var a := 1.0
		var scale := 1.0
		if dp["still"]:
			a = minf(1.0, t * 5.0) * minf(1.0, (life - t) * 4.0)
		elif t < DROP_FALL:
			# up and out of the monster, then down
			var f := t / DROP_FALL
			p = from.lerp(to, f) + Vector2(0, -u * 26.0 * sin(f * PI))
			rot = float(dp["spin"]) * TAU * f
		elif t < DROP_FALL + 0.18:
			var f := (t - DROP_FALL) / 0.18
			p = to + Vector2(0, -u * 5.0 * sin(f * PI))  # one small bounce
		elif t > life - DROP_FLY:
			var f := (t - (life - DROP_FLY)) / DROP_FLY
			f = f * f
			p = to.lerp(hero, f)
			scale = 1.0 - 0.6 * f
			a = 1.0 - f * 0.7
		var on_ground := t >= DROP_FALL and t <= life - DROP_FLY
		# a glow on the floor where it lies: Uncommon and better
		if r >= 1 and on_ground:
			var pulse := 0.5 + 0.5 * sin(t * 5.0)
			draw_set_transform(_snap(to + Vector2(0, side * 0.1)), 0.0, Vector2(1.0, 0.32))
			draw_circle(Vector2.ZERO, side * (0.9 + 0.12 * mini(r, 5)), Color(col, (0.18 + 0.12 * pulse) * a))
			draw_circle(Vector2.ZERO, side * 0.55, Color(col.lightened(0.3), (0.22 + 0.15 * pulse) * a))
			draw_set_transform(Vector2.ZERO)
		# Epic and better: little sparkles rise off it
		if r >= 3 and on_ground:
			for k in 3:
				var st := fmod(t * 0.9 + k * 0.33, 1.0)
				var sp := to + Vector2(sin(k * 2.3 + t) * side * 0.6, -side * 0.3 - st * side * 1.6)
				draw_rect(Rect2(_snap(sp), Vector2(u * 1.5, u * 1.5)), Color(col.lightened(0.5), (1.0 - st) * a))
		var sz := side * scale
		var dst := Rect2(-Vector2(sz, sz) / 2.0, Vector2(sz, sz))
		draw_set_transform(_snap(p - Vector2(0, sz * 0.5)), rot, Vector2.ONE)
		# an outline in the rarity color so it reads against any floor
		if r >= 1:
			var wt: Texture2D = dp["white"]
			for off in [Vector2(-u, 0), Vector2(u, 0), Vector2(0, -u), Vector2(0, u)]:
				draw_texture_rect(wt, Rect2(dst.position + off, dst.size), false, Color(col, 0.85 * a))
		draw_texture_rect(tex, dst, false, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO)

func _set_dying_alpha(v: float) -> void:
	if dying.has("tex"):
		dying["alpha"] = v

func _enemy_died() -> void:
	_sfx("kill", randf_range(0.9, 1.1))
	if dying.has("tex"):
		_burst(_dying_rect().get_center(), Color(dying["color"]), 24, 300.0)
	var t := create_tween()
	t.tween_method(_set_dying_alpha, 1.0, 0.0, 0.6 if (profile == null or not profile.reduce_motion) else 0.3)
	t.tween_callback(func():
		dying = {}
		_burn_off())
	t.tween_callback(func(): walk_in = 1.0)
	t.tween_property(self, "enemy_alpha", 1.0, 0.25)
	# the next one steps out from the doors toward you as it fades in (Juzo, Oct 26)
	t.parallel().tween_property(self, "walk_in", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

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
	_sfx("floor")  # bosses get their own entrance (_start_intro)
	var zone := GameData.zone_for_floor(state.floor_num)
	banner_text = "FLOOR %d" % state.floor_num
	banner_color = Color("#fbbf24")
	banner_sub = "%s  -  %s" % [zone["name"], GameData.sub_name(state.floor_num)]
	banner_alpha = 1.8

## What kind of boss this is, for its entrance card.
func _boss_title() -> String:
	if state.enemy_calamity > 0:
		return "CALAMITY"
	if GameData.wall_mult(state.floor_num) > 1.0:
		return "THE WALL"
	if GameData.is_region_boss(state.floor_num):
		return "REGION BOSS"
	return "MID BOSS" if state.enemy_boss_kind == "mid" else "BOSS"

## True while a boss entrance holds the turns.
func busy() -> bool:
	if DisplayServer.get_name() == "headless":
		return false  # tests drive turns directly
	return intro_t >= 0.0 and intro_t < INTRO_LEN - 0.5

func skip_intro() -> void:
	if intro_t >= 0.0 and intro_t < INTRO_LEN - 0.5:
		if intro_t < INTRO_REVEAL:
			_intro_burst()
		intro_t = INTRO_LEN - 0.5

## Starts a boss's entrance the first time it stands there; runs the clock.
func _intro_step(delta: float) -> void:
	if state == null:
		return
	if (state.enemy_is_boss or state.enemy_calamity > 0) and is_visible_in_tree() and not state.in_town and state.enemy_hp > 0:
		var key := "%d|%s|%d" % [state.floor_num, state.enemy_name, state.enemy_max_hp]
		if key != intro_key:
			intro_key = key
			intro_title = _boss_title()
			intro_name = state.enemy_name
			intro_color = Color("#ef4444") if state.enemy_calamity > 0 else Color("#fbbf24")
			intro_t = 0.0
			_sfx("curse" if state.enemy_calamity > 0 else "enrage", 0.8)
			if profile and profile.reduce_motion:
				intro_t = INTRO_REVEAL  # no silhouette or slide
				_intro_burst()
			return
	if intro_t < 0.0:
		return
	var before := intro_t
	intro_t += delta
	if before < INTRO_REVEAL and intro_t >= INTRO_REVEAL:
		_intro_burst()
	if intro_t >= INTRO_LEN:
		intro_t = -1.0

func _intro_burst() -> void:
	_sfx("boss_intro")
	shake = 12.0
	enemy_flash = 1.0
	create_tween().tween_property(self, "enemy_flash", 0.0, 0.35)
	_burst(_enemy_center(), intro_color, 40, 380.0)

## Letterbox bars, a dimmed room and the boss's name card on the lower bar.
func _draw_intro(font: Font, w: float, h: float) -> void:
	if intro_t < 0.0:
		return
	var k := minf(clampf(intro_t / 0.3, 0.0, 1.0), clampf((INTRO_LEN - intro_t) / 0.4, 0.0, 1.0))
	k = k * k * (3.0 - 2.0 * k)
	var bh := h * 0.13 * k
	draw_rect(Rect2(0, 0, w, bh), Color(0, 0, 0, 0.92))
	draw_rect(Rect2(0, h - bh, w, bh), Color(0, 0, 0, 0.92))
	if intro_t < INTRO_REVEAL:
		draw_rect(Rect2(0, bh, w, h - bh * 2.0), Color(0, 0, 0, 0.25 * k))
	# the name card slides in from the right after the reveal
	var s := clampf((intro_t - INTRO_REVEAL) / 0.35, 0.0, 1.0)
	if s <= 0.0:
		return
	var slide := (1.0 - s) * (1.0 - s) * w * 0.5
	var a := k * s
	var y := h - bh + 20.0
	draw_string_outline(font, Vector2(slide, y), intro_title, HORIZONTAL_ALIGNMENT_CENTER, w, 14, 4, Color(0, 0, 0, a))
	draw_string(font, Vector2(slide, y), intro_title, HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color(intro_color, a))
	var lw := w * 0.5 * s
	draw_rect(Rect2(w / 2.0 - lw / 2.0, y + 6.0, lw, 2.0), Color(intro_color, 0.8 * a))
	draw_string_outline(font, Vector2(-slide, y + 34.0), intro_name, HORIZONTAL_ALIGNMENT_CENTER, w, 28, 7, Color(0, 0, 0, a))
	draw_string(font, Vector2(-slide, y + 34.0), intro_name, HORIZONTAL_ALIGNMENT_CENTER, w, 28, Color(1, 0.96, 0.88, a))

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
	if profile == null or not profile.damage_numbers:
		# one damage display (the counter under the bar): numbers go, words stay
		if text.is_valid_int() or (text.begins_with("-") and text.substr(1).is_valid_int()) or (text.begins_with("+") and text.substr(1).is_valid_int()) or text.begins_with("CRIT"):
			return
		var sp := text.rfind(" ")
		if sp > 0 and text.substr(sp + 1).is_valid_int():
			text = text.substr(0, sp)  # "CLEAVE 579" -> "CLEAVE"
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

## R6: drops finished effects in place (filter() made a new array for each list every
## frame). With "t" and "life": gone when t >= life; only "life": when life <= 0;
## only "t": when t >= 1.
static func _prune(arr: Array, t_key: String, life_key: String) -> void:
	for i in range(arr.size() - 1, -1, -1):
		var d: Dictionary = arr[i]
		var t := float(d[t_key]) if t_key != "" else 0.0
		var gone := t >= float(d[life_key]) if life_key != "" and t_key != "" else (float(d[life_key]) <= 0.0 if life_key != "" else t >= 1.0)
		if gone:
			arr.remove_at(i)

func _process(delta: float) -> void:
	_intro_step(delta)
	if freeze_left > 0.0:
		freeze_left -= delta  # hit stop: hold this frame
		return
	if profile == null or not profile.reduce_motion:
		bob += delta  # idle breathing and bobbing (frozen with Reduce motion)
	shake = move_toward(shake * exp(-delta * 6.0), 0.0, delta * 8.0)  # quick fade with a short tail
	for key in bar_ghost:  # R6: no keys() copy every frame
		bar_ghost[key] = move_toward(float(bar_ghost[key]), float(bar_target.get(key, 0.0)), delta * 0.8)
	hero_anim_t += delta
	if chest_t >= 0.0:
		chest_t += delta
		if chest_t > 2.2:
			chest_t = -1.0
	if state != null:
		summon_in = move_toward(summon_in, 1.0 if state.summon_turns > 0 else 0.0, delta * 3.0)
	if not pet_hits.is_empty():
		for k in pet_hits.keys():
			pet_hits[k] = float(pet_hits[k]) - delta
			if float(pet_hits[k]) <= 0.0:
				pet_hits.erase(k)
	for dp in drops:
		dp["t"] = float(dp["t"]) + delta
	_prune(drops, "t", "life")
	for bm in beams:
		bm["t"] = float(bm["t"]) + delta
	_prune(beams, "t", "life")
	for fx in fx_sprites:
		fx["t"] = float(fx["t"]) + delta
	for i in range(fx_sprites.size() - 1, -1, -1):
		if float(fx_sprites[i]["t"]) * FX_FPS >= float(_fx_frames.get(fx_sprites[i]["name"], 1)):
			fx_sprites.remove_at(i)
	if hero_anim != "combat_idle" and hero_art.has("anims"):
		var la: Dictionary = hero_art["anims"].get(hero_anim, {})
		if la.is_empty() or hero_anim_t >= float((la["tex"] as Array).size()) / float(la["fps"]):
			hero_anim = "combat_idle"
			hero_anim_t = 0.0
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
	_prune(floaters, "", "life")
	for p in particles:
		p["life"] -= delta
		p["vel"] += Vector2(0, 600 * delta)
		p["pos"] += p["vel"] * delta
	_prune(particles, "", "life")
	for r in rings:
		r["life"] -= delta
	_prune(rings, "", "life")
	for pr in projectiles:
		pr["t"] += delta / 0.16
		pr["pos"] = (pr["from"] as Vector2).lerp(pr["to"], minf(pr["t"], 1.0))
	_prune(projectiles, "t", "")
	if toast_life > 0.0:
		toast_life -= delta
	elif not toasts.is_empty():
		toast_text = toasts.pop_front()
		toast_life = 6.0
	# Fable r2 #17: with Reduce motion on nothing breathes, so a still scene is redrawn 4 times a
	# second (HP and state changes still show) instead of every frame; anything moving draws every frame
	if profile == null or not profile.reduce_motion or _anything_moving():
		_still_t = 0.0
		queue_redraw()
	else:
		_still_t += delta
		if _still_t >= 0.25:
			_still_t = 0.0
			queue_redraw()

var _still_t := 0.0

func _anything_moving() -> bool:
	if shake > 0.01 or banner_alpha > 0.0 or toast_life > 0.0 or chest_t >= 0.0 or freeze_left > 0.0 or intro_t >= 0.0:
		return true
	if not (floaters.is_empty() and particles.is_empty() and rings.is_empty() and projectiles.is_empty()
			and drops.is_empty() and beams.is_empty() and fx_sprites.is_empty() and pet_hits.is_empty() and toasts.is_empty()):
		return true
	if hero_anim != "combat_idle" or not hero_seq.is_empty() or not enemy_seq.is_empty():
		return true
	if summon_in > 0.0 and summon_in < 1.0:
		return true
	for key in bar_ghost:
		if absf(float(bar_ghost[key]) - float(bar_target.get(key, 0.0))) > 0.001:
			return true
	return false

## Screen pixels per art pixel (whole numbers keep pixel art crisp).
## (The art is HD: 64x64 bodies, so a unit is half what it was at 32x32.)
## Pixel-perfect sizing: how many REAL screen pixels each art pixel covers.
## The window may be scaled by any amount (phones, resized windows), so the
## count is worked out in screen pixels and kept a whole number: every art
## pixel is then exactly the same size, with no uneven or blurred pixels.
func _unit() -> int:
	# 2.1 ONE scale: hero, monsters and pets all show every art pixel at ArtStyle.SCREEN_PX design
	# points (whole screen pixels), so one screen never mixes pixel sizes. On short screens (iPhone SE,
	# iPad) everyone steps down together: the hero's 64-pixel frame must fit between the top quarter of
	# the stage (the monster) and the team's ground line
	var sc := _scr()
	return clampi(ArtStyle.unit(sc), 1, maxi(1, floori((_team_ground() - size.y * 0.25) * sc / 64.0)))

## Screen pixels per design pixel (the window's stretch factor).
## Tests only: the phone's stretch scale (a headless run never applies one).
static var test_scale := 0.0

func _scr() -> float:
	if test_scale > 0.0:
		return test_scale
	# the window's stretch (fable/pets: the canvas transform reads 1.0 under canvas_items stretch,
	# so "3x" was 2.56 screen px at 430); shared with the pets' and dungeon's pictures
	return PixelPic.stretch(self)

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
	return _unit()

func _party_members() -> Array:
	return state.party.members if state != null and state.party != null else []

## With a party the leader stands a little further forward.
func _leader_x() -> float:
	return 0.5

## Companions stand behind the leader, a size smaller (they're further back).
func _member_canvas(i: int) -> Rect2:
	var u := _u()
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
		var art := Sprites.hero_back_of(g)  # rebuilt at most twice a second, not every frame
		var c := _member_canvas(i)
		var u := c.size.x / Sprites.CANVAS
		var a := 0.35 if m.knocked_out else 1.0
		var body_r := Rect2(c.position + Vector2(8, 12) * Sprites.HD * u, Vector2(32, 32) * Sprites.HD * u)
		draw_ellipse_shadow(body_r)
		var fx0: Dictionary = party_fx.get(i, {})
		if art.has("anims"):
			# Seen from behind, like the leader: a real animation frame (kneeling = faded)
			var anims: Dictionary = art["anims"]
			var striking := float(fx0.get("lunge", 0.0)) > 0.3
			var an: Dictionary = anims.get("slash" if striking and anims.has("slash") else "combat_idle", {})
			if not an.is_empty():
				var n: int = (an["tex"] as Array).size()
				var fi := (int(bob * float(an["fps"]) + i * 3) % n) if not striking else mini(n - 1, int((1.0 - float(fx0.get("lunge", 0.0))) * n))
				var sz: int = an["size"]
				var off := Vector2(Sprites.BODY_OFFSET) - Vector2((sz - HeroArt.CORE) / 2, (sz - HeroArt.CORE) / 2)
				var r := Rect2(c.position + off * u, Vector2(sz, sz) * u)
				draw_texture_rect(an["white"][fi], Rect2(r.position + Vector2(0, -u), r.size), false, Color(_rim_color(), 0.6 * a))
				for d in [Vector2(-u, 0), Vector2(u, 0)]:
					draw_texture_rect(an["white"][fi], Rect2(r.position + d, r.size), false, Color(_rim_color(), 0.3 * a))
				draw_texture_rect(an["tex"][fi], r, false, Color(1, 1, 1, a))
				if float(fx0.get("flash", 0.0)) > 0.0:
					draw_texture_rect(an["white"][fi], r, false, _flash_col(float(fx0["flash"]), true))
			_member_plate(m, g, _member_bar(i))
			continue
		var poses := Sprites.poses_for("m" + str(String(g.get_meta("back_key", "")).hash()), art["body_img"], 1, int(art["hand"].y))
		var fx: Dictionary = party_fx.get(i, {})
		var pose_name := "kneel2" if m.knocked_out else ("strike" if float(fx.get("lunge", 0.0)) > 0.3 else ("idle1" if fmod(bob + i * 0.2, 0.9) > 0.45 else "idle0"))
		var pose: Dictionary = poses[pose_name]
		draw_texture_rect(pose["tex"], c, false, Color(1, 1, 1, a))
		if float(fx.get("flash", 0.0)) > 0.0:
			draw_texture_rect(pose["white"], c, false, _flash_col(float(fx["flash"]), true))
		if art["weapon"] != null and not m.knocked_out:
			var hand: Vector2 = c.position + ((art["hand"] as Vector2) + Vector2(int(pose["dx"]), int(pose["dy"]))) * u
			var ang := deg_to_rad(MELEE_REST - 40.0 * float(fx.get("lunge", 0.0)) if not art["weapon_type"] in ["bow", "staff"] else 12.0)
			draw_set_transform(_off + hand, ang, Vector2(u, u))
			draw_texture(art["weapon"], -(art["pivot"] as Vector2), Color(1, 1, 1, a))
			draw_set_transform(_off)
		_member_plate(m, g, _member_bar(i))

## Where a companion's health bar sits: as wide as their body, just over their head. The
## animated heroes' frames are 1x (128 px, a 32 px body at their centre, the head 37 rows
## down); the older posed art is HD with the body at BODY_OFFSET (pets r5: the 1x frames were
## measured as HD, so the bars ran across the whole room).
func _member_bar(i: int) -> Rect2:
	var c := _member_canvas(i)
	var u := c.size.x / Sprites.CANVAS
	var art := Sprites.hero_back_of(_party_members()[i].hero)
	if art.has("anims"):
		var sz := 128.0
		var an: Dictionary = (art["anims"] as Dictionary).get("combat_idle", {})
		if not an.is_empty():
			sz = float(an["size"])
		var top := c.position.y + (float(Sprites.BODY_OFFSET.y) - (sz - HeroArt.CORE) / 2.0 + float(an.get("top", 37))) * u
		var mid := c.position.x + (float(Sprites.BODY_OFFSET.x) - (sz - HeroArt.CORE) / 2.0 + sz / 2.0) * u
		return Rect2(mid - 16.0 * u, top - 10.0, 32.0 * u, 5.0)
	return Rect2(c.position + Vector2(8.0, 8.0) * Sprites.HD * u, Vector2(32.0 * Sprites.HD * u, 5.0))

## A companion's small health bar and name over their head.
func _member_plate(m, g: GameState, b: Rect2) -> void:
	draw_rect(b, Color(0.03, 0.03, 0.05, 0.85))
	draw_rect(Rect2(b.position.x + 1, b.position.y + 1, (b.size.x - 2) * clampf(float(m.hp) / maxf(1.0, m.max_hp()), 0.0, 1.0), 3), Color("#22c55e") if not m.knocked_out else Color("#64748b"))
	var font := UI.game_font()   # interface pass: the game font everywhere
	# knocked out: the plate says DOWN in red in place of the name (the face-off has no team strip)
	var col := Color("#f87171") if m.knocked_out else Color(g.class_info().get("color", "#ffffff")).lightened(0.4)
	_outlined(font, Vector2(b.position.x - 30, b.position.y - 4), _fit_text(font, member_label(m), NAME_FS, b.size.x + 60), HORIZONTAL_ALIGNMENT_CENTER, b.size.x + 60, NAME_FS, col)

static func member_label(m) -> String:
	return "DOWN" if m.knocked_out else String(m.name)

## The visible body part of the hero (for bars, effects and centering).
func _hero_rect() -> Rect2:
	var c := _hero_canvas()
	var u := _hu()
	return Rect2(c.position + Vector2(8, 12) * Sprites.HD * u, Vector2(32, 32) * Sprites.HD * u)

## The top of the hero's rect standing still (no breathing bob, lunge or recoil). The monster's
## feet and plate are placed from this, so they never hop when the hero attacks (fable r3).
## From _hero_canvas's formula with no bob/lunge/recoil (fable r4: no toggling of live fields),
## once a frame.
func _hero_rest_top() -> float:
	var fr := Engine.get_process_frames()
	if fr != _rest_frame:
		_rest_frame = fr
		var u := _hu()
		_rest_top = _snap(Vector2(0.0, _team_ground() - (Sprites.HERO_FOOT + 1) * u)).y + 12.0 * Sprites.HD * u
	return _rest_top

var _rest_frame := -1
var _rest_top := 0.0

func _hand_screen() -> Vector2:
	var c := _hero_canvas()
	var p: Dictionary = _hero_poses().get(hero_pose, {})
	var off := Vector2(int(p.get("dx", 0)), int(p.get("dy", 0)))
	return c.position + (_anim_hand() + off) * _hu()

## The hand on the hero frame showing now (canvas pixels): each swing frame has its own.
func _anim_hand() -> Vector2:
	var hand: Vector2 = hero_art.get("hand", Vector2(32, 31) * Sprites.HD)
	if not hero_art.has("anims"):
		return hand
	var anims: Dictionary = hero_art["anims"]
	var an: Dictionary = anims.get(hero_anim, anims.get("combat_idle", {}))
	var hs: Array = an.get("hands", [])
	if hs.is_empty():
		return hand
	var fi := int(hero_anim_t * float(an["fps"]))
	return hs[fi % hs.size() if hero_anim == "combat_idle" else mini(fi, hs.size() - 1)]

func _hero_poses() -> Dictionary:
	if hero_art.is_empty() or not hero_art.has("body_img"):
		return {}
	var hand: Vector2 = hero_art.get("hand", Vector2(32, 31) * Sprites.HD)
	return Sprites.poses_for("h" + str(hero_art_key.hash()), hero_art["body_img"], 1, int(hand.y))

func _enemy_poses(art: Dictionary) -> Dictionary:
	if art.is_empty():
		return {}
	var key := state.enemy_art if state.enemy_art != "" else str(state.enemy_name.hash())
	var zone := clampi(GameData.zone_index(state.floor_num), 0, 9)
	var pk := "e%s|%d|%s" % [key, zone, state.enemy_variant]
	if not _lit_src.has(pk):
		# the variant and the zone rim go on the kept source Image once, then every pose is cut
		# from it (fable r3: lit() read each new pose back from the GPU, right on the hit)
		if _lit_src.size() > 24:
			_lit_src.clear()
		_lit_src[pk] = SpriteLight.lit_image(Variants.image(art["img"], state.enemy_variant), zone)
	return Sprites.poses_for(pk, _lit_src[pk], -1)

var _lit_src := {}

## The monster's picture by its art key, falling back to its species id (never its
## shown name: names change with ranks, variants and realm spirits).
func _enemy_art(boss: bool) -> Dictionary:
	if state.enemy_art != "":
		var a := Sprites.enemy_by_key(state.enemy_art)
		if not a.is_empty():
			return a
	if boss:
		var b := Sprites.enemy_by_key("boss_" + state.enemy_species)
		if not b.is_empty():
			return b
	return Sprites.enemy_by_key(state.enemy_species)

func _dying_rect() -> Rect2:
	if dying.has("rect"):
		return dying["rect"]   # taken at the kill (fable r5: re-measured, the corpse moved)
	# the flags were taken at the kill (fable r4: the state's Calamity flag is already cleared)
	return _rect_for(Sprites.enemy_by_key(dying.get("art", "")), dying["boss"], bool(dying.get("big", dying["boss"])), 1 if bool(dying.get("calamity", false)) else 0)

func _enemy_rect(boss: bool) -> Rect2:
	return _rect_for(_enemy_art(boss), boss, _boss_stage())

## Every monster shows at the hero's pixel scale (fable r1: rank is shown by the aura,
## pips and name colour, never by a second pixel size).
## cal: 1 / 0 for a Calamity or not, -1 = the current fight's (a dying one passes its own).
func _rect_for(art: Dictionary, boss: bool, big := false, cal := -1) -> Rect2:
	var sc := _scr()
	var ui := float(_unit())
	var u := ui / sc
	var is_cal := state.enemy_calamity > 0 if cal < 0 else cal == 1
	var x := size.x * 0.5
	# Fable r2: the monster stands ON its plate (plate top = _bar_rect y - 6), never behind it
	var base := _enemy_ground()
	var move := enemy_lunge * size.y * 0.16 - enemy_recoil * u * 3.0 * Sprites.HD - walk_in * size.y * 0.03
	if art.is_empty():
		var s := _sprite_size(boss)
		return Rect2(x - s / 2.0, base + move - s + sin(bob * 2.4 + 1.0) * 2.0, s, s)
	ui = maxf(1.0, minf(ui, _width_cap(art, boss, sc, 1 if is_cal else 0)))
	if big:
		return _faceoff_rect(art, ui, sc, move, boss or is_cal, is_cal)
	# ...and never taller than the space above the team
	ui = maxf(1.0, minf(ui, floorf(base * 0.92 * sc / maxf(1.0, float(art["foot"]) + 1.0))))
	var gy := base + move
	u = ui / sc
	var sz: Vector2 = art["size"] * u
	var foot: float = art["foot"]
	return Rect2(_snap(Vector2(x - sz.x / 2.0, gy - (foot + 1.0) * u)), sz)

## The face-off (Juzo, Oct 26, claude/art_test/monsters/faceoff/JUZO_REFERENCE_surtr_faceoff.jpg:
## "guarding the doors, staring you down"): every monster stands further back, centred between the
## doors, feet on the hall's floor just behind the hero, who stands in front and may cover its
## lower legs. A boss's size is the biggest whole scale no taller than face_share of the stage
## (so it never fills the stage; Juzo's opt2); every top stays under the bar, name and chip row;
## feet face_drop of the stage nearer than the floor seam, or nearer still when its size needs it.
static var face_share := 0.46
static var face_drop := 0.03

func _faceoff_rect(art: Dictionary, ui: float, sc: float, move: float, boss: bool, cal := false) -> Rect2:
	var seam := _floor_line() + size.y * face_drop
	var top_min := _boss_bar().end.y + BOSS_GAP
	var rows := float(art["foot"]) + 1.0
	if boss:
		# a Calamity may stand taller than a zone boss (lead, Oct 26: it must read bigger)
		var share := face_share + (CALAMITY_SHARE if cal else 0.0)
		while ui > 1.0 and rows * ui / sc > size.y * share:
			ui -= 1.0
	else:
		# commons and packs: as big as fits with the feet on the floor, up to COMMON_NEAR of the
		# stage nearer than the seam (lead, Oct 26: a 1x kobold on an SE was too small to read)...
		while ui > 1.0 and top_min + rows * ui / sc > seam + size.y * COMMON_NEAR:
			ui -= 1.0
		# ...and a step bigger while the hero would hide most of it (Juzo, Oct 26: centred like the
		# bosses, never "practically disappearing behind the character")
		# (its feet stay a tenth of the stage behind the hero's)
		while ui < _hero_unit() + 1.0 and _face_visible(rows * ui / sc, seam, top_min) < FACE_VISIBLE 				and top_min + rows * (ui + 1.0) / sc <= _team_ground() - size.y * 0.1:
			ui += 1.0
	var u := ui / sc
	var sz: Vector2 = art["size"] * u
	var feet := maxf(seam, top_min + rows * u)
	return Rect2(_snap(Vector2(size.x * 0.5 - sz.x / 2.0, feet + move - rows * u)), sz)

const COMMON_NEAR := 0.08
const CALAMITY_SHARE := 0.1   # on top of face_share: up to ~56% of the stage
const FACE_VISIBLE := 0.45    # the least share of a monster's height showing above the hero's head

## The share of a monster h tall that shows above the hero's head where the face-off stands it
## (feet on the seam, or nearer when its top would reach the chip row).
func _face_visible(h: float, seam: float, top_min: float) -> float:
	var feet := maxf(seam, top_min + h)
	return clampf((_hero_rest_top() - (feet - h)) / maxf(1.0, h), 0.0, 1.0)

## Design px from the top bar's bottom to a monster's top row: the name line and one chip row,
## always, so chips coming and going never move it.
const BOSS_GAP := 64.0   # BOSS_NAME + CHIP_ROW + 10
const BOSS_NAME := 26.0   # the plate box ends 24 px under the bar (_draw_plate)
## Where the hall's floor meets its far wall (HallsScene.floor_y at the far wall, the row the
## 3D camera draws), a little in front of it.
func _floor_line() -> float:
	if state != null and (state.in_town or state.trial_active):
		return _ground()
	return HallsScene.floor_y(size, HallsScene.D, HallsScene.screen_scale(self)) + 8.0

## Where the wind-up "!" stands (its centre x, its baseline): right of the boss bar on the boss
## stage, else just over its plate's right end.
func _telegraph_at(er: Rect2) -> Vector2:
	if _boss_stage():
		var bb := _boss_bar()
		return Vector2(minf(bb.end.x + 24.0, size.x - 14.0), bb.end.y + 14.0)
	# top-right of the monster, over the wall (fable r5: by the plate it stood on its foot)
	return Vector2(minf(er.end.x + 10.0, size.x - 14.0), er.position.y + 40.0)

## Pips beside a ranked monster's name: one per tier, so Epic, Legendary and Mythic (3-5) are
## told apart by count as well as colour (fable r4: all three wore 3). Calamities keep 3 red.
static func tier_pips(tier: int) -> int:
	return clampi(tier, 1, 5)

## The banner's line: position = (left x, the big text's baseline), size.x = its width; the sub
## line sits 17 lower. On the boss stage it goes under the bar, name and chips; elsewhere under
## the zone title.
func _banner_line() -> Rect2:
	if _boss_stage():
		# over its chest, under its face (the top 35%), over the top of the hero's hair at most
		# allows (fable r5: the text sat on the imp's and Grendel's faces)
		var er := _dying_rect() if dying.has("tex") and enemy_alpha <= 0.0 else _enemy_rect(state.enemy_is_boss)
		var chips_end := _boss_bar().end.y + BOSS_NAME + _boss_chip_room()
		var by := maxf(minf(er.position.y + er.size.y * 0.35 + 24.0, _hero_rest_top() + 24.0), chips_end + 30.0)
		return Rect2(8.0, by, size.x - 16.0, 17.0)
	return Rect2(0.0, 62.0, size.x, 17.0)


## Bosses and Calamities fight on the boss stage (big, behind the hero, their bar at the top).
func _boss_stage() -> bool:
	var fr := Engine.get_process_frames()   # asked ~10 times a frame (fable r4)
	if fr != _stage_frame or _stage_key != _fight_key():
		_stage_frame = fr
		_stage_key = _fight_key()
		_stage = state != null and (state.enemy_is_boss or state.enemy_calamity > 0 or _tall_common())
	return _stage

var _stage_frame := -1
var _stage_key := ""
var _stage := false

func _fight_key() -> String:
	return "" if state == null else "%s|%s|%d|%.3f" % [state.enemy_art, state.enemy_is_boss, state.enemy_calamity, size.y + _scr()]

## A common too tall to keep the one pixel scale above the hero on a short screen (an iPhone SE:
## ~90 of 112 commons were 1x beside the 2x hero): it takes the boss stage's place instead,
## behind the hero under the top bar, at the hero's scale.
func _tall_common() -> bool:
	if state == null or state.enemy_is_boss or state.enemy_calamity > 0:
		return false
	return _is_tall(_enemy_art(false))

## True if this common's art can't keep the unit above the hero (see _tall_common).
func _is_tall(art: Dictionary) -> bool:
	if art.is_empty() or not art.has("foot"):
		return false
	var sc := _scr()
	if sc < 1.0:
		return true   # every common on a phone (fable r5: one layout for both, feet on the floor)
	var ui := maxf(1.0, minf(float(_unit()), _width_cap(art, false, sc, 0)))
	return (float(art["foot"]) + 1.0) * ui / sc > _enemy_ground() * 0.92

## The boss bar (health bar; the name sits under it) along the top of the stage.
func _boss_bar() -> Rect2:
	return Rect2(size.x * 0.15, 20.0, size.x * 0.7, 14.0)  # where the zone title is in other fights

## The monster's feet: on the stage's ground line, or higher if its name plate (which stays
## clear of the hero's head, _bar_rect) would cover them.
func _enemy_ground() -> float:
	return minf(_ground(), _hero_rest_top() - 52.0)

## Most screen pixels per art pixel the stage width allows: commons keep to 60% of
## the width, bosses may reach the edges (92%) and Calamities fill the stage (96%), so
## all of them stay at the hero's 3x on a phone.
func _width_cap(art: Dictionary, boss: bool, sc: float, cal := -1) -> float:
	var span: float = (art["size"] as Vector2).x
	var is_cal := state.enemy_calamity > 0 if cal < 0 else cal == 1
	var share := 0.96 if is_cal else (0.92 if boss else ArtStyle.COMMON_SHARE)
	return floorf(size.x * share * sc / maxf(1.0, span))

func _hero_center() -> Vector2:
	var r := _hero_rect()
	return Vector2(r.get_center().x, r.position.y + r.size.y * 0.35)

func _enemy_center() -> Vector2:
	var r := _enemy_rect(state.enemy_is_boss)
	return Vector2(r.get_center().x, r.position.y + r.size.y * 0.35)

var enemy_plate := Callable()  # set while drawing the monster, called after the team

func _draw() -> void:
	enemy_plate = Callable()
	if state == null:
		return
	var w := size.x
	var h := size.y
	var zone := GameData.zone_for_floor(state.floor_num)
	var tint := Color(zone["color"])
	var font := UI.game_font()   # interface pass: the game font everywhere

	# Background (0.13): the room you walked into, first-person (HallsScene), same as between fights
	if state.in_town or state.trial_active:
		_draw_old_bg(w, h)
	else:
		halls.t = Time.get_ticks_msec() / 1000.0
		halls.build(state, size, HallsScene.screen_scale(self))
		halls.draw_shell(self, size)
		halls.draw_doors(self, null, {}, font)
		var things: Array = halls.scenery()
		things.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
		for th in things:
			halls.draw_scenery(self, th)
		halls.vignette(self, size)
		if not halls.is_3d():
			_draw_mood(w, h, _ground())
	if not _boss_stage():  # the boss bar takes the title's place on the boss stage
		_outlined(font, Vector2(12, 26), _fit_text(font, "%s  -  %s" % [zone["name"], GameData.sub_name(state.floor_num)], SCENE_FS, size.x - 24.0), HORIZONTAL_ALIGNMENT_LEFT, -1, SCENE_FS, Color(1, 1, 1, 0.7))
	elif _tall_common():
		# a tall common keeps the zone's name: small and dim over its plate (which starts at 14)
		# (fable r4: 59% of SE fights lost it); bosses keep the clean bar
		_outlined(font, Vector2(0, 12), _fit_text(font, "%s  -  %s" % [zone["name"], GameData.sub_name(state.floor_num)], 13, size.x - 24.0), HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(1, 1, 1, 0.55))
	_draw_status(font)

	# Shake as "trauma": strength grows faster than linearly (small taps barely move the
	# view, big hits really land) and wobbles smoothly instead of jumping every frame.
	var trauma := clampf(shake / 14.0, 0.0, 1.0) if (profile == null or (profile.shake and not profile.reduce_motion)) else 0.0
	var sh := 14.0 * pow(trauma, 1.6)
	_off = Vector2(sin(bob * 53.0) + 0.5 * sin(bob * 97.0), cos(bob * 61.0) + 0.5 * cos(bob * 89.0)) * sh / 1.5
	draw_set_transform(_off)

	var hr := _hero_rect()

	# Dying enemy fading out
	if dying.has("tex"):
		var dr := _dying_rect()
		# 0.13+: it crumbles away pixel by pixel, edges glowing, instead of fading (_burn_setup)
		var frame := _burn_tex(1.0 - float(dying["alpha"]))
		dr.position.y -= (1.0 - float(dying["alpha"])) * 6.0
		draw_texture_rect(frame, dr, false, Color(1, 1, 1, minf(1.0, float(dying["alpha"]) * 3.0)))

	# A pack shows only the one you fight; the rest wait off stage, counted by its name (Juzo, Oct 26)
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
			_soft_glow(er, Color(0.89, 0.23, 0.27), (0.12 + 0.04 * sin(bob * 1.6)) * enemy_alpha)
		elif boss:
			_soft_glow(er, Color(0.98, 0.75, 0.14), (0.09 + 0.03 * sin(bob * 3.0)) * enemy_alpha)
		elif (state.enemy_tier > 0 and not Realms.hides_tier(state)) or state.enemy_goblin:
			_draw_aura(er, Color("#fbbf24") if state.enemy_goblin else Color(Monsters.tier_color(state.enemy_tier)), state.enemy_tier)
		draw_ellipse_shadow(er)
		# Pose frames (breathing, attacking, getting hit) are made from whole pixels
		var local := er
		var epose: Dictionary = _enemy_poses(art).get(enemy_pose, {})
		if not epose.is_empty():
			etex = epose["tex"]   # already in its variant and the zone's rim (_enemy_poses)
			ewhite = epose["white"]
		else:
			etex = SpriteLight.lit(Variants.tex(etex, state.enemy_variant), clampi(GameData.zone_index(state.floor_num), 0, 9))
		var etint := Color(1, 1, 1, enemy_alpha)
		var rank := GameData.zone_rank(state.floor_num)
		if rank > 0:
			etint = Color(1.0 - 0.08 * rank, 0.9 - 0.1 * rank, 1.0 - 0.02 * rank, enemy_alpha)
		if intro_t >= 0.0:
			# Boss entrance: a black shape until it bursts into view
			var rv := clampf((intro_t - INTRO_REVEAL + 0.1) / 0.15, 0.0, 1.0)
			etint = Color(etint.r * rv, etint.g * rv, etint.b * rv, etint.a)
		if state.enemy_calamity > 0:
			# A shape of darkness with a burning crimson edge while it arrives, then the
			# picture itself, a little cold and red (fable r2: the art was never shown)
			etint = Color(0.16, 0.05, 0.12, enemy_alpha) if intro_t >= 0.0 and intro_t < INTRO_REVEAL else Color(0.95, 0.85, 0.9, enemy_alpha)
			var glow := Color(0.95, 0.2, 0.25, (0.45 + 0.15 * sin(bob * 2.4)) * enemy_alpha)
			var one := 1.0 / _scr()  # one screen pixel, like the Mythic edge (fable r3: 2 design px was a mixel wireframe)
			for off in [Vector2(-one, 0), Vector2(one, 0), Vector2(0, -one), Vector2(0, one)]:
				draw_texture_rect(ewhite, Rect2(local.position + off, local.size), false, glow)
		else:
			draw_texture_rect(ewhite, Rect2(local.position + Vector2(0, -er.size.y / maxf(1.0, (art.get("size", Vector2(64, 64)) as Vector2).y)), local.size), false, Color(_rim_color(), 0.38 * enemy_alpha))
			# Mythic only: a thin steady edge in its colour, one screen pixel (fable r2: the 3 px pulsing
			# band read as a selection sticker; rank is the aura, pips and name colour)
			if state.enemy_tier >= 5 and not boss and not Realms.hides_tier(state):
				var one := 1.0 / _scr()
				for off in [Vector2(-one, 0), Vector2(one, 0), Vector2(0, -one), Vector2(0, one)]:
					draw_texture_rect(ewhite, Rect2(local.position + off, local.size), false, Color(Color(Monsters.tier_color(state.enemy_tier)), 0.55 * enemy_alpha))
		draw_texture_rect(etex, local, false, etint)
		if Combat.winding(state):
			# telegraph: it glows and shows a "!" while it gathers a big blow (Calamities too;
			# the glow holds still with flashes off; the "!" sits by its plate, not on its face)
			var wp := 0.5 + 0.5 * sin(bob * 12.0) if (profile == null or profile.flashes) else 0.5
			draw_texture_rect(ewhite, local, false, Color(1.0, 0.55, 0.1, (0.25 + 0.3 * wp) * enemy_alpha))
			var fnt := UI.game_font()
			var ex := _telegraph_at(er) - Vector2(40.0, 6.0 * wp)
			draw_string_outline(fnt, ex, "!", HORIZONTAL_ALIGNMENT_CENTER, 80, 48, 10, Color(0, 0, 0, enemy_alpha))
			draw_string(fnt, ex, "!", HORIZONTAL_ALIGNMENT_CENTER, 80, 48, Color(1.0, 0.7 + 0.3 * wp, 0.2, enemy_alpha))
		if enemy_flash > 0.0:
			draw_texture_rect(ewhite, local, false, _flash_col(enemy_flash, false, enemy_alpha))
		var name_color := Color("#fbbf24") if boss else Color("#fca5a5")
		if not boss and state.enemy_tier > 0:
			name_color = Color(Monsters.tier_color(state.enemy_tier)).lightened(0.15)
		if state.enemy_goblin:
			name_color = Color("#fde68a")
		var bar_color := Color("#f77622") if boss else Color("#e43b44")   # interface pass: palette.gpl torch / blood
		# UX pass (Juzo: names easy for everyone to read): just the name, coloured by
		# tier, with small diamond pips for elite tiers and dots for a pack, not extra words
		var label := state.enemy_name
		var pips := 0
		var veiled := Realms.hides_tier(state) and not boss
		if veiled:
			name_color = Color("#f9a8d4")
			label = "??? " + state.enemy_name
		elif state.enemy_calamity > 0:
			name_color = Color("#ff6b6b")
			pips = 3
		elif state.enemy_tier > 0 and not boss and not state.enemy_wanderer:
			pips = tier_pips(state.enemy_tier)
		if state.enemy_goblin:
			label += " (%d)" % state.goblin_turns
		var pack := Vector2i.ZERO
		if state.horde_left > 0 and not boss:
			pack = Vector2i(state.horde_total - state.horde_left + 1, state.horde_total)
		# The monster's plate is drawn after your team: the big 2.1 hero (one scale) stands in front of
		# the monster and would otherwise hide its name and health
		enemy_plate = func() -> void:
			# the top bar stays whole while the next one steps in (lead, Oct 26): its name, the new count
			var plate_a := 1.0 if _boss_stage() else enemy_alpha
			_draw_bar(er, label, state.enemy_hp, state.enemy_max_hp, bar_color, Color(name_color, plate_a), pips, pack)
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
	_draw_summon()
	_draw_members()     # Fable pets R3: members stand further back, so the front row (pets) draws over them
	_draw_menagerie()
	_draw_pet()
	_draw_hero()
	if state.enemy_calamity > 0 and not state.in_town:
		# the dimmed world takes the team in too (fable r3: they floated bright over the dark);
		# plates are drawn after this, so they stay crisp
		draw_rect(Rect2(-_off, size), Color(0.02, 0.0, 0.03, 0.2 * enemy_alpha))
	if enemy_plate.is_valid():
		enemy_plate.call()
	var hero_name := "HERO" if state.hero_class == "" else "%s  Lv %d" % [state.title(), state.level]
	Cosmetics.draw_frame(self, _bar_rect(hr), state.codex, bob)
	_draw_bar(hr, hero_name, state.hero_hp, state.get_max_hp(), Color("#63c74d"), Cosmetics.name_color(state.codex))
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
	_draw_drops()
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
		var t: float = 1.0 - r["life"] / float(r.get("max", 0.25))
		draw_arc(r["pos"], 8.0 + t * float(r.get("grow", 26.0)), 0.0, TAU, 24, Color(r.get("color", Color(0.58, 0.77, 0.99)), 1.0 - t), 3.0)

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
		var bl := _banner_line()   # x, baseline, width (fable r4: off the boss name)
		var bfs := 26  # long names shrink to fit the screen
		while bfs > 14 and font.get_string_size(banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x > bl.size.x - 20.0:
			bfs -= 1
		draw_string_outline(font, bl.position + Vector2(slide, 0), banner_text, HORIZONTAL_ALIGNMENT_CENTER, bl.size.x, bfs, 6, Color(0, 0, 0, a))
		draw_string(font, bl.position + Vector2(slide, 0), banner_text, HORIZONTAL_ALIGNMENT_CENTER, bl.size.x, bfs, Color(big_color, a))
		var sfs := 13  # the line under it shrinks to fit too
		while sfs > 9 and font.get_string_size(banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x > bl.size.x - 12.0:
			sfs -= 1
		draw_string_outline(font, bl.position + Vector2(-slide, 17), banner_sub, HORIZONTAL_ALIGNMENT_CENTER, bl.size.x, sfs, 3, Color(0, 0, 0, 0.8 * a))
		draw_string(font, bl.position + Vector2(-slide, 17), banner_sub, HORIZONTAL_ALIGNMENT_CENTER, bl.size.x, sfs, Color(1, 1, 1, 0.85 * a))

	_draw_team_strip(font)
	_draw_intro(font, w, h)

	# Tip toast at the top
	toast_room = 0.0
	if toast_life > 0.0:
		# A slim strip along the bottom edge: never over the fighters or their plates
		var ta := clampf(minf(toast_life, 6.0 - toast_life) * 4.0, 0.0, 1.0)
		var tw := w - 16.0
		# Fable r2 #3: body size (20, was a raw 12 = 9 pt on an SE), up to two lines, bone on ink
		var fs := UI.FONT_BODY
		var lines := minf(font.get_multiline_string_size(toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw - 24, fs).y, 2.0 * font.get_height(fs))
		var box := Rect2(8, h - lines - 14.0, tw, lines + 10.0)
		toast_room = lines
		draw_rect(box, Color(0.04, 0.05, 0.10, 0.92 * ta))
		draw_rect(Rect2(box.position, Vector2(3, box.size.y)), Color(0.91, 0.69, 0.29, ta))
		draw_multiline_string(font, Vector2(box.position.x + 12, roundf(box.position.y + 5 + font.get_ascent(fs))), toast_text, HORIZONTAL_ALIGNMENT_CENTER, tw - 24, fs, 2, Color(UI.TEXT, ta))

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
		if hero_has_aura:
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
	if hero_art.has("anims"):
		_draw_anim_hero(c, u, a, glow)
		return
	var poses := _hero_poses()
	var pose: Dictionary = poses.get(hero_pose, {})
	# Rim light: the zone's light catches the top edge of the silhouette
	draw_texture_rect(pose.get("white", hero_art["body_white"]), Rect2(c.position + Vector2(0, -u), c.size), false, Color(_rim_color(), 0.42 * a))
	draw_texture_rect(pose.get("tex", hero_art["body"]), c, false, Color(1, 1, 1, a))
	if hero_flash > 0.0:
		draw_texture_rect(pose.get("white", hero_art["body_white"]), c, false, _flash_col(hero_flash, true))
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
			draw_texture(hero_art["weapon_white"], -piv, _flash_col(hero_flash, true))
		draw_set_transform(_off)

## A called helper (Raise Dead's skeleton, Call of the Wild's wolf) stands at the hero's
## left as a pale spirit while it lasts, and steps in when it strikes.
func _draw_summon() -> void:
	if state == null or summon_in <= 0.01:
		return
	var key := "revenant" if state.summon_name == "Skeleton" else "barghest"
	var art := Sprites.enemy_by_key(key)
	if not art.has("tex"):
		art = Sprites.enemy_by_key("draugr" if key == "revenant" else "garmr")
	if not art.has("tex"):
		return
	var tex: Texture2D = art["tex"]
	var white: Texture2D = art["white"]
	var asz: Vector2 = art["size"]
	var hc := _hero_canvas()
	var h := hc.size.y * 0.5
	var w := h * asz.x / asz.y
	var feet := Vector2(hc.position.x + hc.size.x * 0.12, _team_ground() - h * 0.06)
	feet += Vector2(summon_lunge * w * 0.25, -summon_lunge * size.y * 0.08)
	var r := Rect2(_snap(feet - Vector2(w / 2.0, h)), Vector2(w, h))
	var a := summon_in * hero_alpha
	var glow := Color("#a78bfa") if key == "revenant" else Color("#86efac")
	draw_set_transform(Vector2(r.get_center().x, r.end.y), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, w * 0.4, Color(glow, 0.18 * a))
	draw_set_transform(Vector2.ZERO)
	for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2)]:
		draw_texture_rect(white, Rect2(r.position + off, r.size), false, Color(glow, (0.35 + 0.15 * sin(bob * 4.0)) * a))
	draw_texture_rect(tex, r, false, Color(0.7, 0.75, 1.0, 0.7 * a))

## The companion stands behind the hero (art/pets/32, Pets 2), a size smaller, breathing (2-frame idle).
func _draw_pet() -> void:
	if state == null or not state.pet_on or World.pet_stage(state) < 0:
		return
	var tex := Pets.portrait_frame(state, bob)
	if tex == null:
		return
	var pu := _u()
	var s := float(tex.get_width()) * pu
	var x: float = team_layout().get(-1, 0.0)
	# a shadow on the ground like every pet (it stays down while the companion hops)
	draw_set_transform(Vector2(x + s / 2.0, _team_ground()), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, s * 0.3 * (1.0 - 0.3 * pet_lunge), Color(0, 0, 0, 0.35 * hero_alpha))
	draw_set_transform(Vector2.ZERO)
	# feet on the ground: the 32 px still's bottom row (the idle strip does the breathing)
	var y := _team_ground() - (Pets.foot(Pets.companion_key(state)) + 1) * pu - pet_lunge * size.y * 0.1
	draw_texture_rect(tex, Rect2(_snap(Vector2(x, y)), Vector2(s, s)), false, Color(1, 1, 1, hero_alpha))

## A frame-animated hero: the current animation frame, with rim light, weapon glow and hit flash.
func _draw_anim_hero(c: Rect2, u: float, a: float, glow: Color) -> void:
	var anims: Dictionary = hero_art["anims"]
	var an: Dictionary = anims.get(hero_anim, anims.get("combat_idle", {}))
	if an.is_empty():
		return
	var tex: Array = an["tex"]
	var n := tex.size()
	var fi := int(hero_anim_t * float(an["fps"]))
	fi = fi % n if hero_anim == "combat_idle" else mini(fi, n - 1)
	var s: int = an["size"]
	var off := Vector2(Sprites.BODY_OFFSET) - Vector2((s - HeroArt.CORE) / 2, (s - HeroArt.CORE) / 2)
	var r := squashed(Rect2(c.position + off * u, Vector2(s, s) * u), hero_squash)
	var white: Texture2D = an["white"][fi]
	if glow.a > 0.0:  # around the weapon only (the whole-hero outline hid the hair and the rim light)
		var ww: Array = HeroArt.weapon_white(an)
		var gw: Texture2D = ww[fi] if fi < ww.size() else white
		var pulse := 0.22 + 0.1 * sin(bob * 4.0)
		for d in [Vector2(-u, 0), Vector2(u, 0), Vector2(0, -u), Vector2(0, u)]:
			draw_texture_rect(gw, Rect2(r.position + d, r.size), false, Color(glow, pulse * a))
	# rim light: strong from above, fainter on both sides, so a dark hero still reads on a dark floor
	draw_texture_rect(white, Rect2(r.position + Vector2(0, -u), r.size), false, Color(_rim_color(), 0.6 * a))
	for d in [Vector2(-u, 0), Vector2(u, 0)]:
		draw_texture_rect(white, Rect2(r.position + d, r.size), false, Color(_rim_color(), 0.3 * a))
	draw_texture_rect(tex[fi], r, false, Color(1, 1, 1, a))
	if hero_flash > 0.0:
		draw_texture_rect(white, r, false, _flash_col(hero_flash, true))

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
	# a soft pool at its feet like the boss glow (fable r3: three hard discs read as a sticker)
	_soft_glow(r, c, (0.04 + 0.02 * tier) * (0.85 + 0.15 * pulse) * enemy_alpha)
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
	var font := UI.game_font()   # interface pass: the game font everywhere
	if _boss_stage():
		return   # with the statuses under the boss plate (_boss_chip_layout)
	var x := r.get_center().x
	var y := _bar_rect(r).position.y - 15.0   # just above the monster's bar, wherever the bar sits
	var total := 0.0
	var widths: Array = []
	for m in state.enemy_mods:
		var wdt := font.get_string_size(str(m), HORIZONTAL_ALIGNMENT_LEFT, -1, SCENE_FS).x + 12.0
		widths.append(wdt)
		total += wdt + 4.0
	var cx := clampf(x - total / 2.0, 4.0, size.x - total - 4.0)
	for i in state.enemy_mods.size():
		var m: String = state.enemy_mods[i]
		var c := Color(Monsters.MODS[m]["color"])
		var box := Rect2(cx, y - 18.0, widths[i], 24.0)
		draw_rect(box, Color(0.03, 0.04, 0.08, 0.85 * enemy_alpha))
		draw_rect(box, Color(c, 0.8 * enemy_alpha), false, 1.0)
		draw_string(font, Vector2(cx + 6.0, y), m, HORIZONTAL_ALIGNMENT_LEFT, -1, SCENE_FS, Color(c, enemy_alpha))
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
		var wdt := font.get_string_size(c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, SCENE_FS).x + 12.0
		draw_rect(Rect2(x, 34, wdt, 24), Color(0.03, 0.04, 0.08, 0.8))
		draw_rect(Rect2(x, 34, wdt, 24), c[1], false, 1.0)
		draw_string(font, Vector2(x + 6, 52), c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, SCENE_FS, c[1])
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
	# the zone's light from HallsScene.MOODS (palette colours), like the room and SpriteLight
	return HallsScene.MOODS[clampi(GameData.zone_index(state.floor_num), 0, HallsScene.MOODS.size() - 1)]["light"]

func draw_ellipse_shadow(r: Rect2) -> void:
	var c := Vector2(r.get_center().x, r.end.y - 2.0)  # under the feet (monsters now stand at different heights)
	draw_set_transform(c + _off, 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, r.size.x * 0.38, Color(0, 0, 0, 0.35))
	draw_set_transform(_off)

## The lowest a team plate's bar may sit: above the message strip, and above a tip while
## one shows (fable r2: a two-line hazard tip covered "Warrior Lv 30").
func _plate_floor() -> float:
	return minf(size.y - 68.0, size.y - toast_room - 58.0)

## A boss's or Calamity's light: a soft glow pooled on the ground at its feet (squashed like
## the shadow) and a faint wash up its body, fading out over 8 rings instead of a hard disc.
func _soft_glow(er: Rect2, col: Color, peak: float) -> void:
	var feet := Vector2(er.get_center().x, er.end.y - 2.0)
	draw_set_transform(feet + _off, 0.0, Vector2(1.0, 0.25))
	for i in 8:
		draw_circle(Vector2.ZERO, er.size.x * (0.9 - 0.05 * i), Color(col, peak * 0.25))
	draw_set_transform(_off)
	for i in 8:
		draw_circle(er.get_center(), er.size.x * (0.9 - 0.05 * i), Color(col, peak * 0.05))

## The fighter's plate under its feet: health bar, then the name. Keeping it
## below the ground line means it never covers the art, banners or numbers.
func _bar_rect(r: Rect2) -> Rect2:
	var bw := clampf(r.size.x * 0.85, 130.0, size.x * 0.4)
	var bx := clampf(r.get_center().x - bw / 2.0, 6.0, size.x - bw - 6.0)
	# Monsters (at the back) get theirs under their feet; your team (in front) above their heads
	if r.get_center().y > size.y * 0.62:
		var beside := r.get_center().x + r.size.x * 0.32 + 8.0   # the drawn body is about 0.6 of this box wide
		var low := _plate_floor()
		var left := r.get_center().x - r.size.x * 0.32 - 8.0
		if maxf(r.end.y, _team_ground()) + 8.0 > low:
			# Phone sweep: the 2.1 hero's feet stand on the team line, under this box; a plate that
			# can't fit under them goes beside the hero (the approved fight mockup), never over the boots:
			# right if it fits, else left, else narrowed to the roomier side.
			# Fable pets R2: when a pet stands there, the plate goes over its head, not over the pet
			var y := low
			if not team_layout().is_empty():
				y = minf(y, _team_ground() - 32.0 * _u() - NAME_FS - 30.0)
			# a tall common stands right of the hero (fable r4): its side is taken, try the left first
			if _tall_common() and left - bw >= 6.0:
				return Rect2(left - bw, y, bw, 14.0)
			if beside + bw <= size.x - 6.0:
				return Rect2(beside, y, bw, 14.0)
			if left - bw >= 6.0:
				return Rect2(left - bw, y, bw, 14.0)
			var room_r := size.x - 6.0 - beside
			var room_l := left - 6.0
			var w := maxf(room_r, room_l)
			return Rect2(beside if room_r >= room_l else 6.0, y, maxf(w, 80.0), 14.0)
		return Rect2(bx, minf(r.end.y + 8.0, low), bw, 14.0)   # room for the name above the message strip
	if _boss_stage() and r.get_center().y <= size.y * 0.62:
		return _boss_bar()
	# ...and the monster's plate stays clear of the hero's head (it sat on it on a short stage)
	return Rect2(bx, minf(_ground() + 9.0, _hero_rest_top() - 44.0), bw, 14.0)

## In-scene text sizes (design px; x0.85 on a 430 pt phone): names and numbers 18 (~15 pt).
const NAME_FS := 18
const SCENE_FS := 18

## Text with a dark outline and a soft drop shadow: readable on any background.
func _outlined(font: Font, pos: Vector2, text: String, align: HorizontalAlignment, width: float, fs: int, col: Color) -> void:
	var a := col.a
	draw_string_outline(font, pos + Vector2(0, 2), text, align, width, fs, 5, Color(0, 0, 0, 0.5 * a))
	draw_string_outline(font, pos, text, align, width, fs, 5, Color(0.04, 0.03, 0.06, 0.95 * a))
	draw_string(font, pos, text, align, width, fs, col)

## Shortens a name with "..." so it never wraps or runs off the plate.
func _fit_text(font: Font, text: String, fs: int, max_w: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_w:
		return text
	var t := text
	while t.length() > 3 and font.get_string_size(t + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		t = t.left(t.length() - 1)
	return t.strip_edges() + "..."

## A small outlined diamond (an elite tier pip).
func _pip(c: Vector2, rad: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad - 1.5), c + Vector2(rad + 1.5, 0), c + Vector2(0, rad + 1.5), c + Vector2(-rad - 1.5, 0)]), Color(0.04, 0.03, 0.06, col.a))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad, 0), c + Vector2(0, rad), c + Vector2(-rad, 0)]), col)

func _draw_bar(r: Rect2, label: String, value: int, max_value: int, fill: Color, label_color: Color, pips := 0, pack := Vector2i.ZERO) -> void:
	var font := UI.game_font()   # interface pass: the game font everywhere
	var b := _bar_rect(r)
	var a := label_color.a
	var pct := clampf(float(value) / maxf(1.0, max_value), 0.0, 1.0)
	# Interface pass: a plate behind the bar and the name, so both read on any backdrop
	# (ink fill, slate line, #0e0812 outline: the same frame as every panel)
	var pextra := (pips * 12.0 + 6.0 if pips > 0 else 0.0) + (_pack_badge_w(font, pack) if pack.y > 0 else 0.0)
	var pw := maxf(b.size.x, font.get_string_size(_fit_text(font, label, NAME_FS, minf(b.size.x + 100.0, size.x - 12.0) - pextra), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FS).x + pextra) + 16.0
	var plate := Rect2(clampf(b.get_center().x - pw / 2.0, 2.0, maxf(2.0, size.x - pw - 2.0)), b.position.y - 6.0, pw, b.size.y + NAME_FS + 16.0)
	draw_rect(plate, Color(UiSkin.SOOT, 0.9 * a))
	draw_rect(plate.grow(-2.0), Color(UiSkin.IRON, 0.9 * a))
	draw_rect(plate.grow(-4.0), Color(Color("#181425"), 0.88 * a))
	# frame, track, fill with a lighter top line, then a recent-damage ghost
	draw_rect(b.grow(2.0), Color(UiSkin.SOOT, a))
	draw_rect(b, Color(Color("#120e1c"), a))
	var fw := (b.size.x) * pct
	# The ghost: health just lost stays as a pale strip that drains away (_process),
	# so every hit reads clearly. Healing moves it straight up.
	var ghost: float = maxf(float(bar_ghost.get(label, pct)), pct)
	bar_ghost[label] = ghost
	bar_target[label] = pct
	if ghost > pct + 0.001:
		draw_rect(Rect2(b.position + Vector2(fw, 0), Vector2(b.size.x * (ghost - pct), b.size.y)), Color(1.0, 0.92, 0.7, 0.75 * a))
	draw_rect(Rect2(b.position, Vector2(fw, b.size.y)), Color(fill.darkened(0.15), a))
	draw_rect(Rect2(b.position, Vector2(fw, 3.0)), Color(fill.lightened(0.35), a))
	_outlined(font, Vector2(b.position.x, b.position.y + b.size.y * 0.5 + SCENE_FS * 0.36), "%s / %s" % [_short(maxi(value, 0)), _short(max_value)], HORIZONTAL_ALIGNMENT_CENTER, b.size.x, SCENE_FS, Color(1, 1, 1, a))
	# The name on its own line under the bar (never over the sprite), one line only
	var extra := (pips * 12.0 + 6.0 if pips > 0 else 0.0) + (_pack_badge_w(font, pack) if pack.y > 0 else 0.0)
	var max_w := minf(b.size.x + 100.0, size.x - 12.0) - extra
	var shown := _fit_text(font, label, NAME_FS, max_w)
	var tw := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FS).x
	var total := tw + extra
	var x0 := clampf(b.get_center().x - total / 2.0, 6.0, maxf(6.0, size.x - total - 6.0))
	var ny := b.end.y + 5.0 + NAME_FS
	for i in pips:
		_pip(Vector2(x0 + 5.0 + i * 12.0, ny - NAME_FS * 0.36), 4.0, label_color)
	var tx := x0 + (pips * 12.0 + 6.0 if pips > 0 else 0.0)
	_outlined(font, Vector2(tx, ny), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FS, label_color)
	if pack.y > 0:
		# a pack: which one this is, "1 of 3" (Juzo, Oct 26: one on stage, the rest off it)
		var bt := _pack_badge(pack)
		var bw := font.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, PACK_FS).x + 10.0
		var box := Rect2(tx + tw + 8.0, ny - PACK_FS - 3.0, bw, PACK_FS + 6.0)
		var bc := Color("#fca5a5")
		draw_rect(box, Color(0.03, 0.04, 0.08, 0.85 * a))
		draw_rect(box, Color(bc, 0.85 * a), false, 1.0)
		draw_string(font, Vector2(box.position.x + 5.0, box.position.y + PACK_FS + 1.0), bt, HORIZONTAL_ALIGNMENT_LEFT, -1, PACK_FS, Color(bc, a))

const PACK_FS := 15

## The pack badge's words: which one of the pack this is ("1 of 3"; lead, Oct 26).
static func _pack_badge(pack: Vector2i) -> String:
	return "%d of %d" % [pack.x, pack.y]

func _pack_badge_w(font: Font, pack: Vector2i) -> float:
	return font.get_string_size(_pack_badge(pack), HORIZONTAL_ALIGNMENT_LEFT, -1, PACK_FS).x + 18.0

## 1234567 -> "1.23M" so bars stay readable.
func _short(v: int) -> String:
	if v >= 10000000:
		return "%.1fM" % (v / 1000000.0)
	if v >= 1000000:
		return "%.2fM" % (v / 1000000.0)
	if v >= 100000:
		return "%dk" % int(v / 1000.0)
	if v >= 10000:
		return "%.1fk" % (v / 1000.0)  # fable r3: five digits overflowed a common's plate
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
func _chip_row(chips: Array, x: float, y: float, font: Font, fs := SCENE_FS) -> void:
	if chips.is_empty():
		return
	# Too many for one line: the rest wrap onto lines ABOVE (the row below stays clear)
	var lines: Array = [[]]
	var line_w: Array = [0.0]
	for c in chips:
		var wdt := font.get_string_size(String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 10.0
		if not (lines[-1] as Array).is_empty() and float(line_w[-1]) + wdt > size.x - 8.0:
			lines.append([])
			line_w.append(0.0)
		(lines[-1] as Array).append([c, wdt])
		line_w[-1] = float(line_w[-1]) + wdt + 4.0
	for li in lines.size():
		var total: float = line_w[li]
		var cx := clampf(x - total / 2.0, 4.0, maxf(4.0, size.x - total - 4.0))
		var ly := y - li * (fs + 9.0)
		for item in lines[li]:
			var c: Array = item[0]
			var wdt: float = item[1]
			_chip_box(c, Rect2(cx, ly, wdt, fs + 6.0), font, fs)
			cx += wdt + 4.0

## One chip: [text, colour] in a dark box.
func _chip_box(c: Array, box: Rect2, font: Font, fs: int) -> void:
	var col: Color = c[1]
	draw_rect(box, Color(0.03, 0.04, 0.08, 0.82))
	draw_rect(box, Color(col, 0.85), false, 1.0)
	draw_string(font, Vector2(box.position.x + 5.0, box.position.y + fs + 1.0), String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

## The monster's statuses and boss clock as chips: [text, colour].
func _enemy_statuses() -> Array:
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
	if state.enemy_grave:
		st.append(["Wears your gear", Color("#fbbf24")])
	if state.enemy_peaceful:
		st.append(["Friendly", Color("#4ade80")])
	var wl := Wanderers.turns_left(state)
	if wl >= 0:
		st.append(["Leaves in %d" % wl, Color("#fde68a")])
	var hz := Hazards.turns_left(state)
	if hz >= 0 and Hazards.KINDS.has(state.hazard):
		var hk: Dictionary = Hazards.KINDS[state.hazard]
		st.append(["%s in %d" % [hk["name"], hz], Color(hk["color"])])
	if Combat.winding(state):
		st.append(["WINDING UP", Color("#f59e0b")])
	var el := Combat.enrage_left(state)
	if el > 0:
		st.append(["Enrage in %d" % el, Color("#ef4444")])
	elif el == 0:
		st.append(["ENRAGED", Color("#ef4444")])
	if state.boss_minions > 0:
		st.append(["Minions x%d" % state.boss_minions, Color("#d4d4d4")])
	return st

## The boss stage's chips (statuses, then mods) in one centred row right under the boss plate:
## [[chip, Rect2], ...]. Once a frame. One row only, so the room _rect_for keeps (BOSS_GAP)
## never changes (fable r5): a long row drops to 15 px, then its last mods fold into "+N".
func _boss_chip_layout() -> Array:
	var fr := Engine.get_process_frames()
	if fr == _chip_frame:
		return _chip_lay
	_chip_frame = fr
	_chip_lay = []
	if state == null or not _boss_stage():
		return _chip_lay
	var chips := _enemy_statuses()
	var n_st := chips.size()
	for m in state.enemy_mods:
		chips.append([m, Color(Monsters.MODS[m]["color"])])
	var font := UI.game_font()
	_chip_fs = SCENE_FS
	var folded := 0
	while _chips_width(chips, font, _chip_fs) > size.x - 16.0:
		if _chip_fs > 15:
			_chip_fs = 15
		elif chips.size() - (1 if folded > 0 else 0) > n_st:
			if folded > 0:
				chips.pop_back()
			chips.pop_back()
			folded += 1
			chips.append(["+%d" % folded, Color("#d4d4d4")])
		else:
			break
	var cx := (size.x - _chips_width(chips, font, _chip_fs)) / 2.0
	var y := _boss_bar().end.y + BOSS_NAME + 2.0
	for c in chips:
		var wdt := font.get_string_size(String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_fs).x + 10.0
		_chip_lay.append([c, Rect2(cx, y, wdt, _chip_fs + 6.0)])
		cx += wdt + 4.0
	return _chip_lay

func _chips_width(chips: Array, font: Font, fs: int) -> float:
	var total := -4.0
	for c in chips:
		total += font.get_string_size(String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14.0
	return total

var _chip_frame := -1
var _chip_lay: Array = []
var _chip_fs := SCENE_FS
const CHIP_ROW := 28.0

## Design px the boss-stage chip rows take under the plate (0 with none).
func _boss_chip_room() -> float:
	var lay := _boss_chip_layout()
	if lay.is_empty():
		return 0.0
	return (lay[-1][1] as Rect2).end.y + 4.0 - (_boss_bar().end.y + BOSS_NAME)

## The monster's statuses and its boss clock. (Juzo, Oct 24: weaknesses and
## resistances live in the Codex only, not over the monster in the fight.)
func _draw_enemy_info(r: Rect2, font: Font) -> void:
	var st := _enemy_statuses()
	if _boss_stage():
		# Boss stage: statuses and mods in rows right under the plate; the boss stands lower by
		# that much (fable r4: a right-edge column sat on its shoulder)
		for it in _boss_chip_layout():
			_chip_box(it[0], it[1], font, _chip_fs)
		return
	var top := maxf(34.0, r.position.y - 6.0)
	_chip_row(st, r.get_center().x, top - 30.0, font)

## Your statuses (poison, burns, chill) over your head.
func _draw_hero_status(r: Rect2, font: Font) -> void:
	var chips: Array = []
	for k in state.hero_status:
		var info: Dictionary = Combat.STATUS_INFO.get(k, {})
		if not info.is_empty():
			var stk := int(state.hero_stacks.get(k, 1))
			chips.append(["%s%s %d" % [info["name"], (" x%d" % stk) if stk > 1 else "", int(state.hero_status[k])], Color(info["color"])])
	if state.bag_full() and not state.in_town:
		chips.append(["BAG FULL: sell to use new drops" if state.bag.size() < state.bag_capacity() + GameState.OVERFLOW_MAX else "BAG OVERFLOWING: drops become scrap", Color("#f87171")])
	# UX pass: down the left edge at chest height, so they never sit on the monster's name plate
	for i in chips.size():
		_chip_row([chips[i]], 0.0, r.position.y + 12.0 + i * (SCENE_FS + 10.0), font)

## Your menagerie pets on the run (caught or hatched), at the hero's right: their own
## baby art (art/pets/32) at true size, breathing, feet on the team's ground. Cherished ones glow.
func _draw_menagerie() -> void:
	if state == null or state.in_town:
		return
	var pets := _team_out()
	if pets.is_empty():
		return
	var pu := _u()
	var w := 32.0 * pu
	var lay := team_layout()
	var hx := _hero_canvas().get_center().x   # hops lean toward the hero
	for i in pets.size():
		var p: Dictionary = pets[i]
		var key := String(p.get("species", ""))
		var tex := Pets.frame(key, bob + i * 0.23 + 0.17)   # out of step with each other and the companion
		if tex == null:
			continue
		# a hit is a hop: an arc over the 0.3 s (pet_hits counts down), a little toward the hero
		var hop := sin(clampf(float(pet_hits.get(int(p["id"]), 0.0)) / 0.3, 0.0, 1.0) * PI)
		var x0 := float(lay.get(i, 0.0)) + w / 2.0
		var feet := Vector2(x0 + signf(hx - x0) * hop * 4.0 * pu, _team_ground() - hop * 6.0 * pu)
		var r := Rect2(_snap(feet - Vector2(w / 2.0, (Pets.foot(key) + 1) * pu)), Vector2(w, w))
		draw_set_transform(Vector2(x0, _team_ground()), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, w * 0.3 * (1.0 - 0.3 * hop), Color(0, 0, 0, 0.35 * hero_alpha))
		draw_set_transform(Vector2.ZERO)
		if p.get("cherished", false):
			var gl := 0.25 + 0.15 * sin(bob * 3.0 + i)
			for off in [Vector2(-pu, 0), Vector2(pu, 0), Vector2(0, -pu)]:
				draw_texture_rect(Pets.white(key), Rect2(r.position + off, r.size), false, Color(1.0, 0.85, 0.4, gl * hero_alpha))
		draw_texture_rect(tex, r, false, Color(1, 1, 1, hero_alpha))  # hurt pets stay home (Menagerie.out)

## Who lunges for a summon_hit (Fable pets R4): the summon, the class companion (its hits carry no
## "pet"), or nobody (a menagerie pet hops through pet_hits instead).
static func who_lunges(e: Dictionary, summon_name: String, summon_turns: int, companion_out: bool) -> String:
	if summon_turns > 0 and String(e.get("name", "")) == summon_name:
		return "summon_lunge"
	if not e.has("pet") and companion_out:
		return "pet_lunge"
	return ""

## Over the head of menagerie pet id (Vector2.INF if it isn't out).
func _pet_head(id: int) -> Vector2:
	var pets := _team_out()
	for i in pets.size():
		if int(pets[i]["id"]) == id:
			return Vector2(float(team_layout().get(i, 0.0)) + 16.0 * _u(), _team_ground() - 36.0 * _u())
	return Vector2.INF   # not out (hurt, swapped): nothing floats over the hero by mistake

## A pet's trick: its name over its head in its rank colour, and a hop.
func _pet_trick(e: Dictionary, delay: float) -> void:
	var id := int(e["pet"])
	var col := Color(Menagerie.TIER_COLORS[clampi(int(e.get("tier", 0)), 0, 5)])
	var label := String(e.get("label", e.get("name", "")))
	_later(delay, func():
		var head := _pet_head(id)
		if head == Vector2.INF:
			return
		_sfx("buff")
		pet_hits[id] = 0.3
		_float(label.to_upper() + "!", head, col, 15))

## Where the team stands (Fable pets R2): the left edge x of each 32 px creature, keyed -1 for
## the class companion and 0.. for menagerie pets, companion first (Pets.row).
var _lay := {}
var _lay_frame := -1

func team_layout() -> Dictionary:
	# once a frame: the pets, the companion and the hero plate all ask
	_frame_cache()
	return _lay

var _out: Array = []

## The pets out this frame (Menagerie.out once a frame, Fable pets R4).
func _team_out() -> Array:
	_frame_cache()
	return _out

func _frame_cache() -> void:
	var fr := Engine.get_process_frames()
	if fr == _lay_frame:
		return
	_lay_frame = fr
	_out = Menagerie.out(state) if state != null else []
	_lay = _team_layout()

func _team_layout() -> Dictionary:
	var who: Array = []
	if state != null and state.pet_on and World.pet_stage(state) >= 0:
		who.append(-1)
	if state != null and not state.in_town:
		for i in _team_out().size():
			who.append(i)
	var pu := _u()
	var hc := _hero_canvas()
	# party members' bodies (Fable pets R3): nobody stands more than half behind one
	var taken: Array = []
	for i in _party_members().size():
		var mc := _member_canvas(i).get_center().x
		taken.append([mc - 16.0 * pu, mc + 16.0 * pu])
	# Fable pets R5: a monster whose feet come down near the team row (staging changes) keeps its middle clear
	if state != null and state.enemy_hp > 0 and not state.in_town:
		var er := _enemy_rect(state.enemy_is_boss)
		if absf(er.end.y - _team_ground()) < size.y * 0.1:
			taken.append([er.position.x + er.size.x * 0.25, er.end.x - er.size.x * 0.25])
	var first := ""
	if not who.is_empty():
		first = Pets.companion_key(state) if int(who[0]) == -1 else String(_team_out()[0].get("species", ""))
	var xs := Pets.row(who.size(), hc.get_center().x, hc.size.x, 32.0 * pu, 2.0 * pu, size.x, Pets.width(first) > 24, taken)
	var out := {}
	for k in who.size():
		out[who[k]] = xs[k]
	return out

var _strip_pics := {}
## With companions: a compact strip at the top-left, a portrait, name and HP bar for
## each hero, so you can read the whole team's health at a glance.
func _draw_team_strip(font: Font) -> void:
	if state == null or state.party == null or state.party.size() == 0 or state.in_town:
		return
	var rows: Array = [[state, state.hero_hp, state.get_max_hp(), state.leader_down, "you"]]
	for m in state.party.members:
		rows.append([m.hero, m.hp, m.max_hp(), m.knocked_out, "m%d" % m.slot])
	var boxes := _team_strip_rects(rows.size())
	for ri in (0 if _boss_stage() else rows.size()):
		var r: Array = rows[ri]
		var box: Rect2 = boxes[ri]
		var x := box.position.x
		var y := box.position.y
		var cw := box.size.x
		var g: GameState = r[0]
		var key: String = r[4]
		if not _strip_pics.has(key):
			_strip_pics[key] = Sprites.portrait(g.appearance, g.hero_looks())
		draw_rect(box, Color(0.03, 0.04, 0.08, 0.78))
		draw_rect(box, Color(Color(g.class_info().get("color", "#94a3b8")), 0.7), false, 1.0)
		var pic: Texture2D = _strip_pics[key]
		var down: bool = r[3]
		if pic:
			draw_texture_rect(pic, Rect2(x + 4, y + 4, box.size.y - 8.0, box.size.y - 8.0), false, Color(1, 1, 1, 0.4 if down else 1.0))
		var pct := clampf(float(r[1]) / maxf(1.0, float(r[2])), 0.0, 1.0)
		var tx := x + box.size.y
		var bw := cw - box.size.y - 2.0
		var bh := 7.0 if box.size.y >= 36.0 else 6.0
		var bar_y := y + box.size.y - 11.0
		var nm: String = "DOWN" if down else (g.hero_name if g.hero_name != "" else g.hero_class)  # knocked out: the plate says so in place of the name
		draw_string(font, Vector2(tx, y + roundf(box.size.y * 0.45)), _fit_text(font, nm, UI.MIN_FONT, bw), HORIZONTAL_ALIGNMENT_LEFT, bw, UI.MIN_FONT, Color("#f87171") if down else Color(1, 1, 1, 0.9))
		draw_rect(Rect2(tx, bar_y, bw, bh), Color(0.1, 0.1, 0.14))
		var col := Color("#22c55e") if pct > 0.5 else (Color("#eab308") if pct > 0.25 else Color("#ef4444"))
		draw_rect(Rect2(tx, bar_y, bw * pct, bh), Color(0.4, 0.4, 0.4) if down else col)
	var tsl := Synergies.strike_left(state)
	if tsl > 0:
		var sb: Rect2 = boxes[-1]
		var lines: PackedStringArray = _strike_lines(font, tsl, sb.size.x)
		for li in lines.size():
			var at := Vector2(sb.position.x, sb.position.y + 14.0 + li * 18.0)
			draw_string_outline(font, at, lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, UI.MIN_FONT, 3, Color(0, 0, 0, 0.9))
			draw_string(font, at, lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, UI.MIN_FONT, Color("#fbbf24"))

## "Team Strike in N" on one line, or two when the strip is too narrow for it.
func _strike_lines(font: Font, left: int, w: float) -> PackedStringArray:
	var one := "Team Strike in %d" % left
	if font.get_string_size(one, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.MIN_FONT).x <= w:
		return PackedStringArray([one])
	return PackedStringArray(["Team Strike", "in %d" % left])

## The team strip's boxes, one 36 px row per hero along the top (UX: 15 px name), then the Team
## Strike line's box (n + 1 rects). The face-off has no rows (Juzo via lead, Oct 26: they
## covered the monster's bar, pets r5, and the SE has no room beside it; the over-head plates
## and the hero plate show everyone's health), only the Team Strike line just over the hero plate.
func _team_strip_rects(n: int) -> Array:
	var out: Array = []
	if _boss_stage():
		var hp := _bar_rect(_hero_rect())
		var lines := _strike_lines(UI.game_font(), 9, hp.size.x).size()
		var h := 18.0 * lines
		out.append(Rect2(hp.position.x, hp.position.y - h - 4.0, hp.size.x, h))
		return out
	var w := minf(132.0, (size.x - 12.0) / n - 4.0)
	for i in n:
		out.append(Rect2(6.0 + i * (w + 4.0), 26.0, w, 36.0))
	out.append(Rect2(6.0, 66.0, size.x - 12.0, 18.0))
	return out

## The burn on a kill (fable r5): a canvas shader eats the dying pose in a noisy order, top
## first, with a glowing edge just ahead of the hole. It draws into a small viewport, one texel
## per art pixel, and _draw shows that like any picture: nothing is cut on the CPU.
const BURN_SHADER := """
shader_type canvas_item;
uniform sampler2D noise : filter_nearest, repeat_enable;
uniform float cut = 0.0;
uniform vec4 edge : source_color = vec4(1.0, 0.6, 0.3, 1.0);
uniform vec2 shift = vec2(0.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float n = texture(noise, (floor(UV / TEXTURE_PIXEL_SIZE) + 0.5 + shift) / 64.0).r * 0.7 + (1.0 - UV.y) * 0.3;
	if (n < cut) {
		discard;
	}
	if (n < cut + 0.08) {
		c.rgb = edge.rgb;
	}
	COLOR = c;
}
"""
var _burn_vp: SubViewport
var _burn_pic: TextureRect

## Makes the burn's viewport once (on the first kill) and points it at the new corpse.
func _burn_setup() -> void:
	if not dying.has("tex"):
		return
	if _burn_vp == null:
		var noise := FastNoiseLite.new()
		noise.frequency = 0.12
		var sh := Shader.new()
		sh.code = BURN_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("noise", ImageTexture.create_from_image(noise.get_seamless_image(64, 64)))
		_burn_vp = SubViewport.new()
		_burn_vp.transparent_bg = true
		_burn_vp.disable_3d = true
		_burn_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_burn_pic = TextureRect.new()
		_burn_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_burn_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_burn_pic.material = mat
		_burn_vp.add_child(_burn_pic)
		add_child(_burn_vp)
	var tex: Texture2D = dying["tex"]
	var sz := Vector2i(tex.get_size())
	_burn_vp.size = sz
	_burn_pic.size = Vector2(sz)
	_burn_pic.texture = tex
	var mat := _burn_pic.material as ShaderMaterial
	mat.set_shader_parameter("edge", Color(String(dying.get("edge", dying.get("color", "#ff8040")))).lightened(0.5))
	mat.set_shader_parameter("shift", Vector2(randi() % 64, randi() % 64))
	mat.set_shader_parameter("cut", 0.0)
	_burn_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

## The dying pose burnt to cut (0 = whole, 1 = gone): the pose itself until the burn starts.
func _burn_tex(cut: float) -> Texture2D:
	if cut <= 0.0 or _burn_vp == null:
		return dying["tex"]
	(_burn_pic.material as ShaderMaterial).set_shader_parameter("cut", cut)
	return _burn_vp.get_texture()

func _burn_off() -> void:
	if _burn_vp != null:
		_burn_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
