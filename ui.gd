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
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

static func rich(font_size := 13, fit := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = fit
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_font_size_override("bold_font_size", font_size)
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

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", style(PANEL, BORDER, 10, 12))

	t.set_stylebox("normal", "Button", style(Color("#1b2438"), Color("#2e3b58"), 6, 6))
	t.set_stylebox("hover", "Button", style(Color("#232f49"), Color("#8a6d3b"), 6, 6))
	t.set_stylebox("pressed", "Button", style(Color("#8a6420"), GOLD, 6, 6))
	t.set_stylebox("disabled", "Button", style(Color("#111829"), Color("#1a2236"), 6, 6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
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
	t.set_stylebox("tab_unselected", "TabContainer", style(BG, EMPTY, 6, 8, 1))
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

	t.set_stylebox("normal", "OptionButton", style(Color("#1b2438"), Color("#2e3b58"), 6, 6))
	t.set_stylebox("hover", "OptionButton", style(Color("#232f49"), Color("#8a6d3b"), 6, 6))
	t.set_stylebox("panel", "PopupMenu", style(PANEL, BORDER, 6, 6))
	t.set_stylebox("grabber_area", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("slider", "HSlider", style(Color("#070a14"), BORDER, 3, 2, 1))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("panel", "TooltipPanel", style(INSET, GOLD, 6, 8))
	return t
