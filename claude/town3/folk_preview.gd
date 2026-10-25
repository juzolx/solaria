extends SceneTree
## Townsfolk walker preview: per person, full-res front | halved front x2 | halved back x2.
## godot --headless --path . -s claude/town3/folk_preview.gd
func _init() -> void:
	var out := ProjectSettings.globalize_path("res://claude/town3/out/walkers_v2/")
	var n := TownFolk.PEOPLE.size()
	var sheet := Image.create(96 * 4, 96 * n, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.16, 0.15, 0.2))
	var t0 := Time.get_ticks_msec()
	for i in n:
		var p: Array = TownFolk.PEOPLE[i]
		var fr := HeroArt.frames(p[0], p[1], p[2], "", false)
		var w := TownFolk.townsfolk(i)
		sheet.blend_rect(fr["img"][7], Rect2i(0, 0, 96, 96), Vector2i(0, i * 96))
		for k in 3:
			var im: Image = [w["s"][0], w["s"][1], w["s"][0]][k].get_image()
			im.resize(96, 96, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(im, Rect2i(0, 0, 96, 96), Vector2i(96 * (k + 1), i * 96))
	print("built ", n, " looks in ", Time.get_ticks_msec() - t0, " ms")
	sheet.save_png(out + "folk_preview.png")
	quit()
