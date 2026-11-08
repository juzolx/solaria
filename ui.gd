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
## - Interface pass (Oct 24 2026, claude/research/ui-research.md): every colour
##   below comes from art/palette.gpl; corners are square pixels (no rounding);
##   text is Pixelify Sans (OFL, the Art Direction's font); frames and buttons
##   are drawn on the same 2x pixel grid as the sprites (UiSkin.PX).

const BG := Color("#0e0812")       # the outline ink of the sprites
const PANEL := Color("#181425")    # panels: catacomb ink
const BORDER := Color("#3a4466")   # panel edges: slate
const INSET := Color("#120e1c")    # boxes inside panels (ink, a step darker)
const EMPTY := Color("#262b44")    # empty / disabled edges
const TEXT := Color("#ead4aa")     # bone text, never white
const DIM := Color("#8b9bb4")      # dust slate: secondary text
const GOLD := Color("#feae34")     # the accent color
const HILITE := Color("#262b44")   # selected rows
const GREEN := Color("#63c74d")
const RED := Color("#f6757a")
const BLUE := Color("#60a5fa")
const TEAL := Color("#2dd4bf")
const PINK := Color("#f472b6")
const PURPLE := Color("#a78bfa")
const GOOD := GREEN   # state family: success, "you can afford it", upgrades
const BAD := RED      # state family: danger, damage, "not enough"
const GOLD_DEEP := Color("#9a7040")  # pressed / filled gold (palette dull gold)
const GOLD_DULL := Color("#c8a060")  # frames of selected things
const CARD_EDGE := Color("#3a4466")  # the 1 px slate edge of a card
# Type scale (design px). Fable round 1: Pixelify Sans draws one font pixel per size/10, so
# only 20 / 30 / 40 sit on the 2x art grid. Body 20 = 17 pt on a 430 pt phone, 14.9 pt on 375.
# Caption 15 is for badges, chips and the captions under icons only.
const FONT_CAPTION := 15
const FONT_BODY := 20
const FONT_TITLE := 30
const FONT_DISPLAY := 40
# Spacing
const SP_XS := 4
const SP_S := 8
const SP_M := 12
const SP_L := 16

static var sfx: Sfx  # set by main, used for button clicks
static var tip_layer: CanvasLayer  # set by main: where tap-tips appear
static var force_touch := false   # tests: a mouse click acts as a finger tap (ui_tour --touch)
static var _tip: Control
# Fable r1 #2: the phone layout is 504 design px on a 375-430 pt screen, so 44 pt = 52-59 design px.
# Fable r2: 44 pt on a 375 pt phone (iPhone SE) is 44 / 0.744 = 59 design px, so TAP is 60.
const TAP := 60  # main actions, Close, nav, toggles: 44.6 pt on an SE, 51 pt on a 430 pt phone
const BUTTON_H := 56  # every other button: 41.7 pt on an SE (the floor where a screen is tight), 47.8 pt at 430
const EDGE := Color("#5a6988")  # edges of things you can press: 3:1 contrast or better
const MIN_FONT := FONT_CAPTION  # UX pass: 15 design px (~13 pt on a 430 pt wide phone); was 13
static var colorblind := false  # set from the settings: adds words and symbols where color carries meaning
static var high_contrast := false  # set from the settings: secondary (DIM) text is drawn brighter
static var calm := false  # set from the settings (Reduce motion): no page fades
const DIM_CONTRAST := Color("#c0cbdc")  # DIM in high-contrast mode

## 9680 -> "9680", 12400 -> "12.4k", 3500000 -> "3.5M", 2.1e9 -> "2.1B": short numbers for tight spots.
static func short(n: int) -> String:
	if absi(n) < 10000:
		return str(n)
	if absi(n) < 1000000:
		return "%.1fk" % (n / 1000.0)
	if absi(n) < 1000000000:
		return "%.1fM" % (n / 1000000.0)
	return "%.1fB" % (n / 1000000000.0)  # QA r2 #39 (was "1234.5M")

## Fable r3 #9: every button that spends says it one way: "Buy · 1,899 gold", "Build · 12.4k gold
## + 60 scrap". Never "g", never brackets.
static func cost(verb: String, gold: int, extra := "") -> String:
	var g := short(gold) if absi(gold) >= 10000 else _commas(gold)
	return "%s · %s gold%s" % [verb, g, (" + " + extra) if extra != "" else ""]

static func _commas(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

static func hex(c: Color) -> String:
	return "#" + c.to_html(false)

static func style(bg: Color, border: Color, radius := 8, margin := 8, width := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(0 if radius < 99 else radius)  # pixel art: square corners (radius kept in calls for old code)
	sb.anti_aliasing = false
	sb.set_content_margin_all(margin)
	return sb

static func label(text: String, font_size := FONT_BODY, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(MIN_FONT, font_size))
	l.add_theme_color_override("font_color", DIM_CONTRAST if high_contrast and color == DIM else color)
	return l

static func rich(font_size := FONT_BODY, fit := true) -> RichTextLabel:
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

## The one section heading (Fable r1 #5): a cut-corner slate plate with the title in gold
## (a few words), and an optional sentence-case note in DIM under it.
static func heading(text: String, note := "") -> Control:
	if note == "" and text.contains("  -  "):   # "Title  -  a note" (older calls): the note goes under the plate
		note = text.get_slice("  -  ", 1)
		note = note.left(1).to_upper() + note.substr(1) + ("" if note.ends_with(".") else ".")
		text = text.get_slice("  -  ", 0)
	var v := vbox(4)
	v.set_meta("heading", text)
	# Fable r3 #2: a heading is never raised (a bevel is the game's "press me"): gold words on a
	# flat 2 px rule across the row, so "Active" or "Help" can't be mistaken for a chip
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", _heading_rule())
	plate.size_flags_horizontal = Control.SIZE_FILL
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(plate)
	var l := label(text, FONT_BODY, GOLD)
	if text.length() > 24:   # a long title wraps across the row (short ones keep their width in a row of buttons)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plate.add_child(l)
	if note != "":
		v.add_child(UI.wrap(note, FONT_BODY, DIM))   # UI.: a bare wrap() is Godot's number wrap
	return v

static var _rule: StyleBoxFlat
static func _heading_rule() -> StyleBoxFlat:
	if _rule == null:
		_rule = StyleBoxFlat.new()
		_rule.bg_color = Color(0, 0, 0, 0)
		_rule.border_color = GOLD_DULL
		_rule.border_width_bottom = 2
		_rule.content_margin_left = 0
		_rule.content_margin_right = 0
		_rule.content_margin_top = 4
		_rule.content_margin_bottom = 4
	return _rule

## The title label inside a heading (for counts that change: "Vault · 3 / 20").
static func heading_label(h: Control) -> Label:
	return h.get_child(0).get_child(0) as Label

## Fable r1 #6: sub-tabs as a wrapping row of slate chips (two rows on a phone) instead of a
## clipped TabBar with 12 px scroll arrows, so every page is visible. Returns a holder (the
## chips over the container; it takes the container's name) to add where the container went;
## call sync_tabs after adding pages or changing a title. (A child of the TabContainer itself,
## even an internal one, would count as a page.)
static func wrap_tabs(t: TabContainer) -> VBoxContainer:
	t.tabs_visible = false
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var holder := vbox(8)
	holder.name = t.name
	var strip := HFlowContainer.new()
	strip.add_theme_constant_override("h_separation", 6)
	strip.add_theme_constant_override("v_separation", 6)
	holder.add_child(strip)
	holder.add_child(t)
	t.set_meta("strip", strip)
	t.tab_changed.connect(func(_i): sync_tabs(t))
	return holder

static func sync_tabs(t: TabContainer) -> void:
	if not t.has_meta("strip"):
		return
	var strip: HFlowContainer = t.get_meta("strip")
	while strip.get_child_count() < t.get_tab_count():
		var i := strip.get_child_count()
		var b := button("", func(): t.current_tab = i)
		b.custom_minimum_size = Vector2(0, BUTTON_H)
		b.focus_mode = Control.FOCUS_NONE
		strip.add_child(b)
	for i in strip.get_child_count():
		var b := strip.get_child(i) as Button
		if i >= t.get_tab_count():
			b.visible = false
			continue
		b.text = t.get_tab_title(i)
		b.visible = not t.is_tab_hidden(i)
		var on := i == t.current_tab
		if b.has_meta("on") and bool(b.get_meta("on")) == on:   # (get_meta with a null default logs an engine error)
			continue
		b.set_meta("on", on)
		chip_look(b, on)

## The chip look (tab strips, the floor picker's zones): gold on slate when on, dim when off.
static func chip_look(b: Button, on: bool) -> void:
	var faces: Array = _chip_faces()   # Fable r3 #16: built once, shared by every chip
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, faces[0] if on else (faces[2] if st == "hover" else faces[1]))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, GOLD if on else (TEXT if c == "font_hover_color" else DIM))

static var _chip_face_cache: Array = []
## [on, off, off-hover] chip faces with the 17 px side margins.
static func _chip_faces() -> Array:
	if _chip_face_cache.is_empty():
		for sb in [UiSkin.bevel(UiSkin.SLATE, GOLD_DULL, 6), UiSkin.bevel(PANEL, EMPTY, 6), UiSkin.bevel(UiSkin.SLATE, EDGE, 6)]:
			var c := (sb as StyleBox).duplicate() as StyleBox
			c.content_margin_left = 8   # Fable r5 #9 (was 17): six Hero chips fit one phone row
			c.content_margin_right = 8
			_chip_face_cache.append(c)
	return _chip_face_cache

## Fable r2 #13: the notch / Dynamic Island (top) and home bar (bottom) in design px, set by
## main._fit_layout; popups, the title and the creator keep their controls out of them.
static var safe_top := 0.0
static var safe_bottom := 0.0
static var nav_ref: Control   # the phone nav bar (main sets it)

## The lowest y a floating card may reach: the nav bar's top, else above the home bar.
static func floor_y(vp_h: float) -> float:
	if nav_ref != null and is_instance_valid(nav_ref) and nav_ref.is_visible_in_tree():
		return nav_ref.get_global_rect().position.y
	return vp_h - safe_bottom

## Fable r2 #5: the OptionButton arrow, a 7x4 bone chevron on the 2 px grid (Godot's is smoothed).
static var _chevron: Texture2D
static func chevron_icon() -> Texture2D:
	if _chevron == null:
		var img := Image.create(7, 4, false, Image.FORMAT_RGBA8)
		for y in 4:
			for x in range(y, 7 - y):
				img.set_pixel(x, y, TEXT)
		img.resize(7 * UiSkin.PX, 4 * UiSkin.PX, Image.INTERPOLATE_NEAREST)
		_chevron = ImageTexture.create_from_image(img)
	return _chevron

## Fable r2 #11: a name and the line under it. Names in bone, titles in gold; the class or
## race colour stays on the picture's frame, never on the text (red reads as "bad").
static func name_plate(name_text: String, sub := "", size := FONT_TITLE) -> VBoxContainer:
	var v := vbox(2)
	v.add_child(label(name_text, size, TEXT))
	if sub != "":
		var s: Label = UI.wrap(sub, FONT_BODY, GOLD)
		v.add_child(s)
	return v

## Fable r1 #18: the Menu glyph, three bone bars on the 2 px grid (the font has no "≡").
static var _menu_icon: Texture2D
static func menu_icon() -> Texture2D:
	if _menu_icon == null:
		var img := Image.create(9, 7, false, Image.FORMAT_RGBA8)
		for y in [0, 3, 6]:
			for x in 9:
				img.set_pixel(x, y, TEXT)
		img.resize(9 * UiSkin.PX, 7 * UiSkin.PX, Image.INTERPOLATE_NEAREST)
		_menu_icon = ImageTexture.create_from_image(img)
	return _menu_icon

## Fable r1 #4: an on/off setting. The same slate face and bone text both ways (so OFF never
## looks disabled); a pixel box at the left says it: gold with a check when on, empty when off.
static func toggle_look(b: Button, on: bool) -> void:
	b.icon = _check_icon(on)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 12)
	b.remove_theme_stylebox_override("normal")
	b.add_theme_color_override("font_color", TEXT)

static var _checks := {}
static func _check_icon(on: bool) -> Texture2D:
	if _checks.has(on):
		return _checks[on]
	var n := 12   # art px, drawn at 2x (the grid)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var edge := x == 0 or y == 0 or x == n - 1 or y == n - 1
			var rim := x == 1 or y == 1 or x == n - 2 or y == n - 2
			img.set_pixel(x, y, UiSkin.SOOT if edge else (EDGE if rim else (GOLD if on else INSET)))
	if on:   # an ink check mark
		for p in [Vector2i(3, 6), Vector2i(4, 7), Vector2i(5, 8), Vector2i(6, 7), Vector2i(7, 6), Vector2i(8, 5), Vector2i(9, 4),
				Vector2i(3, 5), Vector2i(4, 6), Vector2i(5, 7), Vector2i(6, 6), Vector2i(7, 5), Vector2i(8, 4)]:
			img.set_pixel(p.x, p.y, UiSkin.SOOT)
	img.resize(n * UiSkin.PX, n * UiSkin.PX, Image.INTERPOLATE_NEAREST)
	_checks[on] = ImageTexture.create_from_image(img)
	return _checks[on]

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

## Fable r5 #4: a button that can't be used right now still answers a tap with the reason
## (a disabled button gets no tap, and a tooltip is hover-only on a phone). reason "" makes it
## live again. The button is faded, keeps its place, and the tap shows the reason as a tip
## instead of doing the action (the tap is eaten before the button sees it).
static func why(b: Button, reason: String, fade := true) -> void:
	b.disabled = false
	if not b.has_meta("tip0"):
		b.set_meta("tip0", b.tooltip_text)   # the hover text it had while usable
	b.tooltip_text = reason if reason != "" else String(b.get_meta("tip0"))
	b.set_meta("why", reason)
	b.modulate.a = 1.0 if reason == "" or not fade else 0.55
	if b.has_meta("why_wired"):
		return
	b.set_meta("why_wired", true)
	b.gui_input.connect(func(ev: InputEvent):
		var r := String(b.get_meta("why", ""))
		if r == "":
			return
		var press: bool = (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT)
		if not press:
			return
		b.accept_event()
		if ev.is_pressed():
			if sfx:
				sfx.play("error")
			show_tip(b, r))

## The reason for UI.why when a price is out of reach: "Need 120 more gold." ("" when it isn't).
static func need_gold(have: int, cost: int) -> String:
	return "" if have >= cost else "Need %s more gold." % _commas(cost - have)

## True while UI.why holds a reason on this button.
static func blocked(b: Button) -> bool:
	return String(b.get_meta("why", "")) != ""

## A colored button for the main action on a screen.
static func primary(text: String, on_press: Callable, color := GOLD) -> Button:
	color = role_color(color)
	var b := button(text, on_press)
	var edge := GOLD_DULL if color == GOLD else (Color("#a22633") if color == BAD else color)
	var ink := GOLD if color == GOLD else color.lightened(0.25)
	b.add_theme_stylebox_override("normal", UiSkin.bevel(UiSkin.SLATE, edge, 8))
	b.add_theme_stylebox_override("hover", UiSkin.bevel(BORDER, edge, 8))
	b.add_theme_stylebox_override("pressed", UiSkin.bevel(UiSkin.SLATE, edge, 8, true))
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink.lightened(0.2))
	b.add_theme_color_override("font_pressed_color", ink)
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
	b.add_theme_stylebox_override("background", style(INSET, BG, 4, 0, 1))
	b.add_theme_stylebox_override("fill", style(fill, fill, 4, 0, 0))
	return b

## A rounded "pill" holding a value, used in the top bar.
static func pill(text_color: Color, font_size := FONT_CAPTION) -> Array:
	var p := panel(INSET, Color(text_color, 0.35), 12, 0, 1)
	p.get_theme_stylebox("panel").content_margin_left = 12
	p.get_theme_stylebox("panel").content_margin_right = 12
	p.get_theme_stylebox("panel").content_margin_top = 4
	p.get_theme_stylebox("panel").content_margin_bottom = 4
	var l := label("", font_size, text_color)
	p.add_child(l)
	return [p, l]

## A label that wraps onto more lines instead of stretching the screen.
static func wrap(text: String, font_size := FONT_BODY, color := TEXT) -> Label:
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
	parent.add_child(heading(title, note))   # one heading style everywhere

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
		if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and (force_touch or DisplayServer.is_touchscreen_available())):
			# Fable r5 #3: a label whose tip is its own (whole, uncut) words has nothing to add
			if c is Label and c.tooltip_text == (c as Label).text and c.get_theme_font("font").get_string_size((c as Label).text, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x <= c.size.x:
				return
			show_tip(c, c.tooltip_text))

## Fable r5 #10: a path ("Items › Gear") whose › never starts or ends a wrapped line (no-break spaces).
const PATH_SEP := " › "
static func path(parts: Array) -> String:
	return PATH_SEP.join(parts)

## Fable r5 #15: "today", "yesterday", "3 days ago", then "12 Oct".
static func when(unix: int) -> String:
	var days := int(Time.get_unix_time_from_system() / 86400.0) - int(unix / 86400.0)
	if days <= 0:
		return "today"
	if days == 1:
		return "yesterday"
	if days < 7:
		return "%d days ago" % days
	var d := Time.get_date_dict_from_unix_time(unix)
	return "%d %s" % [d["day"], ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(d["month"]) - 1]]

## Juzo (r5 follow-up): the hero stands IN their shadow, never above it. pic shows a portrait at
## k x; the bottom of its last boot row (Sprites.PORTRAIT_FOOT, the same row in every body) goes
## on the plinth's centre line at ground_y, cx is the centre across. The tour's FLOATING HERO /
## CUT SHADOW gate finds the pair by the meta set here.
static func seat_hero(pic: Control, pl: TextureRect, k: int, cx: float, ground_y: float) -> void:
	pic.position = Vector2(roundf(cx - pic.size.x / 2.0), roundf(ground_y) - (Sprites.PORTRAIT_FOOT + 1) * k)
	pl.position = Vector2(roundf(cx - pl.texture.get_width() / 2.0), roundf(ground_y) - roundf(pl.texture.get_height() / 2.0))
	pl.set_meta("hero_pic", pic)
	pl.set_meta("hero_k", k)

## Where the shadow's centre line goes so the whole plinth fits in a box h tall (2 px spare).
static func seat_ground(h: float, pl: TextureRect) -> float:
	return h - roundf(pl.texture.get_height() / 2.0) - 2.0

## Pops a small explanation next to a control; it fades by itself.
static func show_tip(near: Control, text: String) -> void:
	if tip_layer == null or text == "":
		return
	if is_instance_valid(_tip):
		_tip.queue_free()
	var p := panel(INSET, GOLD, 8, 10, 1)
	p.theme = theme()   # a CanvasLayer carries no theme (Fable r4 #2)
	p.name = "Tip"
	var r := rich(FONT_BODY)
	r.text = text
	r.custom_minimum_size = Vector2(minf(300.0, near.get_viewport_rect().size.x - 40.0), 0)
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
	if pos.y + p.size.y > floor_y(vp.y) - 8:
		pos.y = at.position.y - p.size.y - 6
	pos.y = clampf(pos.y, safe_top + 8.0, vp.y - safe_bottom - p.size.y - 8.0)
	pos.x = clampf(pos.x, 8, vp.x - p.size.x - 8)
	p.position = pos
	var tw := p.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)

## The game font: Pixelify Sans (OFL, art/ui/fonts), SemiBold, no subpixel blur.
static var _font: Font
static func game_font() -> Font:
	if _font == null:
		var f := load("res://art/ui/fonts/PixelifySans.ttf") as FontFile
		if f == null:
			return ThemeDB.fallback_font
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		f.fallbacks = [ThemeDB.fallback_font]   # any character Pixelify lacks
		var v := FontVariation.new()
		v.base_font = f
		var ts := TextServerManager.get_primary_interface()
		v.variation_opentype = {ts.name_to_tag("wght"): 600}
		# no ligatures: Pixelify's fi/fl ligature reads as an "A" on the pixel grid ("choose your Aoor")
		v.opentype_features = {ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0}
		_font = v
	return _font

## The one shared theme (Fable r1 #3): built on first use, reused by every popup.
static var _theme: Theme
## Fable r4 #2: Controls that are children of main (a Node2D) or of a CanvasLayer inherit no
## theme and fell back to Godot's own (smooth white sans). Folding ours into the default theme
## once makes every Control in the game Pixelify, bone and iron, wherever it is added.
static func adopt_default_theme() -> void:
	var dt := ThemeDB.get_default_theme()
	if dt == null or dt.has_meta("solaria"):
		return
	dt.merge_with(theme())
	dt.default_font = game_font()
	dt.default_font_size = FONT_BODY
	dt.set_meta("solaria", true)

static func theme() -> Theme:
	if _theme == null:
		_theme = make_theme()
	return _theme

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = game_font()
	t.default_font_size = FONT_BODY
	t.set_constant("line_spacing", "Label", 1)   # the pixel font needs less air between lines than the old one (phone fit)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "PanelContainer", UiSkin.frame(PANEL, UiSkin.IRON, 12))  # next update: iron frames on stone

	t.set_stylebox("normal", "Button", UiSkin.bevel(UiSkin.SLATE, EDGE, 6))  # slate buttons
	t.set_stylebox("hover", "Button", UiSkin.bevel(UiSkin.SLATE, GOLD_DULL, 6))
	t.set_stylebox("pressed", "Button", UiSkin.bevel(GOLD_DEEP, GOLD_DULL, 6, true))
	t.set_stylebox("disabled", "Button", UiSkin.bevel(Color("#1f1d24"), EMPTY, 6))
	var ring := style(Color(0, 0, 0, 0), GOLD, 7, 6, 2)
	ring.draw_center = false
	ring.expand_margin_left = 2
	ring.expand_margin_right = 2
	ring.expand_margin_top = 2
	ring.expand_margin_bottom = 2
	t.set_stylebox("focus", "Button", ring)
	t.set_stylebox("focus", "OptionButton", ring)
	t.set_stylebox("focus", "LineEdit", ring)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", Color("#f4e6c4"))
	t.set_color("font_disabled_color", "Button", Color("#5a6988"))

	t.set_stylebox("panel", "ItemList", style(INSET, EMPTY, 6, 4))
	t.set_stylebox("selected", "ItemList", style(HILITE, HILITE, 4, 2))
	t.set_stylebox("selected_focus", "ItemList", style(HILITE, GOLD_DULL, 4, 2))
	t.set_stylebox("hovered", "ItemList", style(Color("#1f1d24"), Color("#1f1d24"), 4, 2))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_color("guide_color", "ItemList", Color(1, 1, 1, 0.04))

	t.set_stylebox("panel", "TabContainer", UiSkin.frame(Color(PANEL, 0.84), UiSkin.IRON, 12))  # see-through: the torchlit wall shows behind
	t.set_stylebox("tab_selected", "TabContainer", UiSkin.bevel(UiSkin.SLATE, GOLD_DULL, 8))
	t.set_stylebox("tab_unselected", "TabContainer", UiSkin.bevel(PANEL, EMPTY, 8))
	t.set_stylebox("tab_hovered", "TabContainer", UiSkin.bevel(UiSkin.SLATE, EDGE, 8))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font_size("font_size", "TabContainer", FONT_BODY)
	t.set_font_size("font_size", "Button", FONT_BODY)
	t.set_font_size("font_size", "OptionButton", FONT_BODY)
	t.set_font_size("font_size", "ItemList", FONT_BODY)
	t.set_font_size("font_size", "LineEdit", FONT_BODY)

	# Sub-tabs (inside a main tab): a row of slate blocks, the open one framed in gold
	t.add_type("SubTabs")
	t.set_type_variation("SubTabs", "TabContainer")
	t.set_stylebox("panel", "SubTabs", StyleBoxEmpty.new())
	t.set_stylebox("tab_selected", "SubTabs", UiSkin.bevel(UiSkin.SLATE, GOLD_DULL, 6))
	t.set_stylebox("tab_unselected", "SubTabs", UiSkin.bevel(PANEL, EMPTY, 6))
	t.set_stylebox("tab_hovered", "SubTabs", UiSkin.bevel(UiSkin.SLATE, EDGE, 6))
	t.set_font_size("font_size", "SubTabs", FONT_BODY)
	for st_name in ["tab_selected", "tab_unselected", "tab_hovered"]:   # Fable r1 #2: sub-tabs 17+20+17 = 54 design px
		var sb := t.get_stylebox(st_name, "SubTabs").duplicate() as StyleBox
		sb.content_margin_top = 17
		sb.content_margin_bottom = 17
		t.set_stylebox(st_name, "SubTabs", sb)
	t.set_color("font_selected_color", "SubTabs", GOLD)

	# OptionButtons have no minimum height: their margins make them a full tap target (16+20+16)
	for ob in [["normal", EDGE], ["hover", GOLD_DULL], ["pressed", GOLD_DULL]]:
		var osb := UiSkin.bevel(UiSkin.SLATE, ob[1], 6)
		osb.content_margin_top = 16
		osb.content_margin_bottom = 16
		t.set_stylebox(ob[0], "OptionButton", osb)
	var le := style(INSET, EDGE, 0, 10, 2)
	le.content_margin_top = 14
	le.content_margin_bottom = 14
	t.set_stylebox("normal", "LineEdit", le)
	t.set_icon("arrow", "OptionButton", chevron_icon())
	t.set_constant("arrow_margin", "OptionButton", 14)
	# the list an OptionButton opens: body text, rows a full tap tall, the game's bevels
	t.set_stylebox("panel", "PopupMenu", UiSkin.frame(PANEL, UiSkin.IRON, 8))
	t.set_font_size("font_size", "PopupMenu", FONT_BODY)
	t.set_constant("v_separation", "PopupMenu", 30)   # 20 px text + 30 = 50, plus the row's margins
	t.set_constant("item_start_padding", "PopupMenu", 14)
	t.set_constant("item_end_padding", "PopupMenu", 14)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_stylebox("hover", "PopupMenu", UiSkin.bevel(UiSkin.SLATE, GOLD_DULL, 6))
	for ic in ["radio_checked", "radio_unchecked", "checked", "unchecked"]:
		t.set_icon(ic, "PopupMenu", _check_icon(ic in ["radio_checked", "checked"]))
	t.set_stylebox("grabber_area", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", style(GOLD, GOLD, 3, 0, 0))
	t.set_stylebox("slider", "HSlider", style(INSET, EDGE, 3, 2, 1))
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
