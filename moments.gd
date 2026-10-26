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
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.show_behind_parent = true  # A6: the light burst (_draw) shows over the backdrop
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
	band.offset_bottom = 170 if portrait else 90
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
		pic.custom_minimum_size = Vector2(Sprites.PORTRAIT * 3, Sprites.PORTRAIT * 3)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.modulate.a = 0.0
		v.add_child(pic)
		var pt := create_tween()
		pt.tween_interval(0.5)
		pt.tween_property(pic, "modulate:a", 1.0, 0.6)
	var kicker: String = {"realm": "YOU ENTER", "boss": "", "awaken": "AWAKENING", "transform": "SOMETHING CHANGES", "hidden": "HIDDEN CLASS", "god": "A GOD CLASS ANSWERS", "class": "YOUR CLASS GROWS", "milestone": "A MILESTONE", "hatch": "IT HATCHED!", "forge": "FRESH FROM THE FORGE", "first": "FIRST FIND!"}.get(kind, "")
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
	t.tween_property(bg, "color:a", 0.92 if kind in ["hidden", "god", "transform", "class"] else 0.85, 0.4)
	t.parallel().tween_property(band, "color:a", 0.18, 0.6)
	for i in lines.size():
		var l: Label = lines[i]
		l.visible_ratio = 0.0
		l.modulate.a = 1.0
		var dur := 0.9 if i == (1 if kicker != "" else 0) else 0.35
		if kind in ["hidden", "god"] and i == 1:
			dur = 1.6
		t.tween_property(l, "visible_ratio", 1.0, dur)
	t.tween_interval(2.6 if kind != "boss" else 1.8)
	t.tween_callback(close)
	# A6: the rarest moments (hidden or God class, awakening) open with a burst of light
	var calm: bool = main_node != null and main_node.profile != null and main_node.profile.reduce_motion
	if kind in ["hidden", "god", "awaken", "transform"] and not calm:
		_ray_color = color
		_ray_center = Vector2(size.x * 0.5, size.y * 0.42)
		var ft := create_tween()
		ft.tween_interval(0.35)
		ft.tween_method(func(x: float): _rays = x; queue_redraw(), 0.0, 1.0, 0.25)
		ft.tween_callback(_burst)
		ft.tween_method(func(x: float): _rays = x; queue_redraw(), 1.0, 0.3, 1.4)
	if main_node and main_node.timer:
		main_node.timer.paused = true
	if main_node and main_node.sfx:
		main_node.sfx.play({"realm": "portal", "boss": "boss_intro", "awaken": "awaken", "transform": "transform", "hidden": "hidden", "god": "hidden", "class": "spec", "milestone": "milestone", "hatch": "pet", "forge": "craft", "first": "milestone"}.get(kind, "event"))

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

# =====================================================================
# Evolving: the hero changes in front of you
# =====================================================================

## The full-screen evolution: your old look, a burst of light in your rank's
## color, your new look, then the new class, its rank and its signature skill.
## d: {"name", "role", "rank", "color", "before", "after", "skill", "skill_text", "tier"}
static func evolve(main_ref, d: Dictionary) -> Moments:
	var m := Moments.new()
	m.main_node = main_ref
	main_ref.add_child(m)
	m._build_evolve(d)
	return m

var _rays := 0.0       # 0..1 how bright the light burst is
var _ray_color := Color.WHITE
var _ray_center := Vector2.ZERO
var _sparks: Array = []  # [pos, vel, life]

func _build_evolve(d: Dictionary) -> void:
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var color: Color = d.get("color", UI.GOLD)
	_ray_color = color
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.show_behind_parent = true  # A6: the light burst (_draw) shows over the backdrop
	move_child(bg, 0)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var v := UI.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var pic_box := Control.new()
	pic_box.custom_minimum_size = Vector2(Sprites.PORTRAIT * 3, Sprites.PORTRAIT * 3)
	pic_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pic_box)
	var before := TextureRect.new()
	var after := TextureRect.new()
	for p in [before, after]:
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.size = Vector2(190, 190)
		p.pivot_offset = Vector2(95, 95)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic_box.add_child(p)
	before.texture = d.get("before")
	after.texture = d.get("after")
	before.modulate.a = 0.0
	after.modulate.a = 0.0
	var kicker := _line(v, "YOUR CLASS EVOLVES" if int(d.get("tier", 1)) < 3 else "UNIQUE CLASS", 14, color.lightened(0.3))
	var title := _line(v, String(d.get("name", "")).to_upper(), 36, color.lightened(0.45))
	var rank_txt := String(d.get("sub", ""))
	var sub := _line(v, rank_txt, 15, color.lightened(0.2)) if rank_txt != "" else null
	var role := _line(v, String(d.get("role", "")), 14, UI.TEXT)
	var sk := String(d.get("skill", ""))
	var skill := _line(v, "New signature skill: %s" % sk, 15, Color(Signatures.COLOR)) if sk != "" else null
	var skill_t := _line(v, String(d.get("skill_text", "")), 12, UI.DIM) if sk != "" else null
	var tap := _line(v, "(tap to continue)", 10, UI.DIM)
	var texts: Array = [kicker, title, sub, role, skill, skill_t, tap].filter(func(x): return x != null)
	for l in texts:
		(l as Label).modulate.a = 0.0
	lines.assign(texts)
	await get_tree().process_frame
	_ray_center = pic_box.get_global_rect().get_center() - global_position
	var t := create_tween()
	t.tween_property(bg, "color:a", 0.94, 0.4)
	t.tween_property(before, "modulate:a", 1.0, 0.4)
	# The old you shakes, glows and bursts into light
	t.tween_property(before, "scale", Vector2(1.06, 1.06), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(before, "modulate", Color(3, 3, 3, 1), 0.45)
	t.tween_method(func(x: float): _rays = x; queue_redraw(), 0.0, 1.0, 0.25)
	t.tween_callback(func():
		before.visible = false
		after.modulate = Color(3, 3, 3, 1)
		after.scale = Vector2(1.25, 1.25)
		_burst()
		if main_node and main_node.sfx:
			main_node.sfx.play("awaken"))
	t.tween_property(after, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(after, "modulate", Color.WHITE, 0.6)
	t.parallel().tween_method(func(x: float): _rays = x; queue_redraw(), 1.0, 0.35, 1.2)
	for l in texts:
		t.tween_property(l, "modulate:a", 1.0, 0.25)
	t.tween_interval(3.2)
	t.tween_callback(close)
	if main_node and main_node.timer:
		main_node.timer.paused = true
	if main_node and main_node.sfx:
		main_node.sfx.play("evolve")

func _burst() -> void:
	_sparks.clear()
	if main_node and main_node.profile and main_node.profile.reduce_motion:
		return
	for i in 46:
		var a := randf() * TAU
		var sp := randf_range(120.0, 420.0)
		_sparks.append([_ray_center, Vector2(cos(a), sin(a)) * sp, randf_range(0.6, 1.3)])
	set_process(true)

func _process(delta: float) -> void:
	if _sparks.is_empty():
		return
	for i in range(_sparks.size() - 1, -1, -1):  # R6: in place, no new array each frame
		var s: Array = _sparks[i]
		s[0] += s[1] * delta
		s[1] *= 0.94
		s[2] -= delta
		if float(s[2]) <= 0.0:
			_sparks.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if _rays > 0.0:
		var n := 14
		var r := 260.0 + 340.0 * _rays
		for i in n:
			var a := TAU * i / n + Time.get_ticks_msec() / 2400.0
			var a2 := a + TAU / n * 0.42
			var pts := PackedVector2Array([_ray_center, _ray_center + Vector2(cos(a), sin(a)) * r, _ray_center + Vector2(cos(a2), sin(a2)) * r])
			draw_colored_polygon(pts, Color(_ray_color, 0.16 * _rays))
		for k in 5:
			draw_circle(_ray_center, (40.0 + k * 26.0) * (0.6 + _rays), Color(_ray_color.lightened(0.4), 0.07 * _rays))
	for s in _sparks:
		var life := clampf(float(s[2]), 0.0, 1.0)
		draw_rect(Rect2(s[0] - Vector2(2, 2), Vector2(4, 4)), Color(_ray_color.lightened(0.5), life))
