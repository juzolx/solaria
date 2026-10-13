class_name TownView
extends Control
## The town map: a top-down picture of the town (art/town/town_<season>.png, built by
## tools/town_compose.py) that you tap. Each building opens its page. The look follows
## the zone you're in (Town.LOOKS): the season art, a color grade, lamp glow at
## dusk and night, and a little weather.

signal building_pressed(id: String)

const SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sat = 1.0;
uniform float dark = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
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

## Where townsfolk stroll: [feet y, min x, max x] in map pixels (kept clear of things they'd walk through).
const LANES := [[384, 150, 390], [604, 120, 455], [760, 300, 400], [470, 400, 470]]
const FOLK := [
	[{"body": "fem", "skin": 2, "hair": "Bun", "hair_color": 6, "eyes": 2, "race": "Human"}, {"Chest": ["robe", "cloth"], "Feet": ["sandals", "leather"]}],
	[{"body": "masc", "skin": 4, "hair": "Short", "hair_color": 2, "eyes": 1, "race": "Human"}, {"Chest": ["tunic", "leather"], "Legs": ["pants", "cloth"], "Feet": ["boots", "leather"]}],
	[{"body": "masc", "skin": 1, "hair": "Bald", "hair_color": 8, "eyes": 3, "race": "Dwarf"}, {"Chest": ["tunic", "leather"], "Feet": ["boots", "leather"]}],
	[{"body": "fem", "skin": 0, "hair": "Long", "hair_color": 16, "eyes": 5, "race": "Elf"}, {"Chest": ["tunic", "cloth"], "Legs": ["leggings", "cloth"], "Feet": ["boots", "leather"]}],
]

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Loaded as a resource so phone exports include it
	var j := load("res://art/town/town.json") as JSON
	if j:
		data = j.data
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

func set_look(l: Dictionary) -> void:
	if l == look:
		return
	look = l
	map.texture = _season_tex(String(l["season"]))
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

func to_view(p: Vector2) -> Vector2:
	return origin + p * scale_f

func to_map(p: Vector2) -> Vector2:
	return (p - origin) / scale_f

func _spot_at(p: Vector2) -> String:
	var m := to_map(p)
	# Plates first (they sit above the roofs), then the buildings themselves
	for s in data.get("spots", []):
		if _plate_rect(s).has_point(p):
			return s["id"]
	var best := ""
	var best_area := INF
	for s in data.get("spots", []):
		var r: Array = s["rect"]
		var rect := Rect2(r[0], r[1], r[2], r[3])
		if rect.has_point(m) and rect.get_area() < best_area:
			best = s["id"]
			best_area = rect.get_area()
	return best

func _scroll(dy: float) -> void:
	if map.size.y <= size.y:
		return
	pan = clampf(pan + dy, size.y - map.size.y, 0.0)
	_layout()

func _gui_input(e: InputEvent) -> void:
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

func _step_folk(delta: float) -> void:
	for f in folk:
		f["t"] = float(f["t"]) + delta
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
	var sorted := folk.duplicate()
	sorted.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	for f in sorted:
		var walking := float(f["wait"]) <= 0.0
		var frames: Array = f["walk"] if walking else f["idle"]
		var i := (int(float(f["t"]) * 9.0) % maxi(1, frames.size() - 1)) + 1 if walking else (int(float(f["t"]) * 1.5) % frames.size())
		i = clampi(i, 0, frames.size() - 1)
		var tx: Texture2D = frames[i]
		var w := float(tx.get_width())
		var pos := Vector2(float(f["x"]) - w / 2.0, float(f["y"]) - w + w * 0.12)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		people.draw_circle(Vector2(float(f["x"]), float(f["y"]) - 2.0), 9.0, Color(0.04, 0.03, 0.08, 0.25))
		if f["flip"]:
			people.draw_set_transform(Vector2((float(f["x"]) * 2.0) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture(tx, pos)
	people.draw_set_transform(Vector2.ZERO)

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
			pos = Vector2(randf_range(560, 600), randf_range(330, 350))   # the blacksmith's chimney
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

func _font_size() -> int:
	return clampi(int(round(11.0 * maxf(1.0, scale_f * 0.9))), 12, 18)

func _draw_labels() -> void:
	var font := get_theme_default_font()
	var fs := _font_size()
	for s in data.get("spots", []):
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
		labels.draw_string(font, rect.position + Vector2(9, rect.size.y / 2.0 + fs * 0.36), String(s["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		var n := int(badges.get(id, 0))
		if n > 0 and why == "":
			var c := rect.position + Vector2(rect.size.x - 2, 2)
			labels.draw_circle(c, 9, Color("#dc2626"))
			labels.draw_string(font, c + Vector2(-4 if n < 10 else -7, 5), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		if hot and notes.has(id):
			var note := String(notes[id]) if why == "" else why
			var nw := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0
			var nr := Rect2(rect.get_center().x - nw / 2.0, rect.end.y + 3, nw, 20)
			nr.position.x = clampf(nr.position.x, 4.0, size.x - nw - 4.0)
			var nb := StyleBoxFlat.new()
			nb.bg_color = Color(0.05, 0.06, 0.11, 0.9)
			nb.set_corner_radius_all(5)
			labels.draw_style_box(nb, nr)
			labels.draw_string(font, nr.position + Vector2(7, 14), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d6d3c4"))
