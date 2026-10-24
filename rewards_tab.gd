class_name RewardsTab
extends ScrollContainer
## 2.1 G4: Codex > Rewards. Every collection milestone (collections.gd), what it
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
	box.add_child(UI.label("Rewards  %d / %d" % [codex.coll_earned.size(), all.size()], 15, UI.GOLD))
	box.add_child(UI.wrap("Fill the Codex to earn titles, name colors and plate frames. Looks only: they never change your power. Every hero in every town shares them. Pick a title on the Hero tab; name colors and frames at the Guild Hall.", UI.FONT_CAPTION, UI.DIM))
	var tracks := Collections.tracks()
	for g in Collections.GROUPS:
		box.add_child(UI.heading(String(g[0])))
		box.add_child(UI.wrap(String(g[1]), UI.FONT_CAPTION, UI.DIM))
		for t in tracks:
			if Collections.group_of(t) != String(g[0]):
				continue
			if t in ["secret", "god"] and Collections.count(codex, t) == 0:
				continue  # a surprise: these rewards show up once you find your first one
			var ms := Collections.on_track(t)
			if ms.size() == 1:
				box.add_child(_row(ms[0], true))  # one reward: a single line with its own progress
				continue
			box.add_child(Collections.track_card(codex, t))
			for m in ms:
				box.add_child(_row(m, false))

## One milestone: done (with its date) or what's still needed.
func _row(m: Dictionary, with_track: bool) -> Control:
	var got := Collections.has(codex, String(m["id"]))
	var h := UI.hbox(8)
	var mark := UI.label("✓" if got else "•", UI.FONT_CAPTION, UI.GREEN if got else UI.DIM)
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
	var l := UI.wrap("%s  -  %s" % [what, Collections.reward_text(m)], 12, UI.TEXT if got else UI.DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if got:
		h.add_child(UI.label(str(codex.coll_earned[m["id"]]), UI.FONT_CAPTION, UI.DIM))
	return h
