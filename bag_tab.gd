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
var grid: GridContainer
var empty_note: Label
var ids: Array[int] = []
var last_pick_ms := 0
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
var select_button: Button
var picking := false      # next update: multi-select mode
var picked := {}          # id -> true
var pick_row: HBoxContainer
var pick_sell: Button
var pick_salvage: Button

func setup(m) -> void:
	main = m
	state = m.state
	name = "Bag"
	add_theme_constant_override("separation", 6)

	var head := UI.hbox(6)
	add_child(head)
	title = UI.label("", 14, UI.TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # long notes wrap instead of widening the page
	title.custom_minimum_size = Vector2(60, 0)
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
	select_button = UI.button("Select", _toggle_picking)
	select_button.tooltip_text = "Pick several items, then sell or salvage them all at once"
	head.add_child(select_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	grid = ItemGrid.grid()
	sv.add_child(grid)
	empty_note = UI.label("", 12, UI.DIM)
	sv.add_child(empty_note)
	resized.connect(_on_resized)

	var box := UI.panel(UI.INSET, UI.EMPTY, 8, 8, 1)
	add_child(box)
	details = UI.rich(12)
	details.custom_minimum_size = Vector2(0, 74)
	box.add_child(details)

	pick_row = UI.hbox(6)
	pick_row.visible = false
	add_child(pick_row)
	pick_sell = UI.button("", func(): _bulk("sell"))
	pick_salvage = UI.button("", func(): _bulk("salvage"))
	var pick_all := UI.button("All", _pick_all)
	pick_all.tooltip_text = "Pick every unlocked item shown"
	for b in [pick_sell, pick_salvage]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick_row.add_child(b)
	pick_row.add_child(pick_all)

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
	for pair in [[equip_button, "equip"], [lock_button, "lock"], [sell_button, "sell"], [salvage_button, "salvage"]]:
		Drag.wire(pair[0], {}, null, func(d): return d.get("kind", "") == "item" and not state.find_item(int(d["id"])).is_empty(), _dropped_on.bind(pair[1]))
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
	# 2.1: one loot filter screen for every rule (rarity, slots, smart rules, sell or salvage)
	auto_salvage_button = UI.button("", func(): LootFilter.new().show_for(main))
	auto_salvage_button.tooltip_text = "Choose which new drops are salvaged or sold the moment they drop"
	auto_salvage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_salvage_button.custom_minimum_size.y = UI.TAP
	frow.add_child(auto_salvage_button)

func _on_resized() -> void:
	ItemGrid.fit([grid], size.x)

## Tap: select it and open the side-by-side compare popup. In Select mode a tap
## picks or unpicks it instead.
func _tap(id: int) -> void:
	main.sfx.play("click")
	if picking:
		var found := state.find_item(id)
		if found.is_empty() or found["item"].get("locked", false) or state.is_bound(found["item"]):
			return
		if picked.has(id):
			picked.erase(id)
		else:
			picked[id] = true
		shown = ""
		main.refresh()
		return
	selected_id = id
	shown = ""
	main.refresh()
	_popup(id)

func _toggle_picking() -> void:
	picking = not picking
	picked.clear()
	shown = ""
	main.refresh()

func _pick_all() -> void:
	for it in _sorted_items():
		if not it.get("locked", false) and not state.is_bound(it):
			picked[int(it["id"])] = true
	shown = ""
	main.refresh()

## Picked items still in the bag (things can vanish while picking).
func _picked_items() -> Array:
	var out := []
	for id in picked.keys():
		var found := state.find_item(int(id))
		if not found.is_empty() and found["where"] == "bag":
			out.append(found["item"])
	return out

## Sell or salvage everything picked; one confirm if any of it is precious.
func _bulk(action: String) -> void:
	var items := _picked_items()
	if items.is_empty():
		return
	var run := func():
		for it in items:
			if action == "sell":
				state.sell(int(it["id"]))
			else:
				state.salvage(int(it["id"]))
		main.sfx.play(action)
		picked.clear()
		picking = false
		if state.find_item(selected_id).is_empty():
			selected_id = -1
		shown = ""
		main.refresh()
	var precious := items.filter(func(it): return ItemText.is_precious(it)).size()
	if precious > 0:
		main.confirm("%s %d items?" % ["Sell" if action == "sell" else "Salvage", items.size()], "%d of them %s Legendary or better. They're gone for good." % [precious, "is" if precious == 1 else "are"], "Sell them" if action == "sell" else "Salvage them", run)
		return
	run.call()

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
			acts.append(["Salvage (%d scrap)" % GameData.scrap_value(item, state.scrap_mult()), func(): _act("salvage"), UI.BLUE])
			acts.append(["Sell (%d gold)" % state.sell_price(item), func(): _act("sell"), UI.GOLD])
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
				main.confirm("Sell %s?" % GameData.display_name(item), "This is a %s item. You'll get %d gold, but it's gone for good." % [GameData.RARITY_NAMES[int(item["rarity"])], state.sell_price(item)], "Sell it", do_sell)
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
				main.confirm("Salvage %s?" % GameData.display_name(item), "This is a %s item. You'll get %d scrap, but it's gone for good." % [GameData.RARITY_NAMES[int(item["rarity"])], GameData.scrap_value(item, state.scrap_mult())], "Salvage it", do_salvage)
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
	title.text = "BAG  %d / %d%s" % [state.bag.size(), state.bag_capacity(), ("  (%d over: sell to use them)" % (state.bag.size() - state.bag_capacity())) if state.bag.size() > state.bag_capacity() else ""]
	if state.packs_carried > 0:
		title.text += "   +%d backpack%s to bring home" % [state.packs_carried, "" if state.packs_carried == 1 else "s"]
	if state.return_scrolls > 0:
		title.text += "   ·  %d Return Scroll%s" % [state.return_scrolls, "" if state.return_scrolls == 1 else "s"]
	title.add_theme_color_override("font_color", UI.RED if state.bag_full() else UI.TEXT)
	auto_salvage_button.text = "Loot filter: %s" % LootRules.summary(state)
	select_button.text = "Done" if picking else "Select"
	pick_row.visible = picking
	if picking:
		var items := _picked_items()
		var gold_total := 0
		var scrap_total := 0
		for it in items:
			gold_total += state.sell_price(it)
			scrap_total += GameData.scrap_value(it, state.scrap_mult())
		pick_sell.text = "Sell %d (%d gold)" % [items.size(), gold_total]
		pick_salvage.text = "Salvage %d (%d scrap)" % [items.size(), scrap_total]
		pick_sell.disabled = items.is_empty()
		pick_salvage.disabled = items.is_empty()
	for r in salvage_all_buttons:
		var n := state.salvage_all_count(r)
		var b: Button = salvage_all_buttons[r]
		b.text = "%s (%d)" % [GameData.RARITY_NAMES[r], n]
		b.disabled = n == 0

	var key := "%d|%d|%d|%d|%s|%s" % [state.bag_version, sort_pick.selected, filter_pick.selected, selected_id, picking, str(picked.keys())]
	if key != shown:
		shown = key
		ItemGrid.fit([grid], size.x)
		for c in grid.get_children():
			c.queue_free()
		ids.clear()
		for item in _sorted_items():
			var id := int(item["id"])
			var pct := state.compare_pct(item)
			var badge := "LOCK" if item.get("locked", false) else ("+%d%%" % int(round(pct)) if pct > 0.0 else "")
			var over := state.over_limit(id)
			if over:
				badge = "OVER"
			var cell := ItemGrid.cell(item, _tap.bind(id), picked.has(id) if picking else id == selected_id, ItemGrid.CELL, ("PICK" if picked.has(id) else badge) if picking else badge)
			if over:
				cell.modulate = Color(0.55, 0.5, 0.5)  # 0.13+: past the bag's limit: sell or salvage to use it
				cell.tooltip_text = "Over your bag's limit. Sell or salvage something to use it (you can still sell or salvage this one)."
			if not picking:
				Drag.wire(cell, {"kind": "item", "id": id}, Sprites.item_icon(item))  # next update: drag onto Equip, Sell, Salvage or Lock
			grid.add_child(cell)
			ids.append(id)
		empty_note.visible = ids.is_empty()
		empty_note.text = "Nothing here yet." if state.bag.is_empty() else "No items match this filter."
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
	text += "\n[color=%s]Sell %d gold  -  Salvage %d scrap[/color]" % [UI.hex(UI.DIM), state.sell_price(item), GameData.scrap_value(item, state.scrap_mult())]
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
		upgrade_button.text = "Upgrade +%d (%s)" % [int(item["level"]) + 1, Economy.cost_text(cost, Economy.upgrade_dust(item))]
		upgrade_button.disabled = Economy.upgrade_short(state, item) != ""
	if GameData.can_reroll(item):
		var rcost := GameData.reroll_cost(item)
		reroll_button.text = "Reroll: %d%% to %s (%s)" % [GameData.reroll_chance(item), GameData.RARITY_NAMES[int(item["rarity"]) + 1], Economy.cost_text(rcost, Economy.reroll_dust(item))]
		reroll_button.disabled = Economy.reroll_short(state, item) != ""
	else:
		reroll_button.text = "Can't reroll"
		reroll_button.disabled = true

## Next update: an item dropped on Equip, Lock, Sell or Salvage gets that done.
func _dropped_on(d: Dictionary, action: String) -> void:
	selected_id = int(d["id"])
	shown = ""
	_act(action)
