class_name TownView
extends Control
## The town map: a picture of the town that you tap. Each building opens its page. The look
## follows the zone you're in (Town.LOOKS): a color grade, lamp glow at dusk and night, and a
## little weather. The isometric town (town.json "iso", built by claude/town3/export_town.py)
## has one picture per Church / Trophy Cabin state, pans both ways, pinches between 2x and 3x,
## and its townsfolk walk the street grid; the older top-down town uses one picture per season.

signal building_pressed(id: String)
signal zoomed(z: float)                      # a pinch or wheel step (main plays a tick)
signal chatted(pos: Vector2)                 # two townsfolk start a chat, at map px `pos`
signal door_used(id: String, pos: Vector2)   # a walker goes in at a door, at map px `pos`

const SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sat = 1.0;
uniform float dark = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;  // COLOR: shapes drawn on the map (shadows, the pen) keep their own color
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(vec3(l), c.rgb, sat) * tint.rgb;
	float lit = smoothstep(0.3, 0.5, c.r - c.b) * smoothstep(0.6, 0.8, l);   // a lit pane or flame keeps ~80% of its light
	g = mix(g, g * vec3(0.42, 0.48, 0.72), dark * (1.0 - 0.75 * lit));
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
var chimney: Array = []  # the forge chimney's smoke, in every look
var river: Array = []    # iso: drifting pale dashes on the water, [cell px, phase, side offset]
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
var walk_door_ids: Array = []  # iso: the spot id of each walk_doors cell (no trips into unbuilt lots)
var walk_keys: Array = []   # iso: walk.keys(), made once
var shadow_tex: Texture2D   # a 2-row pixel ellipse under each walker
var shadow_pet: Texture2D   # the same, wider, under a pet
var label_key := []         # what the name plates were last drawn for (redrawn only when it changes)
var plate_sb := {}          # "normal" / "hot" / "locked" / "note" -> StyleBoxFlat, made once
var inn_doors: Array = []  # iso: the Inn and its lodging wing - everyone lives at the Inn, so most trips start or end here
var walk_stops: Array = []  # iso: cells beside stalls, the well and the boards where people stop a while
var raised := {}        # iso: Vector2i cell -> px above the ground on the hope path (people climb the stairs)
var occluders: Array = []  # iso: {"tex", "rect", "y", "tag", "look"} sorted by y (front-most last) - drawn again over a walker behind them
var occ_state := ""     # iso: which Church / Trophy Cabin occluders are active ("church:holy|cabin" style key)
var occ_live: Array = []  # iso: occluders for the current state, sorted by y
var up_tex := {}        # iso: level-prop name -> Texture2D
var up_lit := {}        # iso: level-prop name -> its lit texture (the L2 lantern's panes), if it has one
var walk_base := {}     # iso: the walk grid with no level props standing on it
var stop_face := {}     # iso: stop cell -> x of the stall / well / board people turn to face there
var live_stops: Array = []  # iso: walk_stops not blocked by a level prop
var levels_key := ""    # iso: Buildings levels the props, blocked cells and prop occluders were made for
var level_live: Array = []  # iso: [texture, position] of the level props shown now
var level_occ: Array = []   # iso: those props as occluders (walkers pass behind them)
var build_queue: Array = []  # walkers still to build, one per frame once the town is on screen
var pet_half := {}      # pet texture RID -> the same art halved for the iso town (an outline kept, no 0.5 sampling)
var shadow_step: Texture2D  # the walker shadow squashed on a step frame
var light_tex: Texture2D    # a stepped radial glow, one draw per lamp
var light_n: Array = []     # per town.json light: how many lights (itself too) lie within 56 px (the glow is shared out)
var lit_frame := 0          # which of the two flame frames shows, flipped at jittered times
var next_flip := 0.0
var cast_day := -1          # the day today's townsfolk were cast for
var spots_live: Array = []  # _spots(), rebuilt when hidden_spots changes
var spots_key := -1
var level_seen := {}        # building id -> the level its props were last shown at
var level_flash := {}       # building id -> [note, until t]: "Now level N" after an upgrade
var flash_parts: Array = [] # sparkles over freshly upgraded level props
var lit_ov: Array = []     # iso: [texture, map position] of the dusk overlay (lit windows and flames)
var marker_tex := {}    # "you" / "hero" -> a pixel chevron over your heroes
var bubble_tex: Texture2D   # a "..." chat bubble
var touches := {}       # iso: finger index -> position, for the pinch
var pinch_from := 0.0
var plate_w := {}       # "label|font size" -> plate width (measured once; cleared with the look)
var placed := false     # iso: the player has moved the camera (until then it follows the market on resizes)

## A spot from town.json by id ({} if none).
func _spot(id: String) -> Dictionary:
	for sp in data.get("spots", []):
		if String(sp["id"]) == id:
			return sp
	return {}

## The buildings you can see and tap.
func _spots() -> Array:
	var k := hidden_spots.hash()
	if k != spots_key:     # (round 5) not a new filtered array on every mouse move
		spots_key = k
		spots_live = data.get("spots", []).filter(func(sp): return not hidden_spots.has(String(sp["id"])))
	return spots_live

## The Clinic's pen in map pixels (the old garden plots on the top-down town; town.json "pen" on the iso town).
var PEN := Rect2(462, 916, 160, 160)

## Your pets in the pen: a list of textures. Rebuilt only when `key` changes.
var pets_key := ""
func set_pets(texs: Array, key: String) -> void:
	if key == pets_key:
		return
	pets_key = key
	pen_pets.clear()
	for tx in texs.slice(0, MAX_TOWN_PETS):   # the caller lists the most relevant first
		if tx == null:
			continue
		var at := _pen_spot()
		pen_pets.append({"tex": tx, "x": at.x, "y": at.y,
			"to": Vector2.ZERO, "wait": randf_range(0.5, 3.0), "flip": randf() < 0.5, "t": randf() * 3.0})

## Somewhere for a pet to go: the middle of a free pen cell (town.json "pen_cells": not the kennel
## or the hay) with a little jitter; anywhere in the pen on the old top-down town.
func _pen_spot() -> Vector2:
	var cells: Array = data.get("pen_cells", []) if iso else []
	if cells.is_empty() or not (cells[0] is Array):
		return Vector2(randf_range(PEN.position.x + 16, PEN.end.x - 16), randf_range(PEN.position.y + 24, PEN.end.y - 8))
	var c: Array = cells[randi() % cells.size()]
	return _cell_px(Vector2i(int(c[0]), int(c[1]))) + Vector2(randf_range(-6, 6), randf_range(-3, 3))

## Juzo: a town that never looks crowded on a phone. Townsfolk, all walkers (your heroes walk first,
## you at the head), and pets shown in town (the pen), at most.
const MAX_FOLK := 6
const MAX_WALKERS := 10
const MAX_TOWN_PETS := 4
const WALK_SPEED := 26.0   # map px / s
const STEP_PX := 4.0       # map px walked per walk frame (feet planted, no skating)

## Where townsfolk stroll: [feet y, min x, max x] in map pixels (kept clear of things they'd walk through).
const LANES := [[384, 150, 390], [700, 200, 470], [800, 300, 400], [470, 400, 470]]
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
			if String(sp["id"]) in ["market", "bounty", "mail"]:
				continue   # stood at (stops), not gone into
			walk_doors.append(Vector2i(int(sp["door"][0]), int(sp["door"][1])))
			walk_door_ids.append(String(sp["id"]))
		for c in data.get("inn_doors", []):
			inn_doors.append(Vector2i(int(c[0]), int(c[1])))
			walk[inn_doors[-1]] = true
		for c in data.get("stops", []):
			walk_stops.append(Vector2i(int(c[0]), int(c[1])))
			if c.size() > 2:
				stop_face[walk_stops[-1]] = float(c[2])
		for c in data.get("raised", []):
			raised[Vector2i(int(c[0]), int(c[1]))] = float(c[2])
		# keep only the street network reachable from the Inn, and doors / stops on it (no stuck walkers)
		if not inn_doors.is_empty():
			var seen := {inn_doors[0]: true}
			var q: Array = [inn_doors[0]]
			while not q.is_empty():
				var c: Vector2i = q.pop_front()
				for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nb: Vector2i = c + dv
					if walk.has(nb) and not seen.has(nb):
						seen[nb] = true
						q.append(nb)
			walk = seen
			for k in range(walk_doors.size() - 1, -1, -1):
				if not walk.has(walk_doors[k]):
					walk_doors.remove_at(k)
					walk_door_ids.remove_at(k)
			inn_doors = inn_doors.filter(func(c): return walk.has(c))
			walk_stops = walk_stops.filter(func(c): return walk.has(c))
		# occluders: textures loaded once here, sorted by depth so _cover can stop early
		for o in data.get("occluders", []):
			var t: Texture2D = load("res://art/town/iso/occ/%s.png" % String(o[0]))
			if t == null:
				continue
			var lt: Texture2D = load("res://art/town/iso/occ/%s.png" % String(o[6])) if o.size() > 6 and String(o[6]) != "" else null
			occluders.append({"tex": t, "rect": Rect2(float(o[1]), float(o[2]), t.get_width(), t.get_height()), "y": float(o[3]),
				"tag": String(o[4]), "look": String(o[5]) if o.size() > 5 else "", "lit": lt})
		occluders.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
		walk_base = walk
		walk_keys = walk.keys()
		_make_river()
		live_stops = walk_stops
		var lv: Dictionary = data.get("levels", {})
		for id in lv:
			for e in lv[id]:
				if not up_tex.has(String(e[0])):
					up_tex[String(e[0])] = load("res://art/town/iso/up/%s.png" % String(e[0]))
					var lp := "res://art/town/iso/up/%s_lit.png" % String(e[0])
					if ResourceLoader.exists(lp):
						up_lit[String(e[0])] = load(lp)
	shadow_tex = _shadow(12)
	shadow_pet = _shadow(16)   # under 32 px pet art
	shadow_step = _shadow(10)
	light_tex = _light_texture()
	light_n = light_counts(data.get("lights", []))
	marker_tex = {"you": _chevron(Color("#fbbf24"), Color("#a86a12")), "hero": _chevron(Color("#d6c9a0"), Color("#8a7c58"))}
	bubble_tex = _bubble()
	set_notify_transform(true)
	for k in ["normal", "hot", "locked", "note"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.06, 0.11, 0.9 if k == "note" else (0.86 if k == "hot" else 0.74))
		sb.border_color = Color("#e8b14a") if k == "hot" else (Color("#3a3a46") if k == "locked" else Color("#5b4a2a"))
		sb.set_border_width_all(0 if k == "note" else (2 if k == "hot" else 1))
		sb.set_corner_radius_all(5 if k == "note" else 6)
		plate_sb[k] = sb
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
	refresh_levels()
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(_draw_fx)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = add
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # the glow's five steps stay hard
	add_child(fx)
	labels = Control.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.draw.connect(_draw_labels)
	add_child(labels)
	resized.connect(_layout)
	set_look(Town.LOOKS[0])

## The river's moving dashes: one per three water cells (the bridge's cells left out), each on its
## own phase, drifting down the river.
func _make_river() -> void:
	var water := []
	var bridge := Rect2i()
	for g in data.get("ground", []):
		if String(g[0]) == "bridge":
			bridge = Rect2i(int(g[1]), int(g[2]), int(g[3]) - int(g[1]) + 1, int(g[4]) - int(g[2]) + 1)
	for g in data.get("ground", []):
		if String(g[0]) == "water":
			for i in range(int(g[1]), int(g[3]) + 1):
				for j in range(int(g[2]), int(g[4]) + 1):
					if not bridge.has_point(Vector2i(i, j)):
						water.append(Vector2i(i, j))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in range(0, water.size(), 3):
		var c: Vector2i = water[(k + rng.randi_range(0, 2)) % water.size()]
		river.append([_cell_px(c), rng.randf(), rng.randf_range(-3.0, 3.0)])

## The dashes: 3x1, pale, 6 px/s down the river (south-east, along the cell), under the walkers.
func _draw_river() -> void:
	for d in river:
		var u := fposmod(t * 6.0 / 18.0 + float(d[1]), 1.0)   # one cell (18 px along) every 3 s
		var p: Vector2 = d[0] + Vector2(-8.0 + u * 16.0, -8.0 + u * 8.0 + float(d[2]))
		people.draw_rect(Rect2(p.round(), Vector2(3, 1)), Color(0.55, 0.7, 0.75, 0.55 * minf(1.0, 4.0 * minf(u, 1.0 - u))))

## A `w`x3 pixel ellipse under a walker.
func _shadow(w: int) -> Texture2D:
	var im := Image.create(w, 3, false, Image.FORMAT_RGBA8)
	for x in w:
		for y in 3:
			if y == 1 or (x >= 2 and x < w - 2):
				im.set_pixel(x, y, Color(0.04, 0.03, 0.08, 0.32))
	return ImageTexture.create_from_image(im)

## A lamp's glow: 64x64, five hard steps (pixel-art light, drawn once per lamp instead of 5 discs).
func _light_texture() -> Texture2D:
	var im := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2(x - 31.5, y - 31.5).length() / 32.0
			if r < 1.0:
				im.set_pixel(x, y, Color(1, 1, 1, band_alpha(r)))
	return ImageTexture.create_from_image(im)

## The glow texture's alpha at `r` (0 centre .. 1 rim): a 0.7 core (not 1: four overlapping cores
## whitened the porch), then five steps.
static func band_alpha(r: float) -> float:
	if r >= 1.0:
		return 0.0
	return 0.7 if r < 0.09 else 0.55 * (5 - floori(r * 5.0)) / 5.0

## Per light: how many lights (itself included) lie within 56 px. A light shares its glow by the
## square root of that, so a cluster of lamps lights a porch instead of washing it white.
static func light_counts(lights: Array) -> Array:
	var out: Array = []
	for a in lights:
		var n := 0
		for b in lights:
			if Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1]))) <= 56.0:
				n += 1
		out.append(maxi(n, 1))
	return out

## The summed glow alpha at map point `p` for darkness `dark` (no flicker): what the additive layer
## puts over the picture there. The test keeps it under 0.9 where the lamps cluster.
static func glow_sum(lights: Array, p: Vector2, dark: float) -> float:
	var n := light_counts(lights)
	var sum := 0.0
	for i in lights.size():
		var l: Array = lights[i]
		var rad := float(l[3]) if l.size() > 3 else 46.0
		sum += band_alpha(p.distance_to(Vector2(float(l[0]), float(l[1]))) / rad) * glow_alpha(dark) / sqrt(float(n[i]))
	return sum

## A 7x5 chevron with a 1 px dark edge (9x7 in all), pointing down at a hero.
func _chevron(lite: Color, mid: Color) -> Texture2D:
	var rows := ["xxxxxxxxx", "xLLLLLLLx", "xxMMMMMxx", ".xxMMMxx.", "..xxMxx..", "...xxx...", "....x...."]
	var im := Image.create(9, 7, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 9:
			var ch: String = rows[y][x]
			if ch != ".":
				im.set_pixel(x, y, Color(0.05, 0.03, 0.08) if ch == "x" else (lite if ch == "L" else mid))
	return ImageTexture.create_from_image(im)

## A "..." speech bubble: 7x3 inside a 1 px dark edge, a tail below.
func _bubble() -> Texture2D:
	var rows := [".xxxxxxx.", "xWWWWWWWx", "xWdWdWdWx", "xWWWWWWWx", ".xxxxxxx.", "...xx...."]
	var im := Image.create(9, 6, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 9:
			var ch: String = rows[y][x]
			if ch != ".":
				im.set_pixel(x, y, Color(0.05, 0.03, 0.08) if ch == "x" or ch == "d" else Color("#ece4cc"))
	return ImageTexture.create_from_image(im)

## Iso: the level props for the buildings' levels now - which to draw, which street cells they
## stand on (taken off the walk grid, never cutting a door or stop off), and their occluders.
## Call when a building's level may have changed (main._sync_town); cheap when nothing did.
func refresh_levels() -> void:
	if not iso:
		return
	var lv: Dictionary = data.get("levels", {})
	var key := ""
	for id in lv:
		key += "%s%d%s," % [id, Buildings.level(String(id)), hidden_spots.has(id)]
	if key == levels_key:
		return
	var first := levels_key == ""
	levels_key = key
	level_live.clear()
	level_occ.clear()
	var keep := {}
	for c in inn_doors + walk_doors:
		keep[c] = true
	var blocked: Array = []
	for id in lv:
		if hidden_spots.has(id):
			continue
		var l := Buildings.level(String(id))
		var up: bool = not first and is_visible_in_tree() and l > int(level_seen.get(id, l))
		level_seen[id] = l
		if up:   # you just paid for it: "Now level N" under the plate for 4 s
			level_flash[id] = ["Now level %d" % l, t + 4.0]
		for e in lv[id]:
			if int(e[3]) != l:
				continue
			if up:
				for _k in 10:
					flash_parts.append({"pos": Vector2(float(e[1]), float(e[2])) + Vector2(randf_range(0, 24), randf_range(0, 30)),
						"vel": Vector2(randf_range(-4, 4), -randf_range(6, 14)), "age": 0.0, "life": 1.5, "seed": randf() * TAU})
			var tx: Texture2D = up_tex.get(String(e[0]))
			if tx == null:
				continue   # a missing png (town_logic.gd checks they all exist)
			var pos := Vector2(float(e[1]), float(e[2]))
			level_live.append([tx, pos, up_lit.get(String(e[0]))])
			var used := tx.get_image().get_used_rect()
			level_occ.append({"tex": tx, "rect": Rect2(pos, tx.get_size()), "y": pos.y + used.end.y - 3.0, "tag": "level", "look": ""})
			if e.size() > 5:
				var c := Vector2i(int(e[4]), int(e[5]))
				if walk_base.has(c) and not keep.has(c):
					blocked.append(c)
	walk = blocked_walk(walk_base, blocked, inn_doors, walk_doors + walk_stops)
	walk_keys = walk.keys()
	live_stops = walk_stops.filter(func(c): return walk.has(c))
	level_occ.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	occ_state = ""

## The walk grid minus `blocked` cells, except any whose loss would cut a target off from the Inn.
static func blocked_walk(base: Dictionary, blocked: Array, starts: Array, targets: Array) -> Dictionary:
	var w := base.duplicate()
	for c in blocked:
		w.erase(c)
		if not starts.is_empty() and not _reaches(w, starts[0], targets.filter(func(t): return t != c)):
			w[c] = true
	return w

static func _reaches(w: Dictionary, start: Vector2i, targets: Array) -> bool:
	var seen := {start: true}
	var q: Array = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = c + dv
			if w.has(nb) and not seen.has(nb):
				seen[nb] = true
				q.append(nb)
	for t in targets:
		if w.has(t) and not seen.has(t):
			return false
	return true

func _season_tex(season: String) -> Texture2D:
	if not tex.has(season):
		var path := "res://art/town/town_%s.png" % season   # the old top-down town (its pictures are gone)
		tex[season] = load(path) if ResourceLoader.exists(path) else null
	return tex[season]

## The iso town's picture for this town's Church and Trophy Cabin (built or still a lot).
func _iso_tex() -> Texture2D:
	var church := "lot" if not Buildings.built("church") else ("ruin" if hardcore else "holy")
	var cabin := "built" if Buildings.built("cabin") else "lot"
	var path := String(data["art"]) % [church, cabin]
	if not tex.has(path):
		tex.clear()                    # one town picture in memory at a time (~6 MB each)
		tex[path] = load(path)
	return tex[path]

## Dusk and darker: lit windows, torches and lamps (the base picture is the day).
func _lit() -> bool:
	return float(look.get("dark", 0.0)) > 0.1

## The lit overlay for this town's Church / Trophy Cabin state: [texture, map position, second flame frame], or [].
func _lit_overlay() -> Array:
	if not data.has("art_lit"):
		return []
	var church := "lot" if not Buildings.built("church") else ("ruin" if hardcore else "holy")
	var cabin := "built" if Buildings.built("cabin") else "lot"
	var path := String(data["art_lit"]) % [church, cabin]
	if not tex.has(path):
		tex[path] = load(path) if ResourceLoader.exists(path) else null
	var path2 := path.replace("_lit.png", "_lit2.png")   # the second flame frame
	if not tex.has(path2):
		tex[path2] = load(path2) if ResourceLoader.exists(path2) else null
	var at: Array = data.get("lit_pos", {}).get("%s_%s" % [church, cabin], [0, 0])
	return [tex[path], Vector2(float(at[0]), float(at[1])), tex[path2]] if tex[path] else []

## The occluders for this town's state (built Church holy or ruined, Trophy Cabin), rebuilt only when it changes.
func _live_occluders() -> Array:
	var key := "%s:%s:%s:%s" % [Buildings.built("church"), hardcore, Buildings.built("cabin"), levels_key]
	if key != occ_state:
		occ_state = key
		occ_live = occluders.filter(func(o):
			var tag := String(o["tag"])
			if (tag == "church" or tag == "cabin") and not Buildings.built(tag):
				return false
			return tag != "church" or String(o["look"]) == "" or String(o["look"]) == ("ruin" if hardcore else "holy"))
		if not level_occ.is_empty():     # the level props in the street: walkers pass behind them too
			occ_live = occ_live + level_occ
			occ_live.sort_custom(func(a, b): return float(a["y"]) < float(b["y"]))
	return occ_live

## Regular or Hardcore town; call again after the Church or Trophy Cabin is built.
func set_mode(hc: bool) -> void:
	hardcore = hc
	if iso:
		# Hardcore: people stand at the ruined Church's door and look at it instead of going in
		var k := walk_door_ids.find("church")
		if k >= 0:
			var door: Vector2i = walk_doors[k]
			walk_stops = hardcore_stops(walk_stops, door, hc, Buildings.built("church"))
			stop_face.erase(door)
			if walk_stops.has(door):
				var r: Array = _spot("church").get("rect", [0, 0, 0, 0])
				stop_face[door] = float(r[0]) + float(r[2]) / 2.0
			live_stops = walk_stops.filter(func(c): return walk.has(c))
	if iso and map:
		map.texture = _iso_tex()
		lit_ov = _lit_overlay()

## The stops with the Church door as one only in Hardcore with the ruin built (nobody stares at a lot).
static func hardcore_stops(stops: Array, door: Vector2i, hc: bool, built: bool) -> Array:
	var out := stops.filter(func(c): return c != door)
	if hc and built:
		out.append(door)
	return out

func set_look(l: Dictionary) -> void:
	if l == look:
		return
	look = l
	plate_w.clear()
	map.texture = _iso_tex() if iso else _season_tex(String(l["season"]))
	if iso:
		lit_ov = _lit_overlay()
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
	# a whole number of device pixels per map pixel (the phone's canvas scale is 2.56 or 1.49,
	# so a plain 2x would land between device pixels and shimmer)
	var cs := _device_scale()
	scale_f = maxf(1.0, roundf(zoom * cs)) / cs
	var shown := ms * scale_f
	if not placed:                 # keep centring on the market until the player pans or zooms
		var m := _spot_rect("market")
		pan_v = size / 2.0 - (m.get_center() if m.size != Vector2.ZERO else ms / 2.0) * scale_f
	# the whole view stays over the town's diamond (walls included), never out in the wood
	var o: Array = data.get("origin", [ms.x / 2.0, 0])
	var n := float(data.get("grid", 40))
	var dc := Vector2(float(o[0]), float(o[1]) + n * 8.0)
	var half := Vector2(n * 16.0 + 24.0, n * 8.0 + 16.0)
	var c := (size / 2.0 - pan_v) / scale_f - dc
	pan_v = size / 2.0 - (dc + clamp_view(c, size / (2.0 * scale_f), half)) * scale_f
	var lo := size - shown
	pan_v.x = lo.x / 2.0 if lo.x > 0.0 else clampf(pan_v.x, lo.x, 0.0)
	pan_v.y = lo.y / 2.0 if lo.y > 0.0 else clampf(pan_v.y, lo.y, 0.0)
	# whole device pixels counted from the screen, not from this control (it sits at an odd y in the UI)
	var vp := get_viewport()
	var ft := vp.get_final_transform() if vp else Transform2D()
	origin = snap_origin(get_global_position(), pan_v, cs, ft.origin)
	map.position = origin
	map.size = shown
	if people:
		people.size = shown
	fx.size = size
	labels.size = size

## The view centre `c` (map px from the diamond's middle) pulled in so the view rect, half-size
## `hv`, stays inside the town's diamond of half-size `half`: at most 35% of a corner of the view
## may leave it. A view wider than the town falls back to the centre rule.
static func clamp_view(c: Vector2, hv: Vector2, half: Vector2) -> Vector2:
	var k := hv.x * 0.65 / half.x + hv.y * 0.65 / half.y
	var limit := maxf(0.0, 1.0 - k) if hv.x <= half.x else 0.92
	var reach := absf(c.x) / half.x + absf(c.y) / half.y
	if reach > limit:
		c *= limit / reach if reach > 0.0 else 0.0
	return c

## The map's top-left in local px such that it lands on a whole device pixel: `g` is this
## control's global position, `cs` device px per design px, `off` the window's own device offset.
static func snap_origin(g: Vector2, pan: Vector2, cs: float, off := Vector2.ZERO) -> Vector2:
	return (((g + pan) * cs + off).round() - off) / cs - g

## Device pixels per design pixel (the window's stretch), 1 when there's no viewport yet.
func _device_scale() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return maxf(0.01, vp.get_final_transform().get_scale().x)

func _spot_rect(id: String) -> Rect2:
	for s in data.get("spots", []):
		if String(s["id"]) == id:
			var r: Array = s["rect"]
			return Rect2(r[0], r[1], r[2], r[3])
	return Rect2()

## Iso: pinch or wheel between 2x and 3x, keeping the point under the fingers still.
## The pan that keeps map point `m` under screen point `at` at zoom `z`, using the scale the map
## is really drawn at (whole device pixels), not the nominal zoom.
static func zoom_pan(at: Vector2, m: Vector2, z: float, cs: float) -> Vector2:
	return at - m * (maxf(1.0, roundf(z * cs)) / cs)

func _zoom_to(z: float, at: Vector2) -> void:
	z = clampf(z, 2.0, 3.0)
	if z == zoom:
		return
	var m := to_map(at)
	placed = true
	zoom = z
	pan_v = zoom_pan(at, m, z, _device_scale())
	_layout()
	zoomed.emit(z)

func to_view(p: Vector2) -> Vector2:
	return origin + p * scale_f

## Is map point `m` on screen (so a sound there is heard)?
func in_view(m: Vector2) -> bool:
	return view_has(origin, scale_f, size, m)

static func view_has(o: Vector2, s: float, view: Vector2, m: Vector2) -> bool:
	return Rect2(Vector2.ZERO, view).has_point(o + m * s)

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
	if what == NOTIFICATION_TRANSFORM_CHANGED and iso:
		_layout()   # moved inside the UI (margins, the top bar): re-snap to whole device pixels
	if what == NOTIFICATION_MOUSE_EXIT and hover != "":
		hover = ""
		labels.queue_redraw()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		touches.clear()   # a finger lost to a system overlay must not leave every drag read as a pinch
		pinch_from = 0.0
		dragging = false
		press = ""

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	if not build_queue.is_empty() and Engine.get_process_frames() % 3 == 0:
		_build_next()   # one walker every third frame: the first second in town stays smooth
	_step_weather(delta)
	_step_folk(delta)
	people.queue_redraw()
	fx.queue_redraw()
	var key := [origin, scale_f, size, hover, press, badges.hash(), locked.hash(), notes.hash(), hidden_spots.hash(),
		level_flash.size(), level_flash.values().filter(func(v): return t < float(v[1])).size()]
	if key != label_key:
		label_key = key
		labels.queue_redraw()

# =====================================================================
# Townsfolk
# =====================================================================

## The townsfolk are queued, not built: each walker's art is made from the hero sheets pixel by
## pixel, so they're built one per frame once the town is on screen (no hitch at launch).
func _make_folk() -> void:
	var races := TownFolk.PEOPLE.map(func(p): return String(p[0]["race"]))
	cast_day = int(floor(Time.get_unix_time_from_system() / 86400.0))
	for i in cast(MAX_FOLK, TownFolk.PEOPLE.size(), float(cast_day), races):
		build_queue.append({"i": i})

## Today's townsfolk: `n` of the `count` PEOPLE, picked by the day (the same cast all day, another
## tomorrow), no race twice among any three in a row so the street stays mixed.
static func cast(n: int, count: int, day: float, races: Array) -> Array:
	var order: Array = range(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(floorf(day)) * 7 + 1
	for k in range(count - 1, 0, -1):   # Fisher-Yates with the day's seed
		var j := rng.randi_range(0, k)
		var tmp = order[k]
		order[k] = order[j]
		order[j] = tmp
	var out: Array = []
	var later: Array = []
	for i in order:
		var r := String(races[i]) if i < races.size() else ""
		if out.slice(-2).any(func(o): return String(races[o]) == r):
			later.append(i)   # the same race as one of the last two: further down the list
		else:
			out.append(i)
	return (out + later).slice(0, mini(n, count))

## Builds the next queued walker (one every third frame, from _process).
func _build_next() -> void:
	var q: Dictionary = build_queue.pop_front()
	var hero := q.has("hero")
	var w := TownFolk.hero(q["hero"][0], q["hero"][1]) if hero else TownFolk.townsfolk(int(q["i"]))
	if (w["s"] as Array).is_empty():
		return
	var lane: Array = LANES[(int(q["i"]) + (1 if hero else 0)) % LANES.size()]
	var f := {"frames": w["s"], "walk": w["walk"], "foot": float(w.get("foot", TownFolk.FOOT)), "head": float(w.get("head", 0.0)), "x": randf_range(lane[1], lane[2]), "y": float(lane[0]), "lane": lane, "to": -1.0,
		"wait": randf_range(0.5, 4.0 if not hero else 3.0), "flip": randf() < 0.5, "t": randf() * 3.0, "walked": 0.0}
	if hero:
		f["y"] += randf_range(-6.0, 6.0)
		f["hero"] = true
		f["you"] = bool(q["hero"][2])
	folk.append(f)
	if iso:
		_place_on_grid(f)

## Your own heroes stroll the square too: [[appearance, looks, is_you], ...].
## Rebuilt only when `key` changes (a new hero, new gear).
var heroes_key := ""
func set_heroes(list: Array, key: String) -> void:
	if cast_day >= 0 and int(floor(Time.get_unix_time_from_system() / 86400.0)) != cast_day:
		folk = folk.filter(func(f): return f.get("hero", false))   # a new day: a new cast (the app may never relaunch)
		build_queue = build_queue.filter(func(q): return q.has("hero"))
		_make_folk()
	if key == heroes_key:
		return
	heroes_key = key
	folk = folk.filter(func(f): return not f.get("hero", false))
	build_queue = build_queue.filter(func(q): return not q.has("hero"))
	var mine: Array = []
	for i in mini(list.size(), MAX_WALKERS - mini(MAX_FOLK, TownFolk.PEOPLE.size())):   # you first, then the roster
		mine.append({"i": i, "hero": list[i]})
	build_queue = mine + build_queue   # your heroes are built before the townsfolk

# Iso townsfolk: stand at a door, then walk the street grid to another door.
func _cell_px(c: Vector2i) -> Vector2:
	var o: Array = data["origin"]
	var z: float = raised.get(c, 0.0)
	return Vector2(float(o[0]) + (c.x - c.y) * 16.0, float(o[1]) + (c.x + c.y + 1) * 8.0 - z)

## A new walker is already about town: on a stall, the well, a board or a street cell (a few come out
## of the Inn), and fades in over the first two seconds instead of everyone popping out of one door.
func _place_on_grid(f: Dictionary) -> void:
	var starts := inn_doors if not inn_doors.is_empty() else walk_doors   # people come out of the Inn
	var c: Vector2i = starts[randi() % starts.size()] if not starts.is_empty() else Vector2i(17, 20)
	var r := randf()
	if r < 0.45 and not live_stops.is_empty():
		c = live_stops[randi() % live_stops.size()]
	elif r < 0.8 and not walk_keys.is_empty():
		c = walk_keys[randi() % walk_keys.size()]
	var p := _cell_px(c)
	f["x"] = p.x
	f["y"] = p.y
	f["cell"] = c
	f["path"] = []
	f["fade"] = 1.0
	f["inside"] = randf_range(0.2, 2.5)
	f["arriving"] = true   # not "went inside": no "you" marker over an empty cell while fading in
	if stop_face.has(c):
		f["flip"] = float(stop_face[c]) < p.x

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
	if r < 0.25 and not inn_doors.is_empty():
		goal = inn_doors[randi() % inn_doors.size()]
		f["goal_door"] = true
	elif r < 0.5 and not walk_doors.is_empty():
		var k := randi() % walk_doors.size()
		var id: String = walk_door_ids[k]
		if not enterable(id, hardcore, Buildings.built(id), hidden_spots.has(id)):
			f["wait"] = 0.5   # nobody goes into an empty lot; think again in a moment
			return
		goal = walk_doors[k]
		f["goal_door"] = true
	elif r < 0.85 and not live_stops.is_empty():
		goal = live_stops[randi() % live_stops.size()]
	else:
		goal = walk_keys[randi() % walk_keys.size()]
	f["path"] = _grid_path(f["cell"], goal)
	if (f["path"] as Array).is_empty():
		f["wait"] = 1.0

## Can townsfolk go in at this door? Not an empty lot, a building not in town yet, nor in Hardcore
## the ruined Church (no roof to go under) or the Vault (locked).
static func enterable(id: String, hc: bool, built: bool, hidden: bool) -> bool:
	if hidden or ((id == "church" or id == "cabin") and not built):
		return false
	return not (hc and id in ["church", "stash"])

func _arrive(f: Dictionary) -> void:
	if f.get("goal_door", false) and not f.get("hero", false) or (f.get("goal_door", false) and randf() < 0.5):
		f["inside"] = randf_range(2.0, 5.0)   # went in: fades out at the door, comes back out later
		f["fade"] = 0.0
		var k := walk_doors.find(f.get("cell"))
		door_used.emit(walk_door_ids[k] if k >= 0 else "inn", Vector2(float(f["x"]), float(f["y"])))
	elif stop_face.has(f.get("cell")):        # at a stall, the well or a board: turn to face it
		f["flip"] = float(stop_face[f["cell"]]) < float(f["x"])
	f["wait"] = randf_range(1.5, 4.0)
	f["goal_door"] = false

## Two people meeting on the street stop for a chat ("..." over both). Heroes join in; your own
## hero only half the time, so you keep moving.
func _try_chat(f: Dictionary) -> bool:
	if f.get("you", false) and randf() < 0.5 or float(f.get("fade", 0.0)) > 0.0:
		return false
	for o in folk:
		if o == f or float(o.get("inside", 0.0)) > 0.0 or float(o.get("fade", 0.0)) > 0.0 or float(o.get("chat", 0.0)) > 0.0 or (o.get("you", false) and randf() < 0.5):
			continue
		if chat_ok(f, o, _cell_px(o["cell"]) if o.has("cell") else Vector2(INF, INF)):
			var t := randf_range(2.5, 5.0)
			f["wait"] = t
			o["wait"] = maxf(float(o["wait"]), t)
			f["chat"] = t
			o["chat"] = t
			f["flip"] = float(o["x"]) < float(f["x"])
			o["flip"] = not f["flip"]
			chatted.emit(Vector2(float(f["x"]), float(f["y"])))
			return true
	return false

## The chat rule: the partner stands still, or walks but is right on a cell (`o_cell` is its cell's
## pixel; nobody stops between cells), and is within 22 px. Nobody fading in or out (a ghost at a door).
static func chat_ok(f: Dictionary, o: Dictionary, o_cell: Vector2) -> bool:
	if float(o.get("fade", 0.0)) > 0.0 or float(f.get("fade", 0.0)) > 0.0:
		return false
	var op := Vector2(float(o["x"]), float(o["y"]))
	if float(o["wait"]) <= 0.0 and op.distance_to(o_cell) >= 0.5:
		return false
	return op.distance_to(Vector2(float(f["x"]), float(f["y"]))) < 22.0

func _step_iso_walker(f: Dictionary, delta: float) -> void:
	if float(f.get("inside", 0.0)) > 0.0:
		f["inside"] = float(f["inside"]) - delta
		f["fade"] = minf(1.0, float(f.get("fade", 0.0)) + delta * 3.0)
		if float(f["inside"]) <= 0.0:
			f.erase("arriving")
		return
	if float(f.get("fade", 0.0)) > 0.0:
		f["fade"] = maxf(0.0, float(f["fade"]) - delta * 3.0)
	if float(f.get("chat", 0.0)) > 0.0:
		f["chat"] = float(f["chat"]) - delta
	if float(f["wait"]) > 0.0:
		f["wait"] = float(f["wait"]) - delta
		if float(f["wait"]) <= 0.0:
			_pick_goal(f)
		return
	var path: Array = f["path"]
	if path.is_empty():
		_arrive(f)
		return
	var to := _cell_px(path[0])
	var at := Vector2(float(f["x"]), float(f["y"]))
	var stp := WALK_SPEED * delta
	if absf(to.x - at.x) > 0.5:
		f["flip"] = to.x < at.x
	var d := at.distance_to(to)
	if d <= stp:
		f["x"] = to.x
		f["y"] = to.y
		f["cell"] = path.pop_front()
		f["walked"] = float(f.get("walked", 0.0)) + d
		if not path.is_empty() and randf() < 0.06:
			_try_chat(f)   # only ever on a cell, so the walk on afterwards follows the grid
	else:
		var n := at + (to - at).normalized() * stp
		f["x"] = n.x
		f["y"] = n.y
		f["walked"] = float(f.get("walked", 0.0)) + stp

func _step_folk(delta: float) -> void:
	for p in pen_pets:
		p["t"] = float(p["t"]) + delta
		if float(p["wait"]) > 0.0:
			p["wait"] = float(p["wait"]) - delta
			if float(p["wait"]) <= 0.0:
				p["to"] = _pen_spot()
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
			f["walked"] = float(f.get("walked", 0.0)) + step

func _draw_people() -> void:
	people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
	if iso:
		if _lit() and not lit_ov.is_empty():   # two flame frames, flipped at jittered times (never a metronome)
			if t >= next_flip:
				lit_frame = 1 - lit_frame
				next_flip = t + randf_range(0.10, 0.34)
			people.draw_texture(lit_ov[2] if lit_ov[2] != null and lit_frame == 1 else lit_ov[0], lit_ov[1])
		_draw_river()
		_draw_levels()
		_draw_chimney()
	else:
		_draw_placeholders()
	var live := _live_occluders() if iso else []   # once a frame, not once per walker or pet
	if not hidden_spots.has("clinic"):
		_draw_pen(live)
	# insertion sort in place: the order barely changes between frames
	for a in range(1, folk.size()):
		var f0: Dictionary = folk[a]
		var b := a - 1
		while b >= 0 and float(folk[b]["y"]) > float(f0["y"]):
			folk[b + 1] = folk[b]
			b -= 1
		folk[b + 1] = f0
	for f in folk:
		if iso and float(f.get("fade", 0.0)) >= 1.0:
			if door_marker(f):   # you went inside: your marker stays over the door, faded
				var dp := _cell_px(f.get("cell", Vector2i.ZERO))
				people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
				var hy := roundf(dp.y) - float(f.get("foot", TownFolk.FOOT)) + float(f.get("head", 0.0)) - 7.0
				people.draw_texture(marker_tex["you"], Vector2(roundf(dp.x) - 4.0, hy), Color(1, 1, 1, 0.5))
			continue
		# walking: idle, left step, idle, right step, one frame per STEP_PX walked (the feet stay
		# planted); standing breathes slowly on the two idle frames
		var walking := float(f["wait"]) <= 0.0 and float(f.get("inside", 0.0)) <= 0.0
		var fi := int(float(f.get("walked", 0.0)) / STEP_PX) % 4 if walking else int(float(f["t"]) * 1.5) % 2
		var frames: Array = f["walk"] if walking else f["frames"]
		var tx: Texture2D = frames[fi % frames.size()]
		var w := float(tx.get_width())
		var fx0 := roundf(float(f["x"]))
		var fy0 := roundf(float(f["y"]))
		var pos := Vector2(roundf(float(f["x"]) - w / 2.0), fy0 - float(f.get("foot", TownFolk.FOOT)))
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		if walking and fi % 2 == 1:
			people.draw_texture(shadow_step, Vector2(fx0 - 5.0, fy0 - 2.0))
		else:
			people.draw_texture(shadow_tex, Vector2(fx0 - 6.0, fy0 - 2.0))
		if f["flip"]:
			people.draw_set_transform(Vector2((pos.x * 2.0 + w) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture(tx, pos, Color(1, 1, 1, 1.0 - float(f.get("fade", 0.0))))
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		var head := pos.y + float(f.get("head", 0.0)) - 8.0   # just over the sprite's own head
		var over := Rect2(fx0 - 4.0, head + 1.0, 9.0, 7.0)   # a hero's marker or a chat bubble
		if float(f.get("chat", 0.0)) > 0.0:
			people.draw_texture(bubble_tex, Vector2(fx0 - 4.0 + (-3.0 if f["flip"] else 3.0), head))
			over = over.merge(Rect2(fx0 - 7.0, head, 15.0, 6.0))
		elif f.get("hero", false):
			# a pixel chevron over your heroes (gold over the one you're playing), under the cover
			people.draw_texture(marker_tex["you" if f.get("you", false) else "hero"], over.position)
		if iso:
			var cov := Rect2(pos, Vector2(w, w)).merge(over)
			# on the hope path the walker stands in front of the dungeon: sort by the ground under them
			var up: float = raised.get(f.get("cell", Vector2i(-1, -1)), 0.0)
			_cover(cov, float(f["y"]) + up, live, "gate" if up > 0.0 else "")
	people.draw_set_transform(Vector2.ZERO)

## Your faded marker over a door: you went inside (not a walker still arriving about town).
static func door_marker(f: Dictionary) -> bool:
	return f.get("you", false) and float(f.get("fade", 0.0)) >= 1.0 and not f.get("arriving", false)

## Iso: redraw whatever stands in front of a walker (sorts lower on screen) and overlaps it,
## so people pass behind buildings, walls and trees instead of over their roofs.
func _cover(r: Rect2, foot_y: float, live: Array, skip := "") -> void:
	# sorted back to front: find the first one in front of the walker, then draw those back to front
	var first := live.size()
	while first > 0 and float(live[first - 1]["y"]) > foot_y:
		first -= 1
	var lit := _lit()
	for k in range(first, live.size()):
		var o: Dictionary = live[k]
		var orect: Rect2 = o["rect"]
		if orect.intersects(r) and String(o["tag"]) != skip:
			people.draw_texture(o["lit"] if lit and o.get("lit") else o["tex"], orect.position)

## Iso: each building's level props (L1 scaffolding + piles, L2 lantern + upgrade, L3 banners + showpiece).
## Made by refresh_levels (only when a level changes).
func _draw_levels() -> void:
	var lit := _lit()
	for e in level_live:   # a lantern's panes light up at dusk; by day it is glass
		people.draw_texture(e[2] if lit and e[2] != null else e[0], e[1])

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
func _draw_pen(live: Array) -> void:
	if iso:
		_draw_pen_pets(32.0, live)   # the iso town has its own fence and kennel; pets 1:1 (pets dev: never downscaled)
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
	_draw_pen_pets(34.0, live)

## Your pets in the pen, `px` tall: their 32 px Pets 2 art 1:1 (a baby animal beside a ~28 px walker).
func _draw_pen_pets(px: float, live: Array) -> void:
	for a in range(1, pen_pets.size()):   # insertion sort in place, like the folk
		var p0: Dictionary = pen_pets[a]
		var b := a - 1
		while b >= 0 and float(pen_pets[b]["y"]) > float(p0["y"]):
			pen_pets[b + 1] = pen_pets[b]
			b -= 1
		pen_pets[b + 1] = p0
	for p in pen_pets:
		var tx := _pet_tex(p["tex"], px)
		var sz := Vector2(tx.get_size())
		var hop := roundf(absf(sin(float(p["t"]) * 6.0)) * 2.0) if float(p["wait"]) <= 0.0 else 0.0
		var x := roundf(float(p["x"]))
		var y := roundf(float(p["y"]))
		var pos := Vector2(roundf(x - sz.x / 2.0), y - sz.y - hop)
		people.draw_texture(shadow_pet, Vector2(x - 8.0, y - 2.0))
		if p["flip"]:
			people.draw_set_transform(Vector2((pos.x * 2.0 + sz.x) * scale_f, 0), 0.0, Vector2(-scale_f, scale_f))
		people.draw_texture(tx, pos)
		people.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_f, scale_f))
		if iso:
			_cover(Rect2(pos, sz), float(p["y"]), live)   # pets hide behind the wall and the kennel too

## A pet's art drawn 1:1. Only art far bigger than `px` is halved, once, with TownFolk.half
## (outline kept) - never sampled at a fraction every frame.
func _pet_tex(tx: Texture2D, px: float) -> Texture2D:
	if maxf(tx.get_width(), tx.get_height()) <= px * 1.5:
		return tx
	var k := tx.get_rid()
	if not pet_half.has(k):
		var im := tx.get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		pet_half[k] = ImageTexture.create_from_image(TownFolk.half(im))
	return pet_half[k]

# =====================================================================
# Glow and weather
# =====================================================================

## Weather particles kept alive per kind.
const WANT := {"rain": 70, "ash": 45, "embers": 34, "leaves": 18, "fog": 7, "smoke": 10, "wisps": 9, "sparkles": 26, "motes": 22}

func _step_weather(delta: float) -> void:
	var kind := String(look.get("weather", ""))
	var ms := map_size()
	var want: int = WANT.get(kind, 0)
	while parts.size() < want:
		parts.append(_new_part(kind, ms, parts.size() < want / 2 and t < 0.5))
	for p in parts:
		p["pos"] += (p["vel"] as Vector2) * delta
		p["age"] = float(p["age"]) + delta
	for k in range(parts.size() - 1, -1, -1):   # drop the dead in place (no new array a frame)
		var p: Dictionary = parts[k]
		var pos: Vector2 = p["pos"]
		if float(p["age"]) >= float(p["life"]) or pos.x < -80 or pos.x > ms.x + 80 or pos.y < -80 or pos.y > ms.y + 80:
			parts.remove_at(k)
	# the forge burns by day too: its chimney smokes in every look (the dwarf zone adds its own)
	var want_ch := 4 if iso and data.has("smoke") and kind != "smoke" else 0
	while chimney.size() < want_ch:
		chimney.append(_new_part("smoke", ms, false))
	for k in range(flash_parts.size() - 1, -1, -1):
		var fp: Dictionary = flash_parts[k]
		fp["pos"] += (fp["vel"] as Vector2) * delta
		fp["age"] = float(fp["age"]) + delta
		if float(fp["age"]) >= float(fp["life"]):
			flash_parts.remove_at(k)
	for k in range(chimney.size() - 1, -1, -1):
		var p: Dictionary = chimney[k]
		p["pos"] += (p["vel"] as Vector2) * delta
		p["age"] = float(p["age"]) + delta
		if float(p["age"]) >= float(p["life"]) or k >= want_ch:
			chimney.remove_at(k)

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

## The forge chimney's smoke in map px, normal blending under the night grade (round 5: drawn
## additively it vanished on a sunlit roof).
func _draw_chimney() -> void:
	for p in chimney:
		var a := clampf(minf(float(p["age"]), float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var g := floorf(2.0 + float(p["age"]) * 1.5) * 2.0
		people.draw_rect(Rect2((p["pos"] as Vector2).round() - Vector2(g, g) / 2.0, Vector2(g, g)), Color(0.42, 0.40, 0.44, 0.35 * a))

## A puff of smoke at view point `v`, growing as it rises.
func _draw_smoke(p: Dictionary, v: Vector2, a: float) -> void:
	var grow := floorf(2.0 + float(p["age"]) * 1.5) * 2.0
	fx.draw_rect(Rect2(v - Vector2(grow, grow) * scale_f / 2.0, Vector2(grow, grow) * scale_f), Color(0.35, 0.33, 0.34, 0.12 * a))

## The lamps' glow at darkness `dark`: already plain at a rainy 0.3 (when every window is lit), 0.5 at night.
static func glow_alpha(dark: float) -> float:
	return 0.2 + 0.3 * smoothstep(0.1, 0.5, dark)

func _draw_fx() -> void:
	var dark := float(look.get("dark", 0.0))
	# lamp light, stronger the darker it is, with a gentle flicker
	if dark > 0.1:
		var view := Rect2(Vector2.ZERO, size)
		var lights: Array = data.get("lights", [])
		for i in lights.size():
			var l: Array = lights[i]
			var c := to_view(Vector2(l[0], l[1]))
			var rad := (float(l[3]) if l.size() > 3 else 46.0) * scale_f
			if not view.grow(rad).has_point(c):
				continue
			var col := Color(1.0, 0.72, 0.36)
			if l.size() > 2 and l[2] is Array:
				col = Color(float(l[2][0]) / 255.0, float(l[2][1]) / 255.0, float(l[2][2]) / 255.0)
			var fl := 0.9 + 0.1 * sin(t * 7.0 + float(l[0]))
			var share := sqrt(float(light_n[i])) if i < light_n.size() else 1.0
			fx.draw_texture_rect(light_tex, Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), false, Color(col.lightened(0.1), glow_alpha(dark) * fl / share))
	var kind := String(look.get("weather", ""))
	var vr := Rect2(Vector2.ZERO, size).grow(80.0 * scale_f)
	for p in flash_parts:    # sparkles over a building that just went up a level
		var fa := clampf(minf(float(p["age"]) * 4.0, float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var tw0 := maxf(0.0, sin(t * 9.0 + float(p["seed"]) * 3.0))
		fx.draw_rect(Rect2(to_view((p["pos"] as Vector2).round()), Vector2(2, 2) * scale_f), Color(1.0, 0.85, 0.45, 0.9 * fa * tw0))
	for p in parts:
		var a := clampf(minf(float(p["age"]), float(p["life"]) - float(p["age"])), 0.0, 1.0)
		var v := to_view((p["pos"] as Vector2).round())
		if not vr.has_point(v):
			continue
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
				# low hard-edged banks, like the composed town's fog
				fx.draw_rect(Rect2(v + Vector2(-60, -4) * s, Vector2(120, 8) * s), Color(0.55, 0.6, 0.62, 0.035 * a))
				fx.draw_rect(Rect2(v + Vector2(-36, -8) * s, Vector2(72, 4) * s), Color(0.55, 0.6, 0.62, 0.03 * a))
			"smoke":
				_draw_smoke(p, v, a)
			"wisps":
				var bob := Vector2(roundf(sin(t + float(p["seed"])) * 6.0), roundf(cos(t * 0.8 + float(p["seed"])) * 4.0)) * s
				fx.draw_rect(Rect2(v + bob - Vector2(2, 2) * s, Vector2(4, 4) * s), Color(0.4, 0.6, 1.0, 0.18 * a))
				fx.draw_rect(Rect2(v + bob - Vector2(1, 1) * s, Vector2(2, 2) * s), Color(0.7, 0.85, 1.0, 0.6 * a))
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
	var fs := _font_size()
	var w := _plate_w(_label(s), fs)
	var anchor := to_view(plate_anchor(s))
	if s.has("lot_plate") and not Buildings.built(String(s["id"])):
		anchor = to_view(Vector2(float(s["lot_plate"][0]), float(s["lot_plate"][1])))
	var h := fs + 10.0
	var bvr := Rect2(to_view(Vector2(float(r[0]), float(r[1]))), Vector2(float(r[2]), float(r[3])) * scale_f)
	return clamp_plate(Rect2(anchor.x - w / 2.0, anchor.y - h / 2.0, w, h), size, bvr)

## A plate pulled into the view, or an empty rect (hidden) when pulling it in would leave its own
## building: a clamped plate must never sit over another building's tap.
static func clamp_plate(rect: Rect2, view: Vector2, building: Rect2) -> Rect2:
	var at := rect.position
	rect.position.x = clampf(rect.position.x, 4.0, view.x - rect.size.x - 4.0)
	rect.position.y = clampf(rect.position.y, 4.0, view.y - rect.size.y - 4.0)
	return rect if rect.position == at or rect.intersects(building.grow(8.0)) else Rect2()

## A plate's text: an unbuilt Church or Trophy Cabin reads "Church · lot" (it's a plot to build on).
func _label(s: Dictionary) -> String:
	return String(s["label"]) + (" · lot" if s.has("lot_plate") and not Buildings.built(String(s["id"])) else "")

## A label's plate width at font size `fs`, measured once (the font is the same until the look changes).
func _plate_w(label: String, fs: int) -> float:
	var k := "%s|%d" % [label, fs]
	if not plate_w.has(k):
		plate_w[k] = get_theme_default_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
	return plate_w[k]

## Where a spot's name plate sits, in map pixels: town.json "plate" if it has one (the Market's
## sits by the well, the Dungeon's above the portal), else near the top of its tap area.
static func plate_anchor(s: Dictionary) -> Vector2:
	if s.get("plate") is Array:
		return Vector2(float(s["plate"][0]), float(s["plate"][1]))
	var r: Array = s["rect"]
	return Vector2(float(r[0]) + float(r[2]) / 2.0, float(r[1]) + 10.0)

## Iso: the town is bigger than the screen, so only buildings in view get a name plate
## (otherwise off-screen plates would pile up along the edges).
func _plate_shown(s: Dictionary) -> bool:
	if not iso:
		return true
	if (s.has("plate") and s["plate"] == null) or size.x < 16.0 or size.y < 16.0:
		return false   # no plate (the Mailbox: its badge is on the Mail button), or not laid out yet
	# at least 30% of the building on screen, so a plate never hangs over the dark at the edge
	var r: Array = s["rect"]
	var vr := Rect2(to_view(Vector2(float(r[0]), float(r[1]))), Vector2(float(r[2]), float(r[3])) * scale_f)
	var inside := vr.intersection(Rect2(Vector2.ZERO, size))
	return vr.get_area() > 0.0 and inside.get_area() >= 0.3 * vr.get_area() and _plate_rect(s).has_area()

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
		labels.draw_style_box(plate_sb["hot" if hot else ("normal" if why == "" else "locked")], rect)
		var lot: bool = s.has("lot_plate") and not Buildings.built(id)
		var col := Color("#f6d88f") if why == "" and not lot else Color("#8b90a0")
		if id == "gate":
			col = Color("#fca5a5")
		var text := _label(s)
		labels.draw_string_outline(font, rect.position + Vector2(9, rect.size.y / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.04, 0.03, 0.06, 0.95))
		labels.draw_string(font, rect.position + Vector2(9, rect.size.y / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		var n := int(badges.get(id, 0))
		if n > 0 and why == "":
			var c := rect.position + Vector2(rect.size.x - 2, 2)
			labels.draw_circle(c, 12, Color(0.04, 0.03, 0.06))
			labels.draw_circle(c, 11, Color("#dc2626"))
			labels.draw_string(font, c + Vector2(-20, 6), str(n), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)
		var flash: Array = level_flash.get(id, [])
		if not flash.is_empty() and t >= float(flash[1]):
			level_flash.erase(id)
			flash = []
		if (hot and notes.has(id)) or not flash.is_empty():
			var note := String(flash[0]) if not flash.is_empty() else (String(notes[id]) if why == "" else why)
			var nw := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 14.0
			var nr := Rect2(rect.get_center().x - nw / 2.0, rect.end.y + 3, nw, 26)
			nr.position.x = clampf(nr.position.x, 4.0, size.x - nw - 4.0)
			labels.draw_style_box(plate_sb["note"], nr)
			labels.draw_string(font, nr.position + Vector2(7, 19), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6d3c4"))
