class_name SpriteLight
extends RefCounted
## 0.13+: wraparound lighting for flat monster sprites in fights. A normal map is made
## from each sprite's shape (how far each pixel is from the edge, so bodies read as
## rounded), then lit once by the region's torch color from the upper left with a cool
## rim light from behind. Baked into a new texture and cached, so it costs nothing per
## frame (phones). Same look as the 3D prototype's lit monsters, without 3D.

const WRAP := 0.5          # light wraps past the shadow line (soft, painterly)
const KEY_DIR := Vector3(-0.55, -0.6, 0.6)   # from the upper left, in front (screen y down)
const RIM_DIR := Vector2(0.7, -0.7)          # from behind, upper right
static var enabled := true
static var _cache := {}

## The lit version of `tex` for region `zone` (0-9). Returns `tex` itself if it can't be read.
static func lit(tex: Texture2D, zone: int) -> Texture2D:
	if tex == null or not enabled:
		return tex
	var key := "%d|%d" % [tex.get_rid().get_id(), zone]
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 800:
		_cache.clear()
	var src := tex.get_image()
	if src == null:
		_cache[key] = tex
		return tex
	var img := src.duplicate() as Image  # work on a copy of the monster's image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var mood: Dictionary = HallsScene.MOODS[clampi(zone, 0, HallsScene.MOODS.size() - 1)]
	var key_col: Color = Color.WHITE.lerp(mood["light"], 0.45)
	var rim_col: Color = (mood["amb"] as Color).lightened(0.35)
	var out := ImageTexture.create_from_image(shade(img, key_col, rim_col))
	_cache[key] = out
	return out

## Lights an RGBA8 image (returns a new one). The surface normal comes from the blurred
## silhouette, so the whole body bulges toward you: the side facing the light brightens,
## the far side falls into shade, and the back edge catches a colored rim. Brightness is
## kept where the surface faces you, so sprites don't get darker overall.
static func shade(img: Image, key_col: Color, rim_col: Color) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var dist := edge_distance(img)
	var radius := maxi(3, int(round(minf(w, h) / 12.0)))
	var blur := PackedFloat32Array()
	blur.resize(w * h)
	for i in w * h:
		blur[i] = 1.0 if dist[i] > 0.0 else 0.0
	blur = _box(_box(blur, w, h, radius), w, h, radius)
	var res := img.duplicate() as Image
	var ldir := KEY_DIR.normalized()
	var amb := 0.5
	var key := 0.75
	var flat := amb + key * (ldir.z + WRAP) / (1.0 + WRAP)
	var k := float(radius) * 1.6
	# the region tints every monster a little (same beast, its own colors in each region)
	var tint := rim_col / maxf(0.001, maxf(rim_col.r, maxf(rim_col.g, rim_col.b)))
	for y in h:
		for x in w:
			var i := y * w + x
			if dist[i] <= 0.0:
				continue
			var gx := blur[y * w + mini(x + 1, w - 1)] - blur[y * w + maxi(x - 1, 0)]
			var gy := blur[mini(y + 1, h - 1) * w + x] - blur[maxi(y - 1, 0) * w + x]
			var n := Vector3(-gx * k, -gy * k, 1.0).normalized()
			var wrap := maxf(0.0, (n.dot(ldir) + WRAP) / (1.0 + WRAP))
			var c := img.get_pixel(x, y)
			c = Color(c.r * lerpf(1.0, tint.r, 0.3), c.g * lerpf(1.0, tint.g, 0.3), c.b * lerpf(1.0, tint.b, 0.3), c.a)
			var lr := (amb + key * wrap * key_col.r) / flat
			var lg := (amb + key * wrap * key_col.g) / flat
			var lb := (amb + key * wrap * key_col.b) / flat
			var r := c.r * lr
			var g := c.g * lg
			var b := c.b * lb
			# rim: just inside the outline, on the side away from the key light
			var side := Vector2(n.x, n.y)
			if dist[i] <= 3.5 and side.length() > 0.15:
				var rim := maxf(0.0, side.normalized().dot(RIM_DIR)) * clampf(side.length() * 1.5, 0.0, 1.0) * (1.0 - (dist[i] - 1.0) / 3.0)
				r += rim_col.r * rim * 0.5
				g += rim_col.g * rim * 0.5
				b += rim_col.b * rim * 0.5
			# a little ambient occlusion toward the feet
			var s := 1.0 - 0.14 * clampf((float(y) / h - 0.6) / 0.4, 0.0, 1.0)
			res.set_pixel(x, y, Color(minf(r * s, 1.0), minf(g * s, 1.0), minf(b * s, 1.0), c.a))
	return res

## Separable box blur (radius r), clamped at the edges.
static func _box(src: PackedFloat32Array, w: int, h: int, r: int) -> PackedFloat32Array:
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var out := PackedFloat32Array()
	out.resize(w * h)
	var n := float(r * 2 + 1)
	for y in h:
		for x in w:
			var s := 0.0
			for o in range(-r, r + 1):
				s += src[y * w + clampi(x + o, 0, w - 1)]
			tmp[y * w + x] = s / n
	for y in h:
		for x in w:
			var s := 0.0
			for o in range(-r, r + 1):
				s += tmp[clampi(y + o, 0, h - 1) * w + x]
			out[y * w + x] = s / n
	return out

## How far each opaque pixel is from the sprite's edge (two-pass chamfer distance).
static func edge_distance(img: Image) -> PackedFloat32Array:
	var w := img.get_width()
	var h := img.get_height()
	var d := PackedFloat32Array()
	d.resize(w * h)
	for y in h:
		for x in w:
			d[y * w + x] = 0.0 if img.get_pixel(x, y).a < 0.5 else 999.0
	for y in h:
		for x in w:
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var best := d[i]
			best = minf(best, (d[i - 1] if x > 0 else 0.0) + 1.0)
			best = minf(best, (d[i - w] if y > 0 else 0.0) + 1.0)
			best = minf(best, (d[i - w - 1] if x > 0 and y > 0 else 0.0) + 1.4)
			best = minf(best, (d[i - w + 1] if x < w - 1 and y > 0 else 0.0) + 1.4)
			d[i] = best
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var best := d[i]
			best = minf(best, (d[i + 1] if x < w - 1 else 0.0) + 1.0)
			best = minf(best, (d[i + w] if y < h - 1 else 0.0) + 1.0)
			best = minf(best, (d[i + w + 1] if x < w - 1 and y < h - 1 else 0.0) + 1.4)
			best = minf(best, (d[i + w - 1] if x > 0 and y < h - 1 else 0.0) + 1.4)
			d[i] = best
	return d
