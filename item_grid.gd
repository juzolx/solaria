class_name ItemGrid
extends RefCounted
## Small square item pictures (the Vault, the Gear page): the item's icon on a
## frame in its rarity color. Empty squares show free space.

const CELL := 54

static func grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	return g

## As many columns as fit the width.
static func fit(grids: Array, width: float) -> void:
	var cols := maxi(4, int((width - 12.0) / float(CELL + 4)))
	for g in grids:
		if (g as GridContainer).columns != cols:
			(g as GridContainer).columns = cols

static func picture(px: int) -> TextureRect:
	var r := TextureRect.new()
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r

static func cell(item: Dictionary, on_press: Callable, selected := false, px := CELL, badge := "") -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(px, px)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var edge := UI.BORDER
	var bg := Color("#0e1322")
	if not item.is_empty():
		var rc := Color(GameData.color_of(int(item["rarity"])))
		edge = UI.GOLD if selected else rc
		bg = rc.darkened(0.82)
		b.icon = Sprites.item_icon(item)
		b.tooltip_text = ItemText.plain(item)
		if on_press.is_valid():
			b.pressed.connect(on_press)
	else:
		b.disabled = not on_press.is_valid()
		if on_press.is_valid():
			b.pressed.connect(on_press)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.style(bg.lightened(0.08) if st == "hover" else bg, edge, 6, 5, 3 if selected else (2 if not item.is_empty() else 1))
		b.add_theme_stylebox_override(st, sb)
	if badge != "":
		var l := UI.label(badge, 11, UI.GREEN)
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.position = Vector2(4, px - 20)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
	return b
