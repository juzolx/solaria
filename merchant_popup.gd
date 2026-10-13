class_name MerchantPopup
extends Overlay
## The wandering merchant: Epic and Legendary gear, a mystery box and rare
## scrolls. He stays (in Town > Shop) until you beat the next boss.

var m
var state: GameState
var grid: VBoxContainer
var gold_label: Label

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	var who: String = state.merchant_who
	if who == "":
		open(m, "The wandering merchant", 640.0, UI.GOLD)
	else:
		open(m, "%s merchant" % who, 640.0, Color(Races.info(who)["color"]))
	var greet := UI.label("\"Rare goods for a rare customer. I'll wait for you until the next big fight.\"" if who == "" else
		"\"Friends of the %s get our best prices. Friends get better ones.\" (They see you as %s.)" % [Lineage.race_plural(who), Races.rep_level(Lineage.rep(state, who))[0]], 13, UI.DIM)
	greet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(greet)
	gold_label = UI.label("", 14, UI.GOLD)
	content.add_child(gold_label)
	grid = UI.vbox(6)
	content.add_child(grid)
	_fill()
	m.timer.paused = true
	tree_exiting.connect(func(): m.timer.paused = false)

## The merchant's goods as rows (also used by the Shop tab).
static func rows(main_node, parent: Control, on_change: Callable) -> void:
	var st: GameState = main_node.state
	for i in st.merchant.size():
		var e: Dictionary = st.merchant[i]
		var row := UI.panel(UI.INSET, UI.BORDER, 8, 8, 1)
		parent.add_child(row)
		var h := UI.hbox(10)
		row.add_child(h)
		var t := UI.rich(13)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if e["kind"] == "item":
			var item: Dictionary = e["item"]
			t.text = ItemText.describe(st, item)
			t.tooltip_text = ItemText.tip(st, item)
			var pic := TextureRect.new()
			pic.texture = Sprites.item_icon(item)
			pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			pic.custom_minimum_size = Vector2(40, 40)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.add_child(pic)
		else:
			t.text = "[color=#c4b5fd][b]%s[/b][/color]\n%s" % [GameState.SCROLLS[e["id"]]["name"], st.scroll_text(e["id"])]
		h.add_child(t)
		# Say why you can't buy it instead of a button that does nothing
		var need := int(e["price"]) - st.gold
		var full: bool = e["kind"] == "item" and st.bag_full()
		var label := "Sold" if e["sold"] else ("Bag full" if full else ("Need %d more" % need if need > 0 else "%d gold" % int(e["price"])))
		var b := UI.primary(label, func():
			if st.buy_merchant(i):
				main_node.sfx.play("buy")
			on_change.call(), UI.GOLD)
		b.custom_minimum_size = Vector2(120, 40)
		b.tooltip_text = "%d gold" % int(e["price"])
		b.disabled = e["sold"] or need > 0 or full
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)

func _fill() -> void:
	OnlineUI.clear(grid)
	gold_label.text = "Your gold: %d" % state.gold
	if state.bag_full():
		gold_label.text += "    Your bag is full (%d / %d): sell, salvage or stash something to buy gear." % [state.bag.size(), state.bag_capacity()]
	rows(m, grid, func(): _fill(); m.refresh())
