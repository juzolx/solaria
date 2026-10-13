class_name Wardrobe
extends Overlay
## Transmog: show any look you've found instead of the item you're wearing.
## Stats always come from the real item; this only changes how you look.

var main
var state: GameState
var preview: TextureRect
var pickers := {}  # slot -> [OptionButton, keys]

func show_for(m) -> void:
	main = m
	state = m.state
	open(m, "Wardrobe", 760.0)
	content.add_child(UI.label("Wear the look of anything you've found. Your stats still come from the gear you really wear.", 13, UI.DIM))
	var body := UI.hbox(16)
	content.add_child(body)
	var left := UI.panel(UI.INSET, UI.BORDER, 10, 10, 1)
	body.add_child(left)
	preview = TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(Sprites.PORTRAIT * 2, Sprites.PORTRAIT * 2)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left.add_child(preview)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for slot in GameData.SLOT_ORDER:
		var l := UI.label(slot, 13, UI.TEXT)
		l.custom_minimum_size = Vector2(80, 0)
		grid.add_child(l)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.fit_to_longest_item = false
		var keys := ["", "hide"]
		ob.add_item("Show what I'm wearing")
		ob.add_item("Hide this slot")
		var looks := []
		for key in state.wardrobe:
			var lk: Dictionary = state.wardrobe[key]
			if lk["slot"] == slot:
				looks.append([key, lk])
		looks.sort_custom(func(a, b): return int(a[1]["rarity"]) > int(b[1]["rarity"]))
		for entry in looks:
			ob.add_item(str(entry[1]["name"]))
			ob.set_item_icon(ob.item_count - 1, _dot(Color(GameData.color_of(int(entry[1]["rarity"])))))
			keys.append(entry[0])
		var current = state.transmog.get(slot, "")
		ob.select(maxi(0, keys.find(current)))
		ob.item_selected.connect(func(i: int): state.set_transmog(slot, keys[i]); _update())
		grid.add_child(ob)
		pickers[slot] = [ob, keys]
	content.add_child(UI.label("You've found %d looks. New ones are added as you find gear." % state.wardrobe.size(), 12, UI.DIM))
	_update()
	tree_exiting.connect(func(): main.refresh())

func _dot(c: Color) -> ImageTexture:
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func _update() -> void:
	preview.texture = Sprites.portrait(state.appearance, state.hero_looks())
