extends SceneTree
## A boss entrance frame by frame into shots/boss.
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
	var out := TestHero.shots_dir("boss")
	var st: GameState = main.state
	var f := st.floor_num
	while not GameData.is_boss_floor(f):
		f += 1
	st.floor_num = f
	st.spawn_enemy()
	main.refresh()
	print("boss? ", st.enemy_is_boss, " ", st.enemy_name)
	for k in 7:
		await create_timer(0.35).timeout
		root.get_texture().get_image().save_png(out.path_join("boss_%d.png" % k))
	print("busy at end: ", main.battle.busy())
	print("BOSS SHOTS DONE")
	quit()
