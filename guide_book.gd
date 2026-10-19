class_name GuideBook
extends Overlay
## The guide book: a little book that pops up when a new page unlocks.
## "Skip the guide" stops the pop-ups (pages still unlock and stay readable
## in Codex > Guide and on the title screen).

var m
var codex: Codex
var page_id := ""
var text: RichTextLabel
var title_label: Label
var list: VBoxContainer
var popped := false

## Opens the book on a page ("" = the first page you have).
static func open_book(main_node, id: String, as_popup := false) -> GuideBook:
	var g := GuideBook.new()
	g._show(main_node, id, as_popup)
	return g

func _show(main_node, id: String, as_popup: bool) -> void:
	m = main_node
	codex = m.codex
	popped = as_popup
	open(m, "Guide book", 820.0, Color("#c28569"))
	# Side by side on wide screens; on phones the page list sits above the page
	var narrow := is_narrow()
	var body := BoxContainer.new()
	body.vertical = narrow
	body.add_theme_constant_override("separation", 10 if narrow else 14)
	content.add_child(body)
	var left := UI.panel(UI.INSET, UI.BORDER, 8, 8, 1)
	left.custom_minimum_size = Vector2(0, 150) if narrow else Vector2(210, 300)
	body.add_child(left)
	var ls := ScrollContainer.new()
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(ls)
	list = UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(list)
	var page_panel := UI.panel(Color("#1b1712"), Color("#c28569"), 8, 18, 2)
	page_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(page_panel)
	var pv := UI.vbox(10)
	page_panel.add_child(pv)
	title_label = UI.label("", 20, Color("#f6d88f"))
	pv.add_child(title_label)
	text = UI.rich(14)
	text.custom_minimum_size = Vector2(0 if narrow else 380, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(text)
	var row := UI.hbox(8)
	content.add_child(row)
	if as_popup:
		var skip := UI.button("Skip the guide", func():
			codex.at_least("guide_skip", 1)
			codex.guide_queue.clear()
			codex.save()
			close())
		skip.tooltip_text = "Stop showing new pages. You can still read them in Codex > Guide."
		row.add_child(skip)
	row.add_child(UI.spacer())
	var ok := UI.primary("Got it", close, UI.GOLD)
	ok.custom_minimum_size = Vector2(140, 40)
	row.add_child(ok)
	if id == "":
		for p in Guide.PAGES:
			if codex.guide.has(p["id"]):
				id = p["id"]
				break
	_show_page(id)
	if m.timer:
		m.timer.paused = true
		tree_exiting.connect(func(): m.timer.paused = false)

func _show_page(id: String) -> void:
	page_id = id
	if m.sfx:
		m.sfx.play("page")
	OnlineUI.clear(list)
	for p in Guide.PAGES:
		var have := codex.guide.has(p["id"])
		var b := UI.button(p["title"] if have else "???", _show_page.bind(p["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not have
		b.add_theme_font_size_override("font_size", UI.MIN_FONT)
		if p["id"] == id:
			b.add_theme_color_override("font_color", UI.GOLD)
		list.add_child(b)
	var pg := Guide.page(id)
	if pg.is_empty():
		title_label.text = "Nothing here yet"
		text.text = "Pages unlock as you play."
		return
	title_label.text = pg["title"]
	text.text = pg["text"]
