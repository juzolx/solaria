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
const HERO_X := 0.9            # the hero's column on the floor: |x| < HERO_X ...
const HERO_Z := Vector2(2.2, 4.2)   # ... between these depths (his back sprite hides it)
const GLYPH := Vector2(-1.65, 3.6)  # the shrine glyph (x, depth): the trap circle's mirror, its edge clear of the hair
const HAIR_K := 0.14       # the hero's hair is 0.14 * depth wide each side of the middle (87 design px at z 3.6... on the floor)
const CLEAR_X := 1.0       # standing props keep |x| - half >= this: the middle is the hero's, the monster's (face-off) and the room's one thing
const TRAP_SIZE := 64.0 * PX   # the trap ring and the glyph: 64 art px
## The fight's floor (x, depth): every monster stands centred between the doors (Juzo's face-off,
## battle_view), the widest 2x ones within |x| < 1.4. In a room where a fight can happen no standing
## prop's foot meets it, so a monster never overlaps one.
const FIGHT_CLEAR := Rect2(-1.4, 3.2, 2.8, 2.3)
const PALE_FLAME := {"fff4a3": "ffffff", "fee761": "d0dcc8", "feae34": "c0cbdc", "f77622": "c0cbdc", "d77643": "8b9bb4",
	"e43b44": "8b9bb4", "ff0044": "8b9bb4", "be4a2f": "5a6988"}
const GLOW_W := HallsScene.DOOR_W * 1.4   # a door's foot glow, world units wide
const FAR_TORCH_BASE := 3.0   # a far-wall torch's art base on a tall view: over the side labels ("?" at 19 px)
const FIGHT_EVENTS := ["", "chest", "gate"]   # fight rooms (and ambushes), mimics, champions
## The face-off monster's box on screen (Juzo: monsters never overlap props): big monsters'
## solid pixels span 0.21..0.79 of the width down to 0.71 of the height at 430.
const MONSTER_BOX := Rect2(0.20, 0.0, 0.60, 0.72)
## Each layout's horizon (share of the height) and height / width: the 430 phone, the SE.
const LAYOUT_TALL := Vector2(0.40, 615.0 / 504.0)
const LAYOUT_SMALL := Vector2(0.28, 443.0 / 504.0)
const FRAME_TEXEL := 0.062   # world units per door-frame texel: about one viewport pixel at the far wall
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
var built_key := ""     # the HallsScene room this world shows ("" while building)
var horizon := 0.40     # the horizon's height as a share of the view (HallsScene.center.y / h)
var event := ""         # the room's one thing (Halls prop kind), so the layout can match it
var small := false      # a short screen: the shrine glyph sits deeper, with the trap circle
var marks: Array = []   # per door [frame, glow] MeshInstance3D: the pick-a-door highlight, inside the room
var trap_ring: MeshInstance3D = null   # a spotted trap's circle, in the room so nearer props cover it
var trap_rim: MeshInstance3D = null    # its outline-black rim (shown when the trap is the accent's colour)
var standing: Array = []   # every standing prop placed: [x, depth, half width, height, file] (tests read this)
var keepout: Array = []    # floor the standing props stay off (Rect2 in x, depth): pillars, decals, 2D props' spots
var torch_z := Vector2(4.6, 4.6)   # the side torches' depths (HallsScene rolls them)
var _fresh := 0            # frames to render every frame after a rebuild (the wipe)
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
var _aimed_h := 0.40
static var _texcache := {}
static var _far_mesh := {}   # zone -> the far wall baked from its CSG once (CSG rebuilds are slow on phones)
var _far_csg: CSGCombiner3D = null
static var in_hero: Array = []    # floor art placed where the hero stands over it (tests read this)
static var _pad := {}              # texture -> transparent rows under its base (art px)
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
	# only render while the view showing it is on screen, and at 30 Hz (room view and fights:
	# only the flicker moves; the views draw what moves on top)
	var p := get_parent() as CanvasItem
	var on := p != null and p.is_visible_in_tree()
	if not on:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_frame += 1
	if _fresh > 0:
		_fresh -= 1   # the first frames after a rebuild, under the wipe, every frame
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	elif _frame % 2 == 0:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE   # only the flicker moves (9-23 Hz): 30 Hz is enough
	else:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	clock += delta
	for i in flicker.size():
		var o := flicker[i]
		var base: float = o.get_meta("base", 2.0)
		o.light_energy = base * (1.0 + 0.11 * sin(clock * 9.0 + i * 2.1) + 0.07 * sin(clock * 23.0 + i))
	if portal:
		portal.texture = _tex("res://art/halls/portal_1.png" if int(clock * 4.0) % 2 else "res://art/halls/portal.png")
	if _far_csg and is_instance_valid(_far_csg) and not _far_mesh.has(zone):
		# CSG builds its mesh a frame late; keep it for every later room in this zone
		var baked := _far_csg.bake_static_mesh()
		if baked and baked.get_surface_count() > 0:
			_far_mesh[zone] = baked.duplicate()
			_far_csg = null
	if pool_mat:
		pool_mat.albedo_texture = pool_tex(int(clock * 2.0) % 2)

func texture() -> Texture2D:
	return vp.get_texture()

## Matches the view: one viewport pixel = ArtStyle.unit(scr) SCREEN pixels (3 on a phone),
## the same as every sprite, and the camera keeps HallsScene's projection. sz is the view's
## design size, scr its canvas scale (design px -> screen px).
func fit(sz: Vector2, scr := 1.0) -> void:
	if (sz == _size and is_equal_approx(scr, _scr) and _aimed_h == horizon) or sz.x < 8.0 or sz.y < 8.0:
		return
	_aimed_h = horizon
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
	cam.frustum_offset = Vector2(n * (0.5 * ds.x - 0.5 * w) / f, n * (horizon * h - 0.5 * ds.y) / f)

## Builds the room for this floor and region. Same seed, same room.
func rebuild(zone_i: int, seed_value: int, mood: Dictionary) -> void:
	zone = zone_i
	rng.seed = seed_value
	light_col = mood.get("light", Color("#feae34"))
	amb_col = mood.get("amb", Color("#566a56"))
	accent = mood.get("accent", light_col)
	fx_kind = String(mood.get("kind", "fireflies"))
	gate = bool(mood.get("gate", false))
	event = String(mood.get("event", ""))
	small = bool(mood.get("small", false))
	torch_z = mood.get("torch_z", Vector2(4.6, 4.6))
	standing = []
	keepout = []
	trap_ring = null
	trap_rim = null
	_fresh = 4
	built_key = ""
	var kinds: Array = KINDS_FOREST if zone == 0 else KINDS_OTHER
	var ki := rng.randi() % kinds.size()
	# the shrine layout says "pray here": it holds the altar and nothing else
	var shrine := kinds.find("Forgotten shrine")
	if event == "altar":
		ki = shrine
	elif event != "" and ki == shrine:
		ki = (ki + 1) % kinds.size()
	base_kind = kinds[ki]
	kind = base_kind if not NAMES.has(zone) else String(NAMES[zone][ki])
	if event == "camp":
		keepout.append(Rect2(-HW, 1.5, HW - 0.4, 2.4))
	if event in FIGHT_EVENTS:
		keepout.append(FIGHT_CLEAR)   # the monster's floor in the middle
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
	_trap_marks()
	built_key = String(mood.get("key", ""))

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

## A hall tile with its outline black (#0e0812) turned into the zone's deep colour: several
## PixelLab tiles are mostly outline, and no light lifts a black texel (Fable round 3).
static func tile_image(path: String, zi: int) -> Image:
	var t := _tex(path)
	if t == null:
		return null
	var img := t.get_image().duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var deep: Color = HallsScene.MOODS[clampi(zi, 0, HallsScene.MOODS.size() - 1)]["deep"]
	var data := img.get_data()
	for i in range(0, data.size(), 4):
		if data[i] == 14 and data[i + 1] == 8 and data[i + 2] == 18:
			data[i] = deep.r8
			data[i + 1] = deep.g8
			data[i + 2] = deep.b8
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)

static func _tile_tex(path: String, zi: int) -> Texture2D:
	var key := "tile|%s|%d" % [path, zi]
	# the zone's own tiles come remapped already (tools/hall_tiles_deep.gd): no pixel loop on a phone
	var baked := path.get_basename() + "_deep.png"
	if not _texcache.has(key) and path.get_file().begins_with("z%d_" % zi) and ResourceLoader.exists(baked):
		_texcache[key] = load(baked)
	if not _texcache.has(key):
		var img := tile_image(path, zi)
		_texcache[key] = ImageTexture.create_from_image(img) if img else null
	return _texcache[key]

## A tiled wall/floor/ceiling material, cached by texture, tint and zone: TEXELS texels per world unit.
func _mat(path: String, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "mat|%s|%s|%d" % [path, tint.to_html(), zone]
	if _texcache.has(key):
		return _texcache[key]
	var m := StandardMaterial3D.new()
	var t := _tile_tex(path, zone)
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
	if pos.y - size.y / 2.0 < 0.2 and size.y > 0.5 and absf(pos.x) < HW and rot == Vector3.ZERO:   # posts, not the floor slab
		keepout.append(Rect2(pos.x - size.x / 2.0, -pos.z - size.z / 2.0, size.x, size.z))   # props don't stand in it
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
	# the art's lowest opaque row sits on pos (no transparent rows lifting it off the floor)
	s.offset = Vector2(0, tex.get_height() / 2.0 - base_pad(tex)) if tex else Vector2.ZERO
	s.position = pos
	root3.add_child(s)
	if billboard:
		var what := tex.resource_path.get_file() if tex else "sprite"
		_check_seen(pos, what, _half_w(tex) * px)
		if pos.y < 0.01:
			_contact_shadow(pos, _half_w(tex) * px)
			standing.append([pos.x, -pos.z, _half_w(tex) * px, base_height(tex) * px, what])
	return s

## Transparent rows under a texture's lowest opaque pixel (art px). Cached.
static func base_pad(tex: Texture2D) -> int:
	if tex == null:
		return 0
	var k := tex.resource_path if tex.resource_path != "" else str(tex.get_rid().get_id())
	if not _pad.has(k):
		var img := tex.get_image()
		_pad[k] = tex.get_height() - img.get_used_rect().end.y if img else 0
	return _pad[k]

## The opaque height of a texture's art (art px).
static func base_height(tex: Texture2D) -> int:
	var img := tex.get_image() if tex else null
	return img.get_used_rect().size.y if img else 0

## The standing props this room placed, in world units: {x, z (depth), w (width), h (height), art}.
## battle_view's tests project them to check a monster never meets one.
func standing_props() -> Array:
	var out: Array = []
	for s in standing:
		out.append({"x": s[0], "z": s[1], "w": float(s[2]) * 2.0, "h": s[3], "art": s[4]})
	return out

## True when a standing prop (x, depth, half its width, its height) may stand there: on screen,
## inside the walls, out of the middle (hero, face-off monster, the room's one thing), clear
## of the three doorways (or short enough to stay under their feet), off pillars and floor
## decals, and not hiding the base of a prop already standing (or hidden by it).
func spot_ok(x: float, z: float, half: float, h: float) -> bool:
	if absf(x) + half > minf(SEEN * z, HW - 0.05) or absf(x) - half < CLEAR_X:
		return false
	if not door_clear(x, z, half, h):
		return false
	var foot := Rect2(x - half, z - 0.15, half * 2.0, 0.3)
	for r in keepout:
		if foot.intersects(r):
			return false
	for s in standing:
		if stacks([x, z, half, h], s):
			return false
	if event in FIGHT_EVENTS and not monster_clear(x, z, half, h, LAYOUT_SMALL if small else LAYOUT_TALL):
		return false
	return true

## A prop [x, depth, half width, height] stays off the face-off monster's box (MONSTER_BOX) in a
## layout (horizon share, height / width): wholly beside it, or its top below it.
static func monster_clear(x: float, z: float, half: float, h: float, layout: Vector2) -> bool:
	var f := 0.62   # focal, in widths
	if absf(x) - half >= (0.5 - MONSTER_BOX.position.x) / f * z:
		return true
	return layout.x + f / layout.y * (-HallsScene.FLOOR_Y - h) / z >= MONSTER_BOX.end.y

## A standing prop is clear of every doorway at the far wall (by 0.1), or its top stays below
## the doors' feet on screen.
static func door_clear(x: float, z: float, half: float, h: float) -> bool:
	var eye := -HallsScene.FLOOR_Y
	if (eye - h) / z >= eye / RD:
		return true
	var lo := (x - half) * RD / z
	var hi := (x + half) * RD / z
	for dx in HallsScene.DOOR_X:
		if hi > float(dx) - HallsScene.DOOR_W / 2.0 - 0.1 and lo < float(dx) + HallsScene.DOOR_W / 2.0 + 0.1:
			return false
	return true

## Two standing props [x, depth, half, height] overlap on screen so the nearer one's top
## covers the farther one's base (or they stand at one spot).
static func stacks(a: Array, b: Array) -> bool:
	var near: Array = a if float(a[1]) <= float(b[1]) else b
	var far: Array = b if near == a else a
	if absf(float(a[0]) - float(b[0])) < 0.05 and absf(float(a[1]) - float(b[1])) < 0.05:
		return true
	var nl := (float(near[0]) - float(near[2])) / float(near[1])
	var nr := (float(near[0]) + float(near[2])) / float(near[1])
	var fl := (float(far[0]) - float(far[2])) / float(far[1])
	var fr := (float(far[0]) + float(far[2])) / float(far[1])
	if nr <= fl or nl >= fr:
		return false
	var eye := -HallsScene.FLOOR_Y
	return (eye - float(near[3])) / float(near[1]) < eye / float(far[1])

## Stands tex somewhere spot_ok allows on one side (side 0: either) between two depths, or
## nowhere (null) when there's no room: a bare corner beats a prop in a doorway.
func _place(tex: Texture2D, side: float, zlo: float, zhi: float, shaded := true) -> Sprite3D:
	if tex == null:
		return null
	var half := _half_w(tex) * PX
	var h := base_height(tex) * PX
	for i in 40:
		var sd := side if side != 0.0 else (-1.0 if rng.randf() < 0.5 else 1.0)
		var z := rng.randf_range(zlo, zhi)
		var xlo := CLEAR_X + half
		if (-HallsScene.FLOOR_Y - h) / z < -HallsScene.FLOOR_Y / RD:
			# tall enough to reach the doors: only beside the outer doors' edge (plus 0.1)
			xlo = maxf(xlo, (HallsScene.DOOR_X[2] + HallsScene.DOOR_W / 2.0 + 0.1) * z / RD + half + 0.001)
		if event in FIGHT_EVENTS:   # beside the monster's box
			xlo = maxf(xlo, (0.5 - MONSTER_BOX.position.x) / 0.62 * z + half + 0.001)
		var xhi := minf(SEEN * z, HW - 0.05) - half
		if xhi < xlo:
			continue
		var x := sd * rng.randf_range(xlo, xhi)
		if spot_ok(x, z, half, h):
			return _sprite(tex, Vector3(x, 0, -z), shaded)
	return null

## The spotted trap's circle in the room (built hidden): an unshaded quad of the trap's art and
## an outline-black copy a touch larger under it, like the shrine glyph.
func _trap_marks() -> void:
	trap_rim = _trap_quad(Color("#0e0812"), 0.015, 1.03)
	trap_ring = _trap_quad(Color.WHITE, 0.02, 1.0)

func _trap_quad(col: Color, y: float, s: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(TRAP_SIZE, TRAP_SIZE) * s
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mi.material_override = m
	mi.position = Vector3(0, y, -3.6)
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.visible = false
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(mi)
	return mi

## The Flooded Depths pool's frame f, its water lifted off the floor's colours (the #4fb0c6 rim
## and #c0cbdc glints stay).
static func pool_tex(f: int) -> Texture2D:
	return recoloured("res://art/halls/z2_pool_%d.png" % f, {"253a5e": "3a4466", "172038": "253a5e"})

## A texture with some palette colours swapped (hex -> hex). Cached.
static func recoloured(path: String, swaps: Dictionary) -> Texture2D:
	var key := "re|%s|%s" % [path, str(swaps)]
	if not _texcache.has(key):
		var src := _tex(path)
		var img := src.get_image() if src else null
		if img == null:
			return src
		img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var swap := {}
		for k in swaps:
			swap[Color(String(k)).to_rgba32()] = Color(String(swaps[k]))
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var k2 := Color(c, 1.0).to_rgba32()
				if c.a > 0.0 and swap.has(k2):
					img.set_pixel(x, y, Color(swap[k2], c.a))
		var tex := ImageTexture.create_from_image(img)
		tex.resource_name = path.get_file()
		_texcache[key] = tex
	return _texcache[key]

## Shows (on) or hides the trap circle: its art, colour (the view pulses it in two steps),
## rim, and spot (x, depth).
func mark_trap(tex: Texture2D, col: Color, rim: bool, x: float, z: float, on: bool) -> void:
	if trap_ring == null:
		return
	trap_ring.visible = on and tex != null
	trap_rim.visible = on and rim and tex != null
	if not on or tex == null:
		return
	for mi in [trap_ring, trap_rim]:
		(mi as MeshInstance3D).position.x = x
		(mi as MeshInstance3D).position.z = -z
		((mi as MeshInstance3D).material_override as StandardMaterial3D).albedo_texture = tex
	(trap_ring.material_override as StandardMaterial3D).albedo_color = Color(col, 1.0)

## A soft dark oval on the floor under a standing prop, so it sits on the floor (no lights cast shadows).
func _contact_shadow(pos: Vector3, half: float) -> void:
	var tex := _tex("res://art/fx/shadow.png")
	if tex == null:
		return
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * PX
	mi.mesh = q
	var key := "shadow|mat"
	if not _texcache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_texcache[key] = m
	mi.material_override = _texcache[key]
	mi.position = Vector3(pos.x, 0.006, pos.z)
	mi.rotation_degrees = Vector3(-90, 0, 0)
	var w := clampf(half * 2.4 / q.size.x, 0.3, 2.0)   # a bit wider than the art's opaque width
	mi.scale = Vector3(w, w, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root3.add_child(mi)

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

## A flat quad of art at the one pixel size. Materials are shared by texture, size, glow and
## tint (own = true for one the caller changes afterwards). Floor quads (rot.x = -90) must be
## on screen and centred out of the hero's column (|x| < HERO_X, HERO_Z near..far), where he'd hide them.
func _flat(tex: Texture2D, pos: Vector3, size: Vector2, rot: Vector3, glow := false, tint := Color.WHITE, own := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	if is_equal_approx(rot.x, -90.0):
		var what := tex.resource_path.get_file() if tex else "flat"
		_check_seen(pos, what, size.x / 2.0)
		if absf(pos.x) - size.x / 2.0 < HAIR_K * -pos.z + 0.05 and -pos.z > HERO_Z.x and -pos.z < HERO_Z.y:   # its edge, by the hair
			in_hero.append("z%d %s %s at %s" % [zone, kind, what, pos])
	var mkey := "flat|%d|%s|%s|%s" % [tex.get_rid().get_id() if tex else 0, size, glow, tint.to_html()]
	if not own and _texcache.has(mkey):
		mi.material_override = _texcache[mkey]
		mi.position = pos
		mi.rotation_degrees = rot
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3.add_child(mi)
		return mi
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
	if not own:
		_texcache[mkey] = m
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
## Half a door label's widest text (HallsScene.LABEL_MAX_W) at the far wall, in world units
## (the narrowest view, 480 design px, makes it widest).
const LABEL_HALF := HallsScene.LABEL_MAX_W / 2.0 * RD / (0.62 * 480.0)

## Where the far wall's two torches (or wisps) hang, clear of the door frames and the labels:
## on a tall view above the side labels and beside the middle one's text; on a short view
## (the SE) only in the gap between the doors' frames and labels, if the art is that narrow.
## Empty: none fit.
func far_torch_spots() -> Array:
	var art := _tex("res://art/halls/z5_wisp.png") if zone == 5 else _zart("torch", "res://art/dungeon/torch.png")
	var half := _half_w(art) * PX
	var lift := 0.25 if zone == 5 else 0.45   # _torch's art base under its spot
	var frame_in := HallsScene.DOOR_W / 2.0 + 2.0 * FRAME_TEXEL   # door 1's frame edge
	var frame_out := HallsScene.DOOR_X[2] - HallsScene.DOOR_W / 2.0 - 2.0 * FRAME_TEXEL
	var x := maxf(LABEL_HALF, frame_in) + half + 0.02
	if not small and base_height(art) * PX + FAR_TORCH_BASE <= ROOM_H - 0.05:
		return [Vector3(-x, FAR_TORCH_BASE + lift, -RD + 0.05), Vector3(x, FAR_TORCH_BASE + lift, -RD + 0.05)]
	if x + half <= minf(frame_out, HallsScene.DOOR_X[2] - LABEL_HALF) - 0.02:
		return [Vector3(-x, 2.6, -RD + 0.05), Vector3(x, 2.6, -RD + 0.05)]
	return []

func _torch(pos: Vector3, energy := 2.2) -> void:
	# a side-wall torch at a shallow rolled depth would hang outside a phone's view: push it
	# deeper along its wall until its whole art is seen (the z8 sconce is the widest)
	var art := _tex("res://art/halls/z5_wisp.png") if zone == 5 else _zart("torch", "res://art/dungeon/torch.png")
	var half := _half_w(art) * PX
	pos.z = minf(pos.z, -(absf(pos.x) + half) / SEEN - 0.001)
	_check_seen(pos, "torch")
	if zone == 5:
		var wisp := _sprite(_tex("res://art/halls/z5_wisp.png"), pos - Vector3(0, 0.25, 0), false, true)
		wisp.position.x = clampf(wisp.position.x, -SEEN * -pos.z, SEEN * -pos.z)
		_light(pos + Vector3(-signf(pos.x) * 0.3, 0.1, 0.0), accent, energy + 0.2, 4.5)
		return
	_sprite(art, pos - Vector3(0, 0.45, 0), false)
	var push := Vector3(-signf(pos.x) * 0.3, 0.1, 0.0) if absf(pos.x) > 1.5 else Vector3(0, 0.1, 0.3)
	_light(pos + push, light_col, energy, 4.5)

## A pool of light on the floor (under a hole in the ceiling): the glow sprite in hard steps.
func _glyph_z() -> float:
	return 4.0 if small else GLYPH.y

func _light_pool(x: float, z: float) -> void:
	_flat(_tex("res://art/fx/glow.png"), Vector3(x, 0.015, z), Vector2(32, 16) * PX, Vector3(-90, 0, 0), true, Color(light_col, 0.55))
	_light(Vector3(x, ROOM_H - 0.4, z), light_col, 1.6, ROOM_H + 1.0, false)
	# light seen through the hole above, so it reads as an opening, not a black box
	var glow := _tex("res://art/fx/glow.png")
	_flat(glow, Vector3(x, ROOM_H + 0.3, z), Vector2(64, 32) * PX, Vector3(90, 0, 0), true, Color(light_col, 0.6))
	_flat(glow, Vector3(x - 1.0, ROOM_H + 0.35, z - 0.3), Vector2(32, 16) * PX, Vector3(90, 0, 0), true, Color(light_col, 0.4))

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
	e.ambient_light_color = amb_col.darkened(0.35)
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
	_light(Vector3(0, ROOM_H - 1.3, -1.6), amb_col, 0.6, 5.5, false)   # under the beams, so their undersides aren't black
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(-HW - 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	_box(Vector3(0.4, ROOM_H, RD + 1.0), Vector3(HW + 0.2, ROOM_H / 2.0, -RD / 2.0 + 0.5), wall)
	# far wall with three arched doorways (CSG), at HallsScene's door spots
	var dark := _wall_mat(Color(0.62, 0.62, 0.62))
	_far_csg = null
	if _far_mesh.has(zone):
		var fm := MeshInstance3D.new()
		fm.mesh = _far_mesh[zone]
		root3.add_child(fm)
	var far := CSGCombiner3D.new()
	if not _far_mesh.has(zone):
		root3.add_child(far)
		_far_csg = far
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
			var dm := Color.WHITE.lerp(amb_col, 0.3)
			door.modulate = Color(maxf(dm.r, 0.8), maxf(dm.g, 0.8), maxf(dm.b, 0.8))   # a touch of the zone, never dim
	if far.get_parent() == null:
		far.free()   # the baked wall stands in for it
	_door_marks()

## The pick-a-door frame and foot glow live in the room, not drawn flat over it, so a prop in
## front of a door covers them the way it covers the door (drawn over, it seemed to float in
## the doorway: Juzo). Hidden until HallsScene.draw_doors marks a door.
func _door_marks() -> void:
	marks = []
	var frame := frame_tex()
	var glow := _tex("res://art/fx/glow.png")
	for dx in HallsScene.DOOR_X:
		var x: float = dx
		var fm := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(frame.get_width(), frame.get_height()) * FRAME_TEXEL
		fm.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_texture = frame
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.vertex_color_use_as_albedo = false
		fm.material_override = m
		fm.position = Vector3(x, HallsScene.DOOR_H / 2.0, -RD + 0.03)
		fm.visible = false
		root3.add_child(fm)
		var gm := MeshInstance3D.new()
		var gq := QuadMesh.new()
		gq.size = Vector2(32, 16) * PX
		gm.mesh = gq
		var g := StandardMaterial3D.new()
		g.albedo_texture = glow
		g.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.material_override = g
		gm.position = Vector3(x, 0.02, -RD + 0.35)
		gm.rotation_degrees = Vector3(-90, 0, 0)
		# narrower than the doors' spacing (1.9), so a safe and a danger glow never blend between doors
		gm.scale = Vector3(GLOW_W, GLOW_W * 0.6, 1.0)
		gm.visible = false
		root3.add_child(gm)
		marks.append([fm, gm])

## Shows door i's highlight (frame colour, its pulse alpha, the foot glow's alpha); hide with a = 0.
func mark_door(i: int, col: Color, a: float, glow_a: float, glow_col := Color(-1, 0, 0)) -> void:
	if i < 0 or i >= marks.size():
		return
	var fm: MeshInstance3D = marks[i][0]
	var gm: MeshInstance3D = marks[i][1]
	fm.visible = a > 0.0
	gm.visible = a > 0.0 and glow_a > 0.0
	# hard texels can't fade: the pulse dims the colour in two steps instead
	(fm.material_override as StandardMaterial3D).albedo_color = Color(col, 1.0) if a >= 0.75 else Color(col.darkened(0.25), 1.0)
	(gm.material_override as StandardMaterial3D).albedo_color = Color(col if glow_col.r < 0.0 else glow_col, glow_a)

## The door frame: a ring of FRAME_TEXEL-sized texels round the arch (about one viewport pixel
## each on a phone, = 3 screen px): an outline-black outer ring, one white ring tinted by the door's colour.
static func frame_tex() -> Texture2D:
	var key := "frame|tex"
	if _texcache.has(key):
		return _texcache[key]
	var w := int(roundf(HallsScene.DOOR_W / FRAME_TEXEL)) + 4
	var h := int(roundf(HallsScene.DOOR_H / FRAME_TEXEL)) + 4
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var ring := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if ring == 0:
				img.set_pixel(x, y, Color("#0e0812"))
			elif ring == 1:
				img.set_pixel(x, y, Color.WHITE)
	var t := ImageTexture.create_from_image(img)
	_texcache[key] = t
	return t

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
		var z := rng.randf_range(-RD + 0.8, -2.6)
		var x := rng.randf_range(HERO_X + s / 2.0, SEEN * -z - s / 2.0) * (-1.0 if i % 2 == 0 else 1.0)
		_flat(moss_tex(), Vector3(x, 0.01, z), Vector2(s, s), Vector3(-90, rng.randf_range(0, 360), 0))

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
## Everyday things along the walls. Never a chest, altar, nest or mimic: those are the room's
## one thing (the views draw it), and a second one you can't tap breaks "one thing, tap it".
const EVENT_ART := ["chest", "chest_open", "altar", "nest", "mimic"]
## Each zone's own everyday things, so halls in different zones aren't one picture recoloured.
const DRESS := {0: ["urn", "barrel"], 1: ["sarcophagus", "urn"], 2: ["urn", "boulder"], 3: ["crate", "boulder"],
	4: ["urn", "crate"], 5: ["barrel", "urn"], 6: ["urn", "crate"], 7: ["crate", "barrel"], 8: ["urn", "urn"], 9: ["skeleton", "boulder"]}
func _zone_props() -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var dress: Array = DRESS.get(zone, ["urn", "barrel"])
	match base_kind:
		"Overgrown hall":
			_place(prop(dress[0]), side, 3.2, 4.6)
			_place(prop(dress[1]), -side, 3.2, 4.6)
		"Collapsed chamber":   # the rubble is its dressing
			_place(prop("skeleton"), 1.0, 3.4, 4.6)
		"Root-choked passage", "Mushroom grotto":
			_place(prop("boulder"), side, 3.4, 4.6)

## One cheap dressing per zone, its approved motif (claude/zone-palettes.md).
func _signature() -> void:
	match zone:
		1:   # bone niches: skulls and bones heaped at the wall feet
			for side in [-1.0, 1.0]:
				_place(prop("bones"), side, 3.2, 3.6)   # small props near, or they're 12-px thumbnails
				_place(prop("skull"), side, 3.2, 3.6)
		2:   # a pool of dark water on the floor, its rim rippling, a cold light in it
			var pz := -rng.randf_range(2.8, 3.6)
			var ps := -1.0 if rng.randf() < 0.5 else 1.0
			ps = 1.0     # right, off the shrine glyph on the left
			pz = -4.3    # near enough to read as water (at 4.9 it was a 1-texel dash), right of the monster's box
			keepout.append(Rect2(ps * 2.0 - 1.0, -pz - 0.5, 2.0, 1.0))
			# unshaded with a lifted body: shaded, its blues were the floor's own under the blue light
			var pool := _flat(pool_tex(0), Vector3(ps * 2.0, 0.012, pz), Vector2(64, 32) * PX, Vector3(-90, 0, 0), true, Color.WHITE, true)
			pool_mat = pool.material_override
			_light(Vector3(ps * 2.0, 0.5, pz), accent, 2.2, 3.0, false)
		3:   # glowing seams in the floor
			for i in 4:
				var z := -rng.randf_range(2.6, RD - 0.4)
				var x := rng.randf_range(HERO_X + 0.6, SEEN * -z - 0.6) * (-1.0 if i % 2 == 0 else 1.0)
				_flat(_tex("res://art/halls/z3_crack.png"), Vector3(x, 0.013, z), Vector2(32, 8) * PX, Vector3(-90, rng.randf_range(-30, 30), 0), true)
			_light(Vector3(0, 0.2, -3.6), accent, 0.8, 3.0)
		4:   # a carved eye above the middle door
			_flat(_tex("res://art/halls/z4_eye.png"), Vector3(0, HallsScene.DOOR_H + 0.55, -RD + 0.02), Vector2(32, 16) * PX, Vector3.ZERO, true)
			_light(Vector3(0, HallsScene.DOOR_H + 0.5, -RD + 0.6), accent, 0.7, 2.0, false)
		5:   # two more wisps on the far wall: the Hushwood has no fire
			if not far_lit:
				for p in far_torch_spots():
					_torch(p, 1.4)
		6:   # crystal shards at the wall feet
			for i in 4:
				_place(_tex("res://art/halls/z6_crystal.png"), -1.0 if i % 2 == 0 else 1.0, 3.3, 4.2, false)
			_light(Vector3(0, 0.4, -4.2), accent, 0.8, 3.5, false)
		7:   # a brass pipe run along one wall, turning up the far wall (art/halls/z7_pipe.png repeats)
			var side7 := -1.0 if rng.randf() < 0.5 else 1.0
			var pipe := _tex("res://art/halls/z7_pipe.png")
			_flat(pipe, Vector3(side7 * (HW - 0.03), 3.0, -RD / 2.0), Vector2(RD, 16.0 * PX), Vector3(0, -90.0 * side7, 0))
			_flat(pipe, Vector3(side7 * (HW - 0.4), 1.5, -RD + 0.02), Vector2(3.0, 16.0 * PX), Vector3(0, 0, 90))
		8:   # gilded pillars at the far corners (art/halls/z8_pillar.png repeats upward), off door 2's frame (2.67)
			for side in [-1.0, 1.0]:
				_flat(_tex("res://art/halls/z8_pillar.png"), Vector3(side * (HW - 0.15), ROOM_H / 2.0, -RD + 0.02), Vector2(16.0 * PX, ROOM_H), Vector3.ZERO)
		9:   # rows of spikes at the wall feet
			var spikes := _tex("res://art/halls/z9_spikes.png")
			for side in [-1.0, 1.0]:
				if base_kind == "Forgotten shrine" and side < 0:
					continue   # the glyph is on the left
				var rows := [3.7, 4.4, 5.1]
				rows.remove_at(rng.randi() % 3)   # two of three rows, so the Cinder Abyss rooms differ
				for zr in rows:
					_place(spikes, side, zr - 0.25, zr + 0.25, false)

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
	# a row near you and one by the far wall: the props stand between them, where a phone sees
	# them whole and clear of the doors (a row at z 3.5 took that spot)
	var rows: Array = [-1.5, -RD + 0.5]
	rng.randf_range(1.8, 2.2)   # keep the room's later rolls where they were
	if zone != 9:   # the Cinder Abyss is an open pit hall; the Flooded Vaults and Hushwood have no beams
		_pillars(rows, dark, not zone in [2, 5])
	_torch(Vector3(-HW + 0.08, 2.0, -torch_z.x))
	_torch(Vector3(HW - 0.08, 2.0, -torch_z.y))
	if rng.randf() < 0.5:
		rng.randf()   # (the old spot roll: keeps the room's later rolls where they were)
		# far torches clear of the door frames and labels; lower light, so the wall over the doors isn't blown out
		for p in far_torch_spots():
			far_lit = true
			_torch(p, 1.4)
	if zone == 1:   # the Catacombs' own statue in a wall niche
		_place(_zart("statue", "res://art/props/statue_hooded.png"), -1.0 if rng.randf() < 0.5 else 1.0, 3.6, 4.6)
	if zone == 0:
		_vines_on_walls(6)
		_vines_hanging(3)
		_hanging_roots(3, true)

func _collapsed_chamber() -> void:
	var dark := _wall_mat(Color(0.62, 0.62, 0.62))
	_light_pool(0.4, GAP_Z)
	_box(Vector3(0.5, ROOM_H, 0.5), Vector3(HW - 0.25, ROOM_H / 2.0, -1.5), dark)
	_box(Vector3(0.5, 1.1, 0.5), Vector3(-HW + 0.25, 0.55, -1.5), dark)
	_box(Vector3(0.5, 2.4, 0.5), Vector3(-HW + 0.6, 0.25, -3.3), dark, Vector3(88, 12, 0))
	keepout.append(Rect2(-HW + 0.35, 2.1, 0.5, 2.4))   # the fallen column lies along the left wall
	# the fallen beam: untinted wall stone (tinted it was a black slash), its side and angle rolled
	var bs := -1.0 if rng.randf() < 0.5 else 1.0
	_box(Vector3(HallsScene.W * 0.8, 0.3, 0.35), Vector3(bs * 0.3, 3.2, -RD + 1.4), _wall_mat(), Vector3(0, rng.randf_range(-10, 10), rng.randf_range(10, 18) * bs))
	_torch(Vector3(HW - 0.08, 2.0, -torch_z.y))
	_place(prop("boulder"), -1.0, 3.4, 4.4)
	_place(prop("pillar_broken"), -1.0, 3.6, 4.8)
	_place(prop("bones"), 1.0, 3.2, 3.6)   # small props near, or they're 12-px thumbnails
	_place(prop("skull"), 0.0, 3.2, 3.6)
	if zone == 0:
		_vines_on_walls(3)

func _mushroom_grotto() -> void:
	for side in [-1.0, 1.0]:
		for k in 2:
			var m := _place(prop("mushrooms"), side, 3.3, 4.6, false)
			if m:
				_light(m.position + Vector3(0, 0.5, 0), Color("#4fb0c6"), 1.5, 3.0, false)
	_hanging_roots(4, true)
	_vines_on_walls(4)
	_vines_hanging(3)

func _forgotten_shrine() -> void:
	# the shrine's own glyph on the floor (not a trap's circle), in the zone's accent
	# left of the hero (the trap circle's mirror), so he never stands on it
	var rune := _flat(_tex("res://art/traps/shrine.png"), Vector3(GLYPH.x, 0.02, -_glyph_z()), Vector2(64, 64) * PX, Vector3(-90, 0, 0), false, Color.WHITE, true)
	var rm := rune.material_override as StandardMaterial3D
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = accent
	_light(Vector3(GLYPH.x, 0.3, -_glyph_z()), accent, 0.9, 2.6, false)
	keepout.append(Rect2(GLYPH.x - TRAP_SIZE / 2.0, _glyph_z() - TRAP_SIZE / 2.0, TRAP_SIZE, TRAP_SIZE))   # nothing stands on the glyph
	for side in [-1.0, 1.0]:
		# the Hushwood has no fire: its braziers burn pale like its wisps
		var b := _place(recoloured("res://art/props/brazier.png", PALE_FLAME) if zone == 5 else prop("brazier"), side, 3.6, 4.6, false)
		if b:
			_light(b.position + Vector3(0, 1.2, 0.3), light_col, 1.8, 4.0)
	# one statue, and only in some shrines, so they don't stand in every room
	if rng.randf() < 0.5:
		var left := rng.randf() < 0.5
		_place(_zart("statue", "res://art/props/statue_hooded.png" if left else "res://art/props/statue_gargoyle.png"), -1.0 if left else 1.0, 3.4, 4.6)
	for side in [-1.0, 1.0]:
		_place(prop("candles"), side, 3.3, 5.2, false)
	if zone == 0:
		_vines_on_walls(3)

func _root_choked() -> void:
	_hanging_roots(8, false)
	_hanging_roots(4, true)
	_vines_on_walls(6)
	_vines_hanging(5)
	_torch(Vector3(-HW + 0.08, 1.9, -torch_z.x))
