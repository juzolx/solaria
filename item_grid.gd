class_name ItemGrid
extends RefCounted
## Small square item pictures (the Bag, the Vault, the Gear page): the item's icon on a
## frame in its rarity color. Empty squares show free space.
## Interface pass (approved mockup 07): an ink cell, a 1 px rarity edge and a rarity strip
## along the bottom, a gold frame when picked; the icon at whole pixels (2x when it fits).

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
	b.expand_icon = false   # whole pixels: the icon is already sized to the cell (UiIcons.big)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var edge := UI.EMPTY
	var bg := UI.INSET
	if not item.is_empty():
		var rc := Color(GameData.color_of(int(item["rarity"])))
		edge = UI.GOLD if selected else rc
		if Church.is_cursed(item) and not selected:  # 2.1: cursed gear stands out
			edge = Color(Church.COLOR)
			badge = "CURSED" if badge == "" else badge
		b.icon = UiIcons.big(Sprites.item_icon(item), px - 10)
		b.tooltip_text = ItemText.plain(item)
		if on_press.is_valid():
			b.pressed.connect(on_press)
	else:
		b.disabled = not on_press.is_valid()
		if on_press.is_valid():
			b.pressed.connect(on_press)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.style(UiSkin.SLATE if st == "hover" else bg, edge, 6, 5, 2 if selected else 1)
		if not item.is_empty() and not selected:
			sb.border_width_bottom = 4   # the rarity strip
		b.add_theme_stylebox_override(st, sb)
	# Fable r1 #8: a badge is a 3x3 stud in the top-right corner (green better, red over the
	# bag's limit, gold locked or picked, violet cursed); the numbers live in the detail box.
	# Only the Wheel's odds stay as text (a caption, the one place 15 px is allowed).
	var stud := {"OVER": UI.RED, "LOCK": UI.GOLD, "PICK": UI.GOLD, "ON": UI.TEXT, "BEST": UI.GREEN,
		"CURSED": Color(Church.COLOR).lightened(0.25)}
	var sc: Variant = stud.get(badge, UI.GREEN if badge.begins_with("+") else null)
	if sc != null:
		var dot := Control.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size = Vector2(10, 10)
		dot.position = Vector2(px - 15, 5)
		dot.draw.connect(func():
			dot.draw_rect(Rect2(0, 0, 10, 10), UiSkin.SOOT)
			dot.draw_rect(Rect2(2, 2, 6, 6), sc))
		dot.tooltip_text = badge
		b.add_child(dot)
	elif badge != "":
		var l := UI.label(badge, UI.FONT_CAPTION, UI.GREEN)
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.position = Vector2(4, px - 20)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
	return b
