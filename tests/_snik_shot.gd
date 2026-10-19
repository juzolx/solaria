extends SceneTree
## Snik's stall after a haggle, into shots/snik.
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
	var st: GameState = main.state
	st._make_merchant()
	st.codex.add("merchant_buys", 16)
	MerchantPopup.new().show_for(main)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(TestHero.shots_dir("snik").path_join("stall.png"))
	print("SNIK SHOT DONE")
	quit()
