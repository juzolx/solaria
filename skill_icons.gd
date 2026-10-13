class_name SkillIcons
extends RefCounted
## Skill icons: one frame of the matching effect (art/fx) for each skill tag.

const TAG_FX := {"Blade": "slash", "Fist": "impact", "Fire": "fire", "Frost": "ice", "Storm": "lightning", "Arcane": "arcane",
	"Holy": "holy", "Shadow": "shadow", "Blood": "blood", "Nature": "nature", "Song": "heal", "Trick": "claw"}
static var _cache := {}

## A 64x64 icon for a skill tag (the effect's fullest frame), or null.
static func for_tag(tag: String) -> Texture2D:
	if _cache.has(tag):
		return _cache[tag]
	var fx: String = TAG_FX.get(tag, "burst")
	var path := "res://art/fx/%s.png" % fx
	var out: Texture2D = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		var n := img.get_width() / 64
		var best := 0
		var best_a := -1
		for i in n:
			var a := 0
			for y in range(0, 64, 4):
				for x in range(0, 64, 4):
					if img.get_pixel(i * 64 + x, y).a > 0.3:
						a += 1
			if a > best_a:
				best_a = a
				best = i
		var frame := img.get_region(Rect2i(best * 64, 0, 64, 64))
		var used := frame.get_used_rect()
		if used.size.x > 0:
			var side := maxi(used.size.x, used.size.y)
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(frame, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
			sq.resize(32, 32, Image.INTERPOLATE_NEAREST)
			out = ImageTexture.create_from_image(sq)
	_cache[tag] = out
	return out
