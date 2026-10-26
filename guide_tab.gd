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
var shown := ""
var chips: HFlowContainer   # phones: the topics as chips above the article (the list is for wide screens)

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Guide"
	add_theme_constant_override("separation", 10)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(190, 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", UI.FONT_BODY)
	list.add_theme_constant_override("v_separation", UI.TAP - 20)  # rows about 44 px tall: a comfortable tap
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
	chips = HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	v.add_child(chips)
	title_label = UI.label("", UI.FONT_TITLE, UI.GOLD)
	v.add_child(title_label)
	text = UI.rich(UI.FONT_BODY)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(text)

func refresh() -> void:
	var narrow := bool(main.is_tall)
	var key := "%d|%s" % [codex.guide.size(), narrow]
	if shown == key:
		return
	shown = key
	list.visible = not narrow
	chips.visible = narrow
	OnlineUI.clear(chips)
	list.clear()
	ids.clear()
	# 0.13+: only the pages you've found, then one line for the rest (no wall of "???")
	var missing := 0
	for p in Guide.PAGES:
		if not codex.guide.has(p["id"]):
			missing += 1
			continue
		list.add_item(p["title"])
		ids.append(p["id"])
		if narrow:
			var id: String = p["id"]
			var b := UI.button(String(p["title"]), func():
				selected = id
				_show())
			b.custom_minimum_size = Vector2(0, UI.BUTTON_H)
			b.focus_mode = Control.FOCUS_NONE
			b.set_meta("id", id)
			chips.add_child(b)
		if selected == "":
			selected = p["id"]
	if missing > 0:
		var mi := list.add_item("+ %d more to discover" % missing)
		list.set_item_selectable(mi, false)
		list.set_item_custom_fg_color(mi, UI.DIM)
		ids.append("")
		if narrow:
			var lc := UI.chip("+%d locked" % missing, UI.DIM, UI.FONT_BODY)
			lc.tooltip_text = "More pages unlock as you play."
			chips.add_child(lc)
	_show()

func _show() -> void:
	var p := Guide.page(selected)
	title_label.text = p.get("title", "Nothing here yet")
	text.text = p.get("text", "Guide pages unlock as you play.")
	for c in chips.get_children():
		if c is Button:
			var on: bool = String(c.get_meta("id", "")) == selected
			(c as Button).add_theme_color_override("font_color", UI.GOLD if on else UI.TEXT)
			(c as Button).add_theme_stylebox_override("normal", UiSkin.bevel(UiSkin.SLATE, UI.GOLD_DULL, 6) if on else UiSkin.bevel(UI.PANEL, UI.EMPTY, 6))
	if codex.stat("guide_skip") > 0:
		text.text += "\n\n[color=%s](New pages won't pop up because you skipped the guide.)[/color]" % UI.hex(UI.DIM)
