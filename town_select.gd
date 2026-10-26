class_name TownSelect
extends Overlay
## Next update (Juzo): your towns. A save is a town holding a roster of heroes,
## its own stash, skill book and hero slots. Up to GameData.MAX_TOWNS for now.
## Settings and the Codex are shared by every town.

var m
var title_screen

func show_for(main_node, from_title = null) -> void:
	m = main_node
	title_screen = from_title
	open(m, "Your towns", 720.0)
	var note := UI.wrap("Each town has its own heroes, stash and skill book. Build a team in one, or start fresh in another. Settings and the Codex are shared.", UI.FONT_BODY, UI.DIM)
	content.add_child(note)
	for t in range(1, GameData.MAX_TOWNS + 1):
		content.add_child(_card(t))

func _card(t: int) -> PanelContainer:
	var p: Profile = m.profile
	var here := p.town == t
	var founded := p.town_founded(t)
	var card := UI.panel(UI.INSET, UI.GOLD if here else UI.BORDER, 10, 10, 2 if here else 1)
	var outer := UI.vbox(8)
	card.add_child(outer)
	var h := UI.hbox(10)
	outer.add_child(h)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.label(p.town_name(t) if founded else "Town %d" % t, UI.FONT_BODY, UI.GOLD if founded else UI.DIM))
	if founded:
		var hc := p.town_hardcore(t)
		top.add_child(UI.chip("Hardcore" if hc else "Regular", UI.RED if hc else UI.GREEN, UI.FONT_BODY))
	if here and founded:
		top.add_child(UI.chip("YOU'RE HERE", UI.GOLD, UI.FONT_BODY))
	var info := UI.wrap("", UI.FONT_BODY, UI.DIM)
	if founded:
		var heroes := GameState.town_heroes(t)
		var best := p.max_floor if here else int(p.towns.get(str(t), {}).get("max_floor", 0))
		info.text = "%d hero%s  ·  deepest floor %d" % [heroes, "" if heroes == 1 else "es", best]
	else:
		info.text = "Empty land. Found a town here: name it, choose Regular or Hardcore, and make its first hero."
	v.add_child(info)
	var b := UI.primary("Here" if here and founded else ("Enter" if founded else "Found town"), func(): _go(t))   # one gold main action; the words say whether it founds or enters
	b.disabled = here and founded
	b.custom_minimum_size = Vector2(120, UI.TAP)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	if founded:  # Juzo: you can name your town
		var row := UI.hbox(6)
		outer.add_child(row)
		var le := LineEdit.new()
		le.placeholder_text = "Rename %s" % p.town_name(t)
		le.max_length = Profile.TOWN_NAME_MAX
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.custom_minimum_size = Vector2(0, UI.TAP)
		row.add_child(le)
		row.add_child(UI.button("Rename", func():
			p.rename_town(t, le.text)
			close()
			TownSelect.new().show_for(m, title_screen)))
	return card

## Moves to town t (or founds it). Saves the hero you're playing first (their save
## belongs to the town you're leaving), then reloads into the title screen.
func _go(t: int) -> void:
	close()
	if not m.profile.town_founded(t):
		FoundTown.new().show_for(m, t)
		return
	if m.started:
		m.save_everything()
		m.started = false
		m.timer.stop()
		m.profile.switch_town(t)
		m.get_tree().reload_current_scene()
		return
	m.profile.switch_town(t)
	if title_screen and is_instance_valid(title_screen):
		title_screen.queue_free()
	m.show_title()
