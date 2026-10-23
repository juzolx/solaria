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
	Presets.migrate(state, m.profile)
	open(m, "Presets", 560.0)
	content.add_child(UI.wrap("Save what you're running now (stats, skills, gear, team and rows, supplies) and switch back in one tap. Anything you no longer have is skipped.", 13, UI.DIM))
	note = UI.wrap("", 13, UI.GOLD)
	note.visible = false
	content.add_child(note)
	body = UI.vbox(10)
	content.add_child(body)
	_fill()

func _fill() -> void:
	OnlineUI.clear(body)
	for i in Presets.SLOTS:
		var saved := Presets.is_saved(state, i)
		var c := UI.card(UI.TEAL if saved else UI.BORDER)
		body.add_child(c[0])
		var inner: VBoxContainer = c[1]
		inner.add_child(UI.label(Presets.name_of(state, i) if saved else "Empty slot %d" % (i + 1), 17, UI.TEXT if saved else UI.DIM))
		inner.add_child(UI.wrap(Presets.summary(state, i), 13, UI.DIM))
		var row := UI.hbox(8)
		inner.add_child(row)
		var idx := i
		var use := UI.primary("Use", func(): _use(idx), UI.TEAL)
		use.disabled = not saved
		var save := UI.button("Save here", func(): _save(idx))
		var ren := UI.button("Rename", func(): _rename(idx))
		ren.disabled = not saved
		for b in [use, save, ren]:
			b.custom_minimum_size = Vector2(0, UI.TAP)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)

func _use(i: int) -> void:
	var notes := Presets.apply(state, i)
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

func _rename(i: int) -> void:
	var o := Overlay.new().open(m, "Name this preset", 420.0)
	var edit := LineEdit.new()
	edit.text = Presets.name_of(state, i)
	edit.max_length = 20
	edit.custom_minimum_size = Vector2(0, UI.TAP)
	edit.add_theme_font_size_override("font_size", 18)
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
