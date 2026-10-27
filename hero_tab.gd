class_name HeroTab
extends ScrollContainer
## the Hero page: who you are, your 8 stats, your special stat, your saved
## builds and the numbers it all adds up to. Laid out as one column of cards
## so it reads well on a phone.
## Interface pass: the top is a "stage": name plate, the hero big on a stone
## plinth, a paper doll of the six main gear slots (tap = Gear page), XP. Stats
## are compact icon + number cells (tap one to read what it does).
const FitBox := preload("res://fit_box.gd")

var main
var state: GameState

var card_style: StyleBoxFlat
var portrait: TextureRect
var _breath: Array = []  # the portrait's idle frames: the centrepiece breathes (2 fps)
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
var stat_grid: GridContainer
var stat_hold: Control   # FitBox around stat_grid
var special_box: VBoxContainer
var special_rows := {}  # name -> [value label, text rich, bar, panel]
var numbers := {}
var path_label: RichTextLabel
var respec_button: Button
var _look_key := ""
var _chip_key := ""
var title_pick: OptionButton  # 2.1 G4: the title you show (shared with the Guild Hall picker)
var _title_key := ""
var doll := {}       # slot -> [Button, caption Label]
const DOLL_LEFT := ["Weapon", "Helmet", "Chest"]
const DOLL_RIGHT := ["Off Hand", "Legs", "Feet"]
const DOLL_SIZE := 64
var _doll_key := ""
var _ghosts := {}

func setup(m) -> void:
	main = m
	state = m.state
	name = "Hero"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)

	# ---- The stage: name plate, hero on a plinth, paper doll, XP ----
	var card := PanelContainer.new()
	card_style = UI.style(UI.INSET, UI.CARD_EDGE, 6, 12, 1)   # kept for refresh(); the stage itself wears the frame
	card.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, UiSkin.IRON, 12))
	v.add_child(card)
	var sv := UI.vbox(8)
	card.add_child(sv)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiSkin.bevel(UiSkin.SLATE, UI.EDGE, 6))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sv.add_child(plate)
	var pv0 := UI.vbox(0)
	plate.add_child(pv0)
	title_label = UI.label("", UI.FONT_TITLE, UI.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.clip_text = true   # a long name never widens the screen
	title_label.custom_minimum_size = Vector2(220, 0)
	pv0.add_child(title_label)
	level_label = UI.label("", UI.FONT_BODY, UI.DIM_CONTRAST)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.clip_text = true
	level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pv0.add_child(level_label)
	role_label = UI.wrap("", UI.FONT_BODY, UI.DIM)   # the class blurb lives in the plate's tap-tip now (fewer words)
	role_label.visible = false
	sv.add_child(role_label)
	var mid := UI.hbox(4)
	sv.add_child(mid)
	var left := UI.vbox(6)
	mid.add_child(left)
	var center := Control.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(0, 3 * (DOLL_SIZE + 24) - 6)
	center.clip_contents = false
	mid.add_child(center)
	var right := UI.vbox(6)
	mid.add_child(right)
	for col in [[left, DOLL_LEFT], [right, DOLL_RIGHT]]:
		for slot in col[1]:
			col[0].add_child(_doll_slot(slot))
	var pl := TextureRect.new()
	pl.texture = UiIcons.plinth(64)
	pl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(pl)
	portrait = TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 3   # the hero is the centrepiece: 3x, whole pixels
	portrait.size = portrait.custom_minimum_size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(portrait)
	var breathe := Timer.new()
	breathe.wait_time = 0.5
	breathe.autostart = true
	breathe.timeout.connect(func():
		if _breath.size() > 1:
			portrait.texture = _breath[1] if portrait.texture == _breath[0] else _breath[0])
	center.add_child(breathe)
	center.resized.connect(func():   # centre the hero and its plinth in whatever width the phone gives
		UI.seat_hero(portrait, pl, 3, center.size.x / 2.0, UI.seat_ground(center.size.y, pl)))   # boots in the shadow
	chips = UI.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	sv.add_child(chips)
	xp_bar = UI.bar(UI.GOLD, 10)
	sv.add_child(xp_bar)
	xp_label = UI.label("", UI.FONT_BODY, UI.DIM)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(xp_label)
	UI.tip(plate, "Your hero. Tap a gear slot to change what you wear.")

	# ---- 2.1 G4 + G8: your title, and a picture of your hero to share ----
	var trow := UI.hbox(8)
	v.add_child(trow)
	trow.add_child(UI.label("Title:", UI.FONT_BODY, UI.DIM))
	title_pick = OptionButton.new()
	title_pick.fit_to_longest_item = false  # long titles would push the screen wider than a phone
	title_pick.clip_text = true
	title_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_pick.custom_minimum_size = Vector2(0, UI.TAP)
	title_pick.item_selected.connect(func(i: int):
		main.codex.title = "" if i == 0 else title_pick.get_item_text(i)
		main.codex.save()
		main.refresh())
	UI.tip(title_pick, "Titles come from deeds (Guild Hall) and from filling the Codex (Codex › Rewards). Looks only.")
	trow.add_child(title_pick)
	var share := UI.button("Share", func(): ShareCard.share(main))
	UI.tip(share, "Makes a picture of your hero to share.")
	share.custom_minimum_size = Vector2(96, UI.TAP)
	trow.add_child(share)

	# ---- Points banner ----
	points_panel = UI.panel(Color("#2a2010"), UI.GOLD, 8, 10, 1)
	v.add_child(points_panel)
	var pv := UI.vbox(8)
	points_panel.add_child(pv)
	points_label = UI.rich(UI.FONT_BODY)
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
	UI.section(v, "Stats", "Gold = your class wants it. Tap a stat to see what it does.")
	# Small boxes side by side: 2 across on phones, 4 on wider screens (see _fit_stat_grid)
	stat_grid = GridContainer.new()
	stat_grid.columns = 2
	stat_grid.add_theme_constant_override("h_separation", 6)
	stat_grid.add_theme_constant_override("v_separation", 6)
	# Juzo (wide PC): 4 columns made the grid 784 px wide, which kept the page wide enough for 4
	# columns, so it never went back to 2 and pushed the screen past the window. The holder's
	# width (what the page gives) picks the columns now.
	stat_hold = FitBox.hold(stat_grid)
	stat_hold.resized.connect(_fit_stat_grid)
	v.add_child(stat_hold)
	for st in GameData.STAT_ORDER:
		stat_grid.add_child(_stat_row(st))

	# ---- Special stats ----
	special_box = UI.vbox(6)
	v.add_child(special_box)
	UI.section(special_box, "Special stat", "Unique classes have a stat of their own. It can't take points: it grows from doing what your class does best.")

	# ---- Presets (2.1: builds, gear loadouts and team presets in one screen) ----
	UI.section(v, "Presets", "Save your stats, skills, gear, team and supplies together, then switch between them for free (say, a boss build and a farming build).")
	var pb := UI.button("Presets", func(): PresetsScreen.new().show_for(main))
	pb.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(pb)

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
		var k := UI.label(key, UI.FONT_BODY, UI.DIM)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ng.add_child(k)
		var val := UI.label("", UI.FONT_BODY, UI.TEXT)
		ng.add_child(val)
		numbers[key] = val

	# ---- Path + respec ----
	path_label = UI.rich(UI.FONT_BODY)
	v.add_child(path_label)
	respec_button = UI.button("", func(): main.confirm("Respec all stat points?", "You'll get every stat point back to spend again. Your class stays the same.", "Respec", func(): state.respec(); main.refresh()))
	respec_button.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(respec_button)

func _stat_row(st: String) -> PanelContainer:
	var info: Dictionary = GameData.STAT_INFO[st]
	var c := UI.card(UI.CARD_EDGE, UI.INSET, 4)   # suggested stats get a gold edge (refresh)
	var box: PanelContainer = c[0]
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bv: VBoxContainer = c[1]
	bv.add_theme_constant_override("separation", 2)
	UI.tip(box, "%s: %s" % [info["name"], info["text"]])
	# [icon] STR            87 ★
	var nh := UI.hbox(8)
	bv.add_child(nh)
	var ic := TextureRect.new()
	ic.texture = UiIcons.big(UiIcons.stat(st), 56)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.custom_minimum_size = Vector2(48, 56)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nh.add_child(ic)
	var ab := UI.label(st, UI.FONT_BODY, UI.TEXT)
	ab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nh.add_child(ab)
	var sp := UI.spacer()
	nh.add_child(sp)
	var val := UI.label("0", UI.FONT_DISPLAY, Color("#f4e6c4"))
	val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nh.add_child(val)
	var chip := UI.label("★", UI.FONT_BODY, UI.GOLD)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	UI.tip(chip, "Suggested for your class")
	nh.add_child(chip)
	# What it gives: in the tap-tip and the numbers below; shown here only while you spend points
	var gives := UI.rich(UI.FONT_BODY)
	gives.visible = false
	bv.add_child(gives)
	var br := UI.hbox(4)
	bv.add_child(br)
	var p1 := UI.button("+1", func(): state.spend_point(st, 1); main.refresh())
	var p5 := UI.button("+5", func(): state.spend_point(st, 5); main.refresh())
	for b in [p1, p5]:
		b.custom_minimum_size = Vector2(0, UI.TAP)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		br.add_child(b)
	rows[st] = {"value": val, "gives": gives, "p1": p1, "p5": p5, "chip": chip, "box": box, "name": ab}
	return box

## One paper-doll slot: the worn item's picture (or a slate ghost of what goes there) and its name.
func _doll_slot(slot: String) -> Control:
	var col := UI.vbox(2)
	var b := Button.new()
	b.custom_minimum_size = Vector2(DOLL_SIZE, DOLL_SIZE)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.pressed.connect(func(): main.show_tab(1, 0))
	b.tooltip_text = slot
	col.add_child(b)
	var cap := UI.label(slot.replace("Off Hand", "Off-hand").replace("Helmet", "Head"), UI.FONT_BODY, UI.DIM)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)
	doll[slot] = [b, cap]
	return col

## The slot's usual gear picture as a slate shape (no random item roll, so the game's RNG is untouched).
const GHOST_ART := {"Weapon": ["sword", "steel"], "Off Hand": ["buckler", "wood"], "Helmet": ["helm", "steel"],
	"Chest": ["plate_masc", "steel"], "Legs": ["greaves_masc", "steel"], "Feet": ["boots_masc", "leather"]}

func _ghost(s: String) -> Texture2D:
	if not _ghosts.has(s):
		var spec: Array = GHOST_ART.get(s, ["sword", "steel"])
		_ghosts[s] = UiIcons.ghost(UiIcons.gear(spec[0], spec[1]))
	return _ghosts[s]

func _refresh_doll() -> void:
	var key := str(state.equipped)
	if key == _doll_key:
		return
	_doll_key = key
	for slot in doll:
		var b: Button = doll[slot][0]
		var worn: bool = state.equipped.has(slot)
		b.icon = UiIcons.big(Sprites.item_icon(state.equipped[slot]) if worn else _ghost(slot), DOLL_SIZE - 12)
		var edge := Color(GameData.color_of(int(state.equipped[slot].get("rarity", 0)))) if worn else UI.EMPTY
		for st_name in ["normal", "hover", "pressed", "focus"]:
			var sb: StyleBox = UiSkin.bevel(UI.INSET, edge if st_name != "hover" else UI.GOLD_DULL, 2, st_name == "pressed")
			b.add_theme_stylebox_override(st_name, sb)

func _fit_stat_grid() -> void:
	var cols := 4 if stat_hold.size.x >= 680.0 else 2
	if stat_grid.columns != cols:
		stat_grid.columns = cols

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
	card_style.border_color = UI.CARD_EDGE
	var key := str(state.appearance) + Sprites._looks_key(state.hero_looks()) + state.title()
	if key != _look_key:
		_look_key = key
		_breath = Sprites.portrait_frames(state.appearance, state.hero_looks())
		portrait.texture = _breath[0]
	title_label.text = state.hero_name if state.hero_name != "" else state.title()
	title_label.add_theme_color_override("font_color", UI.GOLD)
	var cur := ClassTree.current(state)
	role_label.text = String(cur["role_text"]) if not cur.is_empty() else String(state.class_info().get("blurb", ""))
	level_label.text = "%s  ·  Lv %d" % [state.title(), state.level]
	level_label.add_theme_color_override("font_color", UI.TEXT)   # Fable r2 #11: names in bone; the class colour lives in the outfit
	# Juzo (wide PC): the plate is as wide as its line ("The Undying Fool · Lv 39" was cut at both ends
	# in a 220 px plate), up to the stage's width; past that the line ends in "…"
	var lf := level_label.get_theme_font("font")
	var need := lf.get_string_size(level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, level_label.get_theme_font_size("font_size")).x + 2.0
	level_label.custom_minimum_size.x = minf(ceilf(need), maxf(0.0, (level_label.get_parent().get_parent().get_parent() as Control).size.x - 40.0))
	_refresh_doll()
	_fill_titles()
	var al := ClassTree.alignment(state)
	var chip_key := "%s|%s|%s" % [state.race(), al, ClassTree.rank_of(cur)]
	if chip_key != _chip_key:   # Fable r1 #11: only rebuilt when race, faith side or rank change
		_chip_key = chip_key
		for c in chips.get_children():
			c.queue_free()
		chips.add_child(UI.chip(state.race(), Color(state.race_info().get("color", "#e8b14a")), UI.FONT_BODY))
		chips.add_child(UI.chip(String(ClassTree.ALIGN_NAMES[al]), Color(ClassTree.ALIGN_COLORS[al]), UI.FONT_BODY))
		if ClassTree.rank_of(cur) != "":
			chips.add_child(UI.chip("%s rank" % ClassTree.rank_of(cur), Color(ClassTree.RANK_COLORS[ClassTree.rank_of(cur)]), UI.FONT_BODY))
	xp_bar.max_value = GameData.xp_to_next(state.level)
	xp_bar.value = state.xp
	xp_label.text = "%s / %s XP to level %d" % [UI._commas(state.xp), UI._commas(GameData.xp_to_next(state.level)), state.level + 1]

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
			("  [color=%s](+%d race)[/color]" % [UI.hex(UI.DIM.darkened(0.2)), bonus]) if bonus > 0 else ""]
		(r["p1"] as Button).disabled = state.stat_points < 1
		(r["p5"] as Button).disabled = state.stat_points < 5
		# no points to spend: drop the buttons so the boxes stay small
		(r["p1"] as Button).get_parent().visible = state.stat_points > 0
		(r["chip"] as Control).visible = b.has(st)
		var sb := (r["box"] as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		var want := UI.GOLD if b.has(st) else UI.CARD_EDGE
		if sb.border_color != want:   # only touch the style when it changes
			sb.border_color = want
			sb.set_border_width_all(2 if b.has(st) else 1)
			(r["name"] as Label).add_theme_color_override("font_color", UI.GOLD if b.has(st) else UI.TEXT)

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

	# Where you're headed
	var text := ""
	var t := ClassTree.pick_tier(state)
	if t >= 0:
		text = "[color=#e8b14a]You can choose your next class now[/color] in Hero › Class."
	elif state.god_class != "" or state.hidden_class != "" or state.class_path.size() >= 3:
		text = "Your evolution tree is complete. Your special stat keeps growing."
	else:
		text = "At [color=#e8b14a]level %d[/color] your class evolves again (Hero › Class)." % int(ClassTree.PICK_LEVELS[state.class_path.size()])
	path_label.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), text]

	var spent := 0
	for st in GameData.STAT_ORDER:
		spent += int(state.stats.get(st, 0))
	respec_button.text = "Respec all points · free (Tome of Forgetting)" if state.respec_tomes > 0 else UI.cost("Respec all points", state.respec_cost())
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
		var lbl := UI.label(n, UI.FONT_CAPTION, col)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(lbl)
		var val := UI.label("0", 20, UI.TEXT)
		h.add_child(val)
		var bar := UI.bar(col, 6)
		c[1].add_child(bar)
		var txt := UI.rich(UI.FONT_BODY)
		c[1].add_child(txt)
		special_rows[n] = [val, txt, bar, c[0]]

## 2.1 G4: the title picker (rebuilt only when your titles or your pick change).
func _fill_titles() -> void:
	var c: Codex = main.codex
	var list := c.titles()
	var key := c.title + "|" + str(list.size())
	if key == _title_key:
		return
	_title_key = key
	title_pick.clear()
	title_pick.add_item("(none)")
	for t in list:
		title_pick.add_item(t)
		if t == c.title:
			title_pick.select(title_pick.item_count - 1)
	# Fable r3 #13: no "Title: (none)" picker until there is a title to pick (Share stays)
	title_pick.visible = not list.is_empty()
	(title_pick.get_parent().get_child(0) as Control).visible = title_pick.visible
