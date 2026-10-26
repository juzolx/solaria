class_name PetTab
extends ScrollContainer
## Character > Pets (visible to everyone, so players know pets exist): your class
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
	var key := "%s|%s|%s|%d|%s|%s|%d|%d" % [pets_key(state), str(state.pets_out), str(state.eggs), state.level, state.pet_on, state.pet_name,
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
	# Fable r1 #12: one line; the rest is a tap away
	var bring := ("As a tamer you bring up to %d at a time." % Menagerie.TAMER_OUT) if tamer else (("You can bring one along.") if Menagerie.OTHERS_OUT == 1 else ("You can bring %d along." % Menagerie.OTHERS_OUT))
	var hd := UI.heading("Your pets", "They fight beside you and are never lost. %s" % bring)
	UI.tip(hd, "Pets grow with every kill. When your team goes down they come home hurt and rest, or the Clinic in town patches them up.")
	box.add_child(hd)
	if not state.pets.is_empty():
		box.add_child(UI.heading("Coming along", "%d of %d" % [out_n, Menagerie.max_out(state)]))
	# Fable pets R4: the team first, then the rest by rank and level, the resting ones last;
	# eggs (they have a quest to read) right after the team
	var order := sorted(state)
	var going := Menagerie.out(state).size()
	for i in order.size():
		if i == going:
			_eggs()
		var p: Dictionary = order[i]
		if int(p["hurt"]) > 0 and (i == 0 or int(order[i - 1]["hurt"]) <= 0):
			box.add_child(UI.label("RESTING", UI.FONT_CAPTION, UI.DIM))
		box.add_child(_pet_row(p))
	if order.size() <= going:
		_eggs()
	_hints()

## The order the tab shows pets in: coming along (team order), healthy by rank then level, hurt.
static func sorted(g: GameState) -> Array:
	var team := Menagerie.out(g)
	var rest: Array = g.pets.filter(func(p): return not team.has(p))
	rest.sort_custom(func(a, b):
		var ha := int(a["hurt"]) > 0
		var hb := int(b["hurt"]) > 0
		if ha != hb:
			return hb
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) > int(b["tier"])
		return int(a["level"]) > int(b["level"]))
	return team + rest

## What the tab shows of each pet (not its kill count, which goes up every kill).
static func pets_key(g: GameState) -> String:
	var parts: Array = []
	for p in g.pets:
		parts.append([p["id"], p["name"], p["tier"], p["level"], p["hurt"], p.get("cherished", false)])
	return str(parts)

func _eggs() -> void:
	for e in state.eggs:
		var c := _frame(UI.GOLD_DULL)
		box.add_child(c[0])
		var h := UI.hbox(10)
		c[1].add_child(h)
		var ez := Menagerie.egg_zone(e)
		var pic := PixelPic.make(Pets.egg(String(GameData.ZONES[ez]["id"]) if ez >= 0 else ""))  # Pets 2: each region its own egg, whole screen pixels
		h.add_child(_slot(pic))
		var ev := UI.vbox(2)
		ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(ev)
		var etier := clampi(int(e.get("tier", 0)), 0, 5)
		ev.add_child(UI.label(Menagerie.egg_name(e), UI.FONT_BODY, Color(Menagerie.TIER_COLORS[etier])))
		ev.add_child(UI.wrap("Something inside is moving. It hatches in %d floor%s.\nQuest: %s" % [int(e["floors"]), "" if int(e["floors"]) == 1 else "s", EggQuests.text(e)], UI.FONT_BODY, UI.TEXT))

## Empty slots hint at what's out there (never how)
func _hints() -> void:
	var empty := maxi(0, 3 - state.pets.size() - state.eggs.size())
	for i in empty:
		var c := _frame(UI.EMPTY)
		box.add_child(c[0])
		var hints := ["Old hunters swear there are nests in the deep halls, for the lucky.",
			"Every region keeps its own eggs, they say. Few ever see one.",
			"A nest is a rarer thing than most heroes meet in a lifetime."]
		c[1].add_child(UI.wrap("?  " + hints[(i + state.pets.size()) % hints.size()], UI.FONT_BODY, UI.DIM))

func _pet_row(p: Dictionary) -> PanelContainer:
	var id := int(p["id"])
	var hurt := int(p["hurt"]) > 0
	var going := id in state.pets_out and not hurt
	var c := _frame(UI.GOLD_DULL if going else (Color("#a22633") if hurt else UiSkin.IRON))   # gold = coming along, red = hurt
	var h := UI.hbox(10)
	c[1].add_child(h)
	var pic := PixelPic.make(Menagerie.texture(p))  # about 2x, in whole screen pixels
	if hurt:
		pic.modulate = Color(1, 0.6, 0.6, 0.7)
	h.add_child(_slot(pic))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(String(p["name"]), UI.FONT_BODY, UI.GOLD if going else UI.TEXT))
	var tier := int(p["tier"])
	var tc := Color(GameData.color_of(mini(tier, 5)))
	v.add_child(UI.label("%s %s  ·  Lv %d" % [Menagerie.TIER_NAMES[tier], Monsters.name_of(str(p["species"])), int(p["level"])], UI.FONT_BODY, tc))
	v.add_child(UI.wrap(("Hurt: rests %d more floor%s, or the Clinic heals it for %s gold" % [int(p["hurt"]), "" if int(p["hurt"]) == 1 else "s", UI.short(Menagerie.heal_cost(p))]) if hurt else
		"Hits for %d%% of your Attack" % _hits(p), UI.FONT_CAPTION, UI.RED if hurt else UI.DIM))
	_ability_lines(v, p, renaming == id)   # names only on the card; the sentences and locked ones under "More"
	var right := UI.vbox(8)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	var full := Menagerie.out(state).size() >= Menagerie.max_out(state)
	# Juzo (Oct 25): one of each kind per team; a copy of a kind that's out says so
	var twin := Menagerie.same_kind_out(state, id) if not going and not hurt else {}
	if not twin.is_empty():
		v.add_child(UI.wrap("%s is already out: one of each kind per team." % String(twin["name"]), UI.FONT_CAPTION, UI.DIM))
	var b := UI.button("Coming along" if going else ("Resting" if hurt else ("One is out" if not twin.is_empty() else ("Swap in" if full else "Bring along"))), func():
		if Menagerie.toggle_out(state, id):
			main.sfx.play("click")
			state.save_game()
		else:
			var why := Menagerie.out_block(state, id)
			main.toast(why if why != "" else "Your team is full (%d)." % Menagerie.max_out(state))
		shown = ""
		main.refresh())
	b.custom_minimum_size = Vector2(96, UI.TAP)
	if hurt:
		b.disabled = true   # Fable pets R4: a tap used to drop it from the team without a word
		b.tooltip_text = "Comes back when it has rested"
	elif not twin.is_empty():
		b.modulate = Color(1, 1, 1, 0.55)   # greyed, but a tap still says why
	right.add_child(b)
	var rn := UI.button("Less" if renaming == id else "More", func():
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
		var ok := UI.button("Rename", func():
			Menagerie.rename(state, id, le.text)
			renaming = -1
			shown = ""
			main.refresh())
		ok.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(ok)
		var rel := UI.button("Release", func():
			main.confirm("Release %s?" % String(p["name"]), "%s goes back to the wild for good. Pets are hard to find, so be sure. Your Codex remembers you had one." % String(p["name"]), "Release", func():
				Menagerie.release(state, id)
				renaming = -1
				shown = ""
				main.refresh()))
		rel.add_theme_color_override("font_color", UI.RED)
		rel.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(rel)
	return c[0]

## What one hit of this pet is, as a share of your Attack: Menagerie.turn's own sum
## (a Beast Lord's song and the party's strength included).
func _hits(p: Dictionary) -> int:
	return int(Menagerie.power(p) * (Menagerie.WHISPER_POWER if Menagerie.whisperer_near(state) else 1.0) * state.party_mult() * 100)

## 2.1: what the pet knows (by its rank), and what a higher-ranked one of its kind
## would know. A pet's rank never changes, so this pet won't learn those itself.
func _ability_lines(v: VBoxContainer, p: Dictionary, show_locked := true) -> void:
	var fam := String((PetAbilities.FAMILIES.get(PetAbilities.family(String(p.get("species", ""))), {}) as Dictionary).get("name", "pet"))
	if not show_locked:
		# Fable pets R2: the card names what it knows in one line ("More" opens the sentences)
		var names: Array = []
		for a in PetAbilities.lines(p):
			if a["on"]:
				names.append(String(a["text"]).get_slice(":", 0))
		v.add_child(UI.wrap("  ·  ".join(names), UI.FONT_BODY, Color(GameData.color_of(mini(PetAbilities._rank(p), 5)))))
	for a in PetAbilities.lines(p):
		if a["on"]:
			if show_locked:
				v.add_child(UI.wrap("+ " + String(a["text"]), UI.FONT_BODY, UI.TEXT))
		elif show_locked:
			v.add_child(UI.wrap("A higher-ranked %s pet (%s and up) would know: %s" % [fam, Menagerie.TIER_NAMES[int(a["rank"])], a["text"]], UI.FONT_BODY, UI.DIM))
	# all Spirits together heal at most REGEN_CAP a turn: say so when it cuts this one
	var rs := PetAbilities.regen_share(state, p)
	if rs >= 0.0 and rs < PetAbilities.passive_value(String(p["species"]), PetAbilities._rank(p)) - 0.001:
		v.add_child(UI.wrap("Team regen is capped at %s%% a turn: this pet adds %s%%." % [PetAbilities._num(PetAbilities.REGEN_CAP), PetAbilities._num(rs)], UI.FONT_BODY, UI.GOLD_DULL))

## Your class companion: what it is, what it does, and what it becomes.
func _pet_card() -> void:
	var info := World.pet_info(state)
	if info.is_empty():
		return
	var st := World.pet_stage(state)
	var col := Color(info["color"])
	UI.section(box, "Companion", "A companion joins you at level %d. It fights every turn and evolves when your class does. Charisma makes it stronger." % World.PET_LEVEL)
	var c := _frame(UiSkin.IRON)   # the companion's own colour stays in its name
	box.add_child(c[0])
	if st < 0:
		c[1].add_child(UI.label("Someone is watching you from the shadows... (level %d)" % World.PET_LEVEL, UI.FONT_BODY, UI.DIM))
		return
	var h := UI.hbox(8)
	c[1].add_child(h)
	var pic := PixelPic.make(Pets.portrait(state))
	h.add_child(_slot(pic))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(World.pet_name(state), 17, col.lightened(0.3)))
	v.add_child(UI.label("%s, stage %d of 4" % [World.pet_species(state), st + 1], UI.FONT_BODY, UI.DIM))
	var tog := UI.button("Fighting" if state.pet_on else "Send to fight", func():
		state.pet_on = not state.pet_on
		state.save_game()
		shown = ""
		main.refresh())
	tog.custom_minimum_size = Vector2(90, UI.TAP)
	h.add_child(tog)
	c[1].add_child(UI.wrap("%s Hits for %d%% of your Attack every turn." % [info["text"], int(float(World.PET_POWER[st]) * state.party_mult() * 100)], UI.FONT_BODY, UI.TEXT))
	var stages: Array = []
	for i in 4:
		stages.append(String(info["stages"][i]) if i <= st or state.dev_mode else "???")
	c[1].add_child(UI.wrap("Evolves: " + "  >  ".join(stages), UI.FONT_BODY, UI.DIM))
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
		state.pet_name = Menagerie.clean_name(le.text)   # it goes into the log's BBCode
		state.save_game()
		shown = ""
		main.refresh())
	sv.custom_minimum_size = Vector2(0, UI.TAP)
	nrow.add_child(sv)

## Interface pass (approved mockup 06): a pet card wears the panel frame, its line in the
## pet's state colour (gold = coming along, red = hurt). Returns [card, inner vbox] like UI.card.
func _frame(edge: Color) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, edge, 10))
	var v := UI.vbox(4)
	p.add_child(v)
	return [p, v]

## A pet or egg picture in a dark slot (ink fill, slate edge), the art at a clean 2x.
func _slot(pic: Control) -> PanelContainer:
	var sl := PanelContainer.new()
	sl.add_theme_stylebox_override("panel", UiSkin.bevel(Color("#120e1c"), UI.EMPTY, 2))
	sl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sl.add_child(pic)
	return sl
