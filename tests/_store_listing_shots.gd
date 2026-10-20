extends SceneTree
## App Store screenshots (6.9" iPhone: 1320x2868) into shots/store_listing.
## Renders at a third of that size and scales up 3x (pixel art stays crisp):
## godot --path . --resolution 440x956 -s tests/_store_listing_shots.gd
const TestHero := preload("res://tests/test_hero.gd")
const SIZE := Vector2i(1320, 2868)

var out := ""

func shot(label: String) -> void:
	await create_timer(0.8).timeout
	var img := root.get_texture().get_image()
	var f := maxi(1, SIZE.x / img.get_width())
	if f > 1:
		img.resize(img.get_width() * f, img.get_height() * f, Image.INTERPOLATE_NEAREST)
	if img.get_size() != SIZE:
		var full := Image.create(SIZE.x, SIZE.y, false, img.get_format())
		full.fill(Color("#0b0a1d"))
		full.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size().min(SIZE)), Vector2i.ZERO)
		img = full
	img.convert(Image.FORMAT_RGB8)  # the App Store refuses transparency
	img.save_png(out.path_join(label + ".png"))
	print("shot %s %s" % [label, img.get_size()])

func clear(main: Node) -> void:
	for c in main.get_children():
		if c is Overlay or c is Moments:
			c.queue_free()
	await process_frame

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	out = TestHero.shots_dir("store_listing")
	seed(11)
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	await clear(main)
	for i in 6:
		main._on_tick()
		await create_timer(0.25).timeout
	await clear(main)
	await shot("1_fight")
	main.show_tab(1, 0)
	main.refresh()
	await shot("2_gear")
	main.go_to_town(true)
	await create_timer(0.4).timeout
	await clear(main)
	await shot("3_town")
	main.show_tab(3, 0)
	main.refresh()
	await shot("4_codex")
	main.show_tab(0, 0)
	main.refresh()
	await shot("5_hero")
	print("STORE LISTING SHOTS DONE")
	quit()
