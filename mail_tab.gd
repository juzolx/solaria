class_name MailTab
extends ScrollContainer
## Town › Mailbox: letters with rewards (bounties, deeds, news and gifts).
## Each letter shows its gear as pictures. Collect takes what fits your bag;
## anything that doesn't fit waits in the letter. Mail is always safe.

var main
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	name = "Mailbox"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var g: GameState = main.state
	var key := "%s|%d|%d" % [str(g.mail), g.bag.size(), g.bag_capacity()]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var head := UI.hbox(8)
	box.add_child(head)
	var title := UI.heading("Mailbox")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var waiting := Mail.waiting(g)
	var all := UI.primary("Collect all (%d)" % waiting, _collect_all, UI.GREEN)
	all.disabled = waiting == 0
	head.add_child(all)
	var note := UI.label("Rewards from bounties, deeds and gifts arrive here. Mail is always safe: it can't be lost in the dungeon. Gear that doesn't fit in your bag (%d / %d) waits in its letter." % [g.bag.size(), g.bag_capacity()], UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	if g.mail.is_empty():
		var empty := UI.label("No mail yet. Finish a bounty or a deed and your reward comes here.", UI.FONT_BODY, UI.DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
		return
	var letters: Array = g.mail.duplicate()
	letters.reverse()   # newest first
	var has_empty := false
	for l in letters:
		box.add_child(_letter(l))
		has_empty = has_empty or Mail.is_empty(l)
	if has_empty:
		var clear := UI.button("Throw away opened letters", func():
			Mail.delete_empty(main.state)
			main.sfx.play("click")
			main.refresh())
		clear.custom_minimum_size = Vector2(0, UI.TAP)
		box.add_child(clear)
	# Seeing the mail counts as reading it
	var marked := false
	for l in g.mail:
		if not l.get("read", false):
			l["read"] = true
			marked = true
	if marked:
		shown = "%s|%d|%d" % [str(g.mail), g.bag.size(), g.bag_capacity()]
		g.save_game()

func _letter(l: Dictionary) -> PanelContainer:
	var empty := Mail.is_empty(l)
	var fresh: bool = not l.get("read", false)
	var card := UI.panel(Color("#141a2b") if not empty else UI.INSET, UI.GOLD if fresh else (UI.BORDER if empty else Color("#8a6d2e")), 6, 10, 2 if fresh else 1)
	var v := UI.vbox(4)
	card.add_child(v)
	var top := UI.hbox(8)
	v.add_child(top)
	if fresh:
		top.add_child(UI.chip("NEW", UI.GOLD, UI.FONT_BODY))
	var t := UI.label(String(l["title"]), UI.FONT_BODY, UI.DIM if empty else UI.TEXT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var when := Time.get_date_string_from_unix_time(int(l.get("time", 0)))
	top.add_child(UI.label(when, UI.FONT_BODY, UI.DIM))
	v.add_child(UI.label("From: %s" % l["from"], UI.FONT_BODY, UI.DIM))
	var body := UI.label(String(l["body"]), UI.FONT_BODY, UI.TEXT if not empty else UI.DIM)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	if empty:
		v.add_child(UI.label("Collected.", UI.FONT_BODY, UI.DIM))
		return card
	# What's inside: gear as pictures, the rest in words
	var items: Array = l["items"]
	if not items.is_empty():
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 4)
		row.add_theme_constant_override("v_separation", 4)
		v.add_child(row)
		for it in items:
			row.add_child(ItemGrid.cell(it, _peek.bind(it), false, 46))
	var other := Mail.summary({"gold": l["gold"], "scrap": l["scrap"], "potions": l["potions"], "extra": l["extra"], "items": []})
	if other != "":
		var r := UI.rich(UI.FONT_BODY)
		r.text = "[color=#f6d88f]%s[/color]" % other
		v.add_child(r)
	var id := String(l["id"])
	var full: bool = not items.is_empty() and main.state.bag_full() and other == ""
	var b := UI.primary("Bag full" if full else "Collect", _collect.bind(id), UI.GREEN)
	b.custom_minimum_size = Vector2(120, UI.TAP)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.disabled = full
	if full:
		b.tooltip_text = "Sell, salvage or stash something to make room. The gear waits here."
	v.add_child(b)
	return card

func _peek(item: Dictionary) -> void:
	main.sfx.play("click")
	ItemPopup.show_item(main, item, [])

func _collect(id: String) -> void:
	if Mail.collect(main.state, id) != "":
		main.sfx.play("buy")
	shown = ""
	main.refresh()

func _collect_all() -> void:
	if Mail.collect_all(main.state) > 0:
		main.sfx.play("buy")
	shown = ""
	main.refresh()
