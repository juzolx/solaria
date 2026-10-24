class_name Variants
extends RefCounted
## 0.13+ (Stage 3): monster variants. Now and then a monster turns up changed: gilded,
## blighted, ashen or pale, with its own colors (recolored from its sprite, cached) and
## one small twist. The same beast, a new face.

const CHANCE := 6.0      # % of ordinary fights from FROM_FLOOR
const FROM_FLOOR := 6
const LIST := {
	"Gilded": {"tint": "#f5c542", "keep": 0.35, "text": "drops half again as much gold"},
	"Blighted": {"tint": "#7bbf3a", "keep": 0.45, "text": "its hits can poison you"},
	"Ashen": {"tint": "#9a9a9a", "keep": 0.25, "text": "a third more health"},
	"Pale": {"tint": "#cfe3ff", "keep": 0.3, "text": "hard to see: you miss more often"},
}
const GOLD_MULT := 1.5
const ASHEN_HP := 1.33
const PALE_MISS := 0.15
static var _cache := {}

## Maybe make the monster just spawned a variant (end of spawn_enemy).
static func maybe(g: GameState) -> void:
	g.enemy_variant = ""
	if g.enemy_is_boss or g.enemy_goblin or g.enemy_wanderer or g.enemy_grave or g.enemy_calamity > 0 or Portals.inside(g):
		return
	if g.floor_num < FROM_FLOOR or randf() * 100.0 >= CHANCE:
		return
	make(g, String(LIST.keys().pick_random()))

static func make(g: GameState, v: String) -> void:
	if g.enemy_variant != "":
		g.enemy_name = g.enemy_name.trim_prefix(g.enemy_variant + " ")  # one variant at a time
	g.enemy_variant = v
	g.enemy_name = "%s %s" % [v, g.enemy_name]
	if v == "Ashen":
		g.enemy_max_hp = int(g.enemy_max_hp * ASHEN_HP)
		g.enemy_hp = g.enemy_max_hp
	g.codex.add("variants_met")

## The variant's look of a texture: recolored toward its tint, keeping some of the original.
static func tex(t: Texture2D, v: String) -> Texture2D:
	if t == null or v == "" or not LIST.has(v):
		return t
	var key := "%d|%s" % [t.get_rid().get_id(), v]
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 600:
		_cache.clear()
	var src := t.get_image()
	if src == null:
		return t
	var img := src.duplicate() as Image  # never paint on the original monster's image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var tint := Color(String(LIST[v]["tint"]))
	var keep := float(LIST[v]["keep"])
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var l := c.get_luminance()
			var shaded := Color(tint.r * (0.25 + l * 1.1), tint.g * (0.25 + l * 1.1), tint.b * (0.25 + l * 1.1))
			var out := shaded.lerp(Color(c.r, c.g, c.b), keep)
			img.set_pixel(x, y, Color(minf(out.r, 1.0), minf(out.g, 1.0), minf(out.b, 1.0), c.a))
	var nt := ImageTexture.create_from_image(img)
	_cache[key] = nt
	return nt
