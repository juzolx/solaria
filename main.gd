extends Node2D
## The main screen: top bar, the fight on the left, and three tab groups on
## the right (Character, Items, Town). Each tab lives in its own file:
## hero_tab, class_tab, skills_tab, gear_tab, bag_tab, shop_tab, craft_tab.
## Game rules are in game_state.gd, numbers and content in game_data.gd.

const TURN_SECONDS := 1.0

var state := GameState.new()
var profile: Profile
var codex: Codex
var sfx := Sfx.new()
var timer := Timer.new()
var last_tap_ms := 0

# Tabs
var tabs: TabContainer
var char_tabs: TabContainer
var item_tabs: TabContainer
var town_tabs: TabContainer
var hero_tab: HeroTab
var class_tab: ClassTab
var skills_tab: SkillsTab
var gear_tab: GearTab
var bag_tab: BagTab
var shop_tab: ShopTab
var craft_tab: CraftTab
var online_tabs: TabContainer
var leaderboard_tab: LeaderboardTab
var guild_tab: GuildTab
var raid_tab: RaidTab
var codex_tabs: TabContainer
var bestiary_tab: BestiaryTab
var collection_tab: CollectionTab
var stats_tab: StatsTab
var achievements_tab: AchievementsTab
var bounty_tab: BountyTab
var guide_tab: GuideTab
var stash_tab: StashTab
var party_tab: PartyTab
var race_tab: RaceTab
var moment_queue: Array = []
var escape_button: Button
var spare_button: Button
var wheel_tab: WheelTab

# Top bar
var class_label: Label
var xp_bar: ProgressBar
var zone_label: Label
var floor_label: Label
var pips: Array[PanelContainer] = []
var boss_pill: PanelContainer
var boss_label: Label
var best_label: Label
var gold_label: Label
var scrap_label: Label
var potion_label: Label

# Fight panel
var battle: BattleView
var log_label: RichTextLabel
var log_lines: Array[String] = []
var skill_buttons: Array[Button] = []  # one per active skill slot
var auto_ability_button: Button
var potion_button: Button
var auto_potion_button: Button
var floors_button: Button
var speed_button: Button
var class_overlay: Overlay
var started := false
var event_pill: PanelContainer
var path_panel: PanelContainer
var path_count_label: Label
var body: BoxContainer
var left_panel: VBoxContainer
var title_label: Label
var online: Online
var fallen_shown := false

func _ready() -> void:
	# Let the layout stretch when the window is resized (and on phones later)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	add_child(sfx)
	UI.sfx = sfx
	profile = Profile.load_profile()
	codex = Codex.load_codex()
	state.codex = codex
	_migrate_old_saves()
	online = Online.new()
	online.setup(profile)
	add_child(online)
	_build_ui()
	timer.timeout.connect(_on_tick)
	add_child(timer)
	apply_settings()
	var action := TitleScreen.pending
	TitleScreen.pending = {}
	if action.has("new"):
		new_hero(int(action["new"]), bool(action.get("hc", false)))
	elif action.has("play") and GameState.has_slot(int(action["play"])):
		play_slot(int(action["play"]))
	else:
		show_title()

## Older versions had one Regular and one Hardcore save: move them into hero slots.
func _migrate_old_saves() -> void:
	var first_profile := not FileAccess.file_exists(Profile.PATH)
	var moved := GameState.migrate_legacy()
	if not moved.is_empty():
		profile.active_slot = moved[1] if profile.last_mode == "hardcore" and moved.size() > 1 else moved[0]
		if first_profile:  # settings used to live in the save file
			var old := GameState.new()
			old.autosave = false
			old.slot = int(moved[0])
			if old.load_game():
				profile.take_settings_from(old)
	for n in range(1, GameData.MAX_HEROES + 1):
		profile.max_floor = maxi(profile.max_floor, int(GameState.slot_meta(n).get("best", 0)))
	profile.save()

func show_title() -> void:
	timer.stop()
	TitleScreen.new().show_for(self)

## Saves and goes back to the title screen (to switch heroes).
func back_to_title() -> void:
	if started and not state.run_over:
		state.save_game()
		if state.party != null:
			state.party.save_all()
	codex.save()
	profile.save()
	timer.stop()
	get_tree().reload_current_scene()

## Starts playing the hero in a slot.
func play_slot(n: int) -> void:
	state.slot = n
	_start(false)

## Makes a new hero in a slot: race and look, then a class.
func new_hero(n: int, hc: bool) -> void:
	GameState.delete_slot(n)
	state.slot = n
	state.hardcore = hc
	_start(true)

## Loads (or makes) the hero in state.slot and starts the fight.
func _start(is_new: bool) -> void:
	started = true
	profile.active_slot = state.slot
	profile.save()
	state.codex = codex
	var loaded := false if is_new else state.load_game()
	state.stash_ok = not state.hardcore
	if loaded:
		state.say("Welcome back, %s. Floor %d, %s." % [state.hero_name if state.hero_name != "" else "hero", state.floor_num, GameData.sub_name(state.floor_num)])
		if state.restored_backup:
			state.say("[color=#f87171]Your save was damaged, so your backup save was restored.[/color]")
	else:
		state.new_game()
		state.say("Your descent begins..." if not state.hardcore else "[color=#f87171]Hardcore: one life. Make it count.[/color]")
	state.dev_mode = profile.dev_mode
	state.path_rooms_on = profile.path_choice != "fight"
	_share_skill_book()
	if not state.hardcore and not state.party_slots.is_empty():
		state.set_party(state.party_slots)
	state.tip("tap", "Your hero fights on their own. Tap the enemy to hit it yourself for bonus damage!")
	battle.state = state
	battle.sfx = sfx
	battle.profile = profile
	battle.last_floor = state.floor_num
	battle.tapped.connect(_on_battle_tapped)
	if state.hero_class != "":
		battle.set_cape(Color(state.class_info()["color"]))
	apply_settings()
	codex.refresh_bounties(state)

	timer.wait_time = TURN_SECONDS / 2.0 if state.fast_mode else TURN_SECONDS
	if not loaded or state.needs_creator:
		_show_creator(not loaded)
	elif state.hero_class == "":
		_show_class_picker()
	else:
		timer.start()
		_daily_login()
	refresh()

## Regular heroes share one skill book (kept in the profile). Merges this hero's
## skills in (keeping the higher rank) and points the hero at the shared book.
func _share_skill_book() -> void:
	if state.hardcore:
		return
	for id in state.skill_book:
		profile.skill_book[id] = maxi(int(profile.skill_book.get(id, 0)), int(state.skill_book[id]))
	state.skill_book = profile.skill_book
	profile.save()

## Once a day: a small reward that grows over a 7-day streak.
func _daily_login() -> void:
	var day := codex.check_login()
	if day <= 0:
		return
	var r: Dictionary = Codex.LOGIN_REWARDS[day - 1]
	var got := state.give_reward(r)
	state.save_game()
	codex.save()
	var o := Overlay.new().open(self, "Daily reward", 520.0, UI.GOLD)
	o.content.add_child(UI.label("Day %d of your streak" % int(codex.login["streak"]), 15, UI.TEXT))
	var row := UI.hbox(6)
	o.content.add_child(row)
	for i in Codex.LOGIN_REWARDS.size():
		var today := i == day - 1
		var done := i < day - 1
		var c := UI.panel(Color("#2a2010") if today else UI.INSET, UI.GOLD if today else (UI.GREEN if done else UI.BORDER), 6, 6, 2 if today else 1)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(2)
		c.add_child(v)
		v.add_child(UI.label("Day %d" % (i + 1), 11, UI.GOLD if today else UI.DIM))
		var l := UI.label(str(Codex.LOGIN_REWARDS[i]["text"]), 11, UI.TEXT if (today or done) else UI.DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		row.add_child(c)
	var got_label := UI.rich(14)
	got_label.text = "Today: " + got
	o.content.add_child(got_label)
	o.content.add_child(UI.label("Come back tomorrow to keep the streak going.", 12, UI.DIM))
	sfx.play("buy")
	refresh()

## The character creator: new heroes pick race and look; older heroes pick once.
func _show_creator(new_hero: bool) -> void:
	timer.stop()
	var title := "Create your hero" if new_hero else "New: pick your hero's race and look"
	CharacterCreator.new().show_for(self, state.appearance, func(app: Dictionary):
		if app.has("name"):
			state.hero_name = str(app["name"])
			app.erase("name")
		state.appearance = app
		state.needs_creator = false
		var hp_full := state.hero_hp >= state.get_max_hp()
		if hp_full or new_hero:
			state.hero_hp = state.get_max_hp()
		state.save_game()
		if state.hero_class == "":
			_show_class_picker()
		else:
			timer.start()
		refresh(), title, false, {}, new_hero or state.hero_name == "")

## A fork in the dungeon: pick the next room (shown over the fight).
func _show_path_choice() -> void:
	path_panel = UI.panel(Color(UI.PANEL, 0.97), UI.GOLD, 10, 12, 2)
	path_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	battle.add_child(path_panel)
	var v := UI.vbox(8)
	path_panel.add_child(v)
	var title := Realms.path_title(state)
	if title == "":
		title = "A cursed shrine" if "shrine" in state.path_offer else "A fork in the dungeon"
	var t := UI.label(title, 18, UI.GOLD if not "shrine" in state.path_offer else UI.PURPLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var row := UI.hbox(8)
	v.add_child(row)
	for kind in state.path_offer:
		var info: Dictionary = state.path_info(kind)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 112)
		b.focus_mode = Control.FOCUS_NONE
		var c := Color(info["color"])
		b.add_theme_stylebox_override("normal", UI.style(UI.INSET, c.darkened(0.3), 8, 8, 2))
		b.add_theme_stylebox_override("hover", UI.style(UI.INSET.lightened(0.06), c, 8, 8, 2))
		b.add_theme_stylebox_override("pressed", UI.style(UI.INSET, c, 8, 8, 3))
		var bv := UI.vbox(4)
		bv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bv.offset_left = 8
		bv.offset_right = -8
		bv.offset_top = 6
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var n := UI.label(info["name"], 14, c)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(n)
		var d := UI.label(info["text"], 11, UI.TEXT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(d)
		b.pressed.connect(_choose_path.bind(kind))
		row.add_child(b)
	path_count_label = UI.label("", 11, UI.DIM)
	path_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(path_count_label)
	await get_tree().process_frame
	if is_instance_valid(path_panel):
		path_panel.position = (battle.size - path_panel.size) / 2.0

func _choose_path(kind: String) -> void:
	state.choose_path(kind)
	sfx.play({"treasure": "buy", "rest": "potion", "elite": "boss_intro", "merchant": "buy", "shrine": "rare_spawn", "camp": "potion",
		"attack": "boss_intro", "trade": "buy"}.get(kind, "portal" if kind.begins_with("portal:") else "click"))
	if path_panel:
		path_panel.queue_free()
		path_panel = null
		path_count_label = null
	refresh()

## After a defeat: a card over the fight with what hurt you most and a tip.
var recap_panel: PanelContainer
func _show_recap() -> void:
	var r: Dictionary = state.last_death
	if r.is_empty() or battle == null:
		return
	if is_instance_valid(recap_panel):
		recap_panel.queue_free()
	recap_panel = UI.panel(Color(UI.PANEL, 0.97), UI.RED, 10, 12, 2)
	battle.add_child(recap_panel)
	var v := UI.vbox(6)
	recap_panel.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	var tl := UI.label("Defeated by %s" % r.get("enemy", "?"), 17, UI.RED)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var close := UI.button("OK", func():
		if is_instance_valid(recap_panel):
			recap_panel.queue_free())
	close.custom_minimum_size = Vector2(56, UI.TAP)
	head.add_child(close)
	var taken: Dictionary = r.get("taken", {})
	var total := maxf(1.0, float(r.get("total", 0)))
	var names := {"hits": "its hits", "burning": "burning", "burn": "burns", "poison": "poison", "minions": "minions", "realm": "the realm"}
	var parts: Array = []
	var keys := taken.keys()
	keys.sort_custom(func(a, b): return int(taken[a]) > int(taken[b]))
	for k in keys:
		parts.append("%s %d%%" % [names.get(k, String(k)), int(round(float(taken[k]) * 100.0 / total))])
	var info := UI.rich(12)
	info.text = "[color=%s]%d turns. Damage you took: %s. Biggest hit: %d. It had %d%% health left.[/color]" % [UI.hex(UI.DIM), int(r.get("turns", 0)),
		", ".join(parts) if not parts.is_empty() else "none", int(r.get("biggest", 0)), int(float(r.get("enemy_left", 0.0)) * 100)]
	v.add_child(info)
	for tip_text in r.get("tips", []):
		var t := UI.rich(13)
		t.text = "[color=#e8b14a]Tip:[/color] %s" % tip_text
		v.add_child(t)
	var off := UI.button("Don't show these again", func():
		profile.show_recap = false
		profile.save()
		if is_instance_valid(recap_panel):
			recap_panel.queue_free())
	off.add_theme_font_size_override("font_size", 11)
	v.add_child(off)
	recap_panel.custom_minimum_size.x = minf(520.0, battle.size.x - 24.0)
	await get_tree().process_frame
	if is_instance_valid(recap_panel):
		recap_panel.position = Vector2((battle.size.x - recap_panel.size.x) / 2.0, 40.0)
		var p := recap_panel
		get_tree().create_timer(14.0).timeout.connect(func():
			if is_instance_valid(p):
				p.create_tween().tween_property(p, "modulate:a", 0.0, 0.5).finished.connect(p.queue_free))

## Change your look later (race stays).
func show_look_editor() -> void:
	timer.stop()
	CharacterCreator.new().show_for(self, state.appearance, func(app: Dictionary):
		state.appearance = app
		state.save_game()
		timer.start()
		refresh(), "Change your look", true, state.hero_looks())

## A Hardcore hero died: record it, delete it, and offer a new run.
func _on_hardcore_death() -> void:
	fallen_shown = true
	timer.stop()
	var new_best := profile.record_hc_run(state)
	state.delete_own_saves()
	codex.save()
	if online:
		online.submit_run(state)
	var o := Overlay.new().open(self, "Your hero has fallen", 520.0, UI.RED, false)
	var t := UI.rich(15)
	t.text = "%s, your level %d %s [color=#f87171][b]%s[/b][/color], fell on [color=#e8b14a]floor %d[/color]. Hardcore heroes only get one life.\n\n%s\nTheir kills stay in your Bestiary." % [
		state.hero_name if state.hero_name != "" else "Hero", state.level, state.race(), state.title(), state.floor_num,
		"[color=#fbbf24]A new Hardcore record![/color]" if new_best else "Your best is still floor %d." % profile.hc_best]
	o.content.add_child(t)
	var row := UI.hbox(8)
	o.content.add_child(row)
	var slot_n := state.slot
	var again := UI.primary("New Hardcore hero", func():
		TitleScreen.pending = {"new": slot_n, "hc": true}
		get_tree().reload_current_scene(), UI.RED)
	var back := UI.button("Title screen", func(): get_tree().reload_current_scene())
	for b in [back, again]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		row.add_child(b)

func _on_tick() -> void:
	state.take_turn()
	refresh()

# =====================================================================
# Building the screen
# =====================================================================

func _build_ui() -> void:
	RenderingServer.set_default_clear_color(UI.BG)
	var root := MarginContainer.new()
	root.theme = UI.make_theme()
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 10)
	add_child(root)
	var fit := func(): root.size = get_viewport().get_visible_rect().size
	fit.call()
	get_viewport().size_changed.connect(fit)

	var main_v := UI.vbox(10)
	root.add_child(main_v)
	_build_top_bar(main_v)

	# Side by side on wide screens; fight on top and tabs below on tall (phone) screens
	body = BoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_v.add_child(body)
	left_panel = UI.vbox(10)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left_panel)
	var left := left_panel
	_build_fight(left)

	tabs = TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_stretch_ratio = 1.2
	tabs.tab_changed.connect(func(_i): sfx.play("click"); refresh())
	body.add_child(tabs)
	char_tabs = _group("Character")
	item_tabs = _group("Items")
	town_tabs = _group("Town")
	codex_tabs = _group("Codex")
	online_tabs = _group("Online")
	leaderboard_tab = LeaderboardTab.new()
	guild_tab = GuildTab.new()
	raid_tab = RaidTab.new()
	hero_tab = HeroTab.new()
	class_tab = ClassTab.new()
	skills_tab = SkillsTab.new()
	gear_tab = GearTab.new()
	bag_tab = BagTab.new()
	shop_tab = ShopTab.new()
	craft_tab = CraftTab.new()
	stash_tab = StashTab.new()
	party_tab = PartyTab.new()
	race_tab = RaceTab.new()
	wheel_tab = WheelTab.new()
	bestiary_tab = BestiaryTab.new()
	collection_tab = CollectionTab.new()
	stats_tab = StatsTab.new()
	achievements_tab = AchievementsTab.new()
	bounty_tab = BountyTab.new()
	guide_tab = GuideTab.new()
	for pair in [[char_tabs, hero_tab], [char_tabs, class_tab], [char_tabs, race_tab], [char_tabs, skills_tab], [char_tabs, party_tab],
			[item_tabs, gear_tab], [item_tabs, bag_tab], [item_tabs, stash_tab], [town_tabs, shop_tab], [town_tabs, craft_tab], [town_tabs, wheel_tab],
			[codex_tabs, bestiary_tab], [codex_tabs, collection_tab], [codex_tabs, achievements_tab], [codex_tabs, bounty_tab],
			[codex_tabs, stats_tab], [codex_tabs, guide_tab],
			[online_tabs, leaderboard_tab], [online_tabs, guild_tab], [online_tabs, raid_tab]]:
		pair[1].setup(self)
		(pair[0] as TabContainer).add_child(pair[1])
	tabs.current_tab = 1  # start on Items
	_fit_layout()
	get_viewport().size_changed.connect(_fit_layout)

## Phone-style tall screens stack the fight above the tabs.
func _fit_layout() -> void:
	var win := get_tree().root.size
	var tall := win.x < win.y * 0.95
	# Keep text the same size in both orientations (the design size is 1152x648)
	# Interface size (accessibility): a smaller design size makes everything bigger
	var zoom: float = [1.12, 1.0, 0.86][clampi(profile.text_size if profile else 1, 0, 2)]
	var want := Vector2i(Vector2(648, 1152) * zoom) if tall else Vector2i(Vector2(1152, 648) * zoom)
	if get_tree().root.content_scale_size != want:
		get_tree().root.content_scale_size = want
	body.vertical = tall
	left_panel.size_flags_stretch_ratio = 0.9 if tall else 1.0
	tabs.size_flags_stretch_ratio = 1.1 if tall else 1.2
	title_label.visible = not tall
	best_label.visible = not tall
	event_pill.visible = not tall
	scrap_label.get_parent().visible = not tall
	potion_label.get_parent().visible = not tall
	xp_bar.custom_minimum_size.x = 100 if tall else 150
	if log_label:
		log_label.custom_minimum_size.y = 60 if tall else 80

func _group(title: String) -> TabContainer:
	var t := TabContainer.new()
	t.name = title
	t.theme_type_variation = "SubTabs"
	t.tab_changed.connect(func(_i): sfx.play("click"); refresh())
	tabs.add_child(t)
	return t

func _build_top_bar(parent: Control) -> void:
	var bar := UI.panel(UI.PANEL, UI.BORDER, 10, 8, 1)
	bar.get_theme_stylebox("panel").content_margin_left = 14
	bar.get_theme_stylebox("panel").content_margin_right = 10
	parent.add_child(bar)
	var row := UI.hbox(16)
	bar.add_child(row)

	# Left: game name + your hero
	var title := UI.label("SOLARIA", 20, UI.GOLD)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	title_label = title
	var hero := UI.vbox(3)
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hero)
	class_label = UI.label("", 14, UI.TEXT)
	class_label.mouse_filter = Control.MOUSE_FILTER_PASS
	hero.add_child(class_label)
	xp_bar = UI.bar(UI.GOLD, 5)
	xp_bar.custom_minimum_size = Vector2(150, 5)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	hero.add_child(xp_bar)

	row.add_child(UI.spacer())

	# Middle: where you are
	var mid := UI.vbox(2)
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mid)
	zone_label = UI.label("", 11, UI.DIM)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(zone_label)
	var frow := UI.hbox(8)
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(frow)
	floor_label = UI.label("", 17, UI.TEXT)
	frow.add_child(floor_label)
	var pip_row := UI.hbox(4)
	pip_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(pip_row)
	for i in GameData.FIGHTS_PER_FLOOR:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(10, 10)
		p.add_theme_stylebox_override("panel", UI.style(UI.EMPTY, UI.EMPTY, 5, 0, 1))
		pip_row.add_child(p)
		pips.append(p)
	var bp := UI.pill(UI.RED)
	boss_pill = bp[0]
	boss_label = bp[1]
	boss_label.add_theme_font_size_override("font_size", 12)
	boss_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(boss_pill)
	best_label = UI.label("", 12, UI.DIM)
	best_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(best_label)
	var ep := UI.pill(UI.PINK)
	event_pill = ep[0]
	var names := []
	var tips := []
	for id in GameData.active_events():
		names.append(GameData.EVENTS[id]["name"])
		tips.append("%s: %s" % [GameData.EVENTS[id]["name"], GameData.EVENTS[id]["text"]])
	(ep[1] as Label).text = " + ".join(names)
	(ep[1] as Label).add_theme_font_size_override("font_size", 11)
	event_pill.tooltip_text = "Events running now:\n" + "\n".join(tips)
	event_pill.mouse_filter = Control.MOUSE_FILTER_STOP
	event_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	row.add_child(UI.spacer())
	row.add_child(event_pill)

	# Right: resources + menu
	var g := UI.pill(UI.GOLD)
	var s := UI.pill(Color("#9fb0cc"))
	var p2 := UI.pill(UI.PINK)
	gold_label = g[1]
	scrap_label = s[1]
	potion_label = p2[1]
	(g[0] as Control).tooltip_text = "Gold: from enemies and selling. Spend it in Town > Shop."
	(s[0] as Control).tooltip_text = "Scrap: from salvaging. Use it to upgrade, reroll and craft."
	(p2[0] as Control).tooltip_text = "Potions heal 40% HP."
	for pill in [g[0], s[0], p2[0]]:
		(pill as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pill)
	var menu := UI.button("Menu", func(): SettingsMenu.new().show_for(self))
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(menu)

func _build_fight(parent: Control) -> void:
	var frame := UI.panel(UI.PANEL, UI.BORDER, 10, 2)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)
	battle = BattleView.new()
	battle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(battle)

	var panel := UI.panel(UI.PANEL, UI.BORDER, 10, 10)
	parent.add_child(panel)
	var col := UI.vbox(8)
	panel.add_child(col)
	log_label = UI.rich(12, false)
	log_label.custom_minimum_size = Vector2(0, 80)
	col.add_child(log_label)

	var ability_row := UI.hbox(6)
	col.add_child(ability_row)
	for i in 3:
		var b := UI.primary("", func():
			var id: String = state.active_slots[i]
			if id != "" and state.use_skill(id):
				refresh(), UI.GOLD)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		ability_row.add_child(b)
		skill_buttons.append(b)
	auto_ability_button = UI.button("", func():
		state.auto_ability = not state.auto_ability
		state.save_game()
		refresh())
	auto_ability_button.tooltip_text = "Use your skills automatically whenever they're ready"
	auto_ability_button.custom_minimum_size = Vector2(84, 0)
	ability_row.add_child(auto_ability_button)

	var buttons := GridContainer.new()
	buttons.columns = 4
	buttons.add_theme_constant_override("h_separation", 6)
	col.add_child(buttons)
	potion_button = UI.button("", func(): state.use_potion(); refresh())
	potion_button.tooltip_text = "Heal 40% of your max HP"
	auto_potion_button = UI.button("", func():
		state.auto_potion = not state.auto_potion
		state.save_game()
		refresh())
	auto_potion_button.tooltip_text = "Drink a potion automatically when HP drops below 30%"
	floors_button = UI.button("Floors", func(): FloorPicker.new().show_for(self))
	floors_button.tooltip_text = "Travel to any floor you've reached, including boss floors"
	speed_button = UI.button("", func():
		state.fast_mode = not state.fast_mode
		timer.wait_time = TURN_SECONDS / 2.0 if state.fast_mode else TURN_SECONDS
		state.save_game()
		refresh())
	speed_button.tooltip_text = "Make the fight run twice as fast"
	escape_button = UI.button("Run", func():
		Lineage.try_escape(state)
		refresh())
	escape_button.tooltip_text = "Try to run from this fight (no XP or loot from it). Your AGI helps; rarer monsters are harder to escape. Not from bosses."
	spare_button = UI.button("Spare", func():
		if Lineage.spare(state):
			sfx.play("buff")
		refresh())
	spare_button.tooltip_text = "Let a beaten monster go. It remembers you (half XP, no loot)."
	for b in [potion_button, auto_potion_button, floors_button, speed_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(b)
	var run_row := UI.hbox(6)
	col.add_child(run_row)
	for b in [escape_button, spare_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		run_row.add_child(b)

# =====================================================================
# Popups
# =====================================================================

## "Are you sure?" popup. on_yes runs only if the player confirms.
func confirm(title: String, text: String, yes_text: String, on_yes: Callable) -> void:
	var o := Overlay.new().open(self, title, 440.0, UI.RED)
	var body := UI.rich(14)
	body.text = text
	o.content.add_child(body)
	var row := UI.hbox(8)
	o.content.add_child(row)
	var no := UI.button("Cancel", o.close)
	var yes := UI.primary(yes_text, func(): o.close(); on_yes.call(), UI.RED)
	for b in [no, yes]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		row.add_child(b)

func _show_class_picker() -> void:
	class_overlay = Overlay.new().open(self, "Choose your class", 920.0, UI.GOLD, false)
	var sub := UI.label("Your class sets your strengths, your first skills and your look. Any class can use any skill stone, but skills sharing your class's tags hit harder.", 13, UI.DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	class_overlay.content.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport().get_visible_rect().size.x > 760 else 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	class_overlay.content.add_child(grid)
	for cname in Classes.ORDER:
		var info: Dictionary = Classes.CLASSES[cname]
		var color := Color(info["color"])
		var card := UI.panel(UI.INSET, color.darkened(0.2), 10, 10, 2)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var cv := UI.vbox(6)
		card.add_child(cv)
		var head := UI.hbox(8)
		cv.add_child(head)
		var pic := TextureRect.new()
		var looks := {}
		for slot in info["look"]:
			looks[slot] = Sprites.gear_look({"slot": slot, "type": info["look"][slot], "rarity": 1})
		pic.texture = Sprites.portrait(state.appearance, looks)
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.custom_minimum_size = Vector2(56, 56)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(pic)
		var hv := UI.vbox(0)
		head.add_child(hv)
		hv.add_child(UI.label(cname.to_upper(), 18, color.lightened(0.25)))
		var tags: Array = []
		for t in info["tags"]:
			tags.append("[color=%s]%s[/color]" % [Classes.tag_color(t), t])
		var tl := UI.rich(11)
		tl.text = "%s  -  %s" % [info["role"], " ".join(tags)]
		tl.custom_minimum_size = Vector2(170, 0)
		hv.add_child(tl)
		var text := UI.rich(12)
		text.custom_minimum_size = Vector2(240, 0)
		var start: Array = info["start"]
		text.text = "%s
[color=#e8b14a]%s[/color]: %s" % [info["blurb"], SkillData.skill_name(start[0]), SkillData.info(start[0])["text"]]
		cv.add_child(text)
		cv.add_child(UI.primary("Play as %s" % cname, _on_class_chosen.bind(cname), color))

func _on_class_chosen(cname: String) -> void:
	state.choose_class(cname)
	_give_class_outfit()
	battle.set_cape(Color(state.class_info()["color"]))
	if class_overlay:
		class_overlay.close()
		class_overlay = null
	timer.start()
	refresh()

## A new hero starts in their class's outfit (Common gear, worn).
func _give_class_outfit() -> void:
	var looks: Dictionary = state.class_info().get("look", {})
	for slot in looks:
		if state.equipped.has(slot):
			continue
		var item := GameData.make_item(slot, 0, 1, state._new_id())
		item["type"] = looks[slot]
		item["name"] = "Starting " + str(looks[slot]).capitalize()
		item["base_name"] = item["name"]
		item["flavor"] = "Everyone starts somewhere."
		state.equipped[slot] = item
		state.add_to_wardrobe(item)
	state.save_game()

## Levels 15, 35 and 60: choose where your Evolution Tree goes.
func _show_tree_picker() -> void:
	if ClassTree.pick_tier(state) < 0 or _popup_open():
		return
	timer.stop()
	var t := ClassTree.pick_tier(state)
	var o := Overlay.new().open(self, "Level %d: choose your class" % int(ClassTree.PICK_LEVELS[t]), 820.0, Color(state.class_info().get("color", "#e8b14a")), true)
	o.tree_exited.connect(func(): timer.start())
	var al := ClassTree.alignment(state)
	var intro := UI.rich(13)
	intro.text = "[color=%s]Your deeds are [color=%s][b]%s[/b][/color] (faith %+d). %s[/color]" % [UI.hex(UI.DIM), ClassTree.ALIGN_COLORS[al], ClassTree.ALIGN_NAMES[al], int(state.faith),
		"Good heroes can't take Evil classes, and Evil heroes can't take Good ones." if state.hero_class != "Wanderer" else "The Wanderer is always Neutral."]
	o.content.add_child(intro)
	for n in ClassTree.options(state):
		o.content.add_child(ClassTab.class_card(self, n, true, func():
			if ClassTree.pick(state, n["id"]):
				sfx.play("spec")
			o.close()
			refresh()))

func apply_settings() -> void:
	sfx.enabled = profile.sound_on
	sfx.set_volumes(profile.volume, profile.music_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if profile.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	state.dev_mode = profile.dev_mode
	state.path_rooms_on = profile.path_choice != "fight"
	profile.save()

func reset_save() -> void:
	timer.stop()
	state.run_over = true  # stop any more saving
	state.delete_own_saves()
	codex.save()
	get_tree().reload_current_scene()

# =====================================================================
# Input
# =====================================================================

func _on_battle_tapped(pos: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - last_tap_ms < int(GameData.TAP_COOLDOWN * 1000):
		return
	last_tap_ms = now
	battle.tap_ring(pos)
	if state.tap_attack():
		refresh()

## Jump to a tab: group 0 Character, 1 Items, 2 Town, 3 Codex, 4 Online.
func show_tab(group: int, sub: int) -> void:
	tabs.current_tab = group
	(_groups()[group] as TabContainer).current_tab = sub

func _groups() -> Array:
	return [char_tabs, item_tabs, town_tabs, codex_tabs, online_tabs]

# =====================================================================
# Refreshing the screen
# =====================================================================

func refresh() -> void:
	if battle == null or battle.state == null:
		return
	_handle_events()
	battle.play(state.events)
	state.events.clear()
	if not state.path_offer.is_empty() and path_panel == null:
		_show_path_choice()
	elif state.path_offer.is_empty() and path_panel != null:
		path_panel.queue_free()
		path_panel = null
		path_count_label = null
	if path_count_label:
		var auto_pick: String = state.path_info(state.auto_path())["name"]
		path_count_label.text = "Picks %s by itself in %d..." % [auto_pick, maxi(0, GameData.PATH_WAIT_TURNS - state.path_wait)]
	if state.run_over and not fallen_shown:
		get_tree().create_timer(1.6).timeout.connect(_on_hardcore_death)
		fallen_shown = true
	_play_moments()
	_pull_messages()
	_refresh_top()
	_refresh_fight()
	_refresh_tabs()
	sfx.update_music(state)

## Events that open popups: new guide pages, the merchant. Also keeps records.
func _handle_events() -> void:
	for e in state.events:
		match e["type"]:
			"guide":
				if codex.stat("guide_skip") == 0 and not _popup_open():
					GuideBook.open_book(self, e["id"], true)
			"merchant":
				MerchantPopup.new().show_for(self)
			"class_pick":
				_show_tree_picker.call_deferred()
			"class_up":
				var after_looks := state.hero_looks()
				var before_looks := after_looks.duplicate()
				if int(e.get("tier", 1)) >= 3 or e["rank"] != "":
					before_looks.erase("Cape")
					before_looks.erase("Aura")
				moment_queue.append(["evolve", {"name": e["name"], "role": e["role"],
					"color": Color(ClassTree.RANK_COLORS.get(e["rank"], e["color"])) if e["rank"] != "" else Color(e["color"]),
					"sub": ("%s rank unique class" % e["rank"]) if e["rank"] != "" else "Level %d evolution" % int(ClassTree.PICK_LEVELS[clampi(int(e.get("tier", 1)) - 1, 0, 2)]),
					"before": Sprites.portrait(state.appearance, before_looks), "after": Sprites.portrait(state.appearance, after_looks),
					"skill": e.get("skill", ""), "skill_text": e.get("skill_text", ""), "tier": int(e.get("tier", 1))}])
			"stone":
				profile.save()  # the shared skill book lives in the profile
			"realm_enter":
				var bgp := "res://art/bg/zone_%d_0.png" % Realms.zone_for_id(e["id"])
				moment_queue.append(["realm", e["name"], e["blurb"], Color(e["color"]), e["mechanic"], null, load(bgp) if ResourceLoader.exists(bgp) else null])
			"boss_intro":
				moment_queue.append(["boss", e["name"], e["lore"], Color(e["color"]), e.get("sub", ""), null])
			"awaken":
				moment_queue.append(["awaken", e["name"], e["text"], Color(e["color"]), "", Sprites.portrait(state.appearance, state.hero_looks())])
			"transform":
				moment_queue.append(["transform", e["form"], Races.FORMS[e["form"]]["text"], Color(e["color"]),
					"" if Races.FORMS[e["form"]]["curable"] else "This can't be undone.", Sprites.portrait(state.appearance, state.hero_looks())])
			"hidden_class":
				moment_queue.append(["hidden", e["name"], e["lore"], Color(e["color"]), Hidden.TIER_NAMES[int(e["tier"])], null])
			"camp":
				MerchantPopup.new().show_for(self)
			"key_item", "cured":
				sfx.play("unique")
			"escaped":
				sfx.play("escape")
			"death_recap":
				if profile.show_recap and not state.hardcore:
					_show_recap.call_deferred()
	if state.best_floor > profile.max_floor:
		var before := profile.slots_open()
		profile.max_floor = state.best_floor
		if profile.slots_open() > before:
			state.say("[color=#fbbf24]A new hero slot is open![/color] Make another hero from the title screen.")
		profile.save()

## Big moments play one at a time.
func _play_moments() -> void:
	if moment_queue.is_empty():
		return
	for c in get_children():
		if c is Moments:
			return
	var m: Array = moment_queue.pop_front()
	var mo: Moments
	if m[0] == "evolve":
		mo = Moments.evolve(self, m[1])
	else:
		mo = Moments.play(self, m[0], m[1], m[2], m[3], m[4], m[5], m[6] if m.size() > 6 else null)
	mo.tree_exited.connect(func(): if is_inside_tree(): _play_moments())

func _popup_open() -> bool:
	for c in get_children():
		if c is Overlay:
			return true
	return false

func _pull_messages() -> void:
	if state.messages.is_empty():
		return
	for msg in state.messages:
		log_lines.append(msg)
	state.messages.clear()
	while log_lines.size() > 5:
		log_lines.pop_front()
	var text := ""
	for n in log_lines.size():
		if n < log_lines.size() - 1:
			text += "[color=%s]%s[/color]\n" % [UI.hex(UI.DIM), log_lines[n]]
		else:
			text += log_lines[n]
	log_label.text = text

func _refresh_top() -> void:
	if state.hero_class != "":
		var nm := state.hero_name + "  " if state.hero_name != "" else ""
		var honor := "  \"%s\"" % codex.title if codex.title != "" else ""
		var hid := Hidden.title(state)
		class_label.text = "%sLv %d  %s%s%s" % [nm, state.level, state.title(), "  /  " + hid if hid != "" else "", honor]
		class_label.add_theme_color_override("font_color", Color(state.class_info()["color"]).lightened(0.3))
		class_label.tooltip_text = "XP %d / %d to level %d" % [state.xp, GameData.xp_to_next(state.level), state.level + 1]
		xp_bar.max_value = GameData.xp_to_next(state.level)
		xp_bar.value = state.xp
		xp_bar.tooltip_text = class_label.tooltip_text
	zone_label.text = (GameData.rank_prefix(state.floor_num) + str(GameData.zone_for_floor(state.floor_num)["name"]) + "  -  " + GameData.sub_name(state.floor_num)).to_upper()
	floor_label.text = "Floor %d" % state.floor_num
	var boss := state.enemy_is_boss
	boss_pill.visible = boss
	if boss:
		boss_label.text = "%s  -  unique %d%%" % ["MID BOSS" if state.enemy_boss_kind == "mid" else "ZONE BOSS", int(state.unique_chance())]
	for i in pips.size():
		pips[i].visible = not boss
		var done := i < state.fight - 1
		var current := i == state.fight - 1
		var st := UI.style(UI.GOLD if done else Color(0, 0, 0, 0), UI.GOLD if (done or current) else UI.EMPTY, 5, 0, 2 if current else 1)
		pips[i].add_theme_stylebox_override("panel", st)
	best_label.text = "Best %d" % state.best_floor
	gold_label.text = "Gold  %d" % state.gold
	scrap_label.text = "Scrap  %d" % state.scrap
	potion_label.text = "Potions  %d" % state.potions

func _refresh_fight() -> void:
	potion_button.text = "Potion (%d)" % state.potions
	potion_button.disabled = state.potions <= 0 or state.hero_hp >= state.get_max_hp()
	auto_potion_button.text = "Auto-heal %s" % ("ON" if state.auto_potion else "OFF")
	speed_button.text = "Speed %s" % ("2x" if state.fast_mode else "1x")
	floors_button.disabled = state.best_floor <= 1
	var acts := state.equipped_actives()
	for i in skill_buttons.size():
		var b: Button = skill_buttons[i]
		var id: String = state.active_slots[i] if i < state.active_slot_count() else ""
		if state.hero_class == "":
			b.visible = i == 0
			b.text = "Choose a class first"
			b.disabled = true
			continue
		b.visible = id != "" or i == 0
		if id == "" or not id in acts:
			b.text = "No skill equipped"
			b.disabled = true
			continue
		var sk := SkillData.info(id)
		var cd := int(state.skill_cds.get(id, 0))
		b.text = ("%s!" % sk["name"]) if cd <= 0 else "%s (%d)" % [sk["name"], cd]
		b.disabled = cd > 0
		b.tooltip_text = sk["text"]
		var c := Color(Classes.tag_color(sk["tags"][0]))
		b.add_theme_stylebox_override("normal", UI.style(c.darkened(0.6), c, 6, 8))
		b.add_theme_color_override("font_color", c.lightened(0.55))
	auto_ability_button.text = "Auto %s" % ("ON" if state.auto_ability else "OFF")
	var why := Lineage.escape_block(state)
	escape_button.disabled = why != "" or not state.path_offer.is_empty()
	escape_button.text = ("Run (%d%%)" % int(Lineage.escape_chance(state))) if why == "" else "Run"
	if why != "":
		escape_button.tooltip_text = why
	spare_button.visible = Lineage.can_spare(state)

func _refresh_tabs() -> void:
	# Town (and its Craft page) unlock as you go deeper
	tabs.set_tab_hidden(2, not state.shop_unlocked())
	town_tabs.set_tab_hidden(1, not state.craft_unlocked())
	town_tabs.set_tab_hidden(2, not state.gamble_unlocked())

	# Badges: numbers on tabs that need your attention
	var pts := state.stat_points if state.hero_class != "" else 0
	var sk := 0
	var ups := 0
	for s in GameData.SLOT_ORDER:
		if state.has_upgrade(s):
			ups += 1
	tabs.set_tab_title(0, "Character (%d)" % (pts + sk) if pts + sk > 0 else "Character")
	tabs.set_tab_title(1, "Items (%d)" % ups if ups > 0 else "Items")
	char_tabs.set_tab_title(0, "Hero (%d)" % pts if pts > 0 else "Hero")
	char_tabs.set_tab_title(3, "Skills (%d)" % sk if sk > 0 else "Skills")
	char_tabs.set_tab_title(2, "Race (!)" if Lineage.awaken_block(state) in ["", "trial"] and state.hero_class != "" else "Race")
	item_tabs.set_tab_title(0, "Gear (%d)" % ups if ups > 0 else "Gear")
	item_tabs.set_tab_title(1, "Bag (full)" if state.bag_full() else "Bag")
	item_tabs.set_tab_hidden(2, state.hardcore)
	var ready := codex.bounties_ready()
	tabs.set_tab_title(3, "Codex (%d)" % ready if ready > 0 else "Codex")
	codex_tabs.set_tab_title(3, "Bounties (%d)" % ready if ready > 0 else "Bounties")

	# Only the page you're looking at needs updating
	var group := _groups()[tabs.current_tab] as TabContainer
	var page = group.get_current_tab_control()
	if page and page.has_method("refresh"):
		page.refresh()
