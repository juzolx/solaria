class_name Cosmetics
extends RefCounted
## 0.13+ (Stage 3): name colors and plate frames you earn through deeds (achievements),
## shown with your title in the top bar and on your plate in fights. Looks only: never
## power. Account-wide, kept in the Codex like titles.

## {id, name, color, need}: need is an achievement id ("" = everyone has it)
const COLORS := [
	{"id": "", "name": "Plain", "color": "#e5e7eb", "need": ""},
	{"id": "moss", "name": "Moss", "color": "#86efac", "need": "f50"},
	{"id": "ascend", "name": "Ascendant", "color": "#fde68a", "need": "evo"},
	{"id": "tide", "name": "Tide", "color": "#7dd3fc", "need": "f150"},
	{"id": "veteran", "name": "Veteran Steel", "color": "#cbd5e1", "need": "lv50"},
	{"id": "hunter", "name": "Hunter's Copper", "color": "#f59e0b", "need": "rare100"},
	{"id": "scholar", "name": "Scholar's Ink", "color": "#a5b4fc", "need": "seen50"},
	{"id": "slayer", "name": "Slayer's Red", "color": "#f87171", "need": "k10000"},
	{"id": "void", "name": "Void", "color": "#c084fc", "need": "f250"},
	{"id": "lucky", "name": "Lucky Rose", "color": "#ff6b9d", "need": "sig1"},
	{"id": "myth", "name": "Mythbreaker", "color": "#ff4d6d", "need": "myth1"},
	{"id": "gold", "name": "Bossbreaker Gold", "color": "#fbbf24", "need": "boss100"},
	{"id": "legend", "name": "Legend White", "color": "#ffffff", "need": "lv100"},
]
## {id, name, color, need, studs}: a border around your plate, in its own color
const FRAMES := [
	{"id": "", "name": "None", "color": "", "need": ""},
	{"id": "bark", "name": "Barkwood", "color": "#8b5a2b", "need": "f50", "studs": false},
	{"id": "bone", "name": "Grendel's Bone", "color": "#e7dcc0", "need": "grendel", "studs": true},
	{"id": "iron", "name": "Veteran Iron", "color": "#94a3b8", "need": "lv50", "studs": true},
	{"id": "tide", "name": "Tidewrought", "color": "#38bdf8", "need": "f150", "studs": false},
	{"id": "ember", "name": "Giant's Ember", "color": "#fb923c", "need": "surtr", "studs": true},
	{"id": "abyss", "name": "Abyssal", "color": "#7c3aed", "need": "f250", "studs": true},
	{"id": "curio", "name": "Curator's Gilt", "color": "#fde047", "need": "uniq15", "studs": true},
	{"id": "crown", "name": "Bossbreaker Crown", "color": "#fbbf24", "need": "boss100", "studs": true},
	{"id": "legend", "name": "Living Legend", "color": "#ffffff", "need": "lv100", "studs": true},
]

static func has(codex: Codex, entry: Dictionary) -> bool:
	var need := String(entry["need"])
	return need == "" or codex.achievements.has(need)

static func _find(list: Array, id: String) -> Dictionary:
	for e in list:
		if String(e["id"]) == id:
			return e
	return list[0]

## The deed that unlocks an entry, for "Earn: ..." hints.
static func need_name(entry: Dictionary) -> String:
	for a in Codex.ACHIEVEMENTS:
		if a["id"] == entry["need"]:
			return String(a["name"])
	return ""

## Your name color (falls back to Plain if it was never earned).
static func name_color(codex: Codex) -> Color:
	if codex == null:
		return Color("#e5e7eb")
	var e := _find(COLORS, codex.name_color)
	return Color(String(e["color"])) if has(codex, e) else Color("#e5e7eb")

static func frame(codex: Codex) -> Dictionary:
	if codex == null:
		return FRAMES[0]
	var e := _find(FRAMES, codex.frame)
	return e if has(codex, e) else FRAMES[0]

## Draws your frame around a plate (the HP bar box) on any canvas item.
static func draw_frame(ci: CanvasItem, r: Rect2, codex: Codex, t: float) -> void:
	var f := frame(codex)
	if String(f["color"]) == "":
		return
	var c := Color(String(f["color"]))
	var box := r.grow(3.0)
	ci.draw_rect(box.grow(1.0), Color(0, 0, 0, 0.6), false, 1.0)
	ci.draw_rect(box, c, false, 2.0)
	if bool(f.get("studs", false)):
		var glint := 0.75 + 0.25 * sin(t * 2.0)
		for p in [box.position, Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), box.end]:
			ci.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(c.lightened(0.35), glint))
			ci.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(0, 0, 0, 0.7), false, 1.0)
