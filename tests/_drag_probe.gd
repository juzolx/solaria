extends SceneTree
## Real mouse drags: bag item -> doll slot (equip), skill card -> slot. Prints results.
const TestHero := preload("res://tests/test_hero.gd")
var vp: Viewport

func _drag(from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	down.global_position = from
	vp.push_input(down, true)
	await process_frame
	for i in range(1, 13):
		var mv := InputEventMouseMotion.new()
		mv.position = from.lerp(to, i / 12.0)
		mv.global_position = mv.position
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		mv.relative = (to - from) / 12.0
		vp.push_input(mv, true)
		await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	up.global_position = to
	vp.push_input(up, true)
	await process_frame
	await process_frame

func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	vp = root
	await process_frame
	main.timer.stop()
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	var st: GameState = main.state
	var it := GameData.make_item("Helmet", 3, 30, st._new_id())
	st.bag.append(it)
	st.bag_version += 1
	main.show_tab(1, 0)
	main.gear_tab.slot = "Helmet"
	main.gear_tab.shown = ""
	main.refresh()
	await create_timer(0.4).timeout
	var cell: Control = null
	for c in main.gear_tab.item_grid.get_children():
		if c is Button and not c.is_queued_for_deletion():
			cell = c
	var card: Control = main.gear_tab.slot_pics["Helmet"].get_parent().get_parent()
	await _drag(_center(cell), _center(card))
	print("DRAG gear equip: ", st.equipped.has("Helmet") and int(st.equipped["Helmet"]["id"]) == int(it["id"]))
	# skills: drop the first owned skill card onto the first active slot
	main.show_tab(0, 3)
	main.skills_tab.shown = ""
	main.refresh()
	await create_timer(0.4).timeout
	var target_id := ""
	var src: Control = null
	for b in main.skills_tab.cards.get_children():
		pass
	for id in st.skill_book:
		if SkillData.is_active(id) and not st.is_skill_equipped(id) and st.skill_rank(id) > 0:
			target_id = id
			break
	if target_id == "":
		for id in SkillData.SKILLS:
			if SkillData.is_active(id) and not st.is_skill_equipped(id):
				st.skill_book[id] = 1
				target_id = id
				break
		main.skills_tab.shown = ""
		main.refresh()
		await create_timer(0.3).timeout
	var i := 0
	for id in main.skills_tab.ids:
		if id == target_id:
			src = main.skills_tab.cards.get_child(i)
		i += 1
	var slot_b: Control = main.skills_tab.slot_row_a.get_child(0)
	await _drag(_center(src), _center(slot_b))
	print("DRAG skill equip: ", st.active_slots[0] == target_id, " (", target_id, ")")
	quit()
