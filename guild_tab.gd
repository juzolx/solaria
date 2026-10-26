class_name GuildTab
extends ScrollContainer
## Online > Guild: make or join a guild (up to 20 players), see your members
## and the guild rankings.

var main
var box: VBoxContainer
var loaded_at := -100000
var loading := false
var guild = null  # your guild row, or null

func setup(m) -> void:
	main = m
	name = "Guild"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	if Time.get_ticks_msec() - loaded_at > 60000 and not loading:
		_load()

func reload() -> void:
	loaded_at = -100000
	loading = false
	refresh()

func _best() -> int:
	return main.state.best_floor

func _load() -> void:
	loading = true
	loaded_at = Time.get_ticks_msec()
	OnlineUI.clear(box)
	var online: Online = main.online
	if not online.is_configured():
		box.add_child(OnlineUI.not_setup_card())
		loading = false
		return
	if not online.has_name():
		box.add_child(OnlineUI.name_card(main, reload))
		loading = false
		return
	box.add_child(UI.label("Loading...", UI.FONT_BODY, UI.DIM))
	var r: Dictionary = await online.my_guild()
	OnlineUI.clear(box)
	if not r["ok"]:
		box.add_child(OnlineUI.error_label(r["error"]))
		box.add_child(UI.button("Try again", reload))
		loading = false
		return
	guild = r["data"]
	if guild == null:
		_no_guild()
	else:
		online.update_best(_best())
		await _my_guild()
	await _rankings()
	loading = false

func _no_guild() -> void:
	box.add_child(UI.label("You're not in a guild", 18, UI.GOLD))
	box.add_child(UI.label("Guilds fight a raid boss together every week and climb the guild rankings. Up to %d players." % Online.GUILD_MAX, UI.FONT_BODY, UI.DIM))

	# Make one
	var make := UI.panel(UI.INSET, UI.BORDER, 10, 12, 1)
	box.add_child(make)
	var mv := UI.vbox(8)
	make.add_child(mv)
	mv.add_child(UI.label("Start a guild", 15, UI.TEXT))
	var row := UI.hbox(8)
	mv.add_child(row)
	var gname := LineEdit.new()
	gname.placeholder_text = "Guild name (3-24)"
	gname.max_length = 24
	gname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gname)
	var tag := LineEdit.new()
	tag.placeholder_text = "TAG"
	tag.max_length = 4
	tag.custom_minimum_size = Vector2(70, 0)
	row.add_child(tag)
	var status := UI.label("", UI.FONT_BODY, UI.RED)
	var go := UI.primary("Create", func(): pass)
	go.pressed.connect(func():
		go.disabled = true
		var r: Dictionary = await main.online.create_guild(gname.text, tag.text, _best())
		go.disabled = false
		if r["ok"]:
			main.sfx.play("level_up")
			reload()
		else:
			status.text = r["error"])
	row.add_child(go)
	mv.add_child(status)

	# Find one
	var find := UI.panel(UI.INSET, UI.BORDER, 10, 12, 1)
	box.add_child(find)
	var fv := UI.vbox(8)
	find.add_child(fv)
	fv.add_child(UI.label("Join a guild", 15, UI.TEXT))
	var srow := UI.hbox(8)
	fv.add_child(srow)
	var search := LineEdit.new()
	search.placeholder_text = "Search by name (or leave empty)"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(search)
	var results := UI.vbox(6)
	var do_search := func():
		OnlineUI.clear(results)
		results.add_child(UI.label("Searching...", UI.FONT_BODY, UI.DIM))
		var r: Dictionary = await main.online.list_guilds(search.text)
		OnlineUI.clear(results)
		if not r["ok"]:
			results.add_child(OnlineUI.error_label(r["error"]))
			return
		if (r["data"] as Array).is_empty():
			results.add_child(UI.label("No guilds found. Start one!", UI.FONT_BODY, UI.DIM))
		for g in r["data"]:
			results.add_child(_guild_row(g, true))
	srow.add_child(UI.button("Search", do_search))
	search.text_submitted.connect(func(_t): do_search.call())
	fv.add_child(results)
	do_search.call()

func _guild_row(g: Dictionary, joinable: bool) -> HBoxContainer:
	var row := UI.hbox(8)
	var t := UI.rich(UI.FONT_BODY)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.text = "[color=#e8b14a][%s][/color] %s  [color=%s]%d/%d members  -  power %d[/color]" % [
		g["tag"], g["name"], UI.hex(UI.DIM), int(g["members"]), Online.GUILD_MAX, int(g["power"])]
	row.add_child(t)
	if joinable:
		var full := int(g["members"]) >= Online.GUILD_MAX
		var b := UI.button("Full" if full else "Join", func():
			var r: Dictionary = await main.online.join_guild(int(g["id"]), _best())
			if r["ok"]:
				main.sfx.play("buy")
				reload()
			else:
				main.confirm("Couldn't join", r["error"], "OK", func(): pass))
		b.disabled = full
		row.add_child(b)
	return row

func _my_guild() -> void:
	var head := UI.hbox(8)
	box.add_child(head)
	var t := UI.label("[%s] %s" % [guild["tag"], guild["name"]], 20, UI.GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("Refresh", reload))
	var leave := UI.button("Leave", func():
		main.confirm("Leave your guild?", "You can join another one any time. If you're the last member, the guild is closed.", "Leave", func():
			await main.online.leave_guild()
			reload()))
	leave.add_theme_color_override("font_color", UI.RED)
	head.add_child(leave)
	box.add_child(UI.label("Go to the Raid tab to hit this week's raid boss with your guild.", UI.FONT_BODY, UI.DIM))

	box.add_child(UI.heading("Members"))
	var r: Dictionary = await main.online.guild_members(int(guild["id"]))
	if not r["ok"]:
		box.add_child(OnlineUI.error_label(r["error"]))
		return
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for h in ["Player", "Best floor", ""]:
		grid.add_child(UI.label(h, UI.FONT_BODY, UI.DIM))
	for m in r["data"]:
		var me: bool = m["player_id"] == main.online.user_id()
		var n := UI.label(str(m["name"]), UI.FONT_BODY, UI.GOLD if me else UI.TEXT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(n)
		grid.add_child(UI.label(str(int(m["best_floor"])), UI.FONT_BODY, UI.TEXT))
		grid.add_child(UI.label("Leader" if m["player_id"] == guild["leader"] else "", UI.FONT_BODY, UI.GOLD))

func _rankings() -> void:
	box.add_child(UI.heading("Guild rankings  (power = members' best floors added up)"))
	var r: Dictionary = await main.online.guild_rankings()
	if not r["ok"]:
		box.add_child(OnlineUI.error_label(r["error"]))
		return
	var i := 0
	for g in r["data"]:
		i += 1
		var row := _guild_row(g, false)
		var rank := UI.label("%d." % i, UI.FONT_BODY, UI.DIM)
		rank.custom_minimum_size = Vector2(28, 0)
		row.add_child(rank)
		row.move_child(rank, 0)
		box.add_child(row)
		if guild != null and int(g["id"]) == int(guild["id"]):
			(row.get_child(1) as RichTextLabel).text = "[b]" + (row.get_child(1) as RichTextLabel).text + "[/b]  [color=#4ade80](you)[/color]"
