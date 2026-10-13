class_name WheelTab
extends HBoxContainer
## Town > Wheel: Fortune's Wheel. Bet an item: win and it comes back one
## rarity higher, lose and it's gone for good. Rarer items have worse odds.
## Legendary and better, and locked items, can't go on the wheel.

var main
var state: GameState
var list: ItemList
var ids: Array[int] = []
var selected_id := -1
var wheel: Wheel
var info: RichTextLabel
var spin_button: Button
var result_label: RichTextLabel
var shown := ""
var spinning := false

class Wheel:
	extends Control
	var chance := 0       # % green
	var angle := 0.0      # where the pointer points (radians, 0 = up)
	var glow := 0.0
	var glow_color := Color.WHITE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.44
		if glow > 0.0:
			draw_circle(c, r * 1.12, Color(glow_color, 0.25 * glow))
		draw_circle(c, r + 6.0, Color("#2a2010"))
		var segs := 20
		for i in segs:
			var a0 := -PI / 2.0 + TAU * i / segs
			var a1 := -PI / 2.0 + TAU * (i + 1) / segs
			var win := i * 100.0 / segs < float(chance)
			var col := Color("#2f8f4e") if win else Color("#8f2f3a")
			if i % 2 == 1:
				col = col.darkened(0.18)
			var pts := PackedVector2Array([c])
			for k in 9:
				var a := lerpf(a0, a1, k / 8.0)
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, col)
		draw_arc(c, r, 0.0, TAU, 64, Color("#e8b14a"), 3.0)
		draw_circle(c, r * 0.18, Color("#e8b14a"))
		draw_circle(c, r * 0.12, Color("#2a2010"))
		# Pointer
		var dir := Vector2(sin(angle), -cos(angle))
		var tip := c + dir * r * 0.95
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([tip, c + side * r * 0.07, c - side * r * 0.07]), Color("#f6d88f"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, size.y - 4), "%d%% win" % chance, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color("#4ade80"))

func setup(m) -> void:
	main = m
	state = m.state
	name = "Wheel"
	add_theme_constant_override("separation", 12)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(left)
	left.add_child(UI.label("FORTUNE'S WHEEL", 18, UI.GOLD))
	var note := UI.label("Bet an item. Win: it comes back one rarity higher. Lose: it's gone. Common %d%%, Uncommon %d%%, Rare %d%%, Epic %d%%." % GameData.GAMBLE_CHANCES, 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(note)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", 12)
	list.item_selected.connect(func(i: int):
		if i >= 0 and i < ids.size() and ids[i] >= 0 and not spinning:
			selected_id = ids[i]
			result_label.text = ""
			_update())
	left.add_child(list)
	var right := UI.vbox(8)
	right.custom_minimum_size = Vector2(250, 0)
	add_child(right)
	wheel = Wheel.new()
	wheel.custom_minimum_size = Vector2(230, 230)
	right.add_child(wheel)
	info = UI.rich(13)
	right.add_child(info)
	spin_button = UI.primary("Spin!", _spin, UI.GOLD)
	spin_button.custom_minimum_size = Vector2(0, 44)
	right.add_child(spin_button)
	result_label = UI.rich(15)
	right.add_child(result_label)

func refresh() -> void:
	var key := "%d|%d" % [state.bag_version, state.gold]
	if key != shown and not spinning:
		shown = key
		list.clear()
		ids.clear()
		var items: Array = state.bag.duplicate()
		items.reverse()
		for item in items:
			if not GameData.can_gamble(item):
				continue
			var i := list.add_item("%s  -  %d%%" % [ItemText.line(item), state.gamble_chance(item)])
			list.set_item_custom_fg_color(i, Color(GameData.color_of(item["rarity"])))
			list.set_item_tooltip(i, ItemText.tip(state, item))
			ids.append(int(item["id"]))
			if int(item["id"]) == selected_id:
				list.select(i)
		if ids.is_empty():
			var e := list.add_item("Nothing to bet. Locked items and Legendary or better can't go on the wheel.")
			list.set_item_selectable(e, false)
			list.set_item_custom_fg_color(e, UI.DIM)
			ids.append(-1)
	_update()

func _update() -> void:
	var found := state.find_item(selected_id) if selected_id >= 0 else {}
	if found.is_empty() or found["where"] != "bag" or not GameData.can_gamble(found["item"]):
		if not spinning:
			selected_id = -1
			wheel.chance = 0
			info.text = "[color=%s]Pick an item to bet.[/color]" % UI.hex(UI.DIM)
			spin_button.disabled = true
			spin_button.text = "Spin!"
		wheel.queue_redraw()
		return
	var item: Dictionary = found["item"]
	var r := int(item["rarity"])
	wheel.chance = state.gamble_chance(item)
	var fee := GameData.gamble_fee(item)
	info.text = "[color=%s]%s[/color]\n[color=#4ade80]%d%%[/color] to become [color=%s]%s[/color]\n[color=#f87171]%d%%[/color] to lose it\nFee: %d gold" % [
		GameData.color_of(r), GameData.display_name(item), wheel.chance, GameData.color_of(r + 1), GameData.RARITY_NAMES[r + 1], 100 - wheel.chance, fee]
	spin_button.disabled = spinning or state.gold < fee
	spin_button.text = "Spin! (%d gold)" % fee
	wheel.queue_redraw()

func _spin() -> void:
	if spinning or selected_id < 0:
		return
	var found := state.find_item(selected_id)
	if found.is_empty():
		return
	var item: Dictionary = found["item"]
	var go := func():
		spinning = true
		spin_button.disabled = true
		var res: Dictionary = state.gamble(selected_id)
		if not res.get("ok", false):
			spinning = false
			main.refresh()
			return
		main.sfx.play("click")
		# Land the pointer in a matching slice: green is the first <chance>% of the circle
		var pct: float = randf_range(2.0, float(res["chance"]) - 2.0) if res["win"] else randf_range(float(res["chance"]) + 2.0, 98.0)
		var target: float = TAU * 5.0 + TAU * pct / 100.0
		wheel.angle = fmod(wheel.angle, TAU)
		var t := create_tween()
		t.tween_property(wheel, "angle", target, 2.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.parallel().tween_method(func(_v): wheel.queue_redraw(), 0.0, 1.0, 2.6)
		await t.finished
		spinning = false
		var it: Dictionary = res["item"]
		if res["win"]:
			main.sfx.play("legendary" if int(it["rarity"]) >= GameData.LEGENDARY else "level_up")
			wheel.glow_color = Color("#4ade80")
			result_label.text = "[color=#4ade80][b]WIN![/b][/color] It's now [color=%s]%s[/color]." % [GameData.color_of(int(it["rarity"])), GameData.display_name(it)]
		else:
			main.sfx.play("death")
			wheel.glow_color = Color("#f87171")
			result_label.text = "[color=#f87171][b]LOST.[/b][/color] The wheel keeps %s." % GameData.display_name(it)
			selected_id = -1
		wheel.glow = 1.0
		create_tween().tween_property(wheel, "glow", 0.0, 1.2)
		shown = ""
		main.refresh()
	if ItemText.is_precious(item) or int(item["rarity"]) >= 3 or item.get("level", 0) > 0:
		main.confirm("Bet %s?" % GameData.display_name(item), "If you lose, it's gone for good. %d%% chance to win." % state.gamble_chance(item), "Spin", go)
	else:
		go.call()
