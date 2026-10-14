class_name AchievementsTab
extends VBoxContainer
## Town > Guild Hall: your deeds (achievements). Each one's reward (gold and a
## piece of gear by how hard it was) is claimed here. Some give a title you can
## show next to your hero's name.

var main
var codex: Codex
var head: Label
var title_pick: OptionButton
var box: VBoxContainer
var shown := 0

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
	top.add_child(UI.label("Title:", 12, UI.DIM))
	title_pick = OptionButton.new()
	title_pick.item_selected.connect(func(i: int):
		codex.title = "" if i == 0 else title_pick.get_item_text(i)
		codex.save()
		main.refresh())
	top.add_child(title_pick)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	box = UI.vbox(4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(200, 0)
	scroll.add_child(box)

func refresh() -> void:
	var key := hash(str(codex.deeds) + str(codex.achievements.size()) + str(codex.stat("kills")) + str(main.state.in_town))
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
	OnlineUI.clear(box)
	# Rewards waiting to be claimed come first
	if not codex.deeds.is_empty():
		box.add_child(UI.label("REWARDS WAITING FOR YOU", 11, UI.GOLD))
		for id in codex.deeds.duplicate():
			for a in Codex.ACHIEVEMENTS:
				if a["id"] == id:
					box.add_child(_claim_row(a))
		box.add_child(UI.label("ALL DEEDS", 11, UI.DIM))
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
	var nl := UI.label(a["name"], 14, UI.GOLD if have else UI.TEXT)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nl)
	var reward := Town.reward_text(Town.deed_reward(a), main.state)
	if a.has("title"):
		reward += ", title \"%s\"" % a["title"]
	var dl := UI.label("%s  -  Reward: %s" % [a["text"], reward], 11, UI.DIM)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.custom_minimum_size = Vector2(120, 0)
	v.add_child(dl)
	var right := UI.vbox(2)
	right.custom_minimum_size = Vector2(96, 0)
	h.add_child(right)
	if have:
		right.add_child(UI.label(str(codex.achievements[a["id"]]), 11, UI.DIM))
	else:
		var val := mini(codex.value(a["key"], main.state), int(a["target"]))
		var bar := UI.bar(UI.GOLD, 6)
		bar.max_value = int(a["target"])
		bar.value = val
		right.add_child(bar)
		right.add_child(UI.label("%d / %d" % [val, int(a["target"])], 11, UI.DIM))
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
	var rw := UI.rich(12)
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
	if r.has("mats"):
		parts.append("%d materials" % int(r["mats"]))
	return ", ".join(parts)
