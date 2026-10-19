class_name CampPopup
extends Overlay
## The Descenders' Camp (camp.gd): trade with Snik, or send your gold home.

var m
var state: GameState
var info: Label
var send: Button

func show_for(main_node) -> void:
	m = main_node
	state = m.state
	open(m, "Descenders' Camp", 560.0, Color("#fbbf24"))
	var t := UI.label("Tents around a fire, a few tired descenders, and a courier who knows the way up. You've rested here: full health, abilities ready.", 13, UI.DIM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(t)
	info = UI.label("", 14, UI.GOLD)
	content.add_child(info)
	var trade := UI.primary("Trade with Snik", func():
		close()
		MerchantPopup.new().show_for(m), UI.GREEN)
	trade.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(trade)
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
	info.text = "Gold you carry: %d    In the Bank: %d" % [state.gold, state.bank]
	send.text = ("Send %d gold home (the courier keeps %d%%)" % [Camp.courier_amount(state), int(Camp.COURIER_CUT * 100)]) if state.gold > 0 else "Nothing to send home"
	send.disabled = state.gold <= 0
