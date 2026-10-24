class_name MerchantPopup
extends Overlay
## Snik the goblin trader (or a race's merchant in a realm camp): cheap gear,
## potions, a Return Scroll and a scroll, paid with the gold you carry. Snik also
## buys your junk. He only trades down in the dungeon.

var m
var state: GameState
var grid: VBoxContainer
var gold_label: Label
var say_label: Label   # what Snik just said

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	var who: String = state.merchant_who
	if who == "":
		open(m, "%s, the goblin trader" % GameData.GOBLIN_NAME, 640.0, Color("#a3e635"))
	else:
		open(m, "%s merchant" % who, 640.0, Color(Races.info(who)["color"]))
	var greet := UI.label(Snik.greeting(state) if who == "" else
		"\"Friends of the %s get our best prices. Friends get better ones.\" (They see you as %s.)" % [Lineage.race_plural(who), Races.rep_level(Lineage.rep(state, who))[0]], 13, UI.DIM)
	greet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(greet)
	if who == "":
		var mood := UI.label("Snik sees you as: %s  (%d purchases)" % [Snik.friendship_name(state), state.codex.stat("merchant_buys")], 12, Color("#a3e635"))
		content.add_child(mood)
	gold_label = UI.label("", UI.FONT_CAPTION, UI.GOLD)
	content.add_child(gold_label)
	say_label = UI.label("", UI.FONT_CAPTION, UI.TEXT)
	say_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(say_label)
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
		var t := UI.rich(UI.FONT_CAPTION)
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
			if e["kind"] == "potions":
				t.text = "[color=#f472b6][b]%d Health Potions[/b][/color]\nCheaper than in town." % int(e["amount"])
			else:
				t.text = "[color=#c4b5fd][b]%s[/b][/color]\n%s" % [GameState.SCROLLS[e["id"]]["name"], st.scroll_text(e["id"])]
			var ic := Sprites.consumable_icon("potion" if e["kind"] == "potions" else String(e["id"]))
			if ic != null:
				var cpic := ItemGrid.picture(40)
				cpic.texture = ic
				h.add_child(cpic)
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
	gold_label.text = "Gold you carry: %d" % state.gold
	if state.bag_full():
		gold_label.text += "    Your bag is full (%d / %d): sell, salvage or stash something to buy gear." % [state.bag.size(), state.bag_capacity()]
	var bought := state.codex.stat("merchant_buys")
	rows(m, grid, func():
		if state.codex.stat("merchant_buys") > bought:
			say_label.text = Snik.thanks(state) if state.merchant_who == "" else ""
		_fill()
		m.refresh())
	if state.merchant_who == "":
		# Haggling: once a visit
		var hb := UI.button("Haggle with Snik (%d%% chance)" % int(Snik.haggle_chance(state)) if Snik.can_haggle(state)
			else ("You talked him down: 20% off" if state.merchant_haggle == "won" else "He's still sulking: prices +10%"), func():
			var said := Snik.haggle(state)
			m.sfx.play("buy" if state.merchant_haggle == "won" else "error")
			say_label.text = "\"%s\"" % said
			_fill()
			m.refresh())
		hb.custom_minimum_size = Vector2(0, UI.TAP)
		hb.tooltip_text = "Once a visit. Win: 20% off everything. Lose: he marks it all up 10%."
		hb.disabled = not Snik.can_haggle(state)
		hb.add_theme_color_override("font_color", Color("#a3e635"))
		grid.add_child(hb)
		var junk := state.goblin_junk()
		var jb := UI.button("Sell junk to %s: %d item%s for %d gold" % [GameData.GOBLIN_NAME, junk.size(), "" if junk.size() == 1 else "s", state.goblin_junk_value()] if not junk.is_empty() else "No junk to sell (Common and Uncommon, unlocked)", func():
			if state.goblin_buy_junk() > 0:
				m.sfx.play("buy")
			_fill()
			m.refresh())
		jb.custom_minimum_size = Vector2(0, UI.TAP)
		jb.disabled = junk.is_empty()
		grid.add_child(jb)
