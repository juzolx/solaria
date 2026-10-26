class_name AchievementsTab
extends VBoxContainer
## Town > Guild Hall: your deeds (achievements). Each one's reward (gold and a
## piece of gear by how hard it was) is sent to the Mailbox as soon as you earn it. Some give a title you can
## show next to your hero's name.

var main
var codex: Codex
var head: Label
var title_pick: OptionButton
var color_pick: OptionButton
var frame_pick: OptionButton
var box: VBoxContainer
var shown := 0
var shop_open := false  # the looks shop list is folded away until you open it

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Guild Hall"
	add_theme_constant_override("separation", 8)
	var top := UI.hbox(8)
	add_child(top)
	head = UI.label("", 15, UI.GOLD)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head)
	top.add_child(UI.label("Title:", UI.FONT_BODY, UI.DIM))
	title_pick = OptionButton.new()
	title_pick.item_selected.connect(func(i: int):
		codex.title = "" if i == 0 else title_pick.get_item_text(i)
		codex.save()
		main.refresh())
	top.add_child(title_pick)
	# Name colors and plate frames earned by deeds (looks only)
	var looks := UI.hbox(8)
	add_child(looks)
	looks.add_child(UI.label("Name:", UI.FONT_BODY, UI.DIM))
	color_pick = OptionButton.new()
	color_pick.fit_to_longest_item = false  # long locked names would push the screen wider than a phone
	color_pick.clip_text = true
	color_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_pick.item_selected.connect(func(i: int):
		codex.name_color = String(color_pick.get_item_metadata(i))
		codex.save()
		main.refresh())
	looks.add_child(color_pick)
	looks.add_child(UI.label("Frame:", UI.FONT_BODY, UI.DIM))
	frame_pick = OptionButton.new()
	frame_pick.fit_to_longest_item = false
	frame_pick.clip_text = true
	frame_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_pick.item_selected.connect(func(i: int):
		codex.frame = String(frame_pick.get_item_metadata(i))
		codex.save()
		main.refresh())
	looks.add_child(frame_pick)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	box = UI.vbox(4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(200, 0)
	scroll.add_child(box)

func refresh() -> void:
	var key := hash(str(codex.deeds) + str(codex.coll_earned.size()) + codex.title + str(codex.achievements.size()) + str(codex.stat("kills")) + str(main.state.in_town) + str(codex.bought.size()) + str(shop_open) + (str(main.state.gold) if shop_open else ""))
	if key == shown:
		return
	shown = key
	head.text = "Deeds  %d / %d" % [codex.achievements.size(), Codex.ACHIEVEMENTS.size()]
	title_pick.clear()
	title_pick.add_item("(none)")
	for t in codex.titles():
		title_pick.add_item(t)
		if t == codex.title:
			title_pick.select(title_pick.item_count - 1)
	_fill_looks(color_pick, Cosmetics.colors(), codex.name_color)
	_fill_looks(frame_pick, Cosmetics.frames(), codex.frame)
	OnlineUI.clear(box)
	_looks_shop()
	# Rewards waiting to be claimed come first
	if not codex.deeds.is_empty():
		box.add_child(UI.heading("Rewards waiting"))
		for id in codex.deeds.duplicate():
			for a in Codex.ACHIEVEMENTS:
				if a["id"] == id:
					box.add_child(_claim_row(a))
		box.add_child(UI.label("ALL DEEDS", UI.FONT_BODY, UI.DIM))
	# Done ones last, so what's left to do is on top
	var todo: Array = []
	var done: Array = []
	for a in Codex.ACHIEVEMENTS:
		(done if codex.achievements.has(a["id"]) else todo).append(a)
	for a in todo + done:
		box.add_child(_row(a))

func _row(a: Dictionary) -> PanelContainer:
	var have := codex.achievements.has(a["id"])
	var card := UI.panel(Color("#16201a") if have else UI.INSET, UI.GREEN.darkened(0.4) if have else UI.BORDER, 6, 8, 1)
	var h := UI.hbox(10)
	card.add_child(h)
	var mark := UI.label("✓" if have else "•", 18, UI.GREEN if have else UI.DIM)
	mark.custom_minimum_size = Vector2(18, 0)
	h.add_child(mark)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nl := UI.label(a["name"], UI.FONT_BODY, UI.GOLD if have else UI.TEXT)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nl)
	var reward := Town.reward_text(Town.deed_reward(a), main.state)
	if a.has("title"):
		reward += ", title \"%s\"" % a["title"]
	for e in Cosmetics.COLORS:
		if e["need"] == a["id"]:
			reward += ", name color \"%s\"" % e["name"]
	for e in Cosmetics.FRAMES:
		if e["need"] == a["id"]:
			reward += ", frame \"%s\"" % e["name"]
	var dl := UI.label("%s  -  Reward: %s" % [a["text"], reward], UI.FONT_BODY, UI.DIM)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.custom_minimum_size = Vector2(120, 0)
	v.add_child(dl)
	var right := UI.vbox(2)
	right.custom_minimum_size = Vector2(96, 0)
	h.add_child(right)
	if have:
		right.add_child(UI.label(str(codex.achievements[a["id"]]), UI.FONT_BODY, UI.DIM))
	else:
		var val := mini(codex.value(a["key"], main.state), int(a["target"]))
		var bar := UI.bar(UI.GOLD, 6)
		bar.max_value = int(a["target"])
		bar.value = val
		right.add_child(bar)
		right.add_child(UI.label("%d / %d" % [val, int(a["target"])], UI.FONT_BODY, UI.DIM))
	return card

func _claim_row(a: Dictionary) -> PanelContainer:
	var card := UI.panel(Color("#1d1708"), UI.GOLD, 6, 10, 2)
	var h := UI.hbox(10)
	card.add_child(h)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var cn := UI.label(a["name"], 15, UI.GOLD)
	cn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(cn)
	var rw := UI.rich(UI.FONT_BODY)
	rw.custom_minimum_size = Vector2(120, 0)
	rw.text = "%s  -  [color=#f6d88f]%s[/color]" % [a["text"], Town.reward_text(Town.deed_reward(a), main.state)]
	v.add_child(rw)
	var id: String = a["id"]
	var b := UI.primary("Claim", func():
		if Town.claim_deed(main.state, id) != "":
			main.sfx.play("buy")
		shown = 0
		main.refresh(), UI.GREEN)
	b.custom_minimum_size = Vector2(100, UI.TAP)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return card

static func _reward_text(r: Dictionary) -> String:
	var parts: Array = []
	if r.has("gold"):
		parts.append("gold")
	if r.has("potions"):
		parts.append("%d potions" % int(r["potions"]))
	if r.has("scrap"):
		parts.append("scrap")
	if r.has("dust"):
		parts.append("%d dust" % int(r["dust"]))
	return ", ".join(parts)

## Stage 4: titles, name colors and frames for gold (looks only, never power).
func _looks_shop() -> void:
	var list := Cosmetics.shop_list()
	var owned := 0
	for p in list:
		if Cosmetics.has(codex, p[1]):
			owned += 1
	var b := UI.button("%s Looks shop  -  %d / %d owned" % ["▾" if shop_open else "▸", owned, list.size()], func():
		shop_open = not shop_open
		refresh())
	b.custom_minimum_size = Vector2(0, UI.TAP)
	box.add_child(b)
	if not shop_open:
		return
	var note := UI.label("Looks only: they never change your power. Paid with this hero's gold; every hero in every town can wear them.", UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(120, 0)
	box.add_child(note)
	for p in list:
		box.add_child(_shop_row(String(p[0]), p[1]))

func _shop_row(kind: String, e: Dictionary) -> PanelContainer:
	var got := Cosmetics.has(codex, e)
	var col := Color(String(e.get("color", "#e8b14a")))
	var card := UI.panel(UI.INSET, col.darkened(0.3) if e.has("color") else UI.BORDER, 6, 8, 1)
	var h := UI.hbox(10)
	card.add_child(h)
	var sw := TextureRect.new()
	sw.texture = _swatch(col) if e.has("color") else null
	sw.custom_minimum_size = Vector2(18, 18)
	sw.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sw)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nl := UI.label(String(e["name"]), UI.FONT_BODY, col if kind == "Name color" else UI.TEXT)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nl)
	v.add_child(UI.label(kind, UI.FONT_BODY, UI.DIM))
	if got:
		h.add_child(UI.label("Owned", UI.FONT_BODY, UI.GREEN))
	else:
		var cost := Cosmetics.shop_price(main.state, e)
		var buy := UI.primary("%d gold" % cost, func():
			if Cosmetics.buy(main.state, codex, e):
				main.sfx.play("buy")
				main.toast("Bought: %s. Pick it at the top of the Guild Hall." % e["name"])
			shown = 0
			main.refresh(), UI.GOLD)
		buy.disabled = main.state.gold < cost
		buy.custom_minimum_size = Vector2(110, UI.TAP)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(buy)
	return card

## Every look in the list; the ones you haven't earned say which deed unlocks them.
func _fill_looks(pick: OptionButton, list: Array, current: String) -> void:
	pick.clear()
	for e in list:
		var got := Cosmetics.has(codex, e)
		if not got and String(e["need"]) == "store":
			continue  # supporter looks stay hidden until owned
		if not got and String(e["need"]).begins_with("coll:"):
			continue  # 2.1 G4: Codex rewards show once earned (Codex > Rewards lists what's coming)
		pick.add_item(String(e["name"]) if got else ("%s (looks shop)" % e["name"] if String(e["need"]) == "shop" else "%s (deed: %s)" % [e["name"], Cosmetics.need_name(e)]))
		var i := pick.item_count - 1
		pick.set_item_metadata(pick.item_count - 1, String(e["id"]))
		pick.set_item_disabled(i, not got)
		if String(e.get("color", "")) != "":
			pick.set_item_icon(i, _swatch(Color(String(e["color"]))))
		if String(e["id"]) == current and got:
			pick.select(i)

var _swatches := {}
func _swatch(c: Color) -> Texture2D:
	var k := c.to_html()
	if not _swatches.has(k):
		var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0))
		img.fill_rect(Rect2i(1, 1, 10, 10), c)
		_swatches[k] = ImageTexture.create_from_image(img)
	return _swatches[k]
