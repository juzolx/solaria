class_name CabinTab
extends ScrollContainer
## Town > Trophy Cabin (2.1 G3): this town's proudest moments on the shelves.
## Purely for show (trophies never give power). Bigger cabins hold more.

var main
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	name = "Trophy Cabin"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var p: Profile = main.profile
	var key := "%d|%d|%d|%d" % [Trophies.data.size(), Trophies.slots(), p.max_floor, main.state.best_floor]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	box.add_child(UI.heading("Trophy Cabin"))
	if not Buildings.built("cabin"):
		box.add_child(UI.wrap("An empty lot. Build the cabin (above) and %s gets a place to hang its trophies. They are already being counted: %d so far." % [p.town_name(p.town), Trophies.data.size()], 13, UI.DIM))
		return
	box.add_child(UI.wrap("The pride of %s. Every boss slain, Calamity ended, God class that answered, rare find and great depth goes on the wall. Just for show." % p.town_name(p.town), UI.FONT_BODY, UI.DIM))
	box.add_child(UI.heading("Deepest floor", "Floor %d in this town" % maxi(p.max_floor, main.state.best_floor)))
	var all := Trophies.all()
	var on_show := Trophies.shown()
	box.add_child(UI.label("ON DISPLAY  %d / %d" % [on_show.size(), Trophies.slots()], 11, UI.DIM))
	if all.is_empty():
		box.add_child(UI.wrap("The shelves are bare. Slay a boss to hang your first trophy.", UI.FONT_BODY, UI.DIM))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for t in on_show:
		var k: Array = Trophies.KINDS.get(String(t["kind"]), ["Trophy", "#e8b14a"])
		var card := UI.panel(UI.INSET, Color(String(k[1])).darkened(0.25), 8, 8, 2)
		card.custom_minimum_size = Vector2(150, 0)
		var v := UI.vbox(2)
		card.add_child(v)
		v.add_child(UI.label(String(k[0]).to_upper(), UI.FONT_BODY, Color(String(k[1]))))
		v.add_child(UI.wrap(String(t["name"]), UI.FONT_BODY, UI.TEXT))
		v.add_child(UI.label("%s  ·  %s" % [String(t.get("hero", "")), String(t.get("date", ""))], 10, UI.DIM))
		grid.add_child(card)
	if all.size() > on_show.size():
		box.add_child(UI.wrap("%d more trophies wait in the back room. A bigger cabin shows more." % (all.size() - on_show.size()), UI.FONT_BODY, UI.DIM))
