extends SceneTree
## 2.1 G4/G8: Codex > Rewards, Collection, Bestiary strip, Hero tab title + Share. shots/collect
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
	for id in Collections.zone_monsters("mossy_hollows"):
		cx.entry(id)["kills"] = 2
	for i in 4:
		cx.entry(Collections.zone_monsters("sunken_catacombs")[i])["kills"] = 1
	main.state._check_codex()
	main.refresh()
	await create_timer(0.8).timeout
	var dir := TestHero.shots_dir("collect")
	root.get_texture().get_image().save_png(dir.path_join("toast.png"))
	for pair in [[3, 6, "rewards"], [3, 1, "collection"], [3, 0, "bestiary"], [0, 0, "hero"]]:
		main.show_tab(pair[0], pair[1])
		main.refresh()
		await create_timer(0.5).timeout
		root.get_texture().get_image().save_png(dir.path_join(String(pair[2]) + ".png"))
	print("COLLECT SHOT DONE")
	quit()
