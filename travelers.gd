class_name Travelers
extends RefCounted
## Next update (Juzo): people in the dungeon. Now and then a door opens on a
## traveler: someone else down here, with something to offer for a price, or a
## favor to ask. Tap them to talk (a popup with two choices); Auto takes the
## first offer when you can pay for it, and passes otherwise.
## The room prop is {"kind": "traveler", "who": id, "used": bool}.

const LIST := {
	"pilgrim": {"name": "Brother Aldwin", "title": "a lost pilgrim", "race": "Human", "color": "#fde68a",
		"line": "\"Child of the surface! My flask is empty and my god is quiet. Would you share a potion?\"",
		"offers": [{"text": "Share a potion", "cost": "potion", "give": "blessing"}, {"text": "Point him toward the stairs", "give": "small_gold"}]},
	"cartographer": {"name": "Oswin", "title": "a half-mad cartographer", "race": "Goblin", "color": "#93c5fd",
		"line": "\"Maps! Maps of everywhere you shouldn't be. This one shows the way home. Cheap, for you.\"",
		"offers": [{"text": "Buy the map", "cost": "gold", "price": 30, "give": "scroll"}, {"text": "No thanks", "give": "nothing"}]},
	"smith": {"name": "Gilda Deepanvil", "title": "a dwarf smith on the road", "race": "Dwarf", "color": "#f59e0b",
		"line": "\"That blade's seen better days. Hand it here. Scrap for my trouble, nothing more.\"",
		"offers": [{"text": "Let her hone your weapon", "cost": "scrap", "price": 4, "give": "hone"}, {"text": "Ask about the deep", "give": "lore"}]},
	"seer": {"name": "Mirela", "title": "a fortune-teller", "race": "Elf", "color": "#c084fc",
		"line": "\"Cross my palm and I'll tell you where luck is hiding. It's closer than you think.\"",
		"offers": [{"text": "Cross her palm", "cost": "gold", "price": 20, "give": "luck"}, {"text": "Walk on", "give": "nothing"}]},
	"bard": {"name": "Wren", "title": "a wandering bard", "race": "Fairy", "color": "#f472b6",
		"line": "\"An audience! Sit, sit. One song for the road, and you'll fight like three of you.\"",
		"offers": [{"text": "Listen to a song", "give": "song"}, {"text": "Toss a coin and go", "cost": "gold", "price": 5, "give": "nothing"}]},
	"lost": {"name": "Pell", "title": "a lost descender", "race": "Human", "color": "#cbd5e1",
		"line": "\"I lost my team three floors up. I've got nothing left but this. Help me get home?\"",
		"offers": [{"text": "Give gold for the climb", "cost": "gold", "price": 15, "give": "lost_gift"}, {"text": "Wish him luck", "give": "nothing"}]},
}
const DOOR_WEIGHT := 4   # in GameState.DOOR_WEIGHTS terms
const FROM_FLOOR := 4

static func pick() -> String:
	return LIST.keys().pick_random()

static func info(id: String) -> Dictionary:
	return LIST.get(id, LIST["pilgrim"])

## What an offer costs right now ("" = free), and if you can pay.
static func price(g: GameState, o: Dictionary) -> int:
	return int(o.get("price", 0)) * (2 + g.floor_num) if o.get("cost", "") == "gold" else int(o.get("price", 0)) * (1 + GameData.zone_index(g.floor_num))

static func cost_text(g: GameState, o: Dictionary) -> String:
	match String(o.get("cost", "")):
		"gold":
			return "%d gold" % price(g, o)
		"scrap":
			return "%d scrap" % price(g, o)
		"potion":
			return "1 potion"
	return ""

static func can_pay(g: GameState, o: Dictionary) -> bool:
	match String(o.get("cost", "")):
		"gold":
			return g.gold >= price(g, o)
		"scrap":
			return g.scrap >= price(g, o)
		"potion":
			return g.potions > 0
	return true

## Takes the offer. Returns what happened, for the log and the popup.
static func choose(g: GameState, p: Dictionary, n: int) -> String:
	var who := info(String(p.get("who", "")))
	var o: Dictionary = who["offers"][clampi(n, 0, 1)]
	if p.get("used", false) or not can_pay(g, o):
		return ""
	match String(o.get("cost", "")):
		"gold":
			g.gold -= price(g, o)
		"scrap":
			g.scrap -= price(g, o)
		"potion":
			g.potions -= 1
	p["used"] = true
	g.codex.add("travelers")
	var out := ""
	match String(o["give"]):
		"blessing":
			g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
			g.luck_turns += 20
			g._faith(5)
			out = "Brother Aldwin drinks, and blesses you before he goes (+15% Attack and better luck for a while)."
		"small_gold":
			var gd := 5 + g.floor_num * 2
			g._add_gold(gd)
			out = "He thanks you and presses a few coins into your hand (+%d gold)." % gd
		"scroll":
			g.return_scrolls += 1
			out = "Oswin's map really does show a way home: +1 Return Scroll."
		"hone":
			if g.equipped.has("Weapon") and int(g.equipped["Weapon"]["level"]) < GameData.MAX_UPGRADE:
				g.equipped["Weapon"]["level"] = int(g.equipped["Weapon"]["level"]) + 1
				g.bag_version += 1
				out = "Gilda hones your %s on her travel stone. It's +%d now." % [GameData.display_name(g.equipped["Weapon"]), int(g.equipped["Weapon"]["level"])]
			else:
				g.scrap += price(g, o)
				out = "Gilda looks your weapon over and hands it back. \"Nothing I can do to that.\" She gives your scrap back."
		"lore":
			Lore.maybe_find(g, 100.0)
			out = "Gilda tells you what she's seen further down. You write it all down."
		"luck":
			g.luck_turns += 60
			out = "Mirela smiles at your palm. \"Soon.\" (Better loot for 60 turns.)"
		"song":
			g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
			g.hero_hp = mini(g.get_max_hp(), g.hero_hp + g.get_max_hp() / 4)
			out = "Wren plays you a fighting song. You feel rested and sharp (+15% Attack for a while)."
		"lost_gift":
			if randf() < 0.5:
				var r := maxi(Monsters.RARE, g._rarity(20, GameData.LEGENDARY_CHANCE_NORMAL))
				g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.floor_num, g._new_id()))
				out = "Pell hands you the only thing he kept: a piece of gear from his old team. \"They'd want it used.\""
			else:
				g._faith(5)
				out = "Pell grips your hand and heads for the stairs. Somewhere, someone noticed (+faith)."
		_:
			out = "You nod to %s and move on." % who["name"]
	g.say("[color=%s]%s[/color]" % [who["color"], out])
	g.save_game()
	return out

## Auto: the first offer only if it costs little (a fifth of what you carry at most,
## or a potion when you have 3 or more). Otherwise the free choice.
static func auto_choose(g: GameState, p: Dictionary) -> String:
	var who := info(String(p.get("who", "")))
	var o: Dictionary = who["offers"][0]
	var cheap := can_pay(g, o)
	match String(o.get("cost", "")):
		"gold":
			cheap = price(g, o) * 5 <= g.gold
		"scrap":
			cheap = price(g, o) * 5 <= g.scrap
		"potion":
			cheap = g.potions >= 3
	var n := 0 if cheap else 1
	if not can_pay(g, who["offers"][n]):
		p["used"] = true
		return ""
	return choose(g, p, n)

static var _faces := {}

## Their face (made once, then kept).
static func portrait(id: String) -> Texture2D:
	if not _faces.has(id):
		_faces[id] = Sprites.portrait({"race": info(id)["race"]})
	return _faces[id]
