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
	# (round 3) hall tiles as the room draws them are not mostly outline black
	for z in 10:
		for part in ["wall", "floor", "ceil"]:
			var img := Room3D.tile_image("res://art/halls/z%d_%s.png" % [z, part], z)
			var black := 0
			for y in img.get_height():
				for x in img.get_width():
					if ArtStyle.is_outline(img.get_pixel(x, y)):
						black += 1
			var share := float(black) / float(img.get_width() * img.get_height())
			check(share <= 0.4, "zone %d %s is %d%% outline black as drawn" % [z, part, int(share * 100.0)])

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
	Room3D.in_hero.clear()
	var names := {}
	for z in 10:
		for s in 14:
			var r := Room3D.new()
			r.rebuild(z, 1000 + s * 7919, {"light": HallsScene.MOODS[z]["light"], "amb": HallsScene.ambient(z),
				"accent": HallsScene.MOODS[z]["accent"], "kind": HallsScene.MOODS[z]["kind"], "dark": 0.4, "gate": s % 3 == 0})
			names[r.kind] = true
			var lights := 0
			var meshes := 0
			var mats := {}
			for n in r.world.find_children("*", "", true, false):
				if n is MeshInstance3D:
					meshes += 1
					if (n as MeshInstance3D).material_override:
						mats[(n as MeshInstance3D).material_override.get_instance_id()] = true
				if n is CSGShape3D and (n as Object).get("material"):
					mats[(n as Object).get("material").get_instance_id()] = true
				if n is Sprite3D and (n as Sprite3D).texture and (n as Sprite3D).texture.resource_path.get_file().ends_with("door.png"):
					var dm := (n as Sprite3D).modulate
					check(minf(dm.r, minf(dm.g, dm.b)) >= 0.8, "z%d %s: a door dimmed to %s" % [z, r.kind, dm])
				if n is Sprite3D and (n as Sprite3D).texture and (n as Sprite3D).position.y < 0.01:
					# grounded: the art's lowest opaque row lands on the floor plane (y = 0), with a shadow
					var sp := n as Sprite3D
					var base := sp.position.y + (sp.offset.y - sp.texture.get_height() / 2.0 + Room3D.base_pad(sp.texture)) * sp.pixel_size
					check(absf(base) < 0.001, "z%d %s: %s's base is %.3f off the floor" % [z, r.kind, sp.texture.resource_path.get_file(), base])
				if n is Sprite3D and (n as Sprite3D).texture and (n as Sprite3D).billboard != BaseMaterial3D.BILLBOARD_DISABLED:
					var nz := -(n as Sprite3D).position.z
					var tn := (n as Sprite3D).texture.resource_path.get_file()
					check(nz >= 3.2 - 0.001 or tn == "candles.png", "z%d %s: %s stands at z %.2f, nearer than 3.2" % [z, r.kind, tn, nz])
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
					if mat and mat.albedo_texture and mat.albedo_texture != Room3D.frame_tex():   # the door frame is on the viewport grid
						var q := (n as MeshInstance3D).mesh as QuadMesh
						var ppx := q.size.x / (mat.albedo_texture.get_width() * mat.uv1_scale.x)
						check(is_equal_approx(ppx, Room3D.PX), "z%d %s: a flat at %f, not one pixel size" % [z, r.kind, ppx])
				if n is CPUParticles3D:
					check((n as CPUParticles3D).amount <= Room3D.MAX_PARTICLES, "z%d %s: particles capped" % [z, r.kind])
			var standing := 0
			var shadows := 0
			for n in r.world.find_children("*", "", true, false):
				if n is Sprite3D and (n as Sprite3D).position.y < 0.01 and (n as Sprite3D).billboard != BaseMaterial3D.BILLBOARD_DISABLED:
					standing += 1
				if n is MeshInstance3D and (n as MeshInstance3D).material_override is StandardMaterial3D and ((n as MeshInstance3D).material_override as StandardMaterial3D).albedo_texture and ((n as MeshInstance3D).material_override as StandardMaterial3D).albedo_texture.resource_path.ends_with("shadow.png"):
					shadows += 1
			check(shadows == standing, "z%d %s: %d standing props, %d contact shadows" % [z, r.kind, standing, shadows])
			check(lights <= 8, "z%d %s: %d lights" % [z, r.kind, lights])
			check(meshes <= 60, "z%d %s: %d meshes (budget 60)" % [z, r.kind, meshes])
			check(mats.size() <= 30, "z%d %s: %d materials (budget 30)" % [z, r.kind, mats.size()])
			r.vp.free()
			r.free()
	check(Room3D.offscreen.is_empty(), "props a phone can't see: %s" % str(Room3D.offscreen.slice(0, 5)))
	check(Room3D.in_hero.is_empty(), "floor art under the hero: %s" % str(Room3D.in_hero.slice(0, 5)))


	# the layout follows the room's one thing: an altar always gets the shrine, nothing else does
	for z in [0, 4, 9]:
		for s in 6:
			for ev in ["altar", "nest", ""]:
				var r := Room3D.new()
				r.rebuild(z, 77 + s * 131, {"light": HallsScene.MOODS[z]["light"], "amb": HallsScene.ambient(z),
					"accent": HallsScene.MOODS[z]["accent"], "kind": HallsScene.MOODS[z]["kind"], "dark": 0.4, "event": ev})
				if ev == "altar":
					check(r.base_kind == "Forgotten shrine", "z%d: an altar in a %s" % [z, r.base_kind])
				elif ev == "nest":
					check(r.base_kind != "Forgotten shrine", "z%d: a nest in the shrine" % z)
				r.vp.free()
				r.free()

	# one room for every view: a fight and the room view of one state are one Room3D room
	var g := GameState.new()
	g.floor_num = 37
	g.room_count = 4
	g.room_props = [{"kind": "gate", "x": 0.5, "y": 0.5}]
	g.doors = ["fight", "treasure", "elite"]
	g.path_offer = ["door_l", "door_m", "door_r"]
	var a := HallsScene.new()
	var b := HallsScene.new()
	a.build(g, Vector2(504, 560), 0.853)
	b.build(g, Vector2(504, 330), 0.853)
	check(a.room_key == b.room_key and a.room_key != "", "the room and the fight show one room (%s / %s)" % [a.room_key, b.room_key])
	# the gate's middle door has one label: the gate's own
	check(a.door_label(g, 1) == "" and a.gate, "the champion's gate door carries no door read")

	# the SE: a 504x443 room view at 375 px wide keeps floor between the hero's head and the doors
	var se := RoomView.new()
	var hero := GameState.new()
	hero.appearance = {"body": "masc", "skin": 1, "hair": "Long", "hair_color": 0, "eyes": 4, "race": "Human"}
	hero.new_game()
	hero.choose_class("Warrior")
	se.state = hero
	se.size = Vector2(504, 443)
	var scr := 375.0 / 504.0
	se.scene.build(hero, se.size, scr)
	var door_feet := se.scene.proj(0.0, HallsScene.FLOOR_Y, HallsScene.D).y
	var head := se.leader_head_y(scr)
	check(se.scene.small, "a 330 px tall room view is a short screen")
	check(head - door_feet >= 60.0, "SE: %.0f design px between the hero's head (%.0f) and the door feet (%.0f)" % [head - door_feet, head, door_feet])
	# 2D things in the room (the room's one thing, Snik, travelers) stand on their lowest opaque row
	for f in ["res://art/people/smith.png", "res://art/enemies/treasure_goblin.png", "res://art/props/chest.png", "res://art/people/stranger.png"]:
		var tx: Texture2D = load(f)
		for zz in [2.4, 3.6, 4.8]:
			var rc := se.scene.sprite_rect(tx, 0.6, zz, 1.4, scr)
			var k := rc.size.y / tx.get_height()
			var feet_y := (se.scene.proj(0.6, HallsScene.FLOOR_Y, zz) * scr).round().y / scr
			check(absf(rc.end.y - Room3D.base_pad(tx) * k - feet_y) < 0.01, "%s at z %.1f: base %.2f px off the floor" % [f.get_file(), zz, rc.end.y - Room3D.base_pad(tx) * k - feet_y])
	se.free()
	check(names.size() >= 25, "rooms have their own names per zone (%d)" % names.size())
	print("STAGE6 HALLS TESTS DONE, failures: ", fails)
	quit()
