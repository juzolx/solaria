extends SceneTree
## Before/after sheet for outline.gd: each pet at 3x on a dark hall grey and a light (zone 8) tone.
## Run: godot --headless --path . -s claude/pets2/tools/outline_sheet.gd -- <before dir> <out.png> key1 key2 ...

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var before: String = a[0]
	var keys := a.slice(2)
	var cell := 32 * 3
	var w := 4 * cell + 50
	var img := Image.create(w, keys.size() * (cell + 8) + 8, false, Image.FORMAT_RGBA8)
	img.fill(Color8(20, 18, 24))
	var bgs := [Color8(38, 34, 44), Color8(207, 200, 190)]
	for i in keys.size():
		var y := 8 + i * (cell + 8)
		var pics := [Image.load_from_file(before.path_join(keys[i] + ".png")), Image.load_from_file(ProjectSettings.globalize_path("res://art/pets/32/%s.png" % keys[i]))]
		for col in 4:
			var x := 10 + col * (cell + 10)
			img.fill_rect(Rect2i(x, y, cell, cell), bgs[col % 2])
			var p: Image = pics[col / 2].duplicate()
			p.convert(Image.FORMAT_RGBA8)
			p.resize(cell, cell, Image.INTERPOLATE_NEAREST)
			img.blend_rect(p, Rect2i(0, 0, cell, cell), Vector2i(x, y))
	img.save_png(a[1])
	quit()
