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
var plate: PanelContainer
var backdrop: TextureRect
static var _grounds := {}
var text: RichTextLabel
var strip: VBoxContainer  # 2.1 G4: this region's Bestiary progress and its next reward
var strip_key := ""
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
	list.add_theme_font_size_override("font_size", UI.MIN_FONT)
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
	strip = UI.vbox(4)
	detail.add_child(strip)
	var top := UI.hbox(10)
	detail.add_child(top)
	# 0.13+: an illustrated plate: the monster lit in its home region's colors on a glowing ground
	plate = PanelContainer.new()
	top.add_child(plate)
	backdrop = TextureRect.new()
	backdrop.custom_minimum_size = Vector2(168, 168)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate.add_child(backdrop)
	pic = TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.offset_left = 10
	pic.offset_top = 6
	pic.offset_right = -10
	pic.offset_bottom = -10
	backdrop.add_child(pic)
	list.fixed_icon_size = Vector2i(22, 22)
	text = UI.rich(UI.FONT_CAPTION)
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
		var ids: Array = []  # monster ids (names are only shown)
		for e in z["enemies"]:
			ids.append(e["id"])
		for s in z["subs"]:
			ids.append(s["monster"]["id"])
		ids.append(z["mid"]["id"])
		ids.append(z["boss"]["id"])
		for n in ids:
			var met := codex.seen(n)
			var boss: bool = Monsters.info(n).get("boss", false)
			var label := ("  %s%s  (%d)" % ["[Boss] " if boss else "", Monsters.name_of(n), codex.kills(n)]) if met else "  ???"
			if met and bool(codex.bestiary[n].get("sig", false)):
				label += "  *"
			var i := list.add_item(label)
			var ia := Sprites.enemy_by_key(_art_key(n, GameData.monster_home(n)))
			if ia.has("tex"):
				list.set_item_icon(i, ia["tex"] if met else ia["white"])
				if not met:
					list.set_item_icon_modulate(i, Color(0.5, 0.48, 0.6))  # a shape until you meet it (UX pass: brighter, so the outline reads on a phone)
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
	_strip()
	if selected == "" or not codex.seen(selected):
		pic.texture = null
		text.text = "[color=%s]Meet a monster to learn about it. Monsters you haven't met show as ???.\n\nKill milestones (10, 100, 500 and 1,000 kills) give you lasting bonus damage and gold against that monster.[/color]" % UI.hex(UI.DIM)
		return
	var info := Monsters.info(selected)
	var boss: bool = info.get("boss", false)
	var home := GameData.monster_home(selected)
	var art := Sprites.enemy_by_key(_art_key(selected, home))
	var zi := clampi(int(home.get("zone", 0)), 0, 9)
	pic.texture = SpriteLight.lit(art.get("tex", null), zi) if art.has("tex") else null
	backdrop.texture = _ground(zi)
	var zc := Color(GameData.ZONES[mini(zi, GameData.ZONES.size() - 1)]["color"])
	plate.add_theme_stylebox_override("panel", UI.style(Color(0.02, 0.02, 0.04), zc.lightened(0.2), 6, 3, 2))
	var e := codex.entry(selected)
	var kills := int(e["kills"])
	var dim := UI.hex(UI.DIM)
	var lines: Array = []
	lines.append("[font_size=18][color=#e8b14a]%s[/color][/font_size]" % Monsters.name_of(selected))
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
		lines.append("Hunter bonus: [color=#4ade80]+%d%% damage and gold, %d%% less damage taken[/color] against it" % [bonus, bonus / 2] + ("  [color=%s](next at %d kills)[/color]" % [dim, nxt] if nxt > 0 else "  [color=#fbbf24](mastered!)[/color]"))
		var prof: Dictionary = {"weak": [], "resist": []}
		var zn := ""
		for z in GameData.ZONES:
			for en in z["enemies"]:
				if en["id"] == selected:
					zn = String(z["id"])
					prof["shape"] = en["shape"]
			for sb in z["subs"]:
				if sb["monster"]["id"] == selected:
					zn = String(z["id"])
					prof["shape"] = sb["monster"]["shape"]
		var ze: Dictionary = Combat.ZONE_ELEMENTS.get(zn, {})
		var se: Dictionary = Combat.SHAPE_ELEMENTS.get(String(prof.get("shape", "")), {})
		var weak: Array = (ze.get("weak", []) as Array) + (se.get("weak", []) as Array).filter(func(x): return not x in ze.get("resist", []))
		var res: Array = (ze.get("resist", []) as Array) + (se.get("resist", []) as Array).filter(func(x): return not x in ze.get("weak", []))
		if kills >= 10 or main.state.dev_mode:
			lines.append("Weak to: [color=#4ade80]%s[/color]   Resists: [color=#94a3b8]%s[/color]" % [", ".join(weak.slice(0, 2)) if not weak.is_empty() else "nothing", ", ".join(res) if not res.is_empty() else "nothing"])
		else:
			lines.append("[color=%s]Kill 10 to learn its weaknesses.[/color]" % dim)
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
				lines.append("[color=#ff6b9d][b]Signature: ???[/b][/color]  [color=%s]%s, 1 in %s kills. No pity: every kill is a fresh chance.[/color]" % [dim, a_slot(str(sig["slot"])), _num(Monsters.SIGNATURE_CHANCE)])
	else:
		lines.append("")
		lines.append("[b]Drops[/b]: %d items, %d-%d dust, and sometimes a Unique (your chance right now: %d%%)" % [
			GameData.BOSS_LOOT_DROPS, Economy.BOSS_DUST[0], Economy.BOSS_DUST[1], int(main.state.unique_chance())])
		lines.append(_odds_line("Each item", GameData.rarity_odds(GameData.BOSS_RARITY_BONUS, GameData.LEGENDARY_CHANCE_BOSS)))
		var def: Dictionary = GameData.boss_for_floor(_boss_floor(home))
		for u in def.get("uniques", []):
			var have: bool = codex.collection.has(u["id"])
			lines.append(("[color=#fbbf24]%s[/color] - %s" % [u["name"], GameData.effect_text(u["effect"], int(u["value"]))]) if have else "[color=#fbbf24]???[/color] [color=%s](a Unique %s)[/color]" % [dim, str(u["slot"]).to_lower()])
	text.text = "\n".join(lines)

func _art_key(n: String, home: Dictionary) -> String:
	if home.has("boss"):
		var z: Dictionary = GameData.ZONES[int(home["zone"])]
		return z["mid"]["art"] if home["boss"] == "mid" else z["boss"]["art"]
	return String(Monsters.by_id(n).get("art", n))

func _boss_floor(home: Dictionary) -> int:
	return int(home["zone"]) * GameData.ZONE_FLOORS + (GameData.MID_BOSS_FLOOR if home["boss"] == "mid" else GameData.ZONE_FLOORS)

func _odds_line(label: String, odds: Array) -> String:
	var parts: Array = []
	for r in odds.size():
		var v: float = odds[r]
		parts.append("[color=%s]%s%%[/color]" % [GameData.color_of(r), ("%.1f" % v) if v < 10.0 else str(int(round(v)))])
	return "  %s: %s" % [label, " / ".join(parts)]

## "A helmet", "An off hand" (QA: the Signature line said "A off hand").
static func a_slot(slot: String) -> String:
	var s := slot.to_lower()
	return ("An " if s.left(1) in ["a", "e", "i", "o", "u"] else "A ") + s

func _num(n: int) -> String:
	var s := str(n)
	return s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3) if s.length() > 3 else s

## The plate's backdrop for a region: dark, with its mood light glowing up from the ground.
static func _ground(zi: int) -> Texture2D:
	if _grounds.has(zi):
		return _grounds[zi]
	var mood: Dictionary = HallsScene.MOODS[clampi(zi, 0, HallsScene.MOODS.size() - 1)]
	var amb: Color = mood["amb"]
	var light: Color = mood["light"]
	var img := Image.create(56, 56, false, Image.FORMAT_RGBA8)
	for y in 56:
		for x in 56:
			var g := clampf((y - 20.0) / 36.0, 0.0, 1.0)
			var d := Vector2(x - 27.5, (y - 46.0) * 2.2).length() / 30.0
			var c := Color(0.03, 0.03, 0.05).lerp(amb.darkened(0.6), g * 0.7)
			c = c.lerp(light.darkened(0.25), clampf(1.0 - d, 0.0, 1.0) * 0.55)
			if (x * 7 + y * 13) % 11 == 0 and y < 30:
				c = c.lightened(0.06)  # a little stone grain above the ground
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_grounds[zi] = tex
	return tex

## 2.1 G4: the selected monster's region: how much of its Bestiary you've defeated and the next reward.
func _strip() -> void:
	var zi := 0
	if selected != "" and codex.seen(selected):
		zi = clampi(int(GameData.monster_home(selected).get("zone", 0)), 0, GameData.ZONES.size() - 1)
	var track := "zone:" + String(GameData.ZONES[zi]["id"])
	var key := "%s|%d|%d" % [track, Collections.count(codex, track), codex.coll_earned.size()]
	if key == strip_key:
		return
	strip_key = key
	OnlineUI.clear(strip)
	strip.add_child(Collections.track_card(codex, track))
