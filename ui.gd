class_name UI
extends RefCounted
## Shared colors and building blocks, so every screen looks and feels the same.
##
## THE DESIGN SYSTEM (UX pass, Oct 24 2026; see claude/ui-review.md). Keep to it:
## - Palette: ink + iron/stone greys + bone text, ONE accent (GOLD) for "this
##   matters / tap here", and ONE state family: GOOD (green) and BAD (red), with
##   GOLD doubling as "suggested". Rarity colours are for ITEMS only (item
##   frames, item names). BLUE/TEAL/PINK/PURPLE are legacy: elements, rarity
##   and tags only, never for buttons, cards or frames.
## - Buttons, by role: primary() = the gold main action on a screen; danger() =
##   red, for diving, attacking and anything you cannot undo; everything else is
##   a plain stone button (the theme).
## - Type scale (design px at the 504-wide phone layout): CAPTION 15 (smallest
##   allowed), BODY 16, TITLE 20, DISPLAY 26. Nothing below MIN_FONT.
## - Spacing: 4 / 8 / 12 / 16 (SP_XS..SP_L). Touch targets >= TAP (44).
## - Frames: iron frame (UiSkin.frame) for panels and popups; cards are inset
##   stone with a 1 px iron edge, a gold edge when selected or suggested.
## - Icons: chunky filled pixel shapes with a 1 px near-black outline
##   (UiSkin.SOOT), tinted by state; never thin strokes, never smoothed.

const BG := Color("#0b0a1d")       # catacomb ink (next update: the Art Direction palette)
const PANEL := Color("#15142a")    # panels: indigo slate
const BORDER := Color("#2e2d48")   # panel edges
const INSET := Color("#0f0e20")    # boxes inside panels
const EMPTY := Color("#25243c")    # empty / disabled edges
const TEXT := Color("#e2dac6")     # bone text, never white
const DIM := Color("#a89d84")      # dust: secondary text
const GOLD := Color("#e8b14a")     # the accent color
const HILITE := Color("#24213c")   # selected rows
const GREEN := Color("#4ade80")
const RED := Color("#f87171")
const BLUE := Color("#60a5fa")
const TEAL := Color("#2dd4bf")
const PINK := Color("#f472b6")
const PURPLE := Color("#a78bfa")
const GOOD := GREEN   # state family: success, "you can afford it", upgrades
const BAD := RED      # state family: danger, damage, "not enough"
const GOLD_DEEP := Color("#8a6420")  # pressed / filled gold
const CARD_EDGE := Color("#3d3b58")  # the 1 px iron edge of a card
# Type scale (design px)
const FONT_CAPTION := 15
const FONT_BODY := 16
const FONT_TITLE := 20
const FONT_DISPLAY := 26
# Spacing
const SP_XS := 4
const SP_S := 8
const SP_M := 12
const SP_L := 16

static var sfx: Sfx  # set by main, used for button clicks
static var tip_layer: CanvasLayer  # set by main: where tap-tips appear
static var _tip: Control
const TAP := 44  # smallest comfortable tap target on a phone (pixels at the design size)
const BUTTON_H := 42  # every button is at least this tall (~36 pt on a phone; Apple asks for 44 pt on main controls)
const EDGE := Color("#7a7493")  # edges of things you can press: 3:1 contrast or better
const MIN_FONT := FONT_CAPTION  # UX pass: 15 design px (~13 pt on a 430 pt wide phone); was 13
static var colorblind := false  # set from the settings: adds words and symbols where color carries meaning
static var high_contrast := false  # set from the settings: secondary (DIM) text is drawn brighter
static var calm := false  # set from the settings (Reduce motion): no page fades
const DIM_CONTRAST := Color("#c3cbdc")  # DIM in high-contrast mode

## 9680 -> "9680", 12400 -> "12.4k", 3500000 -> "3.5M": short numbers for tight spots.
static func short(n: int) -> String:
	if absi(n) < 10000:
		return str(n)
	if absi(n) < 1000000:
		return "%.1fk" % (n / 1000.0)
	return "%.1fM" % (n / 1000000.0)

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

static func label(text: String, font_size := FONT_CAPTION, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(MIN_FONT, font_size))
	l.add_theme_color_override("font_color", DIM_CONTRAST if high_contrast and color == DIM else color)
	return l

static func rich(font_size := FONT_CAPTION, fit := true) -> RichTextLabel:
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
	var l := label("◆ " + text.to_upper(), FONT_CAPTION, Color("#c9a36a"))  # next update: a small gold diamond, like a bestiary page
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # long headings wrap instead of widening the screen
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
	color = role_color(color)
	var b := button(text, on_press)
	b.add_theme_stylebox_override("normal", UiSkin.bevel(color.darkened(0.55), color, 8))
	b.add_theme_stylebox_override("hover", UiSkin.bevel(color.darkened(0.4), color.lightened(0.2), 8))
	b.add_theme_stylebox_override("pressed", UiSkin.bevel(color.darkened(0.25), color.lightened(0.3), 8, true))
	b.add_theme_color_override("font_color", color.lightened(0.55))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	return b

## The red button: going down, attacking, and anything you cannot undo.
static func danger(text: String, on_press: Callable) -> Button:
	return primary(text, on_press, BAD)

## Design system: a main-action colour folds into its role. Green, teal, blue,
## pink and purple buttons all become the one gold accent; red stays red
## (danger); other colours (a building's own, a dim BORDER) are kept.
## Note: GOOD is GREEN, so a "good" main button turns gold too. Meaning that a
## colour used to carry must live in the button's words ("Found town", "Collect").
static func role_color(c: Color) -> Color:
	for legacy in [GREEN, TEAL, BLUE, PINK, PURPLE]:
		if c.is_equal_approx(legacy):
			return GOLD
	return c

static func bar(fill: Color, height := 8) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_stylebox_override("background", style(Color("#070a14"), BORDER, 4, 0, 1))
	b.add_theme_stylebox_override("fill", style(fill, fill, 4, 0, 0))
	return b

## A rounded "pill" holding a value, used in the top bar.
static func pill(text_color: Color, font_size := FONT_CAPTION) -> Array:
	var p := panel(Color("#0f1526"), Color(text_color, 0.35), 12, 0, 1)
	p.get_theme_stylebox("panel").content_margin_left = 12
	p.get_theme_stylebox("panel").content_margin_right = 12
	p.get_theme_stylebox("panel").content_margin_top = 4
	p.get_theme_stylebox("panel").content_margin_bottom = 4
	var l := label("", font_size, text_color)
	p.add_child(l)
	return [p, l]

## Text colored green if you have enough, red if not: "7 / 3".
static func have_need(have: int, need: int) -> String:
	var c := GREEN if have >= need else RED
	return "[color=%s]%d[/color][color=%s] / %d[/color]" % [hex(c), have, hex(DIM), need]

## A label that wraps onto more lines instead of stretching the screen.
static func wrap(text: String, font_size := FONT_CAPTION, color := TEXT) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

## A rounded card with a colored edge on the left. Returns [card, inner vbox].
static func card(accent := BORDER, bg := INSET, sep := 6) -> Array:
	var p := PanelContainer.new()
	var st := style(bg, Color(accent, 0.55), 6, 12, 1)
	st.border_width_left = 4
	st.border_color = accent
	if accent == BORDER or accent == CARD_EDGE:
		st.border_width_left = 1   # design system: plain cards have one quiet iron edge
		st.border_color = CARD_EDGE
	p.add_theme_stylebox_override("panel", st)
	var v := vbox(sep)
	p.add_child(v)
	return [p, v]

## A section title with an optional one-line explanation under it.
static func section(parent: Control, title: String, note := "") -> void:
	var h := hbox(8)
	parent.add_child(h)
	var t := label(title.to_upper(), FONT_CAPTION, GOLD)
	h.add_child(t)
	var line := ColorRect.new()
	line.color = Color(GOLD, 0.25)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	if note != "":
		parent.add_child(UI.wrap(note, FONT_CAPTION, DIM))

## A small rounded tag ("SUGGESTED", "WEAK: Fire").
static func chip(text: String, color: Color, font_size := FONT_CAPTION) -> PanelContainer:
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
	color = role_color(color)
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
	t.default_font_size = FONT_BODY
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", UiSkin.frame(PANEL, UiSkin.IRON, 12))  # next update: iron frames on stone

	t.set_stylebox("normal", "Button", UiSkin.bevel(Color("#211f36"), EDGE, 6))  # stone buttons
	t.set_stylebox("hover", "Button", UiSkin.bevel(Color("#2b2843"), Color("#b08a4a"), 6))
	t.set_stylebox("pressed", "Button", UiSkin.bevel(Color("#8a6420"), GOLD, 6, true))
	t.set_stylebox("disabled", "Button", UiSkin.bevel(Color("#13121f"), Color("#2a2840"), 6))
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
	t.set_color("font_disabled_color", "Button", Color("#5a5670"))

	t.set_stylebox("panel", "ItemList", style(INSET, EMPTY, 6, 4))
	t.set_stylebox("selected", "ItemList", style(HILITE, HILITE, 4, 2))
	t.set_stylebox("selected_focus", "ItemList", style(HILITE, Color("#8a6d3b"), 4, 2))
	t.set_stylebox("hovered", "ItemList", style(Color("#151d33"), Color("#151d33"), 4, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_color("guide_color", "ItemList", Color(1, 1, 1, 0.04))

	t.set_stylebox("panel", "TabContainer", UiSkin.frame(Color(PANEL, 0.84), UiSkin.IRON, 12))  # see-through: the torchlit wall shows behind
	var tab_on := style(PANEL, GOLD, 6, 8, 0)
	tab_on.border_width_top = 3
	t.set_stylebox("tab_selected", "TabContainer", tab_on)
	t.set_stylebox("tab_unselected", "TabContainer", style(BG, EDGE, 6, 8, 1))
	t.set_stylebox("tab_hovered", "TabContainer", style(Color("#111a2e"), Color("#8a6d3b"), 6, 8, 1))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font_size("font_size", "TabContainer", FONT_BODY)
	t.set_font_size("font_size", "Button", FONT_CAPTION)
	t.set_font_size("font_size", "OptionButton", FONT_CAPTION)
	t.set_font_size("font_size", "ItemList", FONT_CAPTION)

	# Sub-tabs (inside a main tab): flatter, with a gold underline
	t.add_type("SubTabs")
	t.set_type_variation("SubTabs", "TabContainer")
	t.set_stylebox("panel", "SubTabs", StyleBoxEmpty.new())
	var sub_on := style(Color(0, 0, 0, 0), GOLD, 0, 6, 0)
	sub_on.border_width_bottom = 2
	t.set_stylebox("tab_selected", "SubTabs", sub_on)
	t.set_stylebox("tab_unselected", "SubTabs", style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 0))
	t.set_stylebox("tab_hovered", "SubTabs", style(Color(0, 0, 0, 0), Color("#8a6d3b"), 0, 6, 0))
	t.set_font_size("font_size", "SubTabs", FONT_CAPTION)
	for st_name in ["tab_selected", "tab_unselected", "tab_hovered"]:   # UX pass: sub-tabs are a full 44 px tap target
		var sb := t.get_stylebox(st_name, "SubTabs").duplicate() as StyleBox
		sb.content_margin_top = 13
		sb.content_margin_bottom = 13
		t.set_stylebox(st_name, "SubTabs", sb)
	t.set_color("font_selected_color", "SubTabs", TEXT)

	t.set_stylebox("normal", "OptionButton", UiSkin.bevel(Color("#211f36"), EDGE, 6))
	t.set_stylebox("hover", "OptionButton", UiSkin.bevel(Color("#2b2843"), Color("#b08a4a"), 6))
	t.set_stylebox("panel", "PopupMenu", style(PANEL, BORDER, 6, 6))
	t.set_stylebox("grabber_area", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("slider", "HSlider", style(Color("#070a14"), EDGE, 3, 2, 1))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("panel", "TooltipPanel", style(INSET, GOLD, 6, 8))
	return t

## Next update: a quick fade when a page opens (none with Reduce motion).
static func fade_in(c: CanvasItem) -> void:
	if c == null or calm or not c.is_inside_tree():
		return
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 1.0, 0.16)
