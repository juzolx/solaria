class_name PetBookTab
extends ScrollContainer
## Codex > Pets (next update): every monster that could be your pet, by area.
## Owned ones show in color with the best tier you've had, monsters you've met
## are shadows with a name, the rest are unknown.

var main
var codex: Codex
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Pets"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var key := "%d|%d|%d|%d|%s" % [codex.pet_book.size(), codex.bestiary.size(), codex.coll_earned.size(), codex.extra_titles.size(), str(codex.pet_book.values())]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var all := Menagerie.all_species()
	var seen := 0
	for n in all:
		if _met(n) or codex.pet_book.has(n):
			seen += 1
	var owned := 0
	for n in all:
		if codex.pet_book.has(n):
			owned += 1
	box.add_child(UI.label("Owned  %d / %d     Seen  %d / %d" % [owned, all.size(), seen, all.size()], 15, UI.GOLD))
	box.add_child(Collections.cards(codex, ["pets", "pet_epic", "pet_myth"]))  # 2.1 G4: progress and the next reward
	box.add_child(UI.wrap("Pets are a real find: hatch an egg, or tame a beast as a Beast Tamer. Tiers go from Common to Mythic.", UI.FONT_BODY, UI.DIM))
	var legend := HFlowContainer.new()   # wraps on a phone
	legend.add_theme_constant_override("h_separation", 8)
	box.add_child(legend)
	for t in Menagerie.TIER_NAMES.size():
		legend.add_child(UI.label(Menagerie.TIER_NAMES[t], UI.FONT_BODY, Color(Menagerie.TIER_COLORS[t])))
	_abilities()
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var mons: Array = []
		for e in z["enemies"]:
			mons.append(e["id"])
		for s in z["subs"]:
			mons.append(s["monster"]["id"])
		box.add_child(UI.heading(str(z["name"])))
		box.add_child(UI.wrap("Mythic signature: " + PetAbilities.region_signature_text(String(z["id"])), UI.FONT_BODY, Color(Menagerie.TIER_COLORS[PetAbilities.SIGNATURE_RANK])))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		box.add_child(flow)
		for n in mons:
			flow.add_child(_cell(str(n)))
	# Fable pets R2: the ten Calamity pets (the rarest; a slain Calamity leaves its pet)
	box.add_child(UI.heading("Calamities"))
	box.add_child(UI.wrap("Mythic signature: " + PetAbilities.region_signature_text("calamity"), UI.FONT_BODY, Color(Menagerie.TIER_COLORS[PetAbilities.SIGNATURE_RANK])))
	var cflow := HFlowContainer.new()
	cflow.add_theme_constant_override("h_separation", 6)
	cflow.add_theme_constant_override("v_separation", 6)
	box.add_child(cflow)
	for n in _calamity_pets():
		cflow.add_child(_cell(n))

## The Calamity pets' species ids (calamity_N_pet), in Calamity order.
func _calamity_pets() -> Array:
	var out: Array = []
	for c in Calamity.LIST:
		out.append(Calamity.pet_id(c))
	return out

## Met: seen in the dungeon, or for a Calamity pet, that Calamity slain (its title earned).
func _met(n: String) -> bool:
	for c in Calamity.LIST:
		if Calamity.pet_id(c) == n:
			return codex.extra_titles.has(String(c[4]))
	return codex.seen(n)

func _name(n: String) -> String:
	for c in Calamity.LIST:
		if Calamity.pet_id(c) == n:
			return String(c[5])
	return Monsters.name_of(n)

func _cell(n: String) -> Control:
	var have := codex.pet_book.has(n)
	var met := have or _met(n)
	var tier := int(codex.pet_book.get(n, 0))
	var c := UI.panel(UI.INSET, Color(Menagerie.TIER_COLORS[tier]) if have else UI.BORDER, 4, 4, 2 if have else 1)
	c.custom_minimum_size = Vector2(76, 0)
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(v)
	# the pet's own baby art (art/pets/32) at about 2x in whole screen pixels (PixelPic); met-not-owned is its silhouette
	var pic := PixelPic.make(Menagerie.species_texture(n, String(Monsters.by_id(n).get("art", n))) if have else Pets.white(n))
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not have:
		pic.modulate = Color(0.32, 0.3, 0.4, 0.9) if met else Color(0.12, 0.12, 0.16, 0.6)
	v.add_child(pic)
	var l := UI.label(_name(n) if met else "???", UI.FONT_BODY, Color(Menagerie.TIER_COLORS[tier]) if have else UI.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(68, 0)
	v.add_child(l)
	if met:
		# phones have no hover: a tap opens the card with what this pet does
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.tooltip_text = "
".join(_lines(n, have, tier))
		c.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					c.set_meta("down", ev.global_position)
				elif c.has_meta("down") and ev.global_position.distance_to(c.get_meta("down")) < 12.0:
					_show(n, have, tier))   # a tap, not the end of a scroll
	return c

## What a met species does: its family, passive, and (when owned high enough) trick and signature.
func _lines(n: String, have: bool, tier: int) -> Array:
	var out: Array = [("Best owned: %s" % Menagerie.TIER_NAMES[tier]) if have else "Seen in the dungeon, never owned"]
	out.append("%s family. %s" % [PetAbilities.FAMILIES[PetAbilities.family(n)]["name"], PetAbilities.passive_text(n, tier if have else 0)])
	if have and tier >= PetAbilities.TRICK_RANK:
		out.append(PetAbilities.trick_text(n, tier))
	if have and tier >= PetAbilities.SIGNATURE_RANK:
		out.append(PetAbilities.signature_text(n))
	return out

func _show(n: String, have: bool, tier: int) -> void:
	var col := Color(Menagerie.TIER_COLORS[tier]) if have else UI.BORDER
	var o := Overlay.new().open(main, _name(n), 400.0, col)
	var pic := PixelPic.make(Menagerie.species_texture(n, String(Monsters.by_id(n).get("art", n))) if have else Pets.white(n), 0, ArtStyle.SCREEN_PX)  # like in a fight
	if not have:
		pic.modulate = Color(0.32, 0.3, 0.4, 0.9)
	o.content.add_child(pic)
	var ls := _lines(n, have, tier)
	for i in ls.size():
		o.content.add_child(UI.wrap(String(ls[i]), UI.FONT_BODY, col if i == 0 and have else UI.TEXT))
	if have and tier < PetAbilities.SIGNATURE_RANK:
		o.content.add_child(UI.wrap("A higher rank of this pet unlocks more (How pet abilities work, above).", UI.FONT_BODY, UI.DIM))

## Fable pets R3: one line here (the grid is the tab's point); the rank ladder and the
## families open in an Overlay.
func _abilities() -> void:
	var row := UI.hbox(8)
	box.add_child(row)
	var l := UI.wrap("How pet abilities work: by rank, and by family.", UI.FONT_BODY, UI.DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := UI.button("Read", func():
		var o := Overlay.new().open(main, "Pet abilities", 400.0, UI.GOLD_DULL)
		_ability_text(o.content))
	b.custom_minimum_size = Vector2(80, UI.TAP)
	row.add_child(b)

## 2.1: what pets can do by rank, and each family's passive and trick.
func _ability_text(to: Control) -> void:
	to.add_child(UI.heading("Abilities by rank"))
	for t in PetAbilities.RANK_TEXT.size():
		to.add_child(UI.wrap("%s: %s" % [Menagerie.TIER_NAMES[t], PetAbilities.RANK_TEXT[t]], UI.FONT_BODY, Color(Menagerie.TIER_COLORS[t])))
	to.add_child(UI.wrap("A pet's family is its kind of monster. Tap a pet in the Codex to see its own.", UI.FONT_BODY, UI.DIM))
	for f in PetAbilities.FAMILIES:
		to.add_child(UI.label(String(PetAbilities.FAMILIES[f]["name"]).to_upper(), UI.FONT_BODY, UI.GOLD))
		if f == "calamity":
			# Calamity pets only ever come at Mythic, so the rank ladder above doesn't apply
			to.add_child(UI.wrap("Calamity pets come only at Mythic. %s. %s. %s." % [PetAbilities.family_passive_range(f), PetAbilities.family_trick_text(f, PetAbilities.SIGNATURE_RANK), PetAbilities.region_signature_text("calamity")], UI.FONT_BODY, UI.TEXT))
			continue
		to.add_child(UI.wrap("Passive, %s" % PetAbilities.family_passive_range(f), UI.FONT_BODY, UI.TEXT))
		to.add_child(UI.wrap("Epic trick, %s" % PetAbilities.family_trick_text(f, PetAbilities.TRICK_RANK), UI.FONT_BODY, UI.TEXT))
