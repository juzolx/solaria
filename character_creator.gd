class_name CharacterCreator
extends Overlay
## Pick your race and look before your first fight. The race changes your
## starting stats; everything else is just how you look.

var app := {}
var preview: TextureRect
var race_text: RichTextLabel
var on_done: Callable
var lock_race := false
var preview_looks := {}  # gear shown on the preview (your current gear when changing your look)
var rows := {}  # field -> Array of buttons, to highlight the picked one
var name_edit: LineEdit  # only when making a new hero
const NAMES := ["Aldric", "Brenna", "Corvin", "Dagny", "Eira", "Fenn", "Garrick", "Hilde", "Isolde", "Jory", "Kael", "Liora",
	"Maren", "Nyx", "Orrin", "Perrin", "Quill", "Rowan", "Saga", "Talia", "Ulric", "Vesna", "Wren", "Yara", "Zeph"]

## done gets the look; when ask_name is true it also has "name" in it.
func show_for(parent: Node, start: Dictionary, done: Callable, title := "Create your hero", race_locked := false, looks := {}, ask_name := false) -> void:
	app = start.duplicate()
	preview_looks = looks
	on_done = done
	lock_race = race_locked
	open(parent, title, 860.0, UI.GOLD, false)
	var body := UI.hbox(18)
	content.add_child(body)

	# Left: the hero, big
	var left := UI.panel(UI.INSET, UI.BORDER, 10, 10, 1)
	left.custom_minimum_size = Vector2(250, 0)
	body.add_child(left)
	var lv := UI.vbox(8)
	left.add_child(lv)
	preview = TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(Sprites.PORTRAIT * 3, Sprites.PORTRAIT * 3)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lv.add_child(preview)
	race_text = UI.rich(13)
	lv.add_child(race_text)
	var rnd := UI.button("Randomize look", _randomize)
	lv.add_child(rnd)

	# Right: the choices
	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	if ask_name:
		right.add_child(UI.label("NAME", 11, UI.DIM))
		var nrow := UI.hbox(6)
		right.add_child(nrow)
		name_edit = LineEdit.new()
		name_edit.max_length = 16
		name_edit.text = NAMES.pick_random()
		name_edit.placeholder_text = "Your hero's name"
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nrow.add_child(name_edit)
		nrow.add_child(UI.button("Random", func(): name_edit.text = NAMES.pick_random()))
	if not lock_race:
		_text_row(right, "Race", "race", GameData.RACES)
	_text_row(right, "Build", "body", Sprites.BODIES, Sprites.BODY_NAMES)
	_swatch_row(right, "Skin", "skin", Sprites.swatches("skin"))
	# Every race's choices in one row; _update shows only the current race's (Dragonkin get crests, Golems stone styles)
	var all_hair: Array = Sprites.HAIR_STYLES.duplicate()
	for x in Lpc.CREST_ORDER + Lpc.GOLEM_HAIR:
		if not x in all_hair:
			all_hair.append(x)
	_text_row(right, "Hair and horns", "hair", all_hair)
	_swatch_row(right, "Hair color", "hair_color", Sprites.swatches("hair"))
	_swatch_row(right, "Eyes", "eyes", Sprites.swatches("eyes"))

	var done_button := UI.primary("Done", _finish, UI.GOLD)
	done_button.custom_minimum_size = Vector2(0, 44)
	content.add_child(done_button)
	_update()

func _text_row(parent: Control, label_text: String, field: String, values: Array, names: Array = []) -> void:
	parent.add_child(UI.label(label_text.to_upper(), 11, UI.DIM))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	var list := []
	for i in values.size():
		var v = values[i]
		var b := UI.button(str(names[i]) if i < names.size() else str(v), _pick.bind(field, v))
		b.custom_minimum_size = Vector2(76, 32)
		flow.add_child(b)
		list.append([b, v])
	rows[field] = list

func _swatch_row(parent: Control, label_text: String, field: String, colors: Array) -> void:
	parent.add_child(UI.label(label_text.to_upper(), 11, UI.DIM))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	var list := []
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(32, 32)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_pick.bind(field, i))
		flow.add_child(b)
		list.append([b, i, Color(colors[i])])
	rows[field] = list

func _pick(field: String, value) -> void:
	app[field] = value
	if field == "race":
		var ok := Races.skins(String(value))
		if not int(app.get("skin", 1)) in ok:
			app["skin"] = ok[0]
		var styles := Lpc.hair_styles(String(value))
		if not str(app.get("hair", "")) in styles:
			app["hair"] = styles[0]
	if UI.sfx:
		UI.sfx.play("click")
	_update()

func _randomize() -> void:
	app["body"] = Sprites.BODIES.pick_random()
	app["skin"] = Races.skins(app.get("race", "Human")).pick_random()
	app["hair"] = Lpc.hair_styles(app.get("race", "Human")).pick_random()
	app["hair_color"] = randi() % Sprites.hair_colors().size()
	app["eyes"] = randi() % Sprites.eye_colors().size()
	_update()

func _update() -> void:
	preview.texture = Sprites.portrait(app, preview_looks)
	var race: String = app.get("race", "Human")
	var info: Dictionary = GameData.RACE_INFO.get(race, GameData.RACE_INFO["Human"])
	race_text.text = "[color=#e8b14a][b]%s[/b][/color]\n%s\n%s" % [race, info["text"], race_preview(race)]
	if lock_race:
		race_text.text += "\n[color=%s](Your race was picked when this hero was made.)[/color]" % UI.hex(UI.DIM)
	for field in rows:
		for entry in rows[field]:
			var b: Button = entry[0]
			if field == "skin":
				b.visible = int(entry[1]) in Races.skins(race)
			elif field == "hair":
				b.visible = entry[1] in Lpc.hair_styles(race)
			var picked: bool = app.get(field) == entry[1]
			if entry.size() > 2:  # color swatch
				var c: Color = entry[2]
				var border := UI.GOLD if picked else UI.BORDER
				b.add_theme_stylebox_override("normal", UI.style(c, border, 6, 0, 3 if picked else 1))
				b.add_theme_stylebox_override("hover", UI.style(c.lightened(0.15), UI.HILITE, 6, 0, 3 if picked else 1))
				b.add_theme_stylebox_override("pressed", UI.style(c, UI.GOLD, 6, 0, 3))
			else:
				b.add_theme_color_override("font_color", UI.GOLD if picked else UI.TEXT)
				b.add_theme_stylebox_override("normal", UI.style(Color("#2a2010") if picked else UI.INSET, UI.GOLD if picked else UI.BORDER, 6, 4, 2 if picked else 1))

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
	var t := "[color=%s]%s[/color]: %s\n[color=%s]Awakens:[/color] %s" % [p["color"], p["name"], p["how"], UI.hex(UI.DIM), " > ".join(names)]
	if not friends.is_empty():
		t += "\n[color=%s]Home:[/color] %s (friendly)" % [UI.hex(UI.DIM), ", ".join(friends)]
	if not foes.is_empty():
		t += "\n[color=%s]Rivals:[/color] %s (they start hostile)" % [UI.hex(UI.DIM), ", ".join(foes)]
	return "[font_size=11]%s[/font_size]" % t

func _finish() -> void:
	if name_edit:
		var n := name_edit.text.strip_edges()
		app["name"] = n if n != "" else NAMES.pick_random()
	close()
	on_done.call(app)
