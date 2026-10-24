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
	var key := "%d|%d|%d|%s" % [codex.pet_book.size(), codex.bestiary.size(), codex.coll_earned.size(), str(codex.pet_book.values())]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var all := Monsters.all_monsters()
	var seen := 0
	for n in all:
		if codex.seen(n) or codex.pet_book.has(n):
			seen += 1
	var owned := 0
	for n in all:
		if codex.pet_book.has(n):
			owned += 1
	box.add_child(UI.label("Owned  %d / %d     Seen  %d / %d" % [owned, all.size(), seen, all.size()], 15, UI.GOLD))
	box.add_child(Collections.cards(codex, ["pets", "pet_epic", "pet_myth"]))  # 2.1 G4: progress and the next reward
	box.add_child(UI.wrap("Pets are a real find: hatch an egg, or tame a beast as a Beast Tamer. Tiers go from Common to Mythic.", UI.FONT_CAPTION, UI.DIM))
	var legend := UI.hbox(8)
	box.add_child(legend)
	for t in Menagerie.TIER_NAMES.size():
		legend.add_child(UI.label(Menagerie.TIER_NAMES[t], UI.FONT_CAPTION, Color(Menagerie.TIER_COLORS[t])))
	_abilities()
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var mons: Array = []
		for e in z["enemies"]:
			mons.append(e["id"])
		for s in z["subs"]:
			mons.append(s["monster"]["id"])
		box.add_child(UI.heading(str(z["name"])))
		box.add_child(UI.wrap("Mythic signature: " + PetAbilities.region_signature_text(String(z["id"])), UI.FONT_CAPTION, Color(Menagerie.TIER_COLORS[PetAbilities.SIGNATURE_RANK])))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		box.add_child(flow)
		for n in mons:
			flow.add_child(_cell(str(n)))

func _cell(n: String) -> Control:
	var have := codex.pet_book.has(n)
	var met := have or codex.seen(n)
	var tier := int(codex.pet_book.get(n, 0))
	var c := UI.panel(UI.INSET, Color(Menagerie.TIER_COLORS[tier]) if have else UI.BORDER, 4, 4, 2 if have else 1)
	c.custom_minimum_size = Vector2(76, 0)
	var v := UI.vbox(2)
	c.add_child(v)
	var pic := TextureRect.new()
	pic.texture = Sprites.enemy_by_key(String(Monsters.by_id(n).get("art", n))).get("tex", null)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not have:
		pic.modulate = Color(0.12, 0.12, 0.16, 0.9) if met else Color(0.05, 0.05, 0.07, 0.6)
	v.add_child(pic)
	var l := UI.label(Monsters.name_of(n) if met else "???", UI.FONT_CAPTION, Color(Menagerie.TIER_COLORS[tier]) if have else UI.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(68, 0)
	v.add_child(l)
	c.tooltip_text = ("Owned: best %s" % Menagerie.TIER_NAMES[tier]) if have else ("Seen in the dungeon, never owned" if met else "Not met yet")
	if met:
		c.tooltip_text += "\n%s family. %s" % [PetAbilities.FAMILIES[PetAbilities.family(n)]["name"], PetAbilities.passive_text(n, tier if have else 0)]
		if have and tier >= PetAbilities.TRICK_RANK:
			c.tooltip_text += "\n" + PetAbilities.trick_text(n, tier)
		if have and tier >= PetAbilities.SIGNATURE_RANK:
			c.tooltip_text += "\n" + PetAbilities.signature_text(n)
	return c

## 2.1: what pets can do by rank, and each family's passive and trick.
func _abilities() -> void:
	box.add_child(UI.heading("Abilities by rank"))
	for t in PetAbilities.RANK_TEXT.size():
		box.add_child(UI.wrap("%s: %s" % [Menagerie.TIER_NAMES[t], PetAbilities.RANK_TEXT[t]], UI.FONT_CAPTION, Color(Menagerie.TIER_COLORS[t])))
	box.add_child(UI.wrap("A pet's family is its kind of monster. Hold a pet below to see its own.", UI.FONT_CAPTION, UI.DIM))
	for f in PetAbilities.FAMILIES:
		box.add_child(UI.label(String(PetAbilities.FAMILIES[f]["name"]).to_upper(), UI.FONT_CAPTION, UI.GOLD))
		box.add_child(UI.wrap("Passive, %s" % PetAbilities.family_passive_range(f), UI.FONT_CAPTION, UI.TEXT))
		box.add_child(UI.wrap("Epic trick, %s" % PetAbilities.family_trick_text(f, PetAbilities.TRICK_RANK), UI.FONT_CAPTION, UI.TEXT))
