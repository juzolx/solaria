extends Container
## Juzo (PC wide layout: "the game keeps moving the screen further"): a holder with no minimum
## width, so what it holds can't push its parents wider than the window.
## The child gets the holder's own rect. If the child's minimum is bigger, it runs past the edge,
## and the wide tour's ROOT OVERFLOW gate names it.
## Used around the whole interface (main.gd) and around grids that pick their column count from
## the width they are given (hero stats, bag and gear items). A grid measured by its own size never
## shrinks again: its columns set its minimum width, which keeps the page wide, which keeps the
## columns. That ratchet made the screen drift right over time.

## false: no minimum height either (the whole screen: it is always exactly the window)
var keep_height := true

func _get_minimum_size() -> Vector2:
	var h := 0.0
	if keep_height:
		for c in get_children():
			if c is Control and (c as Control).visible and not (c as Control).top_level:
				h = maxf(h, (c as Control).get_combined_minimum_size().y)
	return Vector2(0.0, h)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		for c in get_children():
			if c is Control and (c as Control).visible and not (c as Control).top_level:
				fit_child_in_rect(c as Control, Rect2(Vector2.ZERO, size))

static func hold(c: Control) -> Control:
	var h = load("res://fit_box.gd").new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(c)
	return h
