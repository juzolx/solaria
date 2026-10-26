extends SceneTree
## Prints "height name width" for every pet still in art/pets/32 that is 24 px tall or less.
func _init() -> void:
	var rows: Array = []
	for f in DirAccess.get_files_at("res://art/pets/32"):
		if not f.ends_with(".png") or f.ends_with("_idle.png") or f.begins_with("egg_"):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art/pets/32/" + f))
		var r := img.get_used_rect()
		rows.append([r.size.y, f.get_basename(), r.size.x])
	rows.sort()
	for r in rows:
		if int(r[0]) <= 24:
			print("H %d %s %d" % [int(r[0]), String(r[1]), int(r[2])])
	quit()
