extends SceneTree
## Pets 2: bakes a 2-frame idle strip (frame 0 = the still, frame 1 = breathe)
## from a pet still. Standing pets: everything above ~45% of the body height
## drops 1 px (the feet stay put). Floating pets (--float): the whole sprite bobs 1 px.
## args: <still.png> <out_strip.png> [--float]
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0])
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width(); var h := src.get_height()
	var used := src.get_used_rect()
	var f1 := Image.create(w, h, false, Image.FORMAT_RGBA8)
	if a.size() > 2 and a[2] == "--float":
		f1.blit_rect(src, Rect2i(0, 0, w, h - 1), Vector2i(0, 1))
	else:
		var cut := used.position.y + int(used.size.y * 0.55)  # rows above this bob
		f1.blit_rect(src, Rect2i(0, cut, w, h - cut), Vector2i(0, cut))
		var top := Image.create(w, cut, false, Image.FORMAT_RGBA8)
		top.blit_rect(src, Rect2i(0, 0, w, cut), Vector2i.ZERO)
		f1.blend_rect(top, Rect2i(0, 0, w, cut), Vector2i(0, 1))
	var out := Image.create(w * 2, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, w, h), Vector2i.ZERO)
	out.blit_rect(f1, Rect2i(0, 0, w, h), Vector2i(w, 0))
	out.save_png(a[1])
	quit()
