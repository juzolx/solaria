class_name HeroTab
extends ScrollContainer
## Character > Hero: who you are, your 8 stats, your special stat, your saved
## builds and the numbers it all adds up to. Laid out as one column of cards
## so it reads well on a phone.

var main
var state: GameState

var card_style: StyleBoxFlat
var portrait: TextureRect
var title_label: Label
var role_label: Label
var level_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var chips: HBoxContainer
var points_panel: PanelContainer
var points_label: RichTextLabel
var auto_button: Button
var spend_button: Button
var rows := {}      # stat -> {"value", "gives", "p1", "p5", "chip"}
var special_box: VBoxContainer
var special_rows := {}  # name -> [value label, text rich, bar, panel]
var build_rows: Array = []  # [name label, use button, save button]
var numbers := {}
var path_label: RichTextLabel
var respec_button: Button
var _look_key := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Hero"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)

	# ---- Character card ----
	var card := PanelContainer.new()
	card_style = UI.style(UI.INSET, UI.GOLD, 10, 12)
	card_style.border_width_left = 6
	card.add_theme_stylebox_override("panel", card_style)
	v.add_child(card)
	var ch := UI.hbox(12)
	card.add_child(ch)
	portrait = TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 2
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ch.add_child(portrait)
	var cv := UI.vbox(4)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(cv)
	var top := UI.hbox(8)
	cv.add_child(top)
	title_label = UI.label("", 21, UI.TEXT)
	title_label.clip_text = true
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	level_label = UI.label("", 17, UI.GOLD)
	top.add_child(level_label)
	role_label = UI.wrap("", 12, UI.DIM)
	cv.add_child(role_label)
	chips = UI.hbox(6)
	cv.add_child(chips)
	xp_bar = UI.bar(UI.GOLD, 8)
	cv.add_child(xp_bar)
	xp_label = UI.label("", 11, UI.DIM)
	cv.add_child(xp_label)

	# ---- Points banner ----
	points_panel = UI.panel(Color("#2a2010"), UI.GOLD, 8, 10, 1)
	v.add_child(points_panel)
	var pv := UI.vbox(8)
	points_panel.add_child(pv)
	points_label = UI.rich(14)
	pv.add_child(points_label)
	var prow := UI.hbox(8)
	pv.add_child(prow)
	spend_button = UI.primary("Spend on my build", func(): state.auto_spend(); state.save_game(); main.refresh())
	UI.tip(spend_button, "Puts every point into your class's suggested stats, keeping the spread even.")
	auto_button = UI.button("", func():
		state.auto_stats = not state.auto_stats
		if state.auto_stats:
			state.auto_spend()
		state.save_game()
		main.refresh())
	UI.tip(auto_button, "Auto spends new points on your class's suggested build every level.")
	for b in [spend_button, auto_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UI.TAP)
		prow.add_child(b)

	# ---- The 8 stats ----
	UI.section(v, "Stats", "Each stat has one job. Stats marked SUGGESTED are the ones your class wants most.")
	var list := UI.vbox(6)
	v.add_child(list)
	for st in GameData.STAT_ORDER:
		list.add_child(_stat_row(st))

	# ---- Special stats ----
	special_box = UI.vbox(6)
	v.add_child(special_box)
	UI.section(special_box, "Special stat", "Unique classes have a stat of their own. It can't take points: it grows from doing what your class does best.")

	# ---- Builds ----
	UI.section(v, "Builds", "Save your stats, skills and gear together, then switch between them for free (say, a boss build and a farming build).")
	var bl := UI.vbox(6)
	v.add_child(bl)
	for i in 3:
		var row := UI.hbox(8)
		bl.add_child(row)
		var nl := UI.label("", 14, UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		row.add_child(nl)
		var idx := i
		var use := UI.primary("Use", func(): state.apply_build(idx); main.sfx.play("buff"); main.refresh(), UI.TEAL)
		var save := UI.button("Save current", func():
			if state.build_saved(idx):
				main.confirm("Replace %s?" % state.build_name(idx), "This saves what you're using right now over it.", "Save", func(): state.save_build(idx); main.refresh())
			else:
				state.save_build(idx)
				main.refresh())
		for b in [use, save]:
			b.custom_minimum_size = Vector2(0, UI.TAP)
			row.add_child(b)
		build_rows.append([nl, use, save])

	# ---- Your numbers ----
	UI.section(v, "Your numbers")
	var nums := UI.panel(UI.INSET, UI.EMPTY, 8, 10, 1)
	v.add_child(nums)
	var ng := GridContainer.new()
	ng.columns = 4
	ng.add_theme_constant_override("h_separation", 12)
	ng.add_theme_constant_override("v_separation", 5)
	nums.add_child(ng)
	for key in ["Attack", "Defense", "Max HP", "Skill dmg", "Crit", "Crit dmg", "Double strike", "Cooldowns",
			"Dodge", "Extra attack", "Strike first", "Heal power", "Regen", "Resist", "Loot bonus", "Gold", "Prices", "Charm"]:
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
	respec_button.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(respec_button)

func _stat_row(st: String) -> PanelContainer:
	var info: Dictionary = GameData.STAT_INFO[st]
	var color := Color(info["color"])
	var c := UI.card(color, UI.INSET, 4)
	var box: PanelContainer = c[0]
	var bv: VBoxContainer = c[1]
	UI.tip(box, "%s: %s" % [info["name"], info["text"]])
	var head := UI.hbox(8)
	bv.add_child(head)
	var name_col := UI.vbox(0)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_col)
	var nh := UI.hbox(6)
	name_col.add_child(nh)
	nh.add_child(UI.label(st, 16, color))
	var nm := UI.label(info["name"], 12, UI.DIM)
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nh.add_child(nm)
	var chip := UI.chip("SUGGESTED", UI.GOLD, 10)
	nh.add_child(chip)
	var gives := UI.rich(12)
	name_col.add_child(gives)
	var val := UI.label("0", 22, UI.TEXT)
	val.custom_minimum_size = Vector2(44, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(val)
	var p1 := UI.button("+1", func(): state.spend_point(st, 1); main.refresh())
	var p5 := UI.button("+5", func(): state.spend_point(st, 5); main.refresh())
	for b in [p1, p5]:
		b.custom_minimum_size = Vector2(UI.TAP + 6, UI.TAP)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(b)
	rows[st] = {"value": val, "gives": gives, "p1": p1, "p5": p5, "chip": chip}
	return box

func _pct(v: float) -> String:
	return "%d%%" % int(round(v))

## "+12 Attack, +24 HP" for a stat at its current value.
func gives_text(st: String) -> String:
	var g := state
	match st:
		"STR":
			return "+%d Attack, +%d HP" % [int(g.stat("STR") * GameData.STR_ATTACK), int(g.stat("STR") * GameData.STR_HP)]
		"VIT":
			return "+%d HP, +%d Defense" % [int(g.stat("VIT") * GameData.VIT_HP), int(g.stat("VIT") * GameData.VIT_DEFENSE)]
		"AGI":
			return "+%s dodge, %s extra attack, %s strike first" % [_pct(g.dim("AGI", GameData.AGI_DODGE)), _pct(g.dim("AGI", GameData.AGI_HASTE)), _pct(g.dim("AGI", GameData.AGI_FIRST))]
		"DEX":
			return "+%s crit, +%s double strike" % [_pct(g.dim("DEX", GameData.DEX_CRIT)), _pct(g.dim("DEX", GameData.DEX_DOUBLE))]
		"INT":
			return "+%d%% skill damage, -%s cooldowns" % [int(g.stat("INT") * GameData.INT_ABILITY_DMG * 100), _pct(g.dim("INT", GameData.INT_COOLDOWN))]
		"WIS":
			return "+%s healing, +%.1f%% regen, -%s from statuses" % [_pct(g.dim("WIS", GameData.WIS_HEAL)), g.dim("WIS", GameData.WIS_REGEN), _pct(g.dim("WIS", GameData.WIS_RESIST))]
		"LUK":
			return "+%d loot luck, +%s gold, +%s crit damage" % [int(g.dim("LUK", GameData.LUK_LOOT)), _pct(g.dim("LUK", GameData.LUK_GOLD)), _pct(g.dim("LUK", GameData.LUK_CRIT_DMG))]
		"CHA":
			return "-%s prices, %s charm, +%s songs" % [_pct(g.dim("CHA", GameData.CHA_DISCOUNT)), _pct(g.dim("CHA", GameData.CHA_CHARM)), _pct(g.dim("CHA", GameData.CHA_SONG))]
	return ""

func refresh() -> void:
	if state.hero_class == "":
		title_label.text = "Choose a class"
		return
	var color := Color(state.class_info()["color"])
	card_style.border_color = color
	var key := str(state.appearance) + str(state.hero_looks().keys()) + state.title()
	if key != _look_key:
		_look_key = key
		portrait.texture = Sprites.portrait(state.appearance, state.hero_looks())
	title_label.text = (state.hero_name + ", " if state.hero_name != "" else "") + state.title()
	title_label.add_theme_color_override("font_color", color.lightened(0.3))
	var cur := ClassTree.current(state)
	role_label.text = String(cur["role_text"]) if not cur.is_empty() else String(state.class_info().get("blurb", ""))
	level_label.text = "Lv %d" % state.level
	for c in chips.get_children():
		c.queue_free()
	chips.add_child(UI.chip(state.race().to_upper(), Color(state.race_info().get("color", "#e8b14a"))))
	var al := ClassTree.alignment(state)
	chips.add_child(UI.chip(String(ClassTree.ALIGN_NAMES[al]).to_upper(), Color(ClassTree.ALIGN_COLORS[al])))
	if ClassTree.rank_of(cur) != "":
		chips.add_child(UI.chip("%s RANK" % ClassTree.rank_of(cur), Color(ClassTree.RANK_COLORS[ClassTree.rank_of(cur)])))
	xp_bar.max_value = GameData.xp_to_next(state.level)
	xp_bar.value = state.xp
	xp_label.text = "%d / %d XP to level %d" % [state.xp, GameData.xp_to_next(state.level), state.level + 1]

	points_panel.visible = state.stat_points > 0 or state.auto_stats
	if state.stat_points > 0:
		points_label.text = "[color=#e8b14a][b]%d stat points to spend.[/b][/color]  [color=%s]Tap +1 / +5 on a stat, or let your build do it.[/color]" % [state.stat_points, UI.hex(UI.DIM)]
	else:
		points_label.text = "[color=%s]Auto is spending your points on your class's suggested build.[/color]" % UI.hex(UI.DIM)
	spend_button.visible = state.stat_points > 0
	auto_button.text = "Auto: %s" % ("ON" if state.auto_stats else "OFF")

	var b := Classes.build(state.hero_class)
	for st in GameData.STAT_ORDER:
		var r: Dictionary = rows[st]
		(r["value"] as Label).text = str(state.stat(st))
		var bonus := state.bonus_stat(st)
		(r["gives"] as RichTextLabel).text = "[color=%s]%s[/color]%s" % [UI.hex(UI.DIM), gives_text(st),
			("  [color=%s](+%d from your race)[/color]" % [UI.hex(UI.DIM.darkened(0.2)), bonus]) if bonus > 0 else ""]
		(r["p1"] as Button).disabled = state.stat_points < 1
		(r["p5"] as Button).disabled = state.stat_points < 5
		(r["chip"] as Control).visible = b.has(st)

	var g := state
	(numbers["Attack"] as Label).text = str(g.get_attack())
	(numbers["Defense"] as Label).text = str(g.get_defense())
	(numbers["Max HP"] as Label).text = str(g.get_max_hp())
	(numbers["Skill dmg"] as Label).text = "x%.2f" % ((1.0 + g.stat("INT") * GameData.INT_ABILITY_DMG) * g._mult("skill"))
	(numbers["Crit"] as Label).text = _pct(g.effect_total("crit"))
	(numbers["Crit dmg"] as Label).text = "x%.2f" % g.crit_mult()
	(numbers["Double strike"] as Label).text = _pct(g.effect_total("double_strike"))
	(numbers["Cooldowns"] as Label).text = "-" + _pct(g.dim("INT", GameData.INT_COOLDOWN))
	(numbers["Dodge"] as Label).text = _pct(g.effect_total("dodge"))
	(numbers["Extra attack"] as Label).text = _pct(g.haste_chance())
	(numbers["Strike first"] as Label).text = _pct(g.first_strike_chance())
	(numbers["Heal power"] as Label).text = "x%.2f" % g.heal_mult()
	(numbers["Regen"] as Label).text = "%.1f%%" % g.effect_value("regen")
	(numbers["Resist"] as Label).text = _pct((1.0 - g.status_mult()) * 100.0)
	(numbers["Loot bonus"] as Label).text = "+%d" % g._loot_bonus()
	(numbers["Gold"] as Label).text = "+" + _pct(g.effect_total("gold_find"))
	(numbers["Prices"] as Label).text = "-" + _pct(g.dim("CHA", GameData.CHA_DISCOUNT))
	(numbers["Charm"] as Label).text = _pct(g.charm_total())

	var names := state.unique_stats()
	special_box.visible = not names.is_empty()
	if str(names) != str(special_rows.keys()):
		_build_special_rows(names)
	for n in special_rows:
		var row: Array = special_rows[n]
		var v := state.unique_value(n)
		(row[0] as Label).text = "%.1f" % v
		var u := ClassTree.unique_class(state)
		var txt := ""
		if not u.is_empty() and n == u["stat"]:
			txt = "Gives %s\nGrows when you [color=#e8b14a]%s[/color] (and from every boss)." % [ClassTree.stat_text(state).trim_suffix("."), ClassTree.grow_text(state)]
		else:
			txt = Hidden.stat_text(state)
		(row[1] as RichTextLabel).text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), txt]
		(row[2] as ProgressBar).max_value = GameState.UNIQUE_CAP
		(row[2] as ProgressBar).value = v

	for i in build_rows.size():
		var br: Array = build_rows[i]
		var saved := state.build_saved(i)
		(br[0] as Label).text = state.build_name(i) if saved else "Empty slot %d" % (i + 1)
		(br[0] as Label).add_theme_color_override("font_color", UI.TEXT if saved else UI.DIM)
		(br[1] as Button).disabled = not saved

	# Where you're headed
	var text := ""
	var t := ClassTree.pick_tier(state)
	if t >= 0:
		text = "[color=#e8b14a]You can choose your next class now[/color] in Character > Class."
	elif state.class_branch != "" or state.class_path.size() >= 3:
		text = "Your evolution tree is complete. Your special stat keeps growing."
	else:
		text = "At [color=#e8b14a]level %d[/color] your class evolves again (Character > Class)." % int(ClassTree.PICK_LEVELS[state.class_path.size()])
	path_label.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), text]

	var spent := 0
	for st in GameData.STAT_ORDER:
		spent += int(state.stats.get(st, 0))
	respec_button.text = "Respec all points  (free: Tome of Forgetting)" if state.respec_tomes > 0 else "Respec all points  (%d gold)" % state.respec_cost()
	respec_button.disabled = spent == 0 or state.gold < state.respec_cost()

## One card per special stat (your unique class's and your hidden class's).
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
		var c := UI.card(col, UI.INSET, 4)
		special_box.add_child(c[0])
		var h := UI.hbox(8)
		c[1].add_child(h)
		var lbl := UI.label(n, 16, col)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(lbl)
		var val := UI.label("0", 20, UI.TEXT)
		h.add_child(val)
		var bar := UI.bar(col, 6)
		c[1].add_child(bar)
		var txt := UI.rich(12)
		c[1].add_child(txt)
		special_rows[n] = [val, txt, bar, c[0]]
