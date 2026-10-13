class_name Pets
extends RefCounted
## Pictures of companions. Each class's companion has 4 stages; the art is in
## art/pets/<class>_<stage>.png (made by tools/art_pets.py).

static var _cache := {}

static func texture_for(cls: String, stage: int) -> Texture2D:
	var key := "%s_%d" % [cls.to_lower(), stage]
	if _cache.has(key):
		return _cache[key]
	var path := "res://art/pets/%s.png" % key
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex

static func portrait(g: GameState) -> Texture2D:
	var st := World.pet_stage(g)
	if st < 0:
		return null
	return texture_for(g.hero_class, st)
