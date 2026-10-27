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
	"Tap a gear slot on your hero to change what you wear.",
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
	# Interface pass: the dungeon room of your hero's floor, dimmed, behind the sun (the first boot,
	# with no hero yet, keeps the plain splash)
	var main := get_parent()
	var prof = main.get("profile") if main else null
	var meta: Dictionary = GameState.slot_meta(prof.active_slot) if prof != null else {}
	if not meta.is_empty():
		var halls := HallsScene.new()
		var st := GameState.new()
		st.floor_num = maxi(1, int(meta.get("floor", 1)))
		var room := Control.new()
		room.size = size
		room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		room.modulate = Color(0.62, 0.58, 0.68)
		room.draw.connect(func():
			halls.build(st, size)
			halls.draw_shell(room, size)
			halls.draw_doors(room, null, {}, UI.game_font())
			halls.vignette(room, size))
		cover.add_child(room)
	var sun := TextureRect.new()
	sun.texture = load("res://splash.png")
	if not meta.is_empty():   # the splash's flat backdrop goes clear so the room shows round the sun
		var si: Image = sun.texture.get_image()
		si.convert(Image.FORMAT_RGBA8)
		var bgc := si.get_pixel(0, 0)
		for y in si.get_height():
			for x in si.get_width():
				if si.get_pixel(x, y).is_equal_approx(bgc):
					si.set_pixel(x, y, Color(0, 0, 0, 0))
		sun.texture = ImageTexture.create_from_image(si)
	sun.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sun.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sun.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sun.size = size
	cover.add_child(sun)
	var plate := PanelContainer.new()   # the tip on a framed plate (the design system)
	plate.add_theme_stylebox_override("panel", UiSkin.frame(Color(UI.PANEL, 0.92), UiSkin.IRON, 12))
	plate.position = Vector2(24, size.y * 0.76)
	plate.size = Vector2(size.x - 48, 0)
	plate.custom_minimum_size = Vector2(size.x - 48, 0)
	cover.add_child(plate)
	var pv := UI.vbox(4)
	plate.add_child(pv)
	var head := UI.label("◆ TIP", UI.FONT_BODY, UI.GOLD_DULL)
	pv.add_child(head)
	var tip := UI.wrap(TIPS.pick_random(), UI.FONT_BODY, UI.TEXT)
	pv.add_child(tip)
	var t2 := create_tween()
	t2.tween_interval(0.35)
	t2.tween_property(cover, "modulate:a", 0.0, 0.45)
	t2.tween_callback(queue_free)
