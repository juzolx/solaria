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
var town_page: VBoxContainer    # the Town group: a "back to the map" bar over town_tabs
var town_back: Control
var fight_frame: Control
var fight_panel: Control
var town_frame: Control
var town_view: TownView
var town_leave: Button
var town_status: Label
var inn_tab: InnTab
var mail_tab: MailTab
var town_mail: Button
var _was_in_town := false
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
var pet_tab: PetTab
var clinic_tab: ClinicTab
var race_tab: RaceTab
var moment_queue: Array = []
var escape_button: Button
var catch_button: Button
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
var room_view: RoomView
var _room_ready := false
var _room_waiting := false
var log_label: RichTextLabel
var ui_root: MarginContainer
var goal_label: Label
var goal_bar: ProgressBar
var log_lines: Array[String] = []
var skill_buttons: Array[Button] = []  # one per active skill slot
var auto_ability_button: Button
var attack_button: Button
var last_turn_ms := 0
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
var nav_bar: PanelContainer   # phone layout: the bottom navigation (Fight, Hero, Items, Town, Codex, Online)
var nav_buttons: Array[Button] = []
var nav_page := 0              # 0 = the fight, 1.. = a tab group (1 + its index)
var is_tall := false
const TOWN_PAGES := ["Shop", "Blacksmith", "Tavern", "Inn", "Vault", "Bounty Board", "Guild Hall", "Mailbox", "Clinic"]
const NAV := [["Fight", "sword"], ["Hero", "person"], ["Items", "bag"], ["Town", "house"], ["Codex", "book"], ["Online", "globe"]]
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
	_fresh_start_check()
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

var fresh_start_notice := false

## A new save epoch (0.12): every hero is wiped once. Settings and the online login stay.
func _fresh_start_check() -> void:
	if not profile.fresh_start_due():
		return
	var had_saves := FileAccess.file_exists(Profile.PATH) or FileAccess.file_exists(GameState.SAVE_PATH) \
		or FileAccess.file_exists(GameState.HC_SAVE_PATH) or FileAccess.file_exists(Codex.PATH)
	for n in range(1, GameData.MAX_HEROES + 1):
		had_saves = had_saves or GameState.has_slot(n)
	if had_saves:
		GameState.delete_saves()
		Codex.delete()
		codex = Codex.load_codex()
		state.codex = codex
		profile.reset_progress()
		fresh_start_notice = true
	profile.save_epoch = Profile.SAVE_EPOCH
	profile.save()

func _show_fresh_start() -> void:
	fresh_start_notice = false
	var o := Overlay.new().open(self, "A fresh start", 440.0, UI.GOLD)
	o.content.add_child(UI.wrap("Solaria %s rebuilds the dungeon: 1,000 floors, the Bank, a roster of 9 heroes, pets and much more. Every hero has been reset so everyone starts fresh. Your settings are kept." % PatchNotes.VERSION, 14, UI.TEXT))
	var b := UI.primary("Begin", o.close, UI.GOLD)
	b.custom_minimum_size = Vector2(0, 44)
	o.content.add_child(b)

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
	if fresh_start_notice:
		_show_fresh_start.call_deferred()

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
	state.profile_ref = profile
	state.path_rooms_on = profile.path_choice != "fight"
	Mail.sync(state, profile)
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
## Room view: walk up to the waiting monster.
func engage_monster() -> void:
	sfx.play("click")
	state.engage()
	refresh()

## Room view: open, smash, pray at or talk to something in the room.
func interact_prop(i: int) -> void:
	var r := Halls.interact(state, i)
	if r != "":
		sfx.play("buy")
		toast(r)
	refresh()

## Room view: through one of the three doors.
func pick_door(i: int) -> void:
	if not state.door_pending():
		return
	sfx.play("click")
	state.choose_path(GameState.DOOR_KEYS[i])
	refresh()

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
	var crow := UI.hbox(8)
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(crow)
	path_count_label = UI.label("", 12, UI.DIM)
	path_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crow.add_child(path_count_label)
	var hold := UI.button("Wait for me", func():
		state.path_hold = true
		refresh())
	hold.tooltip_text = "Stop the countdown: the fight waits until you pick"
	crow.add_child(hold)
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
	if r.has("woke"):
		var lost_l := UI.rich(13)
		lost_l.text = "[color=#f87171]Lost: %s.[/color] [color=%s]You woke at the checkpoint on floor %d. The Bank, Vault and Mailbox are safe.[/color]" % [
			String(r.get("lost", "")) if String(r.get("lost", "")) != "" else "nothing (you carried nothing in)", UI.hex(UI.DIM), int(r["woke"])]
		v.add_child(lost_l)
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
	off.add_theme_font_size_override("font_size", 12)
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
	# Manual play: nothing happens until you act (see _manual_turn)
	if not state.autoplay:
		return
	state.take_turn()
	refresh()

## Manual play: one turn when you tap Attack or the enemy.
func _manual_turn() -> void:
	var now := Time.get_ticks_msec()
	if now - last_turn_ms < 280:
		return
	last_turn_ms = now
	if state.in_town or not state.path_offer.is_empty() or state.run_over:
		return
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
	ui_root = root
	_fit_root()
	get_viewport().size_changed.connect(_fit_root)

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
	_build_nav(main_v)
	char_tabs = _group("Character")
	item_tabs = _group("Items")
	town_page = UI.vbox(6)
	town_page.name = "Town"
	tabs.add_child(town_page)
	town_back = UI.hbox(8)
	town_page.add_child(town_back)
	var back_btn := UI.button("◀  Town map", func():
		nav_page = 0
		_apply_nav()
		refresh())
	back_btn.custom_minimum_size = Vector2(0, UI.TAP)
	town_back.add_child(back_btn)
	town_tabs = TabContainer.new()
	town_tabs.name = "TownPages"
	town_tabs.theme_type_variation = "SubTabs"
	town_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	town_tabs.tab_changed.connect(func(_i): sfx.play("click"); refresh())
	town_page.add_child(town_tabs)
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
	pet_tab = PetTab.new()
	clinic_tab = ClinicTab.new()
	race_tab = RaceTab.new()
	wheel_tab = WheelTab.new()
	bestiary_tab = BestiaryTab.new()
	collection_tab = CollectionTab.new()
	stats_tab = StatsTab.new()
	achievements_tab = AchievementsTab.new()
	bounty_tab = BountyTab.new()
	inn_tab = InnTab.new()
	mail_tab = MailTab.new()
	guide_tab = GuideTab.new()
	for pair in [[char_tabs, hero_tab], [char_tabs, class_tab], [char_tabs, race_tab], [char_tabs, skills_tab], [char_tabs, party_tab], [char_tabs, pet_tab],
			[item_tabs, gear_tab], [item_tabs, bag_tab],
			[town_tabs, shop_tab], [town_tabs, craft_tab], [town_tabs, wheel_tab], [town_tabs, inn_tab], [town_tabs, stash_tab],
			[town_tabs, bounty_tab], [town_tabs, achievements_tab], [town_tabs, mail_tab], [town_tabs, clinic_tab],
			[codex_tabs, bestiary_tab], [codex_tabs, collection_tab],
			[codex_tabs, stats_tab], [codex_tabs, guide_tab],
			[online_tabs, leaderboard_tab], [online_tabs, guild_tab], [online_tabs, raid_tab]]:
		pair[1].setup(self)
		(pair[0] as TabContainer).add_child(pair[1])
	tabs.current_tab = 1  # start on Items
	_fit_layout()
	get_viewport().size_changed.connect(_fit_layout)

## Phone-style tall screens stack the fight above the tabs.
## Keeps the whole interface exactly as big as the visible screen.
func _fit_root() -> void:
	if ui_root:
		ui_root.size = get_viewport().get_visible_rect().size

func _fit_layout() -> void:
	var win := get_tree().root.size
	var tall := win.x < win.y * 0.95
	# Keep text the same size in both orientations (the design size is 1152x648)
	# Interface size (accessibility): a smaller design size makes everything bigger
	var zoom: float = [1.12, 1.0, 0.86][clampi(profile.text_size if profile else 1, 0, 2)]
	var want := Vector2i(Vector2(648, 1152) * zoom) if tall else Vector2i(Vector2(1152, 648) * zoom)
	if get_tree().root.content_scale_size != want:
		get_tree().root.content_scale_size = want
		_fit_root.call_deferred()
	body.vertical = tall
	is_tall = tall
	_apply_nav()
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
	(ep[1] as Label).add_theme_font_size_override("font_size", 12)
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
	fight_frame = frame
	battle = BattleView.new()
	battle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(battle)
	room_view = RoomView.new()
	room_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_view.setup(self)
	room_view.visible = false
	frame.add_child(room_view)
	_build_town(parent)

	var panel := UI.panel(UI.PANEL, UI.BORDER, 10, 10)
	parent.add_child(panel)
	fight_panel = panel
	var col := UI.vbox(8)
	panel.add_child(col)
	# The next goal: always something to chase (world.gd)
	var goal_row := UI.vbox(2)
	col.add_child(goal_row)
	goal_label = UI.label("", 13, UI.GOLD)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_row.add_child(goal_label)
	goal_bar = UI.bar(UI.GOLD, 5)
	goal_row.add_child(goal_bar)
	log_label = UI.rich(12, false)
	log_label.custom_minimum_size = Vector2(0, 80)
	col.add_child(log_label)

	attack_button = UI.primary("Attack", _manual_turn, UI.RED)
	attack_button.custom_minimum_size = Vector2(0, UI.TAP + 8)
	attack_button.tooltip_text = "Take your turn (you can also tap the enemy)"
	attack_button.visible = false
	col.add_child(attack_button)
	var ability_row := UI.hbox(6)
	col.add_child(ability_row)
	for i in 4:
		var b := UI.primary("", func():
			var id: String = state.sig_slot if i == 3 else state.active_slots[i]
			if id != "" and state.use_skill(id):
				refresh(), UI.GOLD)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		ability_row.add_child(b)
		skill_buttons.append(b)
	auto_ability_button = UI.button("", func(): SkillsTab.auto_battle_popup(self))
	auto_ability_button.tooltip_text = "Autoplay options: let the fight run by itself, or take every turn yourself"
	auto_ability_button.custom_minimum_size = Vector2(84, 0)
	ability_row.add_child(auto_ability_button)

	var buttons := GridContainer.new()
	buttons.columns = 4
	buttons.add_theme_constant_override("h_separation", 6)
	col.add_child(buttons)
	potion_button = UI.button("", func(): state.use_potion(); refresh())
	potion_button.icon = Sprites.consumable_icon("potion")
	potion_button.expand_icon = false
	potion_button.add_theme_constant_override("icon_max_width", 20)
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
	catch_button = UI.button("Catch", func():
		if Menagerie.try_catch(state):
			sfx.play("unique")
		refresh())
	catch_button.tooltip_text = "Tame this monster. It becomes your pet (no XP or loot from it)."
	catch_button.add_theme_color_override("font_color", Color("#d9a066"))
	catch_button.visible = false
	for b in [potion_button, auto_potion_button, floors_button, speed_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(b)
	var run_row := UI.hbox(6)
	col.add_child(run_row)
	for b in [escape_button, catch_button, spare_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		run_row.add_child(b)

## The town map (shown instead of the fight while you're in town).
func _build_town(parent: Control) -> void:
	var frame := UI.panel(UI.PANEL, UI.BORDER, 10, 2)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.visible = false
	parent.add_child(frame)
	town_frame = frame
	var v := UI.vbox(0)
	frame.add_child(v)
	town_view = TownView.new()
	town_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	town_view.building_pressed.connect(_on_building)
	v.add_child(town_view)
	var bar := UI.panel(UI.PANEL, UI.BORDER, 0, 8, 0)
	v.add_child(bar)
	var row := UI.hbox(8)
	bar.add_child(row)
	town_status = UI.label("", 13, UI.TEXT)
	town_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	town_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(town_status)
	town_mail = UI.button("Mail", func(): _on_building("mail"))
	town_mail.custom_minimum_size = Vector2(0, UI.TAP)
	row.add_child(town_mail)
	town_leave = UI.primary("Into the dungeon", _choose_floor, UI.RED)
	town_leave.custom_minimum_size = Vector2(0, UI.TAP)
	row.add_child(town_leave)

func _on_building(id: String) -> void:
	sfx.play("click")
	if id == "gate":
		_choose_floor()
		return
	if not Town.BUILDINGS.has(id):
		return
	var page: int = Town.BUILDINGS[id][0]
	if town_tabs.is_tab_hidden(page):
		toast(String(town_view.locked.get(id, "That's closed for now.")))
		return
	show_tab(2, page)
	refresh()

## Leaving town: pick the floor to go down to first.
func _choose_floor() -> void:
	sfx.play("click")
	FloorPicker.new().show_from_town(self)

func _leave_town() -> void:
	Town.leave(state)
	if tabs.current_tab == 2:
		tabs.current_tab = 1
	nav_page = 0
	_apply_nav()
	timer.start()
	refresh()

## A short message near the top of the screen (works in town too, where the fight view is hidden).
func toast(text: String) -> void:
	var vp := get_viewport().get_visible_rect().size
	var p := UI.panel(Color(0.05, 0.06, 0.11, 0.95), UI.GOLD, 8, 10, 1)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13, UI.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(minf(420.0, vp.x - 40.0) - 24.0, 0)
	p.add_child(l)
	p.z_index = 60
	add_child(p)
	p.reset_size()
	p.position = Vector2((vp.x - p.size.x) / 2.0, 64.0)
	var tw := p.create_tween()
	tw.tween_interval(2.4 + text.length() / 30.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

## Goes to town (if you can). Returns false and says why if not.
func go_to_town() -> bool:
	if state.in_town:
		return true
	if not Town.enter(state):
		var why := Town.blocked(state)
		if why == Town.PORTAL_BLOCK and state.return_scrolls <= 0:
			toast(why)
		elif why in [Town.FLOOR_BLOCK, Town.PORTAL_BLOCK] and state.return_scrolls > 0:
			confirm("Read a Return Scroll?", "You escape home right now with everything you carry. You have %d." % state.return_scrolls, "Read it", func():
				if Town.use_return(state):
					sfx.play("click")
					refresh())
		elif why == Town.FLOOR_BLOCK:
			# Mid-floor: you'll walk home the moment this floor is cleared
			state.go_home_after = not state.go_home_after
			toast("Heading home as soon as this floor is cleared." if state.go_home_after else "You'll keep going after this floor.")
		elif why != "":
			toast(why)
		return false
	sfx.play("click")
	return true

var _roster_cache: Array = []

## Every hero in your roster walks around town (the one you play first).
func _town_heroes() -> void:
	var looks := state.hero_looks()
	var key := "%d|%s|%s|%d" % [state.slot, str(state.appearance), str(looks), _roster_cache.size()]
	town_view.set_heroes([[state.appearance, looks, true]] + _roster_cache, key)
	# Your pets live in the Clinic's pen (your class companion too, if you have one)
	var texs: Array = []
	var pkey := ""
	if World.pet_stage(state) >= 0:
		texs.append(Pets.portrait(state))
		pkey += "c%d" % World.pet_stage(state)
	for p in state.pets:
		texs.append(Menagerie.texture(p))
		pkey += "|%d" % int(p["id"])
	town_view.set_pets(texs, "%d:%s" % [state.slot, pkey])

## Map or fight, town look, plates and the leave button.
func _sync_town() -> void:
	var inside := state.in_town
	if inside != _was_in_town:
		_was_in_town = inside
		_apply_nav()
		_roster_cache = []
		if inside:
			# Your other heroes (read once each visit; their saves don't change while you're here)
			for n in range(1, GameData.MAX_HEROES + 1):
				if n != state.slot and GameState.has_slot(n):
					var meta := GameState.slot_meta(n)
					if not meta.is_empty():
						_roster_cache.append([meta.get("appearance", {}), meta.get("looks", {}), false])
	fight_frame.visible = not inside
	fight_panel.visible = not inside
	town_frame.visible = inside
	town_back.visible = is_tall
	if not inside:
		return
	town_view.set_look(Town.look(state))
	_town_heroes()
	town_leave.text = "Into the dungeon"
	var mw := Mail.waiting(state)
	town_mail.text = "✉ Mail (%d)" % mw if mw > 0 else "✉ Mail"
	town_mail.add_theme_color_override("font_color", UI.GOLD if Mail.unread(state) > 0 else UI.TEXT)
	town_status.text = "HP %d / %d   ·   %s" % [state.hero_hp, state.get_max_hp(), Town.look(state)["name"]]
	var notes := {}
	for id in Town.BUILDINGS:
		notes[id] = Town.BUILDINGS[id][1]
	notes["gate"] = "Choose your floor"
	town_view.notes = notes
	town_view.locked = {
		"smith": "" if state.craft_unlocked() else "Opens at floor %d" % GameData.CRAFT_UNLOCK_FLOOR,
		"tavern": "" if state.gamble_unlocked() else "Opens at floor %d" % GameData.GAMBLE_UNLOCK_FLOOR,
		"stash": "" if not state.hardcore else "Hardcore heroes can't use the Vault",
	}
	town_view.hidden_spots = {} if Menagerie.has_any(state) else {"clinic": true}
	var hurt_pets := state.pets.filter(func(p): return int(p["hurt"]) > 0).size()
	town_view.badges = {"bounty": Town.ready_count(state), "guild": codex.deeds.size(), "mail": Mail.waiting(state), "clinic": hurt_pets,
		"inn": 1 if state.hero_hp < state.get_max_hp() * 0.6 else 0}

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

## A Calamity appears: the screen darkens and you choose to fight or run.
func _show_calamity(e: Dictionary) -> void:
	sfx.play("boss_intro")
	var col := Color(String(e.get("color", "#e43b44")))
	var o := Overlay.new().open(self, "A CALAMITY APPROACHES", 460.0, Color("#e43b44"), false)
	var nm := UI.label(String(e["name"]), 24, col.lightened(0.2))
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	o.content.add_child(nm)
	o.content.add_child(UI.wrap(String(e["lore"]), 13, UI.DIM))
	o.content.add_child(UI.wrap("Nothing in this dungeon is stronger. If it beats you, you only pass out: you wake on this floor with everything you carried, and it doesn't count as a death. Running works about half the time.", 13, UI.TEXT))
	var row := UI.hbox(8)
	o.content.add_child(row)
	var run_b := UI.button("Run", func():
		o.close()
		Calamity.run(state)
		refresh())
	var fight_b := UI.primary("Fight", func():
		o.close()
		Calamity.fight(state)
		refresh(), Color("#e43b44"))
	for b in [run_b, fight_b]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 48)
		row.add_child(b)

## The Calamity won: everything goes black, then you wake up.
func _blackout(who: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)
	var txt := UI.label("Everything goes black...", 18, Color("#94a3b8"))
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	txt.modulate.a = 0.0
	layer.add_child(txt)
	timer.stop()
	var t := create_tween()
	t.tween_property(black, "color:a", 1.0, 0.6)
	t.tween_property(txt, "modulate:a", 1.0, 0.5)
	t.tween_interval(1.6)
	t.tween_callback(func(): txt.text = "You wake up. %s is gone.\nYou still have everything you carried." % who)
	t.tween_interval(2.0)
	t.tween_property(black, "color:a", 0.0, 0.8)
	t.parallel().tween_property(txt, "modulate:a", 0.0, 0.6)
	t.tween_callback(func():
		layer.queue_free()
		timer.start())

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
		pic.custom_minimum_size = Vector2(64, 64)
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
	UI.colorblind = profile.colorblind
	DarkGrade.set_enabled(profile.dark_art)
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
	if not state.autoplay:
		battle.tap_ring(pos)
		_manual_turn()
		return
	var now := Time.get_ticks_msec()
	if now - last_tap_ms < int(GameData.TAP_COOLDOWN * 1000):
		return
	last_tap_ms = now
	battle.tap_ring(pos)
	if state.tap_attack():
		refresh()

## Jump to a tab: group 0 Character, 1 Items, 2 Town, 3 Codex, 4 Online.
func show_tab(group: int, sub: int) -> void:
	if group == 2 and not go_to_town():
		return
	nav_page = group + 1
	_apply_nav()
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
	# 0.13: between fights you look at the room; doors are tapped there too
	var in_room := not state.in_town and (state.exploring or state.door_pending())
	if not in_room:
		_room_ready = false
		room_view.visible = false
		battle.visible = true
	elif not _room_ready and not _room_waiting:
		# Let the last blow, the death and the loot play out before the room shows
		_room_waiting = true
		get_tree().create_timer(1.1).timeout.connect(func():
			_room_waiting = false
			_room_ready = true
			refresh())
	elif _room_ready:
		room_view.visible = true
		battle.visible = false
	if not state.path_offer.is_empty() and path_panel == null and not state.door_pending():
		_show_path_choice()
	elif state.path_offer.is_empty() and path_panel != null:
		path_panel.queue_free()
		path_panel = null
		path_count_label = null
	if path_count_label:
		var auto_pick: String = state.path_info(state.auto_path())["name"]
		path_count_label.text = ("Waiting for you to pick" if state.path_hold else "Picks %s by itself in %d..." % [auto_pick, maxi(0, GameData.PATH_WAIT_TURNS - state.path_wait)])
	if state.run_over and not fallen_shown:
		get_tree().create_timer(1.6).timeout.connect(_on_hardcore_death)
		fallen_shown = true
	_play_moments()
	_pull_messages()
	_refresh_top()
	_refresh_fight()
	_refresh_tabs()
	_sync_town()
	sfx.update_music(state)

## Events that open popups: new guide pages, the merchant. Also keeps records.
func _handle_events() -> void:
	for e in state.events:
		# The fight view is hidden in town, so its tips show up here instead
		if state.in_town and e["type"] in ["tip", "toast"]:
			toast(String(e["text"]))
		match e["type"]:
			"guide":
				if codex.stat("guide_skip") == 0 and not _popup_open():
					GuideBook.open_book(self, e["id"], true)
			"merchant":
				MerchantPopup.new().show_for(self)
			"calamity":
				_show_calamity.call_deferred(e)
			"blackout":
				_blackout.call_deferred(String(e["name"]))
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
				moment_queue.append(["realm", e["name"], e["blurb"], Color(e["color"]), e["mechanic"], null, DarkGrade.texture(bgp, DarkGrade.SCENE, false)])
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
	# In the dungeon: what you carry (at risk) over what's safe in the Bank
	var two := not state.in_town and state.bank > 0
	gold_label.text = "Gold  %s\nBank  %s" % [UI.short(state.gold), UI.short(state.bank)] if two else "Gold  %d" % state.gold
	gold_label.add_theme_font_size_override("font_size", 11 if two else 15)
	gold_label.get_parent().tooltip_text = "Carried gold: %d (lost if you fall)\nBank: %d (always safe)" % [state.gold, state.bank] if two else "Gold: from enemies and selling. Spend it in Town."
	scrap_label.text = "Scrap  %d" % state.scrap
	potion_label.text = "Potions  %d" % state.potions

func _refresh_fight() -> void:
	potion_button.text = "Potion (%d)" % state.potions
	potion_button.disabled = state.potions <= 0 or state.hero_hp >= state.get_max_hp() or state.leader_down
	auto_potion_button.text = "Auto-heal %s" % ("ON" if state.auto_potion else "OFF")
	speed_button.text = "Speed %s" % ("2x" if state.fast_mode else "1x")
	floors_button.disabled = state.best_floor <= 1
	var acts := state.equipped_actives()
	for i in skill_buttons.size():
		var b: Button = skill_buttons[i]
		var id: String = state.active_slots[i] if i < mini(3, state.active_slot_count()) else ""
		if i == 3:
			id = state.sig_slot
			if id == "":
				b.visible = false
				continue
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
		b.icon = SkillIcons.for_tag(String(sk["tags"][0]))
		b.add_theme_constant_override("icon_max_width", 26)
		b.add_theme_stylebox_override("normal", UI.style(c.darkened(0.6), c, 6, 8))
		b.add_theme_color_override("font_color", c.lightened(0.55))
	auto_ability_button.text = "Auto" if state.autoplay else "Manual"
	attack_button.visible = not state.autoplay and not state.in_town
	attack_button.disabled = not state.path_offer.is_empty() or state.enemy_hp <= 0
	var goal := World.next_goal(state)
	goal_label.text = "Next: " + String(goal.get("text", ""))
	goal_label.add_theme_color_override("font_color", goal.get("color", UI.GOLD))
	var gp := float(goal.get("pct", -1.0))
	goal_bar.visible = gp >= 0.0
	goal_bar.value = gp * 100.0
	goal_bar.max_value = 100.0
	var why := Lineage.escape_block(state)
	escape_button.disabled = why != "" or not state.path_offer.is_empty()
	escape_button.text = ("Run (%d%%)" % int(Lineage.escape_chance(state))) if why == "" else "Run"
	if why != "":
		escape_button.tooltip_text = why
	spare_button.visible = Lineage.can_spare(state)
	catch_button.visible = Menagerie.can_catch(state) and state.path_offer.is_empty()
	if catch_button.visible:
		catch_button.text = "Catch (%d%%)" % int(Menagerie.catch_chance(state))

# =====================================================================
# Phone layout: bottom navigation
# =====================================================================

## Tall (phone) screens get a bottom bar: one big button per section, and the
## fight or the chosen section fills the screen. Wide screens keep both side by side.
func _build_nav(parent: Control) -> void:
	nav_bar = UI.panel(Color("#111829"), UI.BORDER, 10, 4, 1)
	parent.add_child(nav_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	nav_bar.add_child(row)
	for i in NAV.size():
		var b := Button.new()
		b.text = NAV[i][0]
		b.icon = _nav_icon(NAV[i][1])
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = false
		b.custom_minimum_size = Vector2(0, 58)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := UI.style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 2, 0)
			if st == "focus":
				sb = UI.style(Color(0, 0, 0, 0), Color("#f6d88f"), 8, 2, 2)
				sb.draw_center = false
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func():
			sfx.play("click")
			# Town = travel to town and look at the map; Fight = head back down
			if i == 3:
				if not go_to_town():
					return
				nav_page = 0
			elif i == 0 and state.in_town:
				_choose_floor()
				return
			else:
				nav_page = i
			_apply_nav()
			refresh())
		row.add_child(b)
		nav_buttons.append(b)

func _apply_nav() -> void:
	if nav_bar == null:
		return
	nav_bar.visible = is_tall
	tabs.tabs_visible = not is_tall
	if not is_tall:
		left_panel.visible = true
		tabs.visible = true
		return
	if nav_page > 0 and tabs.is_tab_hidden(nav_page - 1):
		nav_page = 0
	left_panel.visible = nav_page == 0
	tabs.visible = nav_page != 0
	if nav_page > 0 and tabs.current_tab != nav_page - 1:
		tabs.current_tab = nav_page - 1
	for i in nav_buttons.size():
		var on := i == nav_page
		if state != null and state.in_town:
			on = (i == 3 and (nav_page == 0 or nav_page == 3)) or (i == nav_page and i != 0)
		nav_buttons[i].add_theme_color_override("font_color", UI.GOLD if on else UI.DIM)
		nav_buttons[i].add_theme_color_override("font_hover_color", UI.GOLD if on else UI.TEXT)
		nav_buttons[i].modulate = Color.WHITE
		nav_buttons[i].self_modulate = Color(1, 1, 1, 1)
		nav_buttons[i].add_theme_color_override("icon_normal_color", UI.GOLD if on else UI.DIM)
		nav_buttons[i].add_theme_color_override("icon_hover_color", UI.GOLD if on else UI.TEXT)
		nav_buttons[i].add_theme_color_override("icon_pressed_color", UI.GOLD)
		nav_buttons[i].add_theme_color_override("icon_focus_color", UI.GOLD if on else UI.DIM)

## Small pixel icons for the bottom bar (white; tinted by the button).
const NAV_ICONS := {
	"sword": ["..........XX", ".........XXX", "........XXX.", ".......XXX..", "......XXX...", ".X...XXX....", "..X.XXX.....", "...XXX......", "...XX.......", "..X.XX......", ".X....X.....", "X..........."],
	"person": ["....XXXX....", "...XXXXXX...", "...XXXXXX...", "...XXXXXX...", "....XXXX....", "............", "..XXXXXXXX..", ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX."],
	"bag": ["....XXXX....", "...X....X...", "...X....X...", ".XXXXXXXXXX.", ".XXXXXXXXXX.", "XXXXXXXXXXXX", "XXXXX..XXXXX", "XXXXX..XXXXX", "XXXXXXXXXXXX", "XXXXXXXXXXXX", ".XXXXXXXXXX.", "..XXXXXXXX.."],
	"house": [".....XX.....", "....XXXX....", "...XXXXXX...", "..XXXXXXXX..", ".XXXXXXXXXX.", "XXXXXXXXXXXX", ".XXXXXXXXXX.", ".XXXX..XXXX.", ".XXXX..XXXX.", ".XXXX..XXXX.", ".XXXX..XXXX.", ".XXXX..XXXX."],
	"book": ["XXXXX..XXXXX", "XXXXXX.XXXXX", "X...XX.X...X", "XXXXXX.XXXXX", "X...XX.X...X", "XXXXXX.XXXXX", "X...XX.X...X", "XXXXXX.XXXXX", "XXXXXX.XXXXX", "XXXXXX.XXXXX", ".XXXXXXXXXX.", "....XXXX...."],
	"globe": ["....XXXX....", "..XX.XX.XX..", ".X..X..X..X.", ".XXXXXXXXXX.", "X...X..X...X", "X...X..X...X", "XXXXXXXXXXXX", "X...X..X...X", ".X..X..X..X.", ".XXXXXXXXXX.", "..XX.XX.XX..", "....XXXX...."],
}

static func _nav_icon(icon_name: String) -> ImageTexture:
	var rows: Array = NAV_ICONS.get(icon_name, NAV_ICONS["book"])
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in String(rows[y]).length():
			if String(rows[y])[x] == "X":
				img.set_pixel(x, y, Color.WHITE)
	img.resize(24, 24, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func _refresh_tabs() -> void:
	# Town (and its Craft page) unlock as you go deeper
	tabs.set_tab_hidden(2, not state.shop_unlocked())
	town_tabs.set_tab_hidden(1, not state.craft_unlocked())
	town_tabs.set_tab_hidden(2, not state.gamble_unlocked())
	town_tabs.set_tab_hidden(4, state.hardcore)
	town_tabs.set_tab_hidden(8, not Menagerie.has_any(state))
	for i in TOWN_PAGES.size():
		town_tabs.set_tab_title(i, TOWN_PAGES[i])
	# On a wide screen, picking the Town tab means walking to town
	if not is_tall and tabs.current_tab == 2 and not state.in_town and not go_to_town():
		tabs.current_tab = 1

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
	var ready := Town.ready_count(state) + codex.deeds.size() + Mail.waiting(state)
	tabs.set_tab_title(2, "Town (%d)" % ready if ready > 0 else "Town")
	town_tabs.set_tab_title(5, "Bounty Board (%d)" % Town.ready_count(state) if Town.ready_count(state) > 0 else TOWN_PAGES[5])
	town_tabs.set_tab_title(6, "Guild Hall (%d)" % codex.deeds.size() if codex.deeds.size() > 0 else TOWN_PAGES[6])
	town_tabs.set_tab_title(7, "Mailbox (%d)" % Mail.waiting(state) if Mail.waiting(state) > 0 else TOWN_PAGES[7])
	if nav_buttons.size() == NAV.size():
		var counts := [0, pts + sk, ups, ready, 0, 0]
		for i in NAV.size():
			nav_buttons[i].text = NAV[i][0] + (" %d" % counts[i] if counts[i] > 0 else "")
		nav_buttons[3].visible = not tabs.is_tab_hidden(2)

	# Only the page you're looking at needs updating
	var group := _groups()[tabs.current_tab] as TabContainer
	var page = group.get_current_tab_control()
	if page and page.has_method("refresh"):
		page.refresh()
