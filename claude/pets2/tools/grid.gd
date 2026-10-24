extends SceneTree
## Pets 2: a numbered contact grid of candidates (cols per row, integer scale).
## args: <out.png> <scale> <cols> <img>...
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s := int(a[1]); var cols := int(a[2])
	var files := a.slice(3)
	var cell := 32 * s + 6
	var rows := int(ceil(files.size() / float(cols)))
	var out := Image.create(cols * cell + 6, rows * cell + 6, false, Image.FORMAT_RGBA8)
	out.fill(Color("#2a2733"))
	for i in files.size():
		var im := Image.load_from_file(files[i])
		im.convert(Image.FORMAT_RGBA8)
		im.resize(im.get_width() * s, im.get_height() * s, Image.INTERPOLATE_NEAREST)
		var p := Vector2i(6 + (i % cols) * cell, 6 + (i / cols) * cell)
		out.fill_rect(Rect2i(p, im.get_size()), Color("#3a3644") if (i / cols + i % cols) % 2 == 0 else Color("#33303c"))
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), p)
	out.save_png(a[0])
	quit()
