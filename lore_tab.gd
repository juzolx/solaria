class_name LoreTab
extends ScrollContainer
## Codex > Lore: the pages of Solaria's story you've found (lore.gd), in order.

var main
var codex: Codex
var box: VBoxContainer
var shown := -1

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Lore"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	codex = main.codex
	if codex.lore.size() == shown:
		return
	shown = codex.lore.size()
	OnlineUI.clear(box)
	var head := UI.label("Pages found: %d / %d" % [codex.lore.size(), Lore.PAGES.size()], 15, UI.GOLD)
	box.add_child(head)
	if codex.lore.is_empty():
		var hint := UI.label("Torn pages turn up in the dungeon: now and then on a fallen monster, more often in chests. Each one tells a little more of Solaria's story.", 13, UI.DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)
		return
	for i in Lore.PAGES.size():
		var found := i < codex.lore.size()
		var card := UI.panel(UI.INSET, UI.BORDER if found else Color(0.2, 0.2, 0.25), 8, 10, 1)
		box.add_child(card)
		var v := UI.vbox(4)
		card.add_child(v)
		v.add_child(UI.label(("%d. %s" % [i + 1, Lore.PAGES[i][0]]) if found else "%d. ???" % (i + 1), 14, Color("#e8b14a") if found else UI.DIM))
		if found:
			var t := UI.label(String(Lore.PAGES[i][1]), 13, UI.TEXT)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(t)
		if not found:
			break  # only the next missing page shows, as a "???"
