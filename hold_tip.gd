class_name HoldTip
extends Node
## Tap-and-hold tooltips. Phones have no hover, so Godot's tooltips never show
## there. Holding a finger (or the mouse button) still on anything with a
## tooltip for a moment pops its explanation up next to it; letting go then
## closes it without pressing the button underneath.

const HOLD_SECONDS := 0.45
const MOVE_SLOP := 14.0   # screen pixels a finger may drift and still count as holding

var _down := false
var _pos := Vector2.ZERO
var _t := 0.0
var _shown: PanelContainer = null
var _swallow_release := false

func _input(event: InputEvent) -> void:
	var pressed_event := (event is InputEventScreenTouch) or (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if pressed_event:
		if event.is_pressed():
			_close()
			_down = true
			_pos = event.position
			_t = 0.0
		else:
			_down = false
			if _swallow_release:
				# The hold showed a tip: this release mustn't also press the button
				_swallow_release = false
				get_viewport().set_input_as_handled()
				_close.call_deferred()
	elif _down and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		if event.position.distance_to(_pos) > MOVE_SLOP:
			_down = false  # a scroll or a drag, not a hold

func _process(delta: float) -> void:
	if not _down or _shown != null:
		return
	_t += delta
	if _t >= HOLD_SECONDS:
		var c := _control_at(_pos)
		if c != null:
			_show(c)
			_swallow_release = true
		_down = false

## The control under the finger (touch moves Godot's pointer too) or the nearest
## parent of it that has a tooltip.
func _control_at(_screen_pos: Vector2) -> Control:
	var c: Node = get_viewport().gui_get_hovered_control()
	while c != null:
		if c is Control and (c as Control).tooltip_text != "" and (c as Control).is_visible_in_tree():
			return c as Control
		c = c.get_parent()
	return null

func _show(c: Control) -> void:
	var vp := get_viewport().get_visible_rect().size
	var panel := UI.panel(Color(0.05, 0.06, 0.1, 0.97), UI.GOLD, 8, 10, 1)
	var label := UI.label(c.tooltip_text, UI.FONT_BODY, UI.TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(minf(320.0, vp.x - 40.0), 0)
	panel.add_child(label)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.top_level = true
	panel.z_index = 100
	c.get_tree().root.add_child(panel)
	_shown = panel
	# Above the finger when there's room (a finger covers what's under it), else below
	await c.get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var r := c.get_global_rect()
	var sz := panel.size
	var x := clampf(r.get_center().x - sz.x / 2.0, 8.0, vp.x - sz.x - 8.0)
	var y := r.position.y - sz.y - 8.0
	if y < 8.0:
		y = minf(r.end.y + 8.0, vp.y - sz.y - 8.0)
	panel.position = Vector2(x, y)

func _close() -> void:
	if _shown != null and is_instance_valid(_shown):
		_shown.queue_free()
	_shown = null
