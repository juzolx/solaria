class_name ClinicTab
extends ScrollContainer
## Town > Clinic (only once you own a pet or an egg): choose who comes along, heal hurt pets with gold,
## or let them rest (they heal as you clear floors). Your pets live in its pen.

var main
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	name = "Clinic"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var g: GameState = main.state
	var key := "%s|%d|%s|%s" % [str(g.pets), g.gold, str(g.eggs), str(g.pets_out)]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	box.add_child(UI.heading("Clinic"))
	box.add_child(UI.wrap("The keeper looks after your pets between dives. A hurt pet heals by resting (%d cleared floors), or the keeper can patch it up now for gold. Pets are never lost." % Menagerie.HEAL_FLOORS, UI.FONT_CAPTION, UI.DIM))
	if not g.pets.is_empty():
		box.add_child(UI.label("COMING ALONG ON YOUR NEXT DIVE  %d / %d" % [Menagerie.out(g).size(), Menagerie.max_out(g)], 11, UI.GOLD))
	var any_hurt := false
	for p in g.pets:
		var hurt := int(p["hurt"]) > 0
		any_hurt = any_hurt or hurt
		var c := UI.card(UI.RED.darkened(0.3) if hurt else UI.GREEN.darkened(0.3))
		box.add_child(c[0])
		var h := UI.hbox(10)
		c[1].add_child(h)
		var pic := TextureRect.new()
		pic.texture = Menagerie.texture(p)
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.custom_minimum_size = Vector2(48, 48)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(pic)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(String(p["name"]), UI.FONT_CAPTION, UI.TEXT))
		v.add_child(UI.label(("Hurt: %d floor%s of rest left" % [int(p["hurt"]), "" if int(p["hurt"]) == 1 else "s"]) if hurt else "Healthy and ready", UI.FONT_CAPTION, UI.RED if hurt else UI.GREEN))
		if hurt:
			var cost := Menagerie.heal_cost(p)
			var id := int(p["id"])
			var b := UI.primary("Heal (%s gold)" % UI.short(cost), func():
				if Menagerie.heal(main.state, id):
					main.sfx.play("buy")
				shown = ""
				main.refresh(), UI.GREEN)
			b.disabled = g.gold < cost
			b.custom_minimum_size = Vector2(130, UI.TAP)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
		else:
			# 0.13+ (Juzo): pick who comes along right here
			var pid := int(p["id"])
			var going: bool = pid in g.pets_out
			var full := Menagerie.out(g).size() >= Menagerie.max_out(g)
			var eb := UI.primary("Coming along" if going else ("Swap in" if full else "Bring along"), func():
				if Menagerie.toggle_out(main.state, pid):
					main.sfx.play("click")
					main.state.save_game()
				shown = ""
				main.refresh(), UI.GREEN if going else UI.GOLD)
			eb.custom_minimum_size = Vector2(130, UI.TAP)
			eb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			eb.tooltip_text = "Tap to leave it at home" if going else "Tap to bring it on your next dive"
			h.add_child(eb)
	if g.pets.is_empty():
		box.add_child(UI.wrap("No pets yet. The pen is ready for whatever hatches.", UI.FONT_CAPTION, UI.DIM))
	elif not any_hurt:
		box.add_child(UI.wrap("Everyone is healthy.", UI.FONT_CAPTION, UI.DIM))
