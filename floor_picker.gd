class_name FloorPicker
extends Overlay
## Travel to any floor you've reached. Pick a zone at the top, then a floor:
## one row per area (10 floors). Floor 25 (mid boss) and 50 (zone boss) are red.
## Bosses need a short rest between fights; the buttons show the countdown.

var m
var state: GameState
var zone_shown := 0
var rows: VBoxContainer
var zone_bar: HFlowContainer
var boss_buttons := {}  # floor -> Button (negative floor = the big "Fight" button)
var tick := Timer.new()

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Choose a floor", 780.0)
	var sub := UI.rich(13)
	sub.text = "[color=%s]Travel to any floor you've reached. Red floors are bosses: go back to farm them for uniques. You're on [color=#e8b14a]floor %d[/color] (%s).[/color]" % [UI.hex(UI.DIM), state.floor_num, GameData.sub_name(state.floor_num)]
	content.add_child(sub)
	zone_bar = HFlowContainer.new()
	zone_bar.add_theme_constant_override("h_separation", 6)
	zone_bar.add_theme_constant_override("v_separation", 6)
	content.add_child(zone_bar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 300)
	content.add_child(scroll)
	rows = UI.vbox(6)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	zone_shown = _zone_block(state.floor_num)
	_build()
	tick.wait_time = 1.0
	tick.timeout.connect(_update_cooldowns)
	add_child(tick)
	tick.start()

## Zone blocks keep counting past 250 (the looping "Elder" zones are their own block).
func _zone_block(f: int) -> int:
	return floori((f - 1) / float(GameData.ZONE_FLOORS))

func _build() -> void:
	OnlineUI.clear(zone_bar)
	var blocks := _zone_block(state.best_floor) + 1
	for zb in blocks:
		var first := zb * GameData.ZONE_FLOORS + 1
		var zone := GameData.zone_for_floor(first)
		var b := UI.button(GameData.rank_prefix(first) + str(zone["name"]), _show_zone.bind(zb))
		b.add_theme_font_size_override("font_size", 12)
		if zb == zone_shown:
			b.add_theme_stylebox_override("normal", UI.style(Color(zone["color"]).darkened(0.5), Color(zone["color"]).lightened(0.3), 6, 4, 2))
		zone_bar.add_child(b)
	OnlineUI.clear(rows)
	boss_buttons.clear()
	var first_floor := zone_shown * GameData.ZONE_FLOORS + 1
	for si in 5:
		var start := first_floor + si * GameData.SUB_FLOORS
		if start > state.best_floor:
			break
		var area: Dictionary = GameData.sub_area(start)
		var row := UI.hbox(6)
		rows.add_child(row)
		var name_box := UI.vbox(0)
		name_box.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_box)
		var local: String = area["monster"]["name"]
		var lbls := [UI.label(str(area["name"]), 13, Color(GameData.zone_for_floor(start)["color"]).lightened(0.45)),
			UI.label("Home of: " + (local if state.codex.seen(local) else "???"), 11, UI.DIM)]
		for lbl in lbls:
			lbl.clip_text = true
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lbl.tooltip_text = lbl.text
			name_box.add_child(lbl)
		for f in range(start, start + GameData.SUB_FLOORS):
			var b := UI.button(str(f), _go.bind(f))
			b.custom_minimum_size = Vector2(44, 36)
			b.disabled = f > state.best_floor
			if GameData.is_boss_floor(f):
				b.add_theme_stylebox_override("normal", UI.style(Color("#3a1414"), UI.RED, 6, 4))
				b.add_theme_stylebox_override("hover", UI.style(Color("#4d1a1a"), Color("#fca5a5"), 6, 4))
				b.add_theme_color_override("font_color", Color("#fecaca"))
				b.tooltip_text = ("Mid boss: " if GameData.boss_kind(f) == "mid" else "Zone boss: ") + (GameData.boss_name(f) if state.best_floor >= f else "???")
				boss_buttons[f] = b
			if f == state.floor_num:
				b.add_theme_stylebox_override("normal", UI.style(Color("#2a2010"), UI.GOLD, 6, 4, 3))
				b.add_theme_color_override("font_color", UI.GOLD)
				b.tooltip_text = "You are here"
			row.add_child(b)
	# Quick buttons for the zone's two bosses
	var bosses := UI.hbox(8)
	rows.add_child(bosses)
	for f in [first_floor + GameData.MID_BOSS_FLOOR - 1, first_floor + GameData.ZONE_FLOORS - 1]:
		if f > state.best_floor:
			continue
		var b := UI.primary("", _go.bind(f), UI.RED)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bosses.add_child(b)
		boss_buttons[-f] = b
	_update_cooldowns()

func _update_cooldowns() -> void:
	for key in boss_buttons:
		var f: int = absi(int(key))
		var b: Button = boss_buttons[key]
		if not is_instance_valid(b):
			continue
		var cd := state.boss_cooldown(f)
		if int(key) < 0:
			b.text = ("Fight %s" % GameData.boss_name(f)) + ("  (resting %ds)" % cd if cd > 0 else "")
		else:
			b.text = str(f) if cd <= 0 else "%ds" % cd
		b.disabled = cd > 0 or f > state.best_floor

func _show_zone(zb: int) -> void:
	zone_shown = zb
	_build()

func _go(f: int) -> void:
	if state.go_to_floor(f):
		close()
	m.refresh()
