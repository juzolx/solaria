class_name Portals
extends RefCounted
## 2.1 (F3): one portal system. Every place that takes you out of the normal run
## of floors is a portal, and they all follow the same rules (claude/portals.md):
##
##   rift   a shimmer behind a door (from floor 10). One rift type with a depth:
##          depth 1 is 3 fights, depth 3 is 3 pocket floors of 3 fights. Then a vault.
##   realm  the five realm gates on floors 251-500: after each ruler, choose a realm.
##   trial  a single fight against a named champion (race awakening, a cure, a
##          champion hidden class), started from that page.
##
## One place where portals are chosen: the portal card panel (main._show_path_choice,
## fed by offer() through GameState.path_offer with "portal:<key>" choices).
## One state: GameState.portal ({"kind": "rift", ...}) for a rift; a trial keeps
## its own trial_* fields (used across the fight code) and is read through inside().
## A realm is not a place you stay "inside": it is the floors themselves.

const COLOR := "#c4b5fd"   # every portal card, banner and line uses this violet
const LEAVE := "portal:leave"

## The rules, one row per kind (shown in Codex > Guide > Portals and claude/portals.md).
const KINDS := {
	"rift": {"name": "Rift", "found": "Behind about 1 door in 70, from floor 10 (never before a boss)",
		"cost": "Free", "run": false, "home": "Return Scroll only (the rift closes, no vault)",
		"death": "A normal fall: grave, checkpoint; the rift closes", "floors": "Floors don't move inside",
		"reward": "A vault: gear, gold and dust (depth 3: bigger, one Legendary for sure)"},
	"realm": {"name": "Realm gate", "found": "Floors 251-500: after each ruler, the gates to the realms you haven't entered",
		"cost": "Free", "run": true, "home": "As usual (between floors, or a Return Scroll)",
		"death": "A normal fall", "floors": "The realm is the next 50 floors",
		"reward": "The realm itself: its people, mechanic, camp, set and uniques"},
	"trial": {"name": "Trial", "found": "A champion's gate behind about 1 door in 70 while a trial waits for you (awakening, a cure you started, a champion's hidden class), or its page; in the dungeon",
		"cost": "Free", "run": false, "home": "Return Scroll only (try the trial again later)",
		"death": "No losses: you are back where you started it (Hardcore: final)", "floors": "You come back to the floor you left",
		"reward": "What the trial was for, plus gold"},
}

# =====================================================================
# Where you are
# =====================================================================

## True while a portal holds you (inside a rift, or fighting a trial).
static func inside(g: GameState) -> bool:
	return not g.portal.is_empty() or g.trial_active

static func kind(g: GameState) -> String:
	if g.trial_active:
		return "trial"
	if not g.portal.is_empty():
		return "rift"
	return ""

## The one line for "you can't leave right now" ("" when no portal holds you).
static func hold_text(g: GameState) -> String:
	match kind(g):
		"rift":
			return "The rift holds you: finish it, or read a Return Scroll."
		"trial":
			return "The trial holds you: win it, or read a Return Scroll."
	return ""

## The Run button's reason inside a portal.
static func no_run_text(g: GameState) -> String:
	return "No running in a %s" % String(KINDS[kind(g)]["name"]).to_lower() if inside(g) else ""

## Why a rift or trial can't open right now ("" = it can). One portal at a time.
static func open_block(g: GameState) -> String:
	if g.run_over:
		return "This hero's run is over."
	if g.in_town:
		return "Trials and rifts open only in the dungeon. Head down first."
	if inside(g):
		return "Finish the portal you're in first."
	if g.enemy_is_boss and g.enemy_hp > 0:  # a slain boss leaves the flag set until the next fight spawns
		return "Not in the middle of a boss fight."
	return ""

# =====================================================================
# The one place portals are chosen
# =====================================================================

## Shows the portal cards (keys like "realm id", "rift", "leave"). The player picks
## one (Auto picks the first after a few turns, like every path choice).
static func offer(g: GameState, keys: Array, line: String) -> void:
	g.path_offer.assign(keys.map(func(k): return "portal:" + String(k)))
	g.path_wait = 0
	g.path_hold = false
	g.events.append({"type": "portals"})
	g.say("[color=%s]%s[/color]" % [COLOR, line])
	g._page("portals")

## The panel title over the cards.
static func title(g: GameState) -> String:
	if "portal:rift" in g.path_offer:
		return "A rift (depth %d)" % rift_depth_here(g)
	if "portal:trial" in g.path_offer:
		return "A champion's gate"
	return "Choose a realm"

## Name, text and color of one card (the same shape for every kind).
static func card(g: GameState, key: String) -> Dictionary:
	var k := key.trim_prefix("portal:")
	if k == "leave":
		return {"name": "Walk on", "text": "Leave it be. It closes behind you: no risk, no reward.", "color": "#cbd5e1"}
	if k == "rift":
		var d := rift_depth_here(g)
		var what := "%d fights, then a vault." % Rifts.FIGHTS if d <= 1 else "%d floors x %d fights, then a great vault." % [d, Rifts.FIGHTS]
		return {"name": "Rift, depth %d" % d, "text": "%s\n%s" % [what, danger_text(g, Monsters.LEGENDARY)], "color": COLOR}
	if k == "trial":
		var t := gate_trial(g)
		return {"name": "Trial: %s" % String(t.get("name", "a champion")), "text": "%s\n%s" % [String(t.get("goal", "")),
			"Lose: your run ends." if g.hardcore else "Lose: no losses."], "color": COLOR}
	var inf := Realms.info(k)
	var lv := Races.rep_level(Lineage.rep(g, inf["race"]))
	return {"name": inf["name"], "text": "%s. The %s: %s.\n%s" % [inf["mechanic"]["name"], Lineage.race_plural(inf["race"]), lv[0], danger_text(g)], "color": inf["color"]}

## A card was picked (GameState._apply_path sends every "portal:" choice here).
static func choose(g: GameState, key: String) -> void:
	var k := key.trim_prefix("portal:")
	match k:
		"leave":
			var p := _portal_prop(g)
			if not p.is_empty():
				p["used"] = true
			g.say("You leave the %s be. It folds shut without a sound." % ("gate" if String(p.get("kind", "")) == "gate" else "rift"))
			Halls._done(g)
		"trial":
			var p := _portal_prop(g)
			var t := gate_trial(g)
			if start_trial(g, t):
				if not p.is_empty():
					p["used"] = true  # only spent once the trial really starts
			else:
				Halls._done(g)  # nothing to fight after all: on to the doors
		"rift":
			var p := _rift_prop(g)
			var d := rift_depth_here(g)
			if not p.is_empty():
				p["used"] = true
			Rifts.enter(g, d)
		_:
			Realms.enter(g, k)
	g.events.append({"type": "portal"})

## How dangerous the other side is: one hit compared to your health.
## tier: the toughest monster you'll meet there (0 = an ordinary one).
static func danger_text(g: GameState, tier := 0) -> String:
	var f := g.floor_num
	var atk := float(3 + f * 2) * GameData.enemy_attack_growth(f) * float(Monsters.TIERS[clampi(tier, 0, 5)]["atk"])
	var hit := atk * atk / (atk + g.get_defense())
	var pct := hit / maxf(1.0, g.get_max_hp()) * 100.0
	if pct < 4.0:
		return "Danger: low"
	if pct < 10.0:
		return "Danger: fair (hits ~%d%% of your HP)" % int(pct)
	if pct < 25.0:
		return "Danger: high (hits ~%d%% of your HP)" % int(pct)
	if pct < 100.0:
		return "Danger: deadly (hits ~%d%% of your HP)" % int(pct)
	return "Danger: deadly (one hit can kill you)"

# =====================================================================
# Rifts in rooms
# =====================================================================

static func _rift_prop(g: GameState) -> Dictionary:
	for p in g.room_props:
		if String(p.get("kind", "")) == "rift":
			return p
	return {}

## The rift or champion's gate standing in this room ({} = none).
static func _portal_prop(g: GameState) -> Dictionary:
	for p in g.room_props:
		if String(p.get("kind", "")) in ["rift", "gate"]:
			return p
	return {}

# =====================================================================
# Portal doors: "three doors, your choice" (Juzo, Oct 23)
# =====================================================================

const DOOR_KINDS := ["rift", "trial"]
const TRIAL_DOOR_CHANCE := 1.5   # % per door while a trial is waiting for you (same as a rift)
const TRIAL_FROM := 3

## Maybe turns a rolled door into a portal door: a rift, or a champion's gate when a
## trial is waiting for you. At most one portal door in a set of three.
static func maybe_door(g: GameState, kind: String, so_far: Array) -> String:
	if so_far.any(func(k): return String(k) in DOOR_KINDS):
		return kind
	var out := Rifts.maybe_door(g, kind)
	if out != "rift" and g.floor_num >= TRIAL_FROM and not GameData.is_boss_floor(g.floor_num + 1) and not inside(g) \
			and randf() * 100.0 < TRIAL_DOOR_CHANCE and not trial_offer(g).is_empty():
		out = "trial"
	return out

## A portal door is never blank: everyone sees the glow and knows what it is.
static func read_door(g: GameState, kind: String) -> Dictionary:
	if kind == "rift":
		return {"color": COLOR, "label": "Rift", "text": "Violet light leaks around this door: a rift."}
	var t := trial_offer(g)
	return {"color": COLOR, "label": "Trial", "text": "A champion waits behind this door: %s." % String(t.get("name", "a trial"))}

## The trial waiting for you right now ({} = none): your next awakening, the cure you
## set out to find, or a champion's hidden class on offer. Same order as their pages.
static func trial_offer(g: GameState) -> Dictionary:
	if g.run_over:
		return {}
	if Lineage.awaken_block(g) == "trial":
		var nr := Lineage.next_rank(g)
		return {"kind": "race", "id": String(nr["name"]), "name": String(nr["key"]["trial"]["name"]), "goal": "Win: awaken as %s." % String(nr["name"])}
	if Lineage.cure_block(g) == "" and Lineage.cure_info(g).has("trial"):
		return {"kind": "cure", "id": g.form, "name": String(Lineage.cure_info(g)["trial"]["name"]), "goal": "Win: the cure."}
	if g.hidden_class == "":
		for id in g.hidden_offer:
			var c := Hidden.info(String(id))
			if c.has("trial") and not g.feats.get("trial_" + String(id), 0):
				return {"kind": "hidden", "id": String(id), "name": String(c["trial"]["name"]), "goal": "Win: become %s, for good." % String(c["name"])}
	return {}

## The trial behind this room's gate (fixed when you walked in).
static func gate_trial(g: GameState) -> Dictionary:
	return _portal_prop(g).get("trial", {})

## Starts a trial the same way its page does. Returns false if it can't start.
static func start_trial(g: GameState, t: Dictionary) -> bool:
	var ok := false
	match String(t.get("kind", "")):
		"race":
			ok = g.start_race_trial()
		"cure":
			ok = Lineage.finish_cure(g)
		"hidden":
			ok = Hidden.take(g, String(t.get("id", "")))
	if ok and g.trial_active:
		g.trial_data["gate"] = true  # you came through a door: you go back out to your doors
	return ok

## Tapping the champion's gate in a room: its card, or walk on.
static func offer_trial(g: GameState) -> void:
	g.exploring = false
	g.explore_wait = 0
	offer(g, ["trial", "leave"], "%s waits beyond the gate. Face the trial, or walk on?" % String(gate_trial(g).get("name", "A champion")))

# =====================================================================
# Auto and portals
# =====================================================================

## Would Auto go in? Rifts: when you're at half health or better. Trials: only your
## awakening or a cure you started, never as Hardcore, never a class (that's for good).
static func auto_wants(g: GameState, kind: String, t := {}) -> bool:
	var hp := float(g.hero_hp) / maxf(1.0, g.get_max_hp())
	match kind:
		"rift":
			return hp >= 0.5
		"trial":
			if t.is_empty():
				t = trial_offer(g)
			return not g.hardcore and hp >= 0.75 and String(t.get("kind", "")) in ["race", "cure"]
	return true

## Auto's pick among portal cards (GameState.auto_path).
static func auto_pick(g: GameState) -> String:
	if "portal:rift" in g.path_offer:
		return "portal:rift" if auto_wants(g, "rift") else LEAVE
	if "portal:trial" in g.path_offer:
		return "portal:trial" if auto_wants(g, "trial", gate_trial(g)) else LEAVE
	return String(g.path_offer[0])

## Auto at the doors: a door score for a portal door (others score about 0.5-3).
static func auto_door_score(g: GameState, kind: String) -> float:
	return 1.6 if auto_wants(g, kind) else -1.5

## The depth of the rift in this room (rolled when you walk in, shown on its card).
static func rift_depth_here(g: GameState) -> int:
	return clampi(int(_rift_prop(g).get("depth", 1)), 1, Rifts.MAX_DEPTH)

## Tapping the rift in a room: its card, or walk on.
static func offer_rift(g: GameState) -> void:
	g.exploring = false
	g.explore_wait = 0
	offer(g, ["rift", "leave"], "A rift hangs in the air, depth %d. Step through, or walk on?" % rift_depth_here(g))

# =====================================================================
# Leaving: the end, a fall, a Return Scroll
# =====================================================================

## Leave the portal you're in. cleared: you reached its end (the vault, a won trial).
static func leave(g: GameState, cleared: bool) -> void:
	if g.portal.is_empty():
		return
	g.portal = {}
	if not cleared:
		g.say("[color=%s]The rift closes behind you.[/color]" % COLOR)

## You fell (GameState._hero_died, after a Calamity knockout and a team's last stand).
## A rift closes; the normal fall follows (grave, checkpoint; Hardcore: final).
static func on_fall(g: GameState) -> void:
	leave(g, false)
	if g.trial_active and g.hardcore:  # the run ends here: the trial ends with it
		_end_trial(g)

## A lost trial costs nothing: you are back where you started it, at full health.
## (The caller checks Hardcore first: a Hardcore fall is final everywhere.)
static func lose_trial(g: GameState) -> void:
	g.say("[color=#f87171]%s was too strong. Train harder and try the trial again.[/color]" % g.enemy_name)
	var gate := bool(g.trial_data.get("gate", false))
	_end_trial(g)
	g.hero_hp = g.get_max_hp()
	g.spawn_enemy()
	if gate:
		g._room_cleared()  # came through a door: back out to your doors
	g.save_game()

static func _end_trial(g: GameState) -> void:
	g.trial_active = false
	g.trial_kind = "god"
	g.trial_data = {}
	g.floor_num = g.trial_return
	g.fight = 1

## A Return Scroll pulls you out of any portal first (no reward; a trial can be tried again).
static func leave_for_scroll(g: GameState) -> void:
	if g.trial_active:
		g.say("[color=%s]The trial fades around you.[/color] You can face it again later." % COLOR)
		_end_trial(g)
		g.spawn_enemy()  # the champion is gone (clears its boss flags)
	leave(g, false)

## What the Return Scroll prompt adds inside a portal.
static func scroll_note(g: GameState) -> String:
	match kind(g):
		"rift":
			return " The rift closes behind you: no vault."
		"trial":
			return " The trial ends; you can face it again later."
	return ""

# =====================================================================
# Coming back: after loading a save, or going down from town
# =====================================================================

## Puts back what a portal had on screen: the rift's fight, an untouched rift's card,
## or a realm choice you never made (so the realm can't be decided for you).
static func resume(g: GameState) -> void:
	if g.in_town or g.run_over:
		return
	if not g.portal.is_empty():
		Rifts.resume(g)
		return
	var p := _portal_prop(g)
	if g.room_kind in DOOR_KINDS and not p.is_empty() and not p.get("used", false) and g.doors.is_empty() and g.path_offer.is_empty():
		if String(p["kind"]) == "gate":
			offer_trial(g)
		else:
			offer_rift(g)
		return
	if Realms.is_realm_start(g.floor_num) and GameData.realm_slot(g.floor_num) >= g.realm_order.size() and g.path_offer.is_empty():
		Realms.offer_portals(g)
