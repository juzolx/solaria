extends SceneTree
## 2.1 G1-G3: the town map with the Church and Trophy Cabin, the building bar,
## the Church with Cursed gear and the cabin, into shots/buildings.
const TestHero := preload("res://tests/test_hero.gd")

func _shot(main, n: String) -> void:
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("buildings").path_join(n + ".png"))

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
	var st: GameState = main.state
	st.gold = 50000
	st.scrap = 500
	st.dust = 100
	var it := GameData.make_item("Weapon", 3, 100, st._new_id())
	Church.curse(it)
	st.bag.append(it)
	var it2 := GameData.make_item("Chest", 2, 100, st._new_id())
	Church.curse(it2)
	it2["curse"]["known"] = true
	st.bag.append(it2)
	st.bag_version += 1
	Trophies.on_floor(st)
	Trophies.record(st, "boss:grendel", "boss", "Slew Grendel")
	Trophies.record(st, "calamity:0", "calamity", "Ended the Calamity Test")
	main.go_to_town(true)
	await create_timer(0.3).timeout
	main.refresh()
	main.town_view._scroll(-300)
	await _shot(main, "map_mid")
	main.town_view._scroll(-3000)
	await _shot(main, "map_low")
	for b in ["smith", "church", "cabin"]:
		main._on_building(b)
		main.refresh()
		await _shot(main, b)
	main.show_tab(1, 1)
	main.refresh()
	await _shot(main, "bag")
	print("BUILDINGS SHOTS DONE")
	quit()
