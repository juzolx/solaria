class_name DeathScreen
extends RefCounted
## Interface pass (approved mockups 18 and 19): what you see when you fall.
## Regular: a card over the fight: where you fell, what you keep, what you lose (and where
## it waits), what hurt you most and a tip. Hardcore: the hero is gone for good, a headstone,
## the run in one line, and the way on. Built here so main.gd only hands over.

const KEEP := ["The Bank, the Vault and the Mailbox", "Your levels and XP", "Bound items"]

## The Regular fall card. r = GameState.last_death (Combat.recap + "lost" / "woke").
static func regular(r: Dictionary, on_ok: Callable, on_never: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(Color(UI.PANEL, 0.97), Color("#a22633"), 14))
	var v := UI.vbox(6)
	p.add_child(v)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiSkin.bevel(UiSkin.SLATE, UI.GOLD_DULL, 6))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(plate)
	var title := UI.label("You fell on floor %d" % int(r.get("floor", 0)), 19, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(title)
	var who := UI.wrap("%s got you.%s" % [String(r.get("enemy", "A monster")),
		(" You wake at the checkpoint on floor %d." % int(r["woke"])) if r.has("woke") else ""], UI.FONT_BODY, UI.TEXT)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(who)
	# What you keep / what you lose
	v.add_child(_head("You keep"))
	for k in KEEP:
		v.add_child(_pair(k, "kept", UI.GREEN))
	var lost := String(r.get("lost", ""))
	if r.has("woke"):
		v.add_child(_head("You lose"))
		var ll := UI.wrap(lost if lost != "" else "Nothing: you carried nothing in.", UI.FONT_BODY, UI.RED if lost != "" else UI.DIM)
		v.add_child(ll)
		if lost.contains("guarded by your killer"):
			var back := UI.wrap("Beat %s on floor %d to get it all back." % [String(r.get("enemy", "it")), int(r.get("floor", 0))], UI.FONT_BODY, UI.GOLD)
			v.add_child(back)
	# What hurt, in one line, and the tips
	var taken: Dictionary = r.get("taken", {})
	var total := maxf(1.0, float(r.get("total", 0)))
	var names := {"hits": "its hits", "burning": "burning", "burn": "burns", "poison": "poison", "minions": "minions", "realm": "the realm", "hazard": "the room", "bleed": "bleeding"}
	var keys := taken.keys()
	keys.sort_custom(func(a, b): return int(taken[a]) > int(taken[b]))
	var parts: Array = []
	for k in keys.slice(0, 3):
		parts.append("%s %d%%" % [names.get(k, String(k)), int(round(float(taken[k]) * 100.0 / total))])
	if not parts.is_empty():
		v.add_child(UI.wrap("What hurt: %s. It had %d%% health left." % [", ".join(parts), int(float(r.get("enemy_left", 0.0)) * 100)], UI.FONT_BODY, UI.DIM))
	for tip_text in r.get("tips", []):
		var t := UI.rich(UI.FONT_BODY)
		t.text = "[color=%s]Tip:[/color] %s" % [UI.hex(UI.GOLD), tip_text]
		v.add_child(t)
	var ok := UI.primary("OK", on_ok)
	ok.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(ok)
	var never := UI.button("Don't show these again", on_never)
	never.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(never)
	# Fable r1 #15: the fight dims under the card (like the Hardcore Overlay): a screen-wide
	# veil drawn just under the card, above the action row and the nav bar
	p.z_index = 60
	var veil := ColorRect.new()
	veil.color = Color(UiSkin.SOOT, 0.62)
	veil.top_level = true
	veil.show_behind_parent = true
	veil.mouse_filter = Control.MOUSE_FILTER_STOP   # taps on the dimmed fight do nothing
	p.add_child(veil, false, Node.INTERNAL_MODE_FRONT)
	p.ready.connect(func():
		veil.position = Vector2.ZERO
		veil.size = p.get_viewport_rect().size)
	return p

## The Hardcore farewell, filled into an open Overlay's content box.
static func hardcore(content: VBoxContainer, hero: String, level: int, race: String, title: String, floor_num: int,
		new_best: bool, best: int, on_again: Callable, on_title: Callable) -> void:
	var stone := Control.new()   # a small headstone, drawn on the 2x grid in palette colours
	stone.custom_minimum_size = Vector2(0, 92)
	stone.draw.connect(func(): _draw_stone(stone))
	content.add_child(stone)
	var name_l := UI.label("%s is gone" % hero, 21, Color("#f6757a"))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_l)
	var line := UI.wrap("Level %d %s %s. Fell on floor %d. Hardcore heroes get one life." % [level, race, title, floor_num], UI.FONT_BODY, UI.TEXT)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(line)
	var rec := UI.label("A new Hardcore record!" if new_best else "Your best is still floor %d." % best, UI.FONT_BODY, UI.GOLD if new_best else UI.DIM)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(rec)
	content.add_child(_head("What stays"))
	content.add_child(_pair("Their kills in your Bestiary", "kept", UI.GREEN))
	content.add_child(_pair("This hero, their gear and bag", "lost", UI.RED))
	var row := UI.hbox(8)
	content.add_child(row)
	var back := UI.button("Title screen", on_title)
	var again := UI.danger("New Hardcore hero", on_again)
	for b in [back, again]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(b)

static func _head(t: String) -> Control:
	return UI.heading(t)

static func _pair(what: String, state_text: String, col: Color) -> HBoxContainer:
	var h := UI.hbox(8)
	var l := UI.label(what, UI.FONT_BODY, UI.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	h.add_child(UI.label(state_text, UI.FONT_BODY, col))
	return h

## Ink outline, slate stone with a lit top edge, a carved cross, a strip of ground.
static func _draw_stone(c: Control) -> void:
	var px := float(UiSkin.PX)
	var w := 16.0 * px
	var h := 22.0 * px
	var x := roundf((c.size.x - w) / 2.0)
	var y := 6.0
	c.draw_rect(Rect2(x, y, w, h), UiSkin.SOOT)
	c.draw_rect(Rect2(x + px, y + px, w - 2 * px, h - 2 * px), Color("#3a4466"))
	c.draw_rect(Rect2(x + px, y + px, w - 2 * px, px), Color("#5a6988"))
	c.draw_rect(Rect2(x + w / 2.0 - px / 2.0 - px / 2.0, y + 4 * px, px, 9 * px), Color("#8b9bb4"))
	c.draw_rect(Rect2(x + w / 2.0 - 3 * px, y + 7 * px, 6 * px, px), Color("#8b9bb4"))
	c.draw_rect(Rect2(x - 6 * px, y + h, w + 12 * px, 3 * px), UiSkin.SOOT)
	c.draw_rect(Rect2(x - 5 * px, y + h, w + 10 * px, px), Color("#265c42"))
