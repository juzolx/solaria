extends SceneTree
## A sheet of every LPC monster (still frame) -> /root/shots/lpc_monsters.png
func _initialize() -> void:
	var keys := Lpc.MONSTERS.keys()
	var cols := 8
	var cell := 72
	var sheet := Image.create(cols * cell, int(ceil(keys.size() / float(cols))) * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#141020"))
	for i in keys.size():
		var art := Sprites.enemy_by_key(keys[i])
		var img: Image = (art["tex"] as Texture2D).get_image()
		sheet.blend_rect(img, Rect2i(0, 0, 64, 64), Vector2i((i % cols) * cell + 4, (i / cols) * cell + 4))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png("/root/shots/lpc_monsters.png")
	print("monsters ok ", keys.size())
	quit()
