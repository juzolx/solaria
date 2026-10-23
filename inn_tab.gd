class_name InnTab
extends ScrollContainer
## Town > Inn: rest to full health (cheap; free while you're new), buy potions,
## and hear what the regulars are saying.

const RUMORS := [
	"\"Finish a contract down there and the Board mails your pay. Check your Mailbox.\"",
	"\"WANTED posters pay in steel. A boss's weapon is worth the walk back up.\"",
	"\"Every deed you finish earns a reward from the Guild. It comes by mail.\"",
	"\"The Blacksmith turns dust and scrap into whole sets. Ask about bigger bags too.\"",
	"\"Feeling lucky? The Tavern's wheel will bet on any of your spare gear.\"",
	"\"Nothing down below can reach you in town. Rest up before a boss.\"",
	"\"Keep your Vault stocked: every one of your heroes can open it.\"",
]

var main
var box: VBoxContainer
var hp_bar: ProgressBar
var hp_label: Label
var rest_button: Button
var potion_button: Button
var potion_label: Label
var rumor: Label
var recruit_label: Label
var recruit_button: Button

func setup(m) -> void:
	main = m
	name = "Inn"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)
	box.add_child(UI.heading("The Inn"))
	var card := UI.panel(UI.INSET, UI.BORDER, 8, 12, 1)
	box.add_child(card)
	var v := UI.vbox(8)
	card.add_child(v)
	hp_label = UI.label("", 14, UI.TEXT)
	v.add_child(hp_label)
	hp_bar = UI.bar(UI.GREEN, 10)
	v.add_child(hp_bar)
	rest_button = UI.primary("", _rest, UI.GREEN)
	rest_button.custom_minimum_size = Vector2(0, UI.TAP + 4)
	v.add_child(rest_button)
	var note := UI.label("A night's rest heals you and your companions fully and clears every status.", 12, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	var pc := UI.panel(UI.INSET, UI.BORDER, 8, 12, 1)
	box.add_child(pc)
	var ph := UI.hbox(10)
	pc.add_child(ph)
	potion_label = UI.label("", 14, UI.TEXT)
	potion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	potion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(potion_label)
	potion_button = UI.button("", func():
		main.state.buy_potion()
		main.sfx.play("buy")
		main.refresh())
	potion_button.custom_minimum_size = Vector2(150, UI.TAP)
	ph.add_child(potion_button)
	# Juzo: new heroes join your town here (not from a menu), when a slot is open
	var rc := UI.panel(UI.INSET, UI.BORDER, 8, 12, 1)
	box.add_child(rc)
	var rv := UI.vbox(8)
	rc.add_child(rv)
	recruit_label = UI.wrap("", 13, UI.TEXT)
	rv.add_child(recruit_label)
	recruit_button = UI.primary("Recruit a new hero", _recruit, UI.GOLD)
	recruit_button.custom_minimum_size = Vector2(0, UI.TAP)
	rv.add_child(recruit_button)
	box.add_child(UI.label("OVERHEARD AT THE BAR", 11, UI.DIM))
	rumor = UI.label("", 13, Color("#d6c7a1"))
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(rumor)
	rumor.text = RUMORS.pick_random()

func _rest() -> void:
	if Town.rest(main.state):
		main.sfx.play("heal")
		rumor.text = RUMORS.pick_random()
	main.refresh()

func refresh() -> void:
	var g: GameState = main.state
	var mx := g.get_max_hp()
	hp_bar.max_value = mx
	hp_bar.value = g.hero_hp
	hp_label.text = "Health  %d / %d" % [g.hero_hp, mx]
	var cost := Town.rest_cost(g)
	var full := g.hero_hp >= mx
	rest_button.text = "You're fully rested" if full else ("Rest for the night  (free)" if cost == 0 else "Rest for the night  (%d gold)" % cost)
	rest_button.disabled = full or g.gold < cost
	potion_label.text = "Potions: %d" % g.potions
	_recruit_refresh()
	potion_button.text = "Buy one  (%d gold)" % g.potion_cost()
	potion_button.disabled = g.gold < g.potion_cost()

## A new hero joins the town in the next open slot, and you play them right away.
## The hero you were playing stays in town (and can join your team).
func _recruit() -> void:
	var p: Profile = main.profile
	var n := p.free_slot()
	if n == 0:
		return
	var hc := p.town_hardcore(p.town)
	main.confirm("Recruit a new hero?", "A new %s hero joins %s, and you play them now. %s stays in town." % ["Hardcore" if hc else "Regular", p.town_name(p.town), main.state.hero_name if main.state.hero_name != "" else "Your hero"], "Recruit", func():
		TitleScreen.pending = {"new": n, "hc": hc}
		main.back_to_title())

func _recruit_refresh() -> void:
	var p: Profile = main.profile
	var note := p.recruit_note()
	recruit_label.text = "Heroes of %s: %d of %d slots used (a town holds up to %d).%s" % [p.town_name(p.town), GameState.town_heroes(p.town), p.slots_open(), GameData.MAX_HEROES, ("\n" + note) if note != "" else ""]
	recruit_button.disabled = note != ""
