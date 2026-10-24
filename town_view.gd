class_name TownView
extends Control
## The town map: a picture of the town that you tap. Each building opens its page. The look
## follows the zone you're in (Town.LOOKS): a color grade, lamp glow at dusk and night, and a
## little weather. The isometric town (town.json "iso", built by claude/town3/export_town.py)
## has one picture per Church / Trophy Cabin state, pans both ways, pinches between 2x and 3x,
## and its townsfolk walk the street grid; the older top-down town uses one picture per season.

signal building_pressed(id: String)

const SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sat = 1.0;
uniform float dark = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;  // COLOR: shapes drawn on the map (shadows, the pen) keep their own color
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(vec3(l), c.rgb, sat) * tint.rgb;
	g = mix(g, g * vec3(0.42, 0.48, 0.72), dark);
	COLOR = vec4(g, c.a);
}
"""

var data := {}
var tex := {}          # season -> Texture2D
var map: TextureRect
var fx: Control        # glow and weather, over the map
var labels: Control    # name plates, over everything
var mat: ShaderMaterial
var look := {}
var scale_f := 1.0
var origin := Vector2.ZERO
var hover := ""
var press := ""
var pan := 0.0          # vertical scroll when the map is taller than the view (wide screens)
var drag_from := Vector2.ZERO
var dragging := false
var t := 0.0
var parts: Array = []  # weather particles in map pixels
var badges := {}       # building id -> number shown on its plate
var locked := {}       # building id -> why it's closed ("" = open)
var notes := {}        # building id -> short line under the name
var people: Control    # townsfolk walking the square (drawn on the map, so they share its color grade)
var folk: Array = []
var hidden_spots := {}  # building id -> true while it isn't in town yet (the Clinic before your first pet)
var pen_pets: Array = []  # your pets wandering the Clinic's pen: {"tex", "x", "y", "to", "wait", "flip", "t"}
var iso := false        # the isometric town (town.json "iso")
var hardcore := false   # Hardcore town: the Church is a ruin, the graveyard full
var zoom := 2.0         # iso: 2x or 3x (pinch / wheel)
var pan_v := Vector2.INF  # iso: map offset in view pixels (INF = not placed yet: start on the market)
var walk := {}          # iso: Vector2i cell -> true where people can walk
var walk_doors: Array = []  # iso: door cells people walk between
var walk_stops: Array = []  # iso: cells beside stalls, the well and the boards where people stop a while
var raised := {}        # iso: Vector2i cell -> true on the plateau path (people stand higher there)
var occluders: Array = []  # iso: [texture name, x, y, sort y, tag(, look)] - drawn again over a walker behind them
var occ_tex := {}
var up_tex := {}        # iso: level-prop name -> Texture2D
var touches := {}       # iso: finger index -> position, for the pinch
var pinch_from := 0.0
var placed := false     # iso: the player has moved the camera (until then it follows the market on resizes)

## The buildings you can see and tap.
func _spots() -> Array:
	return data.get("spots", []).filter(func(sp): return not hidden_spots.has(String(sp["id"])))

## The Clinic's pen in map pixels (the old garden plots on the top-down town; town.json "pen" on the iso town).
var PEN := Rect2(462, 916, 160, 160)

## Your pets in the pen: a list of textures. Rebuilt only when `key` changes.
var pets_key := ""
func set_pets(texs: Array, key: String) -> void:
	if key == pets_key:
		return
	pets_key = key
	pen_pets.clear()
	for tx in texs:
		if tx == null:
			continue
		pen_pets.append({"tex": tx, "x": randf_range(PEN.position.x + 16, PEN.end.x - 16), "y": randf_range(PEN.position.y + 24, PEN.end.y - 8),
			"to": Vector2.ZERO, "wait": randf_range(0.5, 3.0), "flip": randf() < 0.5, "t": randf() * 3.0})

## Where townsfolk stroll: [feet y, min x, max x] in map pixels (kept clear of things they'd walk through).
const LANES := [[384, 150, 390], [700, 200, 470], [800, 300, 400], [470, 400, 470]]
const FOLK := [
	[{"body": "fem", "skin": 2, "hair": "Bun", "hair_color": 6, "eyes": 2, "race": "Human"}, {"Chest": ["robe", "cloth"], "Feet": ["sandals", "leather"]}],
	[{"body": "masc", "skin": 4, "hair": "Short", "hair_color": 2, "eyes": 1, "race": "Human"}, {"Chest": ["tunic", "leather"], "Legs": ["pants", "cloth"], "Feet": ["boots", "leather"]}],
	[{"body": "masc", "skin": 1, "hair": "Bald", "hair_color": 8, "eyes": 3, "race": "Dwarf"}, {"Chest": ["tunic", "leather"], "Feet": ["boots", "leather"]}],
	[{"body": "fem", "skin": 0, "hair": "Long", "hair_color": 16, "eyes": 5, "race": "Elf"}, {"Chest": ["tunic", "cloth"], "Legs": ["leggings", "cloth"], "Feet": ["boots", "leather"]}],
	# more townsfolk for the bigger iso town
	[{"body": "masc", "skin": 3, "hair": "Short", "hair_color": 10, "eyes": 2, "race": "Human"}, {"Chest": ["robe", "cloth"], "Feet": ["sandals", "leather"]}],
	[{"body": "fem", "skin": 5, "hair": "Bun", "hair_color": 3, "eyes": 1, "race": "Human"}, {"Chest": ["tunic", "cloth"], "Legs": ["pants", "cloth"], "Feet": ["boots", "leather"]}],
	[{"body": "masc", "skin": 2, "hair": "Bald", "hair_color": 0, "eyes": 4, "race": "Human"}, {"Chest": ["tunic", "leather"], "Legs": ["pants", "leather"], "Feet": ["boots", "leather"]}],
	[{"body": "fem", "skin": 1, "hair": "Long", "hair_color": 7, "eyes": 3, "race": "Elf"}, {"Chest": ["robe", "cloth"], "Feet": ["sandals", "leather"]}],
]

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Loaded as a resource so phone exports include it
	var j := load("res://art/town/town.json") as JSON
	if j:
		data = j.data
	iso = bool(data.get("iso", false))
	if iso:
		var pr: Array = data["pen"]
		PEN = Rect2(pr[0], pr[1], pr[2], pr[3])
		for c in data.get("walk", []):
			walk[Vector2i(int(c[0]), int(c[1]))] = true
		for sp in data.get("spots", []):
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))
		for c in data.get("stops", []):
			walk_stops.append(Vector2i(int(c[0]), int(c[1])))
		for c in data.get("raised", []):
			raised[Vector2i(int(c[0]), int(c[1]))] = true
		occluders = data.get("occluders", [])
	map = TextureRect.new()
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.stretch_mode = TextureRect.STRETCH_SCALE
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	map.material = mat
	add_child(map)
	people = Control.new()
	people.mouse_filter = Control.MOUSE_FILTER_IGNORE
	people.use_parent_material = true
	people.draw.connect(_draw_people)
	map.add_child(people)
	_make_folk()
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(_draw_fx)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = add
	add_child(fx)
	labels = Control.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.draw.connect(_draw_labels)
	add_child(labels)
	resized.connect(_layout)
	set_look(Town.LOOKS[0])

func _season_tex(season: String) -> Texture2D:
	if not tex.has(season):
		tex[season] = load("res://art/town/town_%s.png" % season)
	return tex[season]

## The iso town's picture for this town's Church and Trophy Cabin (built or still a lot).
func _iso_tex() -> Texture2D:
	var church := "lot" if not Buildings.built("church") else ("ruin" if hardcore else "holy")
	var cabin := "built" if Buildings.built("cabin") else "lot"
	var path := String(data["art"]) % [church, cabin]
	if not tex.has(path):
		tex[path] = load(path)
	return tex[path]

## Regular or Hardcore town; call again after the Church or Trophy Cabin is built.
func set_mode(hc: bool) -> void:
	hardcore = hc
	if iso and map:
		map.texture = _iso_tex()

func set_look(l: Dictionary) -> void:
	if l == look:
		return
	look = l
	map.texture = _iso_tex() if iso else _season_tex(String(l["season"]))
	mat.set_shader_parameter("tint", l["tint"])
	mat.set_shader_parameter("sat", float(l["sat"]))
	mat.set_shader_parameter("dark", float(l["dark"]))
	parts.clear()
	_layout()

func map_size() -> Vector2:
	var s: Array = data.get("size", [704, 896])
	return Vector2(float(s[0]), float(s[1]))

## Fill the view (cropping the edges), keeping the square and the cave in sight.
func _layout() -> void:
	if map == null:
		return
	var ms := map_size()
	if iso:
		_layout_iso(ms)
		return
	scale_f = maxf(size.x / ms.x, size.y / ms.y)
	# Whole and half steps keep pixels even when the view is close to the art's size
	if scale_f >= 1.0:
		scale_f = maxf(1.0, floorf(scale_f * 2.0) / 2.0)
		if ms.x * scale_f < size.x or ms.y * scale_f < size.y:
			scale_f = maxf(size.x / ms.x, size.y / ms.y)
	var shown := ms * scale_f
	origin = ((size - shown) / 2.0).round()
	# Taller than the view: start near the top (the cave and the square) and let it scroll
	if shown.y > size.y:
		var lo := size.y - shown.y
		if pan == 0.0:
			pan = lo * 0.3
		pan = clampf(pan, lo, 0.0)
		origin.y = roundf(pan)
	map.position = origin
	map.size = shown
	if people:
		people.size = shown
	fx.size = size
	labels.size = size

## Iso: whole-pixel zoom (2x, pinch to 3x), panned both ways inside the picture.
func _layout_iso(ms: Vector2) -> void:
	scale_f = zoom
	var shown := ms * scale_f
	if not placed:                 # keep centring on the market until the player pans or zooms
		var m := _spot_rect("market")
		pan_v = size / 2.0 - (m.get_center() if m.size != Vector2.ZERO else ms / 2.0) * scale_f
	var lo := size - shown
	pan_v.x = lo.x / 2.0 if lo.x > 0.0 else clampf(pan_v.x, lo.x, 0.0)
	pan_v.y = lo.y / 2.0 if lo.y > 0.0 else clampf(pan_v.y, lo.y, 0.0)
	origin = pan_v.round()
	map.position = origin
	map.size = shown
	if people:
		people.size = shown
	fx.size = size
	labels.size = size

func _spot_rect(id: String) -> Rect2:
	for s in data.get("spots", []):
		if String(s["id"]) == id:
			var r: Array = s["rect"]
			return Rect2(r[0], r[1], r[2], r[3])
	return Rect2()

## Iso: pinch or wheel between 2x and 3x, keeping the point under the fingers still.
func _zoom_to(z: float, at: Vector2) -> void:
	z = clampf(z, 2.0, 3.0)
	if z == zoom:
		return
	var m := to_map(at)
	placed = true
	zoom = z
	pan_v = at - m * zoom
	_layout()

func to_view(p: Vector2) -> Vector2:
	return origin + p * scale_f

func to_map(p: Vector2) -> Vector2:
	return (p - origin) / scale_f

func _spot_at(p: Vector2) -> String:
	var m := to_map(p)
	# Plates first (they sit above the roofs), then the buildings themselves
	for s in _spots():
		if _plate_shown(s) and _plate_rect(s).has_point(p):
			return s["id"]
	var best := ""
	var best_area := INF
	for s in _spots():
		var r: Array = s["rect"]
		var rect := Rect2(r[0], r[1], r[2], r[3])
		if rect.has_point(m) and rect.get_area() < best_area:
			best = s["id"]
			best_area = rect.get_area()
	return best

func _scroll(dy: float) -> void:
	if iso:
		pan_v.y += dy
		_layout()
		return
	if map.size.y <= size.y:
		return
	pan = clampf(pan + dy, size.y - map.size.y, 0.0)
	_layout()

func _gui_input(e: InputEvent) -> void:
	if iso and _iso_input(e):
		accept_event()
		return
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_scroll(60.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else -60.0)
		accept_event()
		return
	if e is InputEventMouseMotion and press != "!" and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if dragging or e.position.distance_to(drag_from) > 8.0:
			dragging = true
			_scroll(e.relative.y)
			return
	if e is InputEventMouseMotion:
		var h := _spot_at(e.position)
		if h != hover:
			hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h != "" else Control.CURSOR_ARROW
			labels.queue_redraw()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			press = _spot_at(e.position)
			drag_from = e.position
			dragging = false
			labels.queue_redraw()
		else:
			var id := _spot_at(e.position)
			if id != "" and id == press and not dragging:
				building_pressed.emit(id)
			dragging = false
			press = ""
			labels.queue_redraw()
		accept_event()

## Iso: two-finger pinch / trackpad / wheel zoom, and one-finger drag pans both ways.
## Returns true when the event was used.
func _iso_input(e: InputEvent) -> bool:
	if e is InputEventScreenTouch:
		if e.pressed:
			touches[e.index] = e.position
		else:
			touches.erase(e.index)
		pinch_from = 0.0
		return false
	if e is InputEventScreenDrag and touches.size() >= 2:
		touches[e.index] = e.position
		var k: Array = touches.values()
		var a: Vector2 = k[0]
		var b: Vector2 = k[1]
		var d := a.distance_to(b)
		if pinch_from == 0.0:
			pinch_from = d
		elif d / pinch_from > 1.25 or d / pinch_from < 0.8:
			_zoom_to(3.0 if d > pinch_from else 2.0, (a + b) / 2.0)
			pinch_from = d
		dragging = true
		return true
	if e is InputEventMagnifyGesture:
		_zoom_to(3.0 if e.factor > 1.0 else 2.0, e.position)
		return true
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_zoom_to(3.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0, e.position)
		return true
	if e is InputEventMouseMotion and press != "!" and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and touches.size() < 2:
		if dragging or e.position.distance_to(drag_from) > 8.0:
			dragging = true
			placed = true
			pan_v += e.relative
			_layout()
			return true
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hover != "":
		hover = ""
		labels.queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	_step_weather(delta)
	_step_folk(delta)
	people.queue_redraw()
	fx.queue_redraw()
	labels.queue_redraw()

# =====================================================================
# Townsfolk
# =====================================================================

func _make_folk() -> void:
	for i in FOLK.size():
		var looks := {}
		for slot in FOLK[i][1]:
			looks[slot] = {"type": FOLK[i][1][slot][0], "mat": FOLK[i][1][slot][1], "trim": Color.WHITE, "glow": false}
		var anims := Lpc.build_walker(Lpc.spec(FOLK[i][0], looks))
		if anims["walk"].is_empty():
			continue
		var lane: Array = LANES[i % LANES.size()]
		folk.append({"walk": anims["walk"]["tex"], "idle": anims["idle"]["tex"] if not anims["idle"].is_empty() else anims["walk"]["tex"].slice(0, 1),
			"x": randf_range(lane[1], lane[2]), "y": float(lane[0]), "lane": lane, "to": -1.0, "wait": randf_range(0.5, 4.0), "flip": randf() < 0.5, "t": randf() * 3.0})
		if iso:
			_place_on_grid(folk[-1])

## Your own heroes stroll the square too: [[appearance, looks, is_you], ...].
## Rebuilt only when `key` changes (a new hero, new gear).
var heroes_key := ""
func set_heroes(list: Array, key: String) -> void:
	if key == heroes_key:
		return
	heroes_key = key
	folk = folk.filter(func(f): return not f.get("hero", false))
	for i in list.size():
		var e: Array = list[i]
		var anims := Lpc.build_walker(Lpc.spec(e[0], e[1]))
		if anims["walk"].is_empty():
			continue
		var lane: Array = LANES[(i + 1) % LANES.size()]
		folk.append({"walk": anims["walk"]["tex"], "idle": anims["idle"]["tex"] if not anims["idle"].is_empty() else anims["walk"]["tex"].slice(0, 1),
			"x": randf_range(lane[1], lane[2]), "y": float(lane[0]) + randf_range(-6.0, 6.0), "lane": lane, "to": -1.0, "wait": randf_range(0.5, 3.0),
			"flip": randf() < 0.5, "t": randf() * 3.0, "hero": true, "you": bool(e[2])})
		if iso:
			_place_on_grid(folk[-1])

# Iso townsfolk: stand at a door, then walk the street grid to another door.
func _cell_px(c: Vector2i) -> Vector2:
	var o: Array = data["origin"]
	var z := float(data.get("raised_z", 0)) if raised.has(c) else 0.0
	return Vector2(float(o[0]) + (c.x - c.y) * 16.0, float(o[1]) + (c.x + c.y + 1) * 8.0 - z)

func _place_on_grid(f: Dictionary) -> void:
	var c: Vector2i = walk_doors[randi() % walk_doors.size()] if not walk_doors.is_empty() else Vector2i(17, 20)
	var p := _cell_px(c)
	f["x"] = p.x
	f["y"] = p.y
	f["cell"] = c
	f["path"] = []

func _grid_path(a: Vector2i, b: Vector2i) -> Array:
	var prev := {a: a}
	var q: Array = [a]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == b:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if (walk.has(n) or n == b) and not prev.has(n):
				prev[n] = c
				q.append(n)
	if not prev.has(b):
		return []
	var out: Array = []
	var c2 := b
	while c2 != a:
		out.push_front(c2)
		c2 = prev[c2]
	return out

## Where to go next: mostly a building's door (then inside for a while), else a stall, the well
## or a board to stand at, sometimes just a nearby street cell to idle.
func _pick_goal(f: Dictionary) -> void:
	var r := randf()
	var goal: Vector2i = f["cell"]
	f["goal_door"] = false
	if r < 0.45 and not walk_doors.is_empty():
		goal = walk_doors[randi() % walk_doors.size()]
		f["goal_door"] = true
	elif r < 0.85 and not walk_stops.is_empty():
		goal = walk_stops[randi() % walk_stops.size()]
	else:
		var keys := walk.keys()
		goal = keys[randi() % keys.size()]
	f["path"] = _grid_path(f["cell"], goal)
	if (f["path"] as Array).is_empty():
		f["wait"] = 1.0

func _arrive(f: Dictionary) -> void:
	if f.get("goal_door", false) and not f.get("hero", false) or (f.get("goal_door", false) and randf() < 0.5):
		f["inside"] = randf_range(3.0, 8.0)   # went in: fades out at the door, comes back out later
		f["fade"] = 0.0
	f["wait"] = randf_range(1.5, 4.0)
	f["goal_door"] = false

func _step_iso_walker(f: Dictionary, delta: float) -> void:
	if float(f.get("inside", 0.0)) > 0.0:
		f["inside"] = float(f["inside"]) - delta
		f["fade"] = minf(1.0, float(f.get("fade", 0.0)) + delta * 3.0)
		return
	if float(f.get("fade", 0.0)) > 0.0:
		f["fade"] = maxf(0.0, float(f["fade"]) - delta * 3.0)
	if float(f["wait"]) > 0.0:
		f["wait"] = float(f["wait"]) - delta
		if float(f["wait"]) <= 0.0:
			_pick_goal(f)
		return
	var path: Array = f["path"]
	if path.is_empty():
		_arrive(f)
		return
	# two people meeting on the street stop for a chat now and then
	if not f.get("hero", false) and randf() < 0.004:
		for o in folk:
			if o != f and float(o["wait"]) <= 0.0 and float(o.get("inside", 0.0)) <= 0.0 and Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(f["x"]), float(f["y"]))) < 22.0:
				var t := randf_range(2.5, 5.0)
				f["wait"] = t
				o["wait"] = t
				f["flip"] = float(o["x"]) < float(f["x"])
				o["flip"] = not f["flip"]
				return
	var to := _cell_px(path[0])
	var at := Vector2(float(f["x"]), float(f["y"]))
	var stp := 20.0 * delta
	if absf(to.x - at.x) > 0.5:
		f["flip"] = to.x < at.x
	if at.distance_to(to) <= stp:
		f["x"] = to.x
		f["y"] = to.y
		f["cell"] = path.pop_front()
	else:
		var n := at + (to - at).normalized() * stp
		f["x"] = n.x
		f["y"] = n.y

func _step_folk(delta: float) -> void:
	for p in pen_pets:
		p["t"] = float(p["t"]) + delta
		if float(p["wait"]) > 0.0:
			p["wait"] = float(p["wait"]) - delta
			if float(p["wait"]) <= 0.0:
				p["to"] = Vector2(randf_range(PEN.position.x + 16, PEN.end.x - 16), randf_range(PEN.position.y + 24, PEN.end.y - 8))
			continue
		var at := Vector2(float(p["x"]), float(p["y"]))
		var to: Vector2 = p["to"]
		var stp := 22.0 * delta
		p["flip"] = to.x < at.x
		if at.distance_to(to) <= stp:
			p["x"] = to.x
			p["y"] = to.y
			p["wait"] = randf_range(1.5, 5.0)
		else:
			var nx := at + (to - at).normalized() * stp
			p["x"] = nx.x
			p["y"] = nx.y
	for f in folk:
		f["t"] = float(f["t"]) + delta
		if iso:
			_step_iso_walker(f, delta)
			continue
		if float(f["wait"]) > 0.0:
			f["wait"] = float(f["wait"]) - delta
			if float(f["wait"]) <= 0.0:
				var lane: Array = f["lane"]
				f["to"] = randf_range(lane[1], lane[2])
			continue
		var to := float(f["to"])
		var x := float(f["x"])
		var step := 30.0 * delta
		f["flip"] = to < x
		if absf(to - x) <= step:
			f["x"] = to
			f["wait"] = randf_range(2.0, 6.0)
		else:
			f["x"] = x + step * signf(to - x)

func _draw_people() -> void:
	people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
	if iso:
		_draw_levels()
	else:
		_draw_placeholders()
	if not hidden_spots.has("clinic"):
		_draw_pen()
	var sorted := folk.duplicate()
	sorted.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	for f in sorted:
		if iso and float(f.get("fade", 0.0)) >= 1.0:
			continue
		var walking := float(f["wait"]) <= 0.0
		var frames: Array = f["walk"] if walking else f["idle"]
		var i := (int(float(f["t"]) * 9.0) % maxi(1, frames.size() - 1)) + 1 if walking else (int(float(f["t"]) * 1.5) % frames.size())
		i = clampi(i, 0, frames.size() - 1)
		var tx: Texture2D = frames[i]
		# iso town: walkers at half size (~24 px, about a door's height)
		var k := 0.5 if iso else 1.0
		var w := float(tx.get_width()) * k
		var pos := Vector2(float(f["x"]) - w / 2.0, float(f["y"]) - w + w * 0.12)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		people.draw_circle(Vector2(float(f["x"]), float(f["y"]) - 2.0), 9.0 * k, Color(0.04, 0.03, 0.08, 0.25))
		if f["flip"]:
			people.draw_set_transform(Vector2((float(f["x"]) * 2.0) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture_rect(tx, Rect2(pos, Vector2(w, w)), false, Color(1, 1, 1, 1.0 - float(f.get("fade", 0.0))))
		if iso:
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			_cover(Rect2(pos, Vector2(w, w)), float(f["y"]))
		if f.get("hero", false):
			# A small marker over your heroes (brighter over the one you're playing)
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			var top := Vector2(float(f["x"]), pos.y + w * 0.1 + sin(float(f["t"]) * 3.0) * 1.5)
			var col := Color("#fbbf24") if f.get("you", false) else Color("#d6c9a0")
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -9), top + Vector2(7, -9), top + Vector2(0, 1)]), Color(0.05, 0.03, 0.08, 0.85))
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -8), top + Vector2(5, -8), top + Vector2(0, -1)]), col)
	people.draw_set_transform(Vector2.ZERO)

## Iso: redraw whatever stands in front of a walker (sorts lower on screen) and overlaps it,
## so people pass behind buildings, walls and trees instead of over their roofs.
func _cover(r: Rect2, foot_y: float) -> void:
	for o in occluders:
		if float(o[3]) <= foot_y:
			continue
		var tag := String(o[4])
		if tag == "church" or tag == "cabin":
			if not Buildings.built(tag):
				continue
			if tag == "church" and o.size() > 5 and String(o[5]) != ("ruin" if hardcore else "holy"):
				continue
		var n := String(o[0])
		if not occ_tex.has(n):
			occ_tex[n] = load("res://art/town/iso/occ/%s.png" % n)
		var t: Texture2D = occ_tex[n]
		var orect := Rect2(float(o[1]), float(o[2]), t.get_width(), t.get_height())
		if orect.intersects(r):
			people.draw_texture(t, orect.position)

## Iso: each building's level props (L1 scaffolding + piles, L2 lantern + upgrade, L3 banners + showpiece).
func _draw_levels() -> void:
	var lv: Dictionary = data.get("levels", {})
	for id in lv:
		if hidden_spots.has(id):
			continue
		var l := Buildings.level(String(id))
		for e in lv[id]:
			if int(e[3]) != l:
				continue
			var n := String(e[0])
			if not up_tex.has(n):
				up_tex[n] = load("res://art/town/iso/up/%s.png" % n)
			people.draw_texture(up_tex[n], Vector2(float(e[1]), float(e[2])))

## 2.1: buildings the town picture doesn't have yet (Church, Trophy Cabin) borrow an
## existing building, scaled into their spot and recoloured (Buildings.ART: swap
## that table when the new town art arrives).
func _draw_placeholders() -> void:
	if map.texture == null:
		return
	for s in _spots():
		var id := String(s["id"])
		if not Buildings.ART.has(id):
			continue
		var a: Dictionary = Buildings.ART[id]
		var f: Array = a["from"]
		var r: Array = s["rect"]
		var dst := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		if not Buildings.built(id):
			_draw_lot(dst)
			continue
		people.draw_rect(Rect2(dst.position + Vector2(4, dst.size.y - 10), Vector2(dst.size.x - 4, 10)), Color(0.04, 0.03, 0.08, 0.25))
		people.draw_texture_rect_region(map.texture, dst, Rect2(float(f[0]), float(f[1]), float(f[2]), float(f[3])), a["tint"])

## An empty building lot (not built yet): bare earth, corner stakes with a rope, a
## stack of planks and a construction sign.
func _draw_lot(r: Rect2) -> void:
	var lot := r.grow(-8.0)
	lot.position.y += lot.size.y * 0.3
	lot.size.y *= 0.7
	var wood := Color("#6b4423")
	people.draw_rect(lot, Color("#7a5a3a"))
	people.draw_rect(lot.grow(-4.0), Color("#8a6844"))
	for c in [lot.position, Vector2(lot.end.x, lot.position.y), lot.end, Vector2(lot.position.x, lot.end.y)]:
		people.draw_rect(Rect2(c - Vector2(2, 10), Vector2(4, 12)), wood.darkened(0.2))
	for pair in [[lot.position, Vector2(lot.end.x, lot.position.y)], [Vector2(lot.end.x, lot.position.y), lot.end],
			[lot.end, Vector2(lot.position.x, lot.end.y)], [Vector2(lot.position.x, lot.end.y), lot.position]]:
		people.draw_line(pair[0] - Vector2(0, 7), pair[1] - Vector2(0, 7), Color("#d8c9a0"), 1.0)
	var pl := Vector2(lot.end.x - 30, lot.end.y - 16)
	for i in 3:
		people.draw_rect(Rect2(pl + Vector2(0, -i * 4), Vector2(24, 4)), Color("#b0844c").darkened(i * 0.1))
	var sp := Vector2(lot.position.x + 18, lot.get_center().y)
	people.draw_rect(Rect2(sp.x - 2, sp.y - 6, 4, 18), wood.darkened(0.3))
	people.draw_rect(Rect2(sp.x - 14, sp.y - 22, 28, 17), Color("#e8c547"))
	people.draw_rect(Rect2(sp.x - 14, sp.y - 22, 28, 17), wood, false, 1.0)
	for k in 3:
		people.draw_line(Vector2(sp.x - 12 + k * 9, sp.y - 6), Vector2(sp.x - 6 + k * 9, sp.y - 20), Color("#2a2420"), 2.0)

## The Clinic's pen: a wooden fence around the plots, a little sign, and your pets.
func _draw_pen() -> void:
	if iso:
		_draw_pen_pets(16.0)   # the iso town has its own fence and kennel
		return
	var wood := Color("#6b4423")
	var light := Color("#a0703c")
	var r := PEN
	# Rails
	for y in [r.position.y + 6.0, r.end.y - 6.0]:
		people.draw_rect(Rect2(r.position.x, y - 3.0, r.size.x, 3.0), wood)
		people.draw_rect(Rect2(r.position.x, y - 3.0, r.size.x, 1.0), light)
	for x in [r.position.x, r.end.x - 3.0]:
		people.draw_rect(Rect2(x, r.position.y + 6.0, 3.0, r.size.y - 12.0), wood)
	# Posts
	var px := r.position.x
	while px <= r.end.x:
		for y in [r.position.y, r.end.y - 12.0]:
			people.draw_rect(Rect2(px - 2.0, y, 5.0, 12.0), wood.darkened(0.25))
			people.draw_rect(Rect2(px - 2.0, y, 5.0, 2.0), light)
		px += 32.0
	# The sign: a white board with a green cross
	var sp := Vector2(r.get_center().x, r.position.y - 4.0)
	people.draw_rect(Rect2(sp.x - 2.0, sp.y - 6.0, 4.0, 14.0), wood.darkened(0.3))
	people.draw_rect(Rect2(sp.x - 10.0, sp.y - 20.0, 20.0, 15.0), Color("#e8e0c8"))
	people.draw_rect(Rect2(sp.x - 10.0, sp.y - 20.0, 20.0, 15.0), wood, false, 1.0)
	people.draw_rect(Rect2(sp.x - 2.0, sp.y - 18.0, 4.0, 11.0), Color("#3ca85a"))
	people.draw_rect(Rect2(sp.x - 6.0, sp.y - 14.5, 12.0, 4.0), Color("#3ca85a"))
	_draw_pen_pets(34.0)

## Your pets in the pen, `px` tall (16 in the iso town: knee-high to a 24 px walker).
func _draw_pen_pets(px: float) -> void:
	var sorted := pen_pets.duplicate()
	sorted.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	for p in sorted:
		var tx: Texture2D = p["tex"]
		var sz := Vector2(tx.get_size())
		var k := minf(1.0, px / maxf(sz.x, sz.y))  # Pets 2 art (32 px): 1:1 on the old town, exactly half in the iso town
		var hop := absf(sin(float(p["t"]) * 6.0)) * 2.0 if float(p["wait"]) <= 0.0 else 0.0
		var dst := Vector2(sz.x * k, sz.y * k)
		var pos := Vector2(float(p["x"]) - dst.x / 2.0, float(p["y"]) - dst.y - hop)
		people.draw_circle(Vector2(float(p["x"]), float(p["y"]) - 1.0), 7.0, Color(0.04, 0.03, 0.08, 0.25))
		if p["flip"]:
			people.draw_set_transform(Vector2(float(p["x"]) * 2.0 * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture_rect(tx, Rect2(pos, dst), false)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		if iso:
			_cover(Rect2(pos, dst), float(p["y"]))   # pets hide behind the wall and the kennel too

# =====================================================================
# Glow and weather
# =====================================================================

func _step_weather(delta: float) -> void:
	var kind := String(look.get("weather", ""))
	var ms := map_size()
	var want: int = {"rain": 70, "ash": 45, "embers": 34, "leaves": 18, "fog": 7, "smoke": 10, "wisps": 9, "sparkles": 26, "motes": 22}.get(kind, 0)
	while parts.size() < want:
		parts.append(_new_part(kind, ms, parts.size() < want / 2 and t < 0.5))
	for p in parts:
		p["pos"] += (p["vel"] as Vector2) * delta
		p["age"] = float(p["age"]) + delta
	parts = parts.filter(func(p):
		var pos: Vector2 = p["pos"]
		return float(p["age"]) < float(p["life"]) and pos.x > -80 and pos.x < ms.x + 80 and pos.y > -80 and pos.y < ms.y + 80)

func _new_part(kind: String, ms: Vector2, anywhere: bool) -> Dictionary:
	var pos := Vector2(randf() * ms.x, randf() * ms.y)
	var vel := Vector2.ZERO
	var life := randf_range(4.0, 9.0)
	match kind:
		"rain":
			pos = Vector2(randf() * (ms.x + 200) - 100, -20 if not anywhere else randf() * ms.y)
			vel = Vector2(-60, 520)
			life = 3.0
		"ash", "leaves":
			if not anywhere:
				pos.y = -10
			vel = Vector2(randf_range(-14, 14), randf_range(16, 34) if kind == "ash" else randf_range(26, 46))
			life = 40.0
		"embers":
			if not anywhere:
				pos.y = ms.y + 10
			vel = Vector2(randf_range(-10, 10), -randf_range(20, 46))
			life = 30.0
		"smoke":
			var sm: Array = data.get("smoke", [580, 340])   # the blacksmith's chimney
			pos = Vector2(float(sm[0]) + randf_range(-20, 20), float(sm[1]) + randf_range(-10, 10))
			vel = Vector2(randf_range(4, 12), -randf_range(10, 18))
			life = randf_range(5.0, 8.0)
		"fog":
			pos = Vector2(randf() * ms.x, randf_range(ms.y * 0.2, ms.y))
			vel = Vector2(randf_range(5, 12), 0)
			life = randf_range(14.0, 22.0)
		_:
			vel = Vector2(randf_range(-6, 6), randf_range(-8, -2))
	return {"pos": pos, "vel": vel, "age": 0.0 if not anywhere else randf() * 2.0, "life": life, "seed": randf() * TAU}

func _draw_fx() -> void:
	var dark := float(look.get("dark", 0.0))
	# lamp light, stronger the darker it is, with a gentle flicker
	if dark > 0.1:
		for l in data.get("lights", []):
			var c := to_view(Vector2(l[0], l[1]))
			var fl := 0.9 + 0.1 * sin(t * 7.0 + float(l[0]))
			for i in 5:
				var r := (10.0 + i * 9.0) * scale_f
				fx.draw_circle(c, r, Color(1.0, 0.72, 0.36, 0.05 * dark * fl))
			fx.draw_circle(c, 4.0 * scale_f, Color(1.0, 0.85, 0.5, 0.45 * dark * fl))
	var kind := String(look.get("weather", ""))
	for p in parts:
		var a := clampf(minf(float(p["age"]), float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var v := to_view(p["pos"])
		var s := scale_f
		match kind:
			"rain":
				fx.draw_line(v, v + Vector2(-3, 14) * s, Color(0.55, 0.65, 0.85, 0.35 * a), maxf(1.0, s * 0.8))
			"ash":
				fx.draw_rect(Rect2(v, Vector2(2, 2) * s), Color(0.6, 0.56, 0.55, 0.55 * a))
			"embers":
				var e := 0.6 + 0.4 * sin(t * 6.0 + float(p["seed"]))
				fx.draw_rect(Rect2(v, Vector2(2, 2) * s), Color(1.0, 0.55, 0.2, 0.8 * a * e))
			"leaves":
				var sw := sin(t * 2.0 + float(p["seed"])) * 8.0 * s
				fx.draw_rect(Rect2(v + Vector2(sw, 0), Vector2(3, 2) * s), Color(0.85, 0.45, 0.15, 0.6 * a))
			"fog":
				fx.draw_circle(v, 60.0 * s, Color(0.55, 0.6, 0.62, 0.035 * a))
				fx.draw_circle(v + Vector2(40, 10) * s, 46.0 * s, Color(0.55, 0.6, 0.62, 0.03 * a))
			"smoke":
				var grow := 4.0 + float(p["age"]) * 3.0
				fx.draw_circle(v, grow * s, Color(0.35, 0.33, 0.34, 0.12 * a))
			"wisps":
				var bob := Vector2(sin(t + float(p["seed"])) * 6.0, cos(t * 0.8 + float(p["seed"])) * 4.0) * s
				fx.draw_circle(v + bob, 6.0 * s, Color(0.4, 0.6, 1.0, 0.12 * a))
				fx.draw_circle(v + bob, 2.0 * s, Color(0.7, 0.85, 1.0, 0.6 * a))
			"sparkles":
				var tw := maxf(0.0, sin(t * 3.0 + float(p["seed"]) * 3.0))
				fx.draw_rect(Rect2(v, Vector2(2, 2) * s), Color(1.0, 0.75, 0.95, 0.8 * a * tw))
			_:
				var tw2 := 0.5 + 0.5 * sin(t * 2.0 + float(p["seed"]) * 2.0)
				fx.draw_rect(Rect2(v, Vector2(2, 2) * s), Color(1.0, 0.95, 0.7, 0.35 * a * tw2))

# =====================================================================
# Name plates
# =====================================================================

func _plate_rect(s: Dictionary) -> Rect2:
	var r: Array = s["rect"]
	var font := get_theme_default_font()
	var fs := _font_size()
	var w := font.get_string_size(String(s["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
	var anchor := to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + 10.0))
	if s["id"] == "bounty":
		anchor = to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) - 8.0))
	if s["id"] == "gate":
		anchor = to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + float(r[3]) + 10.0))
	var h := fs + 10.0
	var rect := Rect2(anchor.x - w / 2.0, anchor.y - h / 2.0, w, h)
	rect.position.x = clampf(rect.position.x, 4.0, size.x - w - 4.0)
	rect.position.y = clampf(rect.position.y, 4.0, size.y - h - 4.0)
	return rect

## Iso: the town is bigger than the screen, so only buildings in view get a name plate
## (otherwise off-screen plates would pile up along the edges).
func _plate_shown(s: Dictionary) -> bool:
	if not iso:
		return true
	var r: Array = s["rect"]
	var c := to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + float(r[3]) / 2.0))
	return Rect2(Vector2.ZERO, size).grow(-8.0).has_point(c)

func _font_size() -> int:
	return clampi(int(round(11.0 * maxf(1.0, scale_f * 0.9))), 18, 22)   # UX pass: >= 18 design px (~15 pt on a phone)

func _draw_labels() -> void:
	var font := get_theme_default_font()
	var fs := _font_size()
	for s in _spots():
		if not _plate_shown(s):
			continue
		var id := String(s["id"])
		var rect := _plate_rect(s)
		var why := String(locked.get(id, ""))
		var hot := id == hover or id == press
		var bg := Color(0.05, 0.06, 0.11, 0.86 if hot else 0.74)
		var edge := Color("#e8b14a") if hot else (Color("#5b4a2a") if why == "" else Color("#3a3a46"))
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = edge
		sb.set_border_width_all(2 if hot else 1)
		sb.set_corner_radius_all(6)
		labels.draw_style_box(sb, rect)
		var col := Color("#f6d88f") if why == "" else Color("#8b90a0")
		if id == "gate":
			col = Color("#fca5a5")
		labels.draw_string_outline(font, rect.position + Vector2(9, rect.size.y / 2.0 + fs * 0.36), String(s["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.04, 0.03, 0.06, 0.95))
		labels.draw_string(font, rect.position + Vector2(9, rect.size.y / 2.0 + fs * 0.36), String(s["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		var n := int(badges.get(id, 0))
		if n > 0 and why == "":
			var c := rect.position + Vector2(rect.size.x - 2, 2)
			labels.draw_circle(c, 12, Color(0.04, 0.03, 0.06))
			labels.draw_circle(c, 11, Color("#dc2626"))
			labels.draw_string(font, c + Vector2(-20, 6), str(n), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)
		if hot and notes.has(id):
			var note := String(notes[id]) if why == "" else why
			var nw := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 14.0
			var nr := Rect2(rect.get_center().x - nw / 2.0, rect.end.y + 3, nw, 26)
			nr.position.x = clampf(nr.position.x, 4.0, size.x - nw - 4.0)
			var nb := StyleBoxFlat.new()
			nb.bg_color = Color(0.05, 0.06, 0.11, 0.9)
			nb.set_corner_radius_all(5)
			labels.draw_style_box(nb, nr)
			labels.draw_string(font, nr.position + Vector2(7, 19), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6d3c4"))
