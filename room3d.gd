class_name Room3D
extends Node
## 0.13+: the room you stand in as a real 3D scene, rendered small into a
## SubViewport and drawn pixel-crisp as the backdrop of the room view and fights.
## Its camera matches HallsScene's one-point projection exactly (eye height,
## horizon, focal length, room size), so everything the views still draw in 2D
## on top (doors to tap, the one thing in the room, monsters, traps) lines up.
## Mossy Hollows has five room types; other regions have three, each with its own
## name and one signature dressing (water, lava seams, carved eye, wisps...).
## A pixel room (Fable round 1): no fog, bloom or haze, every prop at one pixel size,
## lights where a phone can see them, colours from HallsScene.MOODS.
## Low graphics skips this and keeps HallsScene's 2D room.

const KINDS_FOREST := ["Overgrown hall", "Collapsed chamber", "Mushroom grotto", "Forgotten shrine", "Root-choked passage"]
const KINDS_OTHER := ["Overgrown hall", "Collapsed chamber", "Forgotten shrine"]
## What each zone calls its three rooms (same order as KINDS_OTHER).
const NAMES := {
	1: ["Ossuary hall", "Caved-in crypt", "Bone shrine"],
	2: ["Flooded hall", "Sunken chamber", "Drowned shrine"],
	3: ["Forge hall", "Collapsed furnace", "Ember shrine"],
	4: ["Hall of eyes", "Fallen vault", "Void shrine"],
	5: ["Ghostwood hall", "Fallen grove", "Elven shrine"],
	6: ["Crystal hall", "Shattered court", "Fairy shrine"],
	7: ["Pipe hall", "Collapsed works", "Rune forge"],
	8: ["Gilded hall", "Fallen treasury", "Sun shrine"],
	9: ["Spiked hall", "Burning pit", "Hellfire shrine"],
}
const PX := 1.0 / 32.0     # world units per art pixel for every prop, torch and sign (one pixel size)
const DOOR_PX := HallsScene.DOOR_W / 32.0   # doors fill their arch: 32 px = DOOR_W
const TEXELS := 16.0       # wall, floor and ceiling texels per world unit (a 32 px tile per 2 units)
const SEEN := 0.78         # a phone (430x932) sees |x| < 0.806 z; props keep inside 0.78 z
const GAP_Z := -4.3        # the Collapsed chamber's hole in the ceiling (deep enough to be on screen)
const MAX_PARTICLES := 24
const ROOM_H := HallsScene.CEIL_Y - HallsScene.FLOOR_Y   # 4.0
const HW := HallsScene.W / 2.0
const RD := HallsScene.D   # depth of the far wall

var vp: SubViewport
var cam: Camera3D
var world: Node3D        # rebuilt for every room
var root3: Node3D        # floor at local y = 0 (sits at FLOOR_Y)
var flicker: Array[OmniLight3D] = []
var portal: Sprite3D = null   # the champion's gate, two frames swapped
var far_lit := false   # this room already has torches on the far wall
var pool_mat: StandardMaterial3D   # the Flooded Vaults pool, two frames swapped like the portal
static var _half := {}             # texture path -> half its drawn (opaque) width in art px
var clock := 0.0
var rng := RandomNumberGenerator.new()
var kind := ""           # the room's name in this zone (shots, notes)
var base_kind := ""      # its layout (one of KINDS_FOREST)
var zone := 0
var light_col := Color("#feae34")
var amb_col := Color("#566a56")
var accent := Color("#75a743")
var fx_kind := "fireflies"
var gate := false        # a champion's gate: the middle door is a glowing portal
var _size := Vector2.ZERO   # the view's design size (HallsScene.proj works in it)
var _scr := 1.0             # design px -> screen px
var _u := 3                 # screen px per viewport pixel (ArtStyle.unit), the sprites' one pixel size
var _frame := 0
static var _texcache := {}
static var offscreen: Array = []   # props placed where a phone can't see them (tests read this)

func _init() -> void:
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.positional_shadow_atlas_size = 0   # no shadow-casting lights (phones)
	vp.size = Vector2i(16, 16)

func _ready() -> void:
	add_child(vp)

func _process(delta: float) -> void:
	# only render while the view showing it is on screen; between fights (the room view)
	# only the flicker moves, so render every other frame there
	var p := get_parent() as CanvasItem
	var on := p != null and p.is_visible_in_tree()
	if not on:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_frame += 1
	if p is RoomView:
		if _frame % 2 == 0:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	clock += delta
	for i in flicker.size():
		var o := flicker[i]
		var base: float = o.get_meta("base", 2.0)
		o.light_energy = base * (1.0 + 0.11 * sin(clock * 9.0 + i * 2.1) + 0.07 * sin(clock * 23.0 + i))
	if portal:
		portal.texture = _tex("res://art/halls/portal_1.png" if int(clock * 4.0) % 2 else "res://art/halls/portal.png")
	if pool_mat:
		pool_mat.albedo_texture = _tex("res://art/halls/z2_pool_%d.png" % (int(clock * 2.0) % 2))

func texture() -> Texture2D:
	return vp.get_texture()

## Matches the view: one viewport pixel = ArtStyle.unit(scr) SCREEN pixels (3 on a phone),
## the same as every sprite, and the camera keeps HallsScene's projection. sz is the view's
## design size, scr its canvas scale (design px -> screen px).
func fit(sz: Vector2, scr := 1.0) -> void:
	if (sz == _size and is_equal_approx(scr, _scr)) or sz.x < 8.0 or sz.y < 8.0:
		return
	_size = sz
	_scr = maxf(scr, 0.01)
	_u = ArtStyle.unit(_scr)
	vp.size = Vector2i(maxi(8, ceili(sz.x * _scr / _u)), maxi(8, ceili(sz.y * _scr / _u)))
	if cam:
		_aim()

## The texture's size in design px: whole viewport pixels, so it may overhang the view
## by less than one pixel (the view clips it).
func drawn_size() -> Vector2:
	return Vector2(vp.size) * float(_u) / _scr

## HallsScene: screen = (w/2, 0.40 h) + focal * (x / z, -y / z), focal = 0.62 w.
## A frustum camera with the same focal length and its center shifted below the horizon.
## The texture is a little bigger than the view (whole pixels), so its centre is offset.
func _aim() -> void:
	var w := _size.x
	var h := _size.y
	var ds := drawn_size()
	var f := 0.62 * w
	var n := 0.05
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = n
	cam.far = 40.0
	cam.size = n * ds.y / f
	cam.frustum_offset = Vector2(n * (0.5 * ds.x - 0.5 * w) / f, n * (0.40 * h - 0.5 * ds.y) / f)

## Builds the room for this floor and region. Same seed, same room.
func rebuild(zone_i: int, seed_value: int, mood: Dictionary) -> void:
	zone = zone_i
	rng.seed = seed_value
	light_col = mood.get("light", Color("#feae34"))
	amb_col = mood.get("amb", Color("#566a56"))
	accent = mood.get("accent", light_col)
	fx_kind = String(mood.get("kind", "fireflies"))
	gate = bool(mood.get("gate", false))
	var kinds: Array = KINDS_FOREST if zone == 0 else KINDS_OTHER
	var ki := rng.randi() % kinds.size()
	base_kind = kinds[ki]
	kind = base_kind if not NAMES.has(zone) else String(NAMES[zone][ki])
	flicker.clear()
	portal = null
	pool_mat = null
	far_lit = false
	if world:
		world.queue_free()
	world = Node3D.new()
	vp.add_child(world)
	_environment(float(mood.get("dark", 0.4)))
	root3 = Node3D.new()
	root3.position = Vector3(0, HallsScene.FLOOR_Y, 0)
	world.add_child(root3)
	_shell()
	_light(Vector3(0.4, 1.2, -0.6), Color("#e8b796"), 1.4, 6.0, false)  # your lantern
	match base_kind:
		"Overgrown hall": _overgrown_hall()
		"Collapsed chamber": _collapsed_chamber()
		"Mushroom grotto": _mushroom_grotto()
		"Forgotten shrine": _forgotten_shrine()
		"Root-choked passage": _root_choked()
	if zone == 0:
		_moss_patches(3)
	if zone in [0, 1, 5]:
		_cobwebs()
	_signature()
	_zone_props()
	_region_particles()

# =====================================================================
# Pixel art drawn in code (original to Solaria)
# =====================================================================

static func vine_tex(seed_value: int) -> ImageTexture:
	var key := "vine%d" % seed_value
	if _texcache.has(key):
		return _texcache[key]
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var img := Image.create(16, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var greens := [Color("#193c3e"), Color("#265c42"), Color("#3e8948"), Color("#75a743")]
	var x := 0
	while x < 16:
		var length := r.randi_range(12, 48)
		var wob := 0
		for y in length:
			if r.randf() < 0.15:
				wob = clampi(wob + r.randi_range(-1, 1), -1, 1)
			var pxx := clampi(x + wob, 0, 15)
			img.set_pixel(pxx, y, greens[r.randi_range(0, 2)])
			if r.randf() < 0.18:
				img.set_pixel(clampi(pxx + (1 if r.randf() < 0.5 else -1), 0, 15), y, greens[3])
		x += r.randi_range(2, 4)
	var tex := ImageTexture.create_from_image(img)
	_texcache[key] = tex
	return tex

static func moss_tex() -> ImageTexture:
	if _texcache.has("moss"):
		return _texcache["moss"]
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var greens := [Color("#193c3e"), Color("#265c42"), Color("#3e8948"), Color("#75a743")]
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			if d + r.randf_range(-0.25, 0.25) < 0.85:
				img.set_pixel(x, y, greens[mini(3, int(r.randf() * 3.4))])
	var tex := ImageTexture.create_from_image(img)
	_texcache["moss"] = tex
	return tex

static func web_tex() -> ImageTexture:
	if _texcache.has("web"):
		return _texcache["web"]
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color("#c0cbdc")
	for i in 5:
		var v: Vector2 = Vector2.from_angle(PI / 2.0 * i / 4.0)
		for s in 24:
			var p: Vector2 = v * float(s)
			if p.x < 24 and p.y < 24:
				img.set_pixel(int(p.x), int(p.y), c)
	for rr in [7.0, 13.0, 19.0]:
		for a in 90:
			var p: Vector2 = Vector2.from_angle(deg_to_rad(a)) * rr
			if a % 2 == 0 and p.x < 24 and p.y < 24:
				img.set_pixel(int(p.x), int(p.y), c)
	var tex := ImageTexture.create_from_image(img)
	_texcache["web"] = tex
	return tex

# =====================================================================
# Building blocks
# =====================================================================

## A texture by path, cached (a missing file warns once and gives null).
static func _tex(path: String) -> Texture2D:
	if not _texcache.has(path):
		if ResourceLoader.exists(path):
			_texcache[path] = load(path)
		else:
			push_warning("Room3D: missing art " + path)
			_texcache[path] = null
	return _texcache[path]

## A tiled wall/floor/ceiling material, cached by texture and tint: TEXELS texels per world unit.
func _mat(path: String, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "mat|%s|%s" % [path, tint.to_html()]
	if _texcache.has(key):
		return _texcache[key]
	var m := StandardMaterial3D.new()
	var t := _tex(path)
	m.albedo_texture = t
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.metallic_specular = 0.15
	m.uv1_triplanar = true
	var s := TEXELS / float(t.get_width()) if t else 0.5
	m.uv1_scale = Vector3(s, s, s)
	_texcache[key] = m
	return m

## A room prop or event sprite (art/props, 40x40).
static func prop(name: String) -> Texture2D:
	return _tex("res://art/props/%s.png" % name)

## This zone's own hall art path (art/halls/z<zone>_<name>.png), or the shared fallback.
func _zpath(name: String, fallback := "") -> String:
	var path := "res://art/halls/z%d_%s.png" % [zone, name]
	if ResourceLoader.exists(path):
		return path
	if fallback == "":
		return ""
	if not fallback.begins_with("res://art/props/"):   # shared props (chest, altar, statue) are meant to be shared
		push_warning("Room3D: zone %d has no %s, using %s" % [zone, name, fallback])
	return fallback

func _zart(name: String, fallback := "") -> Texture2D:
	var p := _zpath(name, fallback)
	return _tex(p) if p != "" else null

func _wall_mat(tint := Color.WHITE) -> StandardMaterial3D:
	return _mat(_zpath("wall", "res://art/halls/z1_wall.png"), tint)

func _box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	root3.add_child(mi)
	return mi

## Records (and asserts) a placement the phone can't see: |x| plus half the sprite's width
## must stay within SEEN * depth.
func _check_seen(pos: Vector3, what: String, half := 0.0) -> void:
	var ok := absf(pos.x) + half <= SEEN * -pos.z + 0.001
	if not ok:
		offscreen.append("z%d %s %s at %s" % [zone, kind, what, pos])
	assert(ok, "Room3D: %s at %s is outside a phone's view" % [what, pos])

## A standing sprite at one pixel size (PX world units per art pixel).
func _sprite(tex: Texture2D, pos: Vector3, shaded := true, billboard := true, px := PX) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = px
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	s.shaded = shaded
	s.offset = Vector2(0, tex.get_height() / 2.0) if tex else Vector2.ZERO
	s.position = pos
	root3.add_child(s)
	if billboard:
		_check_seen(pos, tex.resource_path.get_file() if tex else "sprite", _half_w(tex) * px)
	return s

## Half the opaque width of a texture, in art px (props sit on padded canvases). Cached.
static func _half_w(tex: Texture2D) -> float:
	if tex == null:
		return 0.0
	var k := tex.resource_path if tex.resource_path != "" else str(tex.get_rid().get_id())
	if not _half.has(k):
		var img := tex.get_image()
		var r := img.get_used_rect() if img else Rect2i(0, 0, tex.get_width(), 0)
		var c := tex.get_width() / 2.0
		_half[k] = maxf(absf(r.position.x - c), absf(r.end.x - c))
	return _half[k]

func _flat(tex: Texture2D, pos: Vector3, size: Vector2, rot: Vector3, glow := false, tint := Color.WHITE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if tex:
		# one art pixel = PX world units: a quad bigger than its art repeats it
		m.uv1_scale = Vector3(size.x / (tex.get_width() * PX), size.y / (tex.get_height() * PX), 1.0)
	if glow:
		# lit by itself, in hard alpha steps (no additive haze)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.roughness = 1.0
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(mi)
	return mi

## A point light. No shadows: omni shadows are the dearest thing a phone GPU does.
func _light(pos: Vector3, color: Color, energy: float, reach: float, flickers := true) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.light_color = color
	o.light_energy = energy
	o.omni_range = reach
	o.omni_attenuation = 1.4
	o.shadow_enabled = false
	o.position = pos
	o.set_meta("base", energy)
	root3.add_child(o)
	if flickers:
		flicker.append(o)
	return o

## A wall torch (the Hushwood has pale wisps instead). Side-wall torches stand deep
## enough (z >= 3.9) that a phone sees them.
func _torch(pos: Vector3) -> void:
	_check_seen(pos, "torch")
	if zone == 5:
		var wisp := _sprite(_tex("res://art/halls/z5_wisp.png"), pos - Vector3(0, 0.25, 0), false, true)
		wisp.position.x = clampf(wisp.position.x, -SEEN * -pos.z, SEEN * -pos.z)
		_light(pos + Vector3(-signf(pos.x) * 0.3, 0.1, 0.0), accent, 2.4, 4.5)
		return
	_sprite(_zart("torch", "res://art/dungeon/torch.png"), pos - Vector3(0, 0.45, 0), false)
	var push := Vector3(-signf(pos.x) * 0.3, 0.1, 0.0) if absf(pos.x) > 1.5 else Vector3(0, 0.1, 0.3)
	_light(pos + push, light_col, 2.2, 4.5)

## A pool of light on the floor (under a hole in the ceiling): the glow sprite in hard steps.
func _light_pool(x: float, z: float) -> void:
	_flat(_tex("res://art/fx/glow.png"), Vector3(x, 0.015, z), Vector2(32, 16) * PX, Vector3(-90, 0, 0), true, Color(light_col, 0.55))
	_light(Vector3(x, ROOM_H - 0.4, z), light_col, 1.2, ROOM_H + 1.0, false)

func _particles(count: int, color: Color, size: float, falling: bool, rising := false) -> void:
	var ff := CPUParticles3D.new()
	ff.amount = mini(count, MAX_PARTICLES)
	ff.lifetime = 6.0
	ff.preprocess = 6.0
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(HW - 0.4, ROOM_H / 2.0 - 0.6, RD / 2.0 - 0.6)
	ff.position = Vector3(0, ROOM_H / 2.0, -RD / 2.0 - 0.3)
	ff.gravity = Vector3(0, -0.05, 0) if falling else (Vector3(0, 0.08, 0) if rising else Vector3.ZERO)
	ff.direction = Vector3(0, -1, 0) if falling else Vector3(0, 1, 0)
	ff.spread = 30.0 if (falling or rising) else 180.0
	ff.initial_velocity_min = 0.04
	ff.initial_velocity_max = 0.16
	var fq := QuadMesh.new()
	fq.size = Vector2(size, size)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.albedo_color = color
	fq.material = fm
	ff.mesh = fq
	root3.add_child(ff)

# =====================================================================
# Every room
# =====================================================================

## Flat, hard pixel light: no fog, no bloom, linear tone mapping (the art keeps its colours).
func _environment(dark: float) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#0e0812")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = amb_col.darkened(0.5)
	e.ambient_light_energy = clampf(1.15 - dark, 0.5, 0.95)   # deep floors never flatten to black
	e.fog_enabled = false
	e.glow_enabled = false
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	world.add_child(env)
	cam = Camera3D.new()
	cam.position = Vector3.ZERO  # eye height is the origin; the floor sits at FLOOR_Y
	world.add_child(cam)
	if _size != Vector2.ZERO:
		_aim()

func _shell() -> void:
	var wall := _wall_mat()
	var floor_m := _mat(_zpath("floor", "res://art/halls/z1_floor.png"))
	var ceil_m := _mat(_zpath("ceil", "res://art/halls/z1_ceil.png"))
	# the floor runs on under the far wall (no seam of background between them)
	_box(Vector3(HallsScene.W, 0.2, RD + 1.6), Vector3(0, -0.1, -RD / 2.0 + 0.2), floor_m)
	if base_kind != "Collapsed chamber":
		_box(Vector3(HallsScene.W, 0.2, RD + 1.0), Vector3(0, ROOM_H + 0.1, -RD / 2.0 + 0.5), ceil_m)
	else:
		# a hole in the ceiling deep enough (GAP_Z) that the phone sees it, not just its light
		var near_len := 1.0 - (GAP_Z + 0.6)
		_box(Vector3(HallsScene.W, 0.2, near_len), Vector3(0, ROOM_H + 0.1, 1.0 - near_len / 2.0), ceil_m)
		var far_len := (GAP_Z - 0.6) + RD
		_box(Vector3(HallsScene.W, 0.2, far_len), Vector3(0, ROOM_H + 0.1, -RD + far_len / 2.0), ceil_m)
		_box(Vector3(HallsScene.W * 0.35, 0.2, 1.2), Vector3(-HallsScene.W * 0.33, ROOM_H + 0.1, GAP_Z), ceil_m)
	# one steady fill under the ceiling: the near room is lit, the far wall falls off
	_light(Vector3(0, ROOM_H - 0.3, -1.6), amb_col, 0.6, 5.5, false)
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(-HW - 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(HW + 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	# far wall with three arched doorways (CSG), at HallsScene's door spots
	var dark := _wall_mat(Color(0.62, 0.62, 0.62))
	var far := CSGCombiner3D.new()
	root3.add_child(far)
	var slab := CSGBox3D.new()
	slab.size = Vector3(HallsScene.W, ROOM_H, 0.6)
	slab.position = Vector3(0, ROOM_H / 2.0, -RD - 0.3)
	slab.material = wall
	far.add_child(slab)
	var dw := HallsScene.DOOR_W
	var dh := HallsScene.DOOR_H
	for dx in HallsScene.DOOR_X:
		var x: float = dx
		var cut := CSGBox3D.new()
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.size = Vector3(dw, dh - dw / 2.0, 0.4)
		cut.position = Vector3(x, (dh - dw / 2.0) / 2.0, -RD - 0.1)
		cut.material = dark
		far.add_child(cut)
		var arch := CSGCylinder3D.new()
		arch.operation = CSGShape3D.OPERATION_SUBTRACTION
		arch.radius = dw / 2.0
		arch.height = 0.4
		arch.sides = 12
		arch.rotation_degrees = Vector3(90, 0, 0)
		arch.position = Vector3(x, dh - dw / 2.0, -RD - 0.1)
		arch.material = dark
		far.add_child(arch)
		# every door is 32x56 art, so at DOOR_PX it fills the arch exactly
		if gate and x == 0.0:
			portal = _sprite(_tex("res://art/halls/portal.png"), Vector3(x, 0.0, -RD - 0.25), false, false, DOOR_PX)
			_light(Vector3(x, dh * 0.5, -RD + 0.4), accent, 1.6, 3.5)
		else:
			# unshaded: the door art carries its own light, so it never sinks into a dark far wall
			var door := _sprite(_zart("door", "res://art/halls/door.png"), Vector3(x, 0.0, -RD - 0.25), false, false, DOOR_PX)
			door.modulate = amb_col.lightened(0.15)

func _pillars(rows: Array, mat: Material, with_beams: bool) -> void:
	for zz in rows:
		var z: float = zz
		for side in [-1.0, 1.0]:
			_box(Vector3(0.5, ROOM_H, 0.5), Vector3(side * (HW - 0.25), ROOM_H / 2.0, z), mat)
		if with_beams:
			_box(Vector3(HallsScene.W, 0.35, 0.4), Vector3(0, ROOM_H - 0.17, z), mat)

func _vines_on_walls(count: int) -> void:
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(-RD + 0.6, -1.4)
		var sz := Vector2(16, 48) * PX
		_flat(vine_tex(rng.randi_range(1, 6)), Vector3(side * (HW - 0.03), ROOM_H - sz.y / 2.0, z), sz, Vector3(0, -90.0 * side, 0))

func _vines_hanging(count: int) -> void:
	for i in count:
		var sz := Vector2(16, 48) * PX
		var x := rng.randf_range(-HW + 0.5, HW - 0.5)
		var z := rng.randf_range(-RD + 0.8, -1.8)
		_flat(vine_tex(rng.randi_range(1, 6)), Vector3(x, ROOM_H - sz.y / 2.0, z), sz, Vector3.ZERO)

func _moss_patches(count: int) -> void:
	for i in count:
		var s := 32.0 * PX
		var x := rng.randf_range(-HW + 0.6, HW - 0.6)
		_flat(moss_tex(), Vector3(x, 0.01, rng.randf_range(-RD + 0.8, -2.6)), Vector2(s, s), Vector3(-90, rng.randf_range(0, 360), 0))

func _cobwebs() -> void:
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.6:
			_flat(web_tex(), Vector3(side * (HW - 0.35), ROOM_H - 0.35, -RD + 0.05), Vector2(0.75, 0.75), Vector3(0, 0, 0 if side > 0 else 90))

## Roots: flat 16x48 root sprites (art/halls/z0_root.png) hanging from the ceiling or down
## the side walls, at the one pixel size.
func _hanging_roots(count: int, on_walls: bool) -> void:
	var tex := _tex("res://art/halls/z0_root.png")
	if tex == null:
		return
	var sz := Vector2(16, 48) * PX
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		if on_walls:
			var z := rng.randf_range(-RD + 0.6, -1.6)
			_flat(tex, Vector3(side * (HW - 0.03), ROOM_H - sz.y / 2.0, z), sz, Vector3(0, -90.0 * side, 0))
		else:
			var x := side * rng.randf_range(0.6, HW - 0.4)
			var z2 := rng.randf_range(-RD + 0.8, -1.8)
			_flat(tex, Vector3(x, ROOM_H - sz.y / 2.0, z2), sz, Vector3.ZERO)

## Fallen stone at a collapse: boulders and a broken pillar (billboards, one pixel size).
func _rubble(at: Vector3) -> void:
	_sprite(prop("boulder"), at)
	_sprite(prop("pillar_broken"), at + Vector3(signf(at.x) * 0.4, 0, -0.7))

## Everyday things along the walls. Never a chest, altar, nest or mimic: those are the room's
## one thing (the views draw it), and a second one you can't tap breaks "one thing, tap it".
const EVENT_ART := ["chest", "chest_open", "altar", "nest", "mimic"]
func _zone_props() -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	match base_kind:
		"Overgrown hall":
			_sprite(prop("sarcophagus" if zone == 1 else "crate"), Vector3(-side * (HW - 0.9), 0, -RD + 1.1))
			_sprite(prop("urn"), Vector3(side * (HW - 0.8), 0, -3.6))
			_sprite(prop("barrel"), Vector3(-side * (HW - 0.8), 0, -3.8))
		"Collapsed chamber":
			_sprite(prop("barrel"), Vector3(-HW + 1.0, 0, -RD + 0.7))
			_sprite(prop("skeleton"), Vector3(HW - 0.9, 0, -3.6))
		"Root-choked passage", "Mushroom grotto":
			_sprite(prop("boulder"), Vector3(side * (HW - 0.6), 0, -RD + 1.4))

## One cheap dressing per zone, its approved motif (claude/zone-palettes.md).
func _signature() -> void:
	match zone:
		1:   # bone niches: skulls and bones heaped at the wall feet
			for side in [-1.0, 1.0]:
				_sprite(prop("bones"), Vector3(side * 2.4, 0, -rng.randf_range(4.0, 5.0)))
				_sprite(prop("skull"), Vector3(side * 2.2, 0, -rng.randf_range(3.6, 4.4)))
		2:   # a pool of dark water on the floor, its rim rippling, a cold light in it
			var pz := -rng.randf_range(2.8, 3.6)
			var pool := _flat(_tex("res://art/halls/z2_pool_0.png"), Vector3(rng.randf_range(-0.6, 0.6), 0.012, pz), Vector2(64, 32) * PX, Vector3(-90, 0, 0))
			pool_mat = pool.material_override
			_light(Vector3(0, 0.3, pz), accent, 0.9, 2.6, false)
		3:   # glowing seams in the floor
			for i in 4:
				var z := -rng.randf_range(2.6, RD - 0.4)
				var x := rng.randf_range(-SEEN * -z + 0.6, SEEN * -z - 0.6)
				_flat(_tex("res://art/halls/z3_crack.png"), Vector3(x, 0.013, z), Vector2(32, 8) * PX, Vector3(-90, rng.randf_range(-30, 30), 0), true)
			_light(Vector3(0, 0.2, -3.6), accent, 0.8, 3.0)
		4:   # a carved eye above the middle door
			_flat(_tex("res://art/halls/z4_eye.png"), Vector3(0, HallsScene.DOOR_H + 0.55, -RD + 0.02), Vector2(32, 16) * PX, Vector3.ZERO, true)
			_light(Vector3(0, HallsScene.DOOR_H + 0.5, -RD + 0.6), accent, 0.7, 2.0, false)
		5:   # two more wisps on the far wall: the Hushwood has no fire
			if not far_lit:
				for side in [-1.0, 1.0]:
					_torch(Vector3(side * 1.0, 2.6, -RD + 0.05))
		6:   # crystal shards at the wall feet
			for i in 4:
				var side := -1.0 if i % 2 == 0 else 1.0
				_sprite(_tex("res://art/halls/z6_crystal.png"), Vector3(side * 2.4, 0, -rng.randf_range(3.4, 5.0)), false)
			_light(Vector3(0, 0.4, -4.2), accent, 0.8, 3.5, false)
		7:   # a brass pipe run along one wall, turning up the far wall (art/halls/z7_pipe.png repeats)
			var side7 := -1.0 if rng.randf() < 0.5 else 1.0
			var pipe := _tex("res://art/halls/z7_pipe.png")
			_flat(pipe, Vector3(side7 * (HW - 0.03), 3.0, -RD / 2.0), Vector2(RD, 16.0 * PX), Vector3(0, -90.0 * side7, 0))
			_flat(pipe, Vector3(side7 * (HW - 0.4), 1.5, -RD + 0.02), Vector2(3.0, 16.0 * PX), Vector3(0, 0, 90))
		8:   # gilded pillars at the far corners (art/halls/z8_pillar.png repeats upward)
			for side in [-1.0, 1.0]:
				_flat(_tex("res://art/halls/z8_pillar.png"), Vector3(side * (HW - 0.3), ROOM_H / 2.0, -RD + 0.02), Vector2(16.0 * PX, ROOM_H), Vector3.ZERO)
		9:   # rows of spikes at the wall feet
			for side in [-1.0, 1.0]:
				for k in 2:
					_sprite(_tex("res://art/halls/z9_spikes.png"), Vector3(side * 2.3, 0, -3.8 - k * 0.9), true)

## Drifting particles in the region's mood (HallsScene.MOODS kinds), palette colours.
func _region_particles() -> void:
	match fx_kind:
		"fireflies": _particles(24, Color("#d0da91"), 0.035, false)
		"dust": _particles(24, Color("#c8b08a"), 0.025, true)
		"drips": _particles(24, Color("#4fb0c6"), 0.025, true)
		"embers": _particles(24, Color("#f77622"), 0.03, false, true)
		"shadows": _particles(20, Color("#3e2731"), 0.06, false)
		"leaves": _particles(20, Color("#d0dcc8"), 0.035, true)
		"sparkles": _particles(24, Color("#f6757a"), 0.03, false)
		"sparks": _particles(24, Color("#feae34"), 0.03, false, true)
		_: _particles(20, accent, 0.03, false)

# =====================================================================
# Room types. The middle of the room (x within about 1.2 of center) stays clear:
# that's where the views draw the monster or the one thing in the room.
# Everything a phone should see stays inside |x| <= SEEN * depth.
# =====================================================================

func _overgrown_hall() -> void:
	var dark := _wall_mat(Color("#c8a060") if zone == 8 else Color(0.62, 0.62, 0.62))
	var rows: Array = []
	var z := -1.5
	while z > -RD + 0.8:
		rows.append(z)
		z -= rng.randf_range(1.8, 2.2)
	_pillars(rows, dark, true)
	_torch(Vector3(-HW + 0.08, 2.0, -4.6))
	_torch(Vector3(HW - 0.08, 2.0, -4.6))
	if rng.randf() < 0.5:
		far_lit = true
		_torch(Vector3(-1.0, 2.6, -RD + 0.05))
		_torch(Vector3(1.0, 2.6, -RD + 0.05))
	if zone == 0:
		_vines_on_walls(6)
		_vines_hanging(3)
		_hanging_roots(3, true)

func _collapsed_chamber() -> void:
	var dark := _wall_mat(Color(0.62, 0.62, 0.62))
	_light_pool(0.4, GAP_Z)
	_rubble(Vector3(-1.6, 0, GAP_Z + 0.2))
	_sprite(prop("boulder"), Vector3(2.0, 0, -4.6))
	_box(Vector3(0.5, ROOM_H, 0.5), Vector3(HW - 0.25, ROOM_H / 2.0, -1.5), dark)
	_box(Vector3(0.5, 1.1, 0.5), Vector3(-HW + 0.25, 0.55, -1.5), dark)
	_box(Vector3(0.5, 2.4, 0.5), Vector3(-HW + 0.6, 0.25, -3.3), dark, Vector3(88, 12, 0))
	_box(Vector3(HallsScene.W * 0.8, 0.3, 0.35), Vector3(0.3, 3.2, -RD + 1.4), dark, Vector3(0, 8, -14))
	_torch(Vector3(HW - 0.08, 2.0, -4.6))
	_sprite(prop("bones"), Vector3(1.9, 0, -3.0))
	_sprite(prop("skull"), Vector3(1.5, 0, -2.7))
	if zone == 0:
		_vines_on_walls(3)

func _mushroom_grotto() -> void:
	var spots := [Vector3(-1.5, 0, -3.4), Vector3(1.5, 0, -3.6), Vector3(-2.0, 0, -4.5), Vector3(2.0, 0, -4.7)]
	for sp in spots:
		var c: Vector3 = sp
		for i in rng.randi_range(2, 3):
			_sprite(prop("mushrooms"), c + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.3, 0.3)), false)
		_light(c + Vector3(0, 0.5, 0), Color("#4fb0c6"), 1.5, 3.0, false)
	_hanging_roots(4, true)
	_vines_on_walls(4)
	_vines_hanging(3)

func _forgotten_shrine() -> void:
	# the shrine's own glyph on the floor (not a trap's circle), in the zone's accent
	var rune := _flat(_tex("res://art/traps/shrine.png"), Vector3(0.0, 0.02, -3.0), Vector2(64, 64) * PX, Vector3(-90, 0, 0))
	var rm := rune.material_override as StandardMaterial3D
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = accent
	_light(Vector3(0.0, 0.3, -3.0), accent, 0.9, 2.6, false)
	for side in [-1.0, 1.0]:
		var base := Vector3(side * 1.3, 0, -2.8)
		_sprite(prop("brazier"), base, false)
		_light(base + Vector3(0, 1.2, 0.1), light_col, 1.8, 4.0)
	# one statue, and only in some shrines, so they don't stand in every room
	if rng.randf() < 0.5:
		var left := rng.randf() < 0.5
		_sprite(_zart("statue", "res://art/props/statue_hooded.png" if left else "res://art/props/statue_gargoyle.png"), Vector3((-1.0 if left else 1.0) * (HW - 0.7), 0, -RD + 0.9))
	for i in 5:
		_sprite(prop("candles"), Vector3(rng.randf_range(-HW + 0.3, -1.4) if i % 2 == 0 else rng.randf_range(1.4, HW - 0.3), 0, -RD + rng.randf_range(0.3, 0.8)), false)
	_sprite(prop("bones"), Vector3(-2.0, 0, -3.8))
	_sprite(prop("skull"), Vector3(-1.6, 0, -3.5))
	if zone == 0:
		_vines_on_walls(3)

func _root_choked() -> void:
	_hanging_roots(8, false)
	_hanging_roots(4, true)
	_vines_on_walls(6)
	_vines_hanging(5)
	_torch(Vector3(-HW + 0.08, 1.9, -4.6))
