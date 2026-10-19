extends Control
## PROTOTYPE (not used by the game): Mossy Hollows rooms as real 3D scenes,
## rendered small and scaled up with nearest filtering so every pixel stays crisp.
## Each room picks one of five room types and lays itself out from a seed.
## Open proto/room3d.tscn and press F6: Space/Enter shows the next room.

const RES := Vector2i(208, 304)   # render size; shown at a whole-number scale
const SCALE := 2
const KINDS := ["Overgrown hall", "Collapsed chamber", "Mushroom grotto", "Forgotten shrine", "Root-choked passage"]
const DOOR_X := [-1.9, 0.0, 1.9]
const DOOR_W := 1.15
const DOOR_H := 2.0

# Mossy Hollows mood (art direction palette)
const SHADOW := Color("#06161a")
const MOSS := Color("#1d5546")
const BONE := Color("#b3d3b5")
const FIREFLY := Color("#d8f07a")
const TORCH := Color("#ffb35c")
const SHROOM := Color("#5ad1e6")

var vp: SubViewport
var cam: Camera3D
var world: Node3D
var flicker: Array[OmniLight3D] = []
var mist: Array[StandardMaterial3D] = []
var beast: Sprite3D
var clock := 0.0
var rng := RandomNumberGenerator.new()
var room_w := 6.0
var room_d := 7.0
var room_h := 4.2
var kind := 0
var room_seed := 1
var monster_mode := 0      # 0 flat sprite, 1 normal-mapped, 2 voxel
var _texcache := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	vp = SubViewport.new()
	vp.size = RES
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.positional_shadow_atlas_size = 2048
	add_child(vp)
	var shown := TextureRect.new()
	shown.texture = vp.get_texture()
	shown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shown.stretch_mode = TextureRect.STRETCH_SCALE
	shown.size = Vector2(RES * SCALE)
	add_child(shown)
	rebuild(kind, room_seed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		rebuild((kind + 1) % KINDS.size(), room_seed + 1)

func _process(delta: float) -> void:
	clock += delta
	for i in flicker.size():
		var o := flicker[i]
		var base: float = o.get_meta("base", 2.0)
		o.light_energy = base * (1.0 + 0.11 * sin(clock * 9.0 + i * 2.1) + 0.07 * sin(clock * 23.0 + i))
	for i in mist.size():
		mist[i].uv1_offset = Vector3(clock * (0.012 + i * 0.008), clock * 0.006, 0.0)
	if beast:
		beast.position.y = 0.02 * sin(clock * 2.0)

## The rendered frame at display size (for screenshots).
func frame() -> Image:
	var img := vp.get_texture().get_image()
	img.resize(RES.x * SCALE, RES.y * SCALE, Image.INTERPOLATE_NEAREST)
	return img

## Builds a room of the given type, laid out from the seed.
func rebuild(room_kind: int, seed_value: int) -> void:
	kind = room_kind
	room_seed = seed_value
	if vp == null:
		return  # _ready builds it once the viewport exists
	rng.seed = hash("%d-%d" % [room_kind, seed_value])
	flicker.clear()
	mist.clear()
	beast = null
	if world:
		world.queue_free()
	world = Node3D.new()
	vp.add_child(world)
	match kind:
		4:
			room_w = 4.8
			room_h = 3.5
			room_d = rng.randf_range(6.5, 7.5)
		2:
			room_w = rng.randf_range(5.6, 6.6)
			room_h = rng.randf_range(3.8, 4.4)
			room_d = rng.randf_range(6.0, 7.0)
		_:
			room_w = rng.randf_range(5.6, 6.6)
			room_h = rng.randf_range(4.0, 4.8)
			room_d = rng.randf_range(6.2, 7.4)
	_environment()
	_shell()
	_lantern()
	match kind:
		0: _overgrown_hall()
		1: _collapsed_chamber()
		2: _mushroom_grotto()
		3: _forgotten_shrine()
		4: _root_choked()
	_moss_patches(4 if kind != 1 else 2)
	_cobwebs()
	_monster()

# =====================================================================
# Pixel art drawn in code (original to Solaria)
# =====================================================================

func _pix(name: String, rows: PackedStringArray, pal: Dictionary) -> ImageTexture:
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

func _mushroom_tex() -> ImageTexture:
	return _pix("mushroom", PackedStringArray([
		"..cccc..", ".cCCCCc.", "cCCwCCCc", "cCCCCwCc", ".cccccc.",
		"...ss...", "...ss...", "..sss...", "...ss...", "..ssss.."]),
		{"c": Color("#1b6b6e"), "C": SHROOM, "w": Color("#d8fbff"), "s": Color("#c9c2a8")})

func _bones_tex() -> ImageTexture:
	return _pix("bones", PackedStringArray([
		"....ww..........", "..wwwwww...ww...", ".wWwwWWwwwwWw.ww", "wwWWwwwWWwwwwwWw",
		".wwwwwwwwwwwwww.", "..dddddddddddd.."]),
		{"w": Color("#c8c0a8"), "W": Color("#ece4cc"), "d": Color("#2a2620")})

func _skull_tex() -> ImageTexture:
	return _pix("skull", PackedStringArray([
		"..wwww..", ".wwwwww.", "wwwwwwww", "wkkwwkkw", "wkkwwkkw", "wwwkkwww", ".wwwwww.", ".w.ww.w."]),
		{"w": Color("#d6ceb4"), "k": Color("#16110d")})

func _candle_tex() -> ImageTexture:
	return _pix("candle", PackedStringArray([
		".f.", "fFf", ".F.", ".k.", "ccc", "ccc", "cCc", "ccc", "ccc"]),
		{"f": Color("#ff9a3c"), "F": Color("#fff2c0"), "k": Color("#2a1d14"), "c": Color("#d9ccaf"), "C": Color("#f2ead2")})

func _vine_tex(seed_value: int) -> ImageTexture:
	var key := "vine%d" % seed_value
	if _texcache.has(key):
		return _texcache[key]
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var img := Image.create(16, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var greens := [Color("#123a30"), MOSS, Color("#2f7a52"), Color("#4f9a5c")]
	var x := 0
	while x < 16:
		var length := r.randi_range(12, 48)
		var wob := 0
		for y in length:
			if r.randf() < 0.15:
				wob = clampi(wob + r.randi_range(-1, 1), -1, 1)
			var px := clampi(x + wob, 0, 15)
			img.set_pixel(px, y, greens[r.randi_range(0, 2)])
			if r.randf() < 0.18:
				img.set_pixel(clampi(px + (1 if r.randf() < 0.5 else -1), 0, 15), y, greens[3])
		x += r.randi_range(2, 4)
	var tex := ImageTexture.create_from_image(img)
	_texcache[key] = tex
	return tex

func _moss_tex() -> ImageTexture:
	if _texcache.has("moss"):
		return _texcache["moss"]
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var greens := [Color("#0f2e26"), MOSS, Color("#2f6e46"), Color("#4f8a4c")]
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			if d + r.randf_range(-0.25, 0.25) < 0.85:
				img.set_pixel(x, y, greens[mini(3, int(r.randf() * 3.4))])
	var tex := ImageTexture.create_from_image(img)
	_texcache["moss"] = tex
	return tex

func _rune_tex() -> ImageTexture:
	if _texcache.has("rune"):
		return _texcache["rune"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(SHROOM.r, SHROOM.g, SHROOM.b, 1.0)
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
		var q: Vector2 = Vector2(31.5, 31.5) + v.rotated(TAU / 16.0) * 24.5
		img.set_pixel(int(q.x), int(q.y), c)
		img.set_pixel(int(q.x) + 1, int(q.y), c)
	var tex := ImageTexture.create_from_image(img)
	_texcache["rune"] = tex
	return tex

func _web_tex() -> ImageTexture:
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

func _box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	world.add_child(mi)
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
	world.add_child(s)
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
	world.add_child(mi)
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
	world.add_child(o)
	if flickers:
		flicker.append(o)
	return o

## A Y-up basis pointing along dir (for cylinders).
func _along(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y).normalized() * -1.0)

## A thick bent root from a to b, sagging by `bend`.
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
		world.add_child(mi)
		prev = p

func _shaft(x: float, z: float, top: float, bottom: float, strength: float) -> void:
	var hole := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(top * 2.0, top * 2.0)
	hole.mesh = hq
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.albedo_color = BONE * 0.9
	hole.material_override = hm
	hole.rotation_degrees = Vector3(90, 0, 0)
	hole.position = Vector3(x, room_h - 0.01, z)
	world.add_child(hole)
	var spot := SpotLight3D.new()
	spot.light_color = BONE
	spot.light_energy = 1.4 * strength
	spot.spot_range = room_h + 3.0
	spot.spot_angle = rad_to_deg(atan((bottom + 0.2) / room_h))
	spot.shadow_enabled = true
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.position = Vector3(x, room_h - 0.05, z)
	world.add_child(spot)
	var shaft := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = top
	cone.bottom_radius = bottom
	cone.height = room_h
	cone.cap_top = false
	cone.cap_bottom = false
	shaft.mesh = cone
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var k := 0.032 * strength
	sm.albedo_color = Color(BONE.r * k, BONE.g * k * 1.1, BONE.b * k, 1.0)  # additive: the color is the strength
	shaft.material_override = sm
	shaft.position = Vector3(x, room_h / 2.0, z)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(shaft)

func _torch(pos: Vector3) -> void:
	var flame := _sprite(load("res://art/dungeon/torch.png"), pos - Vector3(0, 0.3, 0), 0.6, false)
	flame.modulate = Color(1.4, 1.2, 1.0)
	var push := Vector3(-signf(pos.x) * 0.3, 0.1, 0.0) if absf(pos.x) > 1.5 else Vector3(0, 0.1, 0.3)
	_light(pos + push, TORCH, 2.2, 4.5, true)

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
	q.size = Vector2(room_w, room_d)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = nt
	m.albedo_color = Color(BONE.r * strength, BONE.g * strength * 1.1, BONE.b * strength, 1.0)
	m.uv1_scale = Vector3(1.5, 1.5, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = Vector3(0, y, -room_d / 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	mist.append(m)

func _particles(count: int, color: Color, size: float, falling: bool) -> void:
	var ff := CPUParticles3D.new()
	ff.amount = count
	ff.lifetime = 6.0
	ff.preprocess = 6.0
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(room_w / 2.0 - 0.4, room_h / 2.0 - 0.6, room_d / 2.0 - 0.6)
	ff.position = Vector3(0, room_h / 2.0, -room_d / 2.0 - 0.3)
	ff.gravity = Vector3(0, -0.05, 0) if falling else Vector3.ZERO
	ff.direction = Vector3(0, -1, 0) if falling else Vector3(0, 1, 0)
	ff.spread = 30.0 if falling else 180.0
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
	world.add_child(ff)

# =====================================================================
# Every room
# =====================================================================

func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = SHADOW
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = MOSS
	e.ambient_light_energy = 0.7 if kind == 2 else 0.55
	e.fog_enabled = true
	e.fog_light_color = Color("#0d2a2c")
	e.fog_density = [0.09, 0.07, 0.13, 0.08, 0.11][kind]
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_bloom = 0.05
	e.glow_hdr_threshold = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	cam = Camera3D.new()
	cam.position = Vector3(0, 1.45, 0.4)
	cam.rotation_degrees = Vector3(-4, 0, 0)
	cam.fov = 70.0
	cam.far = 30.0
	world.add_child(cam)

func _shell() -> void:
	var wall := _mat("res://art/halls/z0_wall.png", Color(0.8, 0.85, 0.8) if kind == 2 else Color.WHITE)
	var floor_m := _mat("res://art/halls/z0_floor.png")
	var ceil_m := _mat("res://art/halls/z0_ceil.png", Color(0.7, 0.75, 0.7))
	var hw := room_w / 2.0
	_box(Vector3(room_w, 0.2, room_d + 1.0), Vector3(0, -0.1, -room_d / 2.0), floor_m)
	if kind != 1:
		_box(Vector3(room_w, 0.2, room_d + 1.0), Vector3(0, room_h + 0.1, -room_d / 2.0), ceil_m)
	else:
		# a broken ceiling: two slabs with a ragged gap between them
		var gap_z := -room_d * 0.42
		_box(Vector3(room_w, 0.2, room_d * 0.42 + 0.3), Vector3(0, room_h + 0.1, (gap_z + 1.0) / 2.0 - 0.6), ceil_m)
		_box(Vector3(room_w, 0.2, room_d * 0.45), Vector3(0, room_h + 0.1, -room_d + room_d * 0.225 + 0.2), ceil_m)
		_box(Vector3(room_w * 0.35, 0.2, 1.6), Vector3(-room_w * 0.33, room_h + 0.1, gap_z - 0.6), ceil_m)
	_box(Vector3(0.4, room_h, room_d + 1.0), Vector3(-hw - 0.2, room_h / 2.0, -room_d / 2.0), wall)
	_box(Vector3(0.4, room_h, room_d + 1.0), Vector3(hw + 0.2, room_h / 2.0, -room_d / 2.0), wall)
	# far wall with three arched doorways (CSG)
	var dark := _mat("res://art/halls/z0_wall.png", Color(0.62, 0.66, 0.6))
	var far := CSGCombiner3D.new()
	world.add_child(far)
	var slab := CSGBox3D.new()
	slab.size = Vector3(room_w, room_h, 0.6)
	slab.position = Vector3(0, room_h / 2.0, -room_d - 0.3)
	slab.material = wall
	far.add_child(slab)
	for dx in DOOR_X:
		var x: float = dx
		var cut := CSGBox3D.new()
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.size = Vector3(DOOR_W, DOOR_H - DOOR_W / 2.0, 0.4)
		cut.position = Vector3(x, (DOOR_H - DOOR_W / 2.0) / 2.0, -room_d - 0.1)
		cut.material = dark
		far.add_child(cut)
		var arch := CSGCylinder3D.new()
		arch.operation = CSGShape3D.OPERATION_SUBTRACTION
		arch.radius = DOOR_W / 2.0
		arch.height = 0.4
		arch.sides = 12
		arch.rotation_degrees = Vector3(90, 0, 0)
		arch.position = Vector3(x, DOOR_H - DOOR_W / 2.0, -room_d - 0.1)
		arch.material = dark
		far.add_child(arch)
		_sprite(load("res://art/dungeon/door_closed.png"), Vector3(x, 0.0, -room_d - 0.28), DOOR_H * 0.98, true, false)

func _lantern() -> void:
	_light(Vector3(0.4, 1.2, -0.4), Color("#ffd9a0"), 1.1, 5.5, false, false)

func _monster() -> void:
	var e_art: Dictionary = Sprites.enemy_by_key(["barghest", "boggart", "redcap", "kobold"][room_seed % 4])
	if e_art.is_empty():
		return
	var tex: Texture2D = e_art["tex"]
	match monster_mode:
		1: _monster_lit(tex, Vector3(0.1, 0, -2.9), 1.35)
		2: _monster_voxel(tex, Vector3(0.1, 0, -2.9), 1.35)
		_: beast = _sprite(tex, Vector3(0.1, 0, -2.9), 1.35)

## How far each opaque pixel is from the sprite's edge (chamfer distance).
func _edge_distance(img: Image) -> PackedFloat32Array:
	var w := img.get_width()
	var h := img.get_height()
	var d := PackedFloat32Array()
	d.resize(w * h)
	for y in h:
		for x in w:
			d[y * w + x] = 0.0 if img.get_pixel(x, y).a < 0.5 else 999.0
	for pass_i in 2:
		var ys := range(h) if pass_i == 0 else range(h - 1, -1, -1)
		var xs := range(w) if pass_i == 0 else range(w - 1, -1, -1)
		var step := -1 if pass_i == 0 else 1
		for y in ys:
			for x in xs:
				var i: int = y * w + x
				if d[i] == 0.0:
					continue
				var best: float = d[i]
				for o in [Vector2i(step, 0), Vector2i(0, step), Vector2i(step, step), Vector2i(-step, step)]:
					var ox: int = x + o.x
					var oy: int = y + o.y
					var cost := 1.4 if o.x != 0 and o.y != 0 else 1.0
					if ox < 0 or oy < 0 or ox >= w or oy >= h:
						best = minf(best, cost)
					else:
						best = minf(best, d[oy * w + ox] + cost)
				d[i] = best
	return d

## Option 1: the flat sprite plus a normal map made from its shape, so light wraps around it.
func _monster_lit(tex: Texture2D, pos: Vector3, height: float) -> void:
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var dist := _edge_distance(img)
	var nimg := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var hl := sqrt(dist[y * w + maxi(x - 1, 0)])
			var hr := sqrt(dist[y * w + mini(x + 1, w - 1)])
			var hu := sqrt(dist[maxi(y - 1, 0) * w + x])
			var hd := sqrt(dist[mini(y + 1, h - 1) * w + x])
			var lum := img.get_pixel(x, y).get_luminance() * 0.6
			var n := Vector3(-(hr - hl) * 1.1 - lum * 0.0, (hd - hu) * 1.1, 1.0).normalized()
			nimg.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(nimg)
	m.normal_scale = 1.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(height * w / float(h), height)
	q.center_offset = Vector3(0, height / 2.0, 0)
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	world.add_child(mi)

## Option 2: every pixel becomes a cube; thicker toward the middle of the body.
func _monster_voxel(tex: Texture2D, pos: Vector3, height: float) -> void:
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var dist := _edge_distance(img)
	var px := height / float(h)
	var depth := PackedInt32Array()
	depth.resize(w * h)
	for i in w * h:
		depth[i] = 0 if dist[i] == 0.0 else 6  # one even thickness: sides only around the outline
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in h:
		for x in w:
			var dd: int = depth[y * w + x]
			if dd == 0:
				continue
			var c := img.get_pixel(x, y)
			c.a = 1.0
			var x0 := (x - w / 2.0) * px
			var y1 := (h - y) * px
			var y0 := y1 - px
			var zf := dd * px * 0.5
			var zb := -zf
			_face(st, c, Vector3(x0, y0, zf), Vector3(x0 + px, y0, zf), Vector3(x0 + px, y1, zf), Vector3(x0, y1, zf), Vector3.BACK)
			_face(st, c * 0.6, Vector3(x0 + px, y0, zb), Vector3(x0, y0, zb), Vector3(x0, y1, zb), Vector3(x0 + px, y1, zb), Vector3.FORWARD)
			var nbrs := [[x - 1, y, Vector3.LEFT], [x + 1, y, Vector3.RIGHT], [x, y - 1, Vector3.UP], [x, y + 1, Vector3.DOWN]]
			for nb in nbrs:
				var nx: int = nb[0]
				var ny: int = nb[1]
				var other := 0 if nx < 0 or ny < 0 or nx >= w or ny >= h else depth[ny * w + nx]
				if other >= dd:
					continue

				var nrm: Vector3 = nb[2]
				var sc := c * 0.85
				if nrm == Vector3.LEFT:
					_face(st, sc, Vector3(x0, y0, -zf), Vector3(x0, y0, zf), Vector3(x0, y1, zf), Vector3(x0, y1, -zf), nrm)
				elif nrm == Vector3.RIGHT:
					_face(st, sc, Vector3(x0 + px, y0, zf), Vector3(x0 + px, y0, -zf), Vector3(x0 + px, y1, -zf), Vector3(x0 + px, y1, zf), nrm)
				elif nrm == Vector3.UP:
					_face(st, sc, Vector3(x0, y1, zf), Vector3(x0 + px, y1, zf), Vector3(x0 + px, y1, -zf), Vector3(x0, y1, -zf), nrm)
				else:
					_face(st, sc, Vector3(x0, y0, -zf), Vector3(x0 + px, y0, -zf), Vector3(x0 + px, y0, zf), Vector3(x0, y0, zf), nrm)
	var mesh := st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	world.add_child(mi)

## One quad (a, b, c, d counter-clockwise seen from outside) with a flat color.
func _face(st: SurfaceTool, col: Color, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3) -> void:
	st.set_color(col)
	st.set_normal(nrm)
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)

func _pillars(rows: Array, mat: Material, with_beams: bool) -> void:
	var hw := room_w / 2.0
	for zz in rows:
		var z: float = zz
		for side in [-1.0, 1.0]:
			_box(Vector3(0.5, room_h, 0.5), Vector3(side * (hw - 0.25), room_h / 2.0, z), mat)
		if with_beams:
			_box(Vector3(room_w, 0.35, 0.4), Vector3(0, room_h - 0.17, z), mat)

func _vines_on_walls(count: int) -> void:
	var hw := room_w / 2.0
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(-room_d + 0.6, -1.2)
		var length := rng.randf_range(1.0, 2.2)
		_flat(_vine_tex(rng.randi_range(1, 6)), Vector3(side * (hw - 0.03), room_h - length / 2.0, z), Vector2(length / 3.0, length), Vector3(0, -90.0 * side, 0))

func _vines_hanging(count: int) -> void:
	for i in count:
		var length := rng.randf_range(0.8, 1.9)
		var x := rng.randf_range(-room_w / 2.0 + 0.5, room_w / 2.0 - 0.5)
		var z := rng.randf_range(-room_d + 0.8, -1.4)
		_flat(_vine_tex(rng.randi_range(1, 6)), Vector3(x, room_h - length / 2.0, z), Vector2(length / 3.0, length), Vector3.ZERO)

func _moss_patches(count: int) -> void:
	for i in count:
		var s := rng.randf_range(0.8, 1.6)
		var x := rng.randf_range(-room_w / 2.0 + 0.5, room_w / 2.0 - 0.5)
		_flat(_moss_tex(), Vector3(x, 0.01, rng.randf_range(-room_d + 0.8, -1.0)), Vector2(s, s), Vector3(-90, rng.randf_range(0, 360), 0))

func _cobwebs() -> void:
	var hw := room_w / 2.0
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.7:
			_flat(_web_tex(), Vector3(side * (hw - 0.35), room_h - 0.35, -room_d + 0.05), Vector2(0.7, 0.7), Vector3(0, 0, 0 if side > 0 else 90))

func _root_mat() -> StandardMaterial3D:
	return _mat("res://art/halls/z0_ceil.png", Color(0.78, 0.58, 0.42))

func _corner_roots(count: int) -> void:
	var hw := room_w / 2.0
	var mat := _root_mat()
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(-room_d + 0.8, -1.5)
		_root(Vector3(side * hw, rng.randf_range(1.5, room_h), z), Vector3(side * (hw - rng.randf_range(0.6, 1.2)), 0.0, z + rng.randf_range(-0.6, 0.6)), 0.09, Vector3(side * 0.25, 0.1, 0), mat)

func _rubble(center: Vector3, spread: float, count: int, mat: Material) -> void:
	for i in count:
		var s := rng.randf_range(0.12, 0.42)
		var off := Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread * 0.7, spread * 0.7))
		var height := maxf(0.0, (1.0 - off.length() / spread)) * 0.35
		_box(Vector3(s, s * 0.7, s * 0.9), center + off + Vector3(0, height + s * 0.3, 0), mat, Vector3(rng.randf_range(0, 40), rng.randf_range(0, 360), rng.randf_range(0, 40)))

# =====================================================================
# The five room types
# =====================================================================

## Pillars and beams wrapped in vines, roots in the corners, torchlight.
func _overgrown_hall() -> void:
	var dark := _mat("res://art/halls/z0_wall.png", Color(0.62, 0.66, 0.6))
	var rows: Array = []
	var z := -1.6
	while z > -room_d + 0.8:
		rows.append(z)
		z -= rng.randf_range(1.8, 2.2)
	_pillars(rows, dark, true)
	var hw := room_w / 2.0
	_torch(Vector3(-hw + 0.08, 2.0, -room_d * 0.65))
	_torch(Vector3(hw - 0.08, 2.0, -room_d * 0.65))
	if rng.randf() < 0.6:
		_torch(Vector3(rng.randf_range(-1.2, -0.8), 2.2, -room_d + 0.05))
		_torch(Vector3(rng.randf_range(0.8, 1.2), 2.2, -room_d + 0.05))
	_vines_on_walls(6)
	_vines_hanging(3)
	_corner_roots(3)
	if rng.randf() < 0.5:
		_shaft(rng.randf_range(-0.5, 0.6), -2.8, 0.28, 0.7, 1.0)
	_sprite(load("res://art/dungeon/statue_1.png"), Vector3(-hw + 0.85, 0, -room_d * 0.72), 1.5)
	_sprite(load("res://art/dungeon/pot.png"), Vector3(hw - 0.7, 0, -2.4), 0.55)
	_particles(30, FIREFLY * 1.6, 0.035, false)
	_mist_layer(0.1, 0.025)

## The ceiling has caved in: a strong shaft of light on a heap of rubble.
func _collapsed_chamber() -> void:
	var wall := _mat("res://art/halls/z0_wall.png")
	var dark := _mat("res://art/halls/z0_wall.png", Color(0.62, 0.66, 0.6))
	var hw := room_w / 2.0
	var gap_z := -room_d * 0.42 - 0.3
	_shaft(0.4, gap_z, 0.55, 0.95, 1.2)
	_rubble(Vector3(-1.2, 0, gap_z - 0.2), 1.1, 22, wall)
	_rubble(Vector3(1.9, 0, -room_d + 1.2), 0.6, 8, wall)
	# one standing pillar, one broken stump and its fallen top
	_box(Vector3(0.5, room_h, 0.5), Vector3(hw - 0.25, room_h / 2.0, -1.6), dark)
	_box(Vector3(0.5, 1.1, 0.5), Vector3(-hw + 0.25, 0.55, -1.6), dark)
	_box(Vector3(0.5, 2.6, 0.5), Vector3(-hw + 1.4, 0.25, -2.5), dark, Vector3(0, 25, 84))
	# a beam that came down at an angle
	_box(Vector3(room_w * 0.8, 0.3, 0.35), Vector3(0.3, 1.2, -room_d + 1.6), dark, Vector3(0, 8, -22))
	_torch(Vector3(hw - 0.08, 2.0, -room_d * 0.7))
	_sprite(_bones_tex(), Vector3(1.4, 0, -2.2), 0.3)
	_sprite(_skull_tex(), Vector3(1.0, 0, -2.0), 0.22)
	_vines_on_walls(3)
	_particles(40, Color(BONE.r, BONE.g, BONE.b) * 0.9, 0.025, true)

## No torches: glowing mushrooms are the only light, under heavy mist.
func _mushroom_grotto() -> void:
	var hw := room_w / 2.0
	var spots := [Vector3(-hw + 0.9, 0, -1.4), Vector3(hw - 0.9, 0, -2.3), Vector3(-hw + 1.0, 0, -room_d + 1.4), Vector3(hw - 1.1, 0, -room_d + 1.0)]
	for sp in spots:
		var c: Vector3 = sp
		for i in rng.randi_range(4, 7):
			var h := rng.randf_range(0.28, 0.75)
			var s := _sprite(_mushroom_tex(), c + Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.4, 0.4)), h, false)
			s.modulate = Color(1.3, 1.3, 1.3)
		_light(c + Vector3(0, 0.5, 0), SHROOM, 1.5, 3.0, false, false)
	_corner_roots(4)
	_vines_on_walls(4)
	_vines_hanging(4)
	_rubble(Vector3(0.0, 0, -room_d + 0.9), 0.8, 6, _mat("res://art/halls/z0_wall.png", Color(0.6, 0.7, 0.7)))
	_particles(44, FIREFLY * 1.5, 0.03, false)
	_mist_layer(0.1, 0.03)

## An old shrine: a glowing rune circle, braziers, candles and statues.
func _forgotten_shrine() -> void:
	var hw := room_w / 2.0
	_flat(_rune_tex(), Vector3(0.1, 0.02, -2.9), Vector2(2.4, 2.4), Vector3(-90, rng.randf_range(0, 45), 0), Color(0.35, 1.0, 1.1, 1.0))
	_light(Vector3(0.1, 0.3, -2.9), SHROOM, 0.9, 2.6, false, false)
	for side in [-1.0, 1.0]:
		var base := Vector3(side * 1.6, 0, -1.9)
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
		world.add_child(bowl)
		var flame := _sprite(load("res://art/dungeon/torch.png"), base + Vector3(0, 0.75, 0), 0.5, false)
		flame.modulate = Color(1.5, 1.2, 1.0)
		_light(base + Vector3(0, 1.2, 0.1), TORCH, 1.8, 4.0, true)
	_sprite(load("res://art/dungeon/statue_0.png"), Vector3(-hw + 0.7, 0, -room_d + 1.0), 1.6)
	_sprite(load("res://art/dungeon/statue_2.png"), Vector3(hw - 0.7, 0, -room_d + 1.0), 1.6)
	for i in 6:
		var c := _sprite(_candle_tex(), Vector3(rng.randf_range(-0.9, 0.9), 0, -room_d + rng.randf_range(0.4, 0.9)), rng.randf_range(0.16, 0.26), false)
		c.modulate = Color(1.2, 1.15, 1.1)
	_light(Vector3(0, 0.5, -room_d + 0.8), TORCH, 0.9, 2.5)
	_sprite(_bones_tex(), Vector3(-1.5, 0, -3.8), 0.3)
	_sprite(_skull_tex(), Vector3(-1.1, 0, -3.6), 0.22)
	_vines_on_walls(3)
	if rng.randf() < 0.6:
		_shaft(0.1, -2.9, 0.22, 0.75, 0.8)
	_particles(18, FIREFLY * 1.5, 0.03, false)

## Narrow and choked by giant roots that arch over the walls and ceiling.
func _root_choked() -> void:
	var hw := room_w / 2.0
	var mat := _root_mat()
	var z := -1.4
	while z > -room_d + 0.8:
		var lean := rng.randf_range(-0.6, 0.6)
		_root(Vector3(-hw, 0.0, z), Vector3(hw, 0.0, z + lean), rng.randf_range(0.16, 0.24), Vector3(0, room_h * 0.95, rng.randf_range(-0.3, 0.3)), mat)
		z -= rng.randf_range(1.3, 1.9)
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var zz := rng.randf_range(-room_d + 1.0, -1.5)
		_root(Vector3(side * hw, room_h, zz), Vector3(side * rng.randf_range(0.3, 1.2), 0.0, zz + rng.randf_range(-1.0, 1.0)), 0.11, Vector3(0, 0.4, 0), mat)
	_corner_roots(4)
	_vines_on_walls(6)
	_vines_hanging(7)
	_torch(Vector3(-hw + 0.08, 1.9, -room_d * 0.55))
	if rng.randf() < 0.5:
		_shaft(rng.randf_range(-0.4, 0.4), -room_d * 0.5, 0.25, 0.8, 0.8)
	_particles(60, FIREFLY * 1.7, 0.035, false)
	_mist_layer(0.1, 0.03)
