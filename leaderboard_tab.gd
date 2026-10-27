class_name LeaderboardTab
extends ScrollContainer
## Online › Leaders: the deepest Hardcore runs, online and your own.

var main
var box: VBoxContainer
var online_box: VBoxContainer
var board_head: Control   # the "Deepest Hardcore runs" heading and Refresh
var refresh_button: Button
var loaded_at := -100000
var loading := false

func setup(m) -> void:
	main = m
	name = "Leaders"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

	var head := UI.hbox(8)
	box.add_child(head)
	var t := UI.heading("Deepest Hardcore runs")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	refresh_button = UI.button("Refresh", func(): loaded_at = -100000; refresh())
	head.add_child(refresh_button)
	board_head = head
	UI.tip(t, "Only Hardcore counts: one life, no second chances. Your best run is sent when a Hardcore hero falls.")   # Fable r2: rules on a tap, not before the list

	online_box = UI.vbox(6)
	box.add_child(online_box)
	box.add_child(UI.heading("Your Hardcore heroes"))
	var mine := UI.rich(UI.FONT_BODY)
	mine.name = "Mine"
	box.add_child(mine)

func refresh() -> void:
	var mine: RichTextLabel = box.get_node("Mine")
	var p: Profile = main.profile
	if p.hc_runs.is_empty():
		mine.text = "[color=%s]No fallen Hardcore heroes yet. Found a Hardcore town from Towns when you open the game to start one.[/color]" % UI.hex(UI.DIM)
	else:
		var lines := ["Best: [color=#e8b14a]floor %d[/color]" % p.hc_best]
		for r in p.hc_runs.slice(0, 8):
			lines.append("Floor %d  -  Lv %d %s %s  [color=%s]%s[/color]" % [int(r["best"]), int(r["level"]), r["race"], r["title"], UI.hex(UI.DIM), r["date"]])
		mine.text = "\n".join(lines)
	if Time.get_ticks_msec() - loaded_at > 60000 and not loading:
		_load()

func _load() -> void:
	loading = true
	loaded_at = Time.get_ticks_msec()
	OnlineUI.clear(online_box)
	board_head.visible = main.online.is_configured()   # Fable r3 #13: no heading or Refresh over a board that can't load
	if not main.online.is_configured():
		online_box.add_child(OnlineUI.not_setup_card())
		loading = false
		return
	if not main.online.has_name():
		online_box.add_child(OnlineUI.name_card(main, func(): loaded_at = -100000; loading = false; refresh()))
		loading = false
		return
	online_box.add_child(UI.label("Loading...", UI.FONT_BODY, UI.DIM))
	var r: Dictionary = await main.online.top_runs(50)
	OnlineUI.clear(online_box)
	loading = false
	if not r["ok"]:
		online_box.add_child(OnlineUI.error_label(r["error"]))
		return
	var rows: Array = r["data"]
	if rows.is_empty():
		online_box.add_child(UI.label("No runs yet. Be the first!", UI.FONT_BODY, UI.DIM))
		return
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)
	online_box.add_child(grid)
	for h in ["#", "Player", "Floor", "Hero"]:
		grid.add_child(UI.label(h, UI.FONT_BODY, UI.DIM))
	var me: String = main.online.user_id()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var podium: Array[Color] = [Color("#fde68a"), Color("#e5e7eb"), Color("#f0a868")]
		var col: Color = UI.TEXT if i >= 3 else podium[i]
		if row["player_id"] == me:
			col = UI.GOLD
		grid.add_child(UI.label(str(i + 1), UI.FONT_BODY, col))
		var n := UI.label(str(row["name"]), UI.FONT_BODY, col)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(n)
		grid.add_child(UI.label(str(int(row["floor"])), UI.FONT_BODY, col))
		grid.add_child(UI.label("Lv %d %s %s" % [int(row["level"]), row["race"], row["title"]], UI.FONT_BODY, UI.DIM))
