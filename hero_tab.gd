class_name HeroTab
extends ScrollContainer
## Character > Hero: who you are, your stat points, and what they add up to.
## Reads top to bottom: character card -> points -> the 4 stats -> your numbers.

var main
var state: GameState

var card_style: StyleBoxFlat
var title_label: Label
var role_label: Label
var level_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var points_panel: PanelContainer
var points_label: RichTextLabel
var stat_value := {}
var stat_gives := {}
var stat_buttons := {}
var numbers := {}
var path_label: RichTextLabel
var respec_button: Button
var special_box: VBoxContainer
var special_rows := {}  # name -> [value label, +1 button, +5 button]

func setup(m) -> void:
	main = m
	state = m.state
	name = "Hero"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)

	# ---- Character card ----
	var card := PanelContainer.new()
	card_style = UI.style(UI.INSET, UI.GOLD, 10, 12)
	card_style.border_width_left = 6
	card.add_theme_stylebox_override("panel", card_style)
	v.add_child(card)
	var cv := UI.vbox(4)
	card.add_child(cv)
	var top := UI.hbox(10)
	cv.add_child(top)
	title_label = UI.label("", 22, UI.TEXT)
	top.add_child(title_label)
	role_label = UI.label("", 13, UI.DIM)
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(role_label)
	top.add_child(UI.spacer())
	level_label = UI.label("", 18, UI.GOLD)
	top.add_child(level_label)
	xp_bar = UI.bar(UI.GOLD, 8)
	cv.add_child(xp_bar)
	xp_label = UI.label("", 11, UI.DIM)
	cv.add_child(xp_label)

	# ---- Points banner ----
	points_panel = UI.panel(Color("#2a2010"), UI.GOLD, 8, 8, 1)
	v.add_child(points_panel)
	points_label = UI.rich(14)
	points_panel.add_child(points_label)

	# ---- The 4 stats, 2 x 2 ----
	v.add_child(UI.heading("Stats"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	for st in GameData.STAT_ORDER:
		var info: Dictionary = GameData.STAT_INFO[st]
		var color := Color(info["color"])
		var box := UI.panel(UI.INSET, Color(color, 0.45), 8, 10, 1)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.tooltip_text = info["text"]
		grid.add_child(box)
		var bv := UI.vbox(4)
		box.add_child(bv)
		var head := UI.hbox(6)
		bv.add_child(head)
		head.add_child(UI.label(st, 15, color))
		var nm := UI.label(info["name"], 12, UI.DIM)
		nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(nm)
		head.add_child(UI.spacer())
		var val := UI.label("0", 22, UI.TEXT)
		head.add_child(val)
		stat_value[st] = val
		var gives := UI.rich(12)
		gives.custom_minimum_size = Vector2(0, 34)
		bv.add_child(gives)
		stat_gives[st] = gives
		var btns := UI.hbox(6)
		bv.add_child(btns)
		var p1 := UI.button("+1", func(): state.spend_point(st, 1); main.refresh())
		var p5 := UI.button("+5", func(): state.spend_point(st, 5); main.refresh())
		for b in [p1, p5]:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btns.add_child(b)
		stat_buttons[st] = [p1, p5]

	# ---- Special stats (special classes only) ----
	special_box = UI.vbox(6)
	v.add_child(special_box)
	special_box.add_child(UI.heading("Special stats"))
	var note := UI.label("Grows from how you fight. Each stat point you put in adds 0.1.", 11, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	special_box.add_child(note)

	# ---- Your numbers ----
	v.add_child(UI.heading("Your numbers"))
	var nums := UI.panel(UI.INSET, UI.EMPTY, 8, 10, 1)
	v.add_child(nums)
	var ng := GridContainer.new()
	ng.columns = 4
	ng.add_theme_constant_override("h_separation", 14)
	ng.add_theme_constant_override("v_separation", 4)
	nums.add_child(ng)
	for key in ["Attack", "Defense", "Max HP", "Crit", "Dodge", "Double strike", "Skill dmg", "Cooldowns"]:
		var k := UI.label(key, 12, UI.DIM)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ng.add_child(k)
		var val := UI.label("", 14, UI.TEXT)
		ng.add_child(val)
		numbers[key] = val

	# ---- Path + respec ----
	path_label = UI.rich(12)
	v.add_child(path_label)
	respec_button = UI.button("", func(): main.confirm("Respec all stat points?", "You'll get every stat point back to spend again. Your class stays the same.", "Respec", func(): state.respec(); main.refresh()))
	respec_button.tooltip_text = "Get all your stat points back"
	v.add_child(respec_button)

func refresh() -> void:
	if state.hero_class == "":
		title_label.text = "Choose a class"
		return
	var color := Color(state.class_info()["color"])
	card_style.border_color = color
	title_label.text = state.title()
	title_label.add_theme_color_override("font_color", color.lightened(0.3))
	var cur := ClassTree.current(state)
	role_label.text = (String(cur["role_text"]) + ("  -  " + ClassTree.rank_text(cur) if ClassTree.rank_of(cur) != "" else "")) if not cur.is_empty() else "Starting class"
	level_label.text = "Level %d" % state.level
	xp_bar.max_value = GameData.xp_to_next(state.level)
	xp_bar.value = state.xp
	xp_label.text = "%d / %d XP to level %d" % [state.xp, GameData.xp_to_next(state.level), state.level + 1]

	if state.stat_points > 0:
		points_panel.visible = true
		points_label.text = "[color=#e8b14a][b]%d stat points to spend.[/b][/color]  [color=%s]Tap + on a stat below.[/color]" % [state.stat_points, UI.hex(UI.DIM)]
	else:
		points_panel.visible = false

	var agi := state.stat("AGI")
	var intel := state.stat("INT")
	var gives := {
		"STR": "+%d Attack, +%d HP" % [int(state.stat("STR") * GameData.STR_ATTACK), int(state.stat("STR") * GameData.STR_HP)],
		"VIT": "+%d HP, +%d Defense" % [int(state.stat("VIT") * GameData.VIT_HP), int(state.stat("VIT") * GameData.VIT_DEFENSE)],
		"AGI": "+%d%% crit, +%d%% dodge, +%d%% double strike" % [
			int(GameData.diminishing(agi, GameData.AGI_CRIT)), int(GameData.diminishing(agi, GameData.AGI_DODGE)), int(GameData.diminishing(agi, GameData.AGI_DOUBLE))],
		"INT": "+%d%% skill damage, -%d%% cooldowns" % [int(intel * GameData.INT_ABILITY_DMG * 100), int(GameData.diminishing(intel, GameData.INT_COOLDOWN))],
	}
	for st in GameData.STAT_ORDER:
		(stat_value[st] as Label).text = str(state.stat(st))
		(stat_gives[st] as RichTextLabel).text = "[color=%s]Gives you:[/color] %s" % [UI.hex(UI.DIM), gives[st]]
		var btns: Array = stat_buttons[st]
		(btns[0] as Button).disabled = state.stat_points < 1
		(btns[1] as Button).disabled = state.stat_points < 5

	(numbers["Attack"] as Label).text = str(state.get_attack())
	(numbers["Defense"] as Label).text = str(state.get_defense())
	(numbers["Max HP"] as Label).text = str(state.get_max_hp())
	(numbers["Crit"] as Label).text = "%d%%" % state.effect_total("crit")
	(numbers["Dodge"] as Label).text = "%d%%" % state.effect_total("dodge")
	(numbers["Double strike"] as Label).text = "%d%%" % state.effect_total("double_strike")
	(numbers["Skill dmg"] as Label).text = "x%.2f" % ((1.0 + intel * GameData.INT_ABILITY_DMG) * state._mult("skill"))
	(numbers["Cooldowns"] as Label).text = "-%d%%" % int(GameData.diminishing(intel, GameData.INT_COOLDOWN))
	var names := state.unique_stats()
	special_box.visible = not names.is_empty()
	if str(names) != str(special_rows.keys()):
		_build_special_rows(names)
	for n in special_rows:
		var row: Array = special_rows[n]
		(row[0] as Label).text = "%.1f" % state.unique_value(n)
		(row[1] as Button).disabled = state.stat_points < 1
		(row[2] as Button).disabled = state.stat_points < 5

	# Where you're headed
	var text := ""
	var t := ClassTree.pick_tier(state)
	if t >= 0:
		text = "[color=#e8b14a]You can choose your next class now[/color] in the Class tab."
	elif state.class_branch != "" or state.class_path.size() >= 3:
		text = "Your family tree is complete. Your special stat keeps growing."
	else:
		text = "At [color=#e8b14a]level %d[/color] your class splits again. See the whole family tree in the Class tab." % int(ClassTree.PICK_LEVELS[state.class_path.size()])
	path_label.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), text]

	var spent := 0
	for st in GameData.STAT_ORDER:
		spent += state.stat(st)
	respec_button.text = "Respec all points  (%d gold)" % state.respec_cost()
	respec_button.disabled = spent == 0 or state.gold < state.respec_cost()

## One row per special stat (your unique class's and your hidden class's).
func _build_special_rows(names: Array) -> void:
	for n in special_rows:
		(special_rows[n][3] as Control).queue_free()
	special_rows.clear()
	for n in names:
		var col := Color("#e8b14a")
		var u := ClassTree.unique_class(state)
		if not u.is_empty() and n == u["stat"]:
			col = Color(ClassTree.RANK_COLORS[ClassTree.rank_of(u)])
		elif state.hidden_class != "":
			col = Color(Hidden.info(state.hidden_class).get("color", "#e8b14a"))
		var row := UI.panel(UI.INSET, Color(col, 0.45), 8, 8, 1)
		special_box.add_child(row)
		var h := UI.hbox(8)
		row.add_child(h)
		var lbl := UI.label(n, 15, col)
		lbl.custom_minimum_size = Vector2(130, 0)
		h.add_child(lbl)
		var val := UI.label("0", 18, UI.TEXT)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(val)
		var sname: String = n
		var p1 := UI.button("+1", func(): state.spend_unique(sname, 1); main.refresh())
		var p5 := UI.button("+5", func(): state.spend_unique(sname, 5); main.refresh())
		h.add_child(p1)
		h.add_child(p5)
		special_rows[n] = [val, p1, p5, row]
