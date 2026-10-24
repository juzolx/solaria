extends SceneTree
## Pets 2: candidates grouped by id: each id gets a block of up to 3 cells
## (in candidate order), blocks laid out <per> to a line, in the map's order.
## args: <out.png> <scale> <per line> <map.txt> <dir>
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s := int(a[1]); var per := int(a[2])
	var order: Array = []; var cands := {}
	for line in FileAccess.get_file_as_string(a[3]).strip_edges().split("\n"):
		var kv := line.split("\t")
		if not cands.has(kv[1]):
			cands[kv[1]] = []; order.append(kv[1])
		cands[kv[1]].append(int(kv[0]))
	var cell := 32 * s + 4
	var bw := cell * 3 + 10
	var rows := int(ceil(order.size() / float(per)))
	var out := Image.create(per * bw + 6, rows * (cell + 6) + 6, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1b1824"))
	for bi in order.size():
		var bx := 6 + (bi % per) * bw; var by := 6 + (bi / per) * (cell + 6)
		out.fill_rect(Rect2i(bx - 3, by - 3, cell * 3 + 2, cell + 2), Color("#2f2b3a") if bi % 2 == 0 else Color("#3a3546"))
		var list: Array = cands[order[bi]]
		for ci in list.size():
			var im := Image.load_from_file("%s/c_%02d.png" % [a[4], list[ci]])
			im.convert(Image.FORMAT_RGBA8)
			im.resize(32 * s, 32 * s, Image.INTERPOLATE_NEAREST)
			out.blend_rect(im, Rect2i(0, 0, 32 * s, 32 * s), Vector2i(bx + ci * cell, by))
	out.save_png(a[0])
	quit()
