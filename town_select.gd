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
	var note := UI.wrap("Each town has its own heroes, stash and skill book. Build a team in one, or start fresh in another. Settings and the Codex are shared.", 13, UI.DIM)
	content.add_child(note)
	for t in range(1, GameData.MAX_TOWNS + 1):
		content.add_child(_card(t))

func _card(t: int) -> PanelContainer:
	var p: Profile = m.profile
	var here := p.town == t
	var founded := p.town_founded(t)
	var card := UI.panel(UI.INSET, UI.GOLD if here else UI.BORDER, 10, 10, 2 if here else 1)
	var h := UI.hbox(10)
	card.add_child(h)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.label(p.town_name(t).to_upper() if founded else "TOWN %d" % t, 15, UI.GOLD if founded else UI.DIM))
	if here:
		top.add_child(UI.chip("YOU'RE HERE", UI.GREEN, 10))
	var info := UI.wrap("", 12, UI.DIM)
	if founded:
		var heroes := GameState.town_heroes(t)
		var best := p.max_floor if here else int(p.towns.get(str(t), {}).get("max_floor", 0))
		info.text = "%d hero%s  ·  deepest floor %d" % [heroes, "" if heroes == 1 else "es", best]
	else:
		info.text = "Empty land. Found a town here and make its first hero."
	v.add_child(info)
	var b := UI.primary("Here" if here else ("Enter" if founded else "Found town"), func(): _go(t), UI.GOLD if founded else UI.GREEN)
	b.disabled = here
	b.custom_minimum_size = Vector2(120, UI.TAP)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return card

## Moves to town t. Saves the hero you're playing first (their save belongs to
## the town you're leaving), then reloads into the title screen.
func _go(t: int) -> void:
	close()
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
