class_name BountyTab
extends ScrollContainer
## Codex > Bounties: 3 small goals a day and 2 bigger ones a week.

var main
var codex: Codex
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Bounties"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	codex.refresh_bounties(main.state)
	var key := str(codex.bounties) + str(Time.get_unix_time_from_system() / 60)
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var now := Time.get_unix_time_from_system()
	var day_left := 86400 - int(now) % 86400
	var streak := int(codex.login.get("streak", 0))
	box.add_child(UI.label("Login streak: %d day%s" % [streak, "" if streak == 1 else "s"], 13, UI.GOLD))
	box.add_child(UI.heading("Daily  -  new ones in %dh %dm" % [day_left / 3600, (day_left % 3600) / 60]))
	var daily: Array = codex.bounties.get("daily", [])
	for i in daily.size():
		box.add_child(_row(daily[i], false, i))
	var days := floori(now / 86400.0)
	var monday := days - ((days + 3) % 7)
	var week_left := int((monday + 7) * 86400 - now)
	box.add_child(UI.heading("Weekly  -  new ones in %dd %dh" % [week_left / 86400, (week_left % 86400) / 3600]))
	var weekly: Array = codex.bounties.get("weekly", [])
	for i in weekly.size():
		box.add_child(_row(weekly[i], true, i))
	var note := UI.label("Daily: gold and 2 materials. Weekly: lots of gold, 6 materials and a Mystery Box.", 11, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)

func _row(b: Dictionary, weekly: bool, i: int) -> PanelContainer:
	var done: bool = b["done"]
	var claimed: bool = b["claimed"]
	var card := UI.panel(UI.INSET, UI.GOLD if done and not claimed else UI.BORDER, 6, 8, 2 if done and not claimed else 1)
	var h := UI.hbox(10)
	card.add_child(h)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(str(b["text"]), 14, UI.DIM if claimed else UI.TEXT))
	var bar := UI.bar(UI.GREEN if done else UI.GOLD, 6)
	bar.max_value = int(b["need"])
	bar.value = mini(int(b["have"]), int(b["need"]))
	v.add_child(bar)
	v.add_child(UI.label("%d / %d" % [mini(int(b["have"]), int(b["need"])), int(b["need"])], 11, UI.DIM))
	var btn := UI.primary("Claimed" if claimed else ("Claim" if done else "In progress"), func():
		var got: String = main.state.claim_bounty(weekly, i)
		if got != "":
			main.sfx.play("buy")
		shown = ""
		main.refresh(), UI.GREEN)
	btn.disabled = claimed or not done
	btn.custom_minimum_size = Vector2(110, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return card
