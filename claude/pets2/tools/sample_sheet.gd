extends SceneTree
## Pets 2: the sample sheet. Battle mock-ups (hero from behind, pet at its knee,
## a Catacombs monster ahead) at 3x, a side line-up at 3x, and the idle frames at 6x.
## args: <out.png> <hero_north.png> <hero_east.png> <monster.png> <pets_dir> <pet names...>
const BG := Color("#1b1824")
const PLATE := Color("#262230")
func _img(f: String) -> Image:
	var im := Image.load_from_file(f)
	im.convert(Image.FORMAT_RGBA8)
	return im
func _up(im: Image, s: int) -> Image:
	var c := im.duplicate()
	c.resize(im.get_width() * s, im.get_height() * s, Image.INTERPOLATE_NEAREST)
	return c
func _put(out: Image, im: Image, x: int, y: int) -> void:  # x,y: bottom-left of the sprite's used rect
	var u := im.get_used_rect()
	out.blend_rect(im, u, Vector2i(x, y - u.size.y))
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var hn := _img(a[1]); var he := _img(a[2]); var mon := _img(a[3])
	var dir := a[4]; var names := a.slice(5)
	var S := 3
	var sw := 150; var sh := 110  # one battle scene, true px
	var W := (sw * names.size() + 4 * (names.size() + 1)) * S
	var H := 40 + sh * S + 30 + 70 * S + 30 + 36 * 6 + 40
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	out.fill(BG)
	# 1) battle scenes
	for i in names.size():
		var sc := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
		sc.fill(Color("#2a3150"))                                   # catacomb wall
		sc.fill_rect(Rect2i(0, 62, sw, sh - 62), Color("#3a4466"))  # floor
		for k in range(0, sw, 16):
			sc.fill_rect(Rect2i(k, 0, 1, 62), Color("#262b44"))
		for k in range(8, 62, 10):
			sc.fill_rect(Rect2i(0, k, sw, 1), Color("#262b44"))
		var pet := _img("%s/%s.png" % [dir, names[i]])
		_put(sc, mon, 52, 78)          # monster ahead
		_put(sc, hn, 50, 108)          # hero from behind
		_put(sc, pet, 92, 108)         # pet at the hero's knee
		var big := _up(sc, S)
		out.blit_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i((4 + i * (sw + 4)) * S, 40))
	# 2) side line-up: hero, pets, eggs, monster on one ground line
	var y0 := 40 + sh * S + 30
	var lu := Image.create(W / S, 70, false, Image.FORMAT_RGBA8)
	lu.fill(PLATE)
	var x := 8
	_put(lu, he, x, 66); x += he.get_used_rect().size.x + 10
	for n in names:
		var p := _img("%s/%s.png" % [dir, n]); _put(lu, p, x, 66); x += p.get_used_rect().size.x + 8
	x += 6
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("egg_") and f.ends_with(".png"):
			var e := _img(dir + "/" + f); _put(lu, e, x, 66); x += e.get_used_rect().size.x + 6
	x += 10
	_put(lu, mon, x, 66)
	var lub := _up(lu, S)
	out.blit_rect(lub, Rect2i(Vector2i.ZERO, lub.get_size()), Vector2i(0, y0))
	# 3) idle frames at 6x
	var y1 := y0 + 70 * S + 30
	x = 12
	for n in names:
		var strip := _img("%s/%s_idle.png" % [dir, n])
		var sb := _up(strip, 6)
		out.fill_rect(Rect2i(Vector2i(x, y1), sb.get_size()), PLATE)
		out.blend_rect(sb, Rect2i(Vector2i.ZERO, sb.get_size()), Vector2i(x, y1))
		x += sb.get_width() + 24
	out.save_png(a[0])
	quit()
