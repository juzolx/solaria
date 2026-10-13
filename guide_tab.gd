class_name GuideTab
extends HBoxContainer
## Codex > Guide: every guide page you've unlocked, to read any time.

var main
var codex: Codex
var list: ItemList
var ids: Array[String] = []
var title_label: Label
var text: RichTextLabel
var selected := ""
var shown := -1

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Guide"
	add_theme_constant_override("separation", 10)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(190, 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(i: int):
		if ids[i] != "":
			selected = ids[i]
			_show())
	add_child(list)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	title_label = UI.label("", 18, Color("#f6d88f"))
	v.add_child(title_label)
	text = UI.rich(14)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(text)

func refresh() -> void:
	if shown == codex.guide.size():
		return
	shown = codex.guide.size()
	list.clear()
	ids.clear()
	for p in Guide.PAGES:
		var have := codex.guide.has(p["id"])
		var i := list.add_item(p["title"] if have else "???  (keep playing)")
		list.set_item_selectable(i, have)
		list.set_item_custom_fg_color(i, UI.TEXT if have else UI.DIM)
		ids.append(p["id"] if have else "")
		if have and selected == "":
			selected = p["id"]
	_show()

func _show() -> void:
	var p := Guide.page(selected)
	title_label.text = p.get("title", "Nothing here yet")
	text.text = p.get("text", "Guide pages unlock as you play.")
	if codex.stat("guide_skip") > 0:
		text.text += "\n\n[color=%s](New pages won't pop up because you skipped the guide.)[/color]" % UI.hex(UI.DIM)
