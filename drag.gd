class_name Drag
## Next update (Juzo): drag and drop for everything you equip or move. Payloads
## are {"kind": "item" | "worn" | "skill" | "pet" | "stash", "id": ..., ...}.
## Mouse: drag right away. Touch screens: press and hold a moment first, so a
## quick swipe still scrolls the list.

const HOLD_MS := 280   # touch: how long to hold before a drag starts

static var _press_ms := 0

## Makes c draggable and/or a drop target. data: the payload (or {} for none);
## picture: a Texture2D, or a Callable that returns one when the drag starts.
## accept(data) -> bool says what it takes; on_drop(data) does the move.
static func wire(c: Control, data: Dictionary, picture: Variant = null, accept := Callable(), on_drop := Callable()) -> void:
	var get_data := Callable()
	if not data.is_empty():
		c.gui_input.connect(func(ev):
			if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed:
				_press_ms = Time.get_ticks_msec())
		get_data = func(_at: Vector2) -> Variant:
			if DisplayServer.is_touchscreen_available() and Time.get_ticks_msec() - _press_ms < HOLD_MS:
				return null  # a swipe: let the list scroll
			c.set_drag_preview(_preview(picture.call() if picture is Callable else picture, c))
			return data
	var can := Callable()
	var drop := Callable()
	if accept.is_valid():
		can = func(_at: Vector2, d: Variant) -> bool:
			return d is Dictionary and accept.call(d)
		drop = func(_at: Vector2, d: Variant) -> void:
			on_drop.call(d)
	c.set_drag_forwarding(get_data, can, drop)

static func _preview(picture: Texture2D, c: Control) -> Control:
	var holder := Control.new()
	var t := TextureRect.new()
	t.texture = picture
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s := clampf(minf(c.size.x, c.size.y), 40.0, 72.0)
	t.size = Vector2(s, s)
	t.position = -t.size * 0.5   # centered under the finger
	t.modulate = Color(1, 1, 1, 0.85)
	if picture == null:
		var l := Label.new()
		l.text = "..."
		holder.add_child(l)
	holder.add_child(t)
	return holder
