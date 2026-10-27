class_name RewardsTab
extends ScrollContainer
## 2.1 G4: Codex › Rewards. Every collection milestone (collections.gd), what it
## takes and the title or look it gives. Looks only: none of it changes power.

var main
var codex: Codex
var box: VBoxContainer
var shown := ""

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Rewards"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box = UI.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

func refresh() -> void:
	var key := "%d|%d|%d|%d|%d|%d|%d" % [codex.coll_earned.size(), codex.bestiary.size(), codex.stat("kills"), codex.collection.size(),
		codex.pet_book.size(), codex.classes_found.size(), Trophies.data.size()]
	if key == shown:
		return
	shown = key
	OnlineUI.clear(box)
	var all := Collections.all()
	box.add_child(UI.label("Rewards  %d / %d" % [codex.coll_earned.size(), all.size()], UI.FONT_BODY, UI.GOLD))
	box.add_child(UI.wrap("Fill the Codex to earn titles, name colors and plate frames. Looks only: they never change your power. Every hero in every town shares them. Pick a title on the Hero page; name colors and frames at the Guild Hall.", UI.FONT_BODY, UI.DIM))
	var tracks := Collections.tracks()
	for g in Collections.GROUPS:
		box.add_child(UI.heading(String(g[0])))
		box.add_child(UI.wrap(String(g[1]), UI.FONT_BODY, UI.DIM))
		for t in tracks:
			if Collections.group_of(t) != String(g[0]):
				continue
			if t in ["secret", "god"] and Collections.count(codex, t) == 0:
				continue  # a surprise: these rewards show up once you find your first one
			var ms := Collections.on_track(t)
			if ms.size() == 1:
				box.add_child(_wrap_card(_row(ms[0], true), Collections.has(codex, String(ms[0]["id"]))))  # one reward: a single line with its own progress
				continue
			box.add_child(_track_card(t, ms))

## One milestone: done (with its date) or what's still needed.
func _row(m: Dictionary, with_track: bool) -> Control:
	var got := Collections.has(codex, String(m["id"]))
	var h := UI.hbox(8)
	var mark := UI.label("✓" if got else "◆", UI.FONT_BODY, UI.GOLD if got else UI.DIM)
	mark.custom_minimum_size = Vector2(16, 0)
	h.add_child(mark)
	var t := String(m["track"])
	var what := Collections.need_text(m)
	if with_track:
		what = "%s: %s" % [Collections.track_name(t), what]
		if not got and Collections.total(t) > 0:
			what += "  (%d / %d)" % [mini(Collections.count(codex, t), Collections.total(t)), Collections.total(t)]
		elif not got:
			what += "  (have %d)" % Collections.count(codex, t)
	var l := UI.wrap("%s  -  %s" % [what, Collections.reward_text(m)], UI.FONT_BODY, UI.TEXT if got else UI.DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if got:
		h.add_child(UI.label(str(codex.coll_earned[m["id"]]), UI.FONT_BODY, UI.DIM))
	return h

## Interface pass (approved mockup 15): one framed card per track: its name and count, a gold
## progress bar, then its milestones (gold check = earned). A finished track gets a gold edge.
func _track_card(t: String, ms: Array) -> PanelContainer:
	var have := Collections.count(codex, t)
	var tot := Collections.total(t)
	var all_got := true
	for m in ms:
		all_got = all_got and Collections.has(codex, String(m["id"]))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, UI.GOLD_DULL if all_got else UiSkin.IRON, 10))
	var v := UI.vbox(4)
	p.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	var nm := UI.label(Collections.track_name(t), UI.FONT_BODY, UI.GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	if tot > 0:
		head.add_child(UI.label("%d / %d" % [mini(have, tot), tot], UI.FONT_BODY, UI.DIM))
		var bar := UI.bar(UI.GOLD, 8)
		bar.max_value = tot
		bar.value = mini(have, tot)
		v.add_child(bar)
	for m in ms:
		v.add_child(_row(m, false))
	return p

## A single-reward line in the same frame.
func _wrap_card(row: Control, got: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.frame(UI.INSET, UI.GOLD_DULL if got else UiSkin.IRON, 10))
	p.add_child(row)
	return p
