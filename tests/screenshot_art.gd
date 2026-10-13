extends SceneTree
## Renders the fight with the new sprites: geared heroes, every monster and boss.

var main

func shot(name: String, wait := 0.3) -> void:
	await create_timer(wait).timeout
	root.get_texture().get_image().save_png("/root/shots/%s.png" % name)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/root/shots")
	seed(3)
	GameState.delete_saves()
	Profile.delete()
	var prof := Profile.new()
	prof.last_mode = "regular"
	prof.save()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for c in main.get_children():
		if c is CharacterCreator:
			c._finish()
	await process_frame
	main._on_class_chosen("Warrior")
	for c in main.get_children():
		if c is Overlay:
			c.close()
	main.timer.stop()
	var s: GameState = main.state
	s.floor_num = 12
	s.best_floor = 12
	# Gear up
	var i := 0
	for slot in GameData.SLOT_ORDER:
		var item := GameData.make_item(slot, [1, 2, 3, 4, 2, 3][i], 12, 9000 + i)
		s.equipped[slot] = item
		i += 1
	s.spawn_enemy()
	main.battle.last_floor = s.floor_num
	main.refresh()
	await shot("art_00_hero")
	main._on_tick()
	await shot("art_01_swing", 0.12)

	# Different looks
	var looks := [
		{"body": "fem", "skin": 0, "hair": "Long", "hair_color": 3, "eyes": 1, "race": "Elf"},
		{"body": "masc", "skin": 4, "hair": "Spiky", "hair_color": 4, "eyes": 4, "race": "Demon"},
		{"body": "fem", "skin": 2, "hair": "Ponytail", "hair_color": 8, "eyes": 5, "race": "Fairy"},
		{"body": "masc", "skin": 1, "hair": "Bun", "hair_color": 5, "eyes": 0, "race": "Angel"},
	]
	var k := 0
	for app in looks:
		s.appearance = app
		var w := GameData.make_item("Weapon", 3, 12, 9100 + k)
		w["type"] = ["bow", "staff", "spear", "axe"][k]
		s.equipped["Weapon"] = w
		main.refresh()
		await shot("art_1%d_look" % k)
		k += 1

	# Every monster
	var n := 0
	for z in GameData.ZONES.size():
		for e in GameData.ZONES[z]["enemies"]:
			s.floor_num = z * 10 + 1
			s.enemy_name = e["name"]
			s.enemy_is_boss = false
			main.battle.last_floor = s.floor_num
			main.refresh()
			if n % 5 == 0:
				await shot("art_2%d_zone%d" % [z, z], 0.15)
			n += 1
		s.floor_num = z * 10 + 10
		s.spawn_enemy()
		main.battle.last_floor = s.floor_num
		main.refresh()
		await shot("art_3%d_boss" % z, 0.15)
	GameState.delete_saves()
	quit()
