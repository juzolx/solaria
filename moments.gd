class_name Moments
extends Control
## The big moments, full screen: stepping into a realm, a realm boss's
## entrance, awakening, a transformation and unlocking a hidden class.
## The fight pauses while one plays. Tap to skip.

var main_node
var lines: Array[Label] = []
var done := false

## kind: "realm", "boss", "awaken", "transform", "hidden"
static func play(main_ref, kind: String, title: String, sub: String, color: Color, extra := "", portrait: Texture2D = null, backdrop: Texture2D = null) -> Moments:
	var m := Moments.new()
	m.main_node = main_ref
	main_ref.add_child(m)
	m._build(kind, title, sub, color, extra, portrait, backdrop)
	return m

func _build(kind: String, title: String, sub: String, color: Color, extra: String, portrait: Texture2D, backdrop: Texture2D) -> void:
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Entering a realm: its landscape slowly pans behind the words
	if backdrop:
		var pan := TextureRect.new()
		pan.texture = backdrop
		pan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pan.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pan.stretch_mode = TextureRect.STRETCH_SCALE
		var h := size.y
		var w := maxf(size.x * 1.25, h * 160.0 / 90.0)
		pan.size = Vector2(w, w * 90.0 / 160.0)
		pan.position = Vector2(0, (h - pan.size.y) / 2.0)
		pan.modulate = Color(1, 1, 1, 0)
		pan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pan)
		var pt := create_tween().set_parallel(true)
		pt.tween_property(pan, "modulate:a", 0.85, 0.8)
		pt.tween_property(pan, "position:x", size.x - pan.size.x, 5.5).set_trans(Tween.TRANS_SINE)
	# A soft band of the moment's color behind the text
	var band := ColorRect.new()
	band.color = Color(color.r, color.g, color.b, 0.0)
	band.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	band.offset_top = -170 if portrait else -90
	band.offset_bottom = 110 if portrait else 90
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	if portrait:
		var pic := TextureRect.new()
		pic.texture = portrait
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.custom_minimum_size = Vector2(150, 150)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.modulate.a = 0.0
		v.add_child(pic)
		var pt := create_tween()
		pt.tween_interval(0.5)
		pt.tween_property(pic, "modulate:a", 1.0, 0.6)
	var kicker: String = {"realm": "YOU ENTER", "boss": "", "awaken": "AWAKENING", "transform": "SOMETHING CHANGES", "hidden": "HIDDEN CLASS", "class": "YOUR CLASS GROWS"}.get(kind, "")
	if kicker != "":
		lines.append(_line(v, kicker, 14, color.lightened(0.3)))
	lines.append(_line(v, title.to_upper(), 34 if kind != "boss" else 30, color.lightened(0.4)))
	if sub != "":
		lines.append(_line(v, sub, 15, UI.TEXT))
	if extra != "":
		lines.append(_line(v, extra, 12, UI.DIM))
	lines.append(_line(v, "(tap to continue)", 10, UI.DIM))
	# Fade in, burn the title in letter by letter, hold, fade out
	var t := create_tween()
	t.tween_property(bg, "color:a", 0.92 if kind in ["hidden", "transform", "class"] else 0.85, 0.4)
	t.parallel().tween_property(band, "color:a", 0.18, 0.6)
	for i in lines.size():
		var l: Label = lines[i]
		l.visible_ratio = 0.0
		l.modulate.a = 1.0
		var dur := 0.9 if i == (1 if kicker != "" else 0) else 0.35
		if kind == "hidden" and i == 1:
			dur = 1.6
		t.tween_property(l, "visible_ratio", 1.0, dur)
	t.tween_interval(2.6 if kind != "boss" else 1.8)
	t.tween_callback(close)
	if main_node and main_node.timer:
		main_node.timer.paused = true
	if main_node and main_node.sfx:
		main_node.sfx.play({"realm": "portal", "boss": "boss_intro", "awaken": "awaken", "transform": "transform", "hidden": "hidden", "class": "spec"}.get(kind, "event"))

func _line(parent: Control, text: String, size_px: int, color: Color) -> Label:
	var l := UI.label(text, size_px, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(560.0, size.x - 40.0), 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		close()

func close() -> void:
	if done:
		return
	done = true
	if main_node and main_node.timer and is_instance_valid(main_node.timer):
		main_node.timer.paused = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
