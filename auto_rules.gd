class_name AutoRules
extends RefCounted
## 0.13+ (Stage 3): Auto rules you set. Autoplay pauses (and tells you why) when one
## of your rules fires, so you can step in at the moments that matter.
## 2.1: shown in the one Auto-dive panel (auto_dive_panel.gd) with AutoDive.

const RULES := {
	"stop_boss": "Before a boss fight",
	"stop_full": "When your bag is full",
	"stop_low": "When HP is low and you're out of potions",
	"stop_rare": "For an Epic or tougher monster, or a wanderer",
}

static func on(g: GameState, id: String) -> bool:
	return bool(g.auto_rules.get(id, false))

static func toggle(g: GameState, id: String) -> void:
	g.auto_rules[id] = not on(g, id)

## Why Auto should pause right now ("" = keep going). Each reason fires once per thing.
static func check(g: GameState) -> String:
	AutoDive.tick(g)  # 2.1: auto-dive settings (head home, elixirs before bosses; re-arms in town)
	if not g.autoplay or g.in_town:
		return ""
	var floor_stop := AutoDive.pause_reason(g)
	if floor_stop != "":
		return floor_stop
	var why := ""
	var key := ""
	if on(g, "stop_boss") and g.enemy_is_boss and g.enemy_hp > 0:
		why = "a boss stands ahead: %s" % g.enemy_name
		key = "boss|%d|%s" % [g.floor_num, g.enemy_name]
	elif on(g, "stop_rare") and g.enemy_hp > 0 and (g.enemy_tier >= Monsters.EPIC or g.enemy_wanderer):
		why = "%s" % g.enemy_name
		key = "rare|%d|%s|%d" % [g.floor_num, g.enemy_name, g.enemy_max_hp]
	elif on(g, "stop_full") and g.bag_full():
		why = "your bag is full"
		key = "full|%d" % g.bag.size()
	elif on(g, "stop_low") and g.potions <= 0 and g.hero_hp < g.get_max_hp() * 0.3:
		why = "HP is low and you have no potions"
		key = "low|%d|%d" % [g.floor_num, g.fight]
	if why == "" or key == g.auto_rule_seen:
		return ""
	g.auto_rule_seen = key
	return why
