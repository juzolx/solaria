class_name CooldownRing
extends Control
## 0.13+: drawn over a skill button. A ring around its icon fills as the skill
## recharges, a thin bar along the bottom shows the same, and a soft pulse says "ready".

var frac := 0.0:          # 0 = ready, 1 = just used
	set(v):
		if v != frac:
			if v <= 0.0 and frac > 0.0:
				t = 0.0   # just came ready: pulse again
			frac = v
			set_process(true)
			queue_redraw()
var color := Color.WHITE
var turns := 0:   # turns left, drawn inside the ring while it recharges
	set(v):
		if v != turns:
			turns = v
			queue_redraw()
var t := 0.0
const PULSE_SECS := 3.0   # then it settles to a still "ready" ring and stops redrawing

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	t += delta
	if is_visible_in_tree():
		queue_redraw()
	if frac <= 0.0 and t > PULSE_SECS:
		set_process(false)

func _draw() -> void:
	var c := Vector2(21.0, size.y / 2.0)   # over the button's icon
	var r := minf(16.0, size.y / 2.0 - 3.0)
	if frac > 0.0:
		draw_arc(c, r, 0.0, TAU, 32, Color(0, 0, 0, 0.55), 3.0)
		var done := 1.0 - frac
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * done, 32, Color(color, 0.95), 3.0)
		draw_rect(Rect2(4, size.y - 4, (size.x - 8) * done, 2), Color(color, 0.8))
		if turns > 0:
			var f := UI.game_font()
			var s := str(turns)
			var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FONT_BODY).x
			draw_circle(c, r - 3.0, Color(UiSkin.SOOT, 0.85))
			draw_string(f, Vector2(roundf(c.x - w / 2.0), roundf(c.y + UI.FONT_BODY * 0.35)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FONT_BODY, UI.TEXT)
	else:
		var p := (0.5 + 0.5 * sin(t * 4.0)) if t <= PULSE_SECS else 0.6
		draw_arc(c, r + p * 1.5, 0.0, TAU, 32, Color(color, 0.25 + 0.35 * p), 2.0)
