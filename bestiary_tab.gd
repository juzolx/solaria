class_name BestiaryTab
extends HBoxContainer
## Codex > Bestiary: every creature, zone by zone. Ones you haven't met are
## "???". Once you've met one you see its lore, your kills, the gear it likes
## to drop and the real drop odds. Its Signature item stays a secret until
## you find it.

var main
var codex: Codex
var list: ItemList
var keys: Array[String] = []
var detail: VBoxContainer
var pic: TextureRect
var text: RichTextLabel
var selected := ""
var shown := ""

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Bestiary"
	add_theme_constant_override("separation", 10)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(200, 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", 12)
	list.item_selected.connect(func(i: int):
		if i >= 0 and i < keys.size() and keys[i] != "":
			selected = keys[i]
			_show())
	add_child(list)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	detail = UI.vbox(8)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(detail)
	var top := UI.hbox(10)
	detail.add_child(top)
	pic = TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(96, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(pic)
	text = UI.rich(13)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(text)

func refresh() -> void:
	var key := "%d|%d" % [codex.stat("kills"), codex.bestiary.size()]
	if key == shown:
		return
	shown = key
	list.clear()
	keys.clear()
	for zi in GameData.ZONES.size():
		var z: Dictionary = GameData.ZONES[zi]
		var h := list.add_item(str(z["name"]).to_upper())
		list.set_item_selectable(h, false)
		list.set_item_custom_fg_color(h, Color(z["color"]).lightened(0.4))
		keys.append("")
		var names: Array = []
		for e in z["enemies"]:
			names.append(e["name"])
		for s in z["subs"]:
			names.append(s["monster"]["name"])
		names.append(z["mid"]["name"])
		names.append(z["boss"]["name"])
		for n in names:
			var met := codex.seen(n)
			var boss: bool = Monsters.info(n).get("boss", false)
			var label := ("  %s%s  (%d)" % ["[Boss] " if boss else "", n, codex.kills(n)]) if met else "  ???"
			if met and bool(codex.bestiary[n].get("sig", false)):
				label += "  *"
			var i := list.add_item(label)
			list.set_item_custom_fg_color(i, UI.TEXT if met else UI.DIM)
			if boss and met:
				list.set_item_custom_fg_color(i, Color("#fca5a5"))
			keys.append(n)
			if n == selected:
				list.select(i)
	if selected == "":
		for k in keys:
			if k != "" and codex.seen(k):
				selected = k
				break
	_show()

func _show() -> void:
	if selected == "" or not codex.seen(selected):
		pic.texture = null
		text.text = "[color=%s]Meet a monster to learn about it. Monsters you haven't met show as ???.\n\nKill milestones (10, 100, 500 and 1,000 kills) give you lasting bonus damage and gold against that monster.[/color]" % UI.hex(UI.DIM)
		return
	var info := Monsters.info(selected)
	var boss: bool = info.get("boss", false)
	var home := GameData.monster_home(selected)
	var art := Sprites.enemy_by_key(_art_key(selected, home))
	pic.texture = art.get("tex", null)
	var e := codex.entry(selected)
	var kills := int(e["kills"])
	var dim := UI.hex(UI.DIM)
	var lines: Array = []
	lines.append("[font_size=18][color=#e8b14a]%s[/color][/font_size]" % selected)
	if not home.is_empty():
		var z: Dictionary = GameData.ZONES[int(home["zone"])]
		var first := int(home["zone"]) * GameData.ZONE_FLOORS + 1
		if home.has("boss"):
			var bf := first + (GameData.MID_BOSS_FLOOR if home["boss"] == "mid" else GameData.ZONE_FLOORS) - 1
			lines.append("[color=%s]%s of %s, floor %d[/color]" % [dim, "Mid boss" if home["boss"] == "mid" else "Zone boss", z["name"], bf])
		elif int(home["sub"]) >= 0:
			var sf := first + int(home["sub"]) * GameData.SUB_FLOORS
			lines.append("[color=%s]Lives in %s, %s (floors %d-%d)[/color]" % [dim, z["name"], z["subs"][int(home["sub"])]["name"], sf, sf + 9])
		else:
			lines.append("[color=%s]Found all over %s (floors %d-%d)[/color]" % [dim, z["name"], first, first + 49])
	lines.append("[i]%s[/i]" % info.get("lore", ""))
	lines.append("")
	lines.append("[b]Defeated: %d[/b]" % kills)
	if not boss:
		var tiers: Array = e["tiers"]
		var parts: Array = []
		for t in range(1, 6):
			if int(tiers[t]) > 0:
				parts.append("[color=%s]%s %d[/color]" % [Monsters.tier_color(t), Monsters.tier_name(t), int(tiers[t])])
		if not parts.is_empty():
			lines.append("Rare kills: " + ", ".join(parts))
		var bonus := Monsters.milestone_bonus(kills)
		var nxt := Monsters.next_milestone(kills)
		lines.append("Hunter bonus: [color=#4ade80]+%d%% damage and gold[/color] against it" % bonus + ("  [color=%s](next at %d kills)[/color]" % [dim, nxt] if nxt > 0 else "  [color=#fbbf24](maxed!)[/color]"))
		lines.append("")
		var drops: Array = info.get("drops", [])
		lines.append("[b]Drops[/b]: 1 item per kill, usually %s (%d%% of the time)" % [" or ".join(drops), int(GameData.FAVORED_SLOT_CHANCE * 100)])
		lines.append(_odds_line("Common", GameData.rarity_odds(0, GameData.LEGENDARY_CHANCE_NORMAL)))
		var rare: Dictionary = Monsters.TIERS[Monsters.RARE]
		lines.append(_odds_line("Rare tier", GameData.rarity_odds(int(rare["loot"]), GameData.LEGENDARY_CHANCE_NORMAL)) + " [color=%s]+1 extra drop[/color]" % dim)
		var myth: Dictionary = Monsters.TIERS[Monsters.MYTHIC]
		lines.append(_odds_line("Mythic tier", GameData.rarity_odds(int(myth["loot"]), GameData.LEGENDARY_CHANCE_BOSS)) + " [color=%s]+3 extra drops[/color]" % dim)
		lines.append("")
		if Monsters.has_signature(selected):
			var sig := Monsters.signature_def(selected)
			if bool(e.get("sig", false)):
				lines.append("[color=#ff6b9d][b]Signature: %s[/b][/color]  (found!)" % sig["name"])
				lines.append("%s %s: %s" % [sig["slot"], str(sig["type"]).capitalize(), GameData.effect_text(sig["effect"], int(sig["value"]))])
				lines.append("[color=%s][i]%s[/i][/color]" % [dim, sig.get("flavor", "")])
			else:
				lines.append("[color=#ff6b9d][b]Signature: ???[/b][/color]  [color=%s]A %s, 1 in %s kills. No pity: every kill is a fresh chance.[/color]" % [dim, str(sig["slot"]).to_lower(), _num(Monsters.SIGNATURE_CHANCE)])
	else:
		lines.append("")
		lines.append("[b]Drops[/b]: %d items, %d-%d materials, and sometimes a Unique (your chance right now: %d%%)" % [
			GameData.BOSS_LOOT_DROPS, GameData.BOSS_MATERIAL_DROP[0], GameData.BOSS_MATERIAL_DROP[1], int(main.state.unique_chance())])
		lines.append(_odds_line("Each item", GameData.rarity_odds(GameData.BOSS_RARITY_BONUS, GameData.LEGENDARY_CHANCE_BOSS)))
		var def: Dictionary = GameData.boss_for_floor(_boss_floor(home))
		for u in def.get("uniques", []):
			var have: bool = codex.collection.has(u["name"])
			lines.append(("[color=#fbbf24]%s[/color] - %s" % [u["name"], GameData.effect_text(u["effect"], int(u["value"]))]) if have else "[color=#fbbf24]???[/color] [color=%s](a Unique %s)[/color]" % [dim, str(u["slot"]).to_lower()])
	text.text = "\n".join(lines)

func _art_key(n: String, home: Dictionary) -> String:
	if home.has("boss"):
		var z: Dictionary = GameData.ZONES[int(home["zone"])]
		return z["mid"]["art"] if home["boss"] == "mid" else z["boss"]["art"]
	return GameData.art_key(n)

func _boss_floor(home: Dictionary) -> int:
	return int(home["zone"]) * GameData.ZONE_FLOORS + (GameData.MID_BOSS_FLOOR if home["boss"] == "mid" else GameData.ZONE_FLOORS)

func _odds_line(label: String, odds: Array) -> String:
	var parts: Array = []
	for r in odds.size():
		var v: float = odds[r]
		parts.append("[color=%s]%s%%[/color]" % [GameData.color_of(r), ("%.1f" % v) if v < 10.0 else str(int(round(v)))])
	return "  %s: %s" % [label, " / ".join(parts)]

func _num(n: int) -> String:
	var s := str(n)
	return s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3) if s.length() > 3 else s
