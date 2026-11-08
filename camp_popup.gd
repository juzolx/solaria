class_name CampPopup
extends Overlay
## The Descenders' Camp (camp.gd): buy potions from the quartermaster, or send your gold home.

var m
var state: GameState
var info: Label
var send: Button
var qm: Button   # the quartermaster's potions

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Descenders' Camp", 560.0, Color("#fbbf24"))
	var t := UI.label("Tents around a fire, a few tired descenders, a quartermaster and a courier who knows the way up. You've rested here: full health, abilities ready.", UI.FONT_BODY, UI.DIM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(t)
	info = UI.wrap("", UI.FONT_BODY, UI.GOLD)
	content.add_child(info)
	qm = UI.primary("", func():
		if Camp.buy_potions(state):
			m.sfx.play("buy")
		_update()
		m.refresh(), UI.GREEN)
	qm.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(qm)
	send = UI.primary("", func():
		if Camp.send_home(state) > 0:
			m.sfx.play("buy")
		_update()
		m.refresh(), UI.GOLD)
	send.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(send)
	_update()
	m.timer.paused = true
	tree_exiting.connect(func(): m.timer.paused = false)

func _update() -> void:
	info.text = "Gold you carry: %s    In the bank: %s" % [UI.commas(state.gold), UI.commas(state.bank)]   # QA r1 B1, B11
	# 375 pt phone: the courier's cut is its own line, so the button fits (it was 497 px)
	if state.gold > 0:
		info.text += "\nThe courier keeps %d%% of what he carries up." % int(Camp.COURIER_CUT * 100)
	send.text = ("Send %s gold home" % UI.commas(Camp.courier_amount(state))) if state.gold > 0 else "Nothing to send home"
	send.disabled = state.gold <= 0
	qm.text = "Quartermaster: %d potions for %s gold" % [Camp.POTION_PACK, UI.commas(Camp.potion_price(state))]
	qm.disabled = state.gold < Camp.potion_price(state)
