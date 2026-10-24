"""One-off: teach town_view.gd the isometric town (town.json "iso"). Usage: py patch_townview.py <repo>"""
import sys

p = sys.argv[1] + "/town_view.gd"
s = open(p, encoding="utf-8").read()


def rep(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b, 1)


rep('''## The town map: a top-down picture of the town (art/town/town_<season>.png, built by
## tools/town_compose.py) that you tap. Each building opens its page. The look follows
## the zone you're in (Town.LOOKS): the season art, a color grade, lamp glow at
## dusk and night, and a little weather.''', '''## The town map: a picture of the town that you tap. Each building opens its page. The look
## follows the zone you're in (Town.LOOKS): a color grade, lamp glow at dusk and night, and a
## little weather. The isometric town (town.json "iso", built by claude/town3/export_town.py)
## has one picture per Church / Trophy Cabin state, pans both ways, pinches between 2x and 3x,
## and its townsfolk walk the street grid; the older top-down town uses one picture per season.''')

rep('''var pen_pets: Array = []  # your pets wandering the Clinic's pen: {"tex", "x", "y", "to", "wait", "flip", "t"}''',
    '''var pen_pets: Array = []  # your pets wandering the Clinic's pen: {"tex", "x", "y", "to", "wait", "flip", "t"}
var iso := false        # the isometric town (town.json "iso")
var hardcore := false   # Hardcore town: the Church is a ruin, the graveyard full
var zoom := 2.0         # iso: 2x or 3x (pinch / wheel)
var pan_v := Vector2.INF  # iso: map offset in view pixels (INF = not placed yet: start on the market)
var walk := {}          # iso: Vector2i cell -> true where people can walk
var walk_doors: Array = []  # iso: door cells people walk between
var up_tex := {}        # iso: level-prop name -> Texture2D
var touches := {}       # iso: finger index -> position, for the pinch
var pinch_from := 0.0''')

rep('''## The Clinic's pen (the old garden plots) in map pixels.
const PEN := Rect2(462, 916, 160, 160)''', '''## The Clinic's pen in map pixels (the old garden plots on the top-down town; town.json "pen" on the iso town).
var PEN := Rect2(462, 916, 160, 160)''')

rep('''	var j := load("res://art/town/town.json") as JSON
	if j:
		data = j.data''', '''	var j := load("res://art/town/town.json") as JSON
	if j:
		data = j.data
	iso = bool(data.get("iso", false))
	if iso:
		var pr: Array = data["pen"]
		PEN = Rect2(pr[0], pr[1], pr[2], pr[3])
		for c in data.get("walk", []):
			walk[Vector2i(int(c[0]), int(c[1]))] = true
		for sp in data.get("spots", []):
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))''')

rep('''func set_look(l: Dictionary) -> void:
	if l == look:
		return
	look = l
	map.texture = _season_tex(String(l["season"]))''', '''## The iso town's picture for this town's Church and Trophy Cabin (built or still a lot).
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
	map.texture = _iso_tex() if iso else _season_tex(String(l["season"]))''')

rep('''	var ms := map_size()
	scale_f = maxf(size.x / ms.x, size.y / ms.y)''', '''	var ms := map_size()
	if iso:
		_layout_iso(ms)
		return
	scale_f = maxf(size.x / ms.x, size.y / ms.y)''')

rep('''func to_view(p: Vector2) -> Vector2:''', '''## Iso: whole-pixel zoom (2x, pinch to 3x), panned both ways inside the picture.
func _layout_iso(ms: Vector2) -> void:
	scale_f = zoom
	var shown := ms * scale_f
	if pan_v == Vector2.INF:
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
	zoom = z
	pan_v = at - m * zoom
	_layout()

func to_view(p: Vector2) -> Vector2:''')

rep('''func _scroll(dy: float) -> void:
	if map.size.y <= size.y:
		return''', '''func _scroll(dy: float) -> void:
	if iso:
		pan_v.y += dy
		_layout()
		return
	if map.size.y <= size.y:
		return''')

rep('''func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):''', '''func _gui_input(e: InputEvent) -> void:
	if iso and _iso_input(e):
		accept_event()
		return
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):''')

rep('''func _notification(what: int) -> void:''', '''## Iso: two-finger pinch / trackpad / wheel zoom, and one-finger drag pans both ways.
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
			pan_v += e.relative
			_layout()
			return true
	return false

func _notification(what: int) -> void:''')

# walkers on the street grid
rep('''		var lane: Array = LANES[i % LANES.size()]
		folk.append({"walk": anims["walk"]["tex"], "idle": anims["idle"]["tex"] if not anims["idle"].is_empty() else anims["walk"]["tex"].slice(0, 1),
			"x": randf_range(lane[1], lane[2]), "y": float(lane[0]), "lane": lane, "to": -1.0, "wait": randf_range(0.5, 4.0), "flip": randf() < 0.5, "t": randf() * 3.0})''',
    '''		var lane: Array = LANES[i % LANES.size()]
		folk.append({"walk": anims["walk"]["tex"], "idle": anims["idle"]["tex"] if not anims["idle"].is_empty() else anims["walk"]["tex"].slice(0, 1),
			"x": randf_range(lane[1], lane[2]), "y": float(lane[0]), "lane": lane, "to": -1.0, "wait": randf_range(0.5, 4.0), "flip": randf() < 0.5, "t": randf() * 3.0})
		if iso:
			_place_on_grid(folk[-1])''')
rep('''			"flip": randf() < 0.5, "t": randf() * 3.0, "hero": true, "you": bool(e[2])})''', '''			"flip": randf() < 0.5, "t": randf() * 3.0, "hero": true, "you": bool(e[2])})
		if iso:
			_place_on_grid(folk[-1])''')

rep('''func _step_folk(delta: float) -> void:''', '''# Iso townsfolk: stand at a door, then walk the street grid to another door.
func _cell_px(c: Vector2i) -> Vector2:
	var o: Array = data["origin"]
	return Vector2(float(o[0]) + (c.x - c.y) * 16.0, float(o[1]) + (c.x + c.y + 1) * 8.0)

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

func _step_iso_walker(f: Dictionary, delta: float) -> void:
	if float(f["wait"]) > 0.0:
		f["wait"] = float(f["wait"]) - delta
		if float(f["wait"]) <= 0.0 and not walk_doors.is_empty():
			f["path"] = _grid_path(f["cell"], walk_doors[randi() % walk_doors.size()])
			if (f["path"] as Array).is_empty():
				f["wait"] = 1.0
		return
	var path: Array = f["path"]
	if path.is_empty():
		f["wait"] = randf_range(2.0, 6.0)
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

func _step_folk(delta: float) -> void:''')
rep('''	for f in folk:
		f["t"] = float(f["t"]) + delta
		if float(f["wait"]) > 0.0:''', '''	for f in folk:
		f["t"] = float(f["t"]) + delta
		if iso:
			_step_iso_walker(f, delta)
			continue
		if float(f["wait"]) > 0.0:''')

rep('''	people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
	_draw_placeholders()''', '''	people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
	if iso:
		_draw_levels()
	else:
		_draw_placeholders()''')
rep('''		var tx: Texture2D = frames[i]
		var w := float(tx.get_width())
		var pos := Vector2(float(f["x"]) - w / 2.0, float(f["y"]) - w + w * 0.12)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		people.draw_circle(Vector2(float(f["x"]), float(f["y"]) - 2.0), 9.0, Color(0.04, 0.03, 0.08, 0.25))
		if f["flip"]:
			people.draw_set_transform(Vector2((float(f["x"]) * 2.0) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture(tx, pos)''', '''		var tx: Texture2D = frames[i]
		# iso town: walkers at half size (~24 px, about a door's height)
		var k := 0.5 if iso else 1.0
		var w := float(tx.get_width()) * k
		var pos := Vector2(float(f["x"]) - w / 2.0, float(f["y"]) - w + w * 0.12)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		people.draw_circle(Vector2(float(f["x"]), float(f["y"]) - 2.0), 9.0 * k, Color(0.04, 0.03, 0.08, 0.25))
		if f["flip"]:
			people.draw_set_transform(Vector2((float(f["x"]) * 2.0) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture_rect(tx, Rect2(pos, Vector2(w, w)), false)''')
rep('''## 2.1: buildings the town picture doesn't have yet''', '''## Iso: each building's level props (L1 scaffolding + piles, L2 lantern + upgrade, L3 banners + showpiece).
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

## 2.1: buildings the town picture doesn't have yet''')
rep('''func _draw_pen() -> void:
	var wood := Color("#6b4423")''', '''func _draw_pen() -> void:
	if iso:
		_draw_pen_pets(16.0)   # the iso town has its own fence and kennel
		return
	var wood := Color("#6b4423")''')
rep('''	# Pets
	var sorted := pen_pets.duplicate()''', '''	_draw_pen_pets(34.0)

## Your pets in the pen, `px` tall (16 in the iso town: knee-high to a 24 px walker).
func _draw_pen_pets(px: float) -> void:
	var sorted := pen_pets.duplicate()''')
rep('''		var k := 34.0 / maxf(sz.x, sz.y)''', '''		var k := px / maxf(sz.x, sz.y)''')
rep('''			pos = Vector2(randf_range(560, 600), randf_range(330, 350))   # the blacksmith's chimney''', '''			var sm: Array = data.get("smoke", [580, 340])   # the blacksmith's chimney
			pos = Vector2(float(sm[0]) + randf_range(-20, 20), float(sm[1]) + randf_range(-10, 10))''')
open(p, "w", encoding="utf-8").write(s)
print("town_view patched")
