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
var from_town := false   # picking where to go down to from town (main._leave_town)
var carry_buttons: Array = []
var carry_note: Label
var risk_note: Label
var team_box: VBoxContainer
var supply_box: VBoxContainer
var preset_box: GridContainer
var preset_note: Label

## From town: the same picker, plus quick picks, and choosing a floor takes you down.
func show_from_town(main_node) -> void:
	from_town = true
	show_for(main_node)

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Into the dungeon: choose your floor" if from_town else "Choose a floor", 780.0)
	if from_town:
		var quick := UI.hbox(8)
		content.add_child(quick)
		# Dives start at a checkpoint: floor 1, or just past a boss you've beaten
		var top := last_start()
		var picks: Array = [["Last checkpoint: floor %d" % top, top]]
		if top > 1:
			picks.append(["From the top: floor 1", 1])
		for p in picks:
			var b := UI.primary(String(p[0]), _go.bind(int(p[1])), UI.GOLD)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, UI.TAP)
			quick.add_child(b)
		# How much gold to take down: the rest stays safe in the Bank
		content.add_child(UI.label("GOLD TO CARRY", UI.FONT_CAPTION, UI.DIM))
		var carry := UI.hbox(6)
		content.add_child(carry)
		carry_buttons.clear()
		for i in Town.CARRY_NAMES.size():
			var cb := UI.button("", _pick_carry.bind(i))
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.custom_minimum_size = Vector2(0, UI.TAP)
			cb.toggle_mode = true
			carry.add_child(cb)
			carry_buttons.append(cb)
		carry_note = UI.label("", UI.FONT_CAPTION, UI.DIM)
		carry_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(carry_note)
		# 2.1: quick swap to a saved preset (gear, skills, team, supplies) right before the dive
		content.add_child(UI.label("PRESET", UI.FONT_CAPTION, UI.DIM))
		preset_box = GridContainer.new()
		preset_box.columns = 2
		preset_box.add_theme_constant_override("h_separation", 8)
		preset_box.add_theme_constant_override("v_separation", 8)
		content.add_child(preset_box)
		preset_note = UI.wrap("", UI.FONT_CAPTION, UI.GOLD)
		preset_note.visible = false
		content.add_child(preset_note)
		_fill_presets()
		# Next update (Juzo): pick your team and where they stand, and what to bring
		content.add_child(UI.wrap("YOUR TEAM: the front row draws the attacks, the back row is hit less", UI.FONT_CAPTION, UI.DIM))
		team_box = UI.vbox(6)
		content.add_child(team_box)
		content.add_child(UI.wrap("SUPPLIES TO BRING: what you carry is lost if you fall; what stays home is safe", UI.FONT_CAPTION, UI.DIM))
		supply_box = UI.vbox(4)
		content.add_child(supply_box)
		_fill_team()
		_fill_supplies()
		risk_note = UI.label("", UI.FONT_CAPTION, Color("#fca5a5"))
		risk_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(risk_note)
		_show_carry()
	var sub := UI.rich(UI.FONT_CAPTION)
	if from_town:
		sub.text = "[color=%s]Dives start at a checkpoint: floor 1, or the floor after any boss you've beaten (26, 51, 76...). Bright floors are checkpoints you can start from.[/color]" % UI.hex(UI.DIM)
	else:
		sub.text = "[color=%s]Travel to any floor you've reached. Red floors are bosses: go back to farm them for uniques. You're on [color=#e8b14a]floor %d[/color] (%s).[/color]" % [UI.hex(UI.DIM), state.floor_num, GameData.sub_name(state.floor_num)]
	content.add_child(sub)
	if World.curses_unlocked(state):
		var cb := UI.button("Curses (%d on): harder climb, better loot" % state.curses.size(), func(): curses_popup(m))
		cb.custom_minimum_size = Vector2(0, UI.TAP)
		cb.add_theme_color_override("font_color", UI.PURPLE)
		content.add_child(cb)
	zone_bar = HFlowContainer.new()
	zone_bar.add_theme_constant_override("h_separation", 6)
	zone_bar.add_theme_constant_override("v_separation", 6)
	content.add_child(zone_bar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if is_narrow() else ScrollContainer.SCROLL_MODE_AUTO
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
		b.add_theme_font_size_override("font_size", UI.MIN_FONT)
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
		# phones: the area name on top, its floors wrapping underneath (a row of 10 ran off the screen)
		var narrow := is_narrow()
		var row: BoxContainer = UI.vbox(4) if narrow else UI.hbox(6)
		rows.add_child(row)
		var name_box := UI.vbox(0)
		name_box.custom_minimum_size = Vector2(0 if narrow else 160, 0)
		row.add_child(name_box)
		var floors_box: Container = row
		var local: String = area["monster"]["id"]
		var lbls := [UI.label(str(area["name"]), UI.FONT_CAPTION, Color(GameData.zone_for_floor(start)["color"]).lightened(0.45)),
			UI.label("Home of: " + (Monsters.name_of(local) if state.codex.seen(local) else "???"), UI.FONT_CAPTION, UI.DIM)]
		for lbl in lbls:
			lbl.clip_text = true
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lbl.tooltip_text = lbl.text
			name_box.add_child(lbl)
		if narrow:
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 6)
			flow.add_theme_constant_override("v_separation", 6)
			row.add_child(flow)
			floors_box = flow
		for f in range(start, start + GameData.SUB_FLOORS):
			var b := UI.button(str(f), _go.bind(f))
			b.custom_minimum_size = Vector2(44, 36)
			b.disabled = not _allowed(f)
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
			floors_box.add_child(b)
	# Quick buttons for the zone's two bosses
	var bosses := UI.hbox(8)
	rows.add_child(bosses)
	for f in [first_floor + GameData.MID_BOSS_FLOOR - 1, first_floor + GameData.ZONE_FLOORS - 1]:
		if not _allowed(f):
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
		b.disabled = cd > 0 or not _allowed(f)

## The deepest checkpoint you can start a dive from: just past the last boss you beat.
func last_start() -> int:
	return GameState.checkpoint_start(mini(state.best_floor, state.checkpoint + 1))

## Floors you can pick: anywhere you've reached while in the dungeon; from town,
## only checkpoint floors (1, 26, 51...) up to your last checkpoint.
func _allowed(f: int) -> bool:
	if from_town:
		return f == GameState.checkpoint_start(f) and f <= last_start()
	return f <= state.best_floor

func _pick_carry(i: int) -> void:
	state.carry_pick = i
	m.sfx.play("click")
	_show_carry()

func _show_carry() -> void:
	for i in carry_buttons.size():
		var b: Button = carry_buttons[i]
		b.text = "%s\n%d" % [Town.CARRY_NAMES[i], Town.carry_amount(state, i)]
		b.set_pressed_no_signal(i == state.carry_pick)
		b.add_theme_color_override("font_color", UI.GOLD if i == state.carry_pick else UI.TEXT)
	var c := Town.carry_amount(state, state.carry_pick)
	carry_note.text = "You take %d gold down; %d stays safe in the Bank. Carried gold is banked when you come home." % [c, state.total_gold() - c]
	if risk_note:
		var worn := 0
		for s in state.equipped:
			if not GameState.is_bound(state.equipped[s]):
				worn += 1
		var packed := state.bag.filter(func(it): return not GameState.is_bound(it)).size()
		risk_note.text = "AT RISK THIS DIVE: %d gold, %d worn item%s and %d in your bag (bound items are always safe). Fall, and the gear plus half that gold wait in your grave on that floor, guarded by your killer; potions, scrolls and elixirs you carry are lost." % [c, worn, "" if worn == 1 else "s", packed]

func _show_zone(zb: int) -> void:
	zone_shown = zb
	_build()

func _go(f: int) -> void:
	if state.go_to_floor(f):
		close()
		if from_town:
			m._leave_town()
			return
	m.refresh()

## Opt-in curses: tougher monsters for better loot and more gold.
static func curses_popup(mm) -> void:
	var st: GameState = mm.state
	var o := Overlay.new().open(mm, "Curses", 520.0, UI.PURPLE)
	_fill_curses(mm, o, st)

static func _fill_curses(mm, o: Overlay, st: GameState) -> void:
	for c in o.content.get_children():
		if c != o.content.get_child(0):
			c.queue_free()
	o.content.add_child(UI.wrap("Turn on curses to make every fight harder. Each one makes loot rarer and gold richer. They stay on until you turn them off.", UI.FONT_CAPTION, UI.DIM))
	o.content.add_child(UI.label("Now: +%d loot luck, +%d%% gold" % [World.curse_loot(st), int(World.curse_gold(st))], 15, UI.PURPLE))
	for id in World.CURSE_ORDER:
		var cu: Dictionary = World.CURSES[id]
		var on := World.has_curse(st, id)
		var c := UI.card(UI.PURPLE if on else UI.BORDER, Color("#1d1430") if on else UI.INSET, 4)
		o.content.add_child(c[0])
		var h := UI.hbox(8)
		c[1].add_child(h)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(String(cu["name"]), 15, UI.PURPLE.lightened(0.3) if on else UI.TEXT))
		v.add_child(UI.wrap("%s  Loot +%d, gold +%d%%." % [cu["text"], int(cu["loot"]), int(cu["gold"])], 12, UI.DIM))
		var cid: String = id
		var b := UI.primary("ON" if on else "OFF", func():
			World.toggle_curse(st, cid)
			_fill_curses(mm, o, st), UI.PURPLE if on else UI.DIM)
		b.custom_minimum_size = Vector2(64, UI.TAP)
		h.add_child(b)

# =====================================================================
# Next update (Juzo): the team and the supplies, picked right before a dive
# =====================================================================

## 2.1: one button per saved preset, plus the Presets screen.
func _fill_presets() -> void:
	Presets.migrate(state)
	OnlineUI.clear(preset_box)
	for i in Presets.SLOTS:
		if not Presets.is_saved(state, i):
			continue
		var idx := i
		var b := UI.button(Presets.name_of(state, i), func(): _use_preset(idx))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UI.TAP)
		b.clip_text = true
		b.tooltip_text = Presets.summary(state, i)
		preset_box.add_child(b)
	var edit := UI.button("Presets...", func(): PresetsScreen.new().show_for(m, _after_presets))
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, UI.TAP)
	edit.add_theme_color_override("font_color", UI.TEAL)
	preset_box.add_child(edit)

func _use_preset(i: int) -> void:
	var notes := Presets.apply(state, i, m.profile.stash)
	m.sfx.play("equip")
	preset_note.visible = true
	preset_note.text = "Now using %s." % Presets.name_of(state, i) + ("" if notes.is_empty() else "\n" + "\n".join(notes))
	_after_presets()

func _after_presets() -> void:
	if not is_inside_tree():
		return
	_fill_presets()
	_fill_team()
	_fill_supplies()
	_show_carry()
	m.refresh()

func _fill_team() -> void:
	OnlineUI.clear(team_box)
	var rows: Array = [["0", state, state.hero_class in Party.TANK_CLASSES, -1]]
	if state.party != null:
		for mem in state.party.members:
			rows.append([str(mem.slot), mem.hero, mem.is_tank(), mem.slot])
	for r in rows:
		var hg: GameState = r[1]
		var h := UI.hbox(8)
		team_box.add_child(h)
		var tp := TextureRect.new()
		tp.texture = Sprites.portrait(hg.appearance, hg.hero_looks())
		tp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tp.custom_minimum_size = Vector2(40, 40)
		tp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tp)
		var nm := UI.label("%s  Lv %d %s" % [hg.hero_name if hg.hero_name != "" else "Hero", hg.level, hg.title()], 12, Color(hg.class_info().get("color", "#e5e7eb")))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		h.add_child(nm)
		var row := state.row_of(String(r[0]), bool(r[2]))
		var rb := UI.button("Front" if row == "front" else "Back", func():
			state.set_row(String(r[0]), "back" if row == "front" else "front")
			m.sfx.play("click")
			_fill_team())
		rb.add_theme_color_override("font_color", UI.GOLD if row == "front" else UI.BLUE)
		rb.tooltip_text = "Tap to move between the front and back row"
		h.add_child(rb)
		if int(r[3]) > 0:
			h.add_child(UI.button("Leave", func():
				var slots: Array = state.party_slots.duplicate()
				slots.erase(int(r[3]))
				state.party.save_all()
				state.set_party(slots)
				_fill_team()))
	if state.hardcore:
		team_box.add_child(UI.wrap("Hardcore heroes go down alone.", UI.FONT_CAPTION, UI.DIM))
		return
	if state.party_slots.size() >= Party.MAX_COMPANIONS:
		return
	var add := HFlowContainer.new()
	add.add_theme_constant_override("h_separation", 6)
	add.add_theme_constant_override("v_separation", 6)
	team_box.add_child(add)
	for n in range(1, GameData.MAX_HEROES + 1):
		if n == state.slot or n in state.party_slots:
			continue
		var meta := GameState.slot_meta(n)
		if meta.is_empty() or meta.get("hardcore", false) or str(meta.get("class", "")) == "":
			continue
		add.add_child(UI.button("+ %s" % str(meta.get("name", "Hero")), func():
			var slots: Array = state.party_slots.duplicate()
			slots.append(n)
			state.set_party(slots)
			m.sfx.play("equip")
			_fill_team()))
	if add.get_child_count() == 0:
		add.add_child(UI.wrap("Going alone. Recruit more heroes at the Inn as your town grows.", UI.FONT_CAPTION, UI.DIM))

func _fill_supplies() -> void:
	OnlineUI.clear(supply_box)
	for key in GameState.supply_keys():
		var carried := state.supply_carried(key)
		var home := state.supply_home(key)
		if carried + home == 0 and not key in ["potion", "scroll"]:
			continue  # elixirs you don't own yet stay off the list
		var h := UI.hbox(6)
		supply_box.add_child(h)
		var l := UI.label("%s: %d carried  ·  %d at home" % [GameState.supply_name(key), carried, home], 12, UI.TEXT if carried > 0 else UI.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var minus := UI.button("-", func():
			state.move_supply(key, -1)
			_fill_supplies()
			_show_carry())
		minus.disabled = carried <= 0
		minus.tooltip_text = "Leave one at home (safe)"
		minus.custom_minimum_size = Vector2(UI.TAP, UI.TAP)
		h.add_child(minus)
		var plus := UI.button("+", func():
			state.move_supply(key, 1)
			_fill_supplies()
			_show_carry())
		plus.disabled = home <= 0
		plus.tooltip_text = "Take one down with you"
		plus.custom_minimum_size = Vector2(UI.TAP, UI.TAP)
		h.add_child(plus)
	if state.supply_home("potion") + state.potions == 0:
		supply_box.add_child(UI.wrap("No potions. Buy some at the Inn first.", UI.FONT_CAPTION, Color("#fca5a5")))
