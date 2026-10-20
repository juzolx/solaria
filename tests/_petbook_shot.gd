extends SceneTree
## Codex > Pets page, then a first-find fanfare. shots/petbook
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
	var all := Monsters.all_monsters()
	for i in 14:
		cx.entry(all[i])["kills"] = 3
	cx.pet_book[all[0]] = 0
	cx.pet_book[all[3]] = 3
	cx.pet_book[all[5]] = 5
	main.show_tab(3, 5)
	main.refresh()
	await create_timer(0.6).timeout
	var dir := TestHero.shots_dir("petbook")
	root.get_texture().get_image().save_png(dir.path_join("book.png"))
	var u := GameData.make_unique(GameData.zone_uniques(0)[0], 10, main.state._new_id())
	main.state._note_find(u)
	main.refresh()
	await create_timer(1.4).timeout
	root.get_texture().get_image().save_png(dir.path_join("first.png"))
	print("PETBOOK SHOT DONE")
	quit()
