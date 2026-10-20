class_name SuppliesPopup
extends Overlay
## Next update (Juzo): what you carried down. Drink an elixir or read a Return
## Scroll any time in the dungeon. (Potions have their own button.)

var m

func show_for(main_node) -> void:
	m = main_node
	var st: GameState = m.state
	open(m, "Supplies", 480.0)
	var any := false
	for id in GameData.ELIXIRS:
		var n := st.supply_carried(id)
		if n <= 0:
			continue
		any = true
		var info: Dictionary = GameData.ELIXIRS[id]
		var h := UI.hbox(8)
		content.add_child(h)
		var l := UI.rich(13)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on := int(st.elixirs.get(id, 0))
		l.text = "[b]%s[/b] x%d\n[color=%s]%s%s[/color]" % [info["name"], n, UI.hex(UI.DIM), info["text"], ("  (active: %d turns left)" % on) if on > 0 else ""]
		h.add_child(l)
		var b := UI.primary("Drink", func():
			if st.drink_elixir(id):
				m.sfx.play("buff")
			close()
			m.refresh(), UI.PURPLE)
		b.disabled = st.in_town
		h.add_child(b)
	if st.return_scrolls > 0:
		any = true
		var h2 := UI.hbox(8)
		content.add_child(h2)
		var l2 := UI.rich(13)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.text = "[b]Return Scroll[/b] x%d\n[color=%s]Escape home right now with everything you carry.[/color]" % [st.return_scrolls, UI.hex(UI.DIM)]
		h2.add_child(l2)
		var rb := UI.primary("Read", func():
			close()
			if Town.use_return(st):
				m.sfx.play("click")
			m.refresh(), UI.GOLD)
		rb.disabled = st.in_town
		h2.add_child(rb)
	content.add_child(UI.wrap("Potions: %d (use the Potion button)." % st.potions, 12, UI.DIM))
	if not any:
		content.add_child(UI.wrap("You carried no elixirs or scrolls this time. Pick what to bring in town, under Into the dungeon.", 12, UI.DIM))
