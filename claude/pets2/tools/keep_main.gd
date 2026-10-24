extends SceneTree
## Pets 2: keeps only the biggest opaque blob of each image (drops stray specks).
## args: <img>...  (rewritten in place)
func _init() -> void:
	for f in OS.get_cmdline_user_args():
		var im := Image.load_from_file(f)
		im.convert(Image.FORMAT_RGBA8)
		var w := im.get_width(); var h := im.get_height()
		var lab := PackedInt32Array(); lab.resize(w * h)
		var sizes := [0]
		for y in h:
			for x in w:
				if im.get_pixel(x, y).a < 0.5 or lab[y * w + x] != 0:
					continue
				var id := sizes.size(); var n := 0
				var st := [Vector2i(x, y)]
				lab[y * w + x] = id
				while not st.is_empty():
					var p: Vector2i = st.pop_back(); n += 1
					for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1)]:
						var q: Vector2i = p + d
						if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and lab[q.y * w + q.x] == 0 and im.get_pixelv(q).a >= 0.5:
							lab[q.y * w + q.x] = id; st.append(q)
				sizes.append(n)
		var best := 0
		for i in sizes.size():
			if sizes[i] > sizes[best]: best = i
		for y in h:
			for x in w:
				if lab[y * w + x] != best:
					im.set_pixel(x, y, Color(0, 0, 0, 0))
		im.save_png(f)
	quit()
