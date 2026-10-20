extends SceneTree
## Diagnostic: lists the deepest controls whose minimum width is wider than the phone layout.
## godot --path . --resolution 430x932 -s tests/_ui_width.gd
const TestHero := preload("res://tests/test_hero.gd")
var limit := 504.0

func walk(n: Node, depth: int) -> void:
	if not (n is Control):
		for c in n.get_children():
			walk(c, depth)
		return
	var w := (n as Control).get_combined_minimum_size().x
	if w <= limit:
		return
	var wide_child := false
	for c in n.get_children():
		if c is Control and (c as Control).get_combined_minimum_size().x > limit:
			wide_child = true
	if not wide_child:
		var txt := ""
		if n is Button or n is Label:
			txt = " \"%s\"" % str(n.get("text")).left(30)
		print("WIDE %.0f px: %s (%s)%s" % [w, n.get_path(), n.get_class(), txt])
	for c in n.get_children():
		walk(c, depth + 1)

func _initialize() -> void:
	if not TestHero.safe():
		quit(1)
		return
	TestHero.make(30)
	TitleScreen.pending = {"play": 1}
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	print("== fight screen")
	walk(main.ui_root, 0)
	main.state.return_scrolls = maxi(main.state.return_scrolls, 1)
	var _home := Town.use_return(main.state)
	if main.go_to_town(true):
		var tg: TabContainer = main._groups()[2]
		for s in tg.get_tab_count():
			if tg.is_tab_hidden(s):
				continue
			main.show_tab(2, s)
			main.refresh()
			await create_timer(0.3).timeout
			print("== town ", tg.get_tab_title(s))
			walk(main.ui_root, 0)
	quit()
