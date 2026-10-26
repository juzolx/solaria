class_name Pets
extends RefCounted
## Pictures of companions and owned pets.
## Pets 2 (Oct 24): every pet has its own baby art, true size (32x32), in
## art/pets/32/<key>.png plus a 2-frame idle strip <key>_idle.png (64x32):
##  - class companions: <class>_<stage> (4 growth stages of one creature),
##  - owned pets: the species id (Menagerie), Calamity pets calamity_N_pet,
##  - eggs: egg_<region id>.
## The old 68x68 companion art in art/pets/<class>_<stage>.png (tools/art_pets.py)
## is the fallback. Everything draws at true size (32 art px x the scene's pixel
## unit, 3x on a phone) with its feet (foot()) on the ground line.

const DIR := "res://art/pets/32/"

static var _cache := {}
static var _keys := {}   # art key -> {"a": still, "i": idle frames, "f": foot row, "w": white, "wd": used width}

## One cache entry per art key (no string building per frame: these run for every pet, every frame).
static func _e(key: String) -> Dictionary:
	var e: Dictionary = _keys.get(key, {})
	if e.is_empty():
		_keys[key] = e
	return e

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
	_keys.clear()

static func portrait(g: GameState) -> Texture2D:
	var st := World.pet_stage(g)
	if st < 0:
		return null
	return texture_for(g.hero_class, st)

## The still for an art key (species id, <class>_<stage>, egg_<region>), or null.
static func art(key: String) -> Texture2D:
	var e := _e(key)
	if not e.has("a"):
		e["a"] = DarkGrade.texture(DIR + key + ".png", DarkGrade.NATIVE) if key != "" else null  # palette-locked like the hd monsters: rim only
	return e["a"]

## The 2 idle frames for an art key ([] if it has none).
static func idle(key: String) -> Array:
	var e := _e(key)
	if not e.has("i"):
		var frames: Array = []
		var strip := DarkGrade.texture(DIR + key + "_idle.png", DarkGrade.NATIVE) if key != "" else null
		if strip != null:
			var w := strip.get_width() / 2
			for i in 2:
				var at := AtlasTexture.new()
				at.atlas = strip
				at.region = Rect2(i * w, 0, w, strip.get_height())
				frames.append(at)
		e["i"] = frames
	return e["i"]

## The class companion's idle frame at time t (seconds), or its still.
static func portrait_frame(g: GameState, t: float) -> Texture2D:
	var st := World.pet_stage(g)
	if st < 0:
		return null
	var fr := idle("%s_%d" % [g.hero_class.to_lower(), st])
	return fr[int(t * 1.6) % 2] if fr.size() == 2 else portrait(g)

## The class companion's art key (<class>_<stage>), or "" if none is out.
static func companion_key(g: GameState) -> String:
	var st := World.pet_stage(g)
	return "%s_%d" % [g.hero_class.to_lower(), st] if st >= 0 else ""

## The idle frame for an art key at time t (seconds), else its still (null if it has no art).
static func frame(key: String, t: float) -> Texture2D:
	var fr := idle(key)
	return fr[int(t * 1.6) % 2] if fr.size() == 2 else art(key)

## The row the pet's feet stand on (bottom of its used rect in the 32x32 still), or 31.
static func foot(key: String) -> int:
	var e := _e(key)
	if not e.has("f"):
		var r := _used(key)
		e["f"] = r.end.y - 1 if r.size.y > 0 else 31
	return e["f"]

## How wide the pet's body is in art px (its used rect in the still), or 32.
static func width(key: String) -> int:
	var e := _e(key)
	if not e.has("wd"):
		var r := _used(key)
		e["wd"] = r.size.x if r.size.x > 0 else 32
	return e["wd"]

static func _used(key: String) -> Rect2i:
	var tex := art(key)
	return tex.get_image().get_used_rect() if tex != null else Rect2i()

## A white silhouette of the still (cherished glow, met-but-not-owned in the Codex), or null.
static func white(key: String) -> Texture2D:
	var e := _e(key)
	if not e.has("w"):
		var tex := art(key)
		e["w"] = ImageTexture.create_from_image(Sprites._silhouette(tex.get_image())) if tex != null else null
	return e["w"]

## A region's egg (region id, GameData.ZONES[i]["id"]), or the shared egg icon.
static func egg(zone_id: String) -> Texture2D:
	var tex := art("egg_" + zone_id) if zone_id != "" else null
	return tex if tex != null else Sprites.consumable_icon("egg")

## Where a team of n creatures (each w wide) stands around a hero whose picture is canvas_w
## wide centred on cx, on a stage stage_w wide (Fable pets R2, the fight and the room): the
## left edge x of each, in order. The first takes the spot right of the hero, then they
## alternate left / right, one creature and a gap apart; a side that runs out of stage is
## squeezed so nobody leaves it. Pets may tuck a little behind the hero's legs, but a wide one
## in the first spot keeps clear of them (wide0). taken: [from, to] spans of party members'
## bodies; a creature whose middle lands inside one moves to its nearer edge (at most half
## behind a member: with two members out the stage can't fit everyone side by side).
static func row(n: int, cx: float, canvas_w: float, w: float, gap: float, stage_w: float, wide0 := false, taken: Array = []) -> Array:
	var half := canvas_w * (0.14 if wide0 else 0.08)
	var sides := [[], []]   # right, left: indexes into the result
	for k in n:
		sides[k % 2].append(k)
	var out: Array = []
	out.resize(n)
	var r0 := cx + half
	var rn: int = sides[0].size()
	var rstep := minf(w + gap, (stage_w - 6.0 - w - r0) / maxf(1.0, rn - 1))
	for j in rn:
		out[sides[0][j]] = clampf(r0 + j * rstep, 6.0, stage_w - 6.0 - w)
	var l0 := cx - half - w
	var ln: int = sides[1].size()
	var lstep := minf(w + gap, (l0 - 6.0) / maxf(1.0, ln - 1))
	for j in ln:
		out[sides[1][j]] = clampf(l0 - j * lstep, 6.0, stage_w - 6.0 - w)
	# a creature behind a member moves to that member's edge, the side that keeps it clear of
	# the others (pets stand in front of members, drawn over them: hiding each other is worse)
	for k in n:
		for sp in taken:
			var c: float = float(out[k]) + w / 2.0
			if c <= float(sp[0]) or c >= float(sp[1]):
				continue
			var best: float = out[k]
			var best_cover := _cover(best, w, sp)
			for edge in [float(sp[0]), float(sp[1])]:
				var x := clampf(edge - w / 2.0, 6.0, stage_w - 6.0 - w)
				var crowd := 0.0
				for o in n:
					if o != k:
						crowd = maxf(crowd, w - absf(x - float(out[o])))
				var cov := _cover(x, w, sp)
				if crowd <= w * 0.25 and cov < best_cover:
					best = x
					best_cover = cov
			out[k] = best
	return out

## How much of a creature at x (w wide) stands behind the span sp.
static func _cover(x: float, w: float, sp: Array) -> float:
	return maxf(0.0, minf(x + w, float(sp[1])) - maxf(x, float(sp[0])))
