"""Fable round 1 fixes in town_view.gd (3 pan clamp, 4 device pixels + pixel shadow/wisps, 5 doors /
marker, 6 lights, 7 plates, 10 per-frame churn). Usage: py fix_r1_view.py (from claude/town3)"""


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:80])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


V = "../../town_view.gd"
patch(V, [
    # --- state
    ('''var walk_doors: Array = []  # iso: door cells people walk between''',
     '''var walk_doors: Array = []  # iso: door cells people walk between
var walk_door_ids: Array = []  # iso: the spot id of each walk_doors cell (no trips into unbuilt lots)
var walk_keys: Array = []   # iso: walk.keys(), made once
var shadow_tex: Texture2D   # a 2-row pixel ellipse under each walker
var label_key := []         # what the name plates were last drawn for (redrawn only when it changes)
var plate_sb := {}          # "normal" / "hot" / "locked" / "note" -> StyleBoxFlat, made once'''),
    # --- ready: door ids, keys, up textures, shadow, plate boxes
    ('''		for sp in data.get("spots", []):
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))''',
     '''		for sp in data.get("spots", []):
			if String(sp["id"]) in ["market", "bounty", "mail"]:
				continue   # stood at (stops), not gone into
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))
			walk_door_ids.append(String(sp["id"]))'''),
    ('''			walk = seen
			walk_doors = walk_doors.filter(func(c): return walk.has(c))''',
     '''			walk = seen
			for k in range(walk_doors.size() - 1, -1, -1):
				if not walk.has(walk_doors[k]):
					walk_doors.remove_at(k)
					walk_door_ids.remove_at(k)'''),
    ('''		occluders.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))''',
     '''		occluders.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
		walk_keys = walk.keys()
		var lv: Dictionary = data.get("levels", {})
		for id in lv:
			for e in lv[id]:
				if not up_tex.has(String(e[0])):
					up_tex[String(e[0])] = load("res://art/town/iso/up/%s.png" % String(e[0]))
	var shi := Image.create(12, 3, false, Image.FORMAT_RGBA8)
	for x in 12:
		for y in 3:
			if y == 1 or (x >= 2 and x < 10):
				shi.set_pixel(x, y, Color(0.04, 0.03, 0.08, 0.32))
	shadow_tex = ImageTexture.create_from_image(shi)
	for k in ["normal", "hot", "locked", "note"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.06, 0.11, 0.9 if k == "note" else (0.86 if k == "hot" else 0.74))
		sb.border_color = Color("#e8b14a") if k == "hot" else (Color("#3a3a46") if k == "locked" else Color("#5b4a2a"))
		sb.set_border_width_all(0 if k == "note" else (2 if k == "hot" else 1))
		sb.set_corner_radius_all(5 if k == "note" else 6)
		plate_sb[k] = sb'''),
    # --- process: plates redrawn only when something they show changed
    ('''	people.queue_redraw()
	fx.queue_redraw()
	labels.queue_redraw()
''', '''	people.queue_redraw()
	fx.queue_redraw()
	var key := [origin, scale_f, size, hover, press, badges.hash(), locked.hash(), notes.hash(), hidden_spots.hash()]
	if key != label_key:
		label_key = key
		labels.queue_redraw()
'''),
    # --- iso layout: whole device pixels, the view centre kept on the town's diamond
    ('''func _layout_iso(ms: Vector2) -> void:
	scale_f = zoom
	var shown := ms * scale_f
	if not placed:                 # keep centring on the market until the player pans or zooms
		var m := _spot_rect("market")
		pan_v = size / 2.0 - (m.get_center() if m.size != Vector2.ZERO else ms / 2.0) * scale_f
	var lo := size - shown
	pan_v.x = lo.x / 2.0 if lo.x > 0.0 else clampf(pan_v.x, lo.x, 0.0)
	pan_v.y = lo.y / 2.0 if lo.y > 0.0 else clampf(pan_v.y, lo.y, 0.0)
	origin = pan_v.round()''', '''func _layout_iso(ms: Vector2) -> void:
	# a whole number of device pixels per map pixel (the phone's canvas scale is 2.56 or 1.49,
	# so a plain 2x would land between device pixels and shimmer)
	var cs := _device_scale()
	scale_f = maxf(1.0, roundf(zoom * cs)) / cs
	var shown := ms * scale_f
	if not placed:                 # keep centring on the market until the player pans or zooms
		var m := _spot_rect("market")
		pan_v = size / 2.0 - (m.get_center() if m.size != Vector2.ZERO else ms / 2.0) * scale_f
	# the view centre stays over the town's diamond (walls included), never out in the dark wood
	var o: Array = data.get("origin", [ms.x / 2.0, 0])
	var n := float(data.get("grid", 40))
	var dc := Vector2(float(o[0]), float(o[1]) + n * 8.0)
	var half := Vector2(n * 16.0 + 24.0, n * 8.0 + 16.0)
	var c := (size / 2.0 - pan_v) / scale_f - dc
	var reach := absf(c.x) / half.x + absf(c.y) / half.y
	if reach > 0.92:
		c *= 0.92 / reach
		pan_v = size / 2.0 - (dc + c) * scale_f
	var lo := size - shown
	pan_v.x = lo.x / 2.0 if lo.x > 0.0 else clampf(pan_v.x, lo.x, 0.0)
	pan_v.y = lo.y / 2.0 if lo.y > 0.0 else clampf(pan_v.y, lo.y, 0.0)
	origin = (pan_v * cs).round() / cs'''),
    ('''func _spot_rect(id: String) -> Rect2:''', '''## Device pixels per design pixel (the window's stretch), 1 when there's no viewport yet.
func _device_scale() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return maxf(0.01, vp.get_final_transform().get_scale().x)

func _spot_rect(id: String) -> Rect2:'''),
    # --- goals: no doors on unbuilt or hidden lots; walk keys cached
    ('''	elif r < 0.5 and not walk_doors.is_empty():
		goal = walk_doors[randi() % walk_doors.size()]
		f["goal_door"] = true''', '''	elif r < 0.5 and not walk_doors.is_empty():
		var k := randi() % walk_doors.size()
		var id: String = walk_door_ids[k]
		if hidden_spots.has(id) or ((id == "church" or id == "cabin") and not Buildings.built(id)):
			f["wait"] = 0.5   # nobody goes into an empty lot; think again in a moment
			return
		goal = walk_doors[k]
		f["goal_door"] = true'''),
    ('''		var keys := walk.keys()
		goal = keys[randi() % keys.size()]''', '''		goal = walk_keys[randi() % walk_keys.size()]'''),
    # --- draw people: in-place sort, pixel shadow, the marker under the cover
    ('''	var sorted := folk.duplicate()
	sorted.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	for f in sorted:''', '''	# insertion sort in place: the order barely changes between frames
	for a in range(1, folk.size()):
		var f0: Dictionary = folk[a]
		var b := a - 1
		while b >= 0 and float(folk[b]["y"]) > float(f0["y"]):
			folk[b + 1] = folk[b]
			b -= 1
		folk[b + 1] = f0
	for f in folk:'''),
    ('''		people.draw_circle(Vector2(float(f["x"]), float(f["y"]) - 1.0), 6.0, Color(0.04, 0.03, 0.08, 0.3))''',
     '''		people.draw_texture(shadow_tex, Vector2(roundf(float(f["x"])) - 6.0, roundf(float(f["y"])) - 2.0))'''),
    ('''		if iso:
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			_cover(Rect2(pos, Vector2(w, w)), float(f["y"]))
		if f.get("hero", false):
			# A small marker over your heroes (brighter over the one you're playing)
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			var top := Vector2(float(f["x"]), pos.y + 9.0 + sin(float(f["t"]) * 3.0) * 1.5)
			var col := Color("#fbbf24") if f.get("you", false) else Color("#d6c9a0")
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -9), top + Vector2(7, -9), top + Vector2(0, 1)]), Color(0.05, 0.03, 0.08, 0.85))
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -8), top + Vector2(5, -8), top + Vector2(0, -1)]), col)''',
     '''		var top := Vector2(float(f["x"]), pos.y + 9.0 + roundf(sin(float(f["t"]) * 3.0) * 1.5))
		if f.get("hero", false):
			# A small marker over your heroes (brighter over the one you're playing), under the cover
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			var col := Color("#fbbf24") if f.get("you", false) else Color("#d6c9a0")
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -9), top + Vector2(7, -9), top + Vector2(0, 1)]), Color(0.05, 0.03, 0.08, 0.85))
			people.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -8), top + Vector2(5, -8), top + Vector2(0, -1)]), col)
		if iso:
			people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
			var cov := Rect2(pos, Vector2(w, w)).merge(Rect2(top + Vector2(-7, -9), Vector2(14, 10)))
			# on the hope path the walker stands in front of the dungeon: sort by the ground under them
			var up: float = raised.get(f.get("cell", Vector2i(-1, -1)), 0.0)
			_cover(cov, float(f["y"]) + up, "gate" if up > 0.0 else "")'''),
    ('''func _cover(r: Rect2, foot_y: float) -> void:''', '''func _cover(r: Rect2, foot_y: float, skip := "") -> void:'''),
    ('''		var orect: Rect2 = o["rect"]
		if orect.intersects(r):''', '''		var orect: Rect2 = o["rect"]
		if orect.intersects(r) and String(o["tag"]) != skip:'''),
    # --- level props: textures preloaded in _ready
    ('''			var n := String(e[0])
			if not up_tex.has(n):
				up_tex[n] = load("res://art/town/iso/up/%s.png" % n)
			people.draw_texture(up_tex[n], Vector2(float(e[1]), float(e[2])))''',
     '''			people.draw_texture(up_tex[String(e[0])], Vector2(float(e[1]), float(e[2])))'''),
    # --- lights: their own colour and radius, only those on screen
    ('''		for l in data.get("lights", []):
			var c := to_view(Vector2(l[0], l[1]))
			var fl := 0.9 + 0.1 * sin(t * 7.0 + float(l[0]))
			for i in 5:
				var r := (10.0 + i * 9.0) * scale_f
				fx.draw_circle(c, r, Color(1.0, 0.72, 0.36, 0.05 * dark * fl))
			fx.draw_circle(c, 4.0 * scale_f, Color(1.0, 0.85, 0.5, 0.45 * dark * fl))''',
     '''		var view := Rect2(Vector2.ZERO, size)
		for l in data.get("lights", []):
			var c := to_view(Vector2(l[0], l[1]))
			var rad := (float(l[3]) if l.size() > 3 else 46.0) * scale_f
			if not view.grow(rad).has_point(c):
				continue
			var col := Color(1.0, 0.72, 0.36)
			if l.size() > 2 and l[2] is Array:
				col = Color(float(l[2][0]) / 255.0, float(l[2][1]) / 255.0, float(l[2][2]) / 255.0)
			var fl := 0.9 + 0.1 * sin(t * 7.0 + float(l[0]))
			for i in 5:
				fx.draw_circle(c, rad * (0.3 + 0.175 * i), Color(col, 0.05 * dark * fl))
			fx.draw_circle(c, 4.0 * scale_f, Color(col.lightened(0.3), 0.45 * dark * fl))'''),
    # --- weather: pixel squares on whole map pixels, culled off screen
    ('''	var kind := String(look.get("weather", ""))
	for p in parts:
		var a := clampf(minf(float(p["age"]), float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var v := to_view(p["pos"])
		var s := scale_f''', '''	var kind := String(look.get("weather", ""))
	var vr := Rect2(Vector2.ZERO, size).grow(80.0 * scale_f)
	for p in parts:
		var a := clampf(minf(float(p["age"]), float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var v := to_view((p["pos"] as Vector2).round())
		if not vr.has_point(v):
			continue
		var s := scale_f'''),
    ('''			"fog":
				fx.draw_circle(v, 60.0 * s, Color(0.55, 0.6, 0.62, 0.035 * a))
				fx.draw_circle(v + Vector2(40, 10) * s, 46.0 * s, Color(0.55, 0.6, 0.62, 0.03 * a))
			"smoke":
				var grow := 4.0 + float(p["age"]) * 3.0
				fx.draw_circle(v, grow * s, Color(0.35, 0.33, 0.34, 0.12 * a))
			"wisps":
				var bob := Vector2(sin(t + float(p["seed"])) * 6.0, cos(t * 0.8 + float(p["seed"])) * 4.0) * s
				fx.draw_circle(v + bob, 6.0 * s, Color(0.4, 0.6, 1.0, 0.12 * a))
				fx.draw_circle(v + bob, 2.0 * s, Color(0.7, 0.85, 1.0, 0.6 * a))''',
     '''			"fog":
				# low hard-edged banks, like the composed town's fog
				fx.draw_rect(Rect2(v + Vector2(-60, -4) * s, Vector2(120, 8) * s), Color(0.55, 0.6, 0.62, 0.035 * a))
				fx.draw_rect(Rect2(v + Vector2(-36, -8) * s, Vector2(72, 4) * s), Color(0.55, 0.6, 0.62, 0.03 * a))
			"smoke":
				var grow := floorf(2.0 + float(p["age"]) * 1.5) * 2.0
				fx.draw_rect(Rect2(v - Vector2(grow, grow) * s / 2.0, Vector2(grow, grow) * s), Color(0.35, 0.33, 0.34, 0.12 * a))
			"wisps":
				var bob := Vector2(roundf(sin(t + float(p["seed"])) * 6.0), roundf(cos(t * 0.8 + float(p["seed"])) * 4.0)) * s
				fx.draw_rect(Rect2(v + bob - Vector2(2, 2) * s, Vector2(4, 4) * s), Color(0.4, 0.6, 1.0, 0.18 * a))
				fx.draw_rect(Rect2(v + bob - Vector2(1, 1) * s, Vector2(2, 2) * s), Color(0.7, 0.85, 1.0, 0.6 * a))'''),
    # --- plates: an optional fixed spot, none for the Mailbox, cached style boxes
    ('''	var anchor := to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + 10.0))
	if s["id"] == "bounty":
		anchor = to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) - 8.0))
	if s["id"] == "gate":
		anchor = to_view(Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + float(r[3]) + 10.0))''',
     '''	var anchor := to_view(plate_anchor(s))'''),
    ('''## Iso: the town is bigger than the screen, so only buildings in view get a name plate''',
     '''## Where a spot's name plate sits, in map pixels: town.json "plate" if it has one (the Market's
## sits by the well, the Dungeon's above the portal), else near the top of its tap area.
static func plate_anchor(s: Dictionary) -> Vector2:
	if s.get("plate") is Array:
		return Vector2(float(s["plate"][0]), float(s["plate"][1]))
	var r: Array = s["rect"]
	return Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + 10.0)

## Iso: the town is bigger than the screen, so only buildings in view get a name plate'''),
    ('''	if not iso:
		return true
	var r: Array = s["rect"]''', '''	if not iso:
		return true
	if s.has("plate") and s["plate"] == null:
		return false   # no plate (the Mailbox: its badge is on the Mail button)
	var r: Array = s["rect"]'''),
    ('''		var bg := Color(0.05, 0.06, 0.11, 0.86 if hot else 0.74)
		var edge := Color("#e8b14a") if hot else (Color("#5b4a2a") if why == "" else Color("#3a3a46"))
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = edge
		sb.set_border_width_all(2 if hot else 1)
		sb.set_corner_radius_all(6)
		labels.draw_style_box(sb, rect)''', '''		labels.draw_style_box(plate_sb["hot" if hot else ("normal" if why == "" else "locked")], rect)'''),
    ('''			var nb := StyleBoxFlat.new()
			nb.bg_color = Color(0.05, 0.06, 0.11, 0.9)
			nb.set_corner_radius_all(5)
			labels.draw_style_box(nb, nr)''', '''			labels.draw_style_box(plate_sb["note"], nr)'''),
])
print("town_view patched")
