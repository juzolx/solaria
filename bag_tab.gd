class_name BagTab
extends VBoxContainer
## Items > Bag: everything you're carrying. Sort, filter, lock, sell, salvage,
## upgrade and reroll. Locked items can't be sold or salvaged.

const SORTS := ["Newest", "Rarity", "Power", "Slot"]

var main
var state: GameState
var title: Label
var sort_pick: OptionButton
var filter_pick: OptionButton
var list: ItemList
var ids: Array[int] = []
var details: RichTextLabel
var equip_button: Button
var lock_button: Button
var sell_button: Button
var salvage_button: Button
var upgrade_button: Button
var reroll_button: Button
var salvage_all_buttons := {}
var auto_salvage_button: Button
var selected_id := -1
var shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Bag"
	add_theme_constant_override("separation", 6)

	var head := UI.hbox(6)
	add_child(head)
	title = UI.label("", 14, UI.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	sort_pick = OptionButton.new()
	for sname in SORTS:
		sort_pick.add_item("Sort: " + sname)
	sort_pick.item_selected.connect(func(_i): shown = ""; main.refresh())
	head.add_child(sort_pick)
	filter_pick = OptionButton.new()
	filter_pick.add_item("All slots")
	for s in GameData.SLOT_ORDER:
		filter_pick.add_item(s)
	filter_pick.item_selected.connect(func(_i): shown = ""; main.refresh())
	head.add_child(filter_pick)

	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", 13)
	list.item_selected.connect(func(idx: int):
		if idx >= 0 and idx < ids.size() and ids[idx] >= 0:
			selected_id = ids[idx]
		main.refresh())
	list.item_activated.connect(func(idx: int):
		if idx >= 0 and idx < ids.size() and ids[idx] >= 0:
			_popup(ids[idx]))
	add_child(list)

	var box := UI.panel(UI.INSET, UI.EMPTY, 8, 8, 1)
	add_child(box)
	details = UI.rich(12)
	details.custom_minimum_size = Vector2(0, 74)
	box.add_child(details)

	var row1 := UI.hbox(6)
	var row2 := UI.hbox(6)
	add_child(row1)
	add_child(row2)
	equip_button = UI.button("Equip", func(): _act("equip"))
	lock_button = UI.button("Lock", func(): _act("lock"))
	sell_button = UI.button("Sell", func(): _act("sell"))
	salvage_button = UI.button("Salvage", func(): _act("salvage"))
	upgrade_button = UI.button("Upgrade", func(): _act("upgrade"))
	reroll_button = UI.button("Reroll", func(): _act("reroll"))
	lock_button.tooltip_text = "Locked items can't be sold or salvaged"
	for b in [equip_button, lock_button, sell_button, salvage_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(b)
	for b in [upgrade_button, reroll_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(b)

	var bulk := UI.hbox(6)
	add_child(bulk)
	bulk.add_child(UI.label("Salvage all:", 12, UI.DIM))
	for r in [0, 1, 2, 3]:
		var b := UI.button("", _salvage_all.bind(r))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_color_override("font_color", Color(GameData.color_of(r)))
		b.tooltip_text = "Salvage every %s item. Locked items and upgrades are kept." % GameData.RARITY_NAMES[r]
		bulk.add_child(b)
		salvage_all_buttons[r] = b
	var frow := UI.hbox(6)
	add_child(frow)
	auto_salvage_button = UI.button("", func(): state.cycle_auto_salvage(); main.refresh())
	auto_salvage_button.tooltip_text = "Automatically turn new drops of these rarities into scrap"
	auto_salvage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(auto_salvage_button)
	frow.add_child(UI.button("Loot filter...", func(): LootFilter.new().show_for(main)))

## The compare popup for one item, with what you can do with it.
func _popup(id: int) -> void:
	var found := state.find_item(id)
	if found.is_empty():
		return
	selected_id = id
	var item: Dictionary = found["item"]
	var acts := []
	if found["where"] == "bag":
		acts.append(["Equip", func(): state.equip(id); main.sfx.play("equip"); main.refresh(), UI.GREEN])
		if not item.get("locked", false):
			acts.append(["Salvage (%d scrap)" % GameData.scrap_value(item), func(): _act("salvage"), UI.BLUE])
			acts.append(["Sell (%d gold)" % GameData.sell_value(item), func(): _act("sell"), UI.GOLD])
	ItemPopup.show_item(main, item, acts)

func _act(action: String) -> void:
	if selected_id < 0:
		return
	var found := state.find_item(selected_id)
	if found.is_empty():
		return
	var item: Dictionary = found["item"]
	match action:
		"equip":
			if found["where"] == "equipped":
				state.unequip(selected_id)
			else:
				state.equip(selected_id)
				main.sfx.play("equip")
		"lock":
			state.toggle_lock(selected_id)
		"sell":
			var do_sell := func():
				state.sell(selected_id)
				main.sfx.play("sell")
				selected_id = -1
				main.refresh()
			if ItemText.is_precious(item):
				main.confirm("Sell %s?" % GameData.display_name(item), "This is a %s item. You'll get %d gold, but it's gone for good." % [GameData.RARITY_NAMES[int(item["rarity"])], GameData.sell_value(item)], "Sell it", do_sell)
				return
			do_sell.call()
			return
		"salvage":
			var do_salvage := func():
				state.salvage(selected_id)
				main.sfx.play("salvage")
				selected_id = -1
				main.refresh()
			if ItemText.is_precious(item):
				main.confirm("Salvage %s?" % GameData.display_name(item), "This is a %s item. You'll get %d scrap, but it's gone for good." % [GameData.RARITY_NAMES[int(item["rarity"])], GameData.scrap_value(item)], "Salvage it", do_salvage)
				return
			do_salvage.call()
			return
		"upgrade":
			state.upgrade(selected_id)
			main.sfx.play("craft")
		"reroll":
			state.reroll(selected_id)
			main.sfx.play("craft")
	main.refresh()

func _salvage_all(rarity: int) -> void:
	state.salvage_all(rarity)
	main.sfx.play("salvage")
	if state.find_item(selected_id).is_empty():
		selected_id = -1
	main.refresh()

func _sorted_items() -> Array:
	var items: Array = state.bag.duplicate()
	items.reverse()  # newest first
	var filt := filter_pick.selected
	if filt > 0:
		var s: String = GameData.SLOT_ORDER[filt - 1]
		items = items.filter(func(it): return it["slot"] == s)
	match sort_pick.selected:
		1:
			items.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]))
		2:
			items.sort_custom(func(a, b): return GameData.item_power(a) > GameData.item_power(b))
		3:
			items.sort_custom(func(a, b): return GameData.SLOT_ORDER.find(a["slot"]) < GameData.SLOT_ORDER.find(b["slot"]))
	return items

func refresh() -> void:
	title.text = "BAG  %d / %d" % [state.bag.size(), state.bag_capacity()]
	title.add_theme_color_override("font_color", UI.RED if state.bag_full() else UI.TEXT)
	var salvage_names := ["Off", "Commons", "Uncommon and below", "Rare and below", "Epic and below"]
	auto_salvage_button.text = "Auto-salvage new drops: %s" % salvage_names[state.auto_salvage + 1]
	for r in salvage_all_buttons:
		var n := state.salvage_all_count(r)
		var b: Button = salvage_all_buttons[r]
		b.text = "%s (%d)" % [GameData.RARITY_NAMES[r], n]
		b.disabled = n == 0

	var key := "%d|%d|%d" % [state.bag_version, sort_pick.selected, filter_pick.selected]
	if key != shown:
		shown = key
		list.clear()
		ids.clear()
		for item in _sorted_items():
			var idx := list.add_item("%s   %s" % [ItemText.line(item), ItemText.delta(state, item)])
			list.set_item_custom_fg_color(idx, Color.html(GameData.color_of(item["rarity"])))
			list.set_item_tooltip(idx, ItemText.tip(state, item))
			if item.get("locked", false):
				list.set_item_custom_bg_color(idx, Color("#1f1a0e"))
			ids.append(int(item["id"]))
			if int(item["id"]) == selected_id:
				list.select(idx)
		if ids.is_empty():
			var e := list.add_item("Nothing here yet." if state.bag.is_empty() else "No items match this filter.")
			list.set_item_selectable(e, false)
			list.set_item_custom_fg_color(e, UI.DIM)
			ids.append(-1)
	_refresh_details()

func _refresh_details() -> void:
	var found := {}
	if selected_id >= 0:
		found = state.find_item(selected_id)
	if found.is_empty():
		selected_id = -1
		details.text = "[color=%s]Select an item to see what it does and what you can do with it.[/color]" % UI.hex(UI.DIM)
		for b in [equip_button, lock_button, sell_button, salvage_button, upgrade_button, reroll_button]:
			b.disabled = true
		return
	var item: Dictionary = found["item"]
	var in_bag: bool = found["where"] == "bag"
	var locked: bool = item.get("locked", false)
	var text := ItemText.describe(state, item)
	text += "\n" + (ItemText.compare(state, item) if in_bag else "[color=%s]You're wearing this.[/color]" % UI.hex(UI.DIM))
	text += "\n[color=%s]Sell %d gold  -  Salvage %d scrap[/color]" % [UI.hex(UI.DIM), GameData.sell_value(item), GameData.scrap_value(item)]
	details.text = text

	equip_button.text = "Equip" if in_bag else "Unequip"
	equip_button.disabled = (not in_bag) and state.bag_full()
	lock_button.text = "Unlock" if locked else "Lock"
	lock_button.disabled = false
	sell_button.disabled = not in_bag or locked
	salvage_button.disabled = not in_bag or locked
	if int(item["level"]) >= GameData.MAX_UPGRADE:
		upgrade_button.text = "Max level"
		upgrade_button.disabled = true
	else:
		var cost := GameData.upgrade_cost(item)
		upgrade_button.text = "Upgrade +%d (%d scrap)" % [int(item["level"]) + 1, cost]
		upgrade_button.disabled = state.scrap < cost
	if GameData.can_reroll(item):
		var rcost := GameData.reroll_cost(item)
		reroll_button.text = "Reroll: %d%% to %s (%d scrap)" % [GameData.reroll_chance(item), GameData.RARITY_NAMES[int(item["rarity"]) + 1], rcost]
		reroll_button.disabled = state.scrap < rcost
	else:
		reroll_button.text = "Can't reroll"
		reroll_button.disabled = true
