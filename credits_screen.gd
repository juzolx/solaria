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
	game[1].add_child(UI.wrap(CreditsData.GAME["by"], UI.FONT_CAPTION))
	game[1].add_child(UI.wrap(CreditsData.GAME["line"], UI.FONT_CAPTION, UI.DIM))
	for group in CreditsData.GROUPS:
		UI.section(c, group)
		for s in CreditsData.in_group(group):
			c.add_child(_entry(s))

func _entry(s: Dictionary) -> Control:
	var card := UI.card(UI.BORDER)
	var v: VBoxContainer = card[1]
	v.add_child(UI.wrap(s["name"], UI.FONT_CAPTION, UI.GOLD))
	v.add_child(UI.wrap(s["author"] if String(s["author"]).begins_with("Many") else "By " + s["author"], UI.FONT_CAPTION))
	v.add_child(UI.wrap("License: " + s["license"], UI.FONT_CAPTION, Color("#c9a36a")))
	v.add_child(UI.wrap(s["used"], UI.FONT_CAPTION, UI.DIM))
	if s["link"] != "-":
		v.add_child(UI.wrap(s["link"], UI.FONT_CAPTION, UI.DIM))
	if s.has("notice"):
		var n := UI.rich(UI.FONT_CAPTION)
		n.text = s["notice"]
		v.add_child(n)
	return card[0]
