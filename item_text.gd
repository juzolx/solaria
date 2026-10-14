class_name ItemText
extends RefCounted
## How items are described everywhere (bag, gear, shop, craft), so it's consistent.

static func line(item: Dictionary) -> String:
	var lock := "  (locked)" if item.get("locked", false) else ""
	return "%s   -   %s   +%d %s%s" % [GameData.display_name(item), item["slot"], GameData.item_power(item), item["stat"], lock]

## Raw stat difference against what you wear in that slot: "(+6)", "(-3)" or "(same)".
static func delta(state: GameState, item: Dictionary) -> String:
	var slot: String = item["slot"]
	var cur := 0
	if state.equipped.has(slot):
		cur = GameData.item_power(state.equipped[slot])
	var diff := GameData.item_power(item) - cur
	if diff > 0:
		return "(+%d)" % diff
	if diff < 0:
		return "(%d)" % diff
	return "(same)"

## Name, rarity, slot, stat, special effect and set.
static func describe(state: GameState, item: Dictionary) -> String:
	var r := int(item["rarity"])
	var dim := UI.hex(UI.DIM)
	var text := "[color=%s][b]%s[/b][/color]  [color=%s](%s %s, floor %d)[/color]\n+%d %s" % [
		GameData.color_of(r), GameData.display_name(item), dim, GameData.RARITY_NAMES[r], item["slot"], int(item["floor"]),
		GameData.item_power(item), item["stat"]]
	if item.get("locked", false):
		text += "  [color=#e8b14a](locked)[/color]"
	match String(item.get("bound", "")):
		"soul":
			text += "\n[color=#e43b44]Soulbound:[/color] [color=%s]never lost when you fall. Can't be sold or salvaged; any of your heroes can wear it.[/color]" % dim
		"account":
			text += "\n[color=#ffffff]Account-bound[/color][color=%s] to %s: never lost when you fall, and it stays with that hero. It holds a seat in the Hall of Fame.[/color]" % [dim, String(item.get("registered", "its hero"))]
	var hist: Array = item.get("history", [])
	if not hist.is_empty():
		var lines: Array = []
		for h in hist.slice(-4):
			lines.append("%s %s (%s)" % [h.get("who", "?"), h.get("what", "held it"), h.get("date", "")])
		text += "\n[color=%s]History: %s[/color]" % [dim, "; ".join(lines)]
	if item["effect"] != "":
		text += "\n[color=#fbbf24]Special: %s[/color]" % GameData.effect_text(item["effect"], int(item["effect_value"]))
	if String(item.get("effect2", "")) != "":
		text += "\n[color=#fde047]Awakened: %s[/color]" % GameData.effect_text(item["effect2"], int(item["effect2_value"]))
	if GameData.is_living(item):
		var sl := GameData.soul_level(item)
		if sl < GameData.SOUL_MAX:
			text += "\n[color=%s]Soul %d/%d: %d / %d kills while worn to the next level (+%d%% power each; level %d awakens a hidden effect).[/color]" % [
				dim, sl, GameData.SOUL_MAX, int(item.get("soul", 0)), int(GameData.SOUL_KILLS[sl]), int(GameData.SOUL_POWER * 100), GameData.SOUL_MAX]
	var set_name: String = item.get("set", "")
	if set_name != "":
		text += "\n[color=#2dd4bf]Set: %s (wearing %d/3) - %s[/color]" % [set_name, int(state.set_counts().get(set_name, 0)), GameData.set_info(set_name).get("text", "")]
	var flavor: String = item.get("flavor", "")
	if flavor != "":
		text += "\n[color=%s][i]%s[/i][/color]" % [dim, flavor]
	return text

## How your stats change if you wear it, and whether your build gets stronger overall.
static func compare(state: GameState, item: Dictionary) -> String:
	var slot: String = item["slot"]
	var current_name := "nothing"
	if state.equipped.has(slot):
		current_name = GameData.display_name(state.equipped[slot])
	var total := state.stat_value(item["stat"])
	var new_total := state.stat_if_equipped(item)
	var diff := new_total - total
	var c := UI.hex(UI.GREEN) if diff >= 0 else UI.hex(UI.RED)
	var plus := "+" if diff >= 0 else ""
	var overall := state.score_with(item) / maxf(1.0, state.build_score()) - 1.0
	var verdict := ""
	if overall > 0.001:
		verdict = "  [color=%s]Overall: stronger (+%d%%)[/color]" % [UI.hex(UI.GREEN), int(round(overall * 100))]
	elif overall < -0.001:
		verdict = "  [color=%s]Overall: weaker (%d%%)[/color]" % [UI.hex(UI.RED), int(round(overall * 100))]
	return "Wearing it (instead of %s): %s %d -> [color=%s]%d (%s%d)[/color]%s" % [
		current_name, item["stat"], total, c, new_total, plus, diff, verdict]

## Plain-text summary for tooltips (no color codes).
static func plain(item: Dictionary) -> String:
	var r := int(item["rarity"])
	var text := "%s (%s %s)\n+%d %s" % [GameData.display_name(item), GameData.RARITY_NAMES[r], item["slot"], GameData.item_power(item), item["stat"]]
	if item["effect"] != "":
		text += "\nSpecial: " + GameData.effect_text(item["effect"], int(item["effect_value"]))
	if item.get("set", "") != "":
		text += "\nSet: %s - %s" % [item["set"], GameData.set_info(item["set"]).get("text", "")]
	if item.get("flavor", "") != "":
		text += "\n" + str(item["flavor"])
	return text

## Tooltip text: the item plus how it compares to what you're wearing (for hovering).
static func tip(state: GameState, item: Dictionary) -> String:
	var text := plain(item)
	var slot: String = item["slot"]
	var worn: Dictionary = state.equipped.get(slot, {})
	if not worn.is_empty() and int(worn["id"]) == int(item["id"]):
		return text + "\n\n(You're wearing this.)"
	var total := state.stat_value(item["stat"])
	var new_total := state.stat_if_equipped(item)
	var diff := new_total - total
	text += "\n\nVs. %s: %s %d -> %d (%s%d)" % [GameData.display_name(worn) if not worn.is_empty() else "nothing", item["stat"], total, new_total, "+" if diff >= 0 else "", diff]
	var overall := state.score_with(item) / maxf(1.0, state.build_score()) - 1.0
	if overall > 0.001:
		text += "\nOverall: stronger (+%d%%)" % int(round(overall * 100))
	elif overall < -0.001:
		text += "\nOverall: weaker (%d%%)" % int(round(overall * 100))
	if not worn.is_empty() and worn["effect"] != "":
		text += "\nYou'd lose: " + GameData.effect_text(worn["effect"], int(worn["effect_value"]))
	return text + "\n(Double-tap for details)"

## True for items worth a "are you sure?" before selling or scrapping.
static func is_precious(item: Dictionary) -> bool:
	return int(item["rarity"]) >= GameData.LEGENDARY
