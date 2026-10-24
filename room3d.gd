class_name Room3D
extends Node
## 0.13+: the room you stand in as a real 3D scene, rendered small into a
## SubViewport and drawn pixel-crisp as the backdrop of the room view and fights.
## Its camera matches HallsScene's one-point projection exactly (eye height,
## horizon, focal length, room size), so everything the views still draw in 2D
## on top (doors to tap, the one thing in the room, monsters, traps) lines up.
## Mossy Hollows has five room types; other regions get halls in their own stone.
## Low graphics skips this and keeps HallsScene's 2D room.

const KINDS_FOREST := ["Overgrown hall", "Collapsed chamber", "Mushroom grotto", "Forgotten shrine", "Root-choked passage"]
const KINDS_OTHER := ["Overgrown hall", "Collapsed chamber", "Forgotten shrine"]
const PIX := 2.0           # design units per rendered pixel (whole numbers keep pixels square)
const ROOM_H := HallsScene.CEIL_Y - HallsScene.FLOOR_Y   # 4.0
const HW := HallsScene.W / 2.0
const RD := HallsScene.D   # depth of the far wall

var vp: SubViewport
var cam: Camera3D
var world: Node3D        # rebuilt for every room
var root3: Node3D        # floor at local y = 0 (sits at FLOOR_Y)
var flicker: Array[OmniLight3D] = []
var mist: Array[StandardMaterial3D] = []
var clock := 0.0
var rng := RandomNumberGenerator.new()
var kind := ""
var zone := 0
var light_col := Color("#ffb35c")
var amb_col := Color("#8fae8a")
var fx_kind := "fireflies"
var _size := Vector2.ZERO
static var _texcache := {}

func _init() -> void:
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.positional_shadow_atlas_size = 1024
	vp.size = Vector2i(16, 16)

func _ready() -> void:
	add_child(vp)

func _process(delta: float) -> void:
	# only render while the view showing it is on screen
	var p := get_parent() as CanvasItem
	var on := p != null and p.is_visible_in_tree()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if not on:
		return
	clock += delta
	for i in flicker.size():
		var o := flicker[i]
		var base: float = o.get_meta("base", 2.0)
		o.light_energy = base * (1.0 + 0.11 * sin(clock * 9.0 + i * 2.1) + 0.07 * sin(clock * 23.0 + i))
	for i in mist.size():
		mist[i].uv1_offset = Vector3(clock * (0.012 + i * 0.008), clock * 0.006, 0.0)

func texture() -> Texture2D:
	return vp.get_texture()

## Matches the view's size: render at 1/PIX and set the camera to HallsScene's projection.
func fit(sz: Vector2) -> void:
	if sz == _size or sz.x < 8.0 or sz.y < 8.0:
		return
	_size = sz
	vp.size = Vector2i(maxi(8, int(sz.x / PIX)), maxi(8, int(sz.y / PIX)))
	if cam:
		_aim()

## HallsScene: screen = (w/2, 0.40 h) + focal * (x / z, -y / z), focal = 0.62 w.
## A frustum camera with the same focal length and its center shifted below the horizon.
func _aim() -> void:
	var w := _size.x
	var h := _size.y
	var f := 0.62 * w
	var n := 0.05
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = n
	cam.far = 40.0
	cam.size = n * h / f
	cam.frustum_offset = Vector2(0.0, n * (0.40 * h - 0.5 * h) / f)

## Builds the room for this floor and region. Same seed, same room.
func rebuild(zone_i: int, seed_value: int, mood: Dictionary) -> void:
	zone = zone_i
	rng.seed = seed_value
	light_col = mood.get("light", Color("#ffb35c"))
	amb_col = mood.get("amb", Color("#8fae8a"))
	fx_kind = String(mood.get("kind", "fireflies"))
	var kinds: Array = KINDS_FOREST if zone == 0 else KINDS_OTHER
	kind = kinds[rng.randi() % kinds.size()]
	flicker.clear()
	mist.clear()
	if world:
		world.queue_free()
	world = Node3D.new()
	vp.add_child(world)
	_environment(float(mood.get("dark", 0.4)))
	root3 = Node3D.new()
	root3.position = Vector3(0, HallsScene.FLOOR_Y, 0)
	world.add_child(root3)
	_shell()
	_light(Vector3(0.4, 1.2, -0.6), Color("#ffd9a0"), 1.4, 6.0, false, false)  # your lantern
	match kind:
		"Overgrown hall": _overgrown_hall()
		"Collapsed chamber": _collapsed_chamber()
		"Mushroom grotto": _mushroom_grotto()
		"Forgotten shrine": _forgotten_shrine()
		"Root-choked passage": _root_choked()
	_moss_patches(3 if zone == 0 else 1)
	_cobwebs()
	_zone_props()
	_region_particles()

# =====================================================================
# Pixel art drawn in code (original to Solaria)
# =====================================================================

static func _pix(name: String, rows: PackedStringArray, pal: Dictionary) -> ImageTexture:
	if _texcache.has(name):
		return _texcache[name]
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	var tex := ImageTexture.create_from_image(img)
	_texcache[name] = tex
	return tex

static func mushroom_tex() -> ImageTexture:
	return _pix("mushroom", PackedStringArray([
		"..cccc..", ".cCCCCc.", "cCCwCCCc", "cCCCCwCc", ".cccccc.",
		"...ss...", "...ss...", "..sss...", "...ss...", "..ssss.."]),
		{"c": Color("#1b6b6e"), "C": Color("#5ad1e6"), "w": Color("#d8fbff"), "s": Color("#c9c2a8")})

static func bones_tex() -> ImageTexture:
	return _pix("bones", PackedStringArray([
		"....ww..........", "..wwwwww...ww...", ".wWwwWWwwwwWw.ww", "wwWWwwwWWwwwwwWw",
		".wwwwwwwwwwwwww.", "..dddddddddddd.."]),
		{"w": Color("#c8c0a8"), "W": Color("#ece4cc"), "d": Color("#2a2620")})

static func skull_tex() -> ImageTexture:
	return _pix("skull", PackedStringArray([
		"..wwww..", ".wwwwww.", "wwwwwwww", "wkkwwkkw", "wkkwwkkw", "wwwkkwww", ".wwwwww.", ".w.ww.w."]),
		{"w": Color("#d6ceb4"), "k": Color("#16110d")})

static func candle_tex() -> ImageTexture:
	return _pix("candle", PackedStringArray([
		".f.", "fFf", ".F.", ".k.", "ccc", "ccc", "cCc", "ccc", "ccc"]),
		{"f": Color("#ff9a3c"), "F": Color("#fff2c0"), "k": Color("#2a1d14"), "c": Color("#d9ccaf"), "C": Color("#f2ead2")})

static func vine_tex(seed_value: int) -> ImageTexture:
	var key := "vine%d" % seed_value
	if _texcache.has(key):
		return _texcache[key]
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var img := Image.create(16, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var greens := [Color("#123a30"), Color("#1d5546"), Color("#2f7a52"), Color("#4f9a5c")]
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
	var greens := [Color("#0f2e26"), Color("#1d5546"), Color("#2f6e46"), Color("#4f8a4c")]
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			if d + r.randf_range(-0.25, 0.25) < 0.85:
				img.set_pixel(x, y, greens[mini(3, int(r.randf() * 3.4))])
	var tex := ImageTexture.create_from_image(img)
	_texcache["moss"] = tex
	return tex

static func rune_tex() -> ImageTexture:
	if _texcache.has("rune"):
		return _texcache["rune"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color("#5ad1e6")
	for a in 360:
		var v: Vector2 = Vector2.from_angle(deg_to_rad(a))
		for rr in [29.5, 28.5, 20.5]:
			var p: Vector2 = Vector2(31.5, 31.5) + v * float(rr)
			img.set_pixel(int(p.x), int(p.y), c)
	for i in 8:
		var v: Vector2 = Vector2.from_angle(TAU * i / 8.0)
		for s in range(21, 28):
			var p: Vector2 = Vector2(31.5, 31.5) + v * float(s)
			img.set_pixel(int(p.x), int(p.y), c)
	var tex := ImageTexture.create_from_image(img)
	_texcache["rune"] = tex
	return tex

static func web_tex() -> ImageTexture:
	if _texcache.has("web"):
		return _texcache["web"]
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(0.85, 0.88, 0.85, 0.55)
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

func _mat(path: String, tint := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.metallic_specular = 0.15
	m.uv1_triplanar = true
	return m

## This zone's own hall art (art/halls/z<zone>_<name>.png), or the shared fallback.
func _zart(name: String, fallback := "") -> Texture2D:
	var path := "res://art/halls/z%d_%s.png" % [zone, name]
	if ResourceLoader.exists(path):
		return load(path)
	return load(fallback) if fallback != "" else null

func _wall_mat(tint := Color.WHITE) -> StandardMaterial3D:
	return _mat("res://art/halls/z%d_wall.png" % zone, tint)

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

func _sprite(tex: Texture2D, pos: Vector3, height: float, shaded := true, billboard := true) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = height / float(tex.get_height())
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	s.shaded = shaded
	s.offset = Vector2(0, tex.get_height() / 2.0)
	s.position = pos
	root3.add_child(s)
	return s

func _flat(tex: Texture2D, pos: Vector3, size: Vector2, rot: Vector3, glow := Color(0, 0, 0, 0)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow.a > 0.0:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = glow
	else:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.roughness = 1.0
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(mi)
	return mi

func _light(pos: Vector3, color: Color, energy: float, reach: float, shadows := false, flickers := true) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.light_color = color
	o.light_energy = energy
	o.omni_range = reach
	o.omni_attenuation = 1.4
	o.shadow_enabled = shadows
	o.position = pos
	o.set_meta("base", energy)
	root3.add_child(o)
	if flickers:
		flicker.append(o)
	return o

func _along(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y).normalized() * -1.0)

func _root(a: Vector3, b: Vector3, thick: float, bend: Vector3, mat: Material) -> void:
	var segs := 8
	var prev := a
	for i in range(1, segs + 1):
		var f := float(i) / segs
		var p: Vector3 = a.lerp(b, f) + bend * sin(f * PI)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var r := thick * (1.0 - f * 0.45)
		cm.top_radius = r
		cm.bottom_radius = r * 1.08
		cm.height = prev.distance_to(p) + r * 0.6
		cm.radial_segments = 6
		mi.mesh = cm
		mi.material_override = mat
		mi.transform = Transform3D(_along(p - prev), (prev + p) / 2.0)
		root3.add_child(mi)
		prev = p

func _shaft(x: float, z: float, top: float, bottom: float, strength: float) -> void:
	var hole := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(top * 2.0, top * 2.0)
	hole.mesh = hq
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.albedo_color = Color("#b3d3b5") * 0.9
	hole.material_override = hm
	hole.rotation_degrees = Vector3(90, 0, 0)
	hole.position = Vector3(x, ROOM_H - 0.01, z)
	root3.add_child(hole)
	var spot := SpotLight3D.new()
	spot.light_color = Color("#d8e8d0")
	spot.light_energy = 1.4 * strength
	spot.spot_range = ROOM_H + 3.0
	spot.spot_angle = rad_to_deg(atan((bottom + 0.2) / ROOM_H))
	spot.shadow_enabled = true
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.position = Vector3(x, ROOM_H - 0.05, z)
	root3.add_child(spot)
	var shaft := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = top
	cone.bottom_radius = bottom
	cone.height = ROOM_H
	cone.cap_top = false
	cone.cap_bottom = false
	shaft.mesh = cone
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var k := 0.032 * strength
	sm.albedo_color = Color(0.70 * k, 0.83 * k, 0.71 * k, 1.0)  # additive: the color is the strength
	shaft.material_override = sm
	shaft.position = Vector3(x, ROOM_H / 2.0, z)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(shaft)

func _torch(pos: Vector3) -> void:
	var flame := _sprite(_zart("torch", "res://art/dungeon/torch.png"), pos - Vector3(0, 0.3, 0), 0.6, false)
	flame.modulate = Color(1.4, 1.2, 1.0)
	var push := Vector3(-signf(pos.x) * 0.3, 0.1, 0.0) if absf(pos.x) > 1.5 else Vector3(0, 0.1, 0.3)
	_light(pos + push, light_col, 2.2, 4.5, true)

func _mist_layer(y: float, strength: float) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.03
	var nt := NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.seamless = true
	nt.noise = noise
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(HallsScene.W, RD)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = nt
	var c := amb_col.lightened(0.3)
	m.albedo_color = Color(c.r * strength, c.g * strength, c.b * strength, 1.0)
	m.uv1_scale = Vector3(1.5, 1.5, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = Vector3(0, y, -RD / 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(mi)
	mist.append(m)

func _particles(count: int, color: Color, size: float, falling: bool, rising := false) -> void:
	var ff := CPUParticles3D.new()
	ff.amount = count
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

func _environment(dark: float) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.01, 0.015, 0.02)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = amb_col.darkened(0.5)
	e.ambient_light_energy = clampf(1.15 - dark, 0.4, 0.95)
	e.fog_enabled = true
	e.fog_light_color = amb_col.darkened(0.8)
	e.fog_density = 0.045 + dark * 0.05
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_bloom = 0.05
	e.glow_hdr_threshold = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	cam = Camera3D.new()
	cam.position = Vector3.ZERO  # eye height is the origin; the floor sits at FLOOR_Y
	world.add_child(cam)
	if _size != Vector2.ZERO:
		_aim()

func _shell() -> void:
	var wall := _wall_mat(Color(0.8, 0.85, 0.8) if kind == "Mushroom grotto" else Color.WHITE)
	var floor_m := _mat("res://art/halls/z%d_floor.png" % zone)
	var ceil_m := _mat("res://art/halls/z%d_ceil.png" % zone, Color(0.75, 0.78, 0.75))
	_box(Vector3(HallsScene.W, 0.2, RD + 1.0), Vector3(0, -0.1, -RD / 2.0 + 0.5), floor_m)
	if kind != "Collapsed chamber":
		_box(Vector3(HallsScene.W, 0.2, RD + 1.0), Vector3(0, ROOM_H + 0.1, -RD / 2.0 + 0.5), ceil_m)
	else:
		var gap_z := -RD * 0.42
		_box(Vector3(HallsScene.W, 0.2, RD * 0.42 + 0.6), Vector3(0, ROOM_H + 0.1, gap_z / 2.0 + 0.15), ceil_m)
		_box(Vector3(HallsScene.W, 0.2, RD * 0.42), Vector3(0, ROOM_H + 0.1, -RD + RD * 0.21), ceil_m)
		_box(Vector3(HallsScene.W * 0.35, 0.2, 1.4), Vector3(-HallsScene.W * 0.33, ROOM_H + 0.1, gap_z - 0.6), ceil_m)
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(-HW - 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(HW + 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	# far wall with three arched doorways (CSG), at HallsScene's door spots
	var dark := _wall_mat(Color(0.62, 0.66, 0.6))
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
		_sprite(_zart("door", "res://art/halls/door.png"), Vector3(x, 0.0, -RD - 0.25), dh * 0.98, true, false)

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
		var length := rng.randf_range(1.0, 2.2)
		_flat(vine_tex(rng.randi_range(1, 6)), Vector3(side * (HW - 0.03), ROOM_H - length / 2.0, z), Vector2(length / 3.0, length), Vector3(0, -90.0 * side, 0))

func _vines_hanging(count: int) -> void:
	for i in count:
		var length := rng.randf_range(0.8, 1.6)
		var x := rng.randf_range(-HW + 0.5, HW - 0.5)
		var z := rng.randf_range(-RD + 0.8, -1.8)
		_flat(vine_tex(rng.randi_range(1, 6)), Vector3(x, ROOM_H - length / 2.0, z), Vector2(length / 3.0, length), Vector3.ZERO)

func _moss_patches(count: int) -> void:
	for i in count:
		var s := rng.randf_range(0.6, 1.0)
		var x := rng.randf_range(-HW + 0.6, HW - 0.6)
		_flat(moss_tex(), Vector3(x, 0.01, rng.randf_range(-RD + 0.8, -2.6)), Vector2(s, s), Vector3(-90, rng.randf_range(0, 360), 0))

func _cobwebs() -> void:
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.6:
			_flat(web_tex(), Vector3(side * (HW - 0.35), ROOM_H - 0.35, -RD + 0.05), Vector2(0.7, 0.7), Vector3(0, 0, 0 if side > 0 else 90))

func _root_mat() -> StandardMaterial3D:
	return _mat("res://art/halls/z%d_ceil.png" % zone, Color(0.78, 0.58, 0.42))

func _corner_roots(count: int) -> void:
	var mat := _root_mat()
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(-RD + 0.8, -1.6)
		_root(Vector3(side * HW, rng.randf_range(1.5, ROOM_H), z), Vector3(side * (HW - rng.randf_range(0.6, 1.1)), 0.0, z + rng.randf_range(-0.5, 0.5)), 0.09, Vector3(side * 0.25, 0.1, 0), mat)

func _rubble(center: Vector3, spread: float, count: int, mat: Material) -> void:
	for i in count:
		var s := rng.randf_range(0.12, 0.38)
		var off := Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread * 0.7, spread * 0.7))
		var height := maxf(0.0, (1.0 - off.length() / spread)) * 0.3
		_box(Vector3(s, s * 0.7, s * 0.9), center + off + Vector3(0, height + s * 0.3, 0), mat, Vector3(rng.randf_range(0, 40), rng.randf_range(0, 360), rng.randf_range(0, 40)))

## The zone's own props (chest, altar, statue) where it has them, at the room's sides.
func _zone_props() -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var chest := _zart("chest")
	var altar := _zart("altar")
	var statue := _zart("statue")
	match kind:
		"Overgrown hall":
			if statue:
				_sprite(statue, Vector3(side * (HW - 0.6), 0, -RD + 0.8), 1.5)
			if chest:
				_sprite(chest, Vector3(-side * (HW - 0.65), 0, -RD + 1.1), 0.5)
		"Collapsed chamber":
			if chest:
				_sprite(chest, Vector3(-HW + 0.8, 0, -RD + 0.7), 0.5)
		"Forgotten shrine":
			if altar:
				_sprite(altar, Vector3(side * (HW - 0.55), 0, -3.1), 0.7)

## Drifting particles in the region's mood (HallsScene.MOODS kinds).
func _region_particles() -> void:
	match fx_kind:
		"fireflies": _particles(28, Color("#d8f07a") * 1.6, 0.035, false)
		"dust": _particles(36, Color("#d8cbb0"), 0.025, true)
		"drips": _particles(30, Color("#a8e6ff"), 0.025, true)
		"embers": _particles(36, Color("#ff8c3a") * 1.6, 0.03, false, true)
		"shadows": _particles(24, Color("#3a2f55"), 0.06, false)
		"leaves": _particles(24, Color("#b8f5d0"), 0.035, true)
		"sparkles": _particles(30, Color("#ffd0f5") * 1.5, 0.03, false)
		"sparks": _particles(30, Color("#ffcf6b") * 1.5, 0.03, false, true)
		_: _particles(20, light_col.lightened(0.4), 0.03, false)

# =====================================================================
# Room types. The middle of the room (x within about 1.2 of center) stays clear:
# that's where the views draw the monster or the one thing in the room.
# =====================================================================

func _overgrown_hall() -> void:
	var dark := _wall_mat(Color(0.62, 0.66, 0.6))
	var rows: Array = []
	var z := -1.5
	while z > -RD + 0.8:
		rows.append(z)
		z -= rng.randf_range(1.8, 2.2)
	_pillars(rows, dark, true)
	_torch(Vector3(-HW + 0.08, 2.0, -RD * 0.65))
	_torch(Vector3(HW - 0.08, 2.0, -RD * 0.65))
	if rng.randf() < 0.5:
		_torch(Vector3(-1.0, 2.6, -RD + 0.05))
		_torch(Vector3(1.0, 2.6, -RD + 0.05))
	if zone == 0:
		_vines_on_walls(6)
		_vines_hanging(3)
		_corner_roots(3)
	if rng.randf() < 0.45:
		_shaft(rng.randf_range(-0.5, 0.5), -2.6, 0.28, 0.7, 0.7)
	_mist_layer(0.1, 0.025)

func _collapsed_chamber() -> void:
	var wall := _wall_mat()
	var dark := _wall_mat(Color(0.62, 0.66, 0.6))
	var gap_z := -RD * 0.42 - 0.3
	_shaft(0.4, gap_z, 0.55, 0.95, 1.2)
	_rubble(Vector3(-2.0, 0, gap_z - 0.2), 0.9, 18, wall)
	_rubble(Vector3(2.1, 0, -RD + 1.0), 0.6, 8, wall)
	_box(Vector3(0.5, ROOM_H, 0.5), Vector3(HW - 0.25, ROOM_H / 2.0, -1.5), dark)
	_box(Vector3(0.5, 1.1, 0.5), Vector3(-HW + 0.25, 0.55, -1.5), dark)
	_box(Vector3(0.5, 2.4, 0.5), Vector3(-HW + 0.6, 0.25, -3.3), dark, Vector3(88, 12, 0))
	_box(Vector3(HallsScene.W * 0.8, 0.3, 0.35), Vector3(0.3, 3.2, -RD + 1.4), dark, Vector3(0, 8, -14))
	_torch(Vector3(HW - 0.08, 2.0, -RD * 0.7))
	_sprite(bones_tex(), Vector3(1.9, 0, -3.0), 0.3)
	_sprite(skull_tex(), Vector3(1.6, 0, -2.8), 0.22)
	if zone == 0:
		_vines_on_walls(3)

func _mushroom_grotto() -> void:
	var spots := [Vector3(-HW + 1.0, 0, -2.6), Vector3(HW - 1.0, 0, -3.0), Vector3(-HW + 0.9, 0, -RD + 1.2), Vector3(HW - 0.9, 0, -RD + 1.0)]
	for sp in spots:
		var c: Vector3 = sp
		for i in rng.randi_range(4, 7):
			var h := rng.randf_range(0.28, 0.7)
			var s := _sprite(mushroom_tex(), c + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)), h, false)
			s.modulate = Color(1.3, 1.3, 1.3)
		_light(c + Vector3(0, 0.5, 0), Color("#5ad1e6"), 1.5, 3.0, false, false)
	_corner_roots(4)
	_vines_on_walls(4)
	_vines_hanging(3)
	_mist_layer(0.1, 0.03)

func _forgotten_shrine() -> void:
	_flat(rune_tex(), Vector3(0.0, 0.02, -2.9), Vector2(2.2, 2.2), Vector3(-90, rng.randf_range(0, 45), 0), Color(0.35, 1.0, 1.1, 1.0))
	_light(Vector3(0.0, 0.3, -2.9), Color("#5ad1e6"), 0.9, 2.6, false, false)
	for side in [-1.0, 1.0]:
		var base := Vector3(side * 2.0, 0, -1.8)
		var bowl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22
		cm.bottom_radius = 0.1
		cm.height = 0.9
		cm.radial_segments = 8
		bowl.mesh = cm
		var metal := StandardMaterial3D.new()
		metal.albedo_color = Color("#2a2622")
		metal.metallic = 0.6
		metal.roughness = 0.5
		bowl.material_override = metal
		bowl.position = base + Vector3(0, 0.45, 0)
		root3.add_child(bowl)
		var flame := _sprite(load("res://art/dungeon/torch.png"), base + Vector3(0, 0.75, 0), 0.5, false)
		flame.modulate = Color(1.5, 1.2, 1.0)
		_light(base + Vector3(0, 1.2, 0.1), light_col, 1.8, 4.0, true)
	_sprite(_zart("statue", "res://art/dungeon/statue_0.png"), Vector3(-HW + 0.7, 0, -RD + 0.9), 1.6)
	_sprite(_zart("statue", "res://art/dungeon/statue_2.png"), Vector3(HW - 0.7, 0, -RD + 0.9), 1.6)
	for i in 5:
		var c := _sprite(candle_tex(), Vector3(rng.randf_range(-HW + 0.3, -1.4) if i % 2 == 0 else rng.randf_range(1.4, HW - 0.3), 0, -RD + rng.randf_range(0.3, 0.8)), rng.randf_range(0.16, 0.26), false)
		c.modulate = Color(1.2, 1.15, 1.1)
	_sprite(bones_tex(), Vector3(-2.0, 0, -3.8), 0.3)
	_sprite(skull_tex(), Vector3(-1.7, 0, -3.6), 0.22)
	if zone == 0:
		_vines_on_walls(3)

func _root_choked() -> void:
	var mat := _root_mat()
	var z := -1.6
	while z > -RD + 0.8:
		var lean := rng.randf_range(-0.5, 0.5)
		_root(Vector3(-HW, 0.0, z), Vector3(HW, 0.0, z + lean), rng.randf_range(0.14, 0.2), Vector3(0, ROOM_H * 0.95, rng.randf_range(-0.3, 0.3)), mat)
		z -= rng.randf_range(1.4, 1.9)
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var zz := rng.randf_range(-RD + 1.0, -1.6)
		_root(Vector3(side * HW, ROOM_H, zz), Vector3(side * rng.randf_range(1.6, 2.4), 0.0, zz + rng.randf_range(-0.8, 0.8)), 0.1, Vector3(0, 0.4, 0), mat)
	_corner_roots(3)
	_vines_on_walls(6)
	_vines_hanging(5)
	_torch(Vector3(-HW + 0.08, 1.9, -RD * 0.55))
	_particles(30, Color("#d8f07a") * 1.7, 0.035, false)
	_mist_layer(0.1, 0.03)
