class_name ClassTab
extends ScrollContainer
## Character > Class: your Evolution Tree. Shows the shape of the tree
## (1 > 2 > 4 > 8) but only names the classes you've reached and the ones you
## can choose right now; the rest stay "???" until you get there. Also your
## signature skills, the branch-offs of your current class, the Wanderer's
## items, the god trials and the hidden classes.

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

func refresh() -> void:
	var sn := ClassTree.stat_name(state)
	var key := "%s|%s|%d|%d|%s|%s|%s|%s|%s|%s|%s|%d|%s|%d" % [state.hero_class, str(state.class_path), state.level, int(state.faith), state.class_branch,
		str(state.class_items), selected, state.dev_mode, str(state.hidden), state.hidden_class, str(state.hidden_stage),
		int(state.ctrack.get("kills", 0)) / 25, sn, int(state.unique_value(sn)) if sn != "" else 0]
	key += "|%s|%d|%s|%s" % [state.sig_slot, ClassTree.divinity(state), state.trial_active, state.enemy_is_boss]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	if state.hero_class == "":
		box.add_child(UI.label("Choose a class first.", 14, UI.DIM))
		return
	_header()
	_pick_panel()
	_tree()
	_detail()
	_signatures()
	_god_trials()
	_branches()
	if state.hero_class == "Wanderer":
		_items()
	_hidden_classes()

# =====================================================================
# Header: who you are now
# =====================================================================

func _header() -> void:
	var info := state.class_info()
	var color := Color(info["color"])
	var cur := ClassTree.current(state)
	var r := ClassTree.rank_of(cur) if not cur.is_empty() else ""
	var border: Color = Color(ClassTree.RANK_COLORS[r]) if r != "" else color
	var card := UI.panel(UI.INSET, border, 10, 12, 2)
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
	var tl := UI.label(state.title().to_upper(), 22, border.lightened(0.25))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	if r != "":
		top.add_child(_badge(ClassTree.rank_text(cur), Color(ClassTree.RANK_COLORS[r])))
	var al := ClassTree.alignment(state)
	top.add_child(_badge(ClassTree.ALIGN_NAMES[al], Color(ClassTree.ALIGN_COLORS[al])))
	var steps: Array = [state.hero_class]
	for n in ClassTree.path_nodes(state):
		steps.append(n["name"])
	var path := UI.rich(13)
	path.text = "[color=%s]Your path:[/color] %s" % [UI.hex(UI.DIM), "  >  ".join(steps)]
	cv.add_child(path)
	var lines: Array = []
	for n in ClassTree.path_nodes(state):
		lines.append("[color=%s]%s:[/color] %s" % [UI.hex(UI.DIM), n["name"], ClassTree.bonus_text(n)])
	if lines.is_empty():
		lines.append("[color=%s]%s[/color]" % [UI.hex(UI.DIM), info["blurb"]])
	var bt := UI.rich(12)
	bt.text = "\n".join(lines)
	cv.add_child(bt)
	var sn := ClassTree.stat_name(state)
	if sn != "":
		var st := UI.rich(12)
		st.text = "[color=%s]Special stat:[/color] [b]%s %.1f[/b]  [color=%s](grows when you %s, and from every boss)[/color]\n[color=%s]It gives you:[/color] %s" % [
			UI.hex(UI.DIM), sn, state.unique_value(sn), UI.hex(UI.DIM), ClassTree.grow_text(state), UI.hex(UI.DIM), ClassTree.stat_text(state)]
		cv.add_child(st)
	var faith := UI.rich(11)
	faith.text = "[color=%s]Faith %+d. Holy skills, bosses and good deeds raise it; Shadow and Blood skills and dark bargains lower it. At %+d you count as Good, at %d as Evil.%s[/color]" % [
		UI.hex(UI.DIM), int(state.faith), int(ClassTree.GOOD_AT), int(ClassTree.EVIL_AT), " The Wanderer is always Neutral." if state.hero_class == "Wanderer" else ""]
	cv.add_child(faith)

static func _badge(text: String, c: Color) -> PanelContainer:
	var p := UI.panel(Color(c, 0.14), c, 6, 4, 1)
	p.add_child(UI.label(text, 11, c.lightened(0.2)))
	return p

# =====================================================================
# Choosing the next class
# =====================================================================

func _pick_panel() -> void:
	var t := ClassTree.pick_tier(state)
	if t < 0:
		if not ClassTree.options(state).is_empty():
			box.add_child(UI.label("Next choice at level %d." % int(ClassTree.PICK_LEVELS[state.class_path.size()]), 12, UI.DIM))
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
	var why := ClassTree.lock_reason(g, n, not with_button)
	var p := UI.panel(UI.INSET, border if why == "" else UI.BORDER, 8, 10, 2 if why == "" else 1)
	var v := UI.vbox(4)
	p.add_child(v)
	var head := UI.hbox(6)
	v.add_child(head)
	var nl := UI.label(String(n["name"]), 16, border.lightened(0.2) if why == "" else UI.DIM)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nl)
	var tags := UI.rich(11)
	var bits: Array = ["[color=%s]%s[/color]" % [ClassTree.ALIGN_COLORS[side], ClassTree.ALIGN_NAMES[side]]]
	if r != "":
		bits.append("[color=%s]%s[/color]" % [ClassTree.RANK_COLORS[r], ClassTree.rank_text(n)])
	tags.text = "  ".join(bits)
	v.add_child(tags)
	var t := UI.rich(12)
	t.text = "%s.\n[color=%s]%s[/color]" % [n["role_text"], UI.hex(UI.DIM), ClassTree.bonus_text(n)]
	v.add_child(t)
	var trial: bool = not (n.get("trial", {}) as Dictionary).is_empty() and not g.ctrack.get("trial_" + String(n["id"]), 0)
	if trial:
		var tr := UI.rich(11)
		tr.text = "[color=#fde047]God trial:[/color] %s" % n["trial"]["name"]
		v.add_child(tr)
	if String(n.get("item", "")) != "":
		var it: Dictionary = ClassTree.ITEMS[n["item"]]
		var ir := UI.rich(11)
		ir.text = "[color=#e8b14a]Needs:[/color] %s%s" % [it["name"], "  (you have it)" if n["item"] in g.class_items else ""]
		v.add_child(ir)
	if why != "" and not why.begins_with("Needs") and (with_button or why.begins_with("Your deeds")):
		var wl := UI.label(why, 11, Color("#f87171"))
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(wl)
	if with_button and why == "":
		var b := UI.primary("Face the trial" if trial else "Choose", on_pick, border)
		b.disabled = trial and (g.enemy_is_boss or g.trial_active)
		v.add_child(b)
	return p

# =====================================================================
# The tree picture
# =====================================================================

func _tree() -> void:
	UI.section(box, "Evolution Tree", "Your class evolves at levels 15, 35 and 60. Classes you haven't reached stay hidden until you get there.")
	var tv := TreeView.new()
	tv.state = state
	tv.selected = selected
	tv.picked.connect(func(id: String):
		selected = id if selected != id else ""
		shown = ""
		refresh())
	box.add_child(tv)
	var legend := UI.rich(11)
	legend.text = "[color=%s]Gold = your path. Border color shows a class's side: [color=%s]Good[/color], [color=%s]Neutral[/color], [color=%s]Evil[/color]. Level 60 classes are unique classes with a rank. Tap a class you've revealed to see it.[/color]" % [
		UI.hex(UI.DIM), ClassTree.ALIGN_COLORS["G"], ClassTree.ALIGN_COLORS["N"], ClassTree.ALIGN_COLORS["E"]]
	box.add_child(legend)

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
	if g.dev_mode or String(n["id"]) in g.class_path or g.discovered.has(n["name"]):
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
		var t := UI.rich(12)
		var els: Array = []
		for tg in s["tags"]:
			els.append("[color=%s]%s[/color]" % [Classes.tag_color(tg), tg])
		t.text = "%s  [color=%s](cooldown %d, %s)[/color]" % [s["text"], UI.hex(UI.DIM), int(s["cd"]), " ".join(els)]
		c[1].add_child(t)

# =====================================================================
# God trials (God rank classes only)
# =====================================================================

func _god_trials() -> void:
	if not ClassTree.god_trials_open(state):
		return
	UI.section(box, "God trials", "Three new trials every week, only for God rank classes. Each win is worth a point of Divinity (+1%% Attack, HP and Defense, up to %d)." % ClassTree.DIVINITY_MAX)
	box.add_child(UI.label("Divinity: %d / %d" % [ClassTree.divinity(state), ClassTree.DIVINITY_MAX], 14, Color(ClassTree.RANK_COLORS["God"])))
	for id in ClassTree.god_trials_now():
		var info: Dictionary = ClassTree.GOD_TRIALS[id]
		var done := ClassTree.god_trial_done(state, id)
		var c := UI.card(UI.GREEN if done else Color(ClassTree.RANK_COLORS["God"]), UI.INSET, 4)
		box.add_child(c[0])
		var h := UI.hbox(8)
		c[1].add_child(h)
		var nl := UI.label(String(info["name"]), 15, UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		if info.get("no_potions", false):
			h.add_child(UI.chip("NO POTIONS", UI.RED))
		c[1].add_child(UI.wrap(String(info["lore"]), 12, UI.DIM))
		if done:
			c[1].add_child(UI.label("Beaten this week.", 12, UI.GREEN))
		else:
			var tid: String = id
			var b := UI.primary("Face the trial", func():
				if ClassTree.start_god_trial(state, tid):
					main.sfx.play("boss_intro")
				main.refresh(), Color(ClassTree.RANK_COLORS["God"]))
			b.disabled = state.enemy_is_boss or state.trial_active
			b.custom_minimum_size = Vector2(0, UI.TAP)
			c[1].add_child(b)

# =====================================================================
# Branch-offs of your current class
# =====================================================================

func _branches() -> void:
	if state.class_branch != "":
		var b := ClassTree.node(state.class_branch)
		var t := UI.label("You took a branch-off: %s. Your tree ends here, and your special stat keeps growing." % b["name"], 12, UI.DIM)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(t)
		return
	if state.class_path.is_empty() or state.class_path.size() >= 3:
		return
	var cur_id: String = state.class_path[state.class_path.size() - 1]
	var cur := ClassTree.node(cur_id)
	box.add_child(UI.heading("Branch-offs of %s" % cur["name"]))
	var intro := UI.label("Hidden unique classes you can step into instead of climbing further. Taking one ends your tree, but gives you a special stat that keeps growing. They close when you pick your next class.", 11, UI.DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	for b in ClassTree.branches(cur_id):
		var prog := ClassTree.progress(state, b)
		var known: bool = prog >= 0.5 or state.dev_mode or state.discovered.has(b["name"])
		var ready := ClassTree.branch_ready(state, b)
		var rc := Color(ClassTree.RANK_COLORS[b["rank"]])
		var p := UI.panel(UI.INSET, rc if ready else UI.BORDER, 8, 8, 2 if ready else 1)
		box.add_child(p)
		var v := UI.vbox(4)
		p.add_child(v)
		var head := UI.hbox(6)
		v.add_child(head)
		var nl := UI.label(String(b["name"]) if known else "???", 14, rc if known else UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nl)
		head.add_child(_badge(ClassTree.rank_text(b) if known else "%s rank" % b["rank"], rc))
		var t := UI.rich(11)
		t.text = "[color=%s]How:[/color] %s  [color=%s](%s)[/color]%s" % [UI.hex(UI.DIM), b["how"], UI.hex(UI.DIM), ClassTree.progress_text(state, b),
			("\n[color=%s]Special stat: %s. %s[/color]" % [UI.hex(UI.DIM), b["stat"], ClassTree.bonus_text(b)]) if known else ""]
		v.add_child(t)
		var bar := UI.bar(rc, 8)
		bar.max_value = 1.0
		bar.value = prog
		v.add_child(bar)
		if ready:
			var bid: String = b["id"]
			var bname: String = b["name"]
			var brank: String = b["rank"]
			v.add_child(UI.primary("Become a %s (ends your tree)" % bname, func():
				main.confirm("Take %s?" % bname, "Your Evolution Tree ends here: you won't pick classes at later levels. You keep everything you have and gain a %s rank unique class." % brank, "Take it", func():
					ClassTree.take_branch(state, bid)
					main.refresh()), rc))

# =====================================================================
# The Wanderer's items
# =====================================================================

func _items() -> void:
	box.add_child(UI.heading("The Wanderer's items"))
	var t := UI.label("Sword Saint and every Wanderer final except Asura need an item. Each one comes from a single meeting on the road: a fight or a conversation that only finds a Wanderer at the right class.", 11, UI.DIM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(t)
	for it in ClassTree.ITEMS:
		var d: Dictionary = ClassTree.ITEMS[it]
		var have: bool = it in state.class_items
		var n := ClassTree.node(String(d["node"]))
		var at := ClassTree.node(String(d["at"]))
		var r := UI.rich(12)
		var where: String = {"elf": "in the Elf realm", "dwarf": "in the Dwarf realm, Honored", "demon": "in the Demon realm", "moon": "on a full moon"}.get(String(d["where"]), "on the road")
		r.text = "[color=%s]%s %s[/color] opens [b]%s[/b]  [color=%s](%s, as a %s, level %d+, %s)[/color]" % [
			"#4ade80" if have else UI.hex(UI.TEXT), "+" if have else "-", d["name"], n.get("name", "?"), UI.hex(UI.DIM), d["title"], at.get("name", "?"), int(d["level"]), where]
		box.add_child(r)

# =====================================================================
# Hidden classes (rules in hidden.gd)
# =====================================================================

func _hidden_classes() -> void:
	box.add_child(UI.heading("Hidden classes"))
	var intro := UI.label("Secret classes you unlock by how you play. They sit on top of your class: you keep everything and gain their title, bonuses and their own special stat.", 11, UI.DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	if not state.hidden.is_empty():
		var row := UI.hbox(6)
		box.add_child(row)
		row.add_child(UI.label("Using:", 12, UI.DIM))
		var pick := OptionButton.new()
		pick.add_item("None")
		var ids: Array = [""]
		for id in Hidden.ORDER:
			if state.hidden.has(id):
				pick.add_item(Hidden.info(id)["name"])
				ids.append(id)
				if id == state.hidden_class:
					pick.select(ids.size() - 1)
		pick.item_selected.connect(func(i: int): Hidden.use(state, ids[i]); main.refresh())
		row.add_child(pick)
	for tier in [1, 2, 3]:
		for id in Hidden.ORDER:
			var c := Hidden.info(id)
			if int(c["tier"]) != tier:
				continue
			_hidden_card(id, c)

func _hidden_card(id: String, c: Dictionary) -> void:
	var have := state.hidden.has(id)
	var close := Hidden.closeness(state, id)
	var col := Color(c["color"])
	var tier := int(c["tier"])
	var tcol := Color(Hidden.TIER_COLORS[tier])
	var p := UI.panel(Color("#2a2010") if state.hidden_class == id else UI.INSET, col.darkened(0.2) if have else UI.BORDER, 8, 8, 2 if have else 1)
	box.add_child(p)
	var v := UI.vbox(3)
	p.add_child(v)
	var head := UI.hbox(6)
	v.add_child(head)
	var shown_name: String = Hidden.title(state) if state.hidden_class == id else c["name"]
	var nl := UI.label(shown_name if have or state.dev_mode else "???", 14, col if have else UI.TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nl)
	head.add_child(UI.label(Hidden.TIER_NAMES[tier], 11, tcol))
	var t := UI.rich(11)
	if have:
		var st := int(state.hidden_stage.get(id, 1))
		var lines: Array = ["[color=%s]%s[/color]  Stage %d of %d: %s. Special stat: [b]%s[/b] %.1f" % [UI.hex(UI.DIM), c["lore"], st, c["stages"].size(),
			" > ".join(c["stages"]), c["stat"], state.unique_value(c["stat"])]]
		for line in Hidden.stage_progress(state, id):
			lines.append(_line(line))
		t.text = "\n".join(lines)
	elif close >= 0.5 or state.dev_mode:
		var lines: Array = ["[color=%s]%s[/color]" % [UI.hex(UI.DIM), c["rumor"]]]
		for line in Hidden.progress(state, id):
			lines.append(_line(line))
		var why := Hidden.block_reason(state, id)
		if why.begins_with("Another"):
			lines.append("[color=#f87171]%s[/color]" % why)
		t.text = "\n".join(lines)
	elif close >= 0.2:
		t.text = "[color=%s]%s[/color]" % [UI.hex(UI.DIM), c["rumor"]]
	else:
		t.text = "[color=%s]Nobody has heard of this one yet.[/color]" % UI.hex(UI.DIM)
	v.add_child(t)
	if not have and Hidden.ready_for_trial(state, id):
		var tb := UI.primary("Face %s" % c["trial"]["name"], func():
			if Hidden.start_trial(state, id):
				main.sfx.play("boss_intro")
			main.refresh(), col)
		tb.disabled = state.enemy_is_boss or state.trial_active
		v.add_child(tb)

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
		var heads := ["Start", "Level 15", "Level 35", "Level 60"]
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
		if state.class_branch != "" and not String(n["id"]) in path:
			return false
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
