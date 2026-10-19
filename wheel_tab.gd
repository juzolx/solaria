class_name WheelTab
extends BoxContainer
## Town > Wheel: Fortune's Wheel. Bet an item: win and it comes back one
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
# High stakes: bet several items at once, each on its own wheel. Spinning again
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
	vertical = (m as Node).get_viewport().get_visible_rect().size.x < 720.0  # phones: the wheel sits under the items
	add_theme_constant_override("separation", 12)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(left)
	left.add_child(UI.label("FORTUNE'S WHEEL", 18, UI.GOLD))
	var note := UI.label("Bet an item. Win: it comes back one rarity higher. Lose: it's gone. Common %d%%, Uncommon %d%%, Rare %d%%, Epic %d%%." % GameData.GAMBLE_CHANCES, 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(note)
	left.add_child(UI.label("TAP AN ITEM TO BET IT  (its odds are on it)", 11, UI.DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	grid = ItemGrid.grid()
	sv.add_child(grid)
	empty_note = UI.label("Nothing to bet. Locked items and Legendary or better can't go on the wheel.", 12, UI.DIM)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(empty_note)
	left.resized.connect(_on_left_resized.bind(left))
	var right := UI.vbox(8)
	right.custom_minimum_size = Vector2(250, 0)
	add_child(right)
	mode_button = UI.button("", _toggle_mode)
	mode_button.custom_minimum_size = Vector2(0, UI.TAP)
	right.add_child(mode_button)
	var nb := UI.vbox(8)
	right.add_child(nb)
	normal_box = nb
	wheel = Wheel.new()
	wheel.custom_minimum_size = Vector2(230, 230)
	nb.add_child(wheel)
	high_box = UI.vbox(6)
	high_box.visible = false
	right.add_child(high_box)
	heat_label = UI.rich(12)
	high_box.add_child(heat_label)
	mini_grid = GridContainer.new()
	mini_grid.columns = 2
	mini_grid.add_theme_constant_override("h_separation", 6)
	mini_grid.add_theme_constant_override("v_separation", 6)
	high_box.add_child(mini_grid)
	load_row = UI.hbox(4)
	high_box.add_child(load_row)
	for r in [0, 1, 2]:
		var lb := UI.button("+ all %s" % GameData.RARITY_NAMES[r], _load_rarity.bind(r))
		lb.add_theme_color_override("font_color", Color(GameData.color_of(r)))
		lb.add_theme_font_size_override("font_size", 11)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load_row.add_child(lb)
	info = UI.rich(13)
	right.add_child(info)
	spin_button = UI.primary("Spin!", _spin, UI.GOLD)
	spin_button.custom_minimum_size = Vector2(0, 44)
	right.add_child(spin_button)
	result_label = UI.rich(15)
	right.add_child(result_label)

func _on_left_resized(left: Control) -> void:
	ItemGrid.fit([grid], left.size.x)

func _pick(id: int) -> void:
	if spinning:
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

func refresh() -> void:
	vertical = main.get_viewport().get_visible_rect().size.x < 720.0  # phones: the wheel sits under the items
	var key := "%d|%d|%d|%s|%s" % [state.bag_version, state.gold, selected_id, str(slate), high]
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
			grid.add_child(ItemGrid.cell(item, _pick.bind(id), sel, ItemGrid.CELL, "%d%%" % state.gamble_chance(item)))
			ids.append(id)
		empty_note.visible = ids.is_empty()
	_update()

func _update() -> void:
	mode_button.text = "High stakes: ON  (many wheels at once)" if high else "High stakes: OFF  (one wheel)"
	normal_box.visible = not high
	high_box.visible = high
	if high:
		_update_high()
		return
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
		if int(it["rarity"]) == r and GameData.can_gamble(it) and not ItemText.is_precious(it) and not id in slate:
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
		"%d wheel%s loaded  -  fee %d gold\n[color=%s]If every wheel wins, you also win the fees back %dx.[/color]" % [items.size(), "" if items.size() == 1 else "s", fee, UI.hex(UI.DIM), items.size()]
	spin_button.text = "Spin %d wheel%s! (%d gold)" % [items.size(), "" if items.size() == 1 else "s", fee] if not items.is_empty() else "Spin!"
	spin_button.disabled = spinning or items.is_empty() or state.gold < fee

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
				w.glow_color = Color("#4ade80") if res["win"] else Color("#f87171")
				w.glow = 1.0
				create_tween().tween_property(w, "glow", 0.0, 1.0)
		var text := "[color=#4ade80][b]%d won[/b][/color]  [color=#f87171][b]%d lost[/b][/color]" % [wins, played - wins]
		if played >= 2 and wins == played:
			var bonus := fee * played
			state.gold += bonus
			text += "\n[color=#fbbf24][b]CLEAN SWEEP![/b] +%d gold[/color]" % bonus
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
		main.confirm("Bet them all?", "Lost items are gone for good. Some of these are Epic, upgraded or precious.", "Spin", go)
	else:
		go.call()
