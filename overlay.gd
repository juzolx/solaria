class_name Overlay
extends Control
## A dimmed full-screen popup with a centered panel. Used for menus,
## the floor picker, confirmations and the class picker.

var content: VBoxContainer
var box: PanelContainer
var scroll: ScrollContainer  # tall popups scroll instead of running off the screen

## Builds the popup on top of the game. Returns self so callers can fill .content.
func open(parent: Node, title: String, width := 560.0, border := UI.GOLD, closable := true) -> Overlay:
	parent.add_child(self)
	for n in get_tree().get_nodes_in_group("toast"):
		n.queue_free()  # a toast never sits on top of a popup
	theme = UI.make_theme()
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
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.minimum_size_changed.connect(_fit_height)
	var head := UI.hbox(8)
	content.add_child(head)
	var t := UI.label(title, 22, UI.GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if closable:
		head.add_child(UI.button("Close", close))
	return self

## True on phone-width screens, where side-by-side layouts should stack.
func is_narrow() -> bool:
	return get_viewport().get_visible_rect().size.x < 720.0  # portrait layouts are 648 wide or less

func _fit_height() -> void:
	if not is_inside_tree():
		return
	var max_h := get_viewport().get_visible_rect().size.y - 70.0
	scroll.custom_minimum_size.y = minf(content.get_combined_minimum_size().y, max_h)

func close() -> void:
	queue_free()
