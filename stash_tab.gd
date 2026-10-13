class_name StashTab
extends VBoxContainer
## Items > Stash: a chest shared by all your Regular heroes. Put gear in with
## one hero and take it out with another. Hardcore heroes can't use it.

var main
var state: GameState
var title: Label
var bag_list: ItemList
var stash_list: ItemList
var bag_ids: Array[int] = []
var upgrade_button: Button
var shown := ""

func setup(m) -> void:
	main = m
	state = m.state
	name = "Stash"
	add_theme_constant_override("separation", 6)
	var head := UI.hbox(8)
	add_child(head)
	title = UI.label("", 14, UI.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	upgrade_button = UI.button("", _upgrade)
	head.add_child(upgrade_button)
	var note := UI.label("Shared by all your Regular heroes. Tap an item to move it.", 12, UI.DIM)
	add_child(note)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(cols)
	for which in ["bag", "stash"]:
		var v := UI.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(v)
		v.add_child(UI.label("YOUR BAG  (tap to stash)" if which == "bag" else "STASH  (tap to take)", 11, UI.DIM))
		var l := ItemList.new()
		l.size_flags_vertical = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 12)
		v.add_child(l)
		if which == "bag":
			bag_list = l
			l.item_selected.connect(_from_bag)
		else:
			stash_list = l
			l.item_selected.connect(_from_stash)

func _from_bag(idx: int) -> void:
	bag_list.deselect_all()
	if idx < 0 or idx >= bag_ids.size():
		return
	if state.to_stash(bag_ids[idx], main.profile.stash, main.profile.stash_capacity()):
		main.profile.save()
		main.sfx.play("equip")
	main.refresh()

func _from_stash(idx: int) -> void:
	stash_list.deselect_all()
	if state.from_stash(idx, main.profile.stash):
		main.profile.save()
		main.sfx.play("equip")
	main.refresh()

func _upgrade() -> void:
	var p: Profile = main.profile
	var cost := GameData.stash_cost(p.stash_level)
	if p.stash_level >= GameData.STASH_MAX_LEVEL or state.gold < cost:
		return
	state.gold -= cost
	p.stash_level += 1
	p.save()
	state.say("The stash now holds %d items." % p.stash_capacity())
	state.save_game()
	main.sfx.play("buy")
	main.refresh()

func refresh() -> void:
	var p: Profile = main.profile
	title.text = "STASH  %d / %d" % [p.stash.size(), p.stash_capacity()]
	var cost := GameData.stash_cost(p.stash_level)
	if p.stash_level >= GameData.STASH_MAX_LEVEL:
		upgrade_button.text = "Stash is max size"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = "+%d slots (%d gold)" % [GameData.STASH_STEP, cost]
		upgrade_button.disabled = state.gold < cost
	var key := "%d|%d|%d" % [state.bag_version, p.stash.size(), p.stash_level]
	if key == shown:
		return
	shown = key
	bag_list.clear()
	bag_ids.clear()
	var items: Array = state.bag.duplicate()
	items.reverse()
	for item in items:
		var i := bag_list.add_item("%s  +%d %s" % [GameData.display_name(item), GameData.item_power(item), item["stat"]])
		bag_list.set_item_custom_fg_color(i, Color(GameData.color_of(item["rarity"])))
		bag_list.set_item_tooltip(i, ItemText.plain(item))
		bag_ids.append(int(item["id"]))
	stash_list.clear()
	for item in p.stash:
		var i := stash_list.add_item("%s  +%d %s" % [GameData.display_name(item), GameData.item_power(item), item["stat"]])
		stash_list.set_item_custom_fg_color(i, Color(GameData.color_of(item["rarity"])))
		stash_list.set_item_tooltip(i, ItemText.tip(state, item))
