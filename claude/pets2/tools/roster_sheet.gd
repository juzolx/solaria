extends SceneTree
## Pets 2: the full roster at 3x. One line per region (its egg, then its pets in
## hatch-pool order), then the Calamity pets, then the 5 companion lines (stage 0..3).
## The hero stands at the start of the first line for scale.
## args: <out.png> <hero_east.png>
const S := 3
const CELL := 34
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var rows: Array = []
	var cur := ""; var row: Array = []
	for l in FileAccess.get_file_as_string("res://claude/pets2/pool.txt").strip_edges().split("\n"):
		var c := l.split("|")
		if c[0] != cur:
			if cur != "": rows.append(row)
			cur = c[0]; row = ["egg_" + cur]
		row.append(c[1])
	rows.append(row)
	var cal: Array = []
	for i in 10: cal.append("calamity_%d_pet" % i)
	rows.append(cal)
	var line: Array = []
	for cls in ["knight", "wanderer", "mage", "ranger", "bard"]:
		for st in 4: line.append("%s_%d" % [cls, st])
		line.append("")
		if line.size() >= 10:
			rows.append(line); line = []
	if not line.is_empty(): rows.append(line)
	var hero := Image.load_from_file(a[1]); hero.convert(Image.FORMAT_RGBA8)
	var hw := hero.get_used_rect().size.x + 6
	var W := (hw + 14 * CELL) * S + 24
	var H := rows.size() * (40 * S + 10) + 20 + 30 * S
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1b1824"))
	var y := 10
	for ri in rows.size():
		var band := Image.create(hw + 14 * CELL, 40 if ri > 0 else 70, false, Image.FORMAT_RGBA8)
		band.fill(Color("#262230") if ri % 2 == 0 else Color("#2c2838"))
		var x := 4
		if ri == 0:
			var u := hero.get_used_rect()
			band.blend_rect(hero, u, Vector2i(x, band.get_height() - 2 - u.size.y))
		x = hw
		for id in rows[ri]:
			if id != "":
				var f := ProjectSettings.globalize_path("res://art/pets/32/%s.png" % id)
				if FileAccess.file_exists(f):
					var im := Image.load_from_file(f); im.convert(Image.FORMAT_RGBA8)
					var u := im.get_used_rect()
					band.blend_rect(im, u, Vector2i(x + (32 - u.size.x) / 2, band.get_height() - 3 - u.size.y))
				else:
					band.fill_rect(Rect2i(x + 8, band.get_height() - 20, 16, 16), Color("#ff0044"))
			x += CELL
		band.resize(band.get_width() * S, band.get_height() * S, Image.INTERPOLATE_NEAREST)
		out.blit_rect(band, Rect2i(Vector2i.ZERO, band.get_size()), Vector2i(12, y))
		y += band.get_height() + 10
	out.crop(W, y + 10)
	out.save_png(a[0])
	quit()
