extends SceneTree
## Dry run: start the game on copied real saves (test dir) and report the towns.
func _initialize() -> void:
	if ProjectSettings.globalize_path("user://").find("solaria_claude_test") < 0:
		quit(1)
		return
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var p: Profile = main.profile
	print("PROBE town=", p.town, " v1=", p.towns_v1)
	for t in range(1, 4):
		GameState.town = t
		var m := GameState.slot_meta(1)
		print("PROBE town ", t, " ", p.town_name(t), " heroes=", GameState.town_heroes(t), " slot1=", m.get("name", "?"), " lv", m.get("level", 0), " best=", p.towns.get(str(t), {}).get("max_floor", -1), " book=", p.towns.get(str(t), {}).get("skill_book", {}).size(), " stash=", p.towns.get(str(t), {}).get("stash", []).size())
	quit()
