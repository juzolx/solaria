class_name ChurchTab
extends ScrollContainer
## Town > Church (2.1 G2): lift curses from Cursed gear (it keeps its hidden power)
## and bless gear (+3% to its stat while worn). Works on what you wear and carry.

var main
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	name = "Church"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var g: GameState = main.state
	var key := "%d|%d|%d|%d|%d" % [g.bag_version, g.gold, g.dust, Buildings.level("church"), g.equipped.size()]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	box.add_child(UI.heading("Church"))
	box.add_child(UI.wrap("Some gear comes up from the deep Cursed: stronger than it should be, with a downside and a hidden power. The priest can lift the curse (the power stays) or bless a clean piece.", 12, UI.DIM))
	var cursed: Array = []
	var clean: Array = []
	for it in Church.items_here(g):
		if Church.is_cursed(it):
			cursed.append(it)
		elif Church.can_bless(it):
			clean.append(it)
	box.add_child(UI.label("CURSED GEAR", 11, Color(Church.COLOR)))
	if cursed.is_empty():
		box.add_child(UI.wrap("Nothing you wear or carry is cursed.", 12, UI.DIM))
	for it in cursed:
		_row(g, it, true)
	box.add_child(UI.label("BLESS YOUR GEAR  (once per item)", 11, UI.GOLD))
	if clean.is_empty():
		box.add_child(UI.wrap("Nothing here to bless.", 12, UI.DIM))
	var n := 0
	for it in clean:
		_row(g, it, false)
		n += 1
		if n >= 12:
			break

func _row(g: GameState, it: Dictionary, curse: bool) -> void:
	var c := UI.card(Color(Church.COLOR).darkened(0.3) if curse else UI.BORDER)
	box.add_child(c[0])
	var h := UI.hbox(10)
	c[1].add_child(h)
	h.add_child(ItemGrid.cell(it, Callable(), false, 48))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var r := UI.rich(12)
	r.text = "[color=%s]%s[/color]%s" % [GameData.color_of(int(it["rarity"])), GameData.display_name(it), Church.describe(it)]
	v.add_child(r)
	var id := int(it["id"])
	var b: Button
	if curse:
		v.add_child(UI.label("Works %d%% of the time  ·  %d gold + %d dust" % [Church.cleanse_chance(it), Church.cleanse_gold(it), Church.cleanse_dust(it)], 11, UI.DIM))
		b = UI.primary("Lift curse", func(): _act(id, true), Color(Church.COLOR))
		b.disabled = Church.cleanse_short(g, it) != ""
	else:
		v.add_child(UI.label("%d gold + %d dust" % [Church.bless_gold(it), Church.bless_dust()], 11, UI.DIM))
		b = UI.primary("Bless", func(): _act(id, false), UI.GOLD)
		b.disabled = Church.bless_short(g, it) != ""
	b.custom_minimum_size = Vector2(110, UI.TAP)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)

func _act(id: int, curse: bool) -> void:
	var g: GameState = main.state
	for it in Church.items_here(g):
		if int(it["id"]) == id:
			if curse:
				main.sfx.play("heal" if Church.cleanse(g, it) else "click")
			elif Church.bless(g, it):
				main.sfx.play("buy")
			break
	shown = ""
	main.refresh()
