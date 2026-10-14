class_name RoomView
extends Control
## 0.13 The Halls Below: the room you're standing in, seen from above.
## One room per floor. Between fights you see the monsters still waiting (tap one
## to fight it, or Auto walks up to them); when the room is clear, three blank
## doors on the far wall lead on (tap one). Tiles: Dungeon Crawl Stone Soup (CC0).

const TILE := 32          # art pixels per tile
const SCALE := 2          # drawn at 2x (whole pixels stay crisp)
const ZONE_MOODS := [     # particles and light by zone index
	{"kind": "fireflies", "dark": 0.35, "light": Color("#ffd27a")},
	{"kind": "dust", "dark": 0.55, "light": Color("#ffb35c")},
	{"kind": "drips", "dark": 0.45, "light": Color("#a8e6ff")},
	{"kind": "embers", "dark": 0.4, "light": Color("#ff7a3d")},
	{"kind": "shadows", "dark": 0.55, "light": Color("#c9a3ff")},
	{"kind": "leaves", "dark": 0.4, "light": Color("#b8f5d0")},
	{"kind": "sparkles", "dark": 0.35, "light": Color("#ffb3f0")},
	{"kind": "sparks", "dark": 0.45, "light": Color("#ffcf6b")},
	{"kind": "motes", "dark": 0.2, "light": Color("#fff4c2")},
	{"kind": "embers", "dark": 0.55, "light": Color("#ff4a4a")},
]

var main
var state: GameState
var t := 0.0
var key := ""
var cols := 6
var rows := 10
var origin := Vector2.ZERO
var cells: Array = []      # [row][col] -> {"floor": tex, "wall": tex or null, "prop": tex or null}
var door_cols: Array = []  # column of each of the 3 doors (top wall)
var spots: Array = []      # where waiting monsters stand (tile coords)
var extra_art: Array = []  # art keys for the monsters after the current one
var torches: Array = []    # tile coords of wall torches
var motes: Array = []
var hit := {}              # "m<i>" / "d<i>" -> Rect2 (tap targets)
var _tex := {}

func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func _tx(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]

func _process(delta: float) -> void:
	if not is_visible_in_tree() or main == null:
		return
	state = main.state
	t += delta
	_step_motes(delta)
	var k := "%d|%d|%d|%s" % [state.floor_num, state.room_count, int(size.x) * 10000 + int(size.y), str(state.doors.size())]
	if k != key:
		key = k
		_build()
	queue_redraw()

## Lays the room out (same floor and room = same room).
func _build() -> void:
	var px := TILE * SCALE
	cols = clampi(floori(size.x / px), 5, 13)
	rows = clampi(floori(size.y / px), 6, 14)
	origin = ((size - Vector2(cols, rows) * px) / 2.0).floor()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d-%d" % [state.floor_num, state.room_count])
	var z := clampi(GameData.zone_index(state.floor_num), 0, 9)
	var floors: Array = []
	var walls: Array = []
	for i in 4:
		var f := _tx("res://art/dungeon/z%d_floor_%d.png" % [z, i])
		if f:
			floors.append(f)
		var w := _tx("res://art/dungeon/z%d_wall_%d.png" % [z, i])
		if w:
			walls.append(w)
	cells = []
	for r in rows:
		var row: Array = []
		for c in cols:
			var wall: Texture2D = null
			if r == 0 or c == 0 or c == cols - 1:
				wall = walls[rng.randi() % walls.size()] if not walls.is_empty() else null
			var fl: Texture2D = floors[rng.randi() % floors.size()] if not floors.is_empty() else null
			row.append({"floor": fl, "wall": wall, "prop": null})
		cells.append(row)
	# Three doors on the far wall
	door_cols = [maxi(1, cols / 6), cols / 2, mini(cols - 2, cols - 1 - cols / 6)]
	if door_cols[0] == door_cols[1]:
		door_cols[0] = maxi(1, door_cols[1] - 2)
	if door_cols[2] == door_cols[1]:
		door_cols[2] = mini(cols - 2, door_cols[1] + 2)
	# Torches on the side walls, a few pillars and statues inside
	torches = [Vector2i(0, 2 + rng.randi() % maxi(1, rows - 5)), Vector2i(cols - 1, 2 + rng.randi() % maxi(1, rows - 5))]
	var props := ["statue_0", "statue_1", "statue_2", "statue_3", "boulder", "pillar", "box"]
	if z == 1:
		props += ["sarcophagus", "sarcophagus"]
	if z in [3, 9]:
		props += ["blood_fountain"]
	for _i in rng.randi_range(2, 4):
		var c := rng.randi_range(1, cols - 2)
		var r := rng.randi_range(2, rows - 4)
		if c in door_cols and r <= 2:
			continue
		if absi(c - cols / 2) <= 0 and r >= rows - 4:
			continue  # keep the path to the team clear
		cells[r][c]["prop"] = _tx("res://art/dungeon/%s.png" % props[rng.randi() % props.size()])
	# Where monsters wait
	spots = []
	for i in 3:
		spots.append(Vector2(cols * (0.3 + 0.2 * i), rows * (0.3 + 0.08 * (i % 2))))
	extra_art = []
	for _i in 2:
		var def := GameData.pick_monster(maxi(1, state.floor_num))
		extra_art.append(GameData.art_key(String(def["name"])))
	motes.clear()

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
			else:
				main.engage_monster()
			return

# =====================================================================
# Drawing
# =====================================================================

func _cell_rect(c: float, r: float) -> Rect2:
	var px := float(TILE * SCALE)
	return Rect2(origin + Vector2(c, r) * px, Vector2(px, px))

func _draw() -> void:
	if state == null or cells.is_empty():
		return
	hit.clear()
	var px := float(TILE * SCALE)
	var z := clampi(GameData.zone_index(state.floor_num), 0, 9)
	var mood: Dictionary = ZONE_MOODS[z]
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.04))
	var doors_open := state.door_pending()
	# Floor and walls
	for r in rows:
		for c in cols:
			var cell: Dictionary = cells[r][c]
			var rect := _cell_rect(c, r)
			if cell["floor"]:
				draw_texture_rect(cell["floor"], rect, false)
			if cell["wall"]:
				draw_texture_rect(cell["wall"], rect, false)
				if r == 0:  # the far wall casts a shadow on the floor
					draw_rect(Rect2(rect.position + Vector2(0, px), Vector2(px, px * 0.3)), Color(0, 0, 0, 0.35))
	# Doors
	for i in 3:
		var rect := _cell_rect(door_cols[i], 0)
		var dt := _tx("res://art/dungeon/%s.png" % ("door_open" if doors_open else "door_closed"))
		if dt:
			draw_texture_rect(dt, rect, false)
		if doors_open:
			# A door reader on the team senses what's behind: a glow, later the room itself
			var rd := Halls.read_door(state, i)
			var col := Color(String(rd["color"])) if String(rd["color"]) != "" else Color(1.0, 0.85, 0.45)
			var pulse := 0.45 + 0.35 * sin(t * 3.0 + i)
			if String(rd["color"]) != "":
				draw_circle(rect.get_center(), px * 0.75, Color(col, 0.18 + 0.1 * sin(t * 2.0 + i)))
			draw_rect(rect.grow(2), Color(col, pulse), false, 2.0)
			hit["d%d" % i] = rect.grow(10)
			var font := get_theme_default_font()
			var lab := String(rd["label"]) if String(rd["label"]) != "" else ""
			var fs := 18 if lab == "?" else 11
			if lab != "":
				draw_string_outline(font, rect.position + Vector2(-20, px + 16), lab, HORIZONTAL_ALIGNMENT_CENTER, px + 40, fs, 4, Color(0, 0, 0, 0.9))
				draw_string(font, rect.position + Vector2(-20, px + 16), lab, HORIZONTAL_ALIGNMENT_CENTER, px + 40, fs, col.lightened(0.3))
	# Props (with a little shadow)
	for r in rows:
		for c in cols:
			var pr: Texture2D = cells[r][c]["prop"]
			if pr:
				var rect := _cell_rect(c, r)
				_shadow(Vector2(rect.get_center().x, rect.end.y - 6), px * 0.35)
				draw_texture_rect(pr, rect, false)
	# Torches and their light
	for tc in torches:
		var rect := _cell_rect(tc.x, tc.y)
		var tt := _tx("res://art/dungeon/torch.png")
		if tt:
			draw_texture_rect(tt, rect, false)
	# A trap you've spotted (hidden ones stay hidden)
	var tr: Dictionary = state.room_trap
	if not tr.is_empty() and tr.get("spotted", false) and not tr.get("done", false) and not doors_open:
		var tt2 := _tx("res://art/dungeon/trap_%s.png" % String(tr["kind"]))
		var tp := origin + Vector2(cols * float(tr["x"]), rows * float(tr["y"])) * px
		var trr := Rect2(tp - Vector2(px / 2.0, px / 2.0), Vector2(px, px))
		if tt2:
			draw_texture_rect(tt2, trr, false)
		draw_rect(trr.grow(2), Color(1, 0.75, 0.2, 0.5 + 0.3 * sin(t * 5.0)), false, 2.0)
	# Monsters still in the room
	if not doors_open and not state.in_town:
		var left := 1 if state.enemy_is_boss else maxi(1, GameData.FIGHTS_PER_FLOOR - state.fight + 1)
		for i in mini(left, 3):
			var art_key := state.enemy_art if i == 0 else String(extra_art[(i - 1) % extra_art.size()])
			var art := Sprites.enemy_by_key(art_key)
			if art.is_empty():
				continue
			var tex: Texture2D = art["tex"]
			var sc := (2.0 if state.enemy_is_boss else 1.25) if i == 0 else 1.0
			var sz := Vector2(tex.get_size()) * sc
			var spot: Vector2 = spots[i]
			var feet := origin + spot * px + Vector2(0, sin(t * 2.2 + i) * 2.0)
			var rect := Rect2(feet - Vector2(sz.x / 2.0, sz.y), sz)
			_shadow(feet, sz.x * 0.3)
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, 1) if i == 0 else Color(0.85, 0.85, 0.9))
			if i == 0:
				draw_rect(rect.grow(3), Color(1, 0.4, 0.35, 0.35 + 0.25 * sin(t * 4.0)), false, 2.0)
			hit["m%d" % i] = rect.grow(8)
	# Your team at the entrance, seen from behind
	_draw_team(px)
	# Darkness: deeper is darker, the team's light and torches push it back
	var depth := clampf(state.floor_num / 1000.0, 0.0, 1.0)
	var dark: float = clampf(float(mood["dark"]) + depth * 0.3, 0.0, 0.85)
	var team_c := origin + Vector2(cols / 2.0, rows - 1.6) * px
	_darkness(dark, [team_c] + torches.map(func(tc): return _cell_rect(tc.x, tc.y).get_center()), mood["light"])
	_draw_motes(mood)
	# What to do
	var font2 := get_theme_default_font()
	var msg := "Pick a door" if doors_open else "Tap a monster to fight"
	if not doors_open and state.autoplay:
		msg += "  (Auto walks up soon)"
	draw_string_outline(font2, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, 4, Color(0, 0, 0, 0.9))
	draw_string(font2, Vector2(0, size.y - 14), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color("#f6d88f"))
	var title := "%s  -  Floor %d" % [GameData.zone_for_floor(state.floor_num)["name"], state.floor_num]
	draw_string_outline(font2, Vector2(10, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
	draw_string(font2, Vector2(10, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.75))

func _draw_team(px: float) -> void:
	var members: Array = state.party.members if state.party != null else []
	var xs := [cols / 2.0]
	if members.size() >= 1:
		xs.append(cols / 2.0 - 1.1)
	if members.size() >= 2:
		xs.append(cols / 2.0 + 1.1)
	for i in xs.size():
		var g: GameState = state if i == 0 else members[i - 1].hero
		var art := Sprites.hero_back(g.appearance, g.hero_looks())
		if not art.has("lpc"):
			continue
		var an: Dictionary = (art["lpc"] as Dictionary).get("combat_idle", {})
		if an.is_empty():
			continue
		var n: int = (an["tex"] as Array).size()
		var fi := int(t * float(an["fps"]) + i) % n
		var s: float = float(an["size"]) * (1.6 if i == 0 else 1.4)
		var feet := origin + Vector2(xs[i], rows - 0.6 - (0.0 if i == 0 else 0.25)) * px
		_shadow(feet, 14.0)
		var a := 0.4 if (i == 0 and state.leader_down) or (i > 0 and members[i - 1].knocked_out) else 1.0
		draw_texture_rect(an["tex"][fi], Rect2(feet - Vector2(s / 2.0, s * 0.9), Vector2(s, s)), false, Color(1, 1, 1, a))

func _shadow(at: Vector2, r: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)

## Darkness over the room with soft pools of light (drawn as rings of decreasing darkness).
func _darkness(dark: float, lights: Array, light_col: Color) -> void:
	if dark <= 0.01:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.0, 0.03, dark * 0.55))
	for lp in lights:
		var flick := 1.0 + 0.04 * sin(t * 9.0 + (lp as Vector2).x)
		for k in 6:
			var rr := (180.0 - k * 26.0) * flick
			draw_circle(lp, rr, Color(light_col, 0.025 * dark + 0.01))
	# edges fall into shadow
	for i in 6:
		var f := float(i) / 6.0
		var a := dark * 0.12 * (1.0 - f)
		draw_rect(Rect2(0, 0, size.x * 0.12 * (1.0 - f), size.y), Color(0, 0, 0, a))
		draw_rect(Rect2(size.x - size.x * 0.12 * (1.0 - f), 0, size.x * 0.12 * (1.0 - f), size.y), Color(0, 0, 0, a))
		draw_rect(Rect2(0, 0, size.x, size.y * 0.08 * (1.0 - f)), Color(0, 0, 0, a))

# =====================================================================
# Mood particles by region
# =====================================================================

func _step_motes(delta: float) -> void:
	if state == null:
		return
	var z := clampi(GameData.zone_index(state.floor_num), 0, 9)
	var kind: String = ZONE_MOODS[z]["kind"]
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
