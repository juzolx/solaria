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
	row.add_child(_card(state, item, "THIS ITEM"))
	var slot: String = item["slot"]
	var worn: Dictionary = state.equipped.get(slot, {})
	var is_worn := not worn.is_empty() and int(worn["id"]) == int(item["id"])
	if not is_worn:
		if worn.is_empty():
			var empty := UI.panel(UI.INSET, UI.BORDER, 8, 12, 1)
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var el := UI.label("You're not wearing anything in this slot.", UI.FONT_CAPTION, UI.DIM)
			el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			empty.add_child(el)
			row.add_child(empty)
		else:
			row.add_child(_card(state, worn, "WEARING NOW"))
	var cmp := UI.rich(UI.FONT_CAPTION)
	cmp.text = "[color=%s]You're wearing this.[/color]" % UI.hex(UI.DIM) if is_worn else ItemText.compare(state, item)
	content.add_child(cmp)
	if not actions.is_empty():
		var buttons := UI.hbox(8)
		content.add_child(buttons)
		for a in actions:
			var color: Color = a[2] if a.size() > 2 and a[2] != null else UI.GOLD
			var cb: Callable = a[1]
			var b := UI.primary(str(a[0]), func(): close(); cb.call(), color)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 40)
			if size.x < 600.0:
				b.add_theme_font_size_override("font_size", UI.FONT_CAPTION)
			buttons.add_child(b)

func _card(state: GameState, item: Dictionary, label: String) -> PanelContainer:
	var r := int(item["rarity"])
	var card := UI.panel(UI.INSET, Color(GameData.color_of(r)).darkened(0.2), 8, 12, 2)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	card.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	var pic := TextureRect.new()
	pic.texture = Sprites.item_icon(item)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var narrow := size.x < 600.0  # phones: two slim columns, still side by side
	pic.custom_minimum_size = Vector2(32, 32) if narrow else Vector2(48, 48)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	head.add_child(UI.label(label, UI.FONT_CAPTION, UI.DIM))
	var t := UI.rich(UI.FONT_CAPTION)
	if narrow:
		t.add_theme_font_size_override("normal_font_size", UI.FONT_CAPTION)
		t.add_theme_font_size_override("bold_font_size", UI.FONT_CAPTION)
		t.add_theme_font_size_override("italics_font_size", UI.FONT_CAPTION)
	t.custom_minimum_size = Vector2(0 if narrow else 300, 0)
	t.text = ItemText.describe(state, item)
	v.add_child(t)
	return card
