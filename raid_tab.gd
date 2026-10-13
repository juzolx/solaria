class_name RaidTab
extends ScrollContainer
## Online > Raid: this week's guild raid boss. Everyone in the guild gets 3
## attacks a day; the damage adds up. Beat it before the week ends and every
## member can claim a reward.

var main
var box: VBoxContainer
var loaded_at := -100000
var loading := false

func setup(m) -> void:
	main = m
	name = "Raid"
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
	box.add_child(UI.label("Loading...", 13, UI.DIM))
	var g: Dictionary = await online.my_guild()
	OnlineUI.clear(box)
	if not g["ok"]:
		box.add_child(OnlineUI.error_label(g["error"]))
		box.add_child(UI.button("Try again", reload))
		loading = false
		return
	if g["data"] == null:
		box.add_child(UI.label("Raids are for guilds", 18, UI.GOLD))
		box.add_child(UI.label("Join or start a guild in the Guild tab. Then everyone fights the same weekly boss and the damage adds up.", 13, UI.DIM))
		box.add_child(UI.primary("Go to Guild", func(): main.show_tab(4, 1)))
		loading = false
		return
	var gid := int(g["data"]["id"])
	var r: Dictionary = await online.raid_status(gid)
	loading = false
	if not r["ok"]:
		box.add_child(OnlineUI.error_label(r["error"]))
		return
	_show(gid, r["data"])

func _show(gid: int, d: Dictionary) -> void:
	var boss: Dictionary = d["boss"]
	var card := UI.panel(UI.INSET, UI.RED if not d["dead"] else UI.GREEN, 10, 14, 2)
	box.add_child(card)
	var row := UI.hbox(14)
	card.add_child(row)
	var pic := TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(144, 144)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art := Sprites.enemy(str(boss["art"]), true)
	if not art.is_empty():
		pic.texture = art["tex"]
	if d["dead"]:
		pic.modulate = Color(1, 1, 1, 0.45)
	row.add_child(pic)
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label("THIS WEEK'S RAID BOSS", 11, UI.DIM))
	v.add_child(UI.label(str(boss["name"]), 22, UI.RED.lightened(0.2) if not d["dead"] else UI.GREEN))
	var hp := int(d["hp"])
	var dealt := mini(int(d["dealt"]), hp)
	var bar := UI.bar(UI.RED, 14)
	bar.max_value = hp
	bar.value = hp - dealt
	v.add_child(bar)
	v.add_child(UI.label("%s / %s HP left  -  %d guild members" % [_num(hp - dealt), _num(hp), int(d["members"])], 12, UI.DIM))
	v.add_child(UI.label("Resets in %s" % _time_left(), 12, UI.DIM))

	var actions := UI.hbox(8)
	v.add_child(actions)
	if not d["dead"]:
		var left := int(d["attacks_left"])
		var preview := Online.raid_damage(main.state)
		var atk := UI.primary("Attack!  (%d left today)" % left, func(): pass, UI.RED)
		atk.disabled = left <= 0 or main.state.hero_class == ""
		atk.tooltip_text = "One attack is %d turns of fighting. Yours hits for about %s." % [Online.RAID_TURNS, _num(preview)]
		atk.pressed.connect(func():
			atk.disabled = true
			var dmg := Online.raid_damage(main.state)
			var r: Dictionary = await main.online.raid_attack(gid, dmg)
			if r["ok"]:
				main.sfx.play("crit")
				main.state.say("[color=#f87171]Raid:[/color] you hit %s for %s damage!" % [boss["name"], _num(dmg)])
				main.refresh()
			else:
				main.confirm("Raid", r["error"], "OK", func(): pass)
			reload())
		actions.add_child(atk)
		if left <= 0:
			v.add_child(UI.label("Come back tomorrow for 3 more attacks.", 12, UI.DIM))
	elif not d["claimed"]:
		var claim := UI.primary("Claim reward", func(): pass, UI.GREEN)
		claim.pressed.connect(func():
			claim.disabled = true
			var r: Dictionary = await main.online.raid_claim(gid)
			if r["ok"]:
				var text: String = main.state.raid_reward()
				main.sfx.play("legendary")
				main.confirm("Raid reward!", text, "Nice", func(): pass)
				main.refresh()
			reload())
		actions.add_child(claim)
	else:
		v.add_child(UI.label("Defeated! You've claimed this week's reward. A new boss arrives Monday.", 13, UI.GREEN))

	box.add_child(UI.heading("Damage this week"))
	var by: Dictionary = d["damage_by"]
	var names := by.keys()
	names.sort_custom(func(a, b): return int(by[a]) > int(by[b]))
	if names.is_empty():
		box.add_child(UI.label("Nobody has attacked yet. Be first!", 13, UI.DIM))
	for n in names:
		var line := UI.hbox(8)
		var l := UI.label(str(n), 13, UI.GOLD if n == main.profile.player_name else UI.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(l)
		line.add_child(UI.label(_num(int(by[n])), 13, UI.TEXT))
		box.add_child(line)

func _num(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _time_left() -> String:
	var now := Time.get_unix_time_from_system()
	var days := floori(now / 86400.0)
	var monday := days - ((days + 3) % 7)
	var ends := (monday + 7) * 86400.0
	var left := int(ends - now)
	var d := left / 86400
	var h := (left % 86400) / 3600
	return "%dd %dh" % [d, h] if d > 0 else "%dh %dm" % [h, (left % 3600) / 60]
