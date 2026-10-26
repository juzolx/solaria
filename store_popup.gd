class_name StorePopup
extends Overlay
## Stage 4: the real-money store (Menu > Supporter store). Only reachable when
## Store.ENABLED is true; the supporter looks, plus Restore purchases.

var main
var status: Label
var rows: VBoxContainer

func show_for(m) -> void:
	main = m
	open(m, "Supporter store", 560.0)
	Store.request_prices()
	var note := UI.label("Everything here is extra room or looks. Nothing sold here makes a hero stronger, and there are no random items.", UI.FONT_BODY, UI.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	rows = UI.vbox(6)
	content.add_child(rows)
	var restore := UI.button("Restore purchases", func():
		Store.restore()
		_update())
	restore.custom_minimum_size = Vector2(0, UI.TAP)
	content.add_child(restore)
	status = UI.label("", UI.FONT_BODY, UI.GOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)
	_update()

func _process(_d: float) -> void:
	if main == null:
		return
	var before := Store.last_message + str(Store.busy) + str(main.profile.owned_products.size()) + str(Store.prices.size())
	Store.poll(main.profile, main.codex)
	if before != Store.last_message + str(Store.busy) + str(main.profile.owned_products.size()) + str(Store.prices.size()):
		_update()
		main.refresh()

func _update() -> void:
	OnlineUI.clear(rows)
	for id in Store.PRODUCTS:
		var p: Dictionary = Store.PRODUCTS[id]
		var card := UI.panel(UI.INSET, UI.BORDER, 6, 8, 1)
		var h := UI.hbox(10)
		card.add_child(h)
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(String(p["name"]), UI.FONT_BODY, UI.TEXT))
		var t := UI.label(String(p["text"]), UI.FONT_BODY, UI.DIM)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(120, 0)
		v.add_child(t)
		if Store.owns(main.profile, id):
			h.add_child(UI.label("Owned", UI.FONT_BODY, UI.GREEN))
		else:
			var pid: String = id
			var b := UI.primary(String(Store.prices.get(id, "Buy")), func():
				Store.buy(pid)
				_update(), UI.GOLD)
			b.disabled = Store.busy
			b.custom_minimum_size = Vector2(110, UI.TAP)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
		rows.add_child(card)
	status.text = Store.last_message
