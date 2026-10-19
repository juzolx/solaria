extends SceneTree
## Monster sprites unlit (top) and with SpriteLight (bottom), zones 0 and 3, into shots/room3d.
func _initialize() -> void:
	var keys := ["redcap", "barghest", "treasure_goblin", "boggart", "wraith", "troll"]
	var texs: Array = []
	for k in keys:
		var a := Sprites.enemy_by_key(k)
		if a.has("tex"):
			texs.append(a["tex"])
	var cell := 64
	var sheet := Image.create(cell * texs.size(), cell * 3, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.1, 0.1))
	for i in texs.size():
		var t: Texture2D = texs[i]
		var rows := [t, SpriteLight.lit(t, 0), SpriteLight.lit(t, 3)]
		for r in 3:
			var img := (rows[r] as Texture2D).get_image()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(cell, cell, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(img, Rect2i(0, 0, cell, cell), Vector2i(i * cell, r * cell))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/room3d/light_sheet.png")
	print("SHEET DONE ", texs.size())
	quit()
