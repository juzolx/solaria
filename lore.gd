class_name Lore
extends RefCounted
## 0.13+ (Stage 3): the story of Solaria, found a page at a time in the dungeon
## (rare drops from monsters, and in chests), read in Codex > Lore. And the town's
## keepers talk to you, about how your climb is going. All original writing.

const DROP_CHANCE := 1.2    # % per monster from floor 3
const CHEST_CHANCE := 15.0  # % per chest
const PAGES := [
	["The Last Noon", "There was a day the sun did not set. It went dark at noon, a black coin with a burning rim, and it has hung there ever since. The old folk call it the Eclipse. The young have never seen anything else."],
	["Roots", "When the light failed, the forest went down instead of up. Roots followed warmth into the deep, and where the roots went, the halls opened. The Mossy Hollows were the first."],
	["The Cave Mouth", "The town was built around the cave because the cave breathes warm air. Every child is told the same thing: the warmth is a promise, and the cave keeps its promises badly."],
	["What the Monsters Want", "Scholars argue about it. The monsters are not hungry; the dead ones have nothing in their bellies. A hunter said it best: they're not guarding the dark. They're guarding something from it."],
	["The First Descender", "Her name is lost, but her lantern is in the tavern above the bar. She went down past floor fifty and came back once. She would not say what she saw, only that it was beautiful, and that it was looking up."],
	["Snik's Account", "Snik claims he was born on floor three hundred, that he walked up for the customers, and that the stairs are much longer than they look. Snik also claims to be a prince. Snik claims a lot."],
	["Bones of the Catacombs", "Nobody built the Sunken Catacombs. They grew, the way the Hollows grew, out of everyone who was ever buried and forgotten. The bones are not angry. They are lonely, which is worse."],
	["The Flood", "The Flooded Depths were dry once. Then someone opened a sealed door looking for gold, and the sea that lives under the world came in to see who knocked."],
	["Ember Halls", "The deep fire is not the sun's fire. It burns without light, mostly, and what light it has it seems to borrow, as if the dark itself were trying to remember warmth."],
	["The Shadow Deep", "Below the embers the dark stops being an absence. It has weight. It has patience. Descenders who sleep there wake with the feeling that someone has just stopped watching them."],
	["The Other Realms", "The roots do not only go down. Some of them go sideways, into places that were never under the town: the elves' quiet groves, the dwarves' furnaces, courts of light and pits of fire. The roots don't care whose world it is."],
	["Calamities", "Some things in the deep are not monsters. They don't fight; they happen, like weather. The ones who meet a Calamity and live say it didn't want to kill them. It wanted to be seen."],
	["Your Killer", "The deep remembers. Fall, and the thing that felled you keeps what you dropped, wearing it like a trophy, waiting at the same spot. Some descenders swear they've seen them polishing the armor."],
	["The Rift", "There are rooms that are not on any floor. They open when the dungeon forgets itself, and close when it remembers. What's kept in them was hidden from something much worse than you."],
	["Under the Eclipse", "The last page is in a hand nobody knows: The sun did not go out. It went in. Every floor you clear, it is a little closer. Keep going. It is waiting to rise."],
]

## Maybe find the next page (call on a kill or a chest). Returns true if found.
static func maybe_find(g: GameState, chance: float) -> bool:
	if g.codex.lore.size() >= PAGES.size() or g.floor_num < 3:
		return false
	if randf() * 100.0 >= chance:
		return false
	var i := g.codex.lore.size()
	g.codex.lore.append(i)
	g.codex.dirty = true
	g.say("[color=#e8b14a]You find a torn page: \"%s\".[/color] Read it in Codex > Lore." % PAGES[i][0])
	g.events.append({"type": "toast", "text": "A lore page: \"%s\"" % PAGES[i][0]})
	g.tip("lore", "Lore pages tell Solaria's story, a page at a time. Read them in Codex > Lore.")
	return true

# =====================================================================
# The town's keepers
# =====================================================================

## Town page index -> [keeper, their usual lines]
const KEEPERS := {
	0: ["Marta, the shopkeeper", ["Potions first, glory second. You'd be amazed how many get that backwards.", "Everything here was carried up by someone who came back. Mostly.", "If it's shiny and cheap, it's cursed or it's Snik's. Usually both."]],
	1: ["Hilde Ironbraid, the dwarf smith", ["Bring me scrap and I'll bring you a reason to go deeper.", "Good steel remembers every hit. So does bad steel, just not for long.", "Sets are worth it. Matching gear sings."]],
	2: ["Pip, the barkeep", ["One spin of the Wheel? For luck. Or for the opposite of luck. One or the other.", "That lantern over the bar? The First Descender's. Don't touch it. It's warm.", "Sit. Drink. Lie to me about how deep you got."]],
	3: ["Mother Wren, at the inn", ["Sleep, love. The dark isn't going anywhere, more's the pity.", "You look like you've been chewed. Bed's made.", "Eat something. Heroes who skip supper skip breakfast for good."]],
	4: ["Ledger, the vault-keeper", ["What's in the Vault stays in the Vault. Even if you don't come back. Especially then.", "I count everything twice. The dark only has to be lucky once.", "Nothing has ever been stolen from my vault. Nothing has ever tried."]],
	5: ["Captain Roe, at the board", ["Contracts are honest work. Killing things, honestly.", "Every name on that board hurt somebody. Go even the score.", "Bring proof. Last fellow brought me a story. Stories don't pay."]],
	6: ["Guildmaster Aldous", ["Deeds, not words. Though the words get written down too.", "The guild remembers every descender. Make it a story worth keeping.", "Titles are earned. Then they're worn. Then they're lived up to."]],
	7: ["Tobin, the courier", ["Letter for you! Probably. Let me check. Yes. Probably.", "I don't go down there. The mail goes down there. I just wave.", "Rewards come by post. Nobody knows who sends half of them. Don't ask."]],
	8: ["Sister Fen, at the clinic", ["Pets heal faster than people. They complain less, too.", "Bring them back hurt, never lost. That's the deal with the deep.", "Every egg is a promise. Keep it warm."]],
	9: ["Father Aubrey, the priest", ["Cursed steel still cuts. It just cuts you a little too.", "A curse is a lock. Every lock has a price, and I take gold.", "Kneel if you like. The blessing works standing up."]],
	10: ["Old Gus, the cabin-keeper", ["Every trophy on this wall has a story. Most of them end with screaming.", "Dust them weekly. The Calamity ones bite.", "Hang another and the kids will never shut up about you."]],
}

## What the keeper of a town page says right now (steady until you next come home).
static func talk(g: GameState, page: int) -> String:
	if not KEEPERS.has(page):
		return ""
	var k: Array = KEEPERS[page]
	var lines: Array = (k[1] as Array).duplicate()
	# They notice how you're doing
	if not g.grave.is_empty():
		lines.append("Word is you fell on floor %d, and the %s is wearing your boots. Go get them back." % [int(g.grave["floor"]), Monsters.name_of(String(g.grave["killer"]))])
	if g.best_floor >= 100:
		lines.append("Floor %d! Half the town thinks you're a ghost now." % g.best_floor)
	elif g.best_floor >= 25:
		lines.append("Past floor %d already. The kids are playing at being you." % g.best_floor)
	if g.town_event != "" and TownEvents.EVENTS.has(g.town_event):
		lines.append("Have you seen? %s! The whole town's out." % String(TownEvents.EVENTS[g.town_event]["name"]))
	var pick := absi(hash("%d-%d" % [g.codex.stat("home_trips"), page])) % lines.size()
	return "%s: \"%s\"" % [k[0], lines[pick]]
