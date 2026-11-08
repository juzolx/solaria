class_name TravelerPopup
extends Overlay
## Next update: talking to a traveler in the dungeon (travelers.gd). Their face,
## what they say, and two choices.

var m
var prop: Dictionary

func show_for(main_node, p: Dictionary) -> void:
	m = main_node
	prop = p
	var who := Travelers.info(String(p.get("who", "")))
	open(m, String(who["name"]), 520.0, Color(who["color"]))
	var h := UI.hbox(12)
	content.add_child(h)
	# QA r1 C1: whole screen pixels (PixelPic), not 64 px art stretched into a 72 box
	var pic := PixelPic.make(Travelers.portrait(String(p.get("who", ""))), 0, 72.0 / 64.0)
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(pic)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var ttl := String(who["title"])
	v.add_child(UI.label(ttl.left(1).to_upper() + ttl.substr(1), UI.FONT_BODY, UI.DIM))
	v.add_child(UI.wrap(String(who["line"]), UI.FONT_BODY, UI.TEXT))
	var st: GameState = m.state
	for n in 2:
		var o: Dictionary = who["offers"][n]
		var cost := Travelers.cost_text(st, o)
		# QA r1 B1: "Buy the map · 3,660 gold", the house way
		var b := UI.primary(String(o["text"]) + ((" · %s" % cost) if cost != "" else ""), _choose.bind(n), UI.GOLD if n == 0 else UI.BORDER)
		b.custom_minimum_size = Vector2(0, UI.TAP)
		UI.why(b, "" if Travelers.can_pay(st, o) else "You can't pay for that.")
		content.add_child(b)

func _choose(n: int) -> void:
	var st: GameState = m.state
	var out := Travelers.choose(st, prop, n)
	close()
	if out != "":
		m.toast(out)
	Halls._done(st)
	m.refresh()
