extends SceneTree
## Holds the pointer on the Potion button: the tooltip should show, and letting go
## must not drink a potion. -- [out.png]
const TestHero := preload("res://tests/test_hero.gd")

func mouse(pos: Vector2, pressed: Variant) -> void:
	var e: InputEvent
	if pressed == null:
		var mm := InputEventMouseMotion.new()
		mm.position = pos
		mm.global_position = pos
		e = mm
	else:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = pressed
		mb.position = pos
		mb.global_position = pos
		e = mb
	Input.parse_input_event(e)

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
	main.state.hero_hp = int(main.state.get_max_hp() * 0.5)  # so the potion button is usable
	main.refresh()
	await create_timer(0.5).timeout
	var b: Button = main.potion_button
	var screen := root.get_final_transform() * (b.get_global_rect().get_center())
	var potions: int = main.state.potions
	mouse(screen, null)
	await create_timer(0.1).timeout
	mouse(screen, true)
	await create_timer(0.7).timeout
	var tip_up := false
	for n in root.get_children():
		if n is PanelContainer and (n as PanelContainer).top_level:
			tip_up = true
	var out := TestHero.shots_dir("feel").path_join("hold_tip.png")
	root.get_texture().get_image().save_png(out)
	mouse(screen, false)
	await create_timer(0.3).timeout
	print("HOLDTIP: tip shown %s | potions %d -> %d | button '%s' tooltip '%s'" % [tip_up, potions, main.state.potions, b.text, b.tooltip_text])
	quit()
