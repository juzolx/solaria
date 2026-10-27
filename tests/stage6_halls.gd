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

## The room's one thing for each kind (halls.gd PROP_NAMES), as the room view draws it: art, height.
const EVENTS := ["", "chest", "altar", "nest", "npc", "traveler", "merchant", "beast", "campfire", "rift", "camp", "gate"]
const EVENT_ART2D := {"chest": ["res://art/props/chest.png", 1.3], "altar": ["res://art/props/altar.png", 1.5],
	"nest": ["res://art/props/nest.png", 1.3], "npc": ["res://art/people/stranger.png", 1.4], "traveler": ["res://art/people/smith.png", 1.5],
	"beast": ["res://art/enemies/barghest.png", 1.3], "merchant": ["res://art/enemies/treasure_goblin.png", 1.4],
	"campfire": ["res://art/props/campfire.png", 1.1], "rift": ["res://art/halls/rift_0.png", 1.9]}

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

	# round 5 (a): an unread door's frame never wears a reader's colour (danger, safe, a fight)
	for z in 10:
		var uf := HallsScene.unread_frame(z)
		for c in HallsScene.READ_COLORS:
			check(ArtStyle.oklab(uf).distance_to(ArtStyle.oklab(c)) >= 0.15, "z%d: the unread frame %s looks like the read colour %s" % [z, uf.to_html(false), (c as Color).to_html(false)])
	# (f) neighbouring door glows never overlap (a safe and a danger glow would blend)
	check(Room3D.GLOW_W < float(HallsScene.DOOR_X[1]) - float(HallsScene.DOOR_X[0]) - 0.02, "door glows (%.2f wide) overlap their neighbours" % Room3D.GLOW_W)

	# every room of every zone, gate or not: props inside a phone's view, real art everywhere
	Room3D.offscreen.clear()
	Room3D.in_hero.clear()
	var names := {}
	var rooms_with_props := 0
	for z in 10:
		for s in 14:
			var r := Room3D.new()
			r.rebuild(z, 1000 + s * 7919, {"light": HallsScene.MOODS[z]["light"], "amb": HallsScene.ambient(z),
				"accent": HallsScene.MOODS[z]["accent"], "kind": HallsScene.MOODS[z]["kind"], "dark": 0.4, "gate": s % 3 == 0,
				"small": s % 2 == 1, "event": EVENTS[s % EVENTS.size()], "torch_z": Vector2(3.9, 3.9) if s % 2 == 1 else Vector2(4.6, 4.6)})
			# (d) round 5: far-wall torches clear the door frames and the labels, at the room's own layout
			var flay := Vector2(488, 345) if r.small else Vector2(488, 587)
			var fscr := 375.0 / 504.0 if r.small else 0.853
			var fcy := flay.y * (0.28 if r.small else 0.40)
			var ffo := 0.62 * flay.x
			var fp := func(x: float, y: float, zz: float) -> Vector2: return Vector2(flay.x / 2.0 + ffo * x / zz, fcy - ffo * y / zz)
			var lfont := UI.game_font()
			for n in r.root3.get_children():
				if not (n is Sprite3D) or (n as Sprite3D).position.z > -Room3D.RD + 0.2 or (n as Sprite3D).position.y < 0.5 or (n as Sprite3D).texture == null:
					continue
				var sp := n as Sprite3D
				var sz3 := -sp.position.z
				var hw := Room3D._half_w(sp.texture) * sp.pixel_size
				var bot3 := sp.position.y + HallsScene.FLOOR_Y   # the art's lowest opaque row sits on its spot
				var tl3: Vector2 = fp.call(sp.position.x - hw, bot3 + Room3D.base_height(sp.texture) * sp.pixel_size, sz3)
				var br3: Vector2 = fp.call(sp.position.x + hw, bot3, sz3)
				var trect := Rect2(tl3, br3 - tl3)
				for i in 3:
					var dx: float = HallsScene.DOOR_X[i]
					var fr := 2.0 * Room3D.FRAME_TEXEL
					var dtl: Vector2 = fp.call(dx - HallsScene.DOOR_W / 2.0 - fr, HallsScene.FLOOR_Y + HallsScene.DOOR_H + fr, HallsScene.D)
					var dbr: Vector2 = fp.call(dx + HallsScene.DOOR_W / 2.0 + fr, HallsScene.FLOOR_Y, HallsScene.D)
					check(not trect.intersects(Rect2(dtl, dbr - dtl)), "z%d %s (%s): a far torch at x %.2f is on door %d's frame" % [z, r.kind, "SE" if r.small else "430", sp.position.x, i])
					var lfs := mini(20, int(ceilf(16.0 / fscr)))
					var base_y := dtl.y + fr * ffo / HallsScene.D - 15.0 - (lfs if i == 1 and not r.small else 0)
					var lrect := Rect2(fp.call(dx, 0.0, HallsScene.D).x - HallsScene.LABEL_MAX_W / 2.0, base_y - lfont.get_ascent(lfs), HallsScene.LABEL_MAX_W, lfont.get_ascent(lfs) + lfont.get_descent(lfs))
					check(not trect.intersects(lrect), "z%d %s (%s): a far torch at x %.2f covers door %d's label" % [z, r.kind, "SE" if r.small else "430", sp.position.x, i])
			# (c, d) every standing prop clear of the doorways and the middle, none hiding another's base
			for i in r.standing.size():
				var a: Array = r.standing[i]
				check(Room3D.door_clear(a[0], a[1], a[2], a[3]), "z%d %s: %s at (%.2f, %.2f) stands in a doorway" % [z, r.kind, a[4], a[0], a[1]])
				check(absf(a[0]) - a[2] >= Room3D.CLEAR_X - 0.001, "z%d %s: %s at (%.2f, %.2f) stands in the middle" % [z, r.kind, a[4], a[0], a[1]])
				for j in range(i + 1, r.standing.size()):
					check(not Room3D.stacks(a, r.standing[j]), "z%d %s: %s (%.2f, %.2f) and %s (%.2f, %.2f) stack" % [z, r.kind, a[4], a[0], a[1], r.standing[j][4], r.standing[j][0], r.standing[j][1]])
			rooms_with_props += 1 if r.standing.size() >= 2 else 0
			# Juzo: a fight room's props never meet the face-off monster's box (Room3D.MONSTER_BOX),
			# checked on the drawn rect at the room's own layout (the 430 phone or the SE)
			if r.event in Room3D.FIGHT_EVENTS:
				var lay := Vector2(504, 443) if r.small else Vector2(504, 615)
				var cy := lay.y * (0.28 if r.small else 0.40)
				var fo := 0.62 * lay.x
				for a in r.standing:
					var ax: float = a[0]
					var az: float = a[1]
					var pr := Rect2(lay.x / 2.0 + fo * (ax - float(a[2])) / az, cy + fo * (-HallsScene.FLOOR_Y - float(a[3])) / az, fo * 2.0 * float(a[2]) / az, fo * float(a[3]) / az)
					check(not HallsScene.meets_monster(pr, lay), "z%d %s (%s, %s): %s at (%.2f, %.2f) meets the monster's box" % [z, r.kind, r.event, "SE" if r.small else "430", a[4], ax, az])
			# the fight's floor stays clear where a fight can happen (monsters never overlap props)
			if String(EVENTS[s % EVENTS.size()]) in Room3D.FIGHT_EVENTS:
				for sp in r.standing_props():
					var foot := Rect2(float(sp["x"]) - float(sp["w"]) / 2.0, float(sp["z"]) - 0.15, float(sp["w"]), 0.3)
					check(not foot.intersects(Room3D.FIGHT_CLEAR), "z%d %s: %s at (%.2f, %.2f) stands on the fight's floor" % [z, r.kind, sp["art"], sp["x"], sp["z"]])
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
					# only small things (candles, a skull, bones: under 0.5 tall) may stand nearer than 3.2
					var small_prop := Room3D.base_height((n as Sprite3D).texture) * (n as Sprite3D).pixel_size < 0.5
					check(nz >= 3.2 - 0.001 or small_prop, "z%d %s: %s stands at z %.2f, nearer than 3.2" % [z, r.kind, tn, nz])
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
	check(rooms_with_props >= 100, "most rooms still have dressing (%d of 140 have 2+ standing props)" % rooms_with_props)


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
	var scr := 375.0 / 504.0
	# round 5 (b, h): the SE's real room view is 488 wide and 345..443 tall (the hint box and log
	# under it change its height): 40+ px of floor over the hair always, 60+ when it's 443
	for sz_se in [Vector2(488, 345), Vector2(488, 419), Vector2(504, 443)]:
		se.size = sz_se
		se.scene.key = ""
		se.scene.build(hero, se.size, scr)
		var door_feet := se.scene.proj(0.0, HallsScene.FLOOR_Y, HallsScene.D).y
		var head := se.leader_head_y(scr)
		check(se.scene.small, "a %d px tall room view is a short screen" % int(sz_se.y * scr))
		var want := 60.0 if sz_se.y >= 443.0 else RoomView.FLOOR_GAP
		check(head - door_feet >= want, "SE %dx%d: %.0f design px between the hero's head (%.0f) and the door feet (%.0f), want %.0f" % [int(sz_se.x), int(sz_se.y), head - door_feet, head, door_feet, want])
		# the door labels' row stays on screen
		var dtop := se.scene.proj(0.0, HallsScene.FLOOR_Y + HallsScene.DOOR_H, HallsScene.D).y
		var lfs2: int = HallsScene.fit_label(UI.game_font(), "?", scr)[1]
		check(dtop - 15.0 - UI.game_font().get_ascent(lfs2) >= 0.0, "SE %dx%d: the door labels run off the top" % [int(sz_se.x), int(sz_se.y)])
	se.size = Vector2(504, 443)
	se.scene.key = ""
	se.scene.build(hero, se.size, scr)
	# 2D things in the room (the room's one thing, Snik, travelers) stand on their lowest opaque row
	for f in ["res://art/people/smith.png", "res://art/enemies/treasure_goblin.png", "res://art/props/chest.png", "res://art/people/stranger.png"]:
		var tx: Texture2D = load(f)
		for zz in [2.4, 3.6, 4.8]:
			var rc := se.scene.sprite_rect(tx, 0.6, zz, 1.4, scr)
			var k := rc.size.y / tx.get_height()
			var feet_y := (se.scene.proj(0.6, HallsScene.FLOOR_Y, zz) * scr).round().y / scr
			check(absf(rc.end.y - Room3D.base_pad(tx) * k - feet_y) < 0.01, "%s at z %.1f: base %.2f px off the floor" % [f.get_file(), zz, rc.end.y - Room3D.base_pad(tx) * k - feet_y])
	se.free()

	# round 4: the room view on the 430 phone and the SE
	var font := ThemeDB.fallback_font
	for geo in [[Vector2(504, 615), 0.853], [Vector2(504, 443), 375.0 / 504.0], [Vector2(488, 345), 375.0 / 504.0]]:
		var vsz: Vector2 = geo[0]
		var vs: float = geo[1]
		var rv2 := RoomView.new()
		rv2.state = hero
		rv2.size = vsz
		# the 2D decor (Low graphics) of fight rooms keeps off the monster's box too
		var keep_props: Array = hero.room_props
		var keep_room: int = hero.room_count
		hero.room_props = []
		var decor_seen := 0
		for rc in 60:
			hero.room_count = 100 + rc
			rv2.scene.key = ""
			rv2.scene.build(hero, vsz, vs)
			for dc in rv2.scene.decor:
				decor_seen += 1
				var dtx := rv2.scene.tx("res://art/dungeon/%s.png" % String(dc["art"]))
				var drc := rv2.scene.sprite_rect(dtx, float(dc["x"]), float(dc["z"]), float(dc["h"]), vs)
				var dsolid: Rect2 = rv2.scene.solid_rect(dtx, drc)
				check(dsolid.position.x >= 0.0 and dsolid.end.x <= vsz.x, "%dx%d room %d: 2D %s runs off the side" % [int(vsz.x), int(vsz.y), rc, dc["art"]])
				check(not HallsScene.meets_monster(drc, vsz), "%dx%d room %d: 2D %s at (%.2f, %.2f) meets the monster's box" % [int(vsz.x), int(vsz.y), rc, dc["art"], dc["x"], dc["z"]])
		check(decor_seen >= 8, "%dx%d: fight rooms still have some 2D decor (%d in 60)" % [int(vsz.x), int(vsz.y), decor_seen])
		hero.room_props = keep_props
		hero.room_count = keep_room
		rv2.scene.key = ""
		rv2.scene.build(hero, vsz, vs)
		var sc := rv2.scene
		var head2 := rv2.leader_head_y(vs)
		var hair := rv2.leader_half_w(vs)
		var tag := "%dx%d" % [int(vsz.x), int(vsz.y)]
		check(absf(HallsScene.floor_y(vsz, 5.2, vs) - sc.proj(0.0, HallsScene.FLOOR_Y, 5.2).y) < 0.01, "%s: floor_y matches the room's floor" % tag)
		# (a) the room's one thing in the middle stands with its base above the hero's hair
		var mz := rv2._prop_z(0.5, 0.5)
		check(sc.proj(0.0, HallsScene.FLOOR_Y, mz).y <= head2 - 6.0, "%s: a middle prop's base (y %.0f) is behind the hair (top %.0f)" % [tag, sc.proj(0.0, HallsScene.FLOOR_Y, mz).y, head2])
		# (e) the trap ring and the shrine glyph clear the hair by their edges
		var tz := rv2._trap_z()
		check(sc.proj(RoomView.TRAP_X - RoomView.TRAP_R, HallsScene.FLOOR_Y, tz).x >= sc.center.x + hair, "%s: the trap ring runs behind the hair" % tag)
		var gz := 4.0 if sc.small else Room3D.GLYPH.y
		check(sc.proj(Room3D.GLYPH.x + Room3D.TRAP_SIZE / 2.0, HallsScene.FLOOR_Y, gz).x <= sc.center.x - hair, "%s: the shrine glyph runs behind the hair" % tag)
		# (f) door labels clear the frame round their door
		for i in 3:
			var dx: float = HallsScene.DOOR_X[i]
			var tl := sc.proj(dx - HallsScene.DOOR_W / 2.0, HallsScene.FLOOR_Y + HallsScene.DOOR_H, HallsScene.D)
			var br := sc.proj(dx + HallsScene.DOOR_W / 2.0, HallsScene.FLOOR_Y, HallsScene.D)
			var drect := Rect2(tl, br - tl)
			for lab in ["?", "Monsters", "Wounded", "Trap: Treasure"]:
				var fit := HallsScene.fit_label(UI.game_font(), lab, vs)
				var fs: int = fit[1]
				var tw := UI.game_font().get_string_size(String(fit[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				check(tw <= HallsScene.LABEL_MAX_W, "%s: label %s is %.0f px wide" % [tag, lab, tw])
				check(fs * vs >= 13.5 or tw > HallsScene.LABEL_MAX_W - 12.0, "%s: label %s is %.1f screen px" % [tag, lab, fs * vs])
				var at := sc.door_label_at(drect, i, fs)
				var lrect := Rect2(drect.get_center().x - tw / 2.0, at.y - font.get_ascent(fs), tw, font.get_ascent(fs) + font.get_descent(fs))
				check(not lrect.intersects(drect.grow(8)), "%s: door %d's label touches its frame" % [tag, i])
		# (b, h) 2D things never cover a nearer standing 3D prop; the camp stays in view and near
		for ev in EVENTS:
			var r3 := Room3D.new()
			r3.rebuild(4, 4242 + ev.length() * 31, {"light": HallsScene.MOODS[4]["light"], "amb": HallsScene.ambient(4),
				"accent": HallsScene.MOODS[4]["accent"], "kind": "x", "dark": 0.4, "event": ev, "small": sc.small})
			var flat2d: Array = []   # [rect, depth, what]
			if ev == "camp":
				for piece in RoomView.camp_pieces(RoomView.CAMP.x, RoomView.CAMP.y):
					var tx: Texture2D = load("res://art/props/%s.png" % piece[0])
					var rc := sc.sprite_rect(tx, piece[1], piece[2], piece[3], vs)
					flat2d.append([rc, piece[2], piece[0]])
					var halfw := rc.size.x / 2.0 / (sc.focal / float(piece[2]))
					check(absf(piece[1]) + halfw * 0.9 <= Room3D.SEEN * float(piece[2]) and float(piece[2]) <= 3.45, "%s camp: %s at (%.1f, %.1f) out of view or too deep" % [tag, piece[0], piece[1], piece[2]])
			elif EVENT_ART2D.has(ev):
				var e: Array = EVENT_ART2D[ev]
				var ez := rv2._prop_z(0.5, 0.5)
				flat2d.append([sc.sprite_rect(load(e[0]), rv2._prop_x(0.5, ez), ez, e[1], vs), ez, ev])
			if ev == "merchant":
				var sx := rv2._prop_x(0.22, 2.6)
				flat2d.append([sc.sprite_rect(load("res://art/enemies/treasure_goblin.png"), sx, 2.6, 1.4, vs), 2.6, "Snik aside"])
			for f2 in flat2d:
				for st3 in r3.standing:
					if float(st3[1]) >= float(f2[1]):
						continue   # behind the 2D thing: it may cover it
					var a3 := sc.proj(float(st3[0]) - float(st3[2]), HallsScene.FLOOR_Y + float(st3[3]), float(st3[1]))
					var b3 := sc.proj(float(st3[0]) + float(st3[2]), HallsScene.FLOOR_Y, float(st3[1]))
					check(not (f2[0] as Rect2).intersects(Rect2(a3, b3 - a3)), "%s %s: the 2D %s (z %.1f) covers the nearer %s at (%.2f, %.2f)" % [tag, ev, f2[2], f2[1], st3[4], st3[0], st3[1]])
			r3.vp.free()
			r3.free()
		rv2.free()

	# the zone tiles come remapped (tools/hall_tiles_deep.gd), the same as the runtime remap
	for z in 10:
		for part in ["wall", "floor", "ceil"]:
			var src := "res://art/halls/z%d_%s.png" % [z, part]
			var baked := Image.load_from_file(ProjectSettings.globalize_path(src.get_basename() + "_deep.png"))
			var live := Room3D.tile_image(src, z)
			check(baked != null and live != null and baked.get_data() == live.get_data(), "z%d %s_deep.png is stale: re-run tools/hall_tiles_deep.gd" % [z, part])
	# the shared fx the room draws load as their files (a stale import showed the Shadow spell's
	# purple sheet as every prop's contact shadow)
	for fx in ["res://art/fx/shadow.png", "res://art/fx/glow.png"]:
		var disk := Image.load_from_file(ProjectSettings.globalize_path(fx))
		var tex: Texture2D = load(fx)
		var live := tex.get_image() if tex else null
		if disk and live:
			disk.convert(Image.FORMAT_RGBA8)
			live.convert(Image.FORMAT_RGBA8)
		var same := disk != null and live != null and disk.get_size() == live.get_size()
		if same:   # alpha everywhere, colour where it shows (the import rewrites hidden pixels' colour)
			for py in disk.get_height():
				for px in disk.get_width():
					var dc := disk.get_pixel(px, py)
					var lc := live.get_pixel(px, py)
					if absf(dc.a - lc.a) > 0.01 or (dc.a > 0.0 and Vector3(dc.r - lc.r, dc.g - lc.g, dc.b - lc.b).length() > 0.02):
						same = false
		check(same, "%s's import is stale: reimport (godot --headless --editor --quit)" % fx)
	check(names.size() >= 25, "rooms have their own names per zone (%d)" % names.size())
	print("STAGE6 HALLS TESTS DONE, failures: ", fails)
	quit()
