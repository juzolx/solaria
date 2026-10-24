extends SceneTree
## Pets 2: lays images in a row at an integer scale on the dark plate.
## args: <out.png> <scale> <img>...
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s := int(a[1])
	var imgs: Array = []
	var w := 8; var h := 0
	for f in a.slice(2):
		var im := Image.load_from_file(f)
		im.convert(Image.FORMAT_RGBA8)
		im.resize(im.get_width() * s, im.get_height() * s, Image.INTERPOLATE_NEAREST)
		imgs.append(im)
		w += im.get_width() + 8
		h = maxi(h, im.get_height())
	var out := Image.create(w, h + 16, false, Image.FORMAT_RGBA8)
	out.fill(Color("#262230"))
	var x := 8
	for im in imgs:
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, 8 + h - im.get_height()))
		x += im.get_width() + 8
	out.save_png(a[0])
	quit()
