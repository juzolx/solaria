extends SceneTree
## Screenshots every tab and sub-tab at phone size: -- <out_dir> <slot>

var out := ""
var n := 0

func shot(main: Node, name: String) -> void:
	await create_timer(0.6).timeout
	n += 1
	var path := "%s/%02d_%s.png" % [out, n, name.to_lower().replace(" ", "_").replace("/", "_")]
	root.get_texture().get_image().save_png(path)
	print("shot ", path)
	if main == null:
		return

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	seed(7)
	TitleScreen.pending = {"play": int(a[1])}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.timer.stop()
	for i in 4:
		main._on_tick()
		await create_timer(0.2).timeout
	# close the daily reward and any other popup that opened on load
	for c in main.get_children():
		if c is Overlay:
			c.queue_free()
	await process_frame
	if main.state.in_town:
		main._choose_floor()
		await shot(main, "floor_picker")
		for c in main.get_children():
			if c is Overlay:
				c.queue_free()
		main._leave_town()
		main.timer.stop()
		for i in 3:
			main._on_tick()
			await create_timer(0.3).timeout
	await shot(main, "fight")
	var group_names := ["character", "items", "town", "codex", "online"]
	for g in [0, 1, 3, 4]:
		var grp: TabContainer = main._groups()[g]
		for s in grp.get_tab_count():
			if grp.is_tab_hidden(s):
				continue
			main.show_tab(g, s)
			main.refresh()
			await shot(main, "%s_%s" % [group_names[g], grp.get_tab_title(s)])
	# The menu
	main.nav_page = 0
	main._apply_nav()
	var menu = SettingsMenu.new()
	menu.show_for(main)
	await shot(main, "menu")
	menu.queue_free()
	await process_frame
	# Town: the map, then each town tab
	if main.go_to_town():
		main.nav_page = 0
		main._apply_nav()
		main.refresh()
		await create_timer(1.0).timeout
		await shot(main, "town_map")
		var tg: TabContainer = main._groups()[2]
		for s in tg.get_tab_count():
			if tg.is_tab_hidden(s):
				continue
			main.show_tab(2, s)
			main.refresh()
			await shot(main, "town_%s" % tg.get_tab_title(s))
	quit()
