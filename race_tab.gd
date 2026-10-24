class_name RaceTab
extends ScrollContainer
## Character > Race: your racial power and awakening, your transformation
## (and any cure), how every race feels about you, and the realms.

var main
var state: GameState
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Race"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var key := "%s|%s|%d|%d|%d|%s|%s|%d|%s|%s|%d|%s|%d" % [state.race(), state.form, state.awaken, int(Lineage.power(state) * 10), state.level,
		str(state.race_keys), str(state.rep), state.stat_points, state.cure_active, state.dev_mode, state.cure_kills, str(state.realm_order),
		int(state.faith)]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	_power_card()
	_awakening()
	_form()
	_reputation()
	_realms()

# ---------- Racial power ----------

func _power_card() -> void:
	var r := state.race()
	var info := Races.info(r)
	var p: Dictionary = info["power"]
	var c := Color(p["color"])
	var card := UI.panel(UI.INSET, c, 10, 12, 2)
	box.add_child(card)
	var v := UI.vbox(6)
	card.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(state.appearance, state.hero_looks())
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 2
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	var hv := UI.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	var title := Lineage.rank_name(state)
	if state.form != "":
		title += "  -  " + state.form
	hv.add_child(UI.label(title.to_upper(), 20, c.lightened(0.3)))
	var t := UI.rich(UI.FONT_CAPTION)
	t.text = "[color=%s]%s.[/color] %s" % [UI.hex(UI.DIM), r, info["text"]]
	hv.add_child(t)
	# The meter
	var pw := Lineage.power(state)
	var nr := Lineage.next_rank(state)
	var row := UI.hbox(8)
	v.add_child(row)
	var pl := UI.label("%s  %.1f" % [p["name"], pw], UI.FONT_CAPTION, c)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pl)
	for n in [1, 5]:
		var b := UI.button("+%d" % n, func(): Lineage.spend_power(state, n); main.refresh())
		b.disabled = state.stat_points < n
		b.tooltip_text = "Put %d stat point%s into %s (each is worth %.1f)" % [n, "" if n == 1 else "s", p["name"], Races.POWER_POINT]
		row.add_child(b)
	var bar := UI.bar(c, 10)
	bar.max_value = float(nr["power"]) if not nr.is_empty() else maxf(1.0, pw)
	bar.value = minf(pw, bar.max_value)
	v.add_child(bar)
	var fl := UI.rich(UI.FONT_CAPTION)
	var side := "Good" if state.faith >= 0.0 else "Evil"
	fl.text = "[color=%s]Faith: [/color][color=%s]%s %d[/color][color=%s]  (Holy skills, bosses and good deeds raise it; Shadow and Blood skills and dark bargains lower it. It opens and locks realms%s.)[/color]" % [
		UI.hex(UI.DIM), "#fde68a" if side == "Good" else "#8b5cf6", side, int(absf(state.faith)), UI.hex(UI.DIM),
		", and an Angel who falls too far never rises again" if r == "Angel" else ""]
	v.add_child(fl)
	var how := UI.rich(UI.FONT_CAPTION)
	how.text = "[color=%s]%s Every 10 points: %s[/color]" % [UI.hex(UI.DIM), p["how"], Classes.bonus_text(Races.power_bonus(r, 10.0))]
	v.add_child(how)

# ---------- Awakening ----------

func _awakening() -> void:
	box.add_child(UI.heading("Awakening"))
	var r := state.race()
	var rk := Races.ranks(r)
	for i in rk.size():
		var rank: Dictionary = rk[i]
		var done := i < state.awaken
		var next := i == state.awaken
		var c := Color(Races.power_info(r)["color"])
		var p := UI.panel(Color("#2a2010") if done else UI.INSET, UI.GOLD if done else (c.darkened(0.2) if next else UI.BORDER), 8, 8, 2 if done or next else 1)
		box.add_child(p)
		var v := UI.vbox(3)
		p.add_child(v)
		var known := done or next or state.is_discovered(rank["name"])
		v.add_child(UI.label(("%d. %s" % [i + 1, rank["name"] if known else "???"]) + ("  (you)" if done and i == state.awaken - 1 else ""), UI.FONT_CAPTION, UI.GOLD if done else UI.TEXT))
		var lines: Array = []
		lines.append(_need("Level %d" % int(rank["level"]), state.level >= int(rank["level"]) or done))
		lines.append(_need("%d %s" % [int(rank["power"]), Races.power_info(r)["name"]], Lineage.power(state) >= float(rank["power"]) or done))
		var key: Dictionary = rank["key"]
		if key.has("item"):
			lines.append(_need(Races.key_text(key), done or String(key["item"]) in state.race_keys))
		elif key.has("trial"):
			lines.append(_need(Races.key_text(key), done))
		var t := UI.rich(UI.FONT_CAPTION)
		t.text = "  ".join(lines) + ("\n" + String(rank["text"]) if known else "")
		v.add_child(t)
		if next:
			var why := Lineage.awaken_block(state)
			if why == "":
				v.add_child(UI.primary("Awaken as %s" % rank["name"], func():
					Lineage.awaken(state)
					main.refresh(), UI.GOLD))
			elif why == "trial":
				var tb := UI.primary("Face %s" % key["trial"]["name"], func():
					if state.start_race_trial():
						main.sfx.play("boss_intro")
					main.refresh(), UI.GOLD)
				tb.disabled = state.enemy_is_boss or Portals.inside(state)  # in town: tapping says why (Portals.open_block)
				v.add_child(tb)
	if not state.race_keys.is_empty():
		var kt := UI.rich(UI.FONT_CAPTION)
		kt.text = "[color=%s]Carrying:[/color] %s" % [UI.hex(UI.DIM), ", ".join(state.race_keys)]
		box.add_child(kt)

func _need(text: String, ok: bool) -> String:
	return "[color=%s]%s %s[/color]" % ["#4ade80" if ok else UI.hex(UI.DIM), "+" if ok else "-", text]

# ---------- Transformation ----------

func _form() -> void:
	var lich := Races.FORMS["Lich"]
	var lich_near: bool = state.form == "" and state.hero_class in lich["need"]["classes"] and state.level >= int(lich["need"]["level"]) - 10
	if state.form == "" and not lich_near:
		return
	box.add_child(UI.heading("Transformation"))
	if state.form != "":
		var f: Dictionary = Races.FORMS[state.form]
		var t := UI.rich(UI.FONT_CAPTION)
		t.text = "[color=%s][b]%s.[/b][/color] %s\n[color=%s]%s[/color]" % [f["color"], state.form, f["text"], UI.hex(UI.DIM),
			"There's a cure, if you want one." if f["curable"] else "This is forever. Only starting the hero over can undo it."]
		box.add_child(t)
		if f["curable"]:
			var c := Lineage.cure_info(state)
			if not state.cure_active:
				box.add_child(UI.button("Search for a cure", func(): Lineage.start_cure(state); main.refresh()))
			else:
				var ct := UI.rich(UI.FONT_CAPTION)
				ct.text = String(c["text"]) % int(c["kills"]) + "\n[color=%s]Progress: %s[/color]" % [UI.hex(UI.DIM), Lineage.cure_block(state) if Lineage.cure_block(state) != "" else "ready"]
				box.add_child(ct)
				var fb := UI.primary("Finish the cure", func(): Lineage.finish_cure(state); main.refresh(), UI.GREEN)
				fb.disabled = Lineage.cure_block(state) != "" or state.enemy_is_boss
				box.add_child(fb)
		return
	# The Lich ritual
	var why := Lineage.lich_block(state)
	var lt := UI.rich(UI.FONT_CAPTION)
	lt.text = "[color=%s][b]The Lich ritual.[/b][/color] %s\n[color=%s]%s[/color]" % [lich["color"], lich["text"], UI.hex(UI.DIM),
		"You can't go back from this." if why == "" else why]
	box.add_child(lt)
	var rb := UI.primary("Begin the ritual", func():
		Lineage.lich_ritual(state)
		main.refresh(), Color(lich["color"]))
	rb.disabled = why != ""
	box.add_child(rb)

# ---------- Reputation ----------

func _reputation() -> void:
	box.add_child(UI.heading("How the races see you"))
	var t := UI.label("Sparing their people and helping them raises it; killing them lowers it. Helping one race annoys its rivals.", UI.FONT_CAPTION, UI.DIM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(t)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for r in Races.ORDER:
		var val := Lineage.rep(state, r)
		var lv := Races.rep_level(val)
		var nl := UI.label(r, UI.FONT_CAPTION, UI.TEXT)
		nl.custom_minimum_size = Vector2(80, 0)
		grid.add_child(nl)
		var bar := UI.bar(Color(lv[1]), 8)
		bar.min_value = Races.REP_MIN
		bar.max_value = Races.REP_MAX
		bar.value = val
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.tooltip_text = "%d / 100" % int(val)
		grid.add_child(bar)
		var ll := UI.label(lv[0], UI.FONT_CAPTION, Color(lv[1]))
		ll.custom_minimum_size = Vector2(70, 0)
		grid.add_child(ll)

# ---------- Realms ----------

func _realms() -> void:
	if state.best_floor < Realms.FIRST_FLOOR - 50 and not state.dev_mode:
		return
	box.add_child(UI.heading("Realm map (floors %d-%d)" % [Realms.FIRST_FLOOR, Realms.FIRST_FLOOR + 249]))
	var week := Realms.realm_of_week()
	for i in Realms.IDS.size():
		var id: String = state.realm_order[i] if i < state.realm_order.size() else ""
		var t := UI.rich(UI.FONT_CAPTION)
		if id == "":
			var opts: Array = []
			for o in Realms.IDS:
				if not o in state.realm_order:
					var lock := Realms.lock_reason(state, o)
					opts.append("%s%s" % [Realms.realm_name(o), " (locked: %s)" % lock if lock != "" else ""])
			t.text = "[color=%s]Floors %d-%d: not chosen yet.[/color] Open: %s" % [UI.hex(UI.DIM), Realms.FIRST_FLOOR + i * 50, Realms.FIRST_FLOOR + i * 50 + 49, ", ".join(opts)]
		else:
			var inf := Realms.info(id)
			var lv := Races.rep_level(Lineage.rep(state, inf["race"]))
			t.text = "[color=%s][b]%s[/b][/color]  floors %d-%d  -  %d%% done  -  the %s: [color=%s]%s[/color]%s\n[color=%s]%s: %s[/color]" % [
				inf["color"], inf["name"], Realms.FIRST_FLOOR + i * 50, Realms.FIRST_FLOOR + i * 50 + 49, Realms.completion(state, id),
				Lineage.race_plural(inf["race"]), lv[1], lv[0], "  [color=#e8b14a](realm of the week)[/color]" if id == week else "",
				UI.hex(UI.DIM), inf["mechanic"]["name"], inf["mechanic"]["text"]]
		box.add_child(t)
	if not state.quest.is_empty():
		var q := UI.rich(UI.FONT_CAPTION)
		q.text = "[color=#e8b14a]Quest:[/color] %s (%d / %d)" % [state.quest["text"], int(state.quest["have"]), int(state.quest["need"])]
		box.add_child(q)
