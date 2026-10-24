extends SceneTree
## 2.1 G9: the welcome card, What's New, the first town card, a coach card in a
## fight and the Class tab whispers. shots/onboard
const TestHero := preload("res://tests/test_hero.gd")

func _shot(dir: String, name: String) -> void:
	await create_timer(0.6).timeout
	root.get_texture().get_image().save_png(dir.path_join(name + ".png"))

func _clear(main) -> void:
	for c in main.get_children():
		if c is Overlay or c.is_in_group("coach"):
			c.queue_free()

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	var dir := TestHero.shots_dir("onboard")
	GameState.delete_saves()
	Profile.delete()
	Codex.delete()
	LoadingScreen.enabled = false
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _shot(dir, "1_welcome")
	_clear(main)
	WhatsNew.new().show_for(main)
	await _shot(dir, "2_whats_new")
	_clear(main)
	Onboarding.set_on(main.profile, true)
	FoundTown.new().show_for(main, 1)
	await _shot(dir, "3_found_town")
	main.queue_free()
	TestHero.make(30)
	var main2 = load("res://main.tscn").instantiate()
	root.add_child(main2)
	await create_timer(0.5).timeout
	for c in main2.get_children():
		if c is Overlay or c is TitleScreen:
			c.queue_free()
	main2.play_slot(1)
	await process_frame
	main2.timer.stop()
	_clear(main2)
	Onboarding.coach(main2, Onboarding.step("loot")["text"])
	await _shot(dir, "4_coach")
	_clear(main2)
	main2.show_tab(0, 1)
	main2.refresh()
	await _shot(dir, "5_class_tab")
	print("ONBOARD SHOT DONE")
	quit()
