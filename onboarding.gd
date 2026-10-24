class_name Onboarding
extends RefCounted
## 2.1 G9: the first-time flow for a brand-new player. One short coach card at a
## time, in a fixed order: found the first town, make the first hero, the first
## dive, fight, loot, going home safely and the first fall. After that the normal
## first-time tips (GameState.tip) and guide pages take over as features open up.
##
## It lives in the profile (account-wide), never blocks anything and can be
## skipped from the welcome card, from any coach card or in Settings. A player
## who already has heroes is never shown the welcome card.
##
## Profile.onboard: {"on": bool, "seen": {step id: true}}. Empty = never asked.

const STEPS := [
	{"id": "town", "text": "Name your town. New here? Pick [b]Regular[/b]: if a hero falls, they lose what they carried, not their life."},
	{"id": "hero", "text": "Make your first hero. Pick any look you like, then a class."},
	{"id": "dive", "text": "Your hero fights on their own. [b]Tap the monster[/b] to hit it harder.", "covers": ["tap"]},
	{"id": "fight", "text": "You won a fight! Each floor has a few. Keep going down."},
	{"id": "loot", "text": "Loot! It's in your bag, but it's only safe once you get it [b]home[/b]."},
	{"id": "home", "text": "Tap [b]Town[/b] to walk home after this floor. What you bring home is safe."},
	{"id": "safe", "text": "Home safe! Your gold went to the Bank. Put on better gear in the Gear tab."},
	{"id": "death", "text": "You fell. Your bag, the gold on you and the gear you wore stay where you fell. Win there to get it back. The Bank is always safe.", "covers": ["death", "grave"]},
	{"id": "more", "text": "That's the basics! New things open as you go deeper, one tip at a time. [b]Codex > Guide[/b] explains everything."},
]

## Steps that show over menus (the title screen and the hero maker); the rest show in play.
const MENU_STEPS := ["town", "hero"]
## Guide pages that the coach cards already cover: they don't pop up while it runs.
const COVERED_PAGES := ["welcome", "death"]
const GAP_MS := 6000  # never two coach cards closer than this

static var _last_ms := -GAP_MS

static func step(id: String) -> Dictionary:
	for s in STEPS:
		if s["id"] == id:
			return s
	return {}

## True while the flow is running (asked, switched on, not finished).
static func active(p: Profile) -> bool:
	return bool(p.onboard.get("on", false)) and not finished(p)

static func asked(p: Profile) -> bool:
	return p.onboard.has("on")

static func finished(p: Profile) -> bool:
	return seen(p, String(STEPS[-1]["id"]))

static func seen(p: Profile, id: String) -> bool:
	return (p.onboard.get("seen", {}) as Dictionary).has(id)

## Turns the flow on (from the start) or off. Off is "skip": nothing more shows.
static func set_on(p: Profile, on: bool) -> void:
	p.onboard = {"on": on, "seen": {} if on else p.onboard.get("seen", {})}
	p.save()

static func mark(p: Profile, id: String) -> void:
	var s: Dictionary = p.onboard.get("seen", {})
	s[id] = true
	p.onboard["seen"] = s
	p.save()

## The welcome card shows on the title screen when the player was never asked and
## has no hero anywhere (a brand-new player, or everyone after the 2.1 fresh start).
static func should_welcome(p: Profile) -> bool:
	if asked(p):
		return false
	for t in range(1, GameData.MAX_TOWNS + 1):
		if GameState.town_heroes(t) > 0:
			return false
	return true

## A menu step's text, once (marks it seen). "" if it isn't due.
static func menu_tip(p: Profile, id: String) -> String:
	if not active(p) or seen(p, id) or not id in MENU_STEPS:
		return ""
	mark(p, id)
	return String(step(id)["text"])

## Does a step's moment in play hold right now?
static func _happened(p: Profile, g: GameState, id: String) -> bool:
	match id:
		"dive":
			return not g.in_town
		"fight":
			return g.codex.stat("kills") > 0
		"loot":
			return not g.in_town and not g.bag.is_empty()
		"home":
			return not g.in_town and g.floor_num >= 3
		"safe":
			return g.in_town and seen(p, "dive") and g.codex.stat("kills") > 0
		"death":
			return not g.hardcore and g.codex.stat("deaths") > 0
		"more":
			return seen(p, "safe") and g.level >= 5
	return false

## Before a hero starts: the existing first-time tips the coach replaces are
## marked seen, so the same thing isn't said twice.
static func on_start(p: Profile, g: GameState) -> void:
	if not active(p):
		return
	for s in STEPS:
		for key in s.get("covers", []):
			g.tips_seen[key] = true
	# A brand-new hero already queued the tap tip (GameState.new_game): the dive card says it
	for i in range(g.events.size() - 1, -1, -1):
		if g.events[i].get("type", "") == "tip":
			g.events.remove_at(i)

## Called often while playing. Returns the next coach text (and marks it seen), or
## "". Strict order: the earliest step not yet seen whose moment has happened; one
## at a time, at least GAP_MS apart. now_ms < 0 uses the clock.
static func pump(p: Profile, g: GameState, now_ms := -1) -> String:
	if not active(p) or g == null:
		return ""
	var now := Time.get_ticks_msec() if now_ms < 0 else now_ms
	if now - _last_ms < GAP_MS:
		return ""
	for s in STEPS:
		var id := String(s["id"])
		if id in MENU_STEPS or seen(p, id):
			continue
		if _happened(p, g, id):
			mark(p, id)
			_last_ms = now
			return String(s["text"])
	return ""

## A guide page that shouldn't pop up right now (the coach covers it).
static func holds_page(p: Profile, page_id: String) -> bool:
	return active(p) and page_id in COVERED_PAGES

# ---------- UI ----------

## The welcome card: start the flow or skip it. Never blocks: one tap either way.
static func show_welcome(m, on_done := Callable()) -> Overlay:
	var o := Overlay.new().open(m, "Welcome to Solaria", 460.0, UI.GOLD, false)
	o.content.add_child(UI.wrap("Lead heroes down into a deep dungeon, bring the loot home, and grow your town.", 17, UI.TEXT))
	o.content.add_child(UI.wrap("Want a few short tips as you go?", 15, UI.DIM))
	var yes := UI.primary("Yes, show me the way", func():
		set_on(m.profile, true)
		o.close()
		if on_done.is_valid():
			on_done.call(), UI.GOLD)
	var no := UI.button("No tips, I've played before", func():
		set_on(m.profile, false)
		o.close()
		if on_done.is_valid():
			on_done.call())
	for b in [yes, no]:
		b.custom_minimum_size = Vector2(0, UI.TAP + 8)
		b.add_theme_font_size_override("font_size", 17)
		o.content.add_child(b)
	return o

## One coach card near the bottom (above the tab bar on phones). Big text, a
## "Got it" and a quiet "Skip tips". It fades by itself and never blocks the game.
static func coach(m, text: String) -> PanelContainer:
	if text == "":
		return null
	for n in m.get_tree().get_nodes_in_group("coach"):
		n.queue_free()
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var p := UI.panel(Color(0.05, 0.06, 0.11, 0.96), UI.GOLD, 10, 14, 2)
	p.add_to_group("coach")
	p.z_index = 90  # above popups like the hero maker
	p.add_to_group("toast")  # a popup opened later clears it (Overlay.open clears toasts)
	var v := UI.vbox(10)
	p.add_child(v)
	var r := UI.rich(17)
	r.text = text
	r.custom_minimum_size = Vector2(minf(440.0, vp.x - 32.0) - 28.0, 0)
	v.add_child(r)
	var row := UI.hbox(8)
	v.add_child(row)
	var skip := UI.button("Skip tips", func():
		set_on(m.profile, false)
		p.queue_free())
	skip.add_theme_color_override("font_color", UI.DIM)
	skip.custom_minimum_size = Vector2(0, UI.TAP)
	row.add_child(skip)
	var ok := UI.primary("Got it", p.queue_free, UI.GOLD)
	ok.custom_minimum_size = Vector2(0, UI.TAP)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	m.add_child(p)
	p.reset_size()
	p.position = Vector2((vp.x - p.size.x) / 2.0, vp.y - p.size.y - (110.0 if vp.y > vp.x else 24.0))
	var tw := p.create_tween()
	tw.tween_interval(5.0 + text.length() / 25.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)
	return p
