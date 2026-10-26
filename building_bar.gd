class_name BuildingBar
extends PanelContainer
## 2.1 G1: the strip at the top of every building's page: its level in this town,
## what it does now, what the next level gives and what it costs.

var main
var title: Label
var now: Label
var next: Label
var build: Button
var id := ""
var shown := ""

func setup(m) -> void:
	main = m
	name = "BuildingBar"
	add_theme_stylebox_override("panel", UI.style(UI.INSET, UI.BORDER, 8, 8, 1))
	# Fable r1 #10: the Build button carries its cost (or why not) and spans the strip
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)
	title = UI.label("", UI.FONT_BODY, UI.GOLD)
	v.add_child(title)
	now = UI.wrap("", UI.FONT_BODY, UI.TEXT)
	v.add_child(now)
	next = UI.wrap("", UI.FONT_BODY, UI.DIM)
	v.add_child(next)
	build = UI.primary("Build", _build, UI.GOLD)
	build.custom_minimum_size = Vector2(0, UI.TAP)
	build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build.add_theme_color_override("font_disabled_color", Color(UI.RED).lightened(0.3))
	v.add_child(build)

## "Build · 1800g + 60 scrap", or the reason it can't be bought that isn't the price.
func _label(g: GameState) -> String:
	var c := Buildings.next_cost(id)
	if Buildings.level(id) + 1 >= 3 and Buildings.deepest(g, main.profile) < Economy.BUILDING_L3_FLOOR:
		return "Needs floor %d" % Economy.BUILDING_L3_FLOOR
	var parts: Array = ["%sg" % UI.short(int(c.get("gold", 0)))]
	for k in ["scrap", "dust"]:
		if int(c.get(k, 0)) > 0:
			parts.append("%d %s" % [int(c[k]), k])
	return "Build · " + " + ".join(parts)

func _build() -> void:
	if Buildings.upgrade(main.state, main.profile, id):
		main.sfx.play("buy")
	shown = ""
	main.refresh()

## page: the Town page on show.
func refresh(page: int) -> void:
	var g: GameState = main.state
	id = Buildings.id_for_page(page)
	visible = id != ""
	if id == "":
		return
	var lvl := Buildings.level(id)
	var key := "%s|%d|%d|%d|%d|%d" % [id, lvl, g.gold, g.scrap, g.dust, Buildings.deepest(g, main.profile)]
	if key == shown:
		return
	shown = key
	var why := Buildings.blocked(g, main.profile, id)
	build.text = "Build"
	if lvl == 0:  # an empty lot (Church, Trophy Cabin): build it first
		title.text = "%s · not built yet" % Buildings.name_of(id)
		now.text = "An empty lot with a sign: \"Coming soon: a %s.\"" % Buildings.name_of(id)
		next.text = "Built: %s" % Buildings.benefit(id, 1)
		build.visible = true
		build.disabled = why != ""
		build.text = _label(g)
		build.tooltip_text = why if why != "" else "Build the %s" % Buildings.name_of(id)
		return
	title.text = "%s · Level %d / %d" % [Buildings.name_of(id), lvl, Economy.BUILDING_MAX]
	now.text = "Now: " + Buildings.benefit(id, lvl)
	if lvl >= Economy.BUILDING_MAX:
		next.text = "Fully built."
		build.visible = false
		return
	build.visible = true
	next.text = "Lv %d: %s" % [lvl + 1, Buildings.benefit(id, lvl + 1)]
	build.disabled = why != ""
	build.tooltip_text = why if why != "" else "Build level %d" % (lvl + 1)
	build.text = _label(g)
