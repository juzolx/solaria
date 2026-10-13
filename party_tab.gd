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
	var key := "%s|%s|%d|%s|%s|%d" % [str(state.party_slots), hp_key, state.level, state.pet_on, state.pet_name, World.pet_stage(state)]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	_pet_card()
	box.add_child(UI.label("YOUR PARTY", 15, UI.GOLD))
	var note := UI.label("Up to 2 of your other Regular heroes can fight beside you. They use their own gear, stats and skills, level up with you, and share one skill book. Monsters get tougher with a bigger party and aim mostly at tanks (Warrior, Knight). Fallen companions get back up on the next floor.", 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	if state.hardcore:
		box.add_child(UI.label("Hardcore heroes fight alone. One life, no backup.", 14, UI.RED))
		return
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
		var t := UI.label("No other Regular heroes yet. Make more from the title screen: hero slot 2 opens at floor 25 and slot 3 at floor 50.", 12, UI.DIM)
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

func _pic(app: Dictionary, looks := {}) -> TextureRect:
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(app, looks)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(56, 56)
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

## Your companion: what it is, what it does, and what it becomes.
func _pet_card() -> void:
	var info := World.pet_info(state)
	if info.is_empty():
		return
	var st := World.pet_stage(state)
	var col := Color(info["color"])
	UI.section(box, "Companion", "A companion joins you at level %d. It fights every turn and evolves when your class does. Charisma makes it stronger." % World.PET_LEVEL)
	var c := UI.card(col if st >= 0 else UI.BORDER)
	box.add_child(c[0])
	if st < 0:
		c[1].add_child(UI.label("Someone is watching you from the shadows... (level %d)" % World.PET_LEVEL, 13, UI.DIM))
		return
	var h := UI.hbox(8)
	c[1].add_child(h)
	var pic := TextureRect.new()
	pic.texture = Pets.portrait(state)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(pic)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(World.pet_name(state), 17, col.lightened(0.3)))
	v.add_child(UI.label("%s, stage %d of 4" % [World.pet_species(state), st + 1], 12, UI.DIM))
	var tog := UI.button("Fighting" if state.pet_on else "Resting", func():
		state.pet_on = not state.pet_on
		state.save_game()
		shown = ""
		main.refresh())
	tog.custom_minimum_size = Vector2(90, UI.TAP)
	h.add_child(tog)
	c[1].add_child(UI.wrap("%s Hits for %d%% of your Attack every turn." % [info["text"], int(float(World.PET_POWER[st]) * state.party_mult() * 100)], 12, UI.TEXT))
	var stages: Array = []
	for i in 4:
		stages.append(String(info["stages"][i]) if i <= st or state.dev_mode else "???")
	c[1].add_child(UI.wrap("Evolves: " + "  >  ".join(stages), 12, UI.DIM))
	var nrow := UI.hbox(6)
	c[1].add_child(nrow)
	var le := LineEdit.new()
	le.placeholder_text = "Give it a name"
	le.text = state.pet_name
	le.max_length = 18
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, UI.TAP)
	nrow.add_child(le)
	var sv := UI.button("Name it", func():
		state.pet_name = le.text.strip_edges()
		state.save_game()
		shown = ""
		main.refresh())
	sv.custom_minimum_size = Vector2(0, UI.TAP)
	nrow.add_child(sv)
