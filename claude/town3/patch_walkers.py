"""One-off: town_view walkers stay on the street grid, hide behind what stands in front of them
(occluders from town.json), and do things: go into buildings, stop at stalls / the well / the
boards, chat in pairs, idle. Usage: py patch_walkers.py <repo>"""
import sys

p = sys.argv[1] + "/town_view.gd"
s = open(p, encoding="utf-8", newline="").read()


def rep(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b, 1)


rep('''var walk_doors: Array = []  # iso: door cells people walk between''', '''var walk_doors: Array = []  # iso: door cells people walk between
var walk_stops: Array = []  # iso: cells beside stalls, the well and the boards where people stop a while
var raised := {}        # iso: Vector2i cell -> true on the plateau path (people stand higher there)
var occluders: Array = []  # iso: [texture name, x, y, sort y, tag(, look)] - drawn again over a walker behind them
var occ_tex := {}''')

rep('''		for sp in data.get("spots", []):
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))''', '''		for sp in data.get("spots", []):
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))
		for c in data.get("stops", []):
			walk_stops.append(Vector2i(int(c[0]), int(c[1])))
		for c in data.get("raised", []):
			raised[Vector2i(int(c[0]), int(c[1]))] = true
		occluders = data.get("occluders", [])''')

rep('''func _cell_px(c: Vector2i) -> Vector2:
	var o: Array = data["origin"]
	return Vector2(float(o[0]) + (c.x - c.y) * 16.0, float(o[1]) + (c.x + c.y + 1) * 8.0)''', '''func _cell_px(c: Vector2i) -> Vector2:
	var o: Array = data["origin"]
	var z := float(data.get("raised_z", 0)) if raised.has(c) else 0.0
	return Vector2(float(o[0]) + (c.x - c.y) * 16.0, float(o[1]) + (c.x + c.y + 1) * 8.0 - z)''')

rep('''func _step_iso_walker(f: Dictionary, delta: float) -> void:
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
		return''', '''## Where to go next: mostly a building's door (then inside for a while), else a stall, the well
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
				return''')

# drawing: hidden while inside, fade at the door, occluders over walkers behind them
rep('''	for f in sorted:
		var walking := float(f["wait"]) <= 0.0''', '''	for f in sorted:
		if iso and float(f.get("fade", 0.0)) >= 1.0:
			continue
		var walking := float(f["wait"]) <= 0.0''')
rep('''		people.draw_texture_rect(tx, Rect2(pos, Vector2(w, w)), false)''', '''		people.draw_texture_rect(tx, Rect2(pos, Vector2(w, w)), false, Color(1, 1, 1, 1.0 - float(f.get("fade", 0.0))))
		if iso:
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			_cover(Rect2(pos, Vector2(w, w)), float(f["y"]))''')
rep('''## Iso: each building's level props''', '''## Iso: redraw whatever stands in front of a walker (sorts lower on screen) and overlaps it,
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

## Iso: each building's level props''')
open(p, "w", encoding="utf-8", newline="").write(s)
print("walkers patched")
