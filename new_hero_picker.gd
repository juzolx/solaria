class_name NewHeroPicker
extends Overlay
## Making a new hero: Regular or Hardcore first, then race and look.

func show_for(m, slot_n: int) -> void:
	var profile: Profile = m.profile
	open(m, "New hero (slot %d)" % slot_n, 780.0)
	content.add_child(UI.label("Pick how this hero plays. You can't change it later.", 13, UI.DIM))
	var row := UI.hbox(14)
	content.add_child(row)
	row.add_child(_card(m, slot_n, false, "REGULAR", UI.GREEN,
		"The normal game. Fall and you lose what you carried in (gold on you, your bag and worn gear) and wake at the last checkpoint. The Bank and Vault are always safe.\n\nRegular heroes share a stash for trading gear."))
	var hc_text := "One life. If your hero dies, it's gone for good, gear and all. Rare monsters show up more often, and how deep you got goes on the leaderboard."
	if profile.hc_best > 0:
		hc_text += "\n\nYour deepest Hardcore run: [color=#e8b14a]floor %d[/color]" % profile.hc_best
	row.add_child(_card(m, slot_n, true, "HARDCORE", UI.RED, hc_text))
	if not profile.hc_runs.is_empty():
		content.add_child(UI.heading("Fallen Hardcore heroes"))
		var list := UI.rich(12)
		var lines := []
		for i in mini(4, profile.hc_runs.size()):
			var r: Dictionary = profile.hc_runs[i]
			lines.append("Floor %d  -  Lv %d %s %s  [color=%s](%s)[/color]" % [int(r["best"]), int(r["level"]), r["race"], r["title"], UI.hex(UI.DIM), r["date"]])
		list.text = "\n".join(lines)
		content.add_child(list)

func _card(m, slot_n: int, hc: bool, title: String, color: Color, text: String) -> PanelContainer:
	var card := UI.panel(UI.INSET, color, 10, 16, 2)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(10)
	card.add_child(v)
	v.add_child(UI.label(title, 22, color.lightened(0.2)))
	var t := UI.rich(14)
	t.custom_minimum_size = Vector2(260, 0)
	t.text = text
	v.add_child(t)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	var b := UI.primary("Make a %s hero" % title.capitalize(), func(): _go(m, slot_n, hc), color)
	b.custom_minimum_size = Vector2(0, 42)
	v.add_child(b)
	return card

func _go(m, slot_n: int, hc: bool) -> void:
	close()
	if m.started:
		TitleScreen.pending = {"new": slot_n, "hc": hc}
		m.back_to_title()
		return
	for c in m.get_children():
		if c is TitleScreen:
			c.queue_free()
	m.new_hero(slot_n, hc)
