class_name HallsScene
extends RefCounted
## 0.13 The Halls Below: the room you stand in, first-person from the doorway.
## Shared by the room view (between fights) and the battle view (its backdrop), so
## fights happen in the same room you walked into.
## Walls, floors, ceilings: art/halls/z<zone>_*.png, made for Solaria with PixelLab
## (the old Tiny Texture versions came from tools/fp_textures.py). Scenery: Dungeon Crawl Stone Soup (CC0).

const W := 6.0            # room width (world units); side walls at x = -3 and +3
const D := 5.5            # depth of the far wall
const Z_NEAR := 0.9
const FLOOR_Y := -1.5     # eye height above the floor
const CEIL_Y := 2.5
const STEP := 0.5         # quads are half a unit (less warping, finer floor)
static var low := false   # Low graphics: quads twice the size (a quarter as many)
static var allow_3d := true   # off in tests that only want the 2D drawer
const DOOR_X := [-1.9, 0.0, 1.9]
const DOOR_W := 1.3
const DOOR_H := 2.3
## The one colour table for each zone's light (palette colours only; claude/zone-palettes.md):
## "deep" its Dark, "amb" its Mid (the ambient light), "accent" its one bright colour (shrine glyph,
## portal light, rim light, the zone's UI colour), "light" its torch. Plus particles and darkness.
## The 3D room, the 2D room, SpriteLight, the battle view's rim and GameData's zone colour read it.
const MOODS := [
	{"kind": "fireflies", "dark": 0.35, "deep": Color("#1f1d24"), "amb": Color("#566a56"), "accent": Color("#75a743"), "light": Color("#feae34")},
	{"kind": "dust", "dark": 0.55, "deep": Color("#181425"), "amb": Color("#5a6988"), "accent": Color("#fee761"), "light": Color("#feae34")},
	{"kind": "drips", "dark": 0.45, "deep": Color("#172038"), "amb": Color("#3a4466"), "accent": Color("#4fb0c6"), "light": Color("#4fb0c6")},
	{"kind": "embers", "dark": 0.4, "deep": Color("#1f1d24"), "amb": Color("#8f563b"), "accent": Color("#e43b44"), "light": Color("#f77622")},
	{"kind": "shadows", "dark": 0.55, "deep": Color("#181425"), "amb": Color("#3a4466"), "accent": Color("#9a4fc0"), "light": Color("#c27ad8")},
	{"kind": "leaves", "dark": 0.4, "deep": Color("#1f1d24"), "amb": Color("#566a56"), "accent": Color("#d0dcc8"), "light": Color("#d0dcc8")},
	{"kind": "sparkles", "dark": 0.35, "deep": Color("#172038"), "amb": Color("#68386c"), "accent": Color("#c27ad8"), "light": Color("#f6757a")},
	{"kind": "sparks", "dark": 0.45, "deep": Color("#1f1d24"), "amb": Color("#5a3f35"), "accent": Color("#c8a060"), "light": Color("#feae34")},
	{"kind": "motes", "dark": 0.3, "deep": Color("#1f1d24"), "amb": Color("#6a4a28"), "accent": Color("#c8a060"), "light": Color("#c8a060")},
	{"kind": "embers", "dark": 0.55, "deep": Color("#2a1a1e"), "amb": Color("#733e39"), "accent": Color("#e43b44"), "light": Color("#f77622")},
]
const UNREAD_FRAME := Color("#c0cbdc")   # an unread door's frame when the accent is the light's colour
const DOOR_LABEL_W := 120.0   # a door label's box, centred on its door
const TEXELS := 16.0      # texels per world unit on walls, floors and ceilings (same as Room3D)

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
var gate := false          # a champion's gate waits here: the middle door is a portal
var _tex := {}
var r3: Room3D = null      # the real 3D room (not on Low graphics): `shared`, while this view draws it
var _r3_key := ""
var _seed := 0
var event := ""            # the room's one thing (room_props[0].kind), so its layout matches
var small := false         # a short screen (the SE): the horizon sits higher, the team lower
var room_key := ""         # the room alone (not the view's size): the shared Room3D shows one room
var _wipe := 0             # frames of the checker wipe left after a room change
var _wipe_tex := {}
var _vig_tex: Texture2D = null
var _vig_at := Vector3.ZERO
## One 3D room for every view (room view and fights), moved to whichever draws: a second one
## would show the last fight's room for a frame and build every room twice (Fable round 3).
static var shared: Room3D = null

func tx(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]

func mood() -> Dictionary:
	return MOODS[zone]

## A zone's ambient light: its Mid colour, brightened to one level so dark zones aren't black.
static func ambient(zi: int) -> Color:
	var c: Color = MOODS[clampi(zi, 0, MOODS.size() - 1)]["amb"]
	return c * (0.68 / maxf(0.05, maxf(c.r, maxf(c.g, c.b))))

## Lays out the room (same floor and room = same room). Rebuilds only when needed.
## scr is the view's screen px per design px: under 400 screen px tall the horizon rises to
## 0.34 so the floor between the hero and the doors stays (the SE).
func build(st: GameState, sz: Vector2, scr := 1.0) -> void:
	var g: bool = not st.room_props.is_empty() and String(st.room_props[0]["kind"]) == "gate" and not st.room_props[0].get("used", false)
	var ev := "" if st.room_props.is_empty() else String(st.room_props[0]["kind"])
	var sm := sz.y * scr < 400.0
	var k := "%d|%d|%d|%d|%s|%d" % [st.floor_num, st.room_count, int(sz.x) * 10000 + int(sz.y), int(g), ev, int(sm)]
	if k == key:
		return
	key = k
	gate = g
	event = ev
	small = sm
	room_key = "%d|%d|%d|%s" % [st.floor_num, st.room_count, int(g), ev]
	focal = sz.x * 0.62
	center = Vector2(sz.x / 2.0, sz.y * (0.28 if small else 0.40))   # 0.28: 60+ px of floor over the hero on the SE (stage6)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d-%d" % [st.floor_num, st.room_count])
	_seed = rng.seed
	zone = clampi(GameData.zone_index(st.floor_num), 0, 9)
	amb = ambient(zone)
	light = MOODS[zone]["light"]
	var depth := clampf(st.floor_num / 1000.0, 0.0, 1.0)
	dark = clampf(float(MOODS[zone]["dark"]) + depth * 0.3, 0.0, 0.85)
	torches = []
	var tz := rng.randf_range(3.9, 4.6)   # side-wall torches a phone can see (|x| <= 0.78 z)
	torches.append(Vector3(-W / 2.0 + 0.05, 0.4, tz))
	torches.append(Vector3(W / 2.0 - 0.05, 0.4, clampf(tz + rng.randf_range(-0.5, 0.5), 3.9, D - 0.3)))
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

## Quad size: half a world unit, or a whole unit on Low graphics.
func _step() -> float:
	return STEP * 2.0 if low else STEP

## A textured world quad from 4 corners (a = top-left of the texture, then clockwise).
## Between begin_batch() and end_batch() quads with the batch's texture are collected
## and sent as one triangle list: one draw call per surface instead of one per quad.
func quad(ci: CanvasItem, tex: Texture2D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv0: Vector2, uv1: Vector2) -> void:
	var pts := PackedVector2Array([proj(a.x, a.y, a.z), proj(b.x, b.y, b.z), proj(c.x, c.y, c.z), proj(d.x, d.y, d.z)])
	var cols := PackedColorArray([lit(a.x, a.y, a.z), lit(b.x, b.y, b.z), lit(c.x, c.y, c.z), lit(d.x, d.y, d.z)])
	var uvs := PackedVector2Array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)])
	if _batch_tex != null and tex == _batch_tex:
		var base := _batch_pts.size()
		_batch_pts.append_array(pts)
		_batch_cols.append_array(cols)
		_batch_uvs.append_array(uvs)
		_batch_idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
		return
	ci.draw_polygon(pts, cols, uvs, tex)

var _batch_tex: Texture2D = null
var _batch_pts := PackedVector2Array()
var _batch_cols := PackedColorArray()
var _batch_uvs := PackedVector2Array()
var _batch_idx := PackedInt32Array()

func begin_batch(tex: Texture2D) -> void:
	_batch_tex = tex
	_batch_pts.clear()
	_batch_cols.clear()
	_batch_uvs.clear()
	_batch_idx.clear()

func end_batch(ci: CanvasItem) -> void:
	if _batch_tex != null and not _batch_idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _batch_idx, _batch_pts, _batch_cols, _batch_uvs,
			PackedInt32Array(), PackedFloat32Array(), _batch_tex.get_rid())
	_batch_tex = null

## A dithered drop shadow (art/fx/shadow.png, 2 hard steps) r pixels wide either side.
func shadow(ci: CanvasItem, at: Vector2, r: float) -> void:
	var tex := tx("res://art/fx/shadow.png")
	if tex:
		ci.draw_texture_rect(tex, Rect2(at - Vector2(r, r * 0.25), Vector2(r * 2.0, r * 0.5)), false)

## The floor glow (art/fx/glow.png, 3 hard steps) tinted c, centred on at, w pixels wide.
func glow(ci: CanvasItem, at: Vector2, w: float, c: Color) -> void:
	var tex := tx("res://art/fx/glow.png")
	if tex:
		ci.draw_texture_rect(tex, Rect2(at - Vector2(w / 2.0, w / 4.0), Vector2(w, w / 2.0)), false, c)

## A sprite standing on the floor at (x, z), about h world units tall. Returns its screen rect.
## Drawn at a whole-number scale of its art (1x, 2x, 3x...), never in between.
## Where sprite() draws tex: k whole SCREEN pixels per art pixel (not design pixels: those are
## 0.85 screen px on a phone), its lowest opaque row on the floor at (x, z) (transparent rows
## under the art would lift it off the floor).
func sprite_rect(tex: Texture2D, x: float, z: float, h: float, scr: float, bob := 0.0) -> Rect2:
	var feet := ((proj(x, FLOOR_Y, z) + Vector2(0, bob)) * scr).round() / scr
	var k := float(maxi(1, roundi(focal * h / z / tex.get_size().y * scr))) / scr
	var hpx := tex.get_size().y * k
	var wpx := tex.get_size().x * k
	return Rect2(feet - Vector2(wpx / 2.0, hpx - Room3D.base_pad(tex) * k), Vector2(wpx, hpx))

func sprite(ci: CanvasItem, tex: Texture2D, x: float, z: float, h: float, tint := Color.WHITE, bob := 0.0) -> Rect2:
	if tex == null:
		return Rect2()
	var scr := screen_scale(ci)
	var rect := sprite_rect(tex, x, z, h, scr, bob)
	var feet := (proj(x, FLOOR_Y, z) * scr).round() / scr   # the shadow stays on the floor when it bobs
	shadow(ci, feet, rect.size.x * 0.35)
	var lc := lit(x, FLOOR_Y + h * 0.6, z)
	ci.draw_texture_rect(tex, rect, false, Color(lc.r * tint.r, lc.g * tint.g, lc.b * tint.b, tint.a))
	return rect

# =====================================================================
# The room itself
# =====================================================================

## Floor, ceiling and walls.
func draw_shell(ci: CanvasItem, sz: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.01, 0.02))
	if _draw_3d(ci, sz):
		return
	var wall := tx("res://art/halls/z%d_wall.png" % zone)
	var flo := tx("res://art/halls/z%d_floor.png" % zone)
	var ceil_t := tx("res://art/halls/z%d_ceil.png" % zone)
	var hw := W / 2.0
	# Tiled like the 3D room: one tile per (texture width / TEXELS) world units (a 32 px tile per 2 units).
	# One texture at a time (all floor, then all ceiling, then the walls), each sent as a
	# single triangle list: a few draw calls for the whole room instead of one per quad.
	for pass_tex in [flo, ceil_t]:
		if pass_tex == null:
			continue
		var y := FLOOR_Y if pass_tex == flo else CEIL_Y
		begin_batch(pass_tex)
		var z0 := Z_NEAR
		while z0 < D - 0.001:
			var z1 := minf(z0 + _step(), D)
			var x0 := -hw
			while x0 < hw - 0.001:
				var x1 := x0 + _step()
				var rep: float = pass_tex.get_width() / TEXELS
				var u0 := Vector2(fposmod((x0 + hw) / rep, 1.0), fposmod((z0 - Z_NEAR) / rep, 1.0))
				var u1 := u0 + Vector2((x1 - x0) / rep, (z1 - z0) / rep)
				if pass_tex == flo:
					quad(ci, flo, Vector3(x0, y, z1), Vector3(x1, y, z1), Vector3(x1, y, z0), Vector3(x0, y, z0), Vector2(u0.x, u1.y), Vector2(u1.x, u0.y))
				else:
					quad(ci, ceil_t, Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1), u0, u1)
				x0 = x1
			z0 = z1
		end_batch(ci)
	if wall:
		begin_batch(wall)
		var wrep: float = wall.get_width() / TEXELS
		# side walls
		var z0 := Z_NEAR
		while z0 < D - 0.001:
			var z1 := minf(z0 + _step(), D)
			var u0 := fposmod((z0 - Z_NEAR) / wrep, 1.0)
			var y0 := FLOOR_Y
			while y0 < CEIL_Y - 0.001:
				var y1 := minf(y0 + _step(), CEIL_Y)
				var v0 := fposmod((CEIL_Y - y1) / wrep, 1.0)
				var uv0 := Vector2(u0, v0)
				var uv1 := Vector2(u0 + (z1 - z0) / wrep, v0 + (y1 - y0) / wrep)
				quad(ci, wall, Vector3(-hw, y1, z0), Vector3(-hw, y1, z1), Vector3(-hw, y0, z1), Vector3(-hw, y0, z0), uv0, uv1)
				quad(ci, wall, Vector3(hw, y1, z1), Vector3(hw, y1, z0), Vector3(hw, y0, z0), Vector3(hw, y0, z1), uv0, uv1)
				y0 = y1
			z0 = z1
	if wall:
		var wrep: float = wall.get_width() / TEXELS
		var yj := FLOOR_Y
		while yj < CEIL_Y - 0.001:
			var y1 := minf(yj + 1.0, CEIL_Y)
			var xj := -hw
			while xj < hw - 0.001:
				var fu := Vector2(fposmod((xj + hw) / wrep, 1.0), fposmod((CEIL_Y - y1) / wrep, 1.0))
				quad(ci, wall, Vector3(xj, y1, D), Vector3(xj + 1.0, y1, D), Vector3(xj + 1.0, yj, D), Vector3(xj, yj, D), fu, fu + Vector2(1.0, y1 - yj) / wrep)
				xj += 1.0
			yj = y1
		end_batch(ci)
	ci.draw_line(proj(-hw, FLOOR_Y, D), proj(hw, FLOOR_Y, D), Color(0, 0, 0, 0.5), 2.0)

## True while the 3D room stands in for the 2D one (doors, scenery and torches
## are part of it then; the views still draw what's in the room on top).
func is_3d() -> bool:
	return r3 != null and _r3_key == room_key and key != "" and not low and allow_3d

## Draws the 3D room as the backdrop, one viewport pixel per ArtStyle.unit screen pixels.
## Only the very first frame (or Low graphics, or headless) uses the 2D drawer.
func _draw_3d(ci: CanvasItem, sz: Vector2) -> bool:
	if low or not allow_3d or DisplayServer.get_name() == "headless":
		if shared != null and is_instance_valid(shared):
			shared.queue_free()
		shared = null
		r3 = null
		_r3_key = ""
		return false
	if shared == null or not is_instance_valid(shared):
		shared = Room3D.new()
		ci.add_child.call_deferred(shared)
	r3 = shared
	if r3.get_parent() != ci and not r3.has_meta("moving"):
		# this view draws now: the room moves here (it only renders under a visible parent)
		r3.set_meta("moving", true)
		_move_room.call_deferred(ci)
	var deep: Color = mood()["deep"]
	if not r3.is_inside_tree():
		ci.draw_rect(Rect2(Vector2.ZERO, sz), deep)
		_r3_key = room_key
		return true
	var scr := screen_scale(ci)
	r3.horizon = center.y / maxf(1.0, sz.y)
	r3.fit(sz, scr if scr > 0.01 else 1.0)
	if r3.get_meta("want", "") != room_key:
		# a new room: build it next frame; until it's built, the zone's deep colour (never the last room)
		r3.set_meta("want", room_key)
		r3.rebuild.call_deferred(zone, _seed, {"light": light, "amb": amb, "accent": mood()["accent"], "kind": mood()["kind"], "dark": dark,
			"gate": gate, "event": event, "small": small, "key": room_key})
	_r3_key = room_key
	if r3.built_key != room_key:
		ci.draw_rect(Rect2(Vector2.ZERO, sz), deep)
		_wipe = 4
		return true
	ci.draw_texture_rect(r3.texture(), Rect2(Vector2.ZERO, r3.drawn_size()), false)
	if _wipe > 0:
		# the new room comes out of the dark in two checker steps (hard pixels, no fade)
		_wipe -= 1
		ci.draw_texture_rect(_wipe_checker(sz, scr, 2 if _wipe >= 2 else 1, deep), Rect2(Vector2.ZERO, sz), false)
	return true

func _move_room(ci: CanvasItem) -> void:
	if shared == null or not is_instance_valid(shared) or not is_instance_valid(ci):
		return
	shared.remove_meta("moving")
	if shared.get_parent() == ci:
		return
	if shared.get_parent():
		shared.reparent(ci, false)
	else:
		ci.add_child(shared)

## A checker over the whole view in ArtStyle.unit cells: 2 of 4 cells dark, then 1 of 4.
func _wipe_checker(sz: Vector2, scr: float, cells: int, c: Color) -> Texture2D:
	var u := float(ArtStyle.unit(scr)) / maxf(0.01, scr)
	var w := int(ceilf(sz.x / u))
	var h := int(ceilf(sz.y / u))
	var k := "%d|%d|%d|%s" % [w, h, cells, c.to_html()]
	if not _wipe_tex.has(k):
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var on := (x + y) % 2 == 0 if cells == 2 else (x % 2 == 0 and y % 2 == 0)
				if on:
					img.set_pixel(x, y, c)
		_wipe_tex[k] = ImageTexture.create_from_image(img)
	return _wipe_tex[k]

## Screen pixels per design pixel for ci: the window's stretch (canvas_items mode leaves the
## canvas transform at 1.0 on phones, so read the viewport's final transform) times any canvas zoom.
static func screen_scale(ci: CanvasItem) -> float:
	return maxf(0.01, PixelPic.stretch(ci) * ci.get_global_transform_with_canvas().get_scale().x)

## The three doors on the far wall. When `st` has doors to pick, they glow and
## become tap targets in `hit` ("d0".."d2").
func draw_doors(ci: CanvasItem, st: GameState, hit: Dictionary, font: Font) -> void:
	var open := st != null and st.door_pending()
	var in3d := is_3d() and r3 != null and r3.built_key == room_key
	if in3d:
		for i in 3:
			r3.mark_door(i, Color.WHITE, 0.0, 0.0)
	var dt := tx("res://art/halls/z%d_door.png" % zone)
	if dt == null:
		dt = tx("res://art/halls/door.png")
	for i in 3:
		var x: float = DOOR_X[i]
		var tl := proj(x - DOOR_W / 2.0, FLOOR_Y + DOOR_H, D)
		var br := proj(x + DOOR_W / 2.0, FLOOR_Y, D)
		var rect := Rect2(tl, br - tl)
		if gate and i == 1 and not is_3d():
			ci.draw_texture_rect(tx("res://art/halls/portal_1.png" if int(t * 4.0) % 2 else "res://art/halls/portal.png"), rect, false)
		elif dt and not is_3d():
			ci.draw_texture_rect(dt, rect, false, lit(x, FLOOR_Y + 1.0, D - 0.3))
		if not open:
			continue
		# a door reader on the team senses what's behind: a glow, later the room itself
		var rd := Halls.read_door(st, i)
		var sensed := String(rd["color"]) != ""
		# every door you can pick glows at its foot (in the zone's accent until a reader senses more),
		# so the main tap target never sinks into a dark far wall
		var col := ArtStyle.nearest(Color(String(rd["color"]))) if sensed else Color(mood()["accent"])
		if not sensed and ArtStyle.oklab(col).distance_to(ArtStyle.oklab(Color(mood()["light"]))) < 0.12:
			col = UNREAD_FRAME   # an accent like the zone's light would vanish on its lit doors
		var pulse := 0.6 + 0.3 * sin(t * 3.0 + i)
		var glow_a := 0.6 + 0.2 * sin(t * 2.0 + i) if sensed else 0.45
		if in3d:
			# in the room itself, so props standing in front of a door cover its frame and glow
			r3.mark_door(i, col, pulse, glow_a)
		else:
			glow(ci, Vector2(rect.get_center().x, rect.end.y), rect.size.x * 1.8, Color(col, glow_a))
			# a 1 px outline-black frame under the coloured one, so a red frame reads on a red door
			ci.draw_rect(rect.grow(4.5), Color("#0e0812"), false, 1.0)
			ci.draw_rect(rect.grow(3), Color(col, pulse), false, 3.0)
		hit["d%d" % i] = rect.grow(12)
		var lab := door_label(st, i)
		if lab != "":
			var fs := 18 if lab == "?" else 16
			# the middle label sits one line higher, so neighbours never touch
			var at := Vector2(rect.get_center().x - DOOR_LABEL_W / 2.0, rect.position.y - 6 - (fs if i == 1 else 0))
			ci.draw_string_outline(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, DOOR_LABEL_W, fs, 4, Color(0, 0, 0, 0.9))
			ci.draw_string(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, DOOR_LABEL_W, fs, col.lightened(0.3))

## What door i says over it ("" for nothing): the gate's middle door carries the gate's own
## name ("Champion", drawn by the room view), so a read there would make two labels.
func door_label(st: GameState, i: int) -> String:
	if gate and i == 1:
		return ""
	return String(Halls.read_door(st, i)["label"])

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
	if is_3d() and String(th["kind"]) in ["decor", "torch"]:
		return true  # part of the 3D room
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
			glow(ci, at, hpx * 1.6 * flick, Color(light, 0.35))
			return true
	return false

## The edges of your view fall into shadow: a thin outline-coloured frame and one band of
## checker dither inside it (hard pixels, no soft gradient over the art).
## Baked once per size into a 3-cell-wide strip, drawn as two texture rects (the right one mirrored).
func vignette(ci: CanvasItem, sz: Vector2) -> void:
	if sz.x < 1.0 or sz.y < 1.0:  # first draw before layout
		return
	var scr := screen_scale(ci)
	var u := float(ArtStyle.unit(scr)) / scr
	var edge := Color("#0e0812")
	var rows := int(ceilf(sz.y / u))
	if _vig_tex == null or _vig_at != Vector3(sz.x, sz.y, u):
		_vig_at = Vector3(sz.x, sz.y, u)
		var img := Image.create(3, rows, false, Image.FORMAT_RGBA8)
		for k in rows:
			img.set_pixel(0, k, edge)
			for row in 2:
				if (k + row) % 2 == 0:
					img.set_pixel(1 + row, k, edge)
		_vig_tex = ImageTexture.create_from_image(img)
	ci.draw_texture_rect(_vig_tex, Rect2(0, 0, 3.0 * u, rows * u), false)
	ci.draw_texture_rect(_vig_tex, Rect2(sz.x, 0, -3.0 * u, rows * u), false)
	ci.draw_rect(Rect2(0, 0, sz.x, u), edge)
