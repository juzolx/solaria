class_name OnlineUI
## Shared pieces for the Online tabs: the "not set up" card and the name picker.

## Shown when OnlineConfig is empty.
static func not_setup_card() -> PanelContainer:
	var card := UI.panel(UI.INSET, UI.BORDER, 10, 14, 1)
	var v := UI.vbox(8)
	card.add_child(v)
	# Fable r2 #1: players (and every picture of the game) see the plain line; the setup steps
	# for whoever builds the game are one quiet line under it in a debug build only
	var t := UI.rich(UI.FONT_BODY)
	v.add_child(UI.heading("Online"))
	t.text = "Online play is not available in this version. Everything else works."
	v.add_child(t)
	if OS.is_debug_build():
		v.add_child(UI.wrap("Builders: see ONLINE_SETUP.md.", UI.FONT_BODY, UI.DIM))
	return card

## Asks for an online name, then calls on_done.
static func name_card(main, on_done: Callable) -> PanelContainer:
	var card := UI.panel(UI.INSET, UI.GOLD, 10, 14, 2)
	var v := UI.vbox(8)
	card.add_child(v)
	v.add_child(UI.heading("Your online name"))
	v.add_child(UI.label("This is how other players see you on leaderboards and in guilds.", UI.FONT_BODY, UI.DIM))
	var row := UI.hbox(8)
	v.add_child(row)
	var field := LineEdit.new()
	field.placeholder_text = "3-16 letters"
	field.max_length = 16
	field.text = main.profile.player_name
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	var status := UI.label("", UI.FONT_BODY, UI.RED)
	var go := UI.primary("Save name", func(): pass)
	go.pressed.connect(func():
		go.disabled = true
		status.text = "Saving..."
		status.add_theme_color_override("font_color", UI.DIM)
		var r: Dictionary = await main.online.register_name(field.text)
		go.disabled = false
		if r["ok"]:
			on_done.call()
		else:
			status.text = r["error"]
			status.add_theme_color_override("font_color", UI.RED))
	row.add_child(go)
	v.add_child(status)
	return card

static func clear(box: Node) -> void:
	for c in box.get_children():
		c.queue_free()

static func error_label(text: String) -> Label:
	var l := UI.label(text, UI.FONT_BODY, UI.RED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
