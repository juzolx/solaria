extends SceneTree
## Pets 2: exports the picked candidates into art/pets/32/: <id>.png (32x32 still,
## hard alpha) and, for pets, <id>_idle.png (2-frame strip, see idle.gd).
## Reads picks.txt ("<call> <id> <slot>"; call "s" = the sample, slot = candidate
## index), raw/call<N>_map.txt (candidate -> id) and spec.tsv (s/f/e kind).
const ROOT := "res://claude/pets2/"
const OUT := "res://art/pets/32/"
func _init() -> void:
	var kind := {}
	for l in FileAccess.get_file_as_string(ROOT + "spec.tsv").strip_edges().split("\n"):
		var c := l.strip_edges().split("|")
		kind[c[1]] = c[2]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var n := 0
	# an optional arg names another picks file (picks_r1.txt: only the Fable R1 redraws);
	# a full re-export undoes outline.gd, so run that again after one
	var args := OS.get_cmdline_user_args()
	for l in FileAccess.get_file_as_string(ROOT + (args[0] if args.size() > 0 else "picks.txt")).strip_edges().split("\n"):
		var p := l.strip_edges().split(" ")
		var src := ""
		if p[0] == "s":
			src = ROOT + "raw/sample/c_%02d.png" % int(p[2])
		else:
			var cands: Array = []
			for m in FileAccess.get_file_as_string(ROOT + "raw/call%s_map.txt" % p[0]).strip_edges().split("\n"):
				var kv := m.split("\t")
				if kv[1] == p[1]:
					cands.append(int(kv[0]))
			src = ROOT + "raw/call%s/c_%02d.png" % [p[0], cands[int(p[2])]]
		var im := Image.load_from_file(ProjectSettings.globalize_path(src))
		im.convert(Image.FORMAT_RGBA8)
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				im.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a >= 0.5 else Color(0, 0, 0, 0))
		im.save_png(ProjectSettings.globalize_path(OUT + p[1] + ".png"))
		if kind.get(p[1], "s") != "e":
			_idle(im, kind.get(p[1], "s") == "f").save_png(ProjectSettings.globalize_path(OUT + p[1] + "_idle.png"))
		n += 1
	print("exported %d" % n)
	quit()

## Frame 0 = the still. Frame 1: standing pets dip everything above ~55% of
## their height by 1 px (feet stay), floating ones bob down 1 px whole.
func _idle(src: Image, floats: bool) -> Image:
	var w := src.get_width(); var h := src.get_height()
	var f1 := Image.create(w, h, false, Image.FORMAT_RGBA8)
	if floats:
		f1.blit_rect(src, Rect2i(0, 0, w, h - 1), Vector2i(0, 1))
	else:
		var used := src.get_used_rect()
		var cut := used.position.y + int(used.size.y * 0.55)
		f1.blit_rect(src, Rect2i(0, cut, w, h - cut), Vector2i(0, cut))
		var top := Image.create(w, cut, false, Image.FORMAT_RGBA8)
		top.blit_rect(src, Rect2i(0, 0, w, cut), Vector2i.ZERO)
		f1.blend_rect(top, Rect2i(0, 0, w, cut), Vector2i(0, 1))
	var out := Image.create(w * 2, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, w, h), Vector2i.ZERO)
	out.blit_rect(f1, Rect2i(0, 0, w, h), Vector2i(w, 0))
	return out
