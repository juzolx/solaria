extends SceneTree
## Pets 2: prints every region's hatch pool (enemies + sub-area monsters) as
## zone|id|name|shape|color, the same pool Menagerie.hatch() draws from.
func _init() -> void:
	var gd = load("res://game_data.gd")
	for z in gd.ZONES:
		for e in z["enemies"]:
			print("POOL|%s|%s|%s|%s|%s" % [z["id"], e["id"], e["name"], e.get("shape", ""), e.get("color", "")])
		for s in z["subs"]:
			var m: Dictionary = s["monster"]
			print("POOL|%s|%s|%s|%s|%s" % [z["id"], m["id"], m["name"], m.get("shape", ""), m.get("color", "")])
	quit()
