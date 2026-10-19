class_name OnlineUI
## Shared pieces for the Online tabs: the "not set up" card and the name picker.

## Shown when OnlineConfig is empty.
static func not_setup_card() -> PanelContainer:
	var card := UI.panel(UI.INSET, UI.BORDER, 10, 14, 1)
	var v := UI.vbox(8)
	card.add_child(v)
	var t := UI.rich(13)
	if OS.is_debug_build():
		# For whoever builds the game
		v.add_child(UI.label("Online isn't turned on yet", 16, UI.GOLD))
		t.text = "Leaderboards, guilds and raids need a free Supabase project. It takes about 5 minutes: follow [color=#e8b14a]ONLINE_SETUP.md[/color] in the game folder, then paste your project URL and key into [color=#e8b14a]online_config.gd[/color]. Everything else works without it."
	else:
		v.add_child(UI.label("Coming soon", 16, UI.GOLD))
		t.text = "Leaderboards, guilds and weekly guild raids open in a later update: race other players to the deepest floor and fight raid bosses together. Everything else in the game works now."
	v.add_child(t)
	return card

## Asks for an online name, then calls on_done.
static func name_card(main, on_done: Callable) -> PanelContainer:
	var card := UI.panel(UI.INSET, UI.GOLD, 10, 14, 2)
	var v := UI.vbox(8)
	card.add_child(v)
	v.add_child(UI.label("Pick your online name", 16, UI.GOLD))
	v.add_child(UI.label("This is how other players see you on leaderboards and in guilds.", 12, UI.DIM))
	var row := UI.hbox(8)
	v.add_child(row)
	var field := LineEdit.new()
	field.placeholder_text = "3-16 letters"
	field.max_length = 16
	field.text = main.profile.player_name
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	var status := UI.label("", 12, UI.RED)
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
	var l := UI.label(text, 13, UI.RED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
