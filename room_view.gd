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
	var font := get_theme_default_font()
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
	draw_string_outline(font, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color("#f6d88f"))
	var title := "%s  -  Floor %d" % [GameData.zone_for_floor(state.floor_num)["name"], state.floor_num]
	draw_string_outline(font, Vector2(10, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(10, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.75))

## A prop's y (0 far .. 1 near, as rolled by Halls) to depth.
func _prop_z(y: float) -> float:
	return lerpf(HallsScene.D - 0.5, 1.7, clampf((y - 0.3) / 0.5, 0.0, 1.0))

func _prop_x(x: float) -> float:
	return (x - 0.5) * (HallsScene.W - 1.4)

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
	var x := _prop_x(float(p["x"]))
	var z := _prop_z(float(p["y"]))
	var rect := Rect2()
	var bob := sin(t * 2.0) * 1.5
	if kind == "npc":
		rect = scene.sprite(self, scene.tx("res://art/dungeon/npc.png"), x, z, 1.7, Color(0.9, 0.85, 0.85))
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
	elif tile != "":
		var big := 1.6 if tile == "altar" else 1.1
		rect = scene.sprite(self, scene.tx("res://art/dungeon/%s.png" % tile), x, z, big, Color(0.6, 0.6, 0.6) if used else Color.WHITE)
	if not Halls.can_interact(state) or rect.size == Vector2.ZERO or kind == "campfire":
		return
	if used and kind != "merchant":
		return
	hit["p%d" % i] = rect.grow(8)
	var lab := String(Halls.PROP_NAMES.get(kind, kind))
	var lc := Color("#f6d88f")
	if tile == "mimic":
		lab = "Mimic!"
		lc = Color("#f87171")
	var at := Vector2(rect.get_center().x - 50, rect.end.y + 12)
	draw_string_outline(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, 100, 10, 3, Color(0, 0, 0, 0.9))
	draw_string(font, at, lab, HORIZONTAL_ALIGNMENT_CENTER, 100, 10, lc)

## A trap you've spotted (hidden ones stay hidden): a glowing plate on the floor.
func _draw_trap() -> void:
	var rtrap: Dictionary = state.room_trap
	var x := _prop_x(float(rtrap["x"]))
	var z := _prop_z(float(rtrap["y"]))
	var fy := HallsScene.FLOOR_Y + 0.01
	var tex := scene.tx("res://art/dungeon/trap_%s.png" % String(rtrap["kind"]))
	if tex:
		scene.quad(self, tex, Vector3(x - 0.45, fy, z + 0.45), Vector3(x + 0.45, fy, z + 0.45), Vector3(x + 0.45, fy, z - 0.45), Vector3(x - 0.45, fy, z - 0.45), Vector2.ZERO, Vector2.ONE)
	draw_set_transform(scene.proj(x, HallsScene.FLOOR_Y, z), 0.0, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, scene.focal * 0.55 / z, 0, TAU, 24, Color(1, 0.75, 0.2, 0.5 + 0.3 * sin(t * 5.0)), 2.0)
	draw_set_transform(Vector2.ZERO)

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
		var art := Sprites.hero_back(g.appearance, g.hero_looks())
		if not art.has("lpc"):
			continue
		var an: Dictionary = (art["lpc"] as Dictionary).get("combat_idle", {})
		if an.is_empty():
			continue
		var n: int = (an["tex"] as Array).size()
		var fi := int(t * float(an["fps"]) + j) % n
		var sz: float = float(an["size"]) * (2.0 if j == 0 else 1.7)
		var feet := Vector2(size.x * float(xs[j]), size.y - (26.0 if j == 0 else 44.0))
		scene.shadow(self, feet, sz * 0.18)
		var a := 0.4 if (j == 0 and state.leader_down) or (j > 0 and members[j - 1].knocked_out) else 1.0
		draw_texture_rect(an["tex"][fi], Rect2(feet - Vector2(sz / 2.0, sz * 0.9), Vector2(sz, sz)), false, Color(0.85, 0.82, 0.8, a))
		if j == 0:
			_draw_pet(feet, sz)

## Your companion trots at the leader's heels.
func _draw_pet(leader_feet: Vector2, leader_sz: float) -> void:
	if not state.pet_on or World.pet_stage(state) < 0:
		return
	var tex := Pets.portrait(state)
	if tex == null:
		return
	var s := leader_sz * 0.5
	var hop := 0.0 if (main.profile and main.profile.reduce_motion) else absf(sin(t * 3.2)) * s * 0.05
	var at := leader_feet + Vector2(leader_sz * 0.62, -4.0)
	scene.shadow(self, at, s * 0.22)
	draw_texture_rect(tex, Rect2(at - Vector2(s / 2.0, s * 0.85 + hop), Vector2(s, s)), false, Color(0.88, 0.85, 0.82))

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
				draw_circle(p, 5.0, Color(0.05, 0.0, 0.1, 0.25 * a))
			"dust", "leaves":
				draw_rect(Rect2(p, Vector2(2, 2)), Color(c.darkened(0.3), 0.45 * a))
			_:
				var tw := 0.5 + 0.5 * sin(t * 5.0 + p.x)
				draw_rect(Rect2(p, Vector2(2, 2)), Color(c, (0.4 + 0.5 * tw) * a))

## A campfire: logs and a flickering flame, lighting the floor around it.
func _draw_campfire(x: float, z: float) -> Rect2:
	var base := scene.proj(x, HallsScene.FLOOR_Y, z)
	var s := scene.focal / z
	for k in 5:
		draw_set_transform(base, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, s * (0.5 + k * 0.25) * (1.0 + 0.05 * sin(t * 9.0)), Color(1.0, 0.55, 0.2, 0.08))
		draw_set_transform(Vector2.ZERO)
	var lw := s * 0.55
	draw_line(base + Vector2(-lw, 0), base + Vector2(lw, -s * 0.08), Color("#4a2e1a"), maxf(3.0, s * 0.1))
	draw_line(base + Vector2(-lw, -s * 0.08), base + Vector2(lw, 0), Color("#5c3a22"), maxf(3.0, s * 0.1))
	for k in 3:
		var fh := s * (0.7 - k * 0.18) * (1.0 + 0.15 * sin(t * (8.0 + k * 3.0) + k))
		var fw := s * (0.28 - k * 0.07)
		var col: Color = [Color("#e8541c"), Color("#f59e0b"), Color("#fde68a")][k]
		var pts := PackedVector2Array([base + Vector2(-fw, -s * 0.05), base + Vector2(sin(t * 6.0 + k) * fw * 0.4, -s * 0.05 - fh), base + Vector2(fw, -s * 0.05)])
		draw_colored_polygon(pts, col)
	return Rect2(base - Vector2(lw, s * 0.8), Vector2(lw * 2.0, s * 0.8))
