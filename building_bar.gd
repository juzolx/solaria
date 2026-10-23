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
	var h := UI.hbox(10)
	add_child(h)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	title = UI.label("", 13, UI.GOLD)
	v.add_child(title)
	now = UI.wrap("", 11, UI.TEXT)
	v.add_child(now)
	next = UI.wrap("", 11, UI.DIM)
	v.add_child(next)
	build = UI.primary("Build", _build, UI.GOLD)
	build.custom_minimum_size = Vector2(96, UI.TAP)
	build.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(build)

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
	title.text = "%s  ·  Level %d / %d" % [Buildings.name_of(id).to_upper(), lvl, Economy.BUILDING_MAX]
	now.text = "Now: " + Buildings.benefit(id, lvl)
	if lvl >= Economy.BUILDING_MAX:
		next.text = "Fully built."
		build.visible = false
		return
	build.visible = true
	var why := Buildings.blocked(g, main.profile, id)
	next.text = "Level %d: %s\nCost: %s" % [lvl + 1, Buildings.benefit(id, lvl + 1), Buildings.cost_text(Buildings.next_cost(id))]
	if lvl + 1 >= 3:
		next.text += "  (needs floor %d)" % Economy.BUILDING_L3_FLOOR
	build.disabled = why != ""
	build.tooltip_text = why if why != "" else "Build level %d" % (lvl + 1)
	build.text = "Build"
