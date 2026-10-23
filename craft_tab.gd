class_name CraftTab
extends ScrollContainer
## Town > Craft. Laid out so it's always clear what you have and what you need:
## 1) your scrap and dust, 2) basics (potion, bag), 3) set recipes, 4) mystery gear.

var main
var state: GameState
var mats_row: HFlowContainer
var potion_cost: RichTextLabel
var potion_button: Button
var bag_info: RichTextLabel
var bag_cost: RichTextLabel
var bag_button: Button
var set_info := {}     # set id -> [header label, cost label, wearing label]
var set_buttons := {}  # set -> Array of buttons
var piece_rows: Array = []  # one row of set-piece buttons per set (stacked on phones)
var gear_buttons := {}
var gear_cost: RichTextLabel
var smith_pic: TextureRect
var section_buttons := {}
var forge_box: VBoxContainer
var sets_box: VBoxContainer
var wares_box: VBoxContainer
var section := "forge"
var wares_key := ""
var wares_list: VBoxContainer

func setup(m) -> void:
	main = m
	state = m.state
	name = "Craft"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)
	# 0.13+ (Juzo): Hilde Ironbraid, the dwarf smith, and her three counters
	var who := UI.hbox(10)
	v.add_child(who)
	smith_pic = TextureRect.new()
	smith_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	smith_pic.custom_minimum_size = Vector2(56, 56)
	smith_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	smith_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	who.add_child(smith_pic)
	who.add_child(UI.wrap("%s, dwarf smith of the town forge" % Smith.NAME, 14, UI.GOLD))
	var tabs_row := UI.hbox(6)
	v.add_child(tabs_row)
	for sec in [["forge", "Forge"], ["sets", "Set Recipes"], ["wares", "Dwarf's Wares"]]:
		var sb := UI.button(String(sec[1]), _show_section.bind(String(sec[0])))
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.custom_minimum_size = Vector2(0, UI.TAP)
		tabs_row.add_child(sb)
		section_buttons[String(sec[0])] = sb
	var root_v := v
	forge_box = UI.vbox(10)
	sets_box = UI.vbox(10)
	wares_box = UI.vbox(10)

	# ---- 1. What you have ----
	v.add_child(UI.heading("Your scrap and dust  -  scrap comes from salvaging, dust from bosses, rare monsters and maxed skills"))
	mats_row = HFlowContainer.new()
	mats_row.add_theme_constant_override("h_separation", 6)
	mats_row.add_theme_constant_override("v_separation", 6)
	v.add_child(mats_row)

	for bx in [forge_box, sets_box, wares_box]:
		root_v.add_child(bx)
	v = forge_box
	# ---- 2. Basics ----
	v.add_child(UI.heading("Basics"))
	var basics := UI.hbox(8)
	v.add_child(basics)
	var pcard := _recipe_card(basics, "Health Potion", UI.PINK, "Heals 40% HP. Drunk automatically when your HP is low.")
	potion_cost = pcard[0]
	potion_button = UI.primary("Craft", func(): state.craft_potion(); main.sfx.play("craft"); main.refresh(), UI.PINK)
	pcard[1].add_child(potion_button)
	var bcard := _recipe_card(basics, "Bigger Bag", UI.BLUE, "")
	bag_info = bcard[2]
	bag_cost = bcard[0]
	bag_button = UI.primary("Craft", func(): state.craft_bag(); main.sfx.play("craft"); main.refresh(), UI.BLUE)
	bcard[1].add_child(bag_button)

	v = sets_box
	# ---- 3. Set recipes ----
	v.add_child(UI.heading("Set recipes  -  wear 2 or 3 pieces of a set for bonuses"))
	for set_name in GameData.SET_ORDER:
		var info: Dictionary = GameData.SETS[set_name]
		var card := UI.panel(UI.INSET, Color(UI.TEAL, 0.45), 8, 10, 2)
		v.add_child(card)
		var cv := UI.vbox(5)
		card.add_child(cv)
		var head := UI.hbox(8)
		cv.add_child(head)
		var title := UI.label(String(info["name"]), 15, UI.TEAL)
		head.add_child(title)
		head.add_child(UI.spacer())
		var wearing := UI.label("", 12, UI.DIM)
		head.add_child(wearing)
		var bonus := UI.rich(12)
		bonus.text = "[color=%s]Bonus:[/color] %s" % [UI.hex(UI.DIM), info["text"]]
		cv.add_child(bonus)
		var cost := UI.rich(12)
		cv.add_child(cost)
		var row := BoxContainer.new()  # side by side, or stacked on phones (refresh)
		row.add_theme_constant_override("separation", 6)
		cv.add_child(row)
		piece_rows.append(row)
		var buttons := []
		for slot in info["pieces"]:
			var b := UI.button("", _craft_set.bind(set_name, slot))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			b.custom_minimum_size = Vector2(60, 56)
			b.add_theme_color_override("font_color", Color("#99f6e4"))
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.expand_icon = false
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(b)
			buttons.append([b, slot])
		set_info[set_name] = [title, cost, wearing]
		set_buttons[set_name] = buttons

	v = forge_box
	# ---- 4. Mystery gear ----
	v.add_child(UI.heading("Mystery gear  -  pick a slot, get a random item with better odds"))
	gear_cost = UI.rich(12)
	v.add_child(gear_cost)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for slot in GameData.SLOT_ORDER:
		var b := UI.button(slot, func(): state.craft_gear(slot); main.sfx.play("craft"); main.refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		gear_buttons[slot] = b

	# ---- Dwarf's wares ----
	wares_box.add_child(UI.heading("Dwarf's Wares  -  forged for your depth, never below your average Gear Score; new pieces each time you come home"))
	wares_list = UI.vbox(6)
	wares_box.add_child(wares_list)
	_show_section("forge")

## Shows one of the smith's three counters.
func _show_section(id: String) -> void:
	section = id
	forge_box.visible = id == "forge"
	sets_box.visible = id == "sets"
	wares_box.visible = id == "wares"
	for k in section_buttons:
		(section_buttons[k] as Button).add_theme_color_override("font_color", UI.GOLD if k == id else UI.TEXT)
	if id == "wares":
		_fill_wares(true)

func _fill_wares(force := false) -> void:
	if state.smith_stock.is_empty():
		Smith.restock(state)
	var key := str(state.smith_stock) + str(state.gold) + str(state.bag.size())
	if key == wares_key and not force:
		return
	wares_key = key
	for c in wares_list.get_children():
		c.queue_free()
	for i in state.smith_stock.size():
		var e: Dictionary = state.smith_stock[i]
		var item: Dictionary = e["item"]
		var row := UI.panel(UI.INSET, Color(GameData.color_of(int(item["rarity"]))), 8, 8, 1)
		wares_list.add_child(row)
		var h := UI.hbox(10)
		row.add_child(h)
		var pic := ItemGrid.picture(40)
		pic.texture = Sprites.item_icon(item)
		h.add_child(pic)
		var t := UI.rich(12)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.text = ItemText.describe(state, item)
		h.add_child(t)
		var need := int(e["price"]) - state.gold
		var label := "Sold" if e["sold"] else ("Bag full" if state.bag_full() else ("Need %d more" % need if need > 0 else "%d gold" % int(e["price"])))
		var b := UI.primary(label, func():
			if Smith.buy(state, i):
				main.sfx.play("buy")
			_fill_wares(true)
			main.refresh(), UI.GOLD)
		b.custom_minimum_size = Vector2(110, 40)
		b.disabled = e["sold"] or need > 0 or state.bag_full()
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)

## A small card: title, description, cost line, and a spot for its button.
func _recipe_card(parent: Control, title: String, color: Color, text: String) -> Array:
	var card := UI.panel(UI.INSET, Color(color, 0.45), 8, 10, 2)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var cv := UI.vbox(5)
	card.add_child(cv)
	cv.add_child(UI.label(title, 15, color))
	var desc := UI.rich(12)
	desc.custom_minimum_size = Vector2(0, 32)
	desc.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), text]
	cv.add_child(desc)
	var cost := UI.rich(12)
	cv.add_child(cost)
	return [cost, cv, desc]

func _craft_set(set_name: String, slot: String) -> void:
	state.craft_set_piece(set_name, slot)
	main.sfx.play("craft")
	main.refresh()

func _chip(text: String, color: Color) -> void:
	var p := UI.panel(Color("#0f1526"), Color(color, 0.4), 12, 6, 1)
	var l := UI.rich(12)
	l.fit_content = true
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.text = text
	p.add_child(l)
	mats_row.add_child(p)

func refresh() -> void:
	var narrow: bool = main.get_viewport().get_visible_rect().size.x < 720.0
	if smith_pic.texture == null:
		var app: Dictionary = state.appearance.duplicate()
		app["race"] = "Dwarf"
		smith_pic.texture = Sprites.portrait(app, {})
	if section == "wares":
		_fill_wares()
	for r in piece_rows:
		(r as BoxContainer).vertical = narrow  # phones: one full-width button per piece, so names fit
	for c in mats_row.get_children():
		c.queue_free()
	_chip("Scrap [color=#e8b14a][b]%d[/b][/color]" % state.scrap, UI.GOLD)
	_chip("Dust [color=#c4b5fd][b]%d[/b][/color]" % state.dust, Color("#c4b5fd"))

	potion_cost.text = "Costs: %s scrap" % UI.have_need(state.scrap, GameData.POTION_SCRAP)
	potion_button.disabled = state.scrap < GameData.POTION_SCRAP

	if state.bag_level >= GameData.BAG_MAX_LEVEL:
		bag_info.text = "[color=%s]Your bag is fully upgraded (%d slots).[/color]" % [UI.hex(UI.DIM), state.bag_capacity()]
		bag_cost.text = ""
		bag_button.disabled = true
	else:
		bag_info.text = "[color=%s]%d -> [/color][color=#4ade80]%d slots[/color][color=%s]. Sewn from scrap.[/color]" % [
			UI.hex(UI.DIM), state.bag_capacity(), state.bag_capacity() + GameData.BAG_STEP, UI.hex(UI.DIM)]
		bag_cost.text = "Costs: %s scrap" % UI.have_need(state.scrap, GameData.bag_craft_scrap(state.bag_level))
		bag_button.disabled = state.bag_craft_block_reason() != ""

	var counts := state.set_counts()
	for set_name in GameData.SET_ORDER:
		var info: Dictionary = GameData.SETS[set_name]
		var labels: Array = set_info[set_name]
		(labels[2] as Label).text = "Wearing %d / 3" % int(counts.get(set_name, 0))
		var full := state.bag_full()
		var reached := Economy.set_zone_reached(state, set_name)
		(labels[1] as RichTextLabel).text = ("Each piece costs: %s dust, %s scrap%s" % [
			UI.have_need(state.dust, Economy.set_piece_dust(set_name)),
			UI.have_need(state.scrap, GameData.SET_PIECE_SCRAP), "   [color=#f87171]Bag is full[/color]" if full else ""]) if reached \
			else "[color=%s]Reach this set's zone to learn the recipe.[/color]" % UI.hex(UI.DIM)
		var ok := state.set_block_reason(set_name) == ""
		for entry in set_buttons[set_name]:
			var b: Button = entry[0]
			var slot: String = entry[1]
			var preview := GameData.make_set_item(set_name, slot, state.best_floor, -1)
			b.text = "%s\n%s  +%d %s" % [info["pieces"][slot], slot, GameData.item_power(preview), preview["stat"]]
			if b.icon == null:
				b.icon = Sprites.item_icon(preview)
			b.tooltip_text = "%s (%s)\n+%d %s\nSet bonus: %s" % [info["pieces"][slot], slot, GameData.item_power(preview), preview["stat"], info["text"]]
			b.disabled = not ok

	gear_cost.text = "Costs: %s scrap each. Items match your best floor (%d)." % [UI.have_need(state.scrap, GameData.CRAFT_GEAR_SCRAP), state.best_floor]
	for slot in gear_buttons:
		(gear_buttons[slot] as Button).disabled = state.scrap < GameData.CRAFT_GEAR_SCRAP or state.bag_full()
