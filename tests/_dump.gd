extends SceneTree
func _initialize() -> void:
	for cls in Classes.ORDER:
		for id in ClassTree.all_nodes():
			var n: Dictionary = ClassTree.node(id)
			if n["cls"] != cls or n["branch"]:
				continue
			print("%s|%d|%s|%s|%s|%s|%s" % [cls, n["tier"], n["name"], ClassTree._main_key(n), str(n["focus"]), " ".join(n["tags"]), n["rank"]])
	quit()
