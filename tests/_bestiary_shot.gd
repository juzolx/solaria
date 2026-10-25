extends SceneTree
## Fable r1: the Bestiary plate (whole screen pixels per art pixel) and list icons at phone size.
##   godot --path . --resolution 430x932 -s tests/_bestiary_shot.gd -> shots/monsters/bestiary/
const TestHero := preload("res://tests/test_hero.gd")
func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var cx: Codex = main.codex
	var ids: Array = Collections.zone_monsters("mossy_hollows")
	for i in ids.size() - 3:
		cx.entry(ids[i])["kills"] = 12
	cx.entry("grendel")["kills"] = 1
	main.state._check_codex()
	main.show_tab(3, 0)
	var dir := TestHero.shots_dir("monsters/bestiary")
	for id in ["kobold", "grendel", ids[ids.size() - 2]]:
		main.bestiary_tab.selected = id
		main.bestiary_tab.shown = ""
		main.refresh()
		await create_timer(0.6).timeout
		root.get_texture().get_image().save_png(dir.path_join(String(id) + ".png"))
	quit()
