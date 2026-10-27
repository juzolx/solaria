class_name StashTab
extends VBoxContainer
## Town › Vault: a chest shared by all your Regular heroes, shown as a grid of
## item pictures (empty squares are free space). Tap a picture to see the item,
## then move it between your bag and the Vault. Hardcore heroes can't use it.

var main
var state: GameState
var title: Label
var upgrade_button: Button
var vault_grid: GridContainer
var bag_grid: GridContainer
var bag_title: Label
var vault_head: Control   # Fable r2 #9: "Vault · 3 / 20" and "Your bag · 2 / 10" are headings
var bag_head: Control
var info: PanelContainer
var info_pic: TextureRect
var info_text: RichTextLabel
var info_button: Button
var picked := {}          # {"where": "bag"/"vault", "key": item id (bag) or index (vault)}
var shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Vault"
	add_theme_constant_override("separation", 6)
	var head := UI.hbox(8)
	add_child(head)
	title = UI.label("", UI.FONT_BODY, UI.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	upgrade_button = UI.button("", _upgrade)
	head.add_child(upgrade_button)
	var note := UI.label("Shared by the heroes of this town. Tap an item to look at it, then move it.", UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var body := UI.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	vault_head = UI.heading("Vault")
	body.add_child(vault_head)
	vault_grid = ItemGrid.grid()
	body.add_child(vault_grid)
	bag_head = UI.heading("Your bag")
	body.add_child(bag_head)
	bag_title = UI.heading_label(bag_head)
	bag_grid = ItemGrid.grid()
	body.add_child(bag_grid)
	# The picked item: picture, stats and the move button
	info = UI.panel(UI.INSET, UI.BORDER, 8, 8, 1)
	add_child(info)
	var ih := UI.hbox(10)
	info.add_child(ih)
	info_pic = ItemGrid.picture(48)
	ih.add_child(info_pic)
	info_text = UI.rich(UI.FONT_BODY)
	info_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_text.custom_minimum_size = Vector2(120, 0)
	ih.add_child(info_text)
	info_button = UI.primary("", _move, UI.GOLD)
	info_button.custom_minimum_size = Vector2(120, UI.TAP)
	info_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ih.add_child(info_button)
	resized.connect(_on_resized)

func _on_resized() -> void:
	ItemGrid.fit([vault_grid, bag_grid], size.x)

func _pick(where: String, key: int) -> void:
	main.sfx.play("click")
	picked = {"where": where, "key": key}
	shown = ""
	refresh()

func _move() -> void:
	if picked.is_empty():
		return
	var p: Profile = main.profile
	var ok := false
	if picked["where"] == "bag":
		ok = state.to_stash(int(picked["key"]), p.stash, p.stash_capacity())
	else:
		ok = state.from_stash(int(picked["key"]), p.stash)
	if ok:
		p.save()
		main.sfx.play("equip")
	picked = {}
	shown = ""
	main.refresh()

func _upgrade() -> void:
	var p: Profile = main.profile
	var cost := GameData.stash_cost(p.stash_level)
	if p.stash_level >= GameData.STASH_MAX_LEVEL or state.gold < cost:
		return
	state.gold -= cost
	p.stash_level += 1
	p.save()
	state.say("The Vault now holds %d items." % p.stash_capacity())
	state.save_game()
	main.sfx.play("buy")
	main.refresh()

func _picked_item() -> Dictionary:
	if picked.is_empty():
		return {}
	if picked["where"] == "bag":
		for it in state.bag:
			if int(it["id"]) == int(picked["key"]):
				return it
		return {}
	var p: Profile = main.profile
	var i := int(picked["key"])
	return p.stash[i] if i >= 0 and i < p.stash.size() else {}

func refresh() -> void:
	var p: Profile = main.profile
	title.text = ""   # the count is on the Vault heading below
	UI.heading_label(vault_head).text = "Vault · %d / %d" % [p.stash.size(), p.stash_capacity()]
	bag_head.visible = not state.bag.is_empty()   # Fable r3 #13: no heading over nothing
	bag_grid.visible = bag_head.visible
	var cost := GameData.stash_cost(p.stash_level)
	if p.stash_level >= GameData.STASH_MAX_LEVEL:
		upgrade_button.text = "Vault is max size"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = UI.cost("+%d slots" % GameData.STASH_STEP, cost)
		upgrade_button.disabled = state.gold < cost
	var key := "%d|%d|%d|%s" % [state.bag_version, p.stash.size(), p.stash_level, str(picked)]
	if key == shown:
		return
	shown = key
	ItemGrid.fit([vault_grid, bag_grid], size.x)
	var item := _picked_item()
	if item.is_empty():
		picked = {}
	for g in [vault_grid, bag_grid]:
		for c in g.get_children():
			c.queue_free()
	# The vault: its items, then empty squares for the free space
	for i in p.stash.size():
		var sel: bool = not picked.is_empty() and picked["where"] == "vault" and int(picked["key"]) == i
		var vc := ItemGrid.cell(p.stash[i], _pick.bind("vault", i), sel)
		Drag.wire(vc, {"kind": "stash", "index": i}, Sprites.item_icon(p.stash[i]), _vault_takes, _drop_move)
		vault_grid.add_child(vc)
	for i in maxi(0, p.stash_capacity() - p.stash.size()):
		var ec := ItemGrid.cell({}, Callable())
		Drag.wire(ec, {}, null, _vault_takes, _drop_move)
		vault_grid.add_child(ec)
	bag_title.text = "Your bag · %d / %d" % [state.bag.size(), state.bag_capacity()]
	var items: Array = state.bag.duplicate()
	items.reverse()
	for it in items:
		var sel2: bool = not picked.is_empty() and picked["where"] == "bag" and int(picked["key"]) == int(it["id"])
		var bc := ItemGrid.cell(it, _pick.bind("bag", int(it["id"])), sel2)
		Drag.wire(bc, {"kind": "item", "id": int(it["id"])}, Sprites.item_icon(it), _bag_takes, _drop_move)
		bag_grid.add_child(bc)
	# The info strip
	info.visible = not item.is_empty()
	if not item.is_empty():
		info_pic.texture = Sprites.item_icon(item)
		info_text.text = ItemText.describe(state, item)
		var to_vault: bool = picked["where"] == "bag"
		info_button.text = "Put in the Vault" if to_vault else "Take it out"
		info_button.disabled = (to_vault and p.stash.size() >= p.stash_capacity()) or (not to_vault and state.bag_full())

# Next update: drag an item between your bag and the vault.
func _vault_takes(d: Dictionary) -> bool:
	return d.get("kind", "") == "item"

func _bag_takes(d: Dictionary) -> bool:
	return d.get("kind", "") == "stash"

func _drop_move(d: Dictionary) -> void:
	picked = {"where": "bag", "key": int(d["id"])} if d["kind"] == "item" else {"where": "vault", "key": int(d["index"])}
	_move()
