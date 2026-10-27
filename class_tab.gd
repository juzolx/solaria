class_name ClassTab
extends ScrollContainer
## Hero › Class: your Evolution Tree. Shows the shape of the tree
## (1 > 2 > 4 > 8: you pick one of two at levels 15, 35 and 75) but only names
## the classes you've reached and the ones you can choose right now; the rest
## stay "???" until you get there. Also your faith, your signature skills, the
## hidden classes offered or taken (15, 35, 75) and a God class that answered.

var main
var state: GameState
var box: VBoxContainer
var shown := ""
var selected := ""   # node id shown in the detail card

func setup(m) -> void:
	main = m
	state = m.state
	name = "Class"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

## Fable r1 #11: the page is seven parts, each with its own key, and a refresh rebuilds only the
## parts whose inputs changed (a kill or a boss only touches the hidden-class part, not the
## portraits and frames of the rest).
var parts := {}   # part name -> its VBoxContainer (in page order)

func refresh() -> void:
	if parts.is_empty():
		for pname in ["none", "header", "pick", "god", "hidden", "tree", "detail", "sigs"]:
			var c := UI.vbox(10)
			box.add_child(c)
			parts[pname] = c
	if shown == "":   # someone asked for a full redraw
		for c in parts.values():
			c.remove_meta("key")
		shown = "built"
	var page := box
	var base := "%s|%s|%d|%s" % [state.hero_class, str(state.class_path), state.level, state.dev_mode]
	var sn := ClassTree.stat_name(state)
	_part("none", str(state.hero_class == ""), func():
		if state.hero_class == "":
			box.add_child(UI.label("Choose a class first.", UI.FONT_BODY, UI.DIM)))
	var no_class := state.hero_class == ""
	_part("header", "" if no_class else "%s|%d|%s|%s|%s|%s" % [base, int(state.faith), state.god_class, state.hidden_class, state.title(), str(state.god_offers)], _header)
	_part("pick", "" if no_class else "%s|%s|%s" % [base, str(state.god_offers), str(state.hidden_offer)], _pick_panel)
	_part("god", "" if no_class else "%s|%s|%s" % [base, state.god_class, str(state.god_offers)], _god_classes)   # a God class that answered, or yours
	_part("hidden", "" if no_class else "%s|%s|%s|%s|%d|%s|%d|%s|%s|%s" % [base, str(state.hidden), state.hidden_class, str(state.hidden_stage),
		int(state.ctrack.get("kills", 0)) / 25, sn, int(state.unique_value(sn)) if sn != "" else 0, state.trial_active, state.enemy_is_boss, str(state.hidden_offer) + str(state.best_floor)], _hidden_classes)
	_part("tree", "" if no_class else "%s|%s" % [base, str(state.appearance)], _tree)
	_part("detail", "" if no_class else "%s|%s" % [base, selected], _detail)
	_part("sigs", "" if no_class else "%s|%s" % [base, state.sig_slot], _signatures)
	box = page

## Rebuilds one part of the page when its key changed; the builders add to `box`.
func _part(pname: String, key: String, builder: Callable) -> void:
	var c: VBoxContainer = parts[pname]
	if c.has_meta("key") and String(c.get_meta("key")) == key:
		return
	c.set_meta("key", key)
	OnlineUI.clear(c)
	if key != "" or pname == "none":
		var page := box
		box = c
		builder.call()
		box = page
	c.visible = c.get_children().any(func(n): return not n.is_queued_for_deletion())

# =====================================================================
# Header: who you are now
# =====================================================================

func _header() -> void:
	var info := state.class_info()
	var color := Color(info["color"])
	var cur := ClassTree.current(state)
	var r := ClassTree.rank_of(cur) if not cur.is_empty() else ""
	var border: Color = Color(ClassTree.RANK_COLORS[r]) if r != "" else color
	# interface pass: the panel frame; a rank colour (identity, like rarity) may tint its line, the class colour stays in the name
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, border if r != "" else UiSkin.IRON, 12))
	box.add_child(card)
	var h := UI.hbox(12)
	card.add_child(h)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(state.appearance, state.hero_looks())
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT) * 2
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(pic)
	var cv := UI.vbox(4)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(cv)
	var top := UI.hbox(8)
	cv.add_child(top)
	var tl := UI.name_plate(state.title())   # Fable r2 #11: the name in bone, the class colour stays on the frame
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	if r != "":
		top.add_child(_badge(ClassTree.rank_text(cur), Color(ClassTree.RANK_COLORS[r])))
	var al := ClassTree.alignment(state)
	top.add_child(_badge(ClassTree.ALIGN_NAMES[al], Color(ClassTree.ALIGN_COLORS[al])))
	var steps: Array = [state.hero_class]
	for n in ClassTree.path_nodes(state):
		steps.append(n["name"])
	var path := UI.rich(UI.FONT_BODY)
	path.text = "[color=%s]Your path:[/color] %s" % [UI.hex(UI.DIM), "  >  ".join(steps)]
	cv.add_child(path)
	var lines: Array = []
	for n in ClassTree.path_nodes(state):
		lines.append("[color=%s]%s:[/color] %s" % [UI.hex(UI.DIM), n["name"], ClassTree.bonus_text(n)])
	if lines.is_empty():
		lines.append("[color=%s]%s[/color]" % [UI.hex(UI.DIM), info["blurb"]])
	var bt := UI.rich(UI.FONT_BODY)
	bt.text = "\n".join(lines)
	cv.add_child(bt)
	var sn := ClassTree.stat_name(state)
	if sn != "":
		var st := UI.rich(UI.FONT_BODY)
		st.text = "[color=%s]Special stat:[/color] [b]%s %.1f[/b]  [color=%s](grows when you %s, and from every boss)[/color]\n[color=%s]It gives you:[/color] %s" % [
			UI.hex(UI.DIM), sn, state.unique_value(sn), UI.hex(UI.DIM), ClassTree.grow_text(state), UI.hex(UI.DIM), ClassTree.stat_text(state)]
		cv.add_child(st)
	# Fable r1 #12: Faith is a chip; the rules are a tap away
	var faith := UI.chip("Faith %+d" % int(state.faith), Color(ClassTree.ALIGN_COLORS[al]), UI.FONT_BODY)
	faith.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UI.tip(faith, "Holy skills, bosses and good deeds raise Faith; Shadow and Blood skills and dark bargains lower it. At %+d you count as Good, at %d as Evil.%s" % [
		int(ClassTree.GOOD_AT), int(ClassTree.EVIL_AT), " The Wanderer is always Neutral." if state.hero_class == "Wanderer" else ""])
	cv.add_child(faith)

static func _badge(text: String, c: Color) -> PanelContainer:
	var p := UI.panel(Color(c, 0.14), c, 6, 4, 1)
	p.add_child(UI.label(text, UI.FONT_BODY, c.lightened(0.2)))
	return p

# =====================================================================
# Choosing the next class
# =====================================================================

func _pick_panel() -> void:
	var t := ClassTree.pick_tier(state)
	if t < 0:
		if not ClassTree.options(state).is_empty():
			box.add_child(UI.label("Next choice at level %d." % int(ClassTree.PICK_LEVELS[state.class_path.size()]), UI.FONT_BODY, UI.DIM))
		return
	box.add_child(UI.heading("Choose your class (level %d)" % int(ClassTree.PICK_LEVELS[t])))
	var cols := UI.hbox(8)
	box.add_child(cols)
	for n in ClassTree.options(state):
		var c := class_card(main, n, true, func():
			if ClassTree.pick(state, n["id"]):
				main.sfx.play("spec" if (n.get("trial", {}) as Dictionary).is_empty() else "boss_intro")
			main.refresh())
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(c)

## A card for one class: name, side, rank, role, bonuses, and a Choose button.
static func class_card(m, n: Dictionary, with_button: bool, on_pick: Callable) -> PanelContainer:
	var g: GameState = m.state
	var side := String(n["side"])
	var sc := Color(ClassTree.ALIGN_COLORS[side])
	var r := ClassTree.rank_of(n)
	var border := Color(ClassTree.RANK_COLORS[r]) if r != "" else sc.darkened(0.25)
	# A God class that answered is a swap, not a tree pick: faith and side never lock it
	var is_god := bool(n.get("god", false)) or r == "God"
	var why := "" if is_god else ClassTree.lock_reason(g, n, not with_button)
	var p := PanelContainer.new()   # interface pass: the panel frame; only a rank colour tints its line
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, Color(ClassTree.RANK_COLORS[r]) if r != "" and why == "" else UiSkin.IRON, 10))
	var v := UI.vbox(4)
	p.add_child(v)
	# the class's outfit on your own hero (race, build, hair, face): what you'd look like
	var st := outfit_stage(g, String(n.get("cls", g.hero_class)), int(ClassTree.PICK_LEVELS[clampi(int(n.get("tier", 1)) - 1, 0, 2)]), 2)
	if why != "":
		st.modulate = Color(1, 1, 1, 0.55)   # locked: the outfit, dimmed
	v.add_child(st)
	var head := UI.hbox(6)
	v.add_child(head)
	var nl := UI.label(String(n["name"]), UI.FONT_BODY, UI.GOLD if why == "" else UI.DIM)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nl)
	var tags := UI.rich(UI.FONT_BODY)
	var bits: Array = ["[color=%s]%s[/color]" % [ClassTree.ALIGN_COLORS[side], ClassTree.ALIGN_NAMES[side]]]
	if r != "":
		bits.append("[color=%s]%s[/color]" % [ClassTree.RANK_COLORS[r], ClassTree.rank_text(n)])
	tags.text = "  ".join(bits)
	v.add_child(tags)
	var t := UI.rich(UI.FONT_BODY)
	t.text = "%s.\n[color=%s]%s[/color]" % [n["role_text"], UI.hex(UI.DIM), ClassTree.bonus_text(n)]
	v.add_child(t)
	if why != "" and (with_button or why.begins_with("Your deeds")):
		var wl := UI.label(why, UI.FONT_BODY, Color("#f87171"))
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(wl)
	if with_button and why == "":
		var b := UI.primary("Swap" if is_god else "Choose", on_pick)   # the gold main action
		v.add_child(b)
	return p

## Interface pass: your hero (own race, build, hair and face) in a class's outfit, front portrait at a
## whole-pixel scale on the plinth. Sprites caches every look, so a card never rebuilds it.
static func outfit_stage(g: GameState, cls: String, tier: int, scale := 2, silhouette := false, gear := {}) -> Control:
	var looks: Dictionary = (gear if not gear.is_empty() else g.hero_looks()).duplicate()
	looks["Class"] = {"cls": cls if Classes.CLASSES.has(cls) else (g.hero_class if g.hero_class != "" else "Warrior"), "tier": tier}
	# a class shows its own weapon (a mage card holds a staff, not your sword)
	var sig := str(Classes.CLASSES.get(looks["Class"]["cls"], {}).get("look", {}).get("Weapon", ""))
	if sig != "" and str((looks.get("Weapon", {}) as Dictionary).get("type", "")) != sig:
		looks["Weapon"] = Sprites.gear_look({"slot": "Weapon", "type": sig, "rarity": 1})
	var side := Sprites.PORTRAIT * scale
	var plinth_w := 24 * scale
	var c := Control.new()
	c.custom_minimum_size = Vector2(side, side + 6)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pl := TextureRect.new()
	pl.texture = UiIcons.plinth(plinth_w)
	pl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	c.add_child(pl)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(g.appearance, looks)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.custom_minimum_size = Vector2(side, side)
	pic.size = pic.custom_minimum_size
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if silhouette:   # a step not reached yet: a flat slate shape of the whole hero (Fable r1 #17)
		pic.texture = ImageTexture.create_from_image(Sprites._silhouette((pic.texture as Texture2D).get_image()))
		pic.modulate = UI.EMPTY
	c.add_child(pic)
	c.resized.connect(func():   # centred, whole pixels, the plinth under the feet
		pic.position = Vector2(roundf((c.size.x - side) / 2.0), 0)
		pl.position = Vector2(roundf((c.size.x - pl.texture.get_width()) / 2.0), c.size.y - pl.texture.get_height()))
	return c

## Interface pass: one class in the first "Choose your class" picker: your hero in its outfit and
## starting gear, its name, role and tags, the blurb and first skill, and the gold main action.
static func pick_card(m, cname: String, on_pick: Callable) -> PanelContainer:
	var info: Dictionary = Classes.CLASSES[cname]
	var card := PanelContainer.new()
	# the frame takes the class colour, so 13 cards read as 13 classes at a glance
	card.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, Color(info.get("color", "#8b9bb4")).darkened(0.2), 10))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cv := UI.vbox(6)
	card.add_child(cv)
	var head := UI.hbox(10)
	cv.add_child(head)
	var gear := {}
	for slot in info["look"]:
		gear[slot] = Sprites.gear_look({"slot": slot, "type": info["look"][slot], "rarity": 1})
	head.add_child(outfit_stage(m.state, cname, 0, 3, false, gear))   # the bible's one scale: 3x
	var hv := UI.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UI.label(cname, UI.FONT_TITLE, UI.GOLD))   # one accent: the class colour lives in its outfit
	var tags: Array = []
	for t in info["tags"]:
		tags.append("[color=%s]%s[/color]" % [Classes.tag_color(t), t])
	var tl := UI.rich(UI.FONT_BODY)
	tl.text = "%s
%s" % [info["role"], " ".join(tags)]
	hv.add_child(tl)
	var blurb := UI.rich(UI.FONT_BODY)
	blurb.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), info["blurb"]]
	hv.add_child(blurb)
	var start: Array = info["start"]
	var text := UI.rich(UI.FONT_BODY)
	text.text = "[color=%s]First skill, %s:[/color] %s" % [UI.hex(UI.GOLD_DULL), SkillData.skill_name(start[0]), SkillData.info(start[0])["text"]]
	cv.add_child(text)
	var b := UI.primary("Play as %s" % cname, on_pick)
	b.custom_minimum_size = Vector2(0, UI.TAP)
	cv.add_child(b)
	return card

# =====================================================================
# The tree picture
# =====================================================================

func _tree() -> void:
	if state.hidden_class != "":
		UI.section(box, "Your path", "Your main route ended when you took a hidden class. It grows on its own now, at levels 15, 35 and 75.")
		return
	# Fable r1 #17: one line of four nodes (dots on a 2 px line, the level under each); reached
	# nodes show the outfit and the class in gold, the ones ahead a dark "?" shape. The choose-now
	# state is the gold pick panel above, not a second colour here.
	UI.section(box, "Your path", "Your class evolves at levels 15, 35 and 75.")
	# a body with one outfit for the class shows no dark shape ahead: it would promise a new look (Fable hero R3 item 9)
	var tiered := not HeroArt.available() or HeroArt.outfit_tiers(state.hero_class, state.appearance) > 1
	var row := UI.hbox(0)
	box.add_child(row)
	var steps: Array = [{"level": 1, "id": "", "name": state.hero_class}]
	for i in ClassTree.PICK_LEVELS.size():
		var id: String = state.class_path[i] if state.class_path.size() > i else ""
		steps.append({"level": int(ClassTree.PICK_LEVELS[i]), "id": id})
	for i in steps.size():
		var st: Dictionary = steps[i]
		var n: Dictionary = ClassTree.node(String(st["id"])) if String(st["id"]) != "" else {}
		if st.has("name"):
			n = {"name": st["name"]}
		var reached := not n.is_empty()
		var next_reached := i + 1 < steps.size() and (String(steps[i + 1]["id"]) != "")
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		var pic: Control
		if reached or tiered:
			pic = outfit_stage(state, state.hero_class, 0 if i == 0 else int(st["level"]), 1, not reached)
		else:
			pic = Control.new()
			pic.custom_minimum_size = Vector2(Sprites.PORTRAIT, Sprites.PORTRAIT + 6)
		if not reached:
			var q := UI.label("?", UI.FONT_TITLE, UI.DIM)
			q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pic.add_child(q)
		v.add_child(pic)
		var track := Control.new()   # this node's dot and its half of the line either side
		track.custom_minimum_size = Vector2(0, 16)
		var first := i == 0
		var last := i == steps.size() - 1
		track.draw.connect(func():
			var cy := roundf(track.size.y / 2.0)
			var cx := roundf(track.size.x / 2.0)
			if not first:
				track.draw_rect(Rect2(0, cy - 1, cx, 2), UI.GOLD_DULL if reached else UI.EMPTY)
			if not last:
				track.draw_rect(Rect2(cx, cy - 1, track.size.x - cx, 2), UI.GOLD_DULL if next_reached else UI.EMPTY)
			track.draw_rect(Rect2(cx - 7, cy - 7, 14, 14), UiSkin.SOOT)
			track.draw_rect(Rect2(cx - 5, cy - 5, 10, 10), UI.GOLD if reached else UI.EMPTY))
		v.add_child(track)
		var lv := UI.label("Start" if i == 0 else "Lv %d" % int(st["level"]), UI.FONT_BODY, UI.DIM)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lv)
		var nl := UI.label(String(n["name"]) if reached else "?", UI.FONT_BODY, UI.GOLD if reached else UI.DIM)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	# Dev Mode still shows the whole branching tree
	if state.dev_mode:
		var tv := TreeView.new()
		tv.state = state
		tv.selected = selected
		tv.picked.connect(func(id: String):
			selected = id if selected != id else ""
			shown = ""
			refresh())
		box.add_child(tv)

func _detail() -> void:
	if selected == "":
		return
	var n := ClassTree.node(selected)
	if n.is_empty() or n["cls"] != state.hero_class or not revealed(state, n):
		return
	box.add_child(class_card(main, n, false, func(): pass))

## Is this class shown by name? Yes if you've been it, if you can choose it
## right now, or in Dev Mode. Everything else on the tree is "???".
static func revealed(g: GameState, n: Dictionary) -> bool:
	if g.dev_mode or String(n["id"]) in g.class_path or g.discovered.has(n["id"]):
		return true
	if ClassTree.pick_tier(g) >= 0:
		return ClassTree.options(g).any(func(o): return String(o["id"]) == String(n["id"]))
	return false

# =====================================================================
# Signature skills
# =====================================================================

func _signatures() -> void:
	var owned := Signatures.owned(state)
	if owned.is_empty():
		return
	UI.section(box, "Signature skills", "Every class you evolve into teaches one. The one in your Signature slot is your 4th skill button in fights.")
	for id in owned:
		var s := SkillData.info(String(id))
		var on: bool = state.sig_slot == id
		var c := UI.card(Color(Signatures.COLOR) if on else UI.BORDER, Color("#221d0e") if on else UI.INSET, 4)
		box.add_child(c[0])
		var h := UI.hbox(8)
		c[1].add_child(h)
		var nl := UI.label(String(s["name"]), 15, Color(Signatures.COLOR) if on else UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		h.add_child(UI.chip(String(s["class"]), Color(Classes.tag_color(String(s["tags"][0])))))
		if on:
			h.add_child(UI.chip("IN SLOT", Color(Signatures.COLOR)))
		else:
			var sid: String = id
			var b := UI.button("Use", func(): state.set_signature(sid); main.refresh())
			b.custom_minimum_size = Vector2(64, UI.TAP)
			h.add_child(b)
		var t := UI.rich(UI.FONT_BODY)
		var els: Array = []
		for tg in s["tags"]:
			els.append("[color=%s]%s[/color]" % [Classes.tag_color(tg), tg])
		t.text = "%s  [color=%s](cooldown %d, %s)[/color]" % [s["text"], UI.hex(UI.DIM), int(s["cd"]), " ".join(els)]
		c[1].add_child(t)

# =====================================================================
# God classes (rules in god_classes.gd)
# =====================================================================

## A God class that answered (swap now, or later from here), or the one you are.
func _god_classes() -> void:
	if state.god_class == "" and state.god_offers.is_empty():
		return
	box.add_child(UI.heading("God class"))
	if state.god_class != "":
		var me := ClassTree.node(state.god_class)
		box.add_child(class_card(main, me, false, Callable()))
		return
	box.add_child(UI.wrap("Your deeds were seen. A God class answers you: you can swap into it now, or later from here. It's for good.", UI.FONT_BODY, Color(ClassTree.RANK_COLORS["God"])))
	for id in state.god_offers:
		box.add_child(class_card(main, ClassTree.node(id), true, func():
			main.confirm("Become %s?" % ClassTree.node(id)["name"], "A God class is the rank above every other. It replaces your class for good.", "Swap", func():
				if GodClasses.take(state, id):
					main.sfx.play("hidden")
				shown = ""
				main.refresh())))

# =====================================================================
# Hidden classes (rules in hidden.gd)
# =====================================================================

func _hidden_classes() -> void:
	# Juzo: a surprise. Nothing shows until you hit 15, 35 or 75 with one earned.
	if state.hidden_class != "":
		var id := state.hidden_class
		var c := Hidden.info(id)
		var col := Color(c["color"])
		var st := Hidden.stage(state)
		box.add_child(UI.heading("Your hidden class"))
		var p := UI.panel(Color("#2a2010"), col.darkened(0.2), 8, 10, 2)
		box.add_child(p)
		var v := UI.vbox(4)
		p.add_child(v)
		var head := UI.hbox(6)
		v.add_child(head)
		var nl := UI.label(Hidden.title(state), UI.FONT_BODY, col)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nl)
		head.add_child(UI.label(Hidden.TIER_NAMES[int(c["tier"])], UI.FONT_BODY, Color(Hidden.TIER_COLORS[int(c["tier"])])))
		var t := UI.rich(UI.FONT_BODY)
		var lines: Array = ["[color=%s]%s[/color]" % [UI.hex(UI.DIM), c["lore"]],
			"Step %d of 3:  %s" % [st, " > ".join(c["stages"])],
			"[color=#4ade80]Now:[/color] %s" % Hidden.stage_text(id, st)]
		if st < 3:
			lines.append("[color=%s]At level %d (%s):[/color] %s" % [UI.hex(UI.GOLD), int(Hidden.STAGE_LEVELS[st]), c["stages"][st], Hidden.stage_text(id, st + 1)])
		lines.append("[color=%s]%s %.1f. %s[/color]" % [UI.hex(UI.DIM), c["stat"], state.unique_value(c["stat"]), Hidden.stat_text(state).replace("\n", ". ")])
		t.text = "\n".join(lines)
		v.add_child(t)
		return
	if not state.hidden_offer.is_empty():
		box.add_child(UI.heading("A hidden path"))
		hidden_offer_cards(main, box, func(): shown = ""; main.refresh())
		return
	var whispers := ClassHints.riddles(state)  # 2.1 G7: riddles, never names; more open as you go deeper
	if not whispers.is_empty():
		# Fable r1 #12: one whisper on the page, all of them on a tap
		var wh := UI.heading("Whispers", ("Rumours of secret classes. Tap for all %d." % whispers.size()) if whispers.size() > 1 else "A rumour of a secret class.")
		var quoted: Array = []
		for w in whispers:
			quoted.append("\"%s\"" % w)
		UI.tip(wh, "\n".join(quoted))
		box.add_child(wh)
		var wl := UI.rich(UI.FONT_BODY)
		wl.text = "[i]\"%s\"[/i]" % whispers[0]
		box.add_child(wl)
	if not state.dev_mode:
		return
	box.add_child(UI.heading("Hidden classes (Dev Mode)"))
	for id in Hidden.ORDER:
		var c := Hidden.info(id)
		var r := UI.rich(UI.FONT_BODY)
		var lines: Array = ["[b]%s[/b]  %s  [color=%s]%s[/color]" % [c["name"], "Earned" if state.hidden.has(id) else "", UI.hex(UI.DIM), c["rumor"]]]
		for line in Hidden.progress(state, id):
			lines.append(_line(line))
		r.text = "\n".join(lines)
		box.add_child(r)

## The hidden classes on offer, as cards with a Take button (the level-up popup uses this too).
static func hidden_offer_cards(m, parent: Control, on_done: Callable) -> void:
	var st: GameState = m.state
	var stage := Hidden.stage(st)
	var note := UI.wrap("Secret classes you earned by how you play. Take one instead of the main route, until level %d. It becomes your class for good: no more evolutions." % (st.hidden_offer_level + 1), UI.FONT_BODY, Color("#c4b5fd"))
	parent.add_child(note)
	for id in st.hidden_offer:
		var c := Hidden.info(id)
		var col := Color(c["color"])
		var p := UI.panel(UI.INSET, col.darkened(0.15), 8, 10, 2)
		parent.add_child(p)
		var v := UI.vbox(4)
		p.add_child(v)
		var head := UI.hbox(6)
		v.add_child(head)
		var nl := UI.label(c["stages"][stage - 1], UI.FONT_CAPTION, col)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nl)
		head.add_child(UI.label(Hidden.TIER_NAMES[int(c["tier"])], UI.FONT_BODY, Color(Hidden.TIER_COLORS[int(c["tier"])])))
		var t := UI.rich(UI.FONT_BODY)
		var lines: Array = ["[color=%s]%s[/color]" % [UI.hex(UI.DIM), c["lore"]], "[color=#4ade80]Gives:[/color] %s" % Hidden.stage_text(id, stage)]
		if stage < 3:
			lines.append("[color=%s]Grows at level %s into %s.[/color]" % [UI.hex(UI.DIM), " and ".join(Hidden.STAGE_LEVELS.slice(stage).map(func(x): return str(x))), " and ".join(c["stages"].slice(stage))])
		t.text = "\n".join(lines)
		v.add_child(t)
		var trial: bool = c.has("trial") and not st.feats.get("trial_" + id, 0)
		var b := UI.primary("Take this path" + ((" (beat %s first)" % c["trial"]["name"]) if trial else ""), func():
			m.confirm("Become %s?" % c["stages"][stage - 1], "This is for good. Your class stops evolving and %s becomes your class." % c["name"], "Take it", func():
				if Hidden.take(st, id):
					m.sfx.play("boss_intro" if trial else "spec")
				on_done.call()), col)
		b.custom_minimum_size = Vector2(0, UI.TAP)
		v.add_child(b)

func _line(line: Array) -> String:
	var ok := int(line[1]) >= int(line[2])
	var amount := "" if int(line[2]) <= 1 else "  %d / %d" % [mini(int(line[1]), int(line[2])), int(line[2])]
	return "[color=%s]%s %s%s[/color]" % ["#4ade80" if ok else UI.hex(UI.DIM), "+" if ok else "-", line[0], amount]

# =====================================================================
# TreeView: draws the 1 > 2 > 4 > 8 tree
# =====================================================================

class TreeView extends Control:
	signal picked(id: String)
	var state: GameState
	var selected := ""
	var rects := {}   # node id -> Rect2
	const ROW := 30.0
	const COLS := [0.0, 0.17, 0.42, 0.68]

	func _ready() -> void:
		custom_minimum_size = Vector2(0, ROW * 8 + 34)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func _layout() -> void:
		rects.clear()
		var w := size.x
		var widths := [w * 0.15, w * 0.23, w * 0.24, w * 0.32]
		var top := 26.0
		var roots := ClassTree.roots(state.hero_class)
		rects["root"] = Rect2(0, top + ROW * 3.5 - 12, widths[0], 24)
		for i in roots.size():
			var r1: String = roots[i]
			var y1 := top + ROW * (1.5 + 4.0 * i)
			rects[r1] = Rect2(w * float(COLS[1]), y1 - 12, widths[1], 24)
			var kids: Array = ClassTree.children(r1)
			for j in kids.size():
				var r2: String = kids[j]
				var y2 := top + ROW * (0.5 + 4.0 * i + 2.0 * j)
				rects[r2] = Rect2(w * float(COLS[2]), y2 - 12, widths[2], 24)
				var finals: Array = ClassTree.children(r2)
				for k in finals.size():
					var r3: String = finals[k]
					var y3 := top + ROW * (4.0 * i + 2.0 * j + k) + 3.0
					rects[r3] = Rect2(w * float(COLS[3]), y3, widths[3], 24)

	func _draw() -> void:
		if state == null:
			return
		_layout()
		var font := get_theme_default_font()
		var dim := Color("#64748b")
		var heads := ["Start", "Level 15", "Level 35", "Level 75"]
		for i in 4:
			draw_string(font, Vector2(float(COLS[i]) * size.x, 14), heads[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
		var on_path: Array = state.class_path
		for id in rects:
			if id == "root":
				continue
			var n := ClassTree.node(id)
			var parent := String(n["parent"]) if String(n["parent"]) != "" else "root"
			if not rects.has(parent):
				continue
			var a: Rect2 = rects[parent]
			var b: Rect2 = rects[id]
			var p0 := Vector2(a.end.x, a.get_center().y)
			var p1 := Vector2(b.position.x, b.get_center().y)
			var mx := (p0.x + p1.x) / 2.0
			var lit: bool = id in on_path and (parent == "root" or parent in on_path)
			var c := Color("#e8b14a") if lit else Color("#334155")
			var wd := 2.0 if lit else 1.0
			draw_line(p0, Vector2(mx, p0.y), c, wd)
			draw_line(Vector2(mx, p0.y), Vector2(mx, p1.y), c, wd)
			draw_line(Vector2(mx, p1.y), p1, c, wd)
		var cls_col := Color(state.class_info().get("color", "#e8b14a"))
		_box(rects["root"], state.hero_class, cls_col, true, true, false, "", font)
		for id in rects:
			if id == "root":
				continue
			var n := ClassTree.node(id)
			var side_c := Color(ClassTree.ALIGN_COLORS[n["side"]])
			var r := ClassTree.rank_of(n)
			var shown := ClassTab.revealed(state, n)
			var label := String(n["name"]) if shown else "???"
			if r == "God" and shown:
				label = "* " + label
			_box(rects[id], label, side_c if shown else Color("#475569"), id in on_path, _reachable(n) and shown, id == selected, r if shown else "", font)

	## Classes on a branch you didn't take, or locked by your side, are drawn faded.
	func _reachable(n: Dictionary) -> bool:
		var path: Array = state.class_path
		var t := int(n["tier"])
		if path.size() >= t:
			return path[t - 1] == n["id"]
		if path.size() > 0:
			var p := String(n["parent"])
			while p != "" and int(ClassTree.node(p)["tier"]) > path.size():
				p = String(ClassTree.node(p)["parent"])
			if p != "" and p != String(path[path.size() - 1]):
				return false
		return ClassTree.side_ok(state, String(n["side"]))

	func _box(r: Rect2, text: String, side_c: Color, mine: bool, reachable: bool, sel: bool, rank: String, font: Font) -> void:
		var border := side_c if reachable else Color(side_c, 0.3)
		if rank != "" and reachable:
			border = Color(ClassTree.RANK_COLORS[rank])
		if mine:
			border = Color("#e8b14a")
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#2a2010") if mine else Color("#0f172a")
		sb.border_color = border
		sb.set_border_width_all(2 if (mine or sel) else 1)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, r)
		if sel:
			draw_rect(r.grow(2), Color(1, 1, 1, 0.5), false, 1.0)
		var tc := Color("#f8fafc") if reachable else Color("#64748b")
		if mine:
			tc = Color("#fde68a")
		var fs := 11 if r.size.x > 110 else 10
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		while tw > r.size.x - 8 and text.length() > 4:
			text = text.substr(0, text.length() - 2) + "."
			tw = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(r.position.x + (r.size.x - tw) / 2.0, r.position.y + r.size.y / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
		if rank != "":
			var rc := Color(ClassTree.RANK_COLORS[rank])
			var rw := font.get_string_size(rank, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			draw_string(font, Vector2(r.end.x - rw - 4, r.position.y + 9), rank, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(rc, 0.9 if reachable else 0.35))

	func _gui_input(event: InputEvent) -> void:
		var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
		if not pressed:
			return
		var pos: Vector2 = event.position
		for id in rects:
			if id != "root" and (rects[id] as Rect2).has_point(pos) and ClassTab.revealed(state, ClassTree.node(id)):
				picked.emit(id)
				accept_event()
				return
