extends SceneTree
## Fable pets R2 item 10: no idle frame may end below the still's bottom row (a bob goes up
## from the ground, not through it). Floating pets whose frame 1 was the still moved down
## get the still moved up instead; any other frame that sinks moves up one row. In place.
## Run: godot --headless --path . -s claude/pets2/tools/idle_fix.gd
const DIR := "res://art/pets/32/"

func _init() -> void:
	var fixed: Array = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with("_idle.png"):
			continue
		var key := f.trim_suffix("_idle.png")
		var still := Image.load_from_file(ProjectSettings.globalize_path(DIR + key + ".png"))
		var strip := Image.load_from_file(ProjectSettings.globalize_path(DIR + f))
		if still == null or strip == null:
			continue
		still.convert(Image.FORMAT_RGBA8)
		strip.convert(Image.FORMAT_RGBA8)
		var bottom := still.get_used_rect().end.y
		var changed := false
		for fi in 2:
			var fr := strip.get_region(Rect2i(fi * 32, 0, 32, 32))
			if fr.get_used_rect().end.y <= bottom:
				continue
			var down := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			down.blit_rect(still, Rect2i(0, 0, 32, 31), Vector2i(0, 1))
			var src := still if fr.get_data() == down.get_data() else fr
			var up := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			up.blit_rect(src, Rect2i(0, 1, 32, 31), Vector2i.ZERO)
			strip.fill_rect(Rect2i(fi * 32, 0, 32, 32), Color(0, 0, 0, 0))
			strip.blit_rect(up, Rect2i(0, 0, 32, 32), Vector2i(fi * 32, 0))
			changed = true
		if changed:
			strip.save_png(ProjectSettings.globalize_path(DIR + f))
			fixed.append(key)
	print("idle fixed %d: %s" % [fixed.size(), ", ".join(fixed)])
	quit()
