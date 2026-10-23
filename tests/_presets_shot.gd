extends SceneTree
## 2.1: Loot filter, Auto-dive settings, Presets and the dive menu quick swap. shots/presets
const TestHero := preload("res://tests/test_hero.gd")

func _clear(main) -> void:
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()

func _shot(name: String) -> void:
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("presets").path_join(name + ".png"))

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(120)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	main.codex.stats["guide_skip"] = 1
	_clear(main)
	var st: GameState = main.state
	main.go_to_town(true)
	await create_timer(0.3).timeout
	_clear(main)
	LootFilter.new().show_for(main)
	await _shot("filter")
	_clear(main)
	AutoDivePanel.new().show_for(main)
	await _shot("autodive")
	_clear(main)
	Presets.save(st, 0, "Boss")
	Presets.save(st, 1, "Farming")
	PresetsScreen.new().show_for(main)
	await _shot("presets")
	_clear(main)
	FloorPicker.new().show_from_town(main)
	await _shot("dive")
	print("PRESETS SHOT DONE")
	quit()
