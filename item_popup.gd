class_name ItemPopup
extends Overlay
## Tap any item to see it side by side with what you're wearing in that slot,
## how your stats change, and buttons for what you can do with it.

## actions: [[button text, Callable, color or null], ...]
static func show_item(main_node, item: Dictionary, actions: Array = []) -> ItemPopup:
	var p := ItemPopup.new()
	p._build(main_node, item, actions)
	return p

func _build(m, item: Dictionary, actions: Array) -> void:
	var state: GameState = m.state
	open(m, GameData.display_name(item), 760.0, Color(GameData.color_of(int(item["rarity"]))))
	# UX pass: phones stack the two cards (side by side, 15 px text left ~200 px a column)
	var row: BoxContainer = UI.vbox(8) if size.x < 600.0 else UI.hbox(12)
	content.add_child(row)
	# Fable r1 #14: no caption on this item (the popup title is its name); "Wearing now" only
	# when there is one; one Now / With compare row; the buttons at TAP under the scroll
	row.add_child(_card(state, item, ""))
	var slot: String = item["slot"]
	var worn: Dictionary = state.equipped.get(slot, {})
	var is_worn := not worn.is_empty() and int(worn["id"]) == int(item["id"])
	if not is_worn and not worn.is_empty():
		row.add_child(_card(state, worn, "Wearing now"))
	if is_worn:
		content.add_child(UI.label("You're wearing this.", UI.FONT_BODY, UI.DIM))
	else:
		content.add_child(_compare(state, item))
	if not actions.is_empty():
		foot.visible = true
		var grid := GridContainer.new()   # up to three across; more go two by two (Fable r2 #4)
		grid.columns = actions.size() if actions.size() <= 3 else 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		foot.add_child(grid)
		for a in actions:
			var color: Color = a[2] if a.size() > 2 and a[2] != null else UI.GOLD
			var cb: Callable = a[1]
			var b := UI.primary(str(a[0]), func(): close(); cb.call(), color)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, UI.TAP)
			b.clip_text = true
			grid.add_child(b)

## "Defense   24   68 (+44)" under Now / With, and the overall change of your build.
func _compare(state: GameState, item: Dictionary) -> Control:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 4)
	var total := int(state.stat_value(item["stat"]))
	var with_v := int(state.stat_if_equipped(item))
	var diff := with_v - total
	var overall := state.score_with(item) / maxf(1.0, state.build_score()) - 1.0
	var pct := int(round(overall * 100))
	var good := UI.GREEN if diff >= 0 else UI.RED
	for cell in [["", UI.DIM], ["Now", UI.DIM], ["With", UI.DIM],
			[String(item["stat"]), UI.TEXT], [str(total), UI.TEXT], ["%d (%s%d)" % [with_v, "+" if diff >= 0 else "", diff], good],
			["Overall", UI.TEXT], ["", UI.TEXT], ["%s%d%%" % ["+" if pct >= 0 else "", pct], UI.GREEN if pct > 0 else (UI.RED if pct < 0 else UI.DIM)]]:
		g.add_child(UI.label(String(cell[0]), UI.FONT_BODY, cell[1]))
	return g

func _card(state: GameState, item: Dictionary, label: String) -> PanelContainer:
	var r := int(item["rarity"])
	var card := PanelContainer.new()   # interface pass: the panel frame, its line in the rarity colour
	card.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, Color(GameData.color_of(r)), 12))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	card.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	var narrow := size.x < 600.0  # phones: two slim columns, still side by side
	# the item big, at whole pixels, in a slot with its rarity strip
	var slot := ItemGrid.cell(item, Callable(), false, 64)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(slot)
	if label != "":
		head.add_child(UI.label(label, UI.FONT_BODY, UI.DIM))
	var t := UI.rich(UI.FONT_BODY)
	if narrow:
		t.add_theme_font_size_override("normal_font_size", UI.FONT_BODY)
		t.add_theme_font_size_override("bold_font_size", UI.FONT_BODY)
		t.add_theme_font_size_override("italics_font_size", UI.FONT_BODY)
	t.custom_minimum_size = Vector2(0 if narrow else 300, 0)
	t.text = ItemText.describe(state, item)
	v.add_child(t)
	return card
