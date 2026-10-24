class_name ChurchTab
extends ScrollContainer
## Town > Church (2.1 G2): lift curses from Cursed gear (it keeps its hidden power)
## and bless gear (+3% to its stat while worn). Works on what you wear and carry.
## A failed cleanse updates its row in place, so the button stays put for another try.

var main
var box: VBoxContainer
var shown := ""
var rows := {}  # item id -> {"text": RichTextLabel, "cost": Label, "button": Button}

func setup(m) -> void:
	main = m
	name = "Church"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func _key(g: GameState) -> String:
	return "%d|%d|%d|%d|%d" % [g.bag_version, g.gold, g.dust, Buildings.level("church"), g.equipped.size()]

func refresh() -> void:
	var g: GameState = main.state
	var key := _key(g)
	if key == shown:
		return
	shown = key
	rows.clear()
	OnlineUI.clear(box)
	box.add_child(UI.heading("Church"))
	if not Buildings.built("church"):
		box.add_child(UI.wrap("An empty lot by the graveyard. Build the Church (above) and its priest will lift curses from your gear and bless it.", UI.FONT_CAPTION, UI.DIM))
		return
	box.add_child(UI.wrap("Some gear comes up from the deep Cursed: stronger than it should be, with a downside and a hidden power. The priest can lift the curse (the power stays) or bless a clean piece.", UI.FONT_CAPTION, UI.DIM))
	var cursed: Array = []
	var clean: Array = []
	for it in Church.items_here(g):
		if Church.is_cursed(it):
			cursed.append(it)
		elif Church.can_bless(it):
			clean.append(it)
	box.add_child(UI.label("CURSED GEAR", UI.FONT_CAPTION, Color(Church.COLOR)))
	if cursed.is_empty():
		box.add_child(UI.wrap("Nothing you wear or carry is cursed.", UI.FONT_CAPTION, UI.DIM))
	for it in cursed:
		_row(g, it, true)
	box.add_child(UI.label("BLESS YOUR GEAR  (once per item)", UI.FONT_CAPTION, UI.GOLD))
	if clean.is_empty():
		box.add_child(UI.wrap("Nothing here to bless.", UI.FONT_CAPTION, UI.DIM))
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
	var r := UI.rich(UI.FONT_CAPTION)
	v.add_child(r)
	var cost := UI.label("", UI.FONT_CAPTION, UI.DIM)
	v.add_child(cost)
	var id := int(it["id"])
	var b: Button
	if curse:
		b = UI.primary("Lift curse", func(): _act(id, true), Color(Church.COLOR))
	else:
		b = UI.primary("Bless", func(): _act(id, false), UI.GOLD)
	b.custom_minimum_size = Vector2(110, UI.TAP)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	rows[id] = {"text": r, "cost": cost, "button": b}
	_fill(g, it, curse)

## Writes a row's text, price and button state (also after a failed try, in place).
func _fill(g: GameState, it: Dictionary, curse: bool) -> void:
	var row: Dictionary = rows.get(int(it["id"]), {})
	if row.is_empty():
		return
	(row["text"] as RichTextLabel).text = "[color=%s]%s[/color]%s" % [GameData.color_of(int(it["rarity"])), GameData.display_name(it), Church.describe(it)]
	if curse:
		(row["cost"] as Label).text = "Works %d%% of the time  ·  %d gold + %d dust" % [Church.cleanse_chance(it), Church.cleanse_gold(it), Church.cleanse_dust(it)]
		(row["button"] as Button).disabled = Church.cleanse_short(g, it) != ""
	else:
		(row["cost"] as Label).text = "%d gold + %d dust" % [Church.bless_gold(it), Church.bless_dust()]
		(row["button"] as Button).disabled = Church.bless_short(g, it) != ""

func _act(id: int, curse: bool) -> void:
	var g: GameState = main.state
	for it in Church.items_here(g):
		if int(it["id"]) != id:
			continue
		if curse:
			if Church.cleanse(g, it):
				main.sfx.play("heal")
				shown = ""  # it's clean now: rebuild the lists
			else:
				main.sfx.play("click")
				# Juzo: the curse held. Keep the button right where it is, ready for another try.
				for other in Church.items_here(g):
					if rows.has(int(other["id"])):
						_fill(g, other, Church.is_cursed(other))
				shown = _key(g)
		elif Church.bless(g, it):
			main.sfx.play("buy")
			shown = ""
		break
	main.refresh()
