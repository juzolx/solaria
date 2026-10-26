extends SceneTree
## The 3D halls (Fable dungeon review round 1): every zone has its full art set, doors and
## portals fit the arch, every room keeps its props where a phone can see them, and the
## zone colours come from one palette table (HallsScene.MOODS).
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		if fails <= 40:
			print("FAIL: ", m)

func _size(path: String) -> Vector2i:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return img.get_size() if img else Vector2i.ZERO

func _initialize() -> void:
	# every zone: wall, floor, ceiling, door and torch; doors on the one 32x56 canvas
	for z in 10:
		for part in ["wall", "floor", "ceil", "door", "torch"]:
			check(FileAccess.file_exists("res://art/halls/z%d_%s.png" % [z, part]), "zone %d has its %s" % [z, part])
		check(_size("res://art/halls/z%d_door.png" % z) == Vector2i(32, 56), "zone %d door is 32x56" % z)
		var tile := _size("res://art/halls/z%d_wall.png" % z)
		check(tile.x in [32, 64] and tile.x == tile.y, "zone %d wall is a 32 or 64 px square" % z)
	for f in ["door", "portal", "portal_1"]:
		check(_size("res://art/halls/%s.png" % f) == Vector2i(32, 56), "%s.png is 32x56" % f)
	for i in 3:
		check(_size("res://art/halls/rift_%d.png" % i) == Vector2i(48, 64), "rift frame %d is 48x64" % i)
	# a rune circle per trap, and the shrine's own glyph
	for k in Halls.TRAPS.keys():
		check(_size("res://art/traps/%s.png" % k) == Vector2i(64, 64), "trap %s has its 64x64 circle" % k)
	check(_size("res://art/traps/shrine.png") == Vector2i(64, 64), "the shrine has its own glyph")

	# one colour table: palette colours only, and GameData's zone colour is the accent
	for z in 10:
		var m: Dictionary = HallsScene.MOODS[z]
		for key in ["deep", "amb", "accent", "light"]:
			check(ArtStyle.in_palette(m[key]), "MOODS[%d] %s is a palette colour" % [z, key])
		check(Color(GameData.ZONES[z]["color"]).is_equal_approx(m["accent"]), "%s's colour is its accent" % GameData.ZONES[z]["name"])

	# every room of every zone, gate or not: props inside a phone's view, real art everywhere
	Room3D.offscreen.clear()
	var names := {}
	for z in 10:
		for s in 14:
			var r := Room3D.new()
			r.rebuild(z, 1000 + s * 7919, {"light": HallsScene.MOODS[z]["light"], "amb": HallsScene.ambient(z),
				"accent": HallsScene.MOODS[z]["accent"], "kind": HallsScene.MOODS[z]["kind"], "dark": 0.4, "gate": s % 3 == 0})
			names[r.kind] = true
			var lights := 0
			for n in r.world.find_children("*", "", true, false):
				if n is OmniLight3D:
					lights += 1
					check(not (n as OmniLight3D).shadow_enabled, "z%d %s: no shadow-casting lights" % [z, r.kind])
				if n is Sprite3D:
					check((n as Sprite3D).texture != null, "z%d %s: a sprite with no art" % [z, r.kind])
					var px := (n as Sprite3D).pixel_size
					check(is_equal_approx(px, Room3D.PX) or is_equal_approx(px, Room3D.DOOR_PX), "z%d %s: one pixel size (%f)" % [z, r.kind, px])
				if n is CPUParticles3D:
					check((n as CPUParticles3D).amount <= Room3D.MAX_PARTICLES, "z%d %s: particles capped" % [z, r.kind])
			check(lights <= 8, "z%d %s: %d lights" % [z, r.kind, lights])
			r.vp.free()
			r.free()
	check(Room3D.offscreen.is_empty(), "props a phone can't see: %s" % str(Room3D.offscreen.slice(0, 5)))
	check(names.size() >= 25, "rooms have their own names per zone (%d)" % names.size())
	print("STAGE6 HALLS TESTS DONE, failures: ", fails)
	quit()
