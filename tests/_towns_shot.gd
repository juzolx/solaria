extends SceneTree
## Title screen with the town line, then the Towns picker. shots/towns
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.8).timeout
	var dir := TestHero.shots_dir("towns")
	root.get_texture().get_image().save_png(dir.path_join("title.png"))
	TownSelect.new().show_for(main)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(dir.path_join("towns.png"))
	print("TOWNS SHOT DONE town=", main.profile.town)
	quit()
