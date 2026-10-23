class_name CollectionTab
extends ScrollContainer
## Codex > Collection: your trophy shelf. Every Unique and Signature item in
## the game; the ones you haven't found yet are shadows.

var main
var codex: Codex
var box: VBoxContainer
var shown := -1

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Collection"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	if shown == codex.collection.size():
		return
	shown = codex.collection.size()
	OnlineUI.clear(box)
	box.add_child(UI.label("Uniques  %d / 15     Signatures  %d / %d" % [codex.value("uniques"), codex.value("signatures"), Monsters.all_monsters().size()], 15, UI.GOLD))
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		box.add_child(UI.heading(str(z["name"])))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		box.add_child(flow)
		for u in GameData.zone_uniques(zi):
			var item := GameData.make_unique(u, 1, 0)
			var boss: Dictionary = z["mid"] if u in z["mid"]["uniques"] else z["boss"]
			flow.add_child(_trophy(item, codex.collection.has(u["id"]), "Unique from " + String(boss["name"]) if codex.seen(boss["id"]) else "A Unique from a boss"))
		var mons: Array = []
		for e in z["enemies"]:
			mons.append(e["id"])
		for s in z["subs"]:
			mons.append(s["monster"]["id"])
		for mid in mons:
			var item := GameData.make_signature(mid, 1, 0)
			var have := bool(codex.bestiary.get(mid, {}).get("sig", false))
			flow.add_child(_trophy(item, have, ("Signature of the " + Monsters.name_of(mid)) if codex.seen(mid) else "A monster's Signature"))

func _trophy(item: Dictionary, have: bool, source: String) -> PanelContainer:
	var r := int(item["rarity"])
	var c := Color(GameData.color_of(r))
	var card := UI.panel(UI.INSET, c.darkened(0.2) if have else UI.BORDER, 6, 6, 2 if have else 1)
	card.custom_minimum_size = Vector2(150, 0)
	var v := UI.vbox(2)
	card.add_child(v)
	var pic := TextureRect.new()
	pic.texture = Sprites.item_icon(item)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(40, 40)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not have:
		pic.modulate = Color(0, 0, 0, 0.55)
	v.add_child(pic)
	var n := UI.label(item["name"] if have else "???", 11, c if have else UI.DIM)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	var s := UI.label(source, 9, UI.DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	if have:
		card.tooltip_text = ItemText.plain(item) + "\nFound " + str(codex.collection.get(item["name"], ""))
	return card
