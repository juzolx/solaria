class_name Overlay
extends Control
## A dimmed full-screen popup with a centered panel. Used for menus,
## the floor picker, confirmations and the class picker.

var content: VBoxContainer
var box: PanelContainer
var scroll: ScrollContainer  # tall popups scroll instead of running off the screen
var head: HBoxContainer   # the title and Close: above the scroll, so they never scroll away (Fable r1 #3)
var foot: HBoxContainer   # under the scroll: a second Close when the content is taller than the screen
var frame_box: VBoxContainer
var bottom_close: Button

## Builds the popup on top of the game. Returns self so callers can fill .content.
func open(parent: Node, title: String, width := 560.0, border := UI.GOLD, closable := true) -> Overlay:
	parent.add_child(self)
	for n in get_tree().get_nodes_in_group("toast"):
		n.queue_free()  # a toast never sits on top of a popup
	theme = UI.theme()   # built once (Fable r1 #3: every popup used to build ~35 styleboxes)
	size = get_viewport().get_visible_rect().size
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiSkin.frame(UI.PANEL, border, 18))  # next update: an iron frame in the popup's color
	box.custom_minimum_size = Vector2(minf(width, size.x - 24.0), 0)  # phones are narrow
	center.add_child(box)
	frame_box = UI.vbox(10)
	box.add_child(frame_box)
	head = UI.hbox(8)
	frame_box.add_child(head)
	var t := UI.label(title, UI.FONT_TITLE, UI.GOLD)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if closable:
		var cb := UI.button("Close", close)
		cb.custom_minimum_size = Vector2(UI.TAP * 2, UI.TAP)
		cb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		head.add_child(cb)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame_box.add_child(scroll)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.minimum_size_changed.connect(_fit_height)
	foot = UI.hbox(8)
	frame_box.add_child(foot)
	if closable:
		bottom_close = UI.button("Close", close)
		bottom_close.custom_minimum_size = Vector2(0, UI.TAP)
		bottom_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_close.visible = false
		foot.add_child(bottom_close)
	foot.visible = false
	return self

## True on phone-width screens, where side-by-side layouts should stack.
func is_narrow() -> bool:
	return get_viewport().get_visible_rect().size.x < 720.0  # portrait layouts are 648 wide or less

func _fit_height() -> void:
	if not is_inside_tree():
		return
	var vh := get_viewport().get_visible_rect().size.y
	var need := content.get_combined_minimum_size().y
	var max_h := vh - 70.0 - head.get_combined_minimum_size().y - 10.0
	# a long popup also gets a Close at the bottom, so the way out is never a scroll away
	if bottom_close:
		bottom_close.visible = need > max_h
	var foot_used := false
	for c in foot.get_children():
		if (c as Control).visible:
			foot_used = true
	foot.visible = foot_used
	if foot_used:
		max_h -= foot.get_combined_minimum_size().y + 10.0
	scroll.custom_minimum_size.y = minf(need, max_h)

func close() -> void:
	queue_free()
