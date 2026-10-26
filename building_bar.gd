class_name BuildingBar
extends PanelContainer
## 2.1 G1: the strip at the top of every building's page. Fable r3 #4: one short row,
## "Shop · Lv 1 / 3" and a plain "Upgrade ›" button; what the level does now, what the next
## one gives, its cost and the real Build (or why not) are in the popup that button opens,
## so no page opens on a disabled red button.

var main
var title: Label
var build: Button   # "Upgrade ›" / "Build ›": opens the details (never disabled)
var id := ""
var shown := ""

func setup(m) -> void:
	main = m
	name = "BuildingBar"
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(8)
	add_child(h)
	title = UI.label("", UI.FONT_BODY, UI.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(title)
	build = UI.button("Upgrade ›", _details)
	build.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(build)

## "Build · 1,800 gold + 60 scrap", or the reason it can't be bought that isn't the price.
func _label(g: GameState) -> String:
	var c := Buildings.next_cost(id)
	if Buildings.level(id) + 1 >= 3 and Buildings.deepest(g, main.profile) < Economy.BUILDING_L3_FLOOR:
		return "Needs floor %d" % Economy.BUILDING_L3_FLOOR
	var extra: Array = []
	for k in ["scrap", "dust"]:
		if int(c.get(k, 0)) > 0:
			extra.append("%d %s" % [int(c[k]), k])
	return UI.cost("Build", int(c.get("gold", 0)), " + ".join(extra))

## The popup: now, next, and the real Build button (disabled with its reason here, not on the page).
func _details() -> void:
	var g: GameState = main.state
	var lvl := Buildings.level(id)
	var o := Overlay.new().open(main, Buildings.name_of(id), 480.0)
	if lvl == 0:
		o.content.add_child(UI.wrap("An empty lot with a sign: \"Coming soon: a %s.\"" % Buildings.name_of(id), UI.FONT_BODY, UI.DIM))
		o.content.add_child(UI.wrap("Built: %s" % Buildings.benefit(id, 1), UI.FONT_BODY, UI.TEXT))
	else:
		o.content.add_child(UI.heading("Level %d now" % lvl))
		o.content.add_child(UI.wrap(Buildings.benefit(id, lvl), UI.FONT_BODY, UI.TEXT))
		o.content.add_child(UI.heading("Level %d" % (lvl + 1)))
		o.content.add_child(UI.wrap(Buildings.benefit(id, lvl + 1), UI.FONT_BODY, UI.TEXT))
	var why := Buildings.blocked(g, main.profile, id)
	var b := UI.primary(_label(g), func():
		if Buildings.upgrade(main.state, main.profile, id):
			main.sfx.play("buy")
		shown = ""
		o.close()
		main.refresh(), UI.GOLD)
	b.custom_minimum_size = Vector2(0, UI.TAP)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = why != ""
	o.foot.visible = true
	o.foot.add_child(b)
	if why != "":
		o.content.add_child(UI.wrap(why, UI.FONT_BODY, UI.RED))

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
	var ready := Buildings.blocked(g, main.profile, id) == ""
	if lvl == 0:  # an empty lot (Church, Trophy Cabin): build it first
		title.text = "%s · not built" % Buildings.name_of(id)
		build.text = "Build ›"
	else:
		title.text = "%s · Lv %d / %d" % [Buildings.name_of(id), lvl, Economy.BUILDING_MAX]
		build.text = "Upgrade ›"
	build.visible = lvl < Economy.BUILDING_MAX
	build.add_theme_color_override("font_color", UI.GOLD if ready else UI.TEXT)   # gold = you can afford it now
	build.tooltip_text = Buildings.benefit(id, lvl + 1) if lvl < Economy.BUILDING_MAX else ""
