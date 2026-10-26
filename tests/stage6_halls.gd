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

func _colours(path: String) -> int:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return 0
	img.convert(Image.FORMAT_RGBA8)
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 > 0:
				seen[c.to_rgba32()] = true
	return seen.size()

## A team that reads doors at level 2, with a fight, a treasure room and an elite behind them.
func _reader() -> GameState:
	var g := GameState.new()
	g.doors = ["fight", "treasure", "elite"]
	g.ctrack["doors_read"] = Halls.READS_FOR_LEVEL_2
	return g

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
	# tiles with drawn stone, not a flat mottle (Fable round 2: the Hushwood floor had 2 colours)
	for z in 10:
		for part in ["wall", "floor"]:
			check(_colours("res://art/halls/z%d_%s.png" % [z, part]) >= 5, "zone %d %s has at least 5 colours" % [z, part])
	for f in ["z2_pool_0", "z2_pool_1", "z7_pipe", "z8_pillar"]:
		check(FileAccess.file_exists("res://art/halls/%s.png" % f), "%s.png exists" % f)

	# the backdrop on the phone's pixel grid: a 3-screen-px viewport pixel, like the sprites
	var probe := Room3D.new()
	probe.fit(Vector2(504, 560), 0.853)
	check(ArtStyle.unit(0.853) == 3 and probe.vp.size == Vector2i(144, 160), "fit(504x560, 0.853) is 144x160 whole 3-px pixels (%s)" % probe.vp.size)
	check(probe.drawn_size().x >= 504.0 and probe.drawn_size().x < 504.0 + 3.0 / 0.853 + 0.01, "the texture overhangs the view by less than a pixel")
	probe.vp.free()
	probe.free()

	# a prop standing in front of a door gets the tap (Snik over the middle door)
	var rv := RoomView.new()
	rv.hit = {"d1": Rect2(183, 235, 64, 115), "p0": Rect2(170, 250, 90, 130)}
	check(rv.pick(Vector2(215, 300)) == "p0", "a prop over a door wins the tap")
	check(rv.pick(Vector2(215, 240)) == "d1", "the door still takes taps above the prop")
	rv.free()

	# the room's own colours are palette colours (labels, glows, door reads)
	for f in ["res://room_view.gd", "res://halls_scene.gd", "res://room3d.gd"]:
		var src := FileAccess.get_file_as_string(f)
		var rx := RegEx.create_from_string('Color[(]"(#[0-9a-fA-F]{6})"')
		for m in rx.search_all(src):
			check(ArtStyle.in_palette(Color(m.get_string(1))) or ArtStyle.is_outline(Color(m.get_string(1))), "%s: %s is a palette colour" % [f.get_file(), m.get_string(1)])
	for d in [Halls.read_door(_reader(), 0), Halls.read_door(_reader(), 1), Halls.read_door(_reader(), 2)]:
		check(String(d["color"]) == "" or ArtStyle.in_palette(Color(String(d["color"]))), "door read colour %s is a palette colour" % d["color"])

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
					var base := (n as Sprite3D).texture.resource_path.get_file().get_basename() if (n as Sprite3D).texture else ""
					check(not base in Room3D.EVENT_ART and not base.ends_with("_chest") and not base.ends_with("_altar"), "z%d %s: %s is event art used as dressing" % [z, r.kind, base])
					var px := (n as Sprite3D).pixel_size
					check(is_equal_approx(px, Room3D.PX) or is_equal_approx(px, Room3D.DOOR_PX), "z%d %s: one pixel size (%f)" % [z, r.kind, px])
				if n is MeshInstance3D and (n as MeshInstance3D).mesh is QuadMesh:
					var mat := (n as MeshInstance3D).material_override as StandardMaterial3D
					if mat and mat.albedo_texture:
						var q := (n as MeshInstance3D).mesh as QuadMesh
						var ppx := q.size.x / (mat.albedo_texture.get_width() * mat.uv1_scale.x)
						check(is_equal_approx(ppx, Room3D.PX), "z%d %s: a flat at %f, not one pixel size" % [z, r.kind, ppx])
				if n is CPUParticles3D:
					check((n as CPUParticles3D).amount <= Room3D.MAX_PARTICLES, "z%d %s: particles capped" % [z, r.kind])
			check(lights <= 8, "z%d %s: %d lights" % [z, r.kind, lights])
			r.vp.free()
			r.free()
	check(Room3D.offscreen.is_empty(), "props a phone can't see: %s" % str(Room3D.offscreen.slice(0, 5)))
	check(names.size() >= 25, "rooms have their own names per zone (%d)" % names.size())
	print("STAGE6 HALLS TESTS DONE, failures: ", fails)
	quit()
