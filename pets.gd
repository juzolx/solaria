class_name Pets
extends RefCounted
## Pictures of companions and owned pets.
## Pets 2 (Oct 24): every pet has its own baby art, true size (32x32), in
## art/pets/32/<key>.png plus a 2-frame idle strip <key>_idle.png (64x32):
##  - class companions: <class>_<stage> (4 growth stages of one creature),
##  - owned pets: the species id (Menagerie), Calamity pets calamity_N_pet,
##  - eggs: egg_<region id>.
## The old 68x68 companion art in art/pets/<class>_<stage>.png (tools/art_pets.py)
## is the fallback. Drawn in the same 64-unit box the old 68x68 art used.

const DIR := "res://art/pets/32/"

static var _cache := {}

static func texture_for(cls: String, stage: int) -> Texture2D:
	var key := "%s_%d" % [cls.to_lower(), stage]
	if _cache.has(key):
		return _cache[key]
	var tex := art(key)
	if tex == null:
		tex = DarkGrade.texture("res://art/pets/%s.png" % key)
	_cache[key] = tex
	return tex

static func clear_cache() -> void:
	_cache.clear()

static func portrait(g: GameState) -> Texture2D:
	var st := World.pet_stage(g)
	if st < 0:
		return null
	return texture_for(g.hero_class, st)

## The still for an art key (species id, <class>_<stage>, egg_<region>), or null.
static func art(key: String) -> Texture2D:
	var k := "a|" + key
	if not _cache.has(k):
		_cache[k] = DarkGrade.texture(DIR + key + ".png") if key != "" else null
	return _cache[k]

## The 2 idle frames for an art key ([] if it has none).
static func idle(key: String) -> Array:
	var k := "i|" + key
	if not _cache.has(k):
		var frames: Array = []
		var strip := DarkGrade.texture(DIR + key + "_idle.png") if key != "" else null
		if strip != null:
			var w := strip.get_width() / 2
			for i in 2:
				var at := AtlasTexture.new()
				at.atlas = strip
				at.region = Rect2(i * w, 0, w, strip.get_height())
				frames.append(at)
		_cache[k] = frames
	return _cache[k]

## The class companion's idle frame at time t (seconds), or its still.
static func portrait_frame(g: GameState, t: float) -> Texture2D:
	var st := World.pet_stage(g)
	if st < 0:
		return null
	var fr := idle("%s_%d" % [g.hero_class.to_lower(), st])
	return fr[int(t * 1.6) % 2] if fr.size() == 2 else portrait(g)

## A region's egg (region id, GameData.ZONES[i]["id"]), or the shared egg icon.
static func egg(zone_id: String) -> Texture2D:
	var tex := art("egg_" + zone_id) if zone_id != "" else null
	return tex if tex != null else Sprites.consumable_icon("egg")
