extends SceneTree

func shot(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("/root/shot_%s.png" % name)

func _initialize() -> void:
	seed(7)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	var s: GameState = main.state
	for i in 140:
		s.take_turn()
		s.messages.clear()
		s.events.clear()
		if i % 15 == 0:
			for item in s.bag.duplicate():
				var cur := 0
				if s.equipped.has(item["slot"]):
					cur = GameData.item_power(s.equipped[item["slot"]])
				if GameData.item_power(item) > cur:
					s.equip(int(item["id"]))
	s.scrap += 60
	s.bag.append(GameData.make_unique(GameData.ZONES[3]["boss"]["uniques"][0], 10, 9999))
	s.bag_version += 1
	main.battle.last_floor = s.floor_num
	main._refresh()

	# 1: mid-fight on the Gear tab, with damage numbers flying
	main.tabs.current_tab = 0
	main._on_tick()
	await create_timer(0.12).timeout
	shot("gear")

	# 2: tap the Weapon slot -> bag filtered to weapons
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	main._on_card_input(ev, "Weapon")
	main._on_tick()
	await create_timer(0.45).timeout
	shot("bag_weapon")

	# 3: a boss on the Shadow Deep floor
	s.floor_num = 50
	s.fight = 1
	s.spawn_enemy()
	main.battle.last_floor = 49
	main._refresh()
	await create_timer(0.3).timeout
	shot("boss")

	# 4: every creature, one per frame, to check the pixel art
	for z in GameData.ZONES.size():
		s.floor_num = z * 10 + 1
		var zone: Dictionary = GameData.ZONES[z]
		var creatures: Array = zone["enemies"]
		var c: Dictionary = creatures[0]
		s.enemy_shape = c["shape"]
		s.enemy_color = c["color"]
		s.enemy_name = c["name"]
		s.enemy_is_boss = false
		main.battle.last_floor = s.floor_num
		main._refresh()
		await create_timer(0.1).timeout
		shot("zone%d" % z)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	quit()
