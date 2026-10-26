class_name RoomView
extends Control
## 0.13 The Halls Below: the room you're standing in, first-person from the doorway
## (the room itself is HallsScene, shared with the battle view). One room per floor,
## one thing per room: fights start by themselves (the battle view shows them); this
## view shows a room's single thing (chest, campfire, Snik, shrine, nest, stranger,
## dying beast) and, once the room is done, the three doors on the far wall.

var main
var state: GameState
var scene := HallsScene.new()
var t := 0.0
var key := ""
var motes: Array = []
var hit := {}              # "m<i>" / "d<i>" / "p<i>" -> Rect2 (tap targets)
const TRAP_Z := 3.6   # a spotted trap's circle always lies here, right of the hero (never under them)
const TRAP_X := 1.4   # its left edge clear of his shoulder; the shrine glyph mirrors it on the left
const TRAP_Z_SMALL := 4.0   # on a short screen (scene.small) the floor is shorter: the circle sits deeper
const REDRAW_HZ := 30.0     # only the flicker and the 2 Hz pulses move here
var _redraw_in := 0.0
var _trap_mesh: ArrayMesh = null
var _trap_at := ""
const LABEL_FS := 16       # prop names, the hint line and the floor title (same font as the fights)

func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if not is_visible_in_tree() or main == null:
		return
	state = main.state
	t += delta
	scene.t = t
	scene.build(state, size, HallsScene.screen_scale(self))
	if not scene.is_3d():
		_step_motes(delta)   # the 3D room has its own particles; these are only drawn in 2D
	var k := "%d|%d" % [state.floor_num, state.room_count]
	_redraw_in -= delta
	if k != key:
		if key != "":
			main.sfx.play("whoosh", randf_range(0.9, 1.1))
		key = k
		motes.clear()
		_redraw_in = 0.0
	if _redraw_in <= 0.0:
		_redraw_in = 1.0 / REDRAW_HZ
		queue_redraw()

# =====================================================================
# Taps
# =====================================================================

func _gui_input(event: InputEvent) -> void:
	var p := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		p = event.position
	elif event is InputEventScreenTouch and event.pressed:
		p = event.position
	else:
		return
	var k := pick(p)
	if k == "":
		return
	accept_event()
	if k.begins_with("d"):
		main.pick_door(int(k.substr(1)))
	elif k.begins_with("p"):
		main.interact_prop(int(k.substr(1)))
	else:
		main.engage_monster()

## The tap target under p ("" = none). Props first: a prop standing in front of a door gets
## the tap, not the door behind it.
func pick(p: Vector2) -> String:
	var keys: Array = hit.keys()
	keys.sort_custom(func(a, b): return String(a).begins_with("p") and not String(b).begins_with("p"))
	for k in keys:
		if (hit[k] as Rect2).has_point(p):
			return String(k)
	return ""

# =====================================================================
# Drawing
# =====================================================================

func _draw() -> void:
	if state == null or scene.key == "":
		return
	hit.clear()
	var font := UI.game_font()
	scene.draw_shell(self, size)
	scene.draw_doors(self, state, hit, font)
	# Everything standing in the room, far to near
	var things: Array = scene.scenery()
	for i in state.room_props.size():
		var p: Dictionary = state.room_props[i]
		things.append({"z": _prop_z(float(p["y"])), "kind": "prop", "i": i})
	var doors_open := state.door_pending()
	var rtrap: Dictionary = state.room_trap
	if not rtrap.is_empty() and rtrap.get("spotted", false) and not rtrap.get("done", false) and not doors_open:
		things.append({"z": _trap_z(), "kind": "trap"})
	things.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
	for th in things:
		if scene.draw_scenery(self, th):
			continue
		match String(th["kind"]):
			"prop":
				_draw_prop(int(th["i"]), font)
			"trap":
				_draw_trap()
	# Your team in the doorway, seen from behind
	_draw_team()
	scene.vignette(self, size)
	if not scene.is_3d():
		_draw_motes(scene.mood())
	# What to do
	var msg := "Pick a door"
	if not doors_open and not state.room_props.is_empty():
		var pk := String(state.room_props[0]["kind"])
		msg = String(Halls.PROP_HINTS.get(pk, ""))
		if state.room_props[0].get("spotted", false):
			msg = "A mimic! Fight it, or pick a door"
		if state.autoplay:
			msg += "  (Auto in a moment)"
	elif doors_open and not state.room_props.is_empty() and String(state.room_props[0]["kind"]) == "merchant":
		msg = "Tap Snik to trade, or pick a door"
	draw_string_outline(font, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_FS, 5, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_FS, Color("#fee761"))
	var title := "%s  -  Floor %d" % [GameData.zone_for_floor(state.floor_num)["name"], state.floor_num]
	draw_string_outline(font, Vector2(10, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FS, 5, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(10, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FS, Color(1, 1, 1, 0.8))

## A prop's y (0 far .. 1 near, as rolled by Halls) to depth.
func _prop_z(y: float) -> float:
	return lerpf(HallsScene.D - 0.5, 2.2, clampf((y - 0.3) / 0.5, 0.0, 1.0))   # never nearer than 2.2: near props dwarf the hero

## A prop's x (0 left .. 1 right) to world x, kept where a phone sees it at depth z.
func _prop_x(x: float, z := HallsScene.D) -> float:
	var lim := 0.7 * z
	return clampf((x - 0.5) * (HallsScene.W - 1.4), -lim, lim)

func _draw_prop(i: int, font: Font) -> void:
	var p: Dictionary = state.room_props[i]
	var used: bool = p.get("used", false)
	var kind := String(p["kind"])
	if used and kind in ["npc", "beast", "nest"]:
		return
	var tile: String = String({"chest": "chest", "altar": "altar", "nest": "nest"}.get(kind, ""))
	if kind == "chest" and p.get("spotted", false) and not used:
		tile = "mimic"
	if used and kind == "chest":
		tile = "chest_open"
	var z := _prop_z(float(p["y"]))
	var x := _prop_x(float(p["x"]), z)
	var rect := Rect2()
	var bob := sin(t * 2.0) * 1.5
	if kind == "npc":
		rect = scene.sprite(self, scene.tx("res://art/people/stranger.png"), x, z, 1.4, Color(0.9, 0.85, 0.85))
	elif kind == "traveler":
		rect = scene.sprite(self, Travelers.portrait(String(p.get("who", ""))), x, z, 1.5, Color(0.92, 0.88, 0.85), bob * 0.5)
	elif kind == "beast":
		var who := Sprites.enemy_by_key("barghest")
		if who.has("tex"):
			rect = scene.sprite(self, who["tex"], x, z, 1.3, Color(0.6, 0.55, 0.55))
	elif kind == "merchant":
		if state.door_pending():
			# while you pick a door Snik steps aside, below and left of them, so he never covers one
			z = 3.0
			x = _prop_x(0.2, z)
		var sn := Sprites.enemy_by_key("treasure_goblin")
		if sn.has("tex"):
			rect = scene.sprite(self, SpriteLight.lit(sn["tex"], scene.zone), x, z, 1.4, Color.WHITE, bob)
	elif kind == "campfire":
		rect = _draw_campfire(x, z)
	elif kind == "rift":
		rect = _draw_rift(x, z)
	elif kind == "gate":
		if not used:
			rect = _draw_gate()
	elif kind == "camp":
		rect = _draw_camp(-0.6, 2.1)   # by the left wall, below and beside the doors
	elif tile != "":
		var big := 1.5 if tile == "altar" else 1.3
		rect = scene.sprite(self, scene.tx("res://art/props/%s.png" % tile), x, z, big, Color(0.6, 0.6, 0.6) if used else Color.WHITE)
	if not Halls.can_interact(state) or rect.size == Vector2.ZERO or kind == "campfire":
		return
	if used and not kind in ["merchant", "camp"]:
		return
	hit["p%d" % i] = rect.grow(8)
	var lab := String(Halls.PROP_NAMES.get(kind, kind))
	if kind == "traveler":
		lab = String(Travelers.info(String(p.get("who", "")))["name"])
	var lc := Color("#fee761")
	if tile == "mimic":
		lab = "Mimic!"
		lc = Color("#e43b44")
	var lw := maxf(160.0, font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FS).x + 16.0)
	var at := Vector2(rect.get_center().x - lw / 2.0, rect.end.y + 16)
	if absf(rect.get_center().x - size.x / 2.0) < 70.0:
		at.y = rect.position.y - 6   # in the middle the hero stands below the prop: label it above
	draw_string_outline(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, lw, LABEL_FS, 5, Color(0, 0, 0, 0.9))
	draw_string(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, lw, LABEL_FS, lc)

## A trap you've spotted (hidden ones stay hidden): its rune circle on the floor (art/traps/<kind>.png,
## its own sigil in the middle), in the colour of what it does (Halls.TRAPS "color"). It doesn't turn
## (1 px lines would crawl); the colour pulses in two hard steps instead.
func _trap_z() -> float:
	return TRAP_Z_SMALL if scene.small else TRAP_Z

func _draw_trap() -> void:
	var rtrap: Dictionary = state.room_trap
	# always the same spot: one size on screen, beside the hero so the sigil shows
	var z := _trap_z()
	var x := TRAP_X
	var col := Color(String(Halls.TRAPS[String(rtrap["kind"])].get("color", "#fee761")))
	var tint := col if int(t * 2.0) % 2 == 0 else col.lightened(0.25)
	var tex := scene.tx("res://art/traps/%s.png" % String(rtrap["kind"]))
	if tex == null:
		tex = scene.tx("res://art/traps/circle.png")
	var mesh := trap_mesh(x, z)
	if ArtStyle.oklab(col).distance_to(ArtStyle.oklab(Color(scene.mood()["accent"]))) < 0.1:
		# a trap the colour of the zone's accent gets an outline-black rim, so it isn't the shrine again
		var c := scene.proj(x, HallsScene.FLOOR_Y, z)
		draw_mesh(mesh, tex, Transform2D(0.0, Vector2(1.03, 1.03), 0.0, c - c * 1.03), Color("#0e0812"))
	draw_mesh(mesh, tex, Transform2D.IDENTITY, tint)

## The trap circle as one mesh: an 8x8 grid of quads so it follows the floor's perspective
## (one big quad warps it). Built once per spot and view (scene.key covers size and horizon).
func trap_mesh(x: float, z: float) -> ArrayMesh:
	var at := "%s|%s|%s" % [x, z, scene.key]
	if _trap_mesh and _trap_at == at:
		return _trap_mesh
	var r := 1.1   # the same size as the shrine's glyph
	var fy := HallsScene.FLOOR_Y + 0.01
	var n := 8
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for gy in n + 1:
		for gx in n + 1:
			var u := Vector2(gx, gy) / float(n)
			pts.append(scene.proj(x + (u.x - 0.5) * 2.0 * r, fy, z + (u.y - 0.5) * 2.0 * r))
			uvs.append(u)
	for gy in n:
		for gx in n:
			var a := gy * (n + 1) + gx
			idx.append_array([a, a + 1, a + n + 2, a, a + n + 2, a + n + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	_trap_mesh = ArrayMesh.new()
	_trap_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_trap_at = at
	return _trap_mesh

func _draw_team() -> void:
	var members: Array = state.party.members if state.party != null else []
	var xs := [0.5]
	if members.size() >= 1:
		xs.append(0.22)
	if members.size() >= 2:
		xs.append(0.78)
	# companions first so the leader stands in front
	for j in range(xs.size() - 1, -1, -1):
		var g: GameState = state if j == 0 else members[j - 1].hero
		var art := Sprites.hero_back_of(g)  # rebuilt at most twice a second, not every frame
		# the fights' one scale (ArtStyle.SCREEN_PX screen pixels per art pixel), companions one step smaller
		var scr := HallsScene.screen_scale(self)
		scr = scr if scr > 0.01 else 1.0
		var unit := ArtStyle.unit(scr)
		if not art.has("anims"):
			continue
		var an: Dictionary = (art["anims"] as Dictionary).get("combat_idle", {})
		if an.is_empty():
			continue
		var n: int = (an["tex"] as Array).size()
		var fi := int(t * float(an["fps"]) + j) % n
		var sz: float = float(an["size"]) * float(unit if j == 0 else maxi(1, unit - 1)) / scr
		var feet := team_feet(j, float(xs[j]))
		scene.shadow(self, feet, sz * 0.18)
		var a := 0.4 if (j == 0 and state.leader_down) or (j > 0 and members[j - 1].knocked_out) else 1.0
		# 2.1 heroes stand on their frame's foot row (older art on ~0.9 of theirs)
		var foot := float(an["foot"]) / float(an["size"]) if an.has("foot") else 0.9
		draw_texture_rect(an["tex"][fi], Rect2(feet - Vector2(sz / 2.0, sz * foot), Vector2(sz, sz)), false, Color(0.85, 0.82, 0.8, a))
		if j == 0:
			# pets use the leader's own pixel size (one art px = sz / cell)
			var k := sz / float(an["size"])
			var spots := _row(feet, sz, k)   # once for both (Fable pets R3)
			_draw_pet(feet, k, spots)
			_draw_menagerie_room(feet, k, spots)

## Where member j (0 = the leader) stands, xf across the view. A short screen puts the team
## lower, so the floor between them and the doors stays (Fable round 3, the SE).
func team_feet(j: int, xf: float) -> Vector2:
	var up := (12.0 if j == 0 else 30.0) if scene.small else (26.0 if j == 0 else 44.0)
	return Vector2(size.x * xf, size.y - up)

## The top of the leader's drawn art (design px) at screen scale scr, for layout checks.
func leader_head_y(scr: float) -> float:
	var art := Sprites.hero_back_of(state)
	var an: Dictionary = (art.get("anims", {}) as Dictionary).get("combat_idle", {})
	if an.is_empty():
		return size.y
	var sz: float = float(an["size"]) * float(ArtStyle.unit(scr)) / scr
	var foot := float(an["foot"]) / float(an["size"]) if an.has("foot") else 0.9
	var img: Image = (an["tex"][0] as Texture2D).get_image()
	var top := float(img.get_used_rect().position.y) if img else 0.0
	return team_feet(0, 0.5).y - sz * foot + top * sz / float(an["size"])

## Your companion trots at the leader's heels (true size: k units per art pixel, feet on the floor).
func _draw_pet(leader_feet: Vector2, k: float, xs: Array) -> void:
	if not state.pet_on or World.pet_stage(state) < 0:
		return
	var tex := Pets.portrait_frame(state, t)
	if tex == null:
		return
	var s := float(tex.get_width()) * k
	var at := Vector2(float(xs[0]) + s / 2.0, leader_feet.y - 4.0).round()
	scene.shadow(self, at, s * 0.22)
	var fy := (Pets.foot(Pets.companion_key(state)) + 1) * k
	draw_texture_rect(tex, Rect2(at - Vector2(s / 2.0, fy), Vector2(s, s)), false, Color(0.88, 0.85, 0.82))

# =====================================================================
# Mood particles by region
# =====================================================================

func _step_motes(delta: float) -> void:
	if main and main.profile and main.profile.reduce_motion:
		motes.clear()  # Reduce motion: no drifting motes
		return
	var kind: String = scene.mood()["kind"]
	while motes.size() < (13 if HallsScene.low else 26):
		motes.append({"p": Vector2(randf() * size.x, randf() * size.y), "v": _mote_vel(kind), "age": randf() * 4.0, "life": randf_range(3.0, 7.0)})
	for m in motes:
		m["p"] = (m["p"] as Vector2) + (m["v"] as Vector2) * delta
		m["age"] = float(m["age"]) + delta
		if float(m["age"]) > float(m["life"]) or not Rect2(Vector2(-20, -20), size + Vector2(40, 40)).has_point(m["p"]):
			m["p"] = Vector2(randf() * size.x, (size.y + 10.0) if kind in ["embers", "sparks"] else (-10.0 if kind in ["drips", "leaves", "dust"] else randf() * size.y))
			m["v"] = _mote_vel(kind)
			m["age"] = 0.0

func _mote_vel(kind: String) -> Vector2:
	match kind:
		"embers", "sparks":
			return Vector2(randf_range(-8, 8), randf_range(-40, -18))
		"drips":
			return Vector2(0, randf_range(90, 140))
		"leaves", "dust":
			return Vector2(randf_range(-12, 12), randf_range(10, 26))
		_:
			return Vector2(randf_range(-10, 10), randf_range(-10, 10))

func _draw_motes(mood: Dictionary) -> void:
	var c: Color = mood["light"]
	var kind: String = mood["kind"]
	for m in motes:
		var life := float(m["life"])
		var a := clampf(minf(float(m["age"]), life - float(m["age"])) / 1.2, 0.0, 1.0)
		var p: Vector2 = m["p"]
		match kind:
			"drips":
				draw_rect(Rect2(p, Vector2(1, 5)), Color(c, 0.5 * a))
			"shadows":
				draw_rect(Rect2(p, Vector2(3, 3)), Color(c.darkened(0.7), 0.5 * a))
			"dust", "leaves":
				draw_rect(Rect2(p, Vector2(2, 2)), Color(c.darkened(0.3), 0.45 * a))
			_:
				var tw := 0.5 + 0.5 * sin(t * 5.0 + p.x)
				draw_rect(Rect2(p, Vector2(2, 2)), Color(c, (0.4 + 0.5 * tw) * a))

## A campfire: logs and a flickering flame, lighting the floor around it.
func _draw_campfire(x: float, z: float) -> Rect2:
	var base := scene.proj(x, HallsScene.FLOOR_Y, z)
	var s := scene.focal / z
	scene.glow(self, base, s * 2.2 * (1.0 + 0.05 * sin(t * 9.0)), Color("#f77622", 0.7))
	var flick := 1.0 + 0.06 * sin(t * 9.0) + 0.04 * sin(t * 23.0)
	return scene.sprite(self, scene.tx("res://art/props/campfire.png"), x, z, 1.1, Color(flick, flick, flick))

## A rift (portals.gd): a swirling violet oval over the floor, a 3-frame loop (art/halls/rift_*.png).
func _draw_rift(x: float, z: float) -> Rect2:
	var tex := scene.tx("res://art/halls/rift_%d.png" % (int(t * 6.0) % 3))
	scene.glow(self, scene.proj(x, HallsScene.FLOOR_Y, z), scene.focal / z * 1.4, Color("#9a4fc0", 0.6))
	return scene.sprite(self, tex, x, z, 1.9, Color.WHITE, -scene.focal / z * 0.15)

## A champion's gate: the middle door itself is the portal (HallsScene/Room3D draw it);
## returns the doorway to tap.
func _draw_gate() -> Rect2:
	var tl := scene.proj(-HallsScene.DOOR_W / 2.0, HallsScene.FLOOR_Y + HallsScene.DOOR_H, HallsScene.D)
	var br := scene.proj(HallsScene.DOOR_W / 2.0, HallsScene.FLOOR_Y, HallsScene.D)
	return Rect2(tl, br - tl)

## Menagerie pets on the run follow at the leader's left: their own baby art, true size, breathing.
func _draw_menagerie_room(leader_feet: Vector2, k: float, xs: Array) -> void:
	var pets := Menagerie.out(state)
	var s := 32.0 * k
	# the fight's row (Pets.row): companion first, pets after it
	var first := 1 if state.pet_on and World.pet_stage(state) >= 0 else 0
	for i in pets.size():
		var p: Dictionary = pets[i]
		var key := String(p.get("species", ""))
		var tex := Pets.frame(key, t + i * 0.23 + 0.17)
		if tex == null:
			continue
		var at := Vector2(float(xs[first + i]) + s / 2.0, leader_feet.y - 4.0).round()
		scene.shadow(self, at, s * 0.2)
		draw_texture_rect(tex, Rect2(at - Vector2(s / 2.0, (Pets.foot(key) + 1) * k), Vector2(s, s)), false, Color(0.9, 0.88, 0.85))

## Left edges of the companion (if out) and the pets on the run around the leader.
func _row(leader_feet: Vector2, leader_sz: float, k: float) -> Array:
	var comp := state.pet_on and World.pet_stage(state) >= 0
	var pets := Menagerie.out(state)
	var first := Pets.companion_key(state) if comp else (String(pets[0].get("species", "")) if not pets.is_empty() else "")
	return Pets.row(pets.size() + (1 if comp else 0), leader_feet.x, leader_sz, 32.0 * k, 2.0 * k, size.x, Pets.width(first) > 24)

## A Descenders' Camp by the left wall: two tents stepping back along it, the fire in front
## of them (below the doors), Snik's lantern between the tents. Drawn far to near, all where
## a phone can see them (|x| <= 0.78 z).
func _draw_camp(x: float, z: float) -> Rect2:
	var s := scene.focal / z
	var t1 := scene.sprite(self, scene.tx("res://art/props/tent.png"), x - 1.3, z + 1.2, 1.1)
	var t2 := scene.sprite(self, scene.tx("res://art/props/tent.png"), x - 0.7, z + 0.7, 1.1)
	var lamp := scene.sprite(self, scene.tx("res://art/props/candles.png"), x - 0.2, z + 1.0, 0.4)
	scene.glow(self, Vector2(lamp.get_center().x, lamp.end.y), s * 0.5, Color("#feae34", 0.5 + 0.15 * sin(t * 5.0)))
	var flick := 1.0 + 0.06 * sin(t * 9.0)
	var fire := scene.sprite(self, scene.tx("res://art/props/cookfire.png"), x, z, 1.0, Color(flick, flick, flick))
	scene.sprite(self, scene.tx("res://art/props/backpack.png"), x - 0.4, z - 0.2, 0.5)
	return fire.merge(t1).merge(t2)
