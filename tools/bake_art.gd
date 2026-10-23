extends SceneTree
## Bakes the shared Solaria look into the shipped PNGs (offline, so the game runs no shaders
## for it). Rules come from art_style.gd:
##   - monsters, bosses, Calamities (art/enemies) and companions (art/pets): snapped to one
##     2x art-pixel grid, mapped to the palette, hard alpha, one art-pixel dark outline,
##     68x68 (two-tile giants 68x132). Old DCSS shadows are removed.
##   - dungeon props (art/dungeon, not the floor/wall tiles) and consumable icons: palette,
##     hard alpha, 1 px outline, 32x32. The pillar and boulder are redrawn here; the flame
##     and frost trap pictures are put the right way round.
##   - effects (art/fx): palette and a few hard alpha steps (no soft gradients).
##   - art_info.gd's "enemies" table is rewritten from the files (size and foot row).
##   - art/palette.gpl (the palette for artists: GIMP / Aseprite / Krita).
## Re-runnable: a second run leaves every file the same. The originals are in git history.
##   godot --headless --path . -s tools/bake_art.gd
##   godot --headless --path . --editor --quit      (reimport afterwards)

const PROP_SKIP := ["_floor_", "_wall_"]

var _changed := 0
var _seen := 0

func _initialize() -> void:
	for f in _pngs("res://art/enemies"):
		_save_if_changed("res://art/enemies/" + f, _bake_monster(_load("res://art/enemies/" + f)))
	for f in _pngs("res://art/pets"):
		_save_if_changed("res://art/pets/" + f, _bake_monster(_load("res://art/pets/" + f)))
	_fix_traps()
	_save_if_changed("res://art/dungeon/pillar.png", _draw_pillar())
	_save_if_changed("res://art/dungeon/boulder.png", _draw_boulder())
	for f in _pngs("res://art/dungeon"):
		var skip := false
		for s in PROP_SKIP:
			skip = skip or f.contains(s)
		if not skip:
			_save_if_changed("res://art/dungeon/" + f, _bake_flat(_load("res://art/dungeon/" + f)))
	for f in _pngs("res://art/consumables"):
		_save_if_changed("res://art/consumables/" + f, _bake_flat(_load("res://art/consumables/" + f)))
	for f in _pngs("res://art/fx"):
		_save_if_changed("res://art/fx/" + f, _bake_fx(_load("res://art/fx/" + f)))
	_write_art_info()
	_write_palette()
	print("BAKE DONE: %d files looked at, %d changed" % [_seen, _changed])
	quit()

# ---------------------------------------------------------------- files

func _pngs(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			out.append(f)
	out.sort()
	return out

func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save_if_changed(path: String, img: Image) -> void:
	_seen += 1
	var old := _load(path) if FileAccess.file_exists(path) else null
	if old != null and old.get_size() == img.get_size() and old.get_data() == img.get_data():
		return
	img.save_png(ProjectSettings.globalize_path(path))
	_changed += 1
	if _changed <= 12:
		print("  baked ", path)

# ---------------------------------------------------------------- monsters (2x art)

func _bake_monster(src: Image) -> Image:
	var size := src.get_size()
	var baked := size == ArtStyle.MONSTER_SIZE or size == ArtStyle.TALL_SIZE
	# Older files carry a thin 1 px ring (half an art pixel): drop it, a full one comes back below
	var drop_ring := not baked
	var off := 0 if _flat_share(src, 0, drop_ring) >= _flat_share(src, 1, drop_ring) else 1
	var lw := (size.x - off) / 2
	var lh := (size.y - off) / 2
	var art := Image.create(lw, lh, false, Image.FORMAT_RGBA8)
	for y in lh:
		for x in lw:
			art.set_pixel(x, y, _block(src, off + x * 2, off + y * 2, drop_ring))
	if not baked:
		_strip_shadow(art)
	var target: Vector2i = ArtStyle.TALL_SIZE if lh > lw * 3 / 2 else ArtStyle.MONSTER_SIZE
	var cw := target.x / ArtStyle.ART_PX
	var ch := target.y / ArtStyle.ART_PX
	var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	var used := art.get_used_rect()
	# Keep the picture where it was (centered on the canvas), but never let the outline fall off
	var at := Vector2i((cw - lw) / 2, (ch - lh) / 2)
	var m := 0 if baked else 1
	at.x = clampi(at.x, m - used.position.x, cw - m - used.end.x)
	at.y = clampi(at.y, m - used.position.y, ch - m - used.end.y)
	canvas.blit_rect(art, used, at + used.position)
	_palette_and_outline(canvas)
	canvas.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	return canvas

## The share of 2x2 blocks (at this grid offset) that are one flat color.
func _flat_share(img: Image, off: int, drop_ring: bool) -> float:
	var blocks := 0
	var flat := 0
	for by in range(off, img.get_height() - 1, 2):
		for bx in range(off, img.get_width() - 1, 2):
			var cs: Array = []
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var c := img.get_pixel(bx + d.x, by + d.y)
				if c.a8 >= 128 and not (drop_ring and ArtStyle.is_outline(c)):
					cs.append(c.to_rgba32() | 255)
			if cs.is_empty():
				continue
			blocks += 1
			if cs.size() == 4 and cs.count(cs[0]) == 4:
				flat += 1
	return float(flat) / maxf(1.0, float(blocks))

## One art pixel from a 2x2 block: the most common solid color, or clear if fewer than two are solid.
func _block(img: Image, x: int, y: int, drop_ring: bool) -> Color:
	var counts := {}
	var n := 0
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if x + d.x >= img.get_width() or y + d.y >= img.get_height():
			continue
		var c := img.get_pixel(x + d.x, y + d.y)
		if c.a8 < 128 or (drop_ring and ArtStyle.is_outline(c)):
			continue
		var k := Color8(c.r8, c.g8, c.b8).to_rgba32()
		counts[k] = int(counts.get(k, 0)) + 1
		n += 1
	if n < 2:
		return Color(0, 0, 0, 0)
	var best := 0
	var bk := 0
	for k in counts:
		if int(counts[k]) > best:
			best = counts[k]
			bk = k
	return Color.hex(bk)

## Dungeon Crawl tiles have a dithered black shadow under the creature: pure black pixels
## that touch no colored pixel are shadow, not outline.
func _strip_shadow(img: Image) -> void:
	var kill: Array = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0 or not _black(c):
				continue
			var near := false
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if (dx != 0 or dy != 0) and nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height():
						var o := img.get_pixel(nx, ny)
						near = near or (o.a8 > 0 and not _black(o))
			if not near:
				kill.append(Vector2i(x, y))
	for p in kill:
		img.set_pixelv(p, Color(0, 0, 0, 0))

func _black(c: Color) -> bool:
	return maxi(c.r8, maxi(c.g8, c.b8)) <= 8

## Dark enough to count as an existing outline when it sits on the edge.
func _ink(c: Color) -> bool:
	return maxi(c.r8, maxi(c.g8, c.b8)) <= 40

# ---------------------------------------------------------------- shared steps

## Every solid pixel onto the palette; edge pixels that are already near-black become the
## outline color, and a one-pixel outline is added wherever the edge isn't dark yet.
func _palette_and_outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a8 == 0:
				continue
			# (judged on the palette color, so a second run decides the same way)
			if ArtStyle.is_outline(c) or (_ink(ArtStyle.nearest(c)) and _on_edge(src, x, y)):
				img.set_pixel(x, y, ArtStyle.OUTLINE)
			else:
				img.set_pixel(x, y, ArtStyle.nearest(c))
	var body := img.duplicate() as Image
	for y in h:
		for x in w:
			if body.get_pixel(x, y).a8 != 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var o := body.get_pixel(nx, ny)
				if o.a8 != 0 and not ArtStyle.is_outline(o):
					img.set_pixel(x, y, ArtStyle.OUTLINE)
					break

func _on_edge(img: Image, x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
			return true
		if img.get_pixel(nx, ny).a8 == 0:
			return true
	return false

## Partly see-through pixels become solid or clear (no soft anti-aliased edges).
func _hard_alpha(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a8 >= 128 else Color(0, 0, 0, 0))

# ---------------------------------------------------------------- props and icons (1x art)

func _bake_flat(src: Image) -> Image:
	var img := src.duplicate() as Image
	_hard_alpha(img)
	_strip_shadow(img)
	_palette_and_outline(img)
	return img

## Effects glow, so they keep some see-through steps, but every pixel is one of a few
## hard alpha levels (no soft gradients), on the palette.
func _bake_fx(src: Image) -> Image:
	var img := src.duplicate() as Image
	var levels: Array = ArtStyle.FX_ALPHA
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 < 32:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var a: int = levels[1]
			for l in levels:
				if int(l) > 0 and absi(int(l) - c.a8) < absi(a - c.a8):
					a = l
			var p := ArtStyle.nearest(c)
			img.set_pixel(x, y, Color8(p.r8, p.g8, p.b8, a))
	return img

# ---------------------------------------------------------------- props redrawn here

## The flame trap must look like fire and the frost trap like ice: the two files were
## swapped. Swaps them only while the frost one is the redder (so re-running keeps them).
func _fix_traps() -> void:
	var fl := _load("res://art/dungeon/trap_flames.png")
	var fr := _load("res://art/dungeon/trap_frost.png")
	if _warmth(fr) > _warmth(fl):
		_save_if_changed("res://art/dungeon/trap_flames.png", fr)
		_save_if_changed("res://art/dungeon/trap_frost.png", fl)

func _warmth(img: Image) -> float:
	var t := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 > 0 and c.s > 0.3:
				t += c.r - c.b
	return t

const STONE := ["e4e0ec", "bdb6cc", "a8a8ba", "7d8798", "545d70", "3a4466", "262b44"]

## A broken stone column on a plinth (drawn for Solaria, CC0).
func _draw_pillar() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# plinth: two steps
	_shade_box(img, Rect2i(7, 27, 18, 3))
	_shade_box(img, Rect2i(9, 25, 14, 2))
	# shaft with three flutes, light from the top left
	for y in range(8, 25):
		for x in range(11, 21):
			var t := float(x - 11) / 9.0
			var i := 1 if t < 0.2 else (2 if t < 0.45 else (3 if t < 0.75 else 4))
			if x in [13, 16, 19] and y % 6 != 0:
				i = mini(i + 1, 6)
			img.set_pixel(x, y, Color(STONE[i]))
	# capital: a wide slab with a darker band under it
	_shade_box(img, Rect2i(8, 5, 16, 2))
	_shade_box(img, Rect2i(10, 7, 12, 1))
	# the broken top: a chipped edge and a crack running down
	for p in [Vector2i(20, 5), Vector2i(21, 5), Vector2i(22, 5), Vector2i(23, 5), Vector2i(21, 6), Vector2i(22, 6), Vector2i(23, 6)]:
		img.set_pixelv(p, Color(0, 0, 0, 0))
	for p in [Vector2i(17, 9), Vector2i(17, 10), Vector2i(16, 11), Vector2i(16, 12), Vector2i(17, 13), Vector2i(18, 14), Vector2i(18, 15)]:
		img.set_pixelv(p, Color(STONE[5]))
	# moss at the foot
	for p in [Vector2i(11, 24), Vector2i(12, 24), Vector2i(12, 23), Vector2i(19, 24), Vector2i(9, 26), Vector2i(10, 26)]:
		img.set_pixelv(p, Color("566a56"))
	img.set_pixelv(Vector2i(12, 24), Color("7f9478"))
	_palette_and_outline(img)
	return img

## Top rows lit, left side lighter, bottom row in shadow.
func _shade_box(img: Image, r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var i := 2
			if y == r.position.y:
				i = 1
			if x == r.position.x:
				i = mini(i, 1)
			if x >= r.end.x - 2:
				i = 4
			if y == r.end.y - 1 and r.size.y > 1:
				i = maxi(i, 4) if x >= r.end.x - 2 else 3
			img.set_pixel(x, y, Color(STONE[i]))

## A rough round boulder with cracks and a little moss (drawn for Solaria, CC0).
func _draw_boulder() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c := Vector2(15.5, 18.0)
	var ramp := ["c8b08a", "a3825f", "9a7040", "6a4a28", "5a3f35", "3e2731"]
	for y in 32:
		for x in 32:
			var d := (Vector2(x + 0.5, y + 0.5) - c) / Vector2(12.5, 10.5)
			# a lumpy outline: flatter bottom, a dent on the upper right
			var bump := 0.06 * sin(atan2(d.y, d.x) * 5.0) + (0.12 if d.y > 0.55 else 0.0)
			if d.length() > 1.0 - bump:
				continue
			# light from the top left, banded (no smooth gradient)
			var lit := -d.dot(Vector2(-0.6, -0.8).normalized()) * 0.75 + d.length() * 0.45
			var i := clampi(int(floor((lit + 0.55) * 3.0)), 0, ramp.size() - 1)
			img.set_pixel(x, y, Color(ramp[i]))
	# cracks
	for p in [Vector2i(12, 13), Vector2i(13, 14), Vector2i(13, 15), Vector2i(14, 16), Vector2i(19, 19), Vector2i(20, 20), Vector2i(20, 21), Vector2i(21, 22), Vector2i(10, 21), Vector2i(11, 22)]:
		if img.get_pixelv(p).a8 > 0:
			img.set_pixelv(p, Color(ramp[5]))
	# a highlight chip and moss on top
	for p in [Vector2i(10, 11), Vector2i(11, 11), Vector2i(9, 12)]:
		if img.get_pixelv(p).a8 > 0:
			img.set_pixelv(p, Color("ead4aa"))
	for p in [Vector2i(15, 8), Vector2i(16, 8), Vector2i(17, 8), Vector2i(14, 9), Vector2i(18, 9), Vector2i(16, 9)]:
		if img.get_pixelv(p).a8 > 0:
			img.set_pixelv(p, Color("75a743") if p.y == 8 else Color("3e8948"))
	_palette_and_outline(img)
	return img

# ---------------------------------------------------------------- data files

## Rewrites the "enemies" table in art_info.gd from the files: size and foot (lowest solid row).
func _write_art_info() -> void:
	var path := ProjectSettings.globalize_path("res://art_info.gd")
	var text := FileAccess.get_file_as_string(path)
	var start := text.find("\"enemies\": {")
	var stop := text.find(", \"races\": {", start)
	if start < 0 or stop < 0:
		print("BAKE: art_info.gd layout not recognised, enemies table left alone")
		return
	var parts: Array = []
	for f in _pngs("res://art/enemies"):
		var img := _load("res://art/enemies/" + f)
		var used := img.get_used_rect()
		parts.append("\"%s\": {\"size\": [%d, %d], \"foot\": %d}" % [f.get_basename(), img.get_width(), img.get_height(), used.end.y - 1])
	var table := "\"enemies\": {" + ", ".join(PackedStringArray(parts)) + "}"
	var out := text.substr(0, start) + table + text.substr(stop)
	if out != text:
		var fa := FileAccess.open(path, FileAccess.WRITE)
		fa.store_string(out)
		fa.close()
		_changed += 1

func _write_palette() -> void:
	var lines: Array = ["GIMP Palette", "Name: Solaria", "Columns: 8", "# Made by tools/bake_art.gd from ArtStyle.PALETTE. Outline color (not in the palette): #0e0812", "#"]
	for h in ArtStyle.PALETTE:
		var c := Color(h)
		lines.append("%3d %3d %3d\t%s" % [c.r8, c.g8, c.b8, h])
	var path := ProjectSettings.globalize_path("res://art/palette.gpl")
	var text := "\n".join(PackedStringArray(lines)) + "\n"
	if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path) == text:
		return
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(text)
	fa.close()
