class_name PartyTab
extends ScrollContainer
## Character > Party: bring your other Regular heroes along. They fight with
## their own gear and skills, earn XP with you, and share your skill book.

var main
var state: GameState
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Party"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var hp_key := ""
	if state.party != null:
		for mem in state.party.members:
			hp_key += "%d/%d," % [mem.hp, mem.hero.level]
	var key := "%s|%s|%d|%s|%s|%d|%s|%s|%s" % [str(state.party_slots), hp_key, state.level, state.pet_on, state.pet_name, World.pet_stage(state), str(main.profile.presets), state.in_town, str(state.bench_haul.get("gold", 0))]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	box.add_child(UI.label("YOUR PARTY", 15, UI.GOLD))
	var note := UI.label("Take a team of 3: you plus up to 2 of your other Regular heroes. They use their own gear, stats and skills, level up with you, and share one skill book. Monsters get tougher with a bigger team and aim mostly at tanks (Warrior, Knight). A hero who falls loses only their own worn gear (bound items stay) and gets back up on the next floor. The run fails only when all three are down. Leave gear you love at home, or send a team with nothing to lose.", 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if state.hardcore:
		box.add_child(note)
		box.add_child(UI.label("Hardcore heroes fight alone. One life, no backup.", 14, UI.RED))
		return
	_preset_rows()
	box.add_child(note)
	box.add_child(_card_for_leader())
	if state.party != null:
		for mem in state.party.members:
			box.add_child(_member_card(mem))
	# Heroes you could bring
	var options: Array = []
	for n in range(1, GameData.MAX_HEROES + 1):
		if n == state.slot or n in state.party_slots:
			continue
		var meta := GameState.slot_meta(n)
		if meta.is_empty() or meta.get("hardcore", false) or str(meta.get("class", "")) == "":
			continue
		options.append([n, meta])
	box.add_child(UI.heading("Bring along"))
	if options.is_empty():
		var t := UI.label("No other Regular heroes yet. Make more from the title screen: each town holds up to %d heroes." % GameData.MAX_HEROES, 12, UI.DIM)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(t)
	for o in options:
		var meta: Dictionary = o[1]
		var row := UI.panel(UI.INSET, UI.BORDER, 8, 8, 1)
		box.add_child(row)
		var h := UI.hbox(8)
		row.add_child(h)
		h.add_child(_pic(meta.get("appearance", {})))
		var r := UI.rich(13)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.text = HeroSelect.describe(meta)
		h.add_child(r)
		var add := UI.primary("Add", func():
			var slots: Array = state.party_slots.duplicate()
			slots.append(int(o[0]))
			state.set_party(slots)
			main.sfx.play("equip")
			shown = ""
			main.refresh(), UI.GREEN)
		add.disabled = state.party_slots.size() >= Party.MAX_COMPANIONS
		add.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(add)
	_bench_rows()
	_synergy_rows()

## Next update: three saved line-ups for this town. One tap puts the team together
## (a different leader means switching heroes, so that one waits until you're in town).
func _preset_rows() -> void:
	box.add_child(UI.heading("Team presets"))
	var p: Profile = main.profile
	for i in 3:
		var pr: Dictionary = p.presets[i] if i < p.presets.size() else {}
		var slots: Array = pr.get("slots", []).filter(func(n): return GameState.has_slot(int(n)))
		var names: Array = []
		for n in slots:
			names.append(str(GameState.slot_meta(int(n)).get("name", "Hero")))
		var row := UI.hbox(6)
		box.add_child(row)
		var use := UI.button("%d: %s" % [i + 1, " + ".join(names) if not names.is_empty() else "empty"], _apply_preset.bind(i))
		use.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		use.clip_text = true
		var other_leader := not slots.is_empty() and int(slots[0]) != state.slot
		use.disabled = slots.is_empty() or (other_leader and not state.in_town)
		use.tooltip_text = "Leads with %s: switch heroes in town." % names[0] if other_leader else "Put this team together"
		row.add_child(use)
		var save := UI.button("Save", func():
			while p.presets.size() < 3:
				p.presets.append({})
			p.presets[i] = {"slots": [state.slot] + state.party_slots}
			p.save()
			main.sfx.play("click")
			shown = ""
			main.refresh())
		save.tooltip_text = "Save your current team here"
		row.add_child(save)

func _apply_preset(i: int) -> void:
	var slots: Array = main.profile.presets[i].get("slots", []).filter(func(n): return GameState.has_slot(int(n)))
	if slots.is_empty():
		return
	var comps: Array = slots.slice(1)
	main.sfx.play("equip")
	if int(slots[0]) == state.slot:
		if state.party != null:
			state.party.save_all()
		state.set_party(comps)
		shown = ""
		main.refresh()
		return
	TitleScreen.pending = {"play": int(slots[0]), "party": comps}
	main.back_to_title()

## Next update: heroes at home bring in gold, scrap and now and then an item while you dive.
func _bench_rows() -> void:
	box.add_child(UI.heading("At home"))
	if state.bench_roster.is_empty():
		box.add_child(UI.wrap("Heroes you leave at home find gold, scrap and sometimes an item while you dive. What they find depends on their class.", 12, UI.DIM))
		return
	for h in state.bench_roster:
		var r := Bench.rate(str(h["class"]))
		var best := []
		for k in ["gold", "scrap", "item"]:
			if float(r[k]) > 1.0:
				best.append(k + "s" if k == "item" else k)
		var l := UI.rich(12)
		l.text = "[b]%s[/b], Lv %d %s: %s%s" % [h["name"], int(h["level"]), h["class"], r["job"], ("  [color=%s](good at %s)[/color]" % [UI.hex(UI.GREEN), " and ".join(best)]) if not best.is_empty() else ""]
		box.add_child(l)
	var haul := state.bench_haul
	var n_items: int = haul.get("items", []).size()
	box.add_child(UI.wrap("Found so far this dive: %d gold, %d scrap, %d item%s. Paid out when you get home." % [int(haul.get("gold", 0)), int(haul.get("scrap", 0)), n_items, "" if n_items == 1 else "s"], 12, UI.GOLD))

func _pic(app: Dictionary, looks := {}) -> TextureRect:
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(app, looks)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(64, 64)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return pic

func _card_for_leader() -> PanelContainer:
	var p := UI.panel(Color("#2a2010"), UI.GOLD, 8, 8, 2)
	var h := UI.hbox(8)
	p.add_child(h)
	h.add_child(_pic(state.appearance, state.hero_looks()))
	var r := UI.rich(13)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.text = "[b]%s[/b]  [color=#e8b14a](you, the leader)[/color]\nLv %d %s  -  %s\nHP %d / %d" % [
		state.hero_name if state.hero_name != "" else "Hero", state.level, state.title(), state.class_info().get("role", ""), state.hero_hp, state.get_max_hp()]
	h.add_child(r)
	return p

func _member_card(mem) -> PanelContainer:
	var g: GameState = mem.hero
	var p := UI.panel(UI.INSET, Color(g.class_info().get("color", "#ffffff")).darkened(0.2), 8, 8, 2)
	var h := UI.hbox(8)
	p.add_child(h)
	h.add_child(_pic(g.appearance, g.hero_looks()))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var r := UI.rich(13)
	var skills: Array = []
	for id in g.equipped_actives():
		skills.append(SkillData.skill_name(id))
	r.text = "[b]%s[/b]  %s\nLv %d %s  -  %s%s\n[color=%s]Skills: %s[/color]" % [mem.name, "[color=#f87171](knocked out)[/color]" if mem.knocked_out else "",
		g.level, g.title(), mem.role(), "  (tank)" if mem.is_tank() else "", UI.hex(UI.DIM), ", ".join(skills) if not skills.is_empty() else "none"]
	v.add_child(r)
	var bar := UI.bar(UI.GREEN, 8)
	bar.max_value = mem.max_hp()
	bar.value = mem.hp
	v.add_child(bar)
	var rm := UI.button("Remove", func():
		var slots: Array = state.party_slots.duplicate()
		slots.erase(mem.slot)
		state.party.save_all()
		state.set_party(slots)
		shown = ""
		main.refresh())
	rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(rm)
	return p


## Team synergies (synergies.gd): the ones your team has light up, the rest say how to get them.
func _synergy_rows() -> void:
	var on := Synergies.active(state) if state.party != null and state.party.size() > 0 else []
	box.add_child(UI.label("TEAM SYNERGIES  (%d active)" % on.size(), 13, UI.GOLD))
	for id in Synergies.LIST:
		var s: Dictionary = Synergies.LIST[id]
		var got: bool = id in on
		var l := UI.label(("%s  -  %s" % [s["name"], s["text"]]), 12, Color(String(s["color"])) if got else UI.DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	var ts := UI.label("Team Strike: with companions standing, your whole team hits together every %d turns of a fight." % Synergies.STRIKE_EVERY, 12, UI.DIM)
	ts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(ts)
