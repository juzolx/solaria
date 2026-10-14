class_name PetTab
extends ScrollContainer
## Hero > Pets (visible to everyone, so players know pets exist): your class
## companion if your class has one, your owned pets (pick who comes along),
## your eggs, and empty slots that hint at what's out there.

var main
var state: GameState
var box: VBoxContainer
var shown := ""
var renaming := -1

func setup(m) -> void:
	main = m
	name = "Pets"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	state = main.state
	var key := "%s|%s|%s|%d|%s|%s|%d|%d" % [str(state.pets), str(state.pets_out), str(state.eggs), state.level, state.pet_on, state.pet_name,
		World.pet_stage(state), renaming]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	_pet_card()
	_owned()

func _owned() -> void:
	var tamer := Menagerie.is_tamer(state)
	var out_n := Menagerie.out(state).size()
	UI.section(box, "Your pets", "Pets fight beside you and grow with every kill. %s Pets are never lost: when your team goes down they come home hurt and rest, or the Clinic in town patches them up." % (
		"As a tamer you bring up to %d at a time." % Menagerie.TAMER_OUT if tamer else "You can bring %d along." % Menagerie.OTHERS_OUT))
	if not state.pets.is_empty():
		box.add_child(UI.label("COMING ALONG  %d / %d" % [out_n, Menagerie.max_out(state)], 11, UI.DIM))
	for p in state.pets:
		box.add_child(_pet_row(p))
	for e in state.eggs:
		var c := UI.card(Color("#fde68a"))
		box.add_child(c[0])
		var h := UI.hbox(10)
		c[1].add_child(h)
		var pic := TextureRect.new()
		pic.texture = Sprites.consumable_icon("egg")
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.custom_minimum_size = Vector2(48, 48)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(pic)
		h.add_child(UI.wrap("An egg. Something inside is moving. It hatches in %d floor%s." % [int(e["floors"]), "" if int(e["floors"]) == 1 else "s"], 13, UI.TEXT))
	# Empty slots hint at what's out there (never how)
	var empty := maxi(0, 3 - state.pets.size() - state.eggs.size())
	for i in empty:
		var c := UI.card(UI.BORDER)
		box.add_child(c[0])
		var hints := ["An empty nest. Some quests end with an egg.", "Some say a goblin trader once sold an egg. Nobody asked where he got it.",
			"Wild things remember kindness."]
		c[1].add_child(UI.wrap("?  " + hints[(i + state.pets.size()) % hints.size()], 12, UI.DIM))

func _pet_row(p: Dictionary) -> PanelContainer:
	var id := int(p["id"])
	var hurt := int(p["hurt"]) > 0
	var going := id in state.pets_out and not hurt
	var c := UI.card(UI.GREEN if going else (UI.RED.darkened(0.3) if hurt else UI.BORDER))
	var h := UI.hbox(10)
	c[1].add_child(h)
	var pic := TextureRect.new()
	pic.texture = Menagerie.texture(p)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if hurt:
		pic.modulate = Color(1, 0.6, 0.6, 0.7)
	h.add_child(pic)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(String(p["name"]), 15, UI.GOLD if going else UI.TEXT))
	var tier := int(p["tier"])
	var tc := Color(GameData.color_of(mini(tier, 5)))
	v.add_child(UI.label("%s %s  ·  Lv %d" % [Menagerie.TIER_NAMES[tier], p["species"], int(p["level"])], 12, tc))
	v.add_child(UI.label(("Hurt: rests %d more floor%s" % [int(p["hurt"]), "" if int(p["hurt"]) == 1 else "s"]) if hurt else
		"Hits for %d%% of your Attack" % int(Menagerie.power(p) * 100), 11, UI.RED if hurt else UI.DIM))
	var right := UI.vbox(4)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	var b := UI.button("Coming" if going else ("Resting" if hurt else "At home"), func():
		if Menagerie.toggle_out(state, id):
			main.sfx.play("click")
			state.save_game()
		else:
			main.toast("Hurt pets must rest first." if hurt else "Your team is full (%d)." % Menagerie.max_out(state))
		shown = ""
		main.refresh())
	b.custom_minimum_size = Vector2(96, UI.TAP)
	right.add_child(b)
	var rn := UI.button("Rename", func():
		renaming = -1 if renaming == id else id
		shown = ""
		main.refresh())
	rn.custom_minimum_size = Vector2(96, UI.TAP)
	right.add_child(rn)
	if renaming == id:
		var row := UI.hbox(6)
		c[1].add_child(row)
		var le := LineEdit.new()
		le.text = String(p["name"])
		le.max_length = 18
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(le)
		var ok := UI.button("Save", func():
			Menagerie.rename(state, id, le.text)
			renaming = -1
			shown = ""
			main.refresh())
		ok.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(ok)
	return c[0]

## Your class companion: what it is, what it does, and what it becomes.
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
	pic.custom_minimum_size = Vector2(64, 64)
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
