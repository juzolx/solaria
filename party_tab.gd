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
	var note := UI.label("Take a team of 3: you plus up to 2 of your other Regular heroes. They use their own gear, stats and skills, level up with you, and share one skill book. Monsters get tougher with a bigger team and aim mostly at tanks (Warrior, Knight). A hero who falls loses only their own worn gear (bound items stay) and gets back up on the next floor. The run fails only when all three are down. Leave gear you love at home, or send a team with nothing to lose.", UI.FONT_CAPTION, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if state.hardcore:
		box.add_child(note)
		box.add_child(UI.label("Hardcore heroes fight alone. One life, no backup.", UI.FONT_CAPTION, UI.RED))
		return
	_preset_rows()
	# interface pass (fewer words): one line here, the full rules on a tap
	var short := UI.wrap("You plus up to 2 of your Regular heroes. Tap here for how teams work.", UI.FONT_CAPTION, UI.DIM)
	UI.tip(short, note.text)
	box.add_child(short)
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
		var t := UI.label("No other Regular heroes yet. Make more from the title screen: each town holds up to %d heroes." % GameData.MAX_HEROES, UI.FONT_CAPTION, UI.DIM)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(t)
	for o in options:
		var meta: Dictionary = o[1]
		var row := _frame(UiSkin.IRON)
		box.add_child(row)
		var h := UI.hbox(8)
		row.add_child(h)
		h.add_child(_slot(_pic(meta.get("appearance", {}))))
		var r := UI.rich(UI.FONT_CAPTION)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.text = HeroSelect.describe(meta)
		h.add_child(r)
		var add := UI.primary("Add", func():
			var slots: Array = state.party_slots.duplicate()
			slots.append(int(o[0]))
			state.set_party(slots)
			main.sfx.play("equip")
			shown = ""
			main.refresh())
		add.disabled = state.party_slots.size() >= Party.MAX_COMPANIONS
		add.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(add)
	_bench_rows()
	_synergy_rows()

## 2.1: one Presets screen (presets.gd) holds team line-ups with gear, skills and supplies.
func _preset_rows() -> void:
	# 2.1: team line-ups are part of the one Presets screen (with gear, skills and supplies)
	var pb := UI.button("Presets: save or swap your team, gear and skills", func(): PresetsScreen.new().show_for(main))
	pb.custom_minimum_size = Vector2(0, UI.TAP)
	box.add_child(pb)

## Next update: heroes at home bring in gold, scrap and now and then an item while you dive.
func _bench_rows() -> void:
	box.add_child(UI.heading("At home"))
	if state.bench_roster.is_empty():
		box.add_child(UI.wrap("Heroes you leave at home find gold, scrap and sometimes an item while you dive. What they find depends on their class.", UI.FONT_CAPTION, UI.DIM))
		return
	for h in state.bench_roster:
		var r := Bench.rate(str(h["class"]))
		var best := []
		for k in ["gold", "scrap", "item"]:
			if float(r[k]) > 1.0:
				best.append(k + "s" if k == "item" else k)
		var l := UI.rich(UI.FONT_CAPTION)
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
	var p := _frame(UI.GOLD_DULL)   # the leader: gold-edged
	var h := UI.hbox(8)
	p.add_child(h)
	h.add_child(_slot(_pic(state.appearance, state.hero_looks())))
	var r := UI.rich(UI.FONT_CAPTION)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.text = "[b]%s[/b]  [color=#e8b14a](you, the leader)[/color]\nLv %d %s  -  %s\nHP %d / %d" % [
		state.hero_name if state.hero_name != "" else "Hero", state.level, state.title(), state.class_info().get("role", ""), state.hero_hp, state.get_max_hp()]
	h.add_child(r)
	return p

func _member_card(mem) -> PanelContainer:
	var g: GameState = mem.hero
	var p := _frame(Color("#a22633") if mem.knocked_out else UiSkin.IRON)   # red edge while knocked out
	var h := UI.hbox(8)
	p.add_child(h)
	h.add_child(_slot(_pic(g.appearance, g.hero_looks())))
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var r := UI.rich(UI.FONT_CAPTION)
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
	box.add_child(UI.label("TEAM SYNERGIES  (%d active)" % on.size(), UI.FONT_CAPTION, UI.GOLD))
	for id in Synergies.LIST:
		var s: Dictionary = Synergies.LIST[id]
		var got: bool = id in on
		var l := UI.label(("%s%s  -  %s" % ["◆ " if got else "", s["name"], s["text"]]), UI.FONT_CAPTION, UI.GOLD if got else UI.DIM)   # one accent: gold = active
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	var ts := UI.label("Team Strike: with companions standing, your whole team hits together every %d turns of a fight." % Synergies.STRIKE_EVERY, UI.FONT_CAPTION, UI.DIM)
	ts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(ts)

## Interface pass (approved mockup 05): a party card wears the panel frame.
func _frame(edge: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, edge, 10))
	return p

## A hero picture in a dark slot (ink fill, slate edge).
func _slot(pic: TextureRect) -> PanelContainer:
	var sl := PanelContainer.new()
	sl.add_theme_stylebox_override("panel", UiSkin.bevel(Color("#120e1c"), UI.EMPTY, 2))
	sl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sl.add_child(pic)
	return sl
