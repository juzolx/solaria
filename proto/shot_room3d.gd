extends SceneTree
## Renders every room type of the 3D room prototype: -- <out_prefix> [seed]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var seed_value := int(a[1]) if a.size() > 1 else 1
	var room: Control = (load("res://proto/room3d.tscn") as PackedScene).instantiate()
	root.add_child(room)
	for k in 5:
		room.call("rebuild", k, seed_value)
		for i in 20:
			await process_frame
		var path := "%s_%d.png" % [a[0], k]
		room.call("frame").save_png(path)
		print("shot ", path)
	quit()
