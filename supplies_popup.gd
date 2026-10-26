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
		var l := UI.rich(UI.FONT_BODY)
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
		var l2 := UI.rich(UI.FONT_BODY)
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
	if st.supply_carried("luck") > 0:
		any = true
		var h3 := UI.hbox(8)
		content.add_child(h3)
		var l3 := UI.rich(UI.FONT_BODY)
		l3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l3.text = "[b]Scroll of Luck[/b] x%d\n[color=%s]Better loot for %d turns.%s[/color]" % [st.supply_carried("luck"), UI.hex(UI.DIM), GameData.LUCK_TURNS,
			("  (active: %d turns left)" % st.luck_turns) if st.luck_turns > 0 else ""]
		h3.add_child(l3)
		var lb := UI.primary("Read", func():
			if st.read_luck_scroll():
				m.sfx.play("buff")
			close()
			m.refresh(), UI.PURPLE)
		lb.disabled = st.in_town
		h3.add_child(lb)
	content.add_child(UI.wrap("Potions: %d (use the Potion button)." % st.potions, UI.FONT_BODY, UI.DIM))
	if not any:
		content.add_child(UI.wrap("You carried no elixirs or scrolls this time. Pick what to bring in town, under Into the dungeon.", UI.FONT_BODY, UI.DIM))
