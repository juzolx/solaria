extends SceneTree
## The same room with the monster drawn three ways: -- <out_prefix> <kind> <seed>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var room: Control = (load("res://proto/room3d.tscn") as PackedScene).instantiate()
	root.add_child(room)
	await process_frame
	for mode in 3:
		room.set("monster_mode", mode)
		room.call("rebuild", int(a[1]), int(a[2]))
		for i in 20:
			await process_frame
		var path := "%s_%d.png" % [a[0], mode]
		room.call("frame").save_png(path)
		print("shot ", path)
	quit()
