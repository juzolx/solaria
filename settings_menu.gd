class_name SettingsMenu
extends Overlay
## The Menu: sound and music volume, fullscreen, reset save, and Dev Mode.

var main
var state: GameState
var profile: Profile
var dev_box: VBoxContainer
var dev_toggle: Button
var sound_toggle: Button
var fullscreen_toggle: Button
var dark_toggle: Button
var battery_toggle: Button
var graphics_toggle: Button
var path_toggle: Button
var a11y_buttons := {}
var cloud_label: Label
var dev_info: Label

func show_for(m) -> void:
	main = m
	state = m.state
	profile = m.profile
	open(m, "Menu", 560.0)

	content.add_child(UI.heading("Hero"))
	var hrow := UI.hbox(8)
	content.add_child(hrow)
	var mode_name := "Hardcore" if state.hardcore else "Regular"
	for entry in [["Title screen / heroes", func(): close(); main.back_to_title()],
			["Change look", func(): close(); main.show_look_editor()],
			["Wardrobe", func(): close(); Wardrobe.new().show_for(main)]]:
		var b := UI.button(entry[0], entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hrow.add_child(b)
	if main.started == false:
		hrow.visible = false

	content.add_child(UI.heading("Sound"))
	var srow := UI.hbox(10)
	content.add_child(srow)
	sound_toggle = UI.button("", func():
		profile.sound_on = not profile.sound_on
		main.apply_settings()
		_update())
	sound_toggle.custom_minimum_size = Vector2(130, 0)
	srow.add_child(sound_toggle)
	srow.add_child(UI.button("Test sound", func(): main.sfx.play("level_up")))
	if OS.is_debug_build():  # a check for whoever builds the game; players never need it
		var found: int = main.sfx.files_found
		var info := UI.label("Sound files found: %d / %d" % [found, Sfx.EXPECTED_FILES] + ("" if found >= Sfx.EXPECTED_FILES else " - copy the sounds folder into the game folder"), 12, UI.GREEN if found >= Sfx.EXPECTED_FILES else UI.RED)
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		srow.add_child(info)
	content.add_child(_slider("Effects", profile.volume, func(v: float): profile.volume = v; main.apply_settings()))
	content.add_child(_slider("Music", profile.music_volume, func(v: float): profile.music_volume = v; main.apply_settings()))

	content.add_child(UI.heading("Game"))
	var grow := UI.hbox(8)
	content.add_child(grow)
	path_toggle = UI.button("", func():
		profile.path_choice = "fight" if profile.path_choice == "ask" else "ask"
		main.apply_settings()
		_update())
	path_toggle.tooltip_text = "Sometimes after a floor you can pick the next room: treasure, campfire or an elite monster."
	fullscreen_toggle = UI.button("", func():
		profile.fullscreen = not profile.fullscreen
		main.apply_settings()
		_update())
	for b in [path_toggle, fullscreen_toggle]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grow.add_child(b)
	dark_toggle = UI.button("", func():
		profile.dark_art = not profile.dark_art
		main.apply_settings()
		_update())
	dark_toggle.tooltip_text = "Darker, colder monsters and backgrounds. Fire and magic still glow. Shows on the next monster or screen."
	dark_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(dark_toggle)
	var prow := UI.hbox(8)
	content.add_child(prow)
	battery_toggle = UI.button("", func():
		profile.battery_saver = not profile.battery_saver
		main.apply_settings()
		_update())
	battery_toggle.tooltip_text = "Caps the game at 30 frames a second. Fights are turn-based, so it looks the same and saves battery and heat."
	graphics_toggle = UI.button("", func():
		profile.low_graphics = not profile.low_graphics
		main.apply_settings()
		_update())
	graphics_toggle.tooltip_text = "Low draws simpler rooms with fewer floating particles, for older phones."
	for b in [battery_toggle, graphics_toggle]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prow.add_child(b)

	content.add_child(UI.heading("Accessibility"))
	var arow := GridContainer.new()
	arow.columns = 2
	arow.add_theme_constant_override("h_separation", 8)
	arow.add_theme_constant_override("v_separation", 6)
	content.add_child(arow)
	for key in ["shake", "damage_numbers", "flashes", "text_size", "colorblind", "reduce_motion", "high_contrast", "haptics"]:
		var b := UI.button("", _toggle_a11y.bind(key))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arow.add_child(b)
		a11y_buttons[key] = b

	content.add_child(UI.heading("Credits"))
	var cr := UI.button("Credits and licenses", func(): CreditsScreen.new().show_for(main))
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(cr)
	# R6: errors kept on this phone only; the player copies them into a bug report
	var dbg := UI.button("Copy debug info", _show_debug_info)
	dbg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(dbg)

	if Store.ENABLED:
		content.add_child(UI.heading("Supporter store"))
		var sb := UI.button("Hero slots and supporter looks...", func(): StorePopup.new().show_for(main))
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(sb)

	content.add_child(UI.heading("Cloud backup"))
	var crow := UI.hbox(8)
	content.add_child(crow)
	var up := UI.button("Back up all heroes", _cloud_backup)
	var down := UI.button("Restore from cloud", _restore_popup)
	for b in [up, down]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not main.online.is_configured()
		crow.add_child(b)
	var off_text := "Online isn't set up yet (see ONLINE_SETUP.md)." if OS.is_debug_build() else "Cloud backup arrives with online features in a later update."
	cloud_label = UI.label(off_text if not main.online.is_configured() else "Saves your heroes to your online account, so you can get them back on a new device.", 11, UI.DIM)
	cloud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(cloud_label)
	# Apple rule: the online account can be deleted from inside the game
	if main.online.is_configured() and main.online.user_id() != "":
		var del := UI.button("Delete my online account...", func():
			main.confirm("Delete your online account?", "This removes your online name, leaderboard runs, guild seat and cloud backups from the server. It can't be undone. Your heroes on this device are not touched.", "Delete account", _delete_account))
		del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(del)

	# Deleting a hero is rare and permanent: a quiet button at the bottom, behind a confirmation
	content.add_child(UI.heading("This hero"))
	var reset := UI.button("Delete this hero...", func():
		main.confirm("Delete this hero?", "This wipes this %s hero's gear, levels, gold and progress. It can't be undone. Your other heroes, the Codex and the stash are not touched." % mode_name, "Delete hero", func(): main.reset_save()))
	reset.disabled = not main.started
	reset.add_theme_color_override("font_color", UI.DIM)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(reset)

	# Developer tools exist only when running from the editor or a debug build
	var drow := UI.hbox(8)
	drow.visible = OS.is_debug_build()
	content.add_child(drow)
	dev_toggle = UI.button("", func():
		profile.dev_mode = not profile.dev_mode
		main.apply_settings()
		_update()
		main.refresh())
	dev_toggle.tooltip_text = "Reveals every class and adds testing tools. For building the game, not for normal play."
	dev_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drow.add_child(dev_toggle)
	dev_box = UI.vbox(6)
	content.add_child(dev_box)
	var sections := [
		["Resources", [["+5 levels", "level"], ["+10,000 gold", "gold"], ["+1,000 scrap", "scrap"], ["+1,000 dust", "dust"],
			["Heal + 10 potions", "heal"], ["Fill the bag", "fill_bag"]]],
		["Floors and bosses", [["Floor +10", "floor_up"], ["Floor -10", "floor_down"], ["Next area", "next_area"], ["Go to mid boss", "mid_boss"],
			["Go to zone boss", "zone_boss"], ["Reset boss rests", "cooldowns"]]],
		["Monsters", [["Make Common", "tier_0"], ["Make Rare", "tier_2"], ["Make Epic", "tier_3"], ["Make Legendary", "tier_4"], ["Make Mythic", "tier_5"],
			["+100 kills (this monster)", "kills100"]]],
		["Events", [["Treasure goblin", "goblin"], ["Monster horde", "horde"], ["Cursed shrine", "shrine"], ["Meet the merchant", "merchant"]]],
		["Loot", [["Give Legendary", "legendary"], ["Give Unique", "unique"], ["Give Signature", "signature"], ["Open a Mystery Box", "box"],
			["Wheel always wins (toggle)", "always_win"]]],
		["Codex", [["Finish all bounties", "bounties"], ["Unlock all guide pages", "pages"]]],
		["Race", [["+50 racial power", "race_power"], ["Awaken one rank", "awaken"], ["Get this rank's key item", "race_key"],
			["Become a Vampire", "form_Vampire"], ["Become a Werewolf", "form_Werewolf"], ["Become a Fallen Angel", "form_Fallen Angel"],
			["Become a Lich", "form_Lich"], ["Cure / clear form", "form_none"], ["Get a Phylactery", "phylactery"]]],
		["Reputation", [["Everyone +25", "rep_up"], ["Everyone -25", "rep_down"], ["Realm race Exalted", "rep_exalted"]]],
		["Realms", [["Go to floor 251", "realms"], ["Next realm", "next_realm"], ["Meet someone", "encounter"], ["Realm event", "realm_event"],
			["Camp", "camp"], ["Portal choice", "portals"]]],
		["Hidden classes", [["Unlock all hidden classes", "hidden_all"], ["Next stage (current)", "hidden_stage"], ["+50 special stat", "hidden_stat"]]],
	]
	for sec in sections:
		dev_box.add_child(UI.label(str(sec[0]).to_upper(), 11, UI.PINK))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		dev_box.add_child(grid)
		for entry in sec[1]:
			var b := UI.button(entry[0], func(): state.dev_grant(entry[1]); main.refresh(); _update())
			b.disabled = not main.started
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_color_override("font_color", UI.PINK)
			b.add_theme_font_size_override("font_size", UI.MIN_FONT)
			grid.add_child(b)
	var cal_b := UI.button("Summon this region's Calamity", func():
		if main.started and not state.in_town:
			Calamity.appear(state, Calamity.region_index(state.floor_num))
			main.refresh()
		_update())
	cal_b.add_theme_color_override("font_color", UI.PINK)
	dev_box.add_child(cal_b)
	var slots_b := UI.button("Open all %d hero slots" % GameData.MAX_HEROES, func():
		profile.max_floor = maxi(profile.max_floor, int(GameData.SLOT_UNLOCKS[-1]))
		profile.save()
		_update())
	slots_b.add_theme_color_override("font_color", UI.PINK)
	dev_box.add_child(slots_b)
	dev_info = UI.label("", 11, UI.DIM)
	dev_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dev_box.add_child(dev_info)
	_update()
	main.timer.paused = true
	tree_exiting.connect(func(): main.timer.paused = false)

func _slider(label_text: String, value: float, on_change: Callable) -> HBoxContainer:
	var row := UI.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.label(label_text, 13, UI.TEXT)
	l.custom_minimum_size = Vector2(60, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(on_change)
	s.drag_ended.connect(func(_changed): profile.save())
	row.add_child(s)
	return row

## R6: the device, version and recent errors as text, copied for a bug report. Stays on
## the phone until the player pastes it somewhere (no analytics, nothing sent).
func _show_debug_info() -> void:
	DebugLog.flush()
	var text := DebugLog.report()
	DisplayServer.clipboard_set(text)
	var o := Overlay.new().open(main, "Debug info (copied)", 420.0, UI.GOLD)
	o.content.add_child(UI.wrap("Copied. Paste it into your TestFlight feedback or a message to the developer. It never leaves your phone on its own.", 12, UI.DIM))
	var box := UI.wrap(text, 10, UI.TEXT)
	o.content.add_child(box)
	var clr := UI.button("Clear the log", func():
		DebugLog.clear()
		box.text = DebugLog.report())
	o.content.add_child(clr)

func _toggle_a11y(key: String) -> void:
	match key:
		"shake":
			profile.shake = not profile.shake
		"damage_numbers":
			profile.damage_numbers = not profile.damage_numbers
		"flashes":
			profile.flashes = not profile.flashes
		"text_size":
			profile.text_size = (profile.text_size + 1) % 3
		"colorblind":
			profile.colorblind = not profile.colorblind
		"reduce_motion":
			profile.reduce_motion = not profile.reduce_motion
		"high_contrast":
			profile.high_contrast = not profile.high_contrast
		"haptics":
			profile.haptics = not profile.haptics
	main.apply_settings()
	main._fit_layout()
	_update()

func _delete_account() -> void:
	var r: Dictionary = await main.online.delete_account()
	main.toast("Your online account is deleted." if r["ok"] else String(r.get("error", "Couldn't reach the server.")))

func _cloud_backup() -> void:
	cloud_label.text = "Backing up..."
	if main.started:
		state.save_game()
	var r: Dictionary = await main.online.cloud_backup()
	cloud_label.text = ("Backed up! Your backup code is %s. Write it down to restore on another device." % r["code"]) if r["ok"] else "Backup failed: " + str(r["error"])

func _restore_popup() -> void:
	var o := Overlay.new().open(main, "Restore from the cloud", 460.0, UI.RED)
	var t := UI.label("Enter your backup code. Every town in the backup gets back its heroes and stash, and the Codex is replaced. Towns that aren't in the backup are kept as they are. The game restarts after.", 13, UI.TEXT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	o.content.add_child(t)
	var edit := LineEdit.new()
	edit.text = str(profile.online.get("cloud_code", ""))
	edit.placeholder_text = "Backup code"
	o.content.add_child(edit)
	o.content.add_child(UI.primary("Restore", func(): o.close(); _cloud_restore(edit.text), UI.RED))

func _cloud_restore(code: String) -> void:
	cloud_label.text = "Restoring..."
	var r: Dictionary = await main.online.cloud_restore(code)
	if r["ok"]:
		main.started = false
		main.state.run_over = true  # don't save over what was just restored
		main.get_tree().reload_current_scene()
	else:
		cloud_label.text = "Restore failed: " + str(r["error"])

func _update() -> void:
	(a11y_buttons["shake"] as Button).text = "Screen shake: %s" % ("ON" if profile.shake else "OFF")
	(a11y_buttons["damage_numbers"] as Button).text = "Damage numbers: %s" % ("ON" if profile.damage_numbers else "OFF")
	(a11y_buttons["flashes"] as Button).text = "Flashing effects: %s" % ("ON" if profile.flashes else "OFF")
	(a11y_buttons["colorblind"] as Button).text = "Colorblind labels: %s" % ("ON" if profile.colorblind else "OFF")
	(a11y_buttons["reduce_motion"] as Button).text = "Reduce motion: %s" % ("ON" if profile.reduce_motion else "OFF")
	(a11y_buttons["high_contrast"] as Button).text = "High-contrast text: %s" % ("ON" if profile.high_contrast else "OFF")
	(a11y_buttons["haptics"] as Button).text = "Vibration: %s" % ("ON" if profile.haptics else "OFF")
	(a11y_buttons["text_size"] as Button).text = "Interface size: %s" % ["Small", "Normal", "Large"][profile.text_size]
	sound_toggle.text = "Sound: %s" % ("ON" if profile.sound_on else "OFF")
	fullscreen_toggle.text = "Fullscreen: %s" % ("ON" if profile.fullscreen else "OFF")
	dark_toggle.text = "Dark art: %s" % ("ON" if profile.dark_art else "OFF")
	battery_toggle.text = "Battery saver: %s" % ("ON" if profile.battery_saver else "OFF")
	graphics_toggle.text = "Graphics: %s" % ("Low" if profile.low_graphics else "Normal")
	path_toggle.text = "Choose-your-path rooms: %s" % ("ON" if profile.path_choice == "ask" else "OFF")
	dev_toggle.text = "Dev Mode: %s" % ("ON" if profile.dev_mode else "OFF")
	dev_toggle.add_theme_color_override("font_color", UI.PINK if profile.dev_mode else UI.TEXT)
	dev_box.visible = profile.dev_mode
	if dev_info and main.started:
		var w := Monsters.tier_weights(state.hardcore)
		var parts := []
		for t in w.size():
			parts.append("%s %.1f%%" % [Monsters.tier_name(t), w[t]])
		dev_info.text = "Now: floor %d (%s), monster tier %s %s, wheel always wins: %s\nSpawn odds: %s" % [state.floor_num, GameData.sub_name(state.floor_num),
			Monsters.tier_name(state.enemy_tier), str(state.enemy_mods), "ON" if state.dev_always_win else "OFF", ", ".join(parts)]
