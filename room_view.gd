class_name RoomView
extends Control
## 0.13 The Halls Below: the room you're standing in, first-person from the doorway
## (the room itself is HallsScene, shared with the battle view). One room per floor.
## Between fights the monsters wait further in (tap one to fight it, or Auto walks
## up); things to poke at stand on the floor; when the room is clear, three doors on
## the far wall lead on (tap one).

var main
var state: GameState
var scene := HallsScene.new()
var t := 0.0
var key := ""
var extra_art: Array = []  # art keys for the monsters after the current one
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
		key = k
		extra_art = []
		for _i in 2:
			var def := GameData.pick_monster(maxi(1, state.floor_num))
			extra_art.append(GameData.art_key(String(def["name"])))
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
	if not doors_open and not state.in_town:
		var left := 1 if state.enemy_is_boss else maxi(1, GameData.FIGHTS_PER_FLOOR - state.fight + 1)
		for i in mini(left, 3):
			things.append({"z": 3.0 + 0.55 * i, "kind": "monster", "i": i})
	things.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))
	for th in things:
		if scene.draw_scenery(self, th):
			continue
		match String(th["kind"]):
			"prop":
				_draw_prop(int(th["i"]), font)
			"trap":
				_draw_trap()
			"monster":
				_draw_monster(int(th["i"]))
	# Your team in the doorway, seen from behind
	_draw_team()
	scene.vignette(self, size)
	_draw_motes(scene.mood())
	# What to do
	var msg := "Pick a door" if doors_open else "Tap a monster to fight"
	if not doors_open and state.autoplay:
		msg += "  (Auto walks up soon)"
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
	if used and kind in ["pot", "key", "npc", "beast", "nest"]:
		return
	var tile: String = String({"chest": "chest", "locked": "chest", "pot": "pot", "altar": "altar", "lever": "lever", "nest": "nest", "key": "key"}.get(kind, ""))
	if kind == "chest" and p.get("spotted", false) and not used:
		tile = "mimic"
	if used and kind in ["chest", "locked"]:
		tile = "chest_open"
	var x := _prop_x(float(p["x"]))
	var z := _prop_z(float(p["y"]))
	var rect := Rect2()
	if kind == "npc":
		rect = scene.sprite(self, scene.tx("res://art/dungeon/npc.png"), x, z, 1.5, Color(0.9, 0.85, 0.85))
	elif kind == "beast":
		var who := Sprites.enemy_by_key("barghest")
		if who.has("tex"):
			rect = scene.sprite(self, who["tex"], x, z, 1.0, Color(0.6, 0.55, 0.55))
	elif tile != "":
		var h := 0.75 if tile == "key" else 0.9
		rect = scene.sprite(self, scene.tx("res://art/dungeon/%s.png" % tile), x, z, h, Color(0.6, 0.6, 0.6) if used else Color.WHITE)
	if used or not Halls.can_interact(state) or rect.size == Vector2.ZERO:
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

func _draw_monster(i: int) -> void:
	var art_key := state.enemy_art if i == 0 else String(extra_art[(i - 1) % extra_art.size()])
	var art := Sprites.enemy_by_key(art_key)
	if art.is_empty():
		return
	var xs := [0.0, -1.3, 1.3]
	var h := (2.4 if state.enemy_is_boss else 1.5) if i == 0 else 1.3
	var tint := Color.WHITE if i == 0 else Color(0.8, 0.8, 0.85)
	var rect := scene.sprite(self, art["tex"], xs[i], 3.0 + 0.55 * i, h, tint, sin(t * 2.2 + i) * 2.0)
	if i == 0:
		draw_rect(rect.grow(3), Color(1, 0.4, 0.35, 0.3 + 0.25 * sin(t * 4.0)), false, 2.0)
	hit["m%d" % i] = rect.grow(8)

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

# =====================================================================
# Mood particles by region
# =====================================================================

func _step_motes(delta: float) -> void:
	var kind: String = scene.mood()["kind"]
	while motes.size() < 26:
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
