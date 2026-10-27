class_name PresetsScreen
extends Overlay
## 2.1: the one Presets screen. Each preset holds your stats, skills, worn gear,
## team and rows, and the supplies you take down. Opened from the Hero, Gear and
## Party tabs and from Into the dungeon. Rules: presets.gd.

var m
var state: GameState
var body: VBoxContainer
var note: Label
var on_change := Callable()  # Into the dungeon refreshes its team and supplies

func show_for(main_node, changed := Callable()) -> void:
	m = main_node
	state = m.state
	on_change = changed
	Presets.migrate(state)
	open(m, "Presets", 560.0)
	content.add_child(UI.wrap("Save what you're running now (stats, skills, gear, team and rows, supplies) and switch back in one tap. Anything you no longer have is skipped.", UI.FONT_BODY, UI.DIM))
	note = UI.wrap("", UI.FONT_BODY, UI.GOLD)
	note.visible = false
	content.add_child(note)
	body = UI.vbox(10)
	content.add_child(body)
	_fill()

func _fill() -> void:
	OnlineUI.clear(body)
	UI.section(body, "This hero", "Stats, skills, gear, team and rows, supplies.")
	for i in Presets.SLOTS:
		var saved := Presets.is_saved(state, i)
		var c := UI.card(UI.TEAL if saved else UI.BORDER)
		body.add_child(c[0])
		var inner: VBoxContainer = c[1]
		inner.add_child(UI.label(Presets.name_of(state, i) if saved else "Empty slot %d" % (i + 1), UI.FONT_BODY, UI.TEXT if saved else UI.DIM))
		inner.add_child(UI.wrap(Presets.summary(state, i), UI.FONT_BODY, UI.DIM))
		var row := UI.hbox(8)
		inner.add_child(row)
		var idx := i
		var use := UI.primary("Use", func(): _use(idx), UI.TEAL)
		use.disabled = not saved
		var save := UI.button("Save here", func(): _save(idx))
		var ren := UI.button("Rename", func(): _rename(idx))
		ren.disabled = not saved
		var clr := UI.button("Clear", func(): _clear(idx))
		clr.disabled = not saved
		for b in [use, save, ren, clr]:
			b.custom_minimum_size = Vector2(0, UI.TAP)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
	_fill_teams()

## Team line-ups: town-wide, usable from any hero (another leader = switch heroes, in town).
func _fill_teams() -> void:
	if state.hardcore:
		return
	UI.section(body, "Team line-ups", "Shared by every hero in this town. A different leader switches you to that hero (in town). Each hero keeps their own gear and skills.")
	for i in Presets.TEAM_SLOTS:
		var saved := Presets.team_saved(m.profile, i)
		var c := UI.card(UI.GOLD if saved else UI.BORDER)
		body.add_child(c[0])
		var inner: VBoxContainer = c[1]
		var lbl := UI.label(Presets.team_label(m.profile, i) if saved else "Empty team %d" % (i + 1), UI.FONT_BODY, UI.TEXT if saved else UI.DIM)
		lbl.clip_text = true
		inner.add_child(lbl)
		var row := UI.hbox(8)
		inner.add_child(row)
		var idx := i
		var use := UI.primary("Use", func(): _use_team(idx), UI.GOLD)
		use.disabled = not saved or Presets.team_leader_gone(m.profile, i)
		if Presets.team_leader_gone(m.profile, i):
			inner.add_child(UI.wrap("Its leader is gone: save a new team here.", UI.FONT_BODY, UI.DIM))
		var save := UI.button("Save team here", func(): _save_team(idx))
		var clr := UI.button("Clear", func():
			Presets.clear_team(m.profile, idx)
			_changed())
		clr.disabled = not saved
		for b in [use, save, clr]:
			b.custom_minimum_size = Vector2(0, UI.TAP)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)

func _use_team(i: int) -> void:
	var out := Presets.apply_team(state, m.profile, i)
	var notes: Array = out["notes"]
	if int(out["switch"]) >= 0:
		if state.party != null:
			state.party.save_all()
		TitleScreen.pending = {"play": int(out["switch"]), "party": out["comps"]}
		m.sfx.play("equip")
		m.back_to_title()
		return
	note.visible = true
	if not bool(out["ok"]):
		note.text = "Couldn't use this team: " + (" ".join(notes) if not notes.is_empty() else "nothing to change.")
		_changed()
		return
	m.sfx.play("equip")
	note.text = ("Team ready: %s." % Presets.team_label(m.profile, i)) + ("" if notes.is_empty() else "\n" + "\n".join(notes))
	_changed()

func _save_team(i: int) -> void:
	if Presets.team_saved(m.profile, i):
		m.confirm("Replace this team?", "This saves your current team over it.", "Save", func():
			Presets.save_team(state, m.profile, i)
			_changed())
		return
	Presets.save_team(state, m.profile, i)
	_changed()

func _use(i: int) -> void:
	var notes := Presets.apply(state, i, m.profile.stash)
	m.sfx.play("equip")
	note.visible = true
	note.text = "Switched to %s." % Presets.name_of(state, i) + ("" if notes.is_empty() else "\n" + "\n".join(notes))
	_changed()

func _save(i: int) -> void:
	if Presets.is_saved(state, i):
		m.confirm("Replace %s?" % Presets.name_of(state, i), "This saves what you're running now over it.", "Save", func():
			Presets.save(state, i)
			_changed())
		return
	Presets.save(state, i)
	_changed()

func _clear(i: int) -> void:
	m.confirm("Clear %s?" % Presets.name_of(state, i), "This empties the slot. Your gear and skills stay as they are.", "Clear", func():
		Presets.clear(state, i)
		Presets.migrate(state)
		_changed())

func _rename(i: int) -> void:
	var o := Overlay.new().open(m, "Name this preset", 420.0)
	var edit := LineEdit.new()
	edit.text = Presets.name_of(state, i)
	edit.max_length = 20
	edit.custom_minimum_size = Vector2(0, UI.TAP)
	edit.add_theme_font_size_override("font_size", UI.FONT_BODY)
	o.content.add_child(edit)
	var ok := UI.primary("Save name", func():
		Presets.rename(state, i, edit.text)
		o.close()
		_changed(), UI.GOLD)
	ok.custom_minimum_size = Vector2(0, UI.TAP)
	o.content.add_child(ok)
	edit.grab_focus.call_deferred()

func _changed() -> void:
	if is_inside_tree():
		_fill()
	if on_change.is_valid():
		on_change.call()
	m.refresh()
