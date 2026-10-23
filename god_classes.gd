class_name GodClasses
extends RefCounted
## God classes (Juzo, Oct 20): the rank above the highest. They are unique classes,
## never on the main route: each one has its own very particular set of secret
## deeds, and the moment a hero completes them the God class answers and the hero
## can choose to swap into it, right then (not tied to a level). The deeds build
## up over time. Most only answer a hero who stayed on the main route of their
## class; a few also answer a hero who took a unique (hidden) class.
## Their class nodes join the class tree (ClassTree._build) with rank "God".

const POWER := 2.4   # Attack, HP and Defense, on top of the class's own focus (a hidden class tops out at about x2.1)

## id (permanent, also its class node id) -> the class (name, base class, the level-35
## class node id it grows from, side, focus,
## tags, role text; optional role / util / extra like a tree final), its reveal art
## and lore, whether it needs the main route, and its secret deeds [label, key, amount]
## (keys as Hidden._have understands them).
const LIST := {
	"god_titan": {"name": "Titan", "cls": "Warrior", "from": "weaponmaster", "side": "N", "focus": "atk:.5 hp:.5", "tags": "",
		"role_text": "Raw strength and endless health", "art": "boss_typhon", "main_route": true,
		"lore": "The first giant lifted the sky so the world could breathe. Now you carry it.",
		"deeds": [["A Warrior", "class:Warrior", 1], ["Walked the Weaponmaster's road", "path:weaponmaster", 1], ["Reach level 75", "level", 75],
			["25,000 monsters slain", "kills_total", 25000], ["Beat 20 champions", "codex:champions", 20], ["2,000 fights in a row, clean", "clean_best", 2000]]},
	"god_sky_dragoon": {"name": "Sky Dragoon", "cls": "Knight", "from": "dragoon", "side": "N", "focus": "atk:.5 crit:.5", "tags": "",
		"role_text": "Diving strikes that ignore defense", "art": "boss_fafnir", "main_route": true,
		"lore": "The dragon's hoard was never gold. It was the sky, and now it answers to you.",
		"deeds": [["A Knight", "class:Knight", 1], ["Walked the Dragoon's road", "path:dragoon", 1], ["Reach level 75", "level", 75],
			["Reach floor 500", "floor", 500], ["Clear 15 Deep Rifts", "codex:deep_rifts", 15], ["Finish 150 Legendary or Mythic monsters with a skill", "skill_kills_elite", 150]]},
	"god_sword_god": {"name": "Sword God", "cls": "Wanderer", "from": "sword_saint", "side": "N", "focus": "atk:.4 crit:.3 double_strike:.3", "tags": "Blade",
		"role_text": "The peak of the blade", "art": "boss_sword_spirit", "main_route": true,
		"lore": "The first sword ever forged finally found a worthy hand.",
		"deeds": [["A Wanderer", "class:Wanderer", 1], ["Walked the Sword Saint's road", "path:sword_saint", 1], ["Reach level 75", "level", 75],
			["3,000 fights in a row, clean", "clean_best", 3000], ["20,000 monsters finished with a skill", "skill_kills", 20000], ["Beat 30 champions", "codex:champions", 30]]},
	"god_heavenly_demon": {"name": "Heavenly Demon", "cls": "Wanderer", "from": "demon_saint", "side": "N", "focus": "atk:.4 lifesteal:.3 hp:.3", "tags": "Fist Blood Shadow",
		"role_text": "Ruler of the demonic path", "art": "boss_demon_ancestor", "main_route": true,
		"lore": "The demon cult's ancestor is dead. Someone has to sit on his throne.",
		"deeds": [["A Wanderer", "class:Wanderer", 1], ["Walked the Demon Saint's road", "path:demon_saint", 1], ["Reach level 75", "level", 75],
			["Evil faith of 90 or more", "evil", 90], ["30,000 monsters slain", "kills_total", 30000], ["Recover 20 graves", "codex:graves", 20]]},
	"god_archdruid": {"name": "Archdruid", "cls": "Cleric", "from": "grove_keeper", "side": "N", "focus": "regen:.5 skill:.5", "tags": "Nature",
		"role_text": "Potions and gear no one else can make", "art": "boss_withered_queen", "main_route": true,
		"role": "crafting", "util": "potion:.4 scrap:.3 stone_find:.3",
		"lore": "You healed the forest's sick heart. It grows through you now.",
		"deeds": [["A Cleric", "class:Cleric", 1], ["Walked the Grove Keeper's road", "path:grove_keeper", 1], ["Reach level 75", "level", 75],
			["400 ability stones found", "codex:stones", 400], ["Forge 20 set pieces", "codex:sets_crafted", 20], ["Own 10 pets", "codex:pets", 10]]},
	"god_saint_militant": {"name": "Saint Militant", "cls": "Acolyte", "from": "templar", "side": "G", "focus": "atk:.4 regen:.3 def:.3", "tags": "Holy",
		"role_text": "Holy damage and healing in battle", "art": "boss_seraphiel", "main_route": true,
		"lore": "The highest angel asked one question, with a sword. You answered.",
		"deeds": [["An Acolyte", "class:Acolyte", 1], ["Walked the Templar's road", "path:templar", 1], ["Reach level 75", "level", 75],
			["Good faith of 95 or more", "good", 95], ["Help 20 pilgrims", "codex:pilgrims_helped", 20], ["Spare 300 monsters", "codex:spared", 300]]},
	"god_chronomancer": {"name": "Chronomancer", "cls": "Mage", "from": "lightbinder", "side": "N", "focus": "skill:.5 double_strike:.5", "tags": "Arcane",
		"role_text": "Extra turns and slowed enemies", "art": "boss_archon_valeth", "main_route": true, "extra": {"cdr": 1},
		"lore": "The Keeper of Hours gave you one second. You made it last forever.",
		"deeds": [["A Mage", "class:Mage", 1], ["Walked the Lightbinder's road", "path:lightbinder", 1], ["Reach level 75", "level", 75],
			["25,000 monsters finished with a skill", "skill_kills", 25000], ["Clear 25 Deep Rifts", "codex:deep_rifts", 25], ["Sell 30 skills", "codex:skills_sold", 30]]},
	"god_phantom": {"name": "Phantom", "cls": "Trickster", "from": "", "side": "N", "focus": "dodge:.5 crit:.5", "tags": "Shadow Trick",
		"role_text": "Can't be pinned down; strikes from the shadows", "art": "boss_weeping_warden", "main_route": false,
		"lore": "The Warden sees everything. It has stopped seeing you.",
		"deeds": [["A Trickster", "class:Trickster", 1], ["Reach level 75", "level", 75], ["Walk away from 500 sure fights", "sure_escapes", 500],
			["Spot 200 traps", "codex:traps_spotted", 200], ["1,500 fights in a row, clean", "clean_best", 1500]]},
	"god_hawkeye": {"name": "Hawkeye", "cls": "Ranger", "from": "", "side": "N", "focus": "crit:.5 atk:.5", "tags": "Storm",
		"role_text": "Sees floors and bosses ahead, finds every secret, almost always escapes", "art": "boss_dullahan", "main_route": false,
		"role": "scouting", "util": "escape:.4 scout:.4 stone_find:.2",
		"lore": "The Headless Rider holds his eyes in his hand. You see further.",
		"deeds": [["A Ranger", "class:Ranger", 1], ["Reach level 75", "level", 75], ["Spot 300 traps", "codex:traps_spotted", 300],
			["Clear 20 Deep Rifts", "codex:deep_rifts", 20], ["Reach floor 600", "floor", 600]]},
	"god_songweaver": {"name": "Songweaver", "cls": "Bard", "from": "", "side": "G", "focus": "regen:.5 skill:.5", "tags": "Song",
		"role_text": "Charms enemies to skip fights or turn on each other", "art": "boss_fairy_queen", "main_route": false,
		"role": "hypnosis", "util": "charm:.6 escape:.4",
		"lore": "The Fairy Queen never lost a song, until she heard yours.",
		"deeds": [["A Bard", "class:Bard", 1], ["Reach level 75", "level", 75], ["Charm 2,000 monsters", "confuses", 2000],
			["Meet 100 travelers", "codex:travelers", 100], ["Spare 500 monsters", "codex:spared", 500]]},
}

static func info(id: String) -> Dictionary:
	return LIST.get(id, {})

## [[label, have, need], ...] for a God class's deeds (Dev Mode and tests only: players never see them).
static func progress(g: GameState, id: String) -> Array:
	var out: Array = []
	for d in info(id).get("deeds", []):
		out.append([d[0], Hidden._have(g, String(d[1])), int(d[2])])
	return out

static func earned(g: GameState, id: String) -> bool:
	if info(id).is_empty():
		return false
	if bool(info(id)["main_route"]) and g.hidden_class != "":
		return false  # this one only answers a hero who stayed on the main route
	for line in progress(g, id):
		if int(line[1]) < int(line[2]):
			return false
	return true

## Any God class whose deeds are complete answers: the swap is offered right away.
static func check(g: GameState) -> void:
	if g.god_class != "":
		return
	for id in LIST:
		if id in g.god_offers or not earned(g, id):
			continue
		g.god_offers.append(id)
		var c := info(id)
		g.discovered[id] = true
		Trophies.on_god(g, id, String(c["name"]))  # 2.1: the Trophy Cabin
		g.events.append({"type": "god_offer", "id": id, "name": c["name"]})
		g.say("[color=#fde047]*** A GOD CLASS ANSWERS YOU: %s ***[/color] %s You can swap into it now." % [c["name"], c["lore"]])

## Swap into a God class that answered. It's for good.
static func take(g: GameState, id: String) -> bool:
	if g.god_class != "" or not id in g.god_offers:
		return false
	g.god_class = id
	g.god_offers.clear()
	g.hidden_class = ""  # the God class is your class now
	g.codex.add("gods")
	ClassTree._on_new_class(g, ClassTree.node(id))
	return true

static func bonus_sources(g: GameState) -> Array:
	if g.god_class == "":
		return []
	return [{"atk": POWER, "hp": POWER, "def": POWER}]
