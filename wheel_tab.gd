class_name WheelTab
extends BoxContainer
## Town › Tavern: Fortune's Wheel. Put an item on it: win and it comes back one
## rarity higher, lose and it's gone for good. Rarer items have worse odds.
## Legendary and better, and locked items, can't go on the wheel.

var main
var state: GameState
var grid: GridContainer
var empty_note: Label
var ids: Array[int] = []
var selected_id := -1
var wheel: Wheel
var info: RichTextLabel
var spin_button: Button
var result_label: RichTextLabel
var shown := ""
var spinning := false
# Many wheels: spin several items at once, each on its own wheel. Spinning again
# quickly builds heat: more wheels at a time and faster spins.
const HEAT_WINDOW_MS := 9000
const BASE_WHEELS := 3
const MAX_WHEELS := 8
var high := false
var slate: Array[int] = []      # item ids loaded onto wheels
var heat := 0
var last_round_ms := -100000
var normal_box: Control
var high_box: VBoxContainer
var mini_grid: GridContainer
var minis: Array = []           # Wheel per slate slot
var mode_button: Button
var heat_label: RichTextLabel
var load_row: HBoxContainer
# 2.1 Legendary table (WheelTables): pay gold for one prize; odds always on screen
var leg := false
var left_col: Control
var leg_box: VBoxContainer
var leg_info: RichTextLabel
var leg_button: Button
var cols: BoxContainer   # the item side and the wheel side (stacked on phones), inside a scroll

class Wheel:
	extends Control
	var chance := 0       # % green
	var angle := 0.0      # where the pointer points (radians, 0 = up)
	var glow := 0.0
	var glow_color := Color.WHITE
	const LABEL_H := 22.0

	func _draw() -> void:
		# The win line gets its own strip under the wheel (it used to sit on the rim)
		var area := Vector2(size.x, maxf(1.0, size.y - LABEL_H))
		var c := area / 2.0
		var r := minf(area.x, area.y) * 0.44
		if glow > 0.0:
			draw_circle(c, r * 1.12, Color(glow_color, 0.25 * glow))
		draw_circle(c, r + 6.0, UiSkin.SOOT)   # interface pass (approved mockup 13): ink rim, palette colours
		draw_circle(c, r + 4.0, Color("#9a7040"))
		var segs := 20
		for i in segs:
			var a0 := -PI / 2.0 + TAU * i / segs
			var a1 := -PI / 2.0 + TAU * (i + 1) / segs
			var win := i * 100.0 / segs < float(chance)
			var col := Color("#3e8948") if win else Color("#a22633")
			if i % 2 == 1:
				col = col.darkened(0.18)
			var pts := PackedVector2Array([c])
			for k in 9:
				var a := lerpf(a0, a1, k / 8.0)
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, col)
		draw_arc(c, r, 0.0, TAU, 64, UiSkin.SOOT, 2.0)
		draw_circle(c, r * 0.2, UiSkin.SOOT)
		draw_circle(c, r * 0.17, Color("#c8a060"))
		draw_circle(c, r * 0.1, Color("#9a7040"))
		# Pointer
		var dir := Vector2(sin(angle), -cos(angle))
		var tip := c + dir * r * 0.95
		var side := Vector2(-dir.y, dir.x)
		var ptr := PackedVector2Array([tip, c + side * r * 0.08, c - side * r * 0.08])
		draw_colored_polygon(ptr, Color("#feae34"))
		draw_polyline(ptr + PackedVector2Array([ptr[0]]), UiSkin.SOOT, 2.0)
		var font := UI.game_font()   # interface pass: the game font everywhere
		if chance > 0:   # Fable r5 #14: no "0% win" before an item is picked
			draw_string(font, Vector2(0, size.y - 4), "%d%% win" % chance, HORIZONTAL_ALIGNMENT_CENTER, size.x, UI.MIN_FONT, UI.GREEN)
		if UI.colorblind and chance > 0:   # QA r2 #44: the winning slice says so, not just its green
			var mid := -PI / 2.0 + TAU * float(chance) / 200.0
			var at := c + Vector2(cos(mid), sin(mid)) * r * 0.6
			draw_string_outline(font, at + Vector2(-40, 6), "WIN", HORIZONTAL_ALIGNMENT_CENTER, 80, UI.MIN_FONT, 4, UiSkin.SOOT)
			draw_string(font, at + Vector2(-40, 6), "WIN", HORIZONTAL_ALIGNMENT_CENTER, 80, UI.MIN_FONT, Color.WHITE)

func setup(m) -> void:
	main = m
	state = m.state
	name = "Wheel"
	vertical = true
	# Phone sweep (SE, 375x667 = 896 design px tall): the Tavern needed 1054 px and pushed the
	# bottom bar off. The page scrolls instead; on taller phones it fills the screen as before.
	var page_scroll := ScrollContainer.new()
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(page_scroll)
	cols = BoxContainer.new()
	cols.vertical = _phone()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	page_scroll.add_child(cols)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left_col = left
	# Fable r1 #12: one line; the odds sit on each item and behind the Odds button
	left.add_child(UI.heading("Fortune's Wheel"))
	var note := UI.label("Win: it comes back one rarity higher. Lose: it's gone.", UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	scroll.custom_minimum_size = Vector2(0, 96)  # phones stack the wheel under this: it was squeezed to nothing (96: two rows of items, still fits the phone)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	grid = ItemGrid.grid()
	sv.add_child(grid)
	empty_note = UI.label("Nothing to put on the Wheel. Locked items and Legendary or better can't go on the wheel.", UI.FONT_BODY, UI.DIM)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(empty_note)
	left.resized.connect(_on_left_resized.bind(left))
	var right := UI.vbox(8)
	right.custom_minimum_size = Vector2(250, 0)
	cols.add_child(right)
	mode_button = UI.button("", _toggle_mode)
	mode_button.custom_minimum_size = Vector2(0, UI.TAP)
	var table_row := UI.hbox(6)
	right.add_child(table_row)
	leg_button = UI.button("", _toggle_leg)
	leg_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leg_button.custom_minimum_size = Vector2(0, UI.TAP)
	table_row.add_child(leg_button)
	mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_row.add_child(mode_button)   # one row for the three table buttons (phone height)
	var odds_button := UI.button("Odds", show_odds)
	odds_button.custom_minimum_size = Vector2(72, UI.TAP)
	table_row.add_child(odds_button)
	var nb := UI.vbox(8)
	right.add_child(nb)
	normal_box = nb
	wheel = Wheel.new()
	# QA (Oct 24): 230 px pushed the bottom bar off a phone once the building bar sat over
	# the page. Smaller at least, and it grows into any room the page has.
	wheel.custom_minimum_size = Vector2(180, 180)
	wheel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nb.add_child(wheel)
	high_box = UI.vbox(6)
	high_box.visible = false
	right.add_child(high_box)
	heat_label = UI.rich(UI.FONT_BODY)
	high_box.add_child(heat_label)
	mini_grid = GridContainer.new()
	mini_grid.columns = 2
	mini_grid.add_theme_constant_override("h_separation", 6)
	mini_grid.add_theme_constant_override("v_separation", 6)
	high_box.add_child(mini_grid)
	load_row = UI.hbox(4)
	high_box.add_child(load_row)
	leg_box = UI.vbox(6)
	leg_box.visible = false
	right.add_child(leg_box)
	leg_box.add_child(UI.heading("Legendary table"))
	leg_info = UI.rich(UI.FONT_BODY)
	leg_box.add_child(leg_info)
	for r in [0, 1, 2]:
		var lb := UI.button("+ all %s" % GameData.RARITY_NAMES[r], _load_rarity.bind(r))
		lb.add_theme_color_override("font_color", Color(GameData.color_of(r)))
		lb.add_theme_font_size_override("font_size", UI.MIN_FONT)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load_row.add_child(lb)
	info = UI.rich(UI.FONT_BODY)
	right.add_child(info)
	spin_button = UI.primary("Spin!", _spin, UI.GOLD)
	spin_button.custom_minimum_size = Vector2(0, UI.TAP)
	right.add_child(spin_button)
	result_label = UI.rich(UI.FONT_BODY)
	right.add_child(result_label)

func _on_left_resized(left: Control) -> void:
	ItemGrid.fit([grid], left.size.x)

func _pick(id: int) -> void:
	if spinning:
		return
	if state.over_limit(id):  # 0.13+ (Juzo): say so instead of quietly refusing
		main.toast("Your bag is full: that item is over its limit. Sell or salvage something to spin for it.")
		result_label.text = "[color=#f87171]Bag full: that item is over the limit. Sell or salvage something first.[/color]"
		main.sfx.play("error")
		return
	if high:
		if id in slate:
			slate.erase(id)
		elif slate.size() < wheel_cap():
			slate.append(id)
		else:
			result_label.text = "[color=%s]All %d wheels are loaded. Spin to build heat for more.[/color]" % [UI.hex(UI.DIM), wheel_cap()]
		shown = ""
		main.sfx.play("click")
		refresh()
		return
	selected_id = id
	result_label.text = ""
	shown = ""
	main.sfx.play("click")
	refresh()

## Phones (the tall layout, or any narrow screen): the wheel sits under the items.
func _phone() -> bool:
	return bool(main.get("is_tall")) or main.get_viewport().get_visible_rect().size.x < 720.0

func refresh() -> void:
	cols.vertical = _phone()
	var key := "%d|%d|%d|%s|%s|%s" % [state.bag_version, state.gold, selected_id, str(slate), high, leg]
	if key != shown and not spinning:
		shown = key
		for c in grid.get_children():
			c.queue_free()
		ids.clear()
		var items: Array = state.bag.duplicate()
		items.reverse()
		for item in items:
			if not GameData.can_gamble(item):
				continue
			var id := int(item["id"])
			var sel: bool = (id in slate) if high else id == selected_id
			var over := state.over_limit(id)
			var wcell := ItemGrid.cell(item, _pick.bind(id), sel, ItemGrid.CELL, "OVER" if over else "%d%%" % state.gamble_chance(item))
			if over:
				wcell.modulate = Color(0.55, 0.5, 0.5)
			grid.add_child(wcell)
			ids.append(id)
		empty_note.visible = ids.is_empty()
	_update()

func _update() -> void:
	if state.bag.size() >= state.bag_capacity() and not spinning and result_label.text == "":
		result_label.text = "[color=#f87171]Your bag is full (%d / %d). You can still spin items in it, but items over the limit can't go on the wheel until you sell or salvage.[/color]" % [state.bag.size(), state.bag_capacity()]
	mode_button.text = "Many wheels"
	UI.toggle_look(mode_button, high)   # Fable r1 #4: a check box, not ": ON / OFF"
	mode_button.tooltip_text = "Spin several items at once, each on its own wheel" if not high else "Back to one wheel"
	leg_button.text = "Item Wheel" if leg else "Legendary"
	leg_button.add_theme_color_override("font_color", UI.TEXT if leg or WheelTables.legendary_unlocked(state) else UI.DIM)   # dim = locked (the tip says why)
	leg_button.tooltip_text = "Back to the item Wheel" if leg else "The Legendary table: pay gold for one prize"
	mode_button.visible = not leg
	left_col.visible = not leg
	leg_box.visible = leg
	info.visible = not leg
	normal_box.visible = not high and not leg
	high_box.visible = high and not leg
	if leg:
		_update_leg()
		return
	if high:
		_update_high()
		return
	var found := state.find_item(selected_id) if selected_id >= 0 else {}
	if found.is_empty() or found["where"] != "bag" or not GameData.can_gamble(found["item"]):
		if not spinning:
			selected_id = -1
			wheel.chance = 0
			info.text = "[color=%s]Pick an item to spin for.[/color]" % UI.hex(UI.DIM)
			UI.why(spin_button, "Pick an item from your bag first.")
			spin_button.text = "Spin!"
		wheel.queue_redraw()
		return
	var item: Dictionary = found["item"]
	var r := int(item["rarity"])
	wheel.chance = state.gamble_chance(item)
	var fee := GameData.gamble_fee(item)
	info.text = "[color=%s]%s[/color]\n[color=#4ade80]%d%%[/color] to become [color=%s]%s[/color]\n[color=#f87171]%d%%[/color] to lose it\nFee: %s gold" % [
		GameData.color_of(r), GameData.display_name(item), wheel.chance, GameData.color_of(r + 1), GameData.RARITY_NAMES[r + 1], 100 - wheel.chance, UI.gold(fee)]
	if spinning:
		spin_button.disabled = true
	else:
		UI.why(spin_button, UI.need_gold(state.gold, fee))
	spin_button.text = UI.cost("Spin!", fee)
	wheel.queue_redraw()

func _spin() -> void:
	if leg:
		_spin_leg()
		return
	if high:
		_spin_all()
		return
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
		if not is_instance_valid(self) or not is_inside_tree():
			return  # QA r2 #36: the screen closed (Heroes, Delete) while it spun: the result is already saved
		spinning = false
		var it: Dictionary = res["item"]
		if res["win"]:
			main.sfx.play("legendary" if int(it["rarity"]) >= GameData.LEGENDARY else "level_up")
			wheel.glow_color = UI.GREEN
			result_label.text = "[color=#4ade80][b]WIN![/b][/color] It's now [color=%s]%s[/color]." % [GameData.color_of(int(it["rarity"])), GameData.display_name(it)]
		else:
			main.sfx.play("death")
			wheel.glow_color = Color("#e43b44")
			result_label.text = "[color=#f87171][b]LOST.[/b][/color] The wheel keeps %s." % GameData.display_name(it)
			selected_id = -1
		wheel.glow = 1.0
		create_tween().tween_property(wheel, "glow", 0.0, 1.2)
		shown = ""
		main.refresh()
	if ItemText.is_precious(item) or int(item["rarity"]) >= 3 or item.get("level", 0) > 0:
		main.confirm("Spin for %s?" % GameData.display_name(item), "If you lose, it's gone for good. %d%% chance to win." % state.gamble_chance(item), "Spin", go)
	else:
		go.call()

# =====================================================================
# High stakes
# =====================================================================

func wheel_cap() -> int:
	return mini(MAX_WHEELS, BASE_WHEELS + heat)

func _heat_now() -> int:
	return heat if Time.get_ticks_msec() - last_round_ms <= HEAT_WINDOW_MS else 0

func _toggle_mode() -> void:
	if spinning:
		return
	high = not high
	slate.clear()
	selected_id = -1
	result_label.text = ""
	shown = ""
	main.sfx.play("click")
	refresh()

func _load_rarity(r: int) -> void:
	if spinning:
		return
	var items: Array = state.bag.duplicate()
	items.reverse()
	for it in items:
		if slate.size() >= wheel_cap():
			break
		var id := int(it["id"])
		if int(it["rarity"]) == r and GameData.can_gamble(it) and not ItemText.is_precious(it) and not id in slate and not state.over_limit(id):
			slate.append(id)
	shown = ""
	refresh()

func _slate_items() -> Array:
	var out: Array = []
	for id in slate:
		var f := state.find_item(id)
		if not f.is_empty() and f["where"] == "bag" and GameData.can_gamble(f["item"]):
			out.append(f["item"])
	return out

func _update_high() -> void:
	heat = _heat_now()
	var items := _slate_items()
	slate.clear()
	for it in items:
		slate.append(int(it["id"]))
	var fee := 0
	for it in items:
		fee += GameData.gamble_fee(it)
	var fire := "".rpad(heat, "*")
	heat_label.text = "[color=#f97316][b]HEAT %d[/b] %s[/color]  [color=%s]%d wheels, spins %.1fs. Spin again within %ds to keep it.[/color]" % [
		heat, fire, UI.hex(UI.DIM), wheel_cap(), _spin_time(), HEAT_WINDOW_MS / 1000]
	# One small wheel per loaded item
	if not spinning:
		for c in mini_grid.get_children():
			c.queue_free()
		minis.clear()
		for it in items:
			var w := Wheel.new()
			w.custom_minimum_size = Vector2(112, 112)
			w.chance = state.gamble_chance(it)
			mini_grid.add_child(w)
			minis.append(w)
	info.text = "[color=%s]Tap items to load them onto wheels (up to %d).[/color]" % [UI.hex(UI.DIM), wheel_cap()] if items.is_empty() else \
		"%d wheel%s loaded  ·  fee %s gold\n[color=%s]If every wheel wins, you also win the fees back %d×.[/color]" % [items.size(), "" if items.size() == 1 else "s", UI.gold(fee), UI.hex(UI.DIM), items.size()]
	spin_button.text = UI.cost("Spin %d wheel%s!" % [items.size(), "" if items.size() == 1 else "s"], fee) if not items.is_empty() else "Spin!"
	if spinning:
		spin_button.disabled = true
	else:
		UI.why(spin_button, "Tap items to load them first." if items.is_empty() else UI.need_gold(state.gold, fee))

func _spin_time() -> float:
	return maxf(0.6, 1.5 - 0.15 * float(heat))

func _spin_all() -> void:
	if spinning:
		return
	var items := _slate_items()
	if items.is_empty():
		return
	var risky := items.any(func(it): return ItemText.is_precious(it) or int(it["rarity"]) >= 3 or int(it.get("level", 0)) > 0)
	var go := func():
		spinning = true
		spin_button.disabled = true
		var fee := 0
		var results: Array = []
		for it in items:
			fee += GameData.gamble_fee(it)
			results.append(state.gamble(int(it["id"])))
		main.sfx.play("click")
		var dur := _spin_time()
		var t := create_tween().set_parallel(true)
		for i in mini(results.size(), minis.size()):
			var res: Dictionary = results[i]
			var w: Wheel = minis[i]
			if not res.get("ok", false):
				continue
			var pct: float = randf_range(2.0, float(res["chance"]) - 2.0) if res["win"] else randf_range(float(res["chance"]) + 2.0, 98.0)
			w.angle = 0.0
			t.tween_property(w, "angle", TAU * (3.0 + i * 0.5) + TAU * pct / 100.0, dur + i * 0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			t.tween_method(func(_v): w.queue_redraw(), 0.0, 1.0, dur + i * 0.08)
		await t.finished
		if not is_instance_valid(self) or not is_inside_tree():
			return  # QA r2 #36: the screen closed (Heroes, Delete) while it spun: the result is already saved
		var wins := 0
		var played := 0
		for i in results.size():
			var res: Dictionary = results[i]
			if not res.get("ok", false):
				continue
			played += 1
			if res["win"]:
				wins += 1
			if i < minis.size():
				var w: Wheel = minis[i]
				w.glow_color = UI.GREEN if res["win"] else Color("#e43b44")
				w.glow = 1.0
				create_tween().tween_property(w, "glow", 0.0, 1.0)
		var text := "[color=#4ade80][b]%d won[/b][/color]  [color=#f87171][b]%d lost[/b][/color]" % [wins, played - wins]
		if played >= 2 and wins == played:
			var bonus := fee * played
			state.gold += bonus
			text += "\n[color=#fbbf24][b]CLEAN SWEEP![/b] +%s gold[/color]" % UI.commas(bonus)
			main.sfx.play("legendary")
		else:
			main.sfx.play("level_up" if wins > played - wins else "death")
		result_label.text = text
		# Heat: spin again soon to keep it going
		heat = mini(MAX_WHEELS - BASE_WHEELS, _heat_now() + 1)
		last_round_ms = Time.get_ticks_msec()
		slate.clear()
		spinning = false
		state.save_game()
		shown = ""
		main.refresh()
	if risky:
		main.confirm("Spin them all?", "Lost items are gone for good. Some of these are Epic, upgraded or precious.", "Spin", go)
	else:
		go.call()

# =====================================================================
# Legendary table (2.1): opens at floor 250. Odds come from WheelTables,
# the same table the spin rolls.
# =====================================================================

func _toggle_leg() -> void:
	if spinning:
		return
	leg = not leg
	result_label.text = ""
	shown = ""
	main.sfx.play("click")
	refresh()

func _update_leg() -> void:
	if not WheelTables.legendary_unlocked(state):
		leg_info.text = "[color=%s]%s[/color]\n[color=%s]Pay gold for one spin and win one prize. The top prizes almost never come up; Luck and goblin builds raise their odds. Tap Odds to see every prize.[/color]" % [UI.hex(UI.RED), WheelTables.lock_text(state), UI.hex(UI.DIM)]
		UI.why(spin_button, WheelTables.lock_text(state))
		spin_button.text = "Locked (floor %d)" % WheelTables.LEGENDARY_UNLOCK_FLOOR
		return
	var fort := WheelTables.fortune(state)
	var cost := WheelTables.spin_cost(state)
	leg_info.text = "One spin, one prize. Spins cost gold you found in the dungeon.\nYour Fortune: [color=#facc15]%d[/color]  (Luck and goblin builds)\nTop prizes: [color=#facc15]%s[/color]  [color=%s](base %s)[/color]" % [
		int(fort), WheelTables.pct_text(WheelTables.top_pct(fort)), UI.hex(UI.DIM), WheelTables.pct_text(WheelTables.top_pct(0.0))]
	if spinning:
		spin_button.disabled = true
	else:
		UI.why(spin_button, UI.need_gold(state.gold, cost))
	spin_button.text = UI.cost("Spin!", cost)

func _spin_leg() -> void:
	if spinning:
		return
	spinning = true
	spin_button.disabled = true
	var res := WheelTables.spin_legendary(state)
	spinning = false
	if not res.get("ok", false):
		main.sfx.play("error")
		main.refresh()
		return
	var prize: Dictionary = res["prize"]
	if prize["tier"] == "top":
		main.sfx.play("legendary")
		result_label.text = "[color=#facc15][b]FORTUNE SMILES![/b][/color] %s\n%s" % [prize["name"], res["text"]]
	elif prize["tier"] == "rare":
		main.sfx.play("legendary")
		result_label.text = "[color=#fb923c][b]%s![/b][/color]\n%s" % [prize["name"], res["text"]]
	else:
		main.sfx.play("level_up")
		result_label.text = "[color=#e8b14a]%s[/color]\n%s" % [prize["name"], res["text"]]
	shown = ""
	main.refresh()

## Every prize on both tables, with your odds and the base odds. Read from
## WheelTables: the same numbers the Wheel rolls.
## QA r1 B12: the odds list names the prize once: "Scroll of Luck  ×1, kept for later", not
## "Scroll of Luck  1 Scroll of Luck, kept for later".
static func _odds_amount(prize: String, amount: String) -> String:
	var nm := prize.trim_prefix("A ").trim_prefix("An ")
	var sp := amount.find(" ")
	if sp > 0 and amount.left(sp).is_valid_int() and amount.substr(sp + 1).begins_with(nm):
		return "×%s%s" % [amount.left(sp), amount.substr(sp + 1 + nm.length())]
	return amount

func show_odds() -> void:
	var o := Overlay.new().open(main, "Wheel odds", 480.0, UI.GOLD)
	o.content.add_child(UI.heading("Item Wheel"))
	o.content.add_child(UI.wrap("Win: the item comes back one rarity higher. Lose: it's gone.", UI.FONT_BODY, UI.DIM))
	var nt := UI.rich(UI.FONT_BODY)
	var lines: Array = []
	for row in WheelTables.normal_rows():
		lines.append("[color=%s]%s[/color] to %s: [b]%d%%[/b]" % [GameData.color_of(int(row["rarity"])), row["name"], row["to"], int(row["pct"])])
	nt.text = "\n".join(lines)
	o.content.add_child(nt)
	o.content.add_child(UI.heading("Legendary table"))
	var fort := WheelTables.fortune(state)
	if not WheelTables.legendary_unlocked(state):
		o.content.add_child(UI.wrap(WheelTables.lock_text(state), UI.FONT_BODY, UI.RED))
	var parts: Array = []
	for p in WheelTables.fortune_parts(state):
		if float(p[1]) > 0.0:
			parts.append("%s +%d" % [p[0], int(p[1])])
	var src := ("  (" + ", ".join(parts) + ")") if not parts.is_empty() else ""
	o.content.add_child(UI.wrap("Your Fortune: %d%s. Each point raises top prizes by %d%% (up to ×%d) and Legendary items by %d%% (up to ×%d)." % [
		int(fort), src, int(round(WheelTables.TOP_PER_POINT * 100)), int(WheelTables.TOP_CAP),
		int(round(WheelTables.RARE_PER_POINT * 100)), int(WheelTables.RARE_CAP)], UI.FONT_CAPTION, UI.DIM))   # QA r1 D3
	var lt := UI.rich(UI.FONT_BODY)
	lines = []
	var rows := WheelTables.legendary_rows(fort)
	for i in rows.size():
		var row: Dictionary = rows[i]
		var col: String = "#facc15" if row["tier"] == "top" else ("#fb923c" if row["tier"] == "rare" else UI.hex(UI.TEXT))
		var amount := _odds_amount(String(row["name"]), String(WheelTables.prize_amount(state, WheelTables.LEGENDARY_PRIZES[i])))
		lines.append("[color=%s]%s[/color]  [color=%s]%s[/color]\n   yours [b]%s[/b]   [color=%s]base %s[/color]" % [col, row["name"], UI.hex(UI.DIM), amount, WheelTables.pct_text(row["pct"]), UI.hex(UI.DIM), WheelTables.pct_text(row["base_pct"])])
	lt.text = "\n".join(lines)
	o.content.add_child(lt)
	o.content.add_child(UI.wrap("Amounts are for your deepest floor (%d): gold and scrap prizes grow the deeper you go. A spin needs %d free bag slots. Spins are paid with gold found in the dungeon. They are never sold for real money." % [state.best_floor, WheelTables.bag_room_needed()], UI.FONT_BODY, UI.DIM))
	var close := UI.primary("Close", o.close)
	close.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(close)
