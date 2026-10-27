class_name BountyTab
extends ScrollContainer
## Town › Bounty Board: monster contracts for the zone you're in. Each posting
## shows its reward up front (gold, gear, or a weapon for your class). Take up to
## Town.MAX_TAKEN and hunt in the dungeon; the reward is mailed the moment you finish.

var main
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	name = "Bounties"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var g: GameState = main.state
	Town.refresh_board(g)
	var key := str(g.contracts) + str(g.gold / 50) + str(g.in_town)
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var head := UI.hbox(8)
	box.add_child(head)
	var title := UI.heading("Contracts in %s" % String(GameData.zone_for_floor(maxi(1, g.floor_num))["name"]))   # Fable r5 #13: the bar names the board
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var reroll := UI.button(UI.cost("Repost", Town.reroll_cost(g)), func():
		if Town.reroll(g):
			main.sfx.play("buy")
		shown = ""
		main.refresh())
	UI.why(reroll, UI.need_gold(g.gold, Town.reroll_cost(g)))
	if not UI.blocked(reroll):
		reroll.tooltip_text = "Replace the postings you haven't taken. They also change every day."
	head.add_child(reroll)
	var taken: Array = []
	var posted: Array = []
	for c in g.contracts:
		(taken if c.get("taken", false) else posted).append(c)
	box.add_child(UI.heading("Your contracts", "%d of %d taken." % [taken.size(), Town.max_taken()]))   # Fable r1 #5: one heading style
	if taken.is_empty():
		box.add_child(UI.wrap("No contracts yet. Take one from the board below.", UI.FONT_BODY, UI.DIM))
	for c in taken:
		box.add_child(_card(c, true))
	box.add_child(UI.heading("Posted"))
	for c in posted:
		box.add_child(_card(c, false))
	var streak := int(main.codex.login.get("streak", 0))
	var note := UI.label("Hunts pay gold or gear. Elite contracts want Rare or stronger monsters. WANTED posters name a boss and pay with a weapon for your class. Rewards arrive in your Mailbox the moment a contract is done. Login streak: %d day%s." % [streak, "" if streak == 1 else "s"], UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)

func _card(c: Dictionary, taken: bool) -> PanelContainer:
	var g: GameState = main.state
	var kind := String(c["kind"])
	var accent: Color = {"hunt": UI.GOLD, "elite": Color("#c084fc"), "wanted": UI.RED}.get(kind, UI.GOLD)
	var done: bool = c.get("done", false)
	var card := UI.panel(UI.INSET, UI.GREEN if done else (accent.darkened(0.3) if taken else UI.BORDER), 6, 10, 2 if done else 1)
	var h := UI.hbox(10)
	card.add_child(h)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var tag: String = {"hunt": "HUNT", "elite": "ELITE", "wanted": "WANTED"}.get(kind, "")
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.chip(tag, accent, UI.FONT_BODY))
	var name_l := UI.label(String(c["text"]).trim_prefix("WANTED: "), UI.FONT_BODY, UI.TEXT)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_l)
	var rw := UI.rich(UI.FONT_BODY)
	rw.text = "[color=%s]Reward:[/color] [color=#f6d88f]%s[/color]" % [UI.hex(UI.DIM), Town.reward_text(c["reward"], g)]
	v.add_child(rw)
	if taken:
		var bar := UI.bar(UI.GREEN if done else accent, 6)
		bar.max_value = int(c["need"])
		bar.value = mini(int(c["have"]), int(c["need"]))
		v.add_child(bar)
		v.add_child(UI.label("%d / %d" % [mini(int(c["have"]), int(c["need"])), int(c["need"])], UI.FONT_BODY, UI.DIM))
	var right := UI.vbox(4)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	var id := int(c["id"])
	if done:
		var b := UI.primary("Turn in", func():
			if Town.claim(g, id) != "":
				main.sfx.play("buy")
			shown = ""
			main.refresh(), UI.GREEN)
		b.custom_minimum_size = Vector2(110, UI.TAP)
		right.add_child(b)
	elif taken:
		var drop := UI.button("Drop", func():
			main.confirm("Drop this contract?", "Its progress is lost.", "Drop", func():
				Town.drop(g, id)
				shown = ""
				main.refresh()))
		drop.custom_minimum_size = Vector2(90, UI.TAP)
		right.add_child(drop)
	else:
		var take := UI.primary("Take", func():
			if Town.take(g, id):
				main.sfx.play("click")
			shown = ""
			main.refresh(), accent)
		take.custom_minimum_size = Vector2(100, UI.TAP)
		UI.why(take, "You have %d contracts already. Finish one first." % Town.max_taken() if Town.taken_count(g) >= Town.max_taken() else "")
		right.add_child(take)
	return card
