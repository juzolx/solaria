class_name CraftTab
extends ScrollContainer
## Town > Craft. Laid out so it's always clear what you have and what you need:
## 1) your materials, 2) basics (potion, bag), 3) set recipes, 4) mystery gear.

var main
var state: GameState
var mats_row: HFlowContainer
var potion_cost: RichTextLabel
var potion_button: Button
var bag_info: RichTextLabel
var bag_cost: RichTextLabel
var bag_button: Button
var set_info := {}     # set -> [header label, cost label, wearing label]
var set_buttons := {}  # set -> Array of buttons
var piece_rows: Array = []  # one row of set-piece buttons per set (stacked on phones)
var gear_buttons := {}
var gear_cost: RichTextLabel

func setup(m) -> void:
	main = m
	state = m.state
	name = "Craft"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)

	# ---- 1. What you have ----
	v.add_child(UI.heading("1. Your materials  -  scrap comes from salvaging, the rest from bosses"))
	mats_row = HFlowContainer.new()
	mats_row.add_theme_constant_override("h_separation", 6)
	mats_row.add_theme_constant_override("v_separation", 6)
	v.add_child(mats_row)

	# ---- 2. Basics ----
	v.add_child(UI.heading("2. Basics"))
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

	# ---- 3. Set recipes ----
	v.add_child(UI.heading("3. Set recipes  -  wear 2 or 3 pieces of a set for bonuses"))
	for set_name in GameData.SET_ORDER:
		var info: Dictionary = GameData.SETS[set_name]
		var card := UI.panel(UI.INSET, Color(UI.TEAL, 0.45), 8, 10, 2)
		v.add_child(card)
		var cv := UI.vbox(5)
		card.add_child(cv)
		var head := UI.hbox(8)
		cv.add_child(head)
		var title := UI.label(set_name, 15, UI.TEAL)
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

	# ---- 4. Mystery gear ----
	v.add_child(UI.heading("4. Mystery gear  -  pick a slot, get a random item with better odds"))
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
	for r in piece_rows:
		(r as BoxContainer).vertical = narrow  # phones: one full-width button per piece, so names fit
	for c in mats_row.get_children():
		c.queue_free()
	_chip("Scrap [color=#e8b14a][b]%d[/b][/color]" % state.scrap, UI.GOLD)
	for i in GameData.MATERIALS.size():
		var n := int(state.materials[i])
		_chip("%s [color=%s][b]%d[/b][/color]" % [GameData.MATERIALS[i], UI.hex(UI.TEAL if n > 0 else UI.DIM), n], UI.TEAL if n > 0 else UI.EMPTY)

	potion_cost.text = "Costs: %s scrap" % UI.have_need(state.scrap, GameData.POTION_SCRAP)
	potion_button.disabled = state.scrap < GameData.POTION_SCRAP

	if state.bag_level >= GameData.BAG_MAX_LEVEL:
		bag_info.text = "[color=%s]Your bag is fully upgraded (%d slots).[/color]" % [UI.hex(UI.DIM), state.bag_capacity()]
		bag_cost.text = ""
		bag_button.disabled = true
	else:
		bag_info.text = "[color=%s]%d -> [/color][color=#4ade80]%d slots[/color][color=%s]. Uses any boss materials.[/color]" % [
			UI.hex(UI.DIM), state.bag_capacity(), state.bag_capacity() + GameData.BAG_STEP, UI.hex(UI.DIM)]
		bag_cost.text = "Costs: %s materials, %s scrap" % [
			UI.have_need(state.material_total(), GameData.bag_craft_materials(state.bag_level)),
			UI.have_need(state.scrap, GameData.bag_craft_scrap(state.bag_level))]
		bag_button.disabled = state.bag_craft_block_reason() != ""

	var counts := state.set_counts()
	for set_name in GameData.SET_ORDER:
		var info: Dictionary = GameData.SETS[set_name]
		var mat: int = info["material"]
		var labels: Array = set_info[set_name]
		(labels[2] as Label).text = "Wearing %d / 3" % int(counts.get(set_name, 0))
		var full := state.bag_full()
		(labels[1] as RichTextLabel).text = "Each piece costs: %s %s, %s scrap%s" % [
			UI.have_need(int(state.materials[mat]), GameData.SET_PIECE_MATERIALS), GameData.MATERIALS[mat],
			UI.have_need(state.scrap, GameData.SET_PIECE_SCRAP), "   [color=#f87171]Bag is full[/color]" if full else ""]
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
