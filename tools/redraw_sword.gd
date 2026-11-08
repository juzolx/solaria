extends SceneTree
## One-off art tool (already run): thickens the hero's held sword in art/heroes/*/weapon_sword.png. The old
## sword was a 1-3 px white sliver next to the other weapons. Every frame keeps its cell, its hilt and its
## angle: each blade row (or column, for flat frames) grows one pixel each side in the new blackened-steel
## ramp (light left edge, mid, shaded right edge); crossguard rows (wide) get a dark steel tone.
##   godot --headless --path . -s tools/redraw_sword.gd
const CELL := 128
const HI := Color("#c0cbdc")
const MID := Color("#8b9bb4")
const SHADE := Color("#545d70")
const GUARD := Color("#4a4852")
const GUARD_EDGE := Color("#7d8798")

func _initialize() -> void:
	var dir := DirAccess.open("res://art/heroes")
	for d in dir.get_directories():
		var path := "res://art/heroes/%s/weapon_sword.png" % d
		if not FileAccess.file_exists(path):
			continue
		var src := Image.load_from_file(ProjectSettings.globalize_path(path))
		src.convert(Image.FORMAT_RGBA8)
		var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
		for c in src.get_width() / CELL:
			_cell(src, out, c * CELL)
		out.save_png(ProjectSettings.globalize_path(path))
		print("redrew ", path)
	quit()

func _cell(src: Image, out: Image, x0: int) -> void:
	var pts: Array = []
	for y in src.get_height():
		for x in CELL:
			if src.get_pixel(x0 + x, y).a > 0.1:
				pts.append(Vector2i(x, y))
	if pts.is_empty():
		return
	var mean := Vector2.ZERO
	for p in pts:
		mean += Vector2(p)
	mean /= pts.size()
	var sxx := 0.0
	var syy := 0.0
	for p in pts:
		var v := Vector2(p) - mean
		sxx += v.x * v.x
		syy += v.y * v.y
	var steep := syy >= sxx   # mostly up and down: widen each row; mostly flat: widen each column
	var lines := {}
	for p in pts:
		var k: int = p.y if steep else p.x
		var v: int = p.x if steep else p.y
		if not lines.has(k):
			lines[k] = [v, v]
		else:
			lines[k][0] = mini(lines[k][0], v)
			lines[k][1] = maxi(lines[k][1], v)
	for k in lines:
		var a: int = lines[k][0]
		var b: int = lines[k][1]
		var guard := b - a + 1 >= 4
		for v in range(a - 1, b + 2):
			var col := MID
			if guard:
				col = GUARD_EDGE if (v == a - 1 or v == b + 1) else GUARD
			elif v == a - 1:
				col = HI
			elif v == b + 1:
				col = SHADE
			var x: int = (v if steep else k)
			var y: int = (k if steep else v)
			if x >= 0 and x < CELL and y >= 0 and y < src.get_height():
				out.set_pixel(x0 + x, y, col)
