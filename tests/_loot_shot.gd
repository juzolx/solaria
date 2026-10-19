extends SceneTree
## Drops a few items of rising rarity in a fight and captures frames into shots/loot.
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
	var out := TestHero.shots_dir("loot")
	var ev: Array[Dictionary] = []
	var slots := ["Weapon", "Helmet", "Chest", "Legs", "Feet"]
	for r in [0, 1, 2, 3, 4]:
		var it: Dictionary = GameData.make_item(slots[r], r, 30, 9000 + r)
		ev.append({"type": "loot", "name": GameData.display_name(it), "rarity": r, "item": it})
	main.battle.play(ev)
	for k in 6:
		await create_timer(0.3).timeout
		root.get_texture().get_image().save_png(out.path_join("loot_%d.png" % k))
	print("LOOT SHOTS DONE ", main.battle.drops.size())
	quit()
