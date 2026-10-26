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
	scene.build(state, size)
	_step_motes(delta)
	var k := "%d|%d" % [state.floor_num, state.room_count]
	if k != key:
		if key != "":
			main.sfx.play("whoosh", randf_range(0.9, 1.1))
		key = k
		motes.clear()
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
	for k in hit:
		if (hit[k] as Rect2).has_point(p):
			accept_event()
			if String(k).begins_with("d"):
				main.pick_door(int(String(k).substr(1)))
			elif String(k).begins_with("p"):
				main.interact_prop(int(String(k).substr(1)))
			else:
				main.engage_monster()
			return

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
		things.append({"z": _prop_z(float(rtrap["y"])), "kind": "trap"})
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
	draw_string(font, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_FS, Color("#f6d88f"))
	var title := "%s  -  Floor %d" % [GameData.zone_for_floor(state.floor_num)["name"], state.floor_num]
	draw_string_outline(font, Vector2(10, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FS, 5, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(10, 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FS, Color(1, 1, 1, 0.8))

## A prop's y (0 far .. 1 near, as rolled by Halls) to depth.
func _prop_z(y: float) -> float:
	return lerpf(HallsScene.D - 0.5, 1.7, clampf((y - 0.3) / 0.5, 0.0, 1.0))

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
		rect = _draw_camp(-0.9, 2.1)   # by the left wall, below and beside the doors
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
	var lc := Color("#f6d88f")
	if tile == "mimic":
		lab = "Mimic!"
		lc = Color("#f87171")
	var at := Vector2(rect.get_center().x - 80, rect.end.y + 16)
	draw_string_outline(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, 160, LABEL_FS, 5, Color(0, 0, 0, 0.9))
	draw_string(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, 160, LABEL_FS, lc)

## A trap you've spotted (hidden ones stay hidden): its rune circle on the floor (art/traps/<kind>.png,
## its own sigil in the middle), in the colour of what it does (Halls.TRAPS "color"). It doesn't turn
## (1 px lines would crawl); the colour pulses in two hard steps instead.
func _draw_trap() -> void:
	var rtrap: Dictionary = state.room_trap
	var z := _prop_z(float(rtrap["y"]))
	var x := _prop_x(float(rtrap["x"]), z)
	var fy := HallsScene.FLOOR_Y + 0.01
	var col := Color(String(Halls.TRAPS[String(rtrap["kind"])].get("color", "#fee761")))
	var tint := col if int(t * 2.0) % 2 == 0 else col.lightened(0.25)
	var r := 1.1   # the same size as the shrine's glyph
	var cols := PackedColorArray([tint, tint, tint, tint])
	var tex := scene.tx("res://art/traps/%s.png" % String(rtrap["kind"]))
	if tex == null:
		tex = scene.tx("res://art/traps/circle.png")
	# an 8x8 grid of small quads so the circle follows the floor's perspective (one big quad warps it)
	var spin := 0.0
	var n := 8
	for gy in n:
		for gx in n:
			var pts := PackedVector2Array()
			var uvs := PackedVector2Array()
			for c in [Vector2(gx, gy), Vector2(gx + 1, gy), Vector2(gx + 1, gy + 1), Vector2(gx, gy + 1)]:
				var u: Vector2 = c / float(n)
				var lx := (u.x - 0.5) * 2.0 * r
				var lz := (u.y - 0.5) * 2.0 * r
				pts.append(scene.proj(x + lx * cos(spin) - lz * sin(spin), fy, z + lx * sin(spin) + lz * cos(spin)))
				uvs.append(u)
			draw_polygon(pts, cols, uvs, tex)

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
		var scr := get_global_transform_with_canvas().get_scale().x
		scr = scr if scr > 0.01 else 1.0
		var unit := ArtStyle.unit(scr)
		if not art.has("lpc"):
			continue
		var an: Dictionary = (art["lpc"] as Dictionary).get("combat_idle", {})
		if an.is_empty():
			continue
		var n: int = (an["tex"] as Array).size()
		var fi := int(t * float(an["fps"]) + j) % n
		var sz: float = float(an["size"]) * float(unit if j == 0 else maxi(1, unit - 1)) / scr
		var feet := Vector2(size.x * float(xs[j]), size.y - (26.0 if j == 0 else 44.0))
		scene.shadow(self, feet, sz * 0.18)
		var a := 0.4 if (j == 0 and state.leader_down) or (j > 0 and members[j - 1].knocked_out) else 1.0
		# 2.1 heroes stand on row 80 of their 96 cell (LPC frames on ~0.9 of theirs)
		var foot := 80.0 / 96.0 if art.get("pl", false) else 0.9
		draw_texture_rect(an["tex"][fi], Rect2(feet - Vector2(sz / 2.0, sz * foot), Vector2(sz, sz)), false, Color(0.85, 0.82, 0.8, a))
		if j == 0:
			# pets use the leader's own pixel size (one art px = sz / cell)
			var k := sz / float(an["size"])
			_draw_pet(feet, sz, k)
			_draw_menagerie_room(feet, sz, k)

## Your companion trots at the leader's heels (true size: k units per art pixel, feet on the floor).
func _draw_pet(leader_feet: Vector2, leader_sz: float, k: float) -> void:
	if not state.pet_on or World.pet_stage(state) < 0:
		return
	var tex := Pets.portrait_frame(state, t)
	if tex == null:
		return
	var s := float(tex.get_width()) * k
	var at := leader_feet + Vector2(leader_sz * 0.62, -4.0)
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
func _draw_menagerie_room(leader_feet: Vector2, leader_sz: float, k: float) -> void:
	var pets := Menagerie.out(state)
	var s := 32.0 * k
	for i in pets.size():
		var p: Dictionary = pets[i]
		var key := String(p.get("species", ""))
		var tex := Pets.frame(key, t + i * 0.31)
		if tex == null:
			continue
		var at := leader_feet + Vector2(-leader_sz * (0.5 + 0.3 * i), -4.0 - i * 4.0)
		scene.shadow(self, at, s * 0.2)
		draw_texture_rect(tex, Rect2(at - Vector2(s / 2.0, (Pets.foot(key) + 1) * k), Vector2(s, s)), false, Color(0.9, 0.88, 0.85))

## A Descenders' Camp by the left wall: two tents stepping back along it, the fire in front
## of them (below the doors), Snik's lantern between the tents. Drawn far to near, all where
## a phone can see them (|x| <= 0.78 z).
func _draw_camp(x: float, z: float) -> Rect2:
	var s := scene.focal / z
	var t1 := scene.sprite(self, scene.tx("res://art/props/tent.png"), x - 1.6, z + 1.2, 1.1)
	var t2 := scene.sprite(self, scene.tx("res://art/props/tent.png"), x - 1.0, z + 0.7, 1.1)
	var lamp := scene.proj(x - 1.0, HallsScene.FLOOR_Y + 1.0, z + 0.6)
	var lw := roundf(s * 0.06)
	draw_rect(Rect2(lamp - Vector2(lw, lw), Vector2(lw, lw) * 2.0), Color("#fee761"))
	scene.glow(self, lamp, s * 0.5, Color("#feae34", 0.5 + 0.15 * sin(t * 5.0)))
	var flick := 1.0 + 0.06 * sin(t * 9.0)
	var fire := scene.sprite(self, scene.tx("res://art/props/cookfire.png"), x, z, 1.0, Color(flick, flick, flick))
	scene.sprite(self, scene.tx("res://art/props/backpack.png"), x - 0.4, z - 0.2, 0.5)
	return fire.merge(t1).merge(t2)
