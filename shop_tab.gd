class_name ShopTab
extends ScrollContainer
## Town › Shop: Marta's Goods. A featured deal, gear on the shelves as
## item squares, supplies (potions and elixirs), upgrades, and quick selling.

const GREETINGS := [
	"\"Finest gear this side of the abyss. Mostly.\"",
	"\"Back from the deep? Your gold's still good here.\"",
	"\"Fresh stock! Some of it barely cursed.\"",
	"\"Everything's for sale. Except my hat.\"",
	"\"Bosses drop the good stuff. I just sell it back to you.\"",
]

var main
var state: GameState
var gold_label: RichTextLabel
var greeting: RichTextLabel
var featured_box: PanelContainer
var featured_style: StyleBoxFlat
var featured_text: RichTextLabel
var featured_buy: Button
var featured_pic: TextureRect
var featured_cmp: RichTextLabel
var restock_button: Button
var gear_grid: GridContainer
var gear_buttons := []   # [button, shop index, price]
var supplies := {}       # id -> [button, label]
var bag_button: Button
var bag_text: RichTextLabel
var quick_sell := {}
var shown := -1
var wander_box: VBoxContainer
var wander_shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Shop"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)

	# ---- Merchant ----
	var merchant := _frame(UiSkin.IRON)   # interface pass (approved mockup 12): the panel frame
	v.add_child(merchant)
	merchant.visible = false   # Fable r4 #9: Marta speaks once (the header line); the bar above says "Shop"
	var mrow := UI.hbox(10)
	merchant.add_child(mrow)
	var mcol := UI.vbox(2)
	mcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mrow.add_child(mcol)
	mcol.add_child(UI.label(GameData.MERCHANT_NAME, UI.FONT_BODY, UI.GOLD))
	greeting = UI.rich(UI.FONT_BODY)
	mcol.add_child(greeting)
	gold_label = UI.rich(UI.FONT_BODY)
	gold_label.custom_minimum_size = Vector2(120, 0)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mrow.add_child(gold_label)
	gold_label.visible = false   # Fable r1 #9: the top bar already shows your gold

	# ---- Wandering merchant (only after you met him at a fork) ----
	wander_box = UI.vbox(6)
	v.add_child(wander_box)

	# ---- Featured deal ----
	v.add_child(UI.heading("Featured deal", "New stock every time you come home."))
	featured_box = PanelContainer.new()
	featured_style = UI.style(UI.INSET, UI.GOLD, 10, 12, 2)
	featured_box.add_theme_stylebox_override("panel", featured_style)
	v.add_child(featured_box)
	# Fable r1 #9: [picture | name + stat line], one compare line, then a full-width Buy;
	# the flavour and the long compare are a tap away (the tip on the box)
	var fcol := UI.vbox(8)
	featured_box.add_child(fcol)
	UI.tip(featured_box, "")
	var frow := UI.hbox(12)
	fcol.add_child(frow)
	featured_pic = ItemGrid.picture(76)
	featured_pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED   # whole pixels
	featured_pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(featured_pic)
	featured_text = UI.rich(UI.FONT_BODY)
	featured_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	featured_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(featured_text)
	featured_cmp = UI.rich(UI.FONT_BODY)
	fcol.add_child(featured_cmp)
	featured_buy = UI.primary("", func():
		if state.buy_featured():
			main.sfx.play("buy")
		main.refresh(), UI.GOLD)
	featured_buy.custom_minimum_size = Vector2(0, UI.TAP)
	featured_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fcol.add_child(featured_buy)

	# ---- Gear shelf ----
	var ghead := UI.hbox(8)
	v.add_child(ghead)
	var gh := UI.heading("Gear on the shelves")
	gh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ghead.add_child(gh)
	restock_button = UI.button("", func(): state.paid_restock(); main.refresh())
	restock_button.tooltip_text = "Pay to get a whole new shelf of gear (and a new featured deal)"
	ghead.add_child(restock_button)
	gear_grid = GridContainer.new()
	gear_grid.columns = 1   # grows to 2-3 on wide screens (resized below)
	gear_grid.resized.connect(func():   # UX pass: two cards across on a phone, so 15 px text fits
		var cols := 3 if gear_grid.size.x >= 760.0 else (2 if gear_grid.size.x >= 600.0 else 1)   # Fable r1: one card a row on phones (body-20 text)
		if gear_grid.columns != cols:
			gear_grid.columns = cols)
	gear_grid.add_theme_constant_override("h_separation", 6)
	gear_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(gear_grid)

	# ---- Supplies ----
	v.add_child(UI.heading("Supplies"))
	var sgrid := GridContainer.new()
	sgrid.columns = 1   # Fable r1: one card a row on phones; two on wide screens
	sgrid.resized.connect(func():
		var sc := 2 if sgrid.size.x >= 600.0 else 1
		if sgrid.columns != sc:
			sgrid.columns = sc)
	sgrid.add_theme_constant_override("h_separation", 8)
	sgrid.add_theme_constant_override("v_separation", 8)
	v.add_child(sgrid)
	_supply_card(sgrid, "potion", "Health Potion", "Heals 40% HP. Drunk automatically when HP is low (Auto-heal).", UI.PINK,
		func(): state.buy_potion(); main.sfx.play("buy"); main.refresh())
	_supply_card(sgrid, "greater", "Greater Potion", "Drink now: heals you to full.", UI.PINK,
		func(): state.buy_greater_potion(); main.sfx.play("potion"); main.refresh())
	for id in GameData.ELIXIR_ORDER:
		var info: Dictionary = GameData.ELIXIRS[id]
		_supply_card(sgrid, id, info["name"], info["text"] + ". Starts right away.", UI.PURPLE,
			func(): state.buy_elixir(id); main.sfx.play("buy"); main.refresh())

	# ---- Upgrades ----
	v.add_child(UI.heading("Upgrades"))
	var bag_card := _frame(UiSkin.IRON)
	v.add_child(bag_card)
	var brow := UI.hbox(10)
	bag_card.add_child(brow)
	bag_text = UI.rich(UI.FONT_BODY)
	bag_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(bag_text)
	bag_button = UI.primary("", func(): state.buy_bag_upgrade(); main.sfx.play("buy"); main.refresh())
	bag_button.custom_minimum_size = Vector2(130, UI.BUTTON_H)
	bag_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brow.add_child(bag_button)

	# ---- Quick sell ----
	v.add_child(UI.heading("Quick sell  -  locked items and upgrades are kept"))
	var qrow := UI.hbox(8)
	v.add_child(qrow)
	for r in [0, 1, 2]:
		var b := UI.button("", func():
			state.sell_all(r)
			main.sfx.play("sell")
			main.refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_color_override("font_color", Color(GameData.color_of(r)))
		qrow.add_child(b)
		quick_sell[r] = b

func _supply_card(parent: Control, id: String, title: String, text: String, color: Color, on_buy: Callable) -> void:
	var card := _frame(UiSkin.IRON)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var cv := UI.vbox(4)
	card.add_child(cv)
	var top := UI.hbox(6)
	cv.add_child(top)
	var ic := Sprites.consumable_icon(id)
	if ic != null:
		var pic := ItemGrid.picture(maxi(28, ic.get_width()))   # QA r1 C1: 32 px art at 1x, not squeezed into 28
		pic.texture = ic
		top.add_child(pic)
	var tl := UI.label(title, UI.FONT_BODY, color)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(tl)
	var lbl := UI.rich(UI.FONT_BODY)
	lbl.custom_minimum_size = Vector2(0, 32)
	lbl.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), text]
	cv.add_child(lbl)
	var b := UI.button("", on_buy)
	cv.add_child(b)
	supplies[id] = [b, lbl, text]

## One item square on the shelf.
func _gear_card(item: Dictionary, index: int) -> void:
	var r := int(item["rarity"])
	var color := Color(GameData.color_of(r))
	var card := _frame(color)   # the shelf card's line is the item's rarity colour
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 196)
	card.tooltip_text = ItemText.plain(item)
	gear_grid.add_child(card)
	var cv := UI.vbox(3)
	card.add_child(cv)
	var top := UI.hbox(6)
	cv.add_child(top)
	var pic := ItemGrid.picture(44)
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED   # whole pixels
	pic.texture = UiIcons.big(Sprites.item_icon(item), 44)
	top.add_child(pic)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	# three cards across a phone: these two lines shorten with "..." rather than widen the screen
	for l in [UI.label(GameData.RARITY_NAMES[r], UI.FONT_BODY, color), UI.label(item["slot"], UI.FONT_BODY, UI.DIM)]:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
		tv.add_child(l)
	var nm := UI.label(GameData.display_name(item), UI.FONT_BODY, color.lightened(0.15))
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(0, 38)
	cv.add_child(nm)
	var stat := UI.rich(UI.FONT_BODY)
	var d := ItemText.delta(state, item)
	var dcol := UI.GREEN if d.begins_with("(+") else (UI.RED if d.begins_with("(-") else UI.DIM)
	stat.text = "+%d %s  [color=%s]%s[/color]" % [GameData.item_power(item), item["stat"], UI.hex(dcol), d]
	cv.add_child(stat)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(fill)
	var price := state.shop_cost(item)
	var b := UI.primary(UI.cost("Buy", price), func():
		if state.buy_shop(index):
			main.sfx.play("buy")
		main.refresh(), UI.GOLD)
	cv.add_child(b)
	gear_buttons.append([b, index, price])

func _rebuild_shelf() -> void:
	for c in gear_grid.get_children():
		c.queue_free()
	gear_buttons.clear()
	for i in state.shop.size():
		_gear_card(state.shop[i], i)
	if state.shop.is_empty():
		var empty := UI.label("The shelves are empty. New stock after the next boss.", UI.FONT_BODY, UI.DIM)
		gear_grid.add_child(empty)

func _refresh_wanderer() -> void:
	var key := str(state.merchant.size()) + str(state.gold) + str(state.merchant.map(func(e): return e["sold"]))
	if key == wander_shown:
		return
	wander_shown = key
	OnlineUI.clear(wander_box)
	# Snik only trades down in the dungeon; race merchants still follow you to town
	if state.merchant.is_empty() or state.merchant_who == "":
		return
	wander_box.add_child(UI.heading("%s merchant  -  leaves after the next boss" % state.merchant_who))
	MerchantPopup.rows(main, wander_box, func(): wander_shown = ""; main.refresh())

func refresh() -> void:
	_refresh_wanderer()
	gold_label.text = "[right][color=%s]Your gold[/color]\n[font_size=20][color=#e8b14a]%d[/color][/font_size][/right]" % [UI.hex(UI.DIM), state.gold]
	if state.shop_version != shown:
		shown = state.shop_version
		greeting.text = "[i][color=%s]%s[/color][/i]" % [UI.hex(UI.DIM), GREETINGS[state.shop_version % GREETINGS.size()]]
		_rebuild_shelf()

	# Featured
	if state.featured.is_empty():
		featured_style.border_color = UI.EMPTY
		featured_text.text = "[color=%s]Sold out! A new featured deal arrives after the next boss.[/color]" % UI.hex(UI.DIM)
		featured_buy.visible = false
		featured_cmp.visible = false
		featured_box.tooltip_text = ""
		featured_pic.texture = null
	else:
		var f := state.featured
		featured_pic.texture = UiIcons.big(Sprites.item_icon(f), 76)
		featured_style.border_color = Color(GameData.color_of(f["rarity"]))
		featured_text.text = ItemText.headline(f)
		featured_cmp.visible = true
		featured_cmp.text = ItemText.short_compare(state, f)
		featured_box.tooltip_text = ItemText.tip(state, f)
		featured_buy.visible = true
		featured_buy.text = "Bag full" if state.bag_full() else UI.cost("Buy", state.featured_price())   # QA r1 B1
		UI.why(featured_buy, "Your bag is full." if state.bag_full() else UI.need_gold(state.gold, state.featured_price()))

	for entry in gear_buttons:
		var b: Button = entry[0]
		UI.why(b, "Your bag is full." if state.bag_full() else UI.need_gold(state.gold, int(entry[2])))
		b.text = "Bag full" if state.bag_full() else UI.cost("Buy", int(entry[2]))
	restock_button.text = UI.cost("Restock", state.restock_cost())
	UI.why(restock_button, UI.need_gold(state.gold, state.restock_cost()))

	# Supplies
	var potion: Array = supplies["potion"]
	(potion[0] as Button).text = UI.cost("Buy", state.potion_cost()) + " · have %d" % state.potions
	UI.why(potion[0], UI.need_gold(state.gold, state.potion_cost()))
	var greater: Array = supplies["greater"]
	(greater[0] as Button).text = UI.cost("Buy & drink", state.greater_potion_cost())
	UI.why(greater[0], "You're at full health." if state.hero_hp >= state.get_max_hp() else UI.need_gold(state.gold, state.greater_potion_cost()))
	for id in GameData.ELIXIR_ORDER:
		var info: Dictionary = GameData.ELIXIRS[id]
		var entry: Array = supplies[id]
		var active := int(state.elixirs.get(id, 0))
		(entry[1] as RichTextLabel).text = "[color=%s]%s[/color]\n[color=#c4b5fd]At home: %d   Carried: %d[/color]%s" % [UI.hex(UI.DIM), entry[2], state.supply_home(id), state.supply_carried(id),
			("\n[color=#c4b5fd]Active: %d turns left[/color]" % active) if active > 0 else ""]
		(entry[0] as Button).text = UI.cost("Buy", state.elixir_cost(id))
		UI.why(entry[0], UI.need_gold(state.gold, state.elixir_cost(id)))

	# Bag
	if state.bag_level >= GameData.BAG_MAX_LEVEL:
		bag_text.text = "[b]Bigger Bag[/b]\n[color=%s]Fully upgraded: %d slots.[/color]" % [UI.hex(UI.DIM), state.bag_capacity()]
		bag_button.text = "Maxed"
		UI.why(bag_button, "Your bag is as big as it gets.")
	else:
		var cost := state.next_bag_cost()
		bag_text.text = "[b]Bigger Bag[/b]  [color=%s]level %d / %d[/color]\n%d -> [color=#4ade80]%d slots[/color]  [color=%s](or craft one with scrap at the Blacksmith)[/color]" % [
			UI.hex(UI.DIM), state.bag_level, GameData.BAG_MAX_LEVEL, state.bag_capacity(), state.bag_capacity() + GameData.BAG_STEP, UI.hex(UI.DIM)]
		bag_button.text = UI.cost("Buy", cost)
		UI.why(bag_button, UI.need_gold(state.gold, cost))

	# Quick sell
	for r in quick_sell:
		var n := state.salvage_all_count(r)
		var total := 0
		for item in state.bag:
			if int(item["rarity"]) == r and not item.get("locked", false) and not state.is_upgrade(item):
				total += state.sell_price(item)
		var b: Button = quick_sell[r]
		b.text = "%s (%d)\n+%s gold" % [GameData.RARITY_NAMES[r], n, UI.gold(total)]   # two lines: three across must fit a phone
		UI.why(b, "Nothing of that rarity to sell." if n == 0 else "")

## Interface pass: a shop card wears the panel frame, its line in `edge`.
func _frame(edge: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, edge, 10))
	return p
