class_name EggQuests
extends RefCounted
## 0.13+ (Stage 3): egg quests. Every egg asks for a little care while it incubates.
## Do it before it hatches and the pet comes out stronger (a tier higher, at least
## Rare) and Cherished. Miss it and the egg hatches as usual: nothing is ever lost.

const QUESTS := {
	"hunt": {"text": "Keep it warm in battle: defeat %d monsters", "need": 20},
	"rare": {"text": "Show it something fierce: defeat %d Rare or tougher monsters", "need": 2},
	"boss": {"text": "Let it hear a giant fall: defeat %d boss", "need": 1},
	"fire": {"text": "Let it rest by a campfire %d time", "need": 1},
}

static func assign(egg: Dictionary) -> void:
	egg["quest"] = String(QUESTS.keys().pick_random())
	egg["prog"] = 0

static func _ensure(egg: Dictionary) -> void:
	if not egg.has("quest"):
		assign(egg)  # eggs from before 0.13 get a quest too

static func need(egg: Dictionary) -> int:
	return int(QUESTS[String(egg["quest"])]["need"])

static func done(egg: Dictionary) -> bool:
	return egg.has("quest") and int(egg.get("prog", 0)) >= need(egg)

static func text(egg: Dictionary) -> String:
	_ensure(egg)
	var q: Dictionary = QUESTS[String(egg["quest"])]
	var t := String(q["text"]) % need(egg)
	return ("%s (done!)" % t) if done(egg) else ("%s (%d/%d)" % [t, mini(int(egg["prog"]), need(egg)), need(egg)])

static func _step(g: GameState, kind: String) -> void:
	for egg in g.eggs:
		_ensure(egg)
		if String(egg["quest"]) == kind and not done(egg):
			egg["prog"] = int(egg["prog"]) + 1
			if done(egg):
				g.say("[color=#fde68a]Your egg stirs happily.[/color] Its quest is done: it will hatch Cherished.")
				g.events.append({"type": "toast", "text": "Egg quest done! It will hatch Cherished."})

## A monster fell (tier, and whether it was a boss).
static func on_kill(g: GameState, tier: int, boss: bool) -> void:
	if g.eggs.is_empty():
		return
	_step(g, "hunt")
	if tier >= Monsters.RARE:
		_step(g, "rare")
	if boss:
		_step(g, "boss")

static func on_rest(g: GameState) -> void:
	_step(g, "fire")
