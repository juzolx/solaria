class_name PixelPic
extends TextureRect
## A pixel-art picture in the UI at a whole number of SCREEN pixels per art pixel
## (Fable pets R2): a 64-point slot on a 430 pt phone is 54.6 screen px, 1.71 px per
## art px, so its pixels come out uneven. This sizes itself to art_px x round(want x
## stretch) screen px and keeps that when the window changes, as battle_view._unit does.

var art_px := 32
var want := 2.0   # design points per art pixel it aims for (2 = a 64 pt slot for 32 px art)

## px 0 = the texture's own longer side (non-square art keeps its shape, still whole pixels).
static func make(tex: Texture2D, px := 0, w := 2.0) -> PixelPic:
	var p := PixelPic.new()
	p.texture = tex
	if px <= 0:
		px = maxi(tex.get_width(), tex.get_height()) if tex != null else 32
	p.art_px = px
	p.want = w
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # the box is a whole multiple of the longer side
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.custom_minimum_size = Vector2.ONE * px * w   # until it knows the screen
	return p

## Screen pixels per design pixel (the window's stretch), 1 with no viewport yet.
static func stretch(c: CanvasItem) -> float:
	var vp := c.get_viewport()
	return maxf(0.01, vp.get_final_transform().get_scale().x) if vp != null else 1.0

## Design size of the picture for a stretch: whole screen pixels per art pixel. Leans
## bigger (+0.25): a 2x slot is 2 screen px on both a 430 pt (1.71) and a 375 pt (1.49) phone.
static func side(px: int, w: float, sc: float) -> float:
	return px * screen_px(w, sc) / sc

static func screen_px(w: float, sc: float) -> int:
	return maxi(1, roundi(w * sc + 0.25))

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_fit()
		if not get_viewport().size_changed.is_connected(_fit):
			get_viewport().size_changed.connect(_fit)
	elif what == NOTIFICATION_EXIT_TREE:
		if get_viewport().size_changed.is_connected(_fit):
			get_viewport().size_changed.disconnect(_fit)

func _fit() -> void:
	custom_minimum_size = Vector2.ONE * side(art_px, want, stretch(self))
