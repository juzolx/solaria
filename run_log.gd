class_name RunLog
extends RefCounted
## 0.13+: run history. Every dive ends in the log: home safe or fallen, how deep,
## what it brought back (or who ended it). The last MAX are kept per hero.

const MAX := 20

static func add(g: GameState, outcome: String, gold: int, items: int, killer := "") -> void:
	if g.dive.is_empty():
		return
	g.runs.push_front({"t": int(Time.get_unix_time_from_system()), "out": outcome, "from": int(g.dive.get("floor", g.floor_num)),
		"to": g.floor_num, "gold": gold, "items": items, "killer": killer})
	while g.runs.size() > MAX:
		g.runs.pop_back()

## The log as lines for Codex › Stats.
static func lines(g: GameState) -> Array:
	var out: Array = []
	for r in g.runs:
		var when := Time.get_datetime_string_from_unix_time(int(r["t"])).substr(5, 11).replace("T", " ")
		if String(r["out"]) == "home":
			out.append("[color=#4ade80]Home[/color]  floors %d-%d  +%d gold, %d item%s  [color=#94a3b8]%s[/color]" % [int(r["from"]), int(r["to"]), int(r["gold"]), int(r["items"]), "" if int(r["items"]) == 1 else "s", when])
		else:
			out.append("[color=#f87171]Fell[/color]  floors %d-%d  to the %s  [color=#94a3b8]%s[/color]" % [int(r["from"]), int(r["to"]), String(r["killer"]), when])
	return out
