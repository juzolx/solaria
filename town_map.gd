class_name TownMap
extends Control
## Town map overlay (approved mockup 10; Juzo via town dev 2: the iso town is "a little
## crowded", so a map to find buildings fast). A flat isometric diamond in the same
## orientation as the town (ground zones, wall band, towers, houses, buildings as small
## roof-coloured blocks, empty lots as gold outlines) with a pin on every place, and a
## list of big rows under it. Tapping a pin or a row opens that place. All from
## art/town/town.json; colours from art/palette.gpl; drawn on the 2x pixel grid.

signal picked(id: String)

const CW := 10    # one grid cell across (design px)
const CH := 5     # and down: a flat 2:1 diamond
const GROUND := {"grass": "#265c42", "plateau": "#3a4466", "grave": "#1f1d24", "yard": "#3e8948", "road": "#5a6988",
	"path": "#5a6988", "square": "#8b9bb4", "water": "#3c5e8b", "bridge": "#a3825f", "field": "#5a3f35", "pen": "#75a743"}
const ROOF := "#8f563b"
const ROOF_GATE := "#feae34"   # the dungeon: the lit focal point
const HOUSE := "#5a3f35"
const WALL := "#4a4852"
const TOWER := "#625f6a"
const OUT := Color("#0e0812")
## Small pixel glyphs (palette letters as on the nav icons), one per place.
const PINS := {
	"gate": [".ooooo.", "oyGGGyo", "oG...Go", "oG.o.Go", "oG.o.Go", "ooooooo"],
	"guild": ["ooooooo", "orrrrRo", "orGGrRo", "orrrrRo", ".orrRo.", "..oRo..", "...o..."],
	"inn": ["..ooo..", ".oGGGo.", "oGgggGo", "oGgggGo", ".oGGGo.", "..ooo.."],
	"tavern": ["ooooo..", "owwwoo.", "oGGGooo", "oGGGo.o", "oGGGooo", "ooooo.."],
	"church": ["...o...", "..oGo..", ".ooGoo.", ".oGGGo.", "..oGo..", "..oGo..", "..ooo.."],
	"shop": ["..ooo..", ".oLLLo.", "oLgLLLo", "oLLgLLo", "oLLLLLo", ".ooooo."],
	"smith": ["ooooooo", "obbbbdo", ".ooodo.", "..ods..", ".oddso.", "ooooooo"],
	"stash": ["ooooooo", "oLLLLLo", "oGGgGGo", "oLLLLLo", "ooooooo"],
	"cabin": ["o.o.o.o", "oyoyoyo", ".oyyyo.", "..oyo..", ".oyyyo.", "ooooooo"],
	"clinic": [".oo.oo.", "orrorro", "orrrrRo", ".orrRo.", "..oRo..", "...o..."],
	"market": ["ooooooo", "orwrwro", "ooooooo", "oL...Lo", "oL...Lo", "ooooooo"],
	"bounty": ["ooooooo", "owwwwwo", "owssswo", "owwwwwo", "ooooooo", "..oLo..", "..oLo.."],
	"mail": ["ooooooo", "owwwwwo", "oowwwoo", "owowowo", "ooooooo"],
	"obelisk": ["..o..", ".oco.", ".oco.", ".oCo.", ".oCo.", "ooooo"],
}
const INK := {"o": "#0e0812", "r": "#e43b44", "R": "#a22633", "w": "#f4e6c4", "g": "#feae34", "G": "#c8a060", "y": "#9a7040",
	"L": "#733e39", "s": "#8b9bb4", "d": "#5a6988", "b": "#c0cbdc", "c": "#73bed3", "C": "#4f8fba"}

var data: Dictionary = {}
var hidden_ids := {}   # spot id -> true while it isn't in town yet (as TownView.hidden_spots)
var locked := {}       # spot id -> why it's closed
var selected := ""
var _pins := {}        # id -> Rect2 of its pin (for taps)
var _icons := {}

static func icon(id: String) -> ImageTexture:
	var rows: Array = PINS.get(id, PINS["obelisk"])
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if INK.has(row[x]):
				img.set_pixel(x, y, Color(INK[row[x]]))
	img.resize(w * UiSkin.PX, rows.size() * UiSkin.PX, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func _ready() -> void:
	var j := load("res://art/town/town.json") as JSON
	if j:
		data = j.data
	var n := int(data.get("grid", 40))
	custom_minimum_size = Vector2(n * CW + 8, n * CH + 40)
	mouse_filter = Control.MOUSE_FILTER_STOP

## Grid cell (i, j) -> map pixel (top corner of the cell).
func _iso(i: float, j: float) -> Vector2:
	var o := Vector2(size.x / 2.0, 30.0)   # the top corner of the diamond (room above for the pins)
	return o + Vector2((i - j) * CW / 2.0, (i + j) * CH / 2.0)

func _quad(x0: float, y0: float, x1: float, y1: float, lift := 0.0) -> PackedVector2Array:
	var up := Vector2(0, -lift)
	return PackedVector2Array([_iso(x0, y0) + up, _iso(x1 + 1, y0) + up, _iso(x1 + 1, y1 + 1) + up, _iso(x0, y1 + 1) + up])

func _block(r: Array, h: float, roof: Color) -> PackedVector2Array:
	var base := _quad(r[0], r[1], r[2], r[3])
	var top := _quad(r[0], r[1], r[2], r[3], h)
	draw_colored_polygon(PackedVector2Array([base[1], base[2], top[2], top[1]]), roof.darkened(0.38))
	draw_colored_polygon(PackedVector2Array([base[2], base[3], top[3], top[2]]), roof.darkened(0.55))
	draw_colored_polygon(top, roof)
	for poly in [top, PackedVector2Array([base[1], base[2], base[3]])]:
		var pts: PackedVector2Array = poly
		draw_polyline(pts + PackedVector2Array([pts[0]]), OUT, 1.0)
	return top

func _draw() -> void:
	if data.is_empty():
		return
	var n := int(data.get("grid", 40))
	for g in data.get("ground", []):
		draw_colored_polygon(_quad(g[1], g[2], g[3], g[4]), Color(GROUND.get(String(g[0]), "#265c42")))
	# the wall ring, towers and the sealed gatehouse
	for i in n:
		for c in [[i, 0], [i, n - 1], [0, i], [n - 1, i]]:
			draw_colored_polygon(_quad(c[0], c[1], c[0], c[1]), Color(WALL))
	var walls: Dictionary = data.get("walls", {})
	for t in walls.get("towers", []):
		_block(t, 7.0, Color(TOWER))
	if walls.has("gatehouse"):
		_block(walls["gatehouse"], 6.0, Color(TOWER))
	for h in data.get("houses", []):
		_block(h, 4.0, Color(HOUSE))
	# buildings back to front; empty lots as a gold outline on the ground
	var spots: Array = data.get("spots", []).duplicate()
	spots.sort_custom(func(a, b): return int(a["cells"][0]) + int(a["cells"][1]) < int(b["cells"][0]) + int(b["cells"][1]))
	var tops := {}
	for sp in spots:
		var id := String(sp["id"])
		var c: Array = sp["cells"]
		var kind := String(sp.get("kind", "building"))
		if hidden_ids.has(id) or kind == "point" or kind == "market":
			continue
		if kind == "lot" and not Buildings.built(id):
			var q := _quad(c[0], c[1], c[2], c[3])
			draw_colored_polygon(q, Color("#262b44"))
			draw_polyline(q + PackedVector2Array([q[0]]), Color("#c8a060"), 1.0)
			tops[id] = q
		else:
			var h := 7.0 if id == "gate" else 5.0
			tops[id] = _block(c, h, Color(ROOF_GATE if id == "gate" else ROOF))
	# pins
	_pins.clear()
	var places: Array = []
	for sp in data.get("spots", []):
		if not hidden_ids.has(String(sp["id"])):
			places.append([String(sp["id"]), sp["cells"]])
	for lm in data.get("landmarks", []):
		places.append([String(lm["id"]), lm["cells"]])
	for pl in places:
		var id: String = pl[0]
		var c: Array = pl[1]
		var at: Vector2
		if tops.has(id):
			var q: PackedVector2Array = tops[id]
			at = Vector2((q[0].x + q[2].x) / 2.0, minf(q[0].y, q[1].y) - 2.0)
		else:
			at = _iso((float(c[0]) + float(c[2]) + 1.0) / 2.0, (float(c[1]) + float(c[3]) + 1.0) / 2.0) - Vector2(0, 2)
		if not _icons.has(id):
			_icons[id] = icon(id)
		var ic: ImageTexture = _icons[id]
		var box := Rect2(roundf(at.x - ic.get_width() / 2.0) - 4, roundf(at.y - ic.get_height()) - 8, ic.get_width() + 8, ic.get_height() + 8)
		draw_rect(box, OUT)
		draw_rect(box.grow(-2), Color("#262b44") if not locked.get(id, "") else Color("#181425"))
		draw_texture(ic, box.position + Vector2(4, 4))
		if id == selected:
			draw_rect(box.grow(1), Color("#c8a060"), false, 2.0)
		_pins[id] = box.grow(6)   # a little extra so a finger finds it

func _gui_input(e: InputEvent) -> void:
	var pos := Vector2.INF
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
	if pos == Vector2.INF:
		return
	var best := ""
	var dist := INF
	for id in _pins:
		var r: Rect2 = _pins[id]
		if r.has_point(pos) and r.get_center().distance_to(pos) < dist:
			best = id
			dist = r.get_center().distance_to(pos)
	if best != "":
		accept_event()
		selected = best
		queue_redraw()
		picked.emit(best)

## Opens the map over the town: the diamond, then one row per place. pick(id) opens it.
static func open_for(main, hidden_spots: Dictionary, locked_spots: Dictionary, on_pick: Callable) -> Overlay:
	var o := Overlay.new().open(main, "Town map", 480.0, UI.GOLD)
	var m := TownMap.new()
	m.hidden_ids = hidden_spots
	m.locked = locked_spots
	o.content.add_child(m)
	var go := func(id: String):
		if id == "obelisk":
			main.toast("The Prophecy stone. Its words change as the town grows.")
			return
		o.close()
		on_pick.call(id)
	m.picked.connect(go)
	o.content.add_child(UI.label("Tap a place to go there", UI.FONT_BODY, UI.DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	o.content.add_child(grid)
	var spots: Array = m.data.get("spots", [])
	for sp in spots:
		var id := String(sp["id"])
		if hidden_spots.has(id):
			continue
		var empty := String(sp.get("kind", "")) == "lot" and not Buildings.built(id)
		var b := UI.button(("+  " if empty else "") + String(sp["label"]).replace(" (lot)", ""), func(): go.call(id))
		b.icon = icon(id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, UI.TAP)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if empty or locked_spots.get(id, "") != "":
			b.add_theme_color_override("font_color", UI.DIM)
		grid.add_child(b)
	return o
