class_name LoadingScreen
extends CanvasLayer
## Next update (Juzo): a loading screen. It covers the screen while the game
## builds itself (start-up, back to the title, switching towns), with the sun
## from the splash, a torchlit flicker and a tip, then fades away.

static var enabled := true   # tests turn it off so screenshots aren't covered
const TIPS := [
	"Getting home alive is the win. Everything you carry is at risk until you do.",
	"Heroes left at home find gold and scrap while you dive.",
	"Lock your favorite items so you never sell them by accident.",
	"Pets are a real find. Look after the eggs you get.",
	"A shimmer in the air might be a rift. Its depth tells you how far down it goes.",
	"Travelers in the dungeon have things to offer, if you can pay.",
	"Drag gear onto your hero to wear it.",
	"Each town keeps its own heroes, stash and skill book.",
]

var cover: ColorRect

func _ready() -> void:
	layer = 120
	cover = ColorRect.new()
	cover.color = Color(0.043, 0.031, 0.071)  # the boot splash color, so it carries straight on from it
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	var size := get_viewport().get_visible_rect().size
	cover.size = size
	var sun := TextureRect.new()
	sun.texture = load("res://splash.png")
	sun.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sun.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sun.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sun.size = size
	cover.add_child(sun)
	var tip := UI.wrap(TIPS.pick_random(), 13, UI.DIM)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.position = Vector2(24, size.y * 0.78)
	tip.size = Vector2(size.x - 48, 60)
	cover.add_child(tip)
	var t2 := create_tween()
	t2.tween_interval(0.35)
	t2.tween_property(cover, "modulate:a", 0.0, 0.45)
	t2.tween_callback(queue_free)
