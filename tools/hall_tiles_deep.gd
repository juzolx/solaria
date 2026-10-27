extends SceneTree
## Writes art/halls/z<zone>_<wall|floor|ceil>_deep.png: each zone's hall tiles with the outline
## black (#0e0812) turned into the zone's deep colour (Room3D.tile_image), so a phone loads them
## instead of remapping pixels in GDScript on the first room of a zone (Fable dungeon round 4).
## Re-run after redrawing a hall tile or changing HallsScene.MOODS:
##   godot --headless --path . -s tools/hall_tiles_deep.gd

func _initialize() -> void:
	var n := 0
	for z in 10:
		for part in ["wall", "floor", "ceil"]:
			var src := "res://art/halls/z%d_%s.png" % [z, part]
			if not ResourceLoader.exists(src):
				continue
			var img := Room3D.tile_image(src, z)
			img.save_png(ProjectSettings.globalize_path(src.get_basename() + "_deep.png"))
			n += 1
	print("HALL TILES DEEP DONE: %d tiles" % n)
	quit()
