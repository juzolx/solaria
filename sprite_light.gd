class_name SpriteLight
extends RefCounted
## Monsters in fights and rooms: the art keeps its own drawn shades (no wash, no tint, no
## blurred normal map: Fable round 1). The only touch is a 1 px rim in the zone's accent
## (HallsScene.MOODS) on the upper-right edge pixels, just inside the outline, so a monster
## sits in its zone. One pass over the bytes, baked into a texture and cached per zone.

static var enabled := true
static var _cache := {}
static var _order: Array = []   # cache keys, oldest first
const MAX_CACHED := 150         # ~150 rimmed monster textures; the oldest goes first (no all-at-once clear)

## The rimmed version of `tex` for region `zone` (0-9). Returns `tex` itself if it can't be read.
static func lit(tex: Texture2D, zone: int) -> Texture2D:
	if tex == null or not enabled:
		return tex
	var key := "%d|%d" % [tex.get_rid().get_id(), zone]
	if _cache.has(key):
		return _cache[key]
	var src := tex.get_image()
	if src == null:
		_remember(key, tex)
		return tex
	var img := src.duplicate() as Image  # work on a copy of the monster's image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var mood: Dictionary = HallsScene.MOODS[clampi(zone, 0, HallsScene.MOODS.size() - 1)]
	var out := ImageTexture.create_from_image(shade(img, mood["accent"]))
	_remember(key, out)
	return out

static func _remember(key: String, tex: Texture2D) -> void:
	_cache[key] = tex
	_order.append(key)
	while _order.size() > MAX_CACHED:
		_cache.erase(_order.pop_front())

## A new RGBA8 image with a 1 px rim of `rim` on every solid, non-outline pixel whose
## neighbour up or to the right is the outline or see-through (light from the upper right).
static func shade(img: Image, rim: Color) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var res := data.duplicate()
	var r8 := rim.r8
	var g8 := rim.g8
	var b8 := rim.b8
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			if _open(data, i):
				continue
			var edge := y == 0 or x == w - 1 or _open(data, i - w * 4) or _open(data, i + 4)
			if edge:
				# halfway to the rim colour, so the drawn shade still shows through
				res[i] = (data[i] + r8) / 2
				res[i + 1] = (data[i + 1] + g8) / 2
				res[i + 2] = (data[i + 2] + b8) / 2
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, res)

## True where pixel byte offset i is see-through or the outline colour (#0e0812).
static func _open(data: PackedByteArray, i: int) -> bool:
	return data[i + 3] < 128 or (data[i] == 14 and data[i + 1] == 8 and data[i + 2] == 18)
