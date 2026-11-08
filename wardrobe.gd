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
	# QA r1 A3: the words wrap and a phone stacks the preview over the slots (it was 952 px wide)
	content.add_child(UI.wrap("Wear the look of anything you've found. Your stats still come from the gear you really wear.", UI.FONT_BODY, UI.DIM))
	var body := BoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.vertical = is_narrow()
	content.add_child(body)
	var left := UI.panel(UI.INSET, UI.BORDER, 10, 10, 1)
	left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(left)
	preview = TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(Sprites.PORTRAIT * 3, Sprites.PORTRAIT * 3)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left.add_child(preview)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for slot in GearSlots.LOOK_SLOTS:  # 2.1: rings and necklaces have no look (yet)
		var l := UI.label(slot, UI.FONT_BODY, UI.TEXT)
		l.custom_minimum_size = Vector2(80, 0)
		grid.add_child(l)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.fit_to_longest_item = false
		ob.clip_text = true   # a long look name ends in "…" instead of widening the popup
		ob.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	content.add_child(UI.wrap("You've found %d looks. New ones are added as you find gear." % state.wardrobe.size(), UI.FONT_BODY, UI.DIM))
	_update()
	tree_exiting.connect(func(): main.refresh())

func _dot(c: Color) -> ImageTexture:
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func _update() -> void:
	preview.texture = Sprites.portrait(state.appearance, state.hero_looks())
