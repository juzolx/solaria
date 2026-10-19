class_name HallsScene
extends RefCounted
## 0.13 The Halls Below: the room you stand in, first-person from the doorway.
## Shared by the room view (between fights) and the battle view (its backdrop), so
## fights happen in the same room you walked into.
## Walls, floors, ceilings: Screaming Brain Studios Tiny Texture Packs (CC0),
## pixelized by tools/fp_textures.py into art/halls. Scenery: Dungeon Crawl Stone Soup (CC0).

const W := 6.0            # room width (world units); side walls at x = -3 and +3
const D := 5.5            # depth of the far wall
const Z_NEAR := 0.9
const FLOOR_Y := -1.5     # eye height above the floor
const CEIL_Y := 2.5
const STEP := 0.5         # quads are half a unit (less warping, finer floor)
const DOOR_X := [-1.9, 0.0, 1.9]
const DOOR_W := 1.3
const DOOR_H := 2.3
const MOODS := [          # particles and light by zone index
	{"kind": "fireflies", "dark": 0.35, "light": Color("#ffd27a"), "amb": Color("#8fae8a")},
	{"kind": "dust", "dark": 0.55, "light": Color("#ffb35c"), "amb": Color("#a89a88")},
	{"kind": "drips", "dark": 0.45, "light": Color("#a8e6ff"), "amb": Color("#8aa4b4")},
	{"kind": "embers", "dark": 0.4, "light": Color("#ff7a3d"), "amb": Color("#b88a78")},
	{"kind": "shadows", "dark": 0.55, "light": Color("#c9a3ff"), "amb": Color("#9a8fb0")},
	{"kind": "leaves", "dark": 0.4, "light": Color("#b8f5d0"), "amb": Color("#90b49c")},
	{"kind": "sparkles", "dark": 0.35, "light": Color("#ffb3f0"), "amb": Color("#b49ab8")},
	{"kind": "sparks", "dark": 0.45, "light": Color("#ffcf6b"), "amb": Color("#ab9c88")},
	{"kind": "motes", "dark": 0.2, "light": Color("#fff4c2"), "amb": Color("#c4bca4")},
	{"kind": "embers", "dark": 0.55, "light": Color("#ff4a4a"), "amb": Color("#a87878")},
]

var focal := 300.0
var center := Vector2.ZERO
var zone := 0
var decor: Array = []      # scenery standing in the room [{art, x, z, h}]
var torches: Array = []    # world positions of wall torches (Vector3)
var amb := Color.WHITE
var light := Color.WHITE
var dark := 0.4
var t := 0.0
var key := ""
var _tex := {}

func tx(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]

func mood() -> Dictionary:
	return MOODS[zone]

## Lays out the room (same floor and room = same room). Rebuilds only when needed.
func build(st: GameState, sz: Vector2) -> void:
	var k := "%d|%d|%d" % [st.floor_num, st.room_count, int(sz.x) * 10000 + int(sz.y)]
	if k == key:
		return
	key = k
	focal = sz.x * 0.62
	center = Vector2(sz.x / 2.0, sz.y * 0.40)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d-%d" % [st.floor_num, st.room_count])
	zone = clampi(GameData.zone_index(st.floor_num), 0, 9)
	amb = MOODS[zone]["amb"]
	light = MOODS[zone]["light"]
	var depth := clampf(st.floor_num / 1000.0, 0.0, 1.0)
	dark = clampf(float(MOODS[zone]["dark"]) + depth * 0.3, 0.0, 0.85)
	torches = []
	var tz := rng.randf_range(3.9, 4.6)
	torches.append(Vector3(-W / 2.0 + 0.05, 0.4, tz))
	torches.append(Vector3(W / 2.0 - 0.05, 0.4, clampf(tz + rng.randf_range(-0.5, 0.5), 3.8, D - 0.3)))
	var kinds := ["statue_0", "statue_1", "statue_2", "statue_3", "boulder", "box"]
	if zone == 1:
		kinds += ["sarcophagus", "sarcophagus"]
	if zone in [3, 9]:
		kinds += ["blood_fountain"]
	decor = []
	for i in rng.randi_range(1, 3):
		var side := -1.0 if i % 2 == 0 else 1.0
		decor.append({"art": kinds[rng.randi() % kinds.size()], "x": side * rng.randf_range(2.0, 2.4), "z": rng.randf_range(3.4, D - 0.5), "h": 1.1})

# =====================================================================
# Projection and light
# =====================================================================

func proj(x: float, y: float, z: float) -> Vector2:
	return Vector2(center.x + focal * x / z, center.y - focal * y / z)

## How lit a world point is: dim ambient that fades with depth, plus the torches.
func lit(x: float, y: float, z: float) -> Color:
	var a := clampf(1.15 - z / D * 0.75, 0.15, 1.0) * (1.0 - dark * 0.8)
	var c := amb * a
	for tp in torches:
		var tv: Vector3 = tp
		var d2 := (tv.x - x) * (tv.x - x) + (tv.y - y) * (tv.y - y) + (tv.z - z) * (tv.z - z)
		var flick := 1.0 + 0.06 * sin(t * 9.0 + tv.z * 3.0)
		c += light * (0.9 * flick / (1.0 + d2 * 0.9))
	# your own light at the doorway
	var dn := (z - Z_NEAR) * (z - Z_NEAR) + x * x * 0.3
	c += light * (0.35 / (1.0 + dn * 0.5))
	return Color(minf(c.r, 1.2), minf(c.g, 1.2), minf(c.b, 1.2), 1.0)

## A textured world quad from 4 corners (a = top-left of the texture, then clockwise).
func quad(ci: CanvasItem, tex: Texture2D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv0: Vector2, uv1: Vector2) -> void:
	var pts := PackedVector2Array([proj(a.x, a.y, a.z), proj(b.x, b.y, b.z), proj(c.x, c.y, c.z), proj(d.x, d.y, d.z)])
	var cols := PackedColorArray([lit(a.x, a.y, a.z), lit(b.x, b.y, b.z), lit(c.x, c.y, c.z), lit(d.x, d.y, d.z)])
	var uvs := PackedVector2Array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)])
	ci.draw_polygon(pts, cols, uvs, tex)

func shadow(ci: CanvasItem, at: Vector2, r: float) -> void:
	ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.3))
	ci.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.4))
	ci.draw_set_transform(Vector2.ZERO)

## A sprite standing on the floor at (x, z), h world units tall. Returns its screen rect.
func sprite(ci: CanvasItem, tex: Texture2D, x: float, z: float, h: float, tint := Color.WHITE, bob := 0.0) -> Rect2:
	if tex == null:
		return Rect2()
	var feet := proj(x, FLOOR_Y, z) + Vector2(0, bob)
	var hpx := focal * h / z
	var wpx := hpx * tex.get_size().x / tex.get_size().y
	var rect := Rect2(feet - Vector2(wpx / 2.0, hpx), Vector2(wpx, hpx))
	shadow(ci, feet, wpx * 0.35)
	var lc := lit(x, FLOOR_Y + h * 0.6, z)
	ci.draw_texture_rect(tex, rect, false, Color(lc.r * tint.r, lc.g * tint.g, lc.b * tint.b, tint.a))
	return rect

# =====================================================================
# The room itself
# =====================================================================

## Floor, ceiling and walls.
func draw_shell(ci: CanvasItem, sz: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.01, 0.02))
	var wall := tx("res://art/halls/z%d_wall.png" % zone)
	var flo := tx("res://art/halls/z%d_floor.png" % zone)
	var ceil_t := tx("res://art/halls/z%d_ceil.png" % zone)
	var hw := W / 2.0
	var z0 := Z_NEAR
	while z0 < D - 0.001:
		var z1 := minf(z0 + STEP, D)
		var x0 := -hw
		while x0 < hw - 0.001:
			var x1 := x0 + STEP
			if flo:
				quad(ci, flo, Vector3(x0, FLOOR_Y, z1), Vector3(x1, FLOOR_Y, z1), Vector3(x1, FLOOR_Y, z0), Vector3(x0, FLOOR_Y, z0), Vector2.ZERO, Vector2.ONE)
			if ceil_t:
				quad(ci, ceil_t, Vector3(x0, CEIL_Y, z0), Vector3(x1, CEIL_Y, z0), Vector3(x1, CEIL_Y, z1), Vector3(x0, CEIL_Y, z1), Vector2.ZERO, Vector2.ONE)
			x0 = x1
		if wall:
			# side walls: one texture per world unit
			var u0 := fposmod(z0 - Z_NEAR, 1.0)
			var y0 := FLOOR_Y
			while y0 < CEIL_Y - 0.001:
				var y1 := minf(y0 + STEP, CEIL_Y)
				var v0 := fposmod(CEIL_Y - y1, 1.0)
				var uv0 := Vector2(u0, v0)
				var uv1 := Vector2(u0 + (z1 - z0), v0 + (y1 - y0))
				quad(ci, wall, Vector3(-hw, y1, z0), Vector3(-hw, y1, z1), Vector3(-hw, y0, z1), Vector3(-hw, y0, z0), uv0, uv1)
				quad(ci, wall, Vector3(hw, y1, z1), Vector3(hw, y1, z0), Vector3(hw, y0, z0), Vector3(hw, y0, z1), uv0, uv1)
				y0 = y1
		z0 = z1
	if wall:
		var yj := FLOOR_Y
		while yj < CEIL_Y - 0.001:
			var y1 := minf(yj + 1.0, CEIL_Y)
			var xj := -hw
			while xj < hw - 0.001:
				quad(ci, wall, Vector3(xj, y1, D), Vector3(xj + 1.0, y1, D), Vector3(xj + 1.0, yj, D), Vector3(xj, yj, D), Vector2(0, 1.0 - (y1 - yj)), Vector2.ONE)
				xj += 1.0
			yj = y1
	ci.draw_line(proj(-hw, FLOOR_Y, D), proj(hw, FLOOR_Y, D), Color(0, 0, 0, 0.5), 2.0)

## The three doors on the far wall. When `st` has doors to pick, they glow and
## become tap targets in `hit` ("d0".."d2").
func draw_doors(ci: CanvasItem, st: GameState, hit: Dictionary, font: Font) -> void:
	var open := st != null and st.door_pending()
	var dt := tx("res://art/halls/door.png")
	for i in 3:
		var x: float = DOOR_X[i]
		var tl := proj(x - DOOR_W / 2.0, FLOOR_Y + DOOR_H, D)
		var br := proj(x + DOOR_W / 2.0, FLOOR_Y, D)
		var rect := Rect2(tl, br - tl)
		if dt:
			ci.draw_texture_rect(dt, rect, false, lit(x, FLOOR_Y + 1.0, D - 0.3))
		if not open:
			continue
		# a door reader on the team senses what's behind: a glow, later the room itself
		var rd := Halls.read_door(st, i)
		var col := Color(String(rd["color"])) if String(rd["color"]) != "" else Color(1.0, 0.85, 0.45)
		var pulse := 0.45 + 0.35 * sin(t * 3.0 + i)
		if String(rd["color"]) != "":
			ci.draw_set_transform(Vector2(rect.get_center().x, rect.end.y), 0.0, Vector2(1.0, 0.3))
			ci.draw_circle(Vector2.ZERO, rect.size.x * 0.9, Color(col, 0.22 + 0.1 * sin(t * 2.0 + i)))
			ci.draw_set_transform(Vector2.ZERO)
		ci.draw_rect(rect.grow(2), Color(col, pulse), false, 2.0)
		hit["d%d" % i] = rect.grow(12)
		var lab := String(rd["label"])
		if lab != "":
			var fs := 18 if lab == "?" else 11
			var at := Vector2(rect.position.x - 30, rect.position.y - 6)
			ci.draw_string_outline(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 60, fs, 4, Color(0, 0, 0, 0.9))
			ci.draw_string(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 60, fs, col.lightened(0.3))

## Scenery and torches as depth-sorted entries ({"z", "kind": "decor"/"torch"}).
func scenery() -> Array:
	var out: Array = []
	for dc in decor:
		out.append({"z": float(dc["z"]), "kind": "decor", "d": dc})
	for tp in torches:
		out.append({"z": (tp as Vector3).z, "kind": "torch", "p": tp})
	return out

## Draws one scenery entry; returns false if it isn't scenery.
func draw_scenery(ci: CanvasItem, th: Dictionary) -> bool:
	match String(th["kind"]):
		"decor":
			var dc: Dictionary = th["d"]
			sprite(ci, tx("res://art/dungeon/%s.png" % String(dc["art"])), float(dc["x"]), float(dc["z"]), float(dc["h"]))
			return true
		"torch":
			var p: Vector3 = th["p"]
			var at := proj(p.x, p.y, p.z)
			var hpx := focal * 0.7 / p.z
			var tt := tx("res://art/dungeon/torch.png")
			if tt:
				ci.draw_texture_rect(tt, Rect2(at - Vector2(hpx / 2.0, hpx / 2.0), Vector2(hpx, hpx)), false)
			var flick := 1.0 + 0.08 * sin(t * 11.0 + p.z)
			for k in 4:
				ci.draw_circle(at, (hpx * (0.35 + k * 0.22)) * flick, Color(light, 0.07))
			return true
	return false

## The edges of your view fall into shadow.
func vignette(ci: CanvasItem, sz: Vector2) -> void:
	for i in 8:
		var f := float(i) / 8.0
		var a := (0.1 + dark * 0.12) * (1.0 - f)
		ci.draw_rect(Rect2(0, 0, sz.x * 0.1 * (1.0 - f), sz.y), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(sz.x - sz.x * 0.1 * (1.0 - f), 0, sz.x * 0.1 * (1.0 - f), sz.y), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(0, 0, sz.x, sz.y * 0.1 * (1.0 - f)), Color(0, 0, 0, a))
