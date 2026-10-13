class_name StatsTab
extends ScrollContainer
## Codex > Stats: lifetime numbers for all your heroes together.
## Per-monster numbers are in the Bestiary.

var main
var codex: Codex
var text: RichTextLabel

func setup(m) -> void:
	main = m
	codex = m.codex
	name = "Stats"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text = UI.rich(13)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(text)

func _n(v: int) -> String:
	var s := str(v)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func refresh() -> void:
	var c := codex
	var g := UI.hex(UI.GOLD)
	var lines: Array = []
	var row := func(label: String, v: int) -> String: return "%s  [color=%s]%s[/color]" % [label, g, _n(v)]
	lines.append("[font_size=16][color=#e8b14a]Combat[/color][/font_size]")
	for e in [["Monsters defeated", c.stat("kills")], ["Bosses defeated", c.stat("boss_kills")], ["Deaths", c.stat("deaths")],
			["Turns fought", c.stat("turns")], ["Damage dealt", c.stat("damage")], ["Biggest hit", c.stat("best_hit")], ["Taps", c.stat("taps")],
			["Potions drunk", c.stat("potions_used")]]:
		lines.append(row.call(e[0], e[1]))
	var tiers: Array = []
	for t in range(1, 6):
		tiers.append("[color=%s]%s %s[/color]" % [Monsters.tier_color(t), Monsters.tier_name(t), _n(c.stat("tier_%d" % t))])
	lines.append("Rare monsters:  " + "   ".join(tiers))
	lines.append("")
	lines.append("[font_size=16][color=#e8b14a]Loot[/color][/font_size]")
	lines.append(row.call("Items found", c.stat("items")))
	var by: Array = []
	for r in [0, 1, 2, 3, 4, 5, 7]:
		by.append("[color=%s]%s %s[/color]" % [GameData.color_of(r), GameData.RARITY_NAMES[r], _n(c.stat("items_r%d" % r))])
	lines.append("   ".join(by))
	lines.append(row.call("Gold earned", c.stat("gold_earned")))
	lines.append(row.call("Set items crafted", c.stat("sets_crafted")))
	lines.append(row.call("Rerolls won", c.stat("rerolls_won")))
	lines.append("")
	lines.append("[font_size=16][color=#e8b14a]Dungeon events[/color][/font_size]")
	for e in [["Treasure goblins caught", c.stat("goblins")], ["Hordes beaten", c.stat("hordes")], ["Shrine curses taken", c.stat("shrines")],
			["Bought from the merchant", c.stat("merchant_buys")], ["Bounties finished", c.stat("bounties")]]:
		lines.append(row.call(e[0], e[1]))
	lines.append("")
	lines.append("[font_size=16][color=#e8b14a]Records[/color][/font_size]")
	for e in [["Deepest floor", c.stat("best_floor")], ["Highest level", c.stat("best_level")], ["Deepest Hardcore floor", c.stat("hc_floor")],
			["Longest login streak", c.value("streak_best")], ["Monsters met", c.value("seen")], ["Achievements", c.achievements.size()]]:
		lines.append(row.call(e[0], e[1]))
	text.text = "\n".join(lines)
