class_name CharacterCreator
extends Overlay
## Pick your race and look before your first fight. The race changes your
## starting stats; everything else is just how you look.
## Interface pass (phone sweep): the hero big on a plinth at the top, then the choices; every
## control at least 44 pt on a 430 pt phone (52 design px); the long lists (37 hair styles,
## 10 faces) are one stepper row each; Done stays on screen under the scrolling choices.

var app := {}
var preview: TextureRect
var race_text: RichTextLabel
var on_done: Callable
var lock_race := false
var preview_looks := {}  # gear shown on the preview (your current gear when changing your look)
var rows := {}  # field -> Array of [button, value(, colour)], to highlight the picked one
var row_parts := {}  # field -> [label, row], to hide a whole row (Beastkin have fur, not skin or hair)
var steppers := {}  # field -> {"name": Label, "count": Label}
var name_edit: LineEdit  # only when making a new hero
var done_button: Button
const NAMES := ["Aldric", "Brenna", "Corvin", "Dagny", "Eira", "Fenn", "Garrick", "Hilde", "Isolde", "Jory", "Kael", "Liora",
	"Maren", "Nyx", "Orrin", "Perrin", "Quill", "Rowan", "Saga", "Talia", "Ulric", "Vesna", "Wren", "Yara", "Zeph"]

## done gets the look; when ask_name is true it also has "name" in it.
func show_for(parent: Node, start: Dictionary, done: Callable, title := "Create your hero", race_locked := false, looks := {}, ask_name := false) -> void:
	app = start.duplicate()
	preview_looks = looks
	on_done = done
	lock_race = race_locked
	open(parent, title, 860.0, UI.GOLD, false)
	# Phones stack: the hero on top, the choices under them. Wide screens: side by side.
	var body := BoxContainer.new()
	body.vertical = is_narrow()
	body.add_theme_constant_override("separation", 14)
	content.add_child(body)

	# The stage: your hero at 3x (whole pixels) on the plinth, the name and the dice beside them
	var left := UI.vbox(10)
	left.custom_minimum_size = Vector2(0 if body.vertical else 380, 0)
	body.add_child(left)
	var stage := UI.hbox(10)
	left.add_child(stage)
	var side := Sprites.PORTRAIT * 3
	var ph := Control.new()
	ph.custom_minimum_size = Vector2(side, side + 8)
	stage.add_child(ph)
	var pl := TextureRect.new()
	pl.texture = UiIcons.plinth(64)
	pl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pl.position = Vector2(roundf((side - pl.texture.get_width()) / 2.0), side + 8 - pl.texture.get_height())
	ph.add_child(pl)
	preview = TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(side, side)
	preview.size = preview.custom_minimum_size
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ph.add_child(preview)
	var sv := UI.vbox(8)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(sv)
	if ask_name:
		sv.add_child(_head("Name"))
		name_edit = LineEdit.new()
		name_edit.max_length = 16
		name_edit.text = NAMES.pick_random()
		name_edit.placeholder_text = "Your hero's name"
		name_edit.custom_minimum_size = Vector2(0, UI.TAP)
		sv.add_child(name_edit)
		var nb := UI.button("New name", func(): name_edit.text = NAMES.pick_random())
		nb.custom_minimum_size = Vector2(0, UI.TAP)
		sv.add_child(nb)
	var rnd := UI.button("Random look", _randomize)
	rnd.custom_minimum_size = Vector2(0, UI.TAP)
	sv.add_child(rnd)
	var race_card := PanelContainer.new()
	race_card.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, UiSkin.IRON, 10))
	race_text = UI.rich(UI.FONT_BODY)
	race_card.add_child(race_text)

	# The choices
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	if not lock_race:
		_text_row(right, "Race", "race", GameData.RACES, [], 3)
	right.add_child(race_card)  # what the race does, right under the pick
	_text_row(right, "Body", "body", Sprites.BODIES, Sprites.BODY_NAMES, 2)
	_swatch_row(right, "Skin", "skin", Sprites.swatches("skin"))
	_stepper_row(right, "Hair style", "hair")
	_swatch_row(right, "Hair color", "hair_color", Sprites.swatches("hair"))
	_swatch_row(right, "Fur color", "fur", Races.FUR.map(func(f): return Color(f[1][1])))
	_swatch_row(right, "Eyes", "eyes", Sprites.swatches("eyes"))
	if HeroArt.available():
		_stepper_row(right, "Face", "face")
	var pad := Control.new()   # the last row clears the scroll's edge instead of sitting half under it
	pad.custom_minimum_size = Vector2(0, 24)
	right.add_child(pad)

	# Done sits under the scroll, always on screen
	done_button = UI.primary("Done", _finish)
	done_button.custom_minimum_size = Vector2(0, UI.TAP)
	if lock_race:
		# "Change your look" (an existing hero): a way out that keeps the old look
		var keep := start.duplicate()
		var cancel := UI.button("Cancel", func():   # hands back the look you had (the caller restarts the fight)
			close()
			on_done.call(keep))
		cancel.custom_minimum_size = Vector2(120, UI.TAP)
		foot.add_child(cancel)
		done_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		done_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(done_button)   # under the scroll: always on screen
	foot.visible = true
	_update()

static func _head(t: String) -> Control:
	return UI.heading(t)

func _text_row(parent: Control, label_text: String, field: String, values: Array, names: Array = [], columns := 3) -> void:
	var lbl := _head(label_text)
	parent.add_child(lbl)
	var grid := GridContainer.new()
	grid.columns = columns
	row_parts[field] = [lbl, grid]
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(grid)
	var list := []
	for i in values.size():
		var v = values[i]
		var b := UI.button(str(names[i]) if i < names.size() else str(v), _pick.bind(field, v))
		b.custom_minimum_size = Vector2(0, UI.TAP)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		grid.add_child(b)
		list.append([b, v])
	rows[field] = list

func _swatch_row(parent: Control, label_text: String, field: String, colors: Array) -> void:
	var lbl := _head(label_text)
	parent.add_child(lbl)
	var flow := HFlowContainer.new()
	row_parts[field] = [lbl, flow]
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	parent.add_child(flow)
	var list := []
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(UI.TAP, UI.TAP)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_pick.bind(field, i))
		flow.add_child(b)
		list.append([b, i, Color(colors[i])])
	rows[field] = list

## One row for a long list: big arrows either side, the name and where you are in the list
## in the middle. The preview shows each one as you step.
func _stepper_row(parent: Control, label_text: String, field: String) -> void:
	var lbl := _head(label_text)
	parent.add_child(lbl)
	var row := UI.hbox(6)
	row_parts[field] = [lbl, row]
	parent.add_child(row)
	var prev := UI.button("◀", _step.bind(field, -1))
	prev.custom_minimum_size = Vector2(UI.TAP + 12, UI.TAP)
	row.add_child(prev)
	var mid := PanelContainer.new()
	mid.add_theme_stylebox_override("panel", UiSkin.bevel(UiSkin.SLATE, UI.GOLD_DULL, 4))
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size = Vector2(0, UI.TAP)
	row.add_child(mid)
	var mv := UI.vbox(0)
	mv.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(mv)
	var nm := UI.label("", UI.FONT_BODY, UI.GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	mv.add_child(nm)
	var cnt := UI.label("", UI.FONT_BODY, UI.DIM)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(cnt)
	var nxt := UI.button("▶", _step.bind(field, 1))
	nxt.custom_minimum_size = Vector2(UI.TAP + 12, UI.TAP)
	row.add_child(nxt)
	steppers[field] = {"name": nm, "count": cnt}

## The values a stepper walks through for the current race, and the names it shows.
func _step_values(field: String) -> Array:
	if field == "face":
		return [HeroArt.FACES, HeroArt.FACE_NAMES]
	var l := _hair_list(String(app.get("race", "Human")))
	return [l, l]

func _step(field: String, d: int) -> void:
	var vals: Array = _step_values(field)[0]
	var i := vals.find(app.get(field, vals[0]))
	_pick(field, vals[posmod(i + d, vals.size())])

func _pick(field: String, value) -> void:
	app[field] = value
	if field == "race":
		var ok := Races.skins(String(value))
		if not int(app.get("skin", 1)) in ok:
			app["skin"] = ok[0]
		if String(value) == "Beastkin" and not app.has("fur"):
			app["fur"] = 5
		var styles := _hair_list(String(value))
		if not str(app.get("hair", "")) in styles:
			app["hair"] = styles[0]
	if UI.sfx:
		UI.sfx.play("click")
	_update()

func _randomize() -> void:
	app["body"] = Sprites.BODIES.pick_random()
	app["skin"] = Races.skins(app.get("race", "Human")).pick_random()
	app["hair"] = _hair_list(app.get("race", "Human")).pick_random()
	if HeroArt.available():
		app["face"] = HeroArt.FACES.pick_random()
	app["hair_color"] = randi() % Sprites.hair_colors().size()
	app["eyes"] = randi() % Sprites.eye_colors().size()
	app["fur"] = randi() % Races.FUR.size()
	_update()

func _update() -> void:
	preview.texture = Sprites.portrait(app, preview_looks)
	var race: String = app.get("race", "Human")
	var info: Dictionary = GameData.RACE_INFO.get(race, GameData.RACE_INFO["Human"])
	race_text.text = "[color=%s][b]%s[/b][/color]\n%s\n%s" % [UI.hex(UI.GOLD), race, info["text"], race_preview(race)]
	if lock_race:
		race_text.text += "\n[color=%s](Your race was picked when this hero was made.)[/color]" % UI.hex(UI.DIM)
	# Beastkin: fur color instead of skin, hair and hair color
	# 2.1 heroes: every race uses the drawn human body for now (skin tones per race), its 37 hair
	# styles and the drawn faces; fur, crests and eye colours come back with each race's own art
	var furry := race == "Beastkin" and not HeroArt.available()
	for field in row_parts:
		var show: bool = (field == "fur") == furry if field in ["skin", "hair", "hair_color", "fur"] else true
		if field == "eyes" and HeroArt.available():
			show = false
		# races with their own body build (goblin, dwarf...) have a drawn face: no face choice; the hair
		# style only where the bake fitted the styles to that build's head (heroes.json "hair")
		if field in ["hair", "face"] and HeroArt.available() and HeroArt.build_dir(app) != "":
			show = field == "hair" and bool(HeroArt.info()["builds"].get(HeroArt.art_race(app), {}).get("hair", false))
		# a build that keeps its drawn skin (goblin and orc green, the werewolf's grey) has nothing to pick
		if field == "skin" and HeroArt.available() and HeroArt.build_dir(app) != "":
			var bd: Dictionary = HeroArt.info()["builds"].get(HeroArt.art_race(app), {})
			if not bool(bd.get("skin", true)) or bd.has("skin_ramp"):
				show = false
		for c in row_parts[field]:
			(c as Control).visible = show
	for field in rows:
		for entry in rows[field]:
			var b: Button = entry[0]
			if field == "skin":
				b.visible = int(entry[1]) in Races.skins(race)
			var picked: bool = app.get(field) == entry[1]
			if entry.size() > 2:  # color swatch: ink outline, a gold frame round the picked one
				var c: Color = entry[2]
				var sw := _swatch_style(c, picked)
				b.add_theme_stylebox_override("normal", sw)
				b.add_theme_stylebox_override("hover", _swatch_style(c.lightened(0.12), picked))
				b.add_theme_stylebox_override("pressed", sw)
			else:  # the design system: slate blocks, the picked one edged in gold
				b.add_theme_color_override("font_color", UI.GOLD if picked else UI.TEXT)
				if picked:
					b.add_theme_stylebox_override("normal", UiSkin.bevel(UiSkin.SLATE, UI.GOLD, 6))
				else:
					b.remove_theme_stylebox_override("normal")
	for field in steppers:
		var sv: Array = _step_values(field)
		var vals: Array = sv[0]
		var i := vals.find(app.get(field, vals[0]))   # no face saved yet: the first (Calm), as the art draws it
		steppers[field]["name"].text = str(sv[1][i]) if i >= 0 else str(app.get(field, ""))
		steppers[field]["count"].text = "%d of %d" % [i + 1, vals.size()] if i >= 0 else ""

## A colour square: ink outline, or a gold frame round the picked one.
static func _swatch_style(c: Color, picked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.border_color = UI.GOLD if picked else UiSkin.SOOT
	sb.set_border_width_all(4 if picked else 2)
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	return sb

## What a race grows into, and who likes it (for the race picker).
static func race_preview(race: String) -> String:
	var info := Races.info(race)
	var p: Dictionary = info["power"]
	var names: Array = []
	for r in info["ranks"]:
		names.append(r["name"])
	var friends: Array = []
	var foes: Array = Races.RIVALS.get(race, [])
	for id in Realms.IDS:
		if Realms.info(id)["race"] == race:
			friends.append(Realms.realm_name(id))
	var t := "[color=%s]%s[/color]: %s\n[color=%s]Awakens:[/color] %s" % [p["color"], p["name"], p["how"], UI.hex(UI.DIM), " › ".join(names)]
	if not friends.is_empty():
		t += "\n[color=%s]Home:[/color] %s (friendly)" % [UI.hex(UI.DIM), ", ".join(friends)]
	if not foes.is_empty():
		t += "\n[color=%s]Rivals:[/color] %s (they start hostile)" % [UI.hex(UI.DIM), ", ".join(foes)]
	return t   # body size: these four lines decide the race pick (Fable r4 #7)

func _finish() -> void:
	if name_edit:
		var n := name_edit.text.strip_edges()
		app["name"] = n if n != "" else NAMES.pick_random()
	close()
	on_done.call(app)

## The hair styles a race can pick (2.1 heroes: the 37 drawn styles for everyone).
static func _hair_list(race: String) -> Array:
	return Sprites.HAIR_STYLES.duplicate() if HeroArt.available() else Races.hair_styles(race)
