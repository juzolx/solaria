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
static var _heads := {}
const PLATE := 296  # design px tall: a 121-row boss at 2 screen px per art pixel on a 430 pt phone
const ICON := 32    # list icon: ICON art pixels around the upper body, shown 1:1 (ICON screen pixels)
var pic_size := Vector2.ZERO
var text: RichTextLabel
var strip: VBoxContainer  # 2.1 G4: this region's Bestiary progress and its next reward
var strip_key := ""
var selected := ""
var shown := ""
var shown_kills := -1

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Bestiary"
	add_theme_constant_override("separation", 10)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(200, 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size", UI.MIN_FONT)
	list.add_theme_constant_override("v_separation", UI.TAP - 20)  # rows about 44 px tall: a comfortable tap (15 px text is ~20 px a line)
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
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # the whole column wide (fable r2: room for 2x bosses)
	top.add_child(plate)
	backdrop = TextureRect.new()
	backdrop.custom_minimum_size = Vector2(0, PLATE)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # a soft glow, no pixel grid (fable r2: the grain striped)
	plate.add_child(backdrop)
	pic = TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE  # sized by _place_pic to whole screen pixels
	backdrop.add_child(pic)
	backdrop.resized.connect(_place_pic)
	text = UI.rich(UI.FONT_CAPTION)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(text)

func refresh() -> void:
	# fable r3: a kill only changes counts, so those rows are relabelled in place; the list is
	# rebuilt (icons and all) only when a monster is met
	var key := str(codex.bestiary.size())
	if key == shown:
		var kills := int(codex.stat("kills"))
		if kills != shown_kills:
			shown_kills = kills
			for i in keys.size():
				if keys[i] != "":
					list.set_item_text(i, _label(keys[i]))
			_show()
		return
	shown = key
	shown_kills = int(codex.stat("kills"))
	# Phones: a narrower list ("Jack-in-Irons (12)" still fits) leaves the plate room for 2x bosses
	list.custom_minimum_size.x = 150.0 if bool(main.is_tall) else 200.0
	list.clear()
	keys.clear()
	# Icons are a head crop shown 1:1 on screen (fable r1: whole 76 px monsters squeezed to 22 px were blobs)
	var icon := int(round(ICON / _screen_scale()))
	list.fixed_icon_size = Vector2i(icon, icon)
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
			var i := list.add_item(_label(n))
			var head := _head(_art_key(n, GameData.monster_home(n)), met)
			if head != null:
				list.set_item_icon(i, head)
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

## A list row: "[Boss] Name  (kills)", a * once its Signature is found, "???" until met.
func _label(n: String) -> String:
	if not codex.seen(n):
		return "  ???"
	var boss: bool = Monsters.info(n).get("boss", false)
	var label := "  %s%s  (%d)" % ["[Boss] " if boss else "", Monsters.name_of(n), codex.kills(n)]
	if bool(codex.bestiary[n].get("sig", false)):
		label += "  *"
	return label

func _show() -> void:
	_strip()
	if selected == "" or not codex.seen(selected):
		# An unmet monster shows as its shape (the "???" goal), a blank plate before any pick
		var ua := Sprites.enemy_by_key(_art_key(selected, GameData.monster_home(selected))) if selected != "" else {}
		pic.texture = ua.get("white", null)
		pic.modulate = Color(0.5, 0.48, 0.6)
		pic_size = ua.get("size", Vector2.ZERO)
		_place_pic()
		text.text = "[color=%s]Meet a monster to learn about it. Monsters you haven't met show as ???.\n\nKill milestones (10, 100, 500 and 1,000 kills) give you lasting bonus damage and gold against that monster.[/color]" % UI.hex(UI.DIM)
		return
	var info := Monsters.info(selected)
	var boss: bool = info.get("boss", false)
	var home := GameData.monster_home(selected)
	var art := Sprites.enemy_by_key(_art_key(selected, home))
	var zi := clampi(int(home.get("zone", 0)), 0, 9)
	pic.texture = SpriteLight.lit(art.get("tex", null), zi) if art.has("tex") else null
	pic.modulate = Color.WHITE
	pic_size = art.get("size", Vector2.ZERO)
	_place_pic()
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
		# Juzo (Oct 24): weaknesses and resistances live here, not over the monster in a fight.
		# One row each, every element in its own colour.
		if kills >= 10 or main.state.dev_mode:
			lines.append("[b]Weak to[/b]   " + _element_chips(weak, dim))
			lines.append("[b]Resists[/b]   " + _element_chips(res, dim))
		else:
			lines.append("[b]Weak to[/b]   [color=%s]???  (kill 10 to learn)[/color]" % dim)
			lines.append("[b]Resists[/b]   [color=%s]???[/color]" % dim)
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

## Screen pixels per design pixel (the window's stretch factor).
func _screen_scale() -> float:
	var sc := get_global_transform_with_canvas().get_scale().x if is_inside_tree() else 1.0
	return sc if sc > 0.01 else 1.0

## Puts the monster on the plate at a whole number of screen pixels per art pixel
## (commons 2x, bosses and Calamities 1x on a phone), feet on the glowing ground.
func _place_pic() -> void:
	if pic == null or pic_size.x <= 0.0:
		return
	var sc := _screen_scale()
	var room := (backdrop.size - Vector2(12, 12)) * sc
	var k := maxf(1.0, floorf(minf(room.x / pic_size.x, room.y / pic_size.y)))
	# Commons never outsize the bosses (2x on a phone): one scale for the whole Bestiary
	k = minf(k, float(maxi(2, ArtStyle.unit(sc) - 1)))
	var sz := pic_size * k / sc
	var pos := Vector2((backdrop.size.x - sz.x) * 0.5, backdrop.size.y - 8.0 - sz.y)
	# snap the top-left corner onto the screen's pixel grid
	var origin := backdrop.get_global_transform_with_canvas().origin
	pos = ((origin + pos * sc).round() - origin) / sc
	pic.position = pos
	pic.size = sz

## The list icon (fable r2): a met monster's upper body (its head is about a quarter of the
## way down), ICON art pixels square at 1:1; an unmet one's whole shape fitted into ICON
## pixels (the shape is the tease).
## Made from the plain picture (no grade, no texture readback), cached by art key.
static func _head(key: String, met: bool) -> Texture2D:
	var ck := "%s|%s" % [key, met]
	if _heads.has(ck):
		return _heads[ck]
	var img := Sprites._img("enemies/%s.png" % key)
	if img == null:
		_heads[ck] = null
		return null
	var used := img.get_used_rect()
	var out: Image
	if met:
		var lo := img.get_width()
		var hi := -1
		var band := used.position.y + int(used.size.y * 0.35)
		for y in range(used.position.y + int(used.size.y * 0.1), band):
			for x in range(used.position.x, used.end.x):
				if img.get_pixel(x, y).a8 > 0:
					lo = mini(lo, x)
					hi = maxi(hi, x)
		var cx := (lo + hi) / 2 if hi >= 0 else used.get_center().x
		var x0 := clampi(cx - ICON / 2, 0, maxi(0, img.get_width() - ICON))
		var y0 := clampi(used.position.y + int(used.size.y * 0.25) - ICON / 2, 0, maxi(0, img.get_height() - ICON))
		out = img.get_region(Rect2i(x0, y0, ICON, ICON))
	else:
		var shape := Sprites._silhouette(img.get_region(used))
		var k := minf(float(ICON) / shape.get_width(), float(ICON) / shape.get_height())
		shape.resize(maxi(1, int(shape.get_width() * k)), maxi(1, int(shape.get_height() * k)), Image.INTERPOLATE_NEAREST)
		out = Image.create(ICON, ICON, false, Image.FORMAT_RGBA8)
		out.blit_rect(shape, Rect2i(Vector2i.ZERO, shape.get_size()), Vector2i((ICON - shape.get_width()) / 2, ICON - shape.get_height()))
	var tex := ImageTexture.create_from_image(out)
	_heads[ck] = tex
	return tex

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

## "◆ Fire  ◆ Holy": each element in its own colour (Combat.ELEMENT_COLORS), or "nothing".
func _element_chips(els: Array, dim: String) -> String:
	if els.is_empty():
		return "[color=%s]nothing[/color]" % dim
	var out: Array = []
	for e in els:
		out.append("[color=%s]◆ %s[/color]" % [Combat.ELEMENT_COLORS.get(String(e), "#c0cbdc"), String(e)])
	return "   ".join(out)
