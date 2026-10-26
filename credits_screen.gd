class_name CreditsScreen
extends RefCounted
## Menu > Credits: who made Solaria, then every asset source by group (data: credits_data.gd).

var overlay: Overlay

func show_for(main: Node) -> Overlay:
	overlay = Overlay.new().open(main, "Credits", 640.0, UI.GOLD)
	_build(overlay.content)
	return overlay

func _build(c: VBoxContainer) -> void:
	var game := UI.card(UI.GOLD)
	c.add_child(game[0])
	game[1].add_child(UI.label(CreditsData.GAME["title"], 20, UI.GOLD))
	game[1].add_child(UI.wrap(CreditsData.GAME["by"], UI.FONT_BODY))
	game[1].add_child(UI.wrap(CreditsData.GAME["line"], UI.FONT_BODY, UI.DIM))
	for group in CreditsData.GROUPS:
		UI.section(c, group)
		for s in CreditsData.in_group(group):
			c.add_child(_entry(s))
	UI.section(c, "Townsfolk parts, one by one", "Every artist behind the LPC parts the town's walkers are built from, with each part's licenses.")
	var lpc := UI.rich(UI.FONT_BODY)
	lpc.text = Credits.TEXT
	lpc.visible = false
	var tog := UI.button("Show the full LPC list", func(): pass)
	tog.pressed.connect(func():
		lpc.visible = not lpc.visible
		tog.text = "Hide the LPC list" if lpc.visible else "Show the full LPC list")
	c.add_child(tog)
	c.add_child(lpc)

func _entry(s: Dictionary) -> Control:
	var card := UI.card(UI.BORDER)
	var v: VBoxContainer = card[1]
	v.add_child(UI.wrap(s["name"], UI.FONT_BODY, UI.GOLD))
	v.add_child(UI.wrap(s["author"] if String(s["author"]).begins_with("Many") else "By " + s["author"], UI.FONT_BODY))
	v.add_child(UI.wrap("License: " + s["license"], UI.FONT_BODY, Color("#c9a36a")))
	v.add_child(UI.wrap(s["used"], UI.FONT_BODY, UI.DIM))
	if s["link"] != "-":
		v.add_child(UI.wrap(s["link"], UI.FONT_BODY, UI.DIM))
	if s.has("notice"):
		var n := UI.rich(UI.FONT_BODY)
		n.text = s["notice"]
		v.add_child(n)
	return card[0]
