class_name FoundTown
extends Overlay
## Founding a town (Juzo, Oct 20): name it, and choose Regular or Hardcore. The
## whole town plays that way: every hero you raise there follows its rules.
## Then you make the town's first hero.

var m
var t := 1
var name_edit: LineEdit

func show_for(main_node, town_n: int) -> void:
	m = main_node
	t = town_n
	var p: Profile = m.profile
	open(m, "Found a town", 760.0)
	content.add_child(UI.wrap("Name your town, then choose how it plays. You can't change Regular or Hardcore later.", UI.FONT_CAPTION, UI.DIM))
	name_edit = LineEdit.new()
	name_edit.placeholder_text = p.town_name(t)
	name_edit.max_length = Profile.TOWN_NAME_MAX
	name_edit.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(name_edit)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 12)
	content.add_child(row)
	row.add_child(_card(false, "REGULAR", UI.GREEN,
		"The normal game. Fall and you lose what you carried in (gold on you, your bag, worn gear, scrolls and all but 2 potions) and wake at the last checkpoint. The Bank and the town's Vault are always safe."))
	var hc_text := "One life for every hero here. A hero who dies is gone for good, gear and all. Rare monsters show up more often, and how deep you got goes on the leaderboard."
	if p.hc_best > 0:
		hc_text += "\n\nYour deepest Hardcore run: [color=#e8b14a]floor %d[/color]" % p.hc_best
	row.add_child(_card(true, "HARDCORE", UI.RED, hc_text))

func _card(hc: bool, title: String, color: Color, text: String) -> PanelContainer:
	var card := UI.panel(UI.INSET, color, 10, 14, 2)
	card.custom_minimum_size = Vector2(minf(330.0, get_viewport().get_visible_rect().size.x - 72.0), 0)
	var v := UI.vbox(10)
	card.add_child(v)
	v.add_child(UI.label(title, 20, color.lightened(0.2)))
	var r := UI.rich(UI.FONT_CAPTION)
	r.text = text
	v.add_child(r)
	var b := UI.primary("Found a %s town" % title.capitalize(), func(): _go(hc), color)
	b.custom_minimum_size = Vector2(0, UI.TAP)
	v.add_child(b)
	return card

func _go(hc: bool) -> void:
	close()
	if m.started:
		m.save_everything()  # the hero you're playing belongs to the town you're leaving
		m.started = false
		m.timer.stop()
	m.profile.found_town(t, name_edit.text, hc)
	TitleScreen.pending = {"new": 1, "hc": hc}
	m.get_tree().reload_current_scene()
