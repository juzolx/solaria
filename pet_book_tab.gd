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
	var key := "%d|%d" % [codex.pet_book.size(), codex.bestiary.size()]
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
	box.add_child(UI.wrap("Pets are a real find: hatch an egg, or tame a beast as a Beast Tamer. Tiers go from Common to Mythic.", 12, UI.DIM))
	var legend := UI.hbox(8)
	box.add_child(legend)
	for t in Menagerie.TIER_NAMES.size():
		legend.add_child(UI.label(Menagerie.TIER_NAMES[t], 11, Color(Menagerie.TIER_COLORS[t])))
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var mons: Array = []
		for e in z["enemies"]:
			mons.append(e["name"])
		for s in z["subs"]:
			mons.append(s["monster"]["name"])
		box.add_child(UI.heading(str(z["name"])))
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
	pic.texture = Sprites.enemy_by_key(Sprites.enemy_key(n, false)).get("tex", null)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not have:
		pic.modulate = Color(0.12, 0.12, 0.16, 0.9) if met else Color(0.05, 0.05, 0.07, 0.6)
	v.add_child(pic)
	var l := UI.label(n if met else "???", 10, Color(Menagerie.TIER_COLORS[tier]) if have else UI.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(68, 0)
	v.add_child(l)
	c.tooltip_text = ("Owned: best %s" % Menagerie.TIER_NAMES[tier]) if have else ("Seen in the dungeon, never owned" if met else "Not met yet")
	return c
