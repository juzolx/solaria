class_name UI
extends RefCounted
## Shared colors and building blocks, so every screen looks and feels the same.

const BG := Color("#0b1020")       # deep midnight
const PANEL := Color("#141b2e")    # panels
const BORDER := Color("#26324d")   # panel edges
const INSET := Color("#0f1526")    # boxes inside panels
const EMPTY := Color("#1f2940")    # empty / disabled edges
const TEXT := Color("#ece4d0")     # warm parchment text
const DIM := Color("#8590a8")      # secondary text
const GOLD := Color("#e8b14a")     # the accent color
const HILITE := Color("#1d2740")   # selected rows
const GREEN := Color("#4ade80")
const RED := Color("#f87171")
const BLUE := Color("#60a5fa")
const TEAL := Color("#2dd4bf")
const PINK := Color("#f472b6")
const PURPLE := Color("#a78bfa")

static var sfx: Sfx  # set by main, used for button clicks
static var tip_layer: CanvasLayer  # set by main: where tap-tips appear
static var _tip: Control
const TAP := 44  # smallest comfortable tap target on a phone (pixels at the design size)
const BUTTON_H := 36  # every button is at least this tall (the window scales up on phones)
const EDGE := Color("#64759b")  # edges of things you can press: 3:1 contrast or better
const MIN_FONT := 12
static var colorblind := false  # set from the settings: adds words and symbols where color carries meaning

static func hex(c: Color) -> String:
	return "#" + c.to_html(false)

static func style(bg: Color, border: Color, radius := 8, margin := 8, width := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb

static func label(text: String, font_size := 14, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(MIN_FONT, font_size))
	l.add_theme_color_override("font_color", color)
	return l

static func rich(font_size := 13, fit := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = fit
	r.add_theme_font_size_override("normal_font_size", maxi(MIN_FONT, font_size))
	r.add_theme_font_size_override("bold_font_size", maxi(MIN_FONT, font_size))
	return r

static func vbox(sep := 8) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

static func hbox(sep := 8) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func panel(bg := INSET, border := EMPTY, radius := 8, margin := 10, width := 2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, border, radius, margin, width))
	return p

## Small caps heading for a section.
static func heading(text: String) -> Label:
	var l := label(text.to_upper(), 12, DIM)
	return l

## A button that squishes and clicks when pressed, so every tap feels answered.
static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = BUTTON_H
	b.pressed.connect(on_press)
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.button_down.connect(func():
		if sfx:
			sfx.play("click")
		b.create_tween().tween_property(b, "scale", Vector2(0.94, 0.94), 0.06))
	b.button_up.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	return b

## A colored button for the main action on a screen.
static func primary(text: String, on_press: Callable, color := GOLD) -> Button:
	var b := button(text, on_press)
	b.add_theme_stylebox_override("normal", style(color.darkened(0.55), color, 6, 8))
	b.add_theme_stylebox_override("hover", style(color.darkened(0.4), color.lightened(0.2), 6, 8))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.25), color.lightened(0.3), 6, 8))
	b.add_theme_color_override("font_color", color.lightened(0.55))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	return b

static func bar(fill: Color, height := 8) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_stylebox_override("background", style(Color("#070a14"), BORDER, 4, 0, 1))
	b.add_theme_stylebox_override("fill", style(fill, fill, 4, 0, 0))
	return b

## A rounded "pill" holding a value, used in the top bar.
static func pill(text_color: Color) -> Array:
	var p := panel(Color("#0f1526"), Color(text_color, 0.35), 12, 0, 1)
	p.get_theme_stylebox("panel").content_margin_left = 12
	p.get_theme_stylebox("panel").content_margin_right = 12
	p.get_theme_stylebox("panel").content_margin_top = 4
	p.get_theme_stylebox("panel").content_margin_bottom = 4
	var l := label("", 15, text_color)
	p.add_child(l)
	return [p, l]

## Text colored green if you have enough, red if not: "7 / 3".
static func have_need(have: int, need: int) -> String:
	var c := GREEN if have >= need else RED
	return "[color=%s]%d[/color][color=%s] / %d[/color]" % [hex(c), have, hex(DIM), need]

## A label that wraps onto more lines instead of stretching the screen.
static func wrap(text: String, font_size := 13, color := TEXT) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

## A rounded card with a colored edge on the left. Returns [card, inner vbox].
static func card(accent := BORDER, bg := INSET, sep := 6) -> Array:
	var p := PanelContainer.new()
	var st := style(bg, Color(accent, 0.55), 10, 12, 1)
	st.border_width_left = 4
	st.border_color = accent
	p.add_theme_stylebox_override("panel", st)
	var v := vbox(sep)
	p.add_child(v)
	return [p, v]

## A section title with an optional one-line explanation under it.
static func section(parent: Control, title: String, note := "") -> void:
	var h := hbox(8)
	parent.add_child(h)
	var t := label(title.to_upper(), 13, GOLD)
	h.add_child(t)
	var line := ColorRect.new()
	line.color = Color(GOLD, 0.25)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	if note != "":
		parent.add_child(UI.wrap(note, 12, DIM))

## A small rounded tag ("SUGGESTED", "WEAK: Fire").
static func chip(text: String, color: Color, font_size := 11) -> PanelContainer:
	var p := panel(Color(color, 0.14), Color(color, 0.6), 9, 0, 1)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_child(label(text, font_size, color.lightened(0.25)))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p

## Explains something on hover (mouse) AND on tap (phones have no hover).
static func tip(c: Control, text: String) -> void:
	c.tooltip_text = text
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
	if c is BaseButton:
		return  # buttons do their job on tap; the hover text is enough
	c.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and DisplayServer.is_touchscreen_available()):
			show_tip(c, c.tooltip_text))

## Pops a small explanation next to a control; it fades by itself.
static func show_tip(near: Control, text: String) -> void:
	if tip_layer == null or text == "":
		return
	if is_instance_valid(_tip):
		_tip.queue_free()
	var p := panel(INSET, GOLD, 8, 10, 1)
	var r := rich(13)
	r.text = text
	r.custom_minimum_size = Vector2(260, 0)
	p.add_child(r)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_layer.add_child(p)
	_tip = p
	var vp := near.get_viewport_rect().size
	p.reset_size()
	await p.get_tree().process_frame
	if not is_instance_valid(p) or not is_instance_valid(near):
		return
	var at := near.get_global_rect()
	var pos := Vector2(at.position.x, at.end.y + 6)
	if pos.y + p.size.y > vp.y - 8:
		pos.y = at.position.y - p.size.y - 6
	pos.x = clampf(pos.x, 8, vp.x - p.size.x - 8)
	p.position = pos
	var tw := p.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)

## A big, phone-friendly button with a title and a small line under it.
static func big_button(title: String, sub: String, on_press: Callable, color := GOLD) -> Button:
	var b := button("", on_press)
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_stylebox_override("normal", style(Color(color, 0.12), Color(color, 0.7), 8, 8, 1))
	b.add_theme_stylebox_override("hover", style(Color(color, 0.2), color, 8, 8, 1))
	b.add_theme_stylebox_override("pressed", style(Color(color, 0.32), color.lightened(0.2), 8, 8, 2))
	var v := vbox(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := label(title, 15, color.lightened(0.4))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	if sub != "":
		var s := label(sub, 11, DIM)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.name = "Sub"
		v.add_child(s)
	t.name = "Title"
	return b

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", style(PANEL, BORDER, 10, 12))

	t.set_stylebox("normal", "Button", style(Color("#1b2438"), EDGE, 6, 6))
	t.set_stylebox("hover", "Button", style(Color("#232f49"), Color("#8a6d3b"), 6, 6))
	t.set_stylebox("pressed", "Button", style(Color("#8a6420"), GOLD, 6, 6))
	t.set_stylebox("disabled", "Button", style(Color("#111829"), Color("#1a2236"), 6, 6))
	var ring := style(Color(0, 0, 0, 0), Color("#f6d88f"), 7, 6, 2)
	ring.draw_center = false
	ring.expand_margin_left = 2
	ring.expand_margin_right = 2
	ring.expand_margin_top = 2
	ring.expand_margin_bottom = 2
	t.set_stylebox("focus", "Button", ring)
	t.set_stylebox("focus", "OptionButton", ring)
	t.set_stylebox("focus", "LineEdit", ring)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color("#f6d88f"))
	t.set_color("font_pressed_color", "Button", BG)
	t.set_color("font_disabled_color", "Button", Color("#4a5470"))

	t.set_stylebox("panel", "ItemList", style(INSET, EMPTY, 6, 4))
	t.set_stylebox("selected", "ItemList", style(HILITE, HILITE, 4, 2))
	t.set_stylebox("selected_focus", "ItemList", style(HILITE, Color("#8a6d3b"), 4, 2))
	t.set_stylebox("hovered", "ItemList", style(Color("#151d33"), Color("#151d33"), 4, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_color("guide_color", "ItemList", Color(1, 1, 1, 0.04))

	t.set_stylebox("panel", "TabContainer", style(PANEL, BORDER, 10, 12))
	var tab_on := style(PANEL, GOLD, 6, 8, 0)
	tab_on.border_width_top = 3
	t.set_stylebox("tab_selected", "TabContainer", tab_on)
	t.set_stylebox("tab_unselected", "TabContainer", style(BG, EDGE, 6, 8, 1))
	t.set_stylebox("tab_hovered", "TabContainer", style(Color("#111a2e"), Color("#8a6d3b"), 6, 8, 1))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font_size("font_size", "TabContainer", 15)

	# Sub-tabs (inside a main tab): flatter, with a gold underline
	t.add_type("SubTabs")
	t.set_type_variation("SubTabs", "TabContainer")
	t.set_stylebox("panel", "SubTabs", StyleBoxEmpty.new())
	var sub_on := style(Color(0, 0, 0, 0), GOLD, 0, 6, 0)
	sub_on.border_width_bottom = 2
	t.set_stylebox("tab_selected", "SubTabs", sub_on)
	t.set_stylebox("tab_unselected", "SubTabs", style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 0))
	t.set_stylebox("tab_hovered", "SubTabs", style(Color(0, 0, 0, 0), Color("#8a6d3b"), 0, 6, 0))
	t.set_font_size("font_size", "SubTabs", 13)
	t.set_color("font_selected_color", "SubTabs", TEXT)

	t.set_stylebox("normal", "OptionButton", style(Color("#1b2438"), EDGE, 6, 6))
	t.set_stylebox("hover", "OptionButton", style(Color("#232f49"), Color("#8a6d3b"), 6, 6))
	t.set_stylebox("panel", "PopupMenu", style(PANEL, BORDER, 6, 6))
	t.set_stylebox("grabber_area", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("slider", "HSlider", style(Color("#070a14"), EDGE, 3, 2, 1))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("panel", "TooltipPanel", style(INSET, GOLD, 6, 8))
	return t
