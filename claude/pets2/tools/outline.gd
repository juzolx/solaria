extends SceneTree
## Fable pets R1 item 4: give pale pets the heroes' 1 px #0e0812 outline.
## Every clear pixel next to an opaque pixel that is not near-black (any channel >= 70) turns #0e0812; edges
## that are already dark are left alone, so nothing gets a double line.
## Works on the still and on each 32x32 frame of the idle strip, in place.
## Run: godot --headless --path . -s claude/pets2/tools/outline.gd -- key1 key2 ...

const DIR := "res://art/pets/32/"
const INK := Color8(0x0e, 0x08, 0x12)

func _init() -> void:
	for key in OS.get_cmdline_user_args():
		for path in [DIR + key + ".png", DIR + key + "_idle.png"]:
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img == null:
				print("missing ", path)
				continue
			img.convert(Image.FORMAT_RGBA8)
			var src := img.duplicate() as Image
			var added := 0
			for x0 in range(0, img.get_width(), 32):
				for y in 32:
					for x in range(x0, x0 + 32):
						if src.get_pixel(x, y).a > 0.5:
							continue
						for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
							var n: Vector2i = Vector2i(x, y) + d
							if n.x < x0 or n.x >= x0 + 32 or n.y < 0 or n.y >= 32:
								continue
							var c := src.get_pixel(n.x, n.y)
							if c.a > 0.5 and maxf(c.r, maxf(c.g, c.b)) * 255.0 >= 70.0:
								img.set_pixel(x, y, INK)
								added += 1
								break
			img.save_png(ProjectSettings.globalize_path(path))
			print("%s +%d" % [path.get_file(), added])
	quit()
