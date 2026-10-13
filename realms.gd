class_name Realms
extends RefCounted
## Floors 251-500: the realms of the races. The World Tree's roots (floors
## 1-250) crack open into other races' homelands, and you invade them.
##
## You choose the order: after each zone boss from floor 250 on, portals open
## to the realms you haven't entered yet. Your path (race, faith, Wanderer
## road) adds or locks some portals. Each realm has 5 sub-areas, a mid boss
## at its floor 25, a ruler at its floor 50, its own mechanic, its own event,
## a camp with that race's merchant, a set, uniques and a material.
##
## Monsters marked "people" are the realm race's own people: killing them
## costs reputation with that race, sparing them earns it.
##
## Names and story text are working names until the lore is written.

const FIRST_FLOOR := 251
const COUNT := 5
const IDS := ["elf", "fairy", "dwarf", "angel", "demon"]
const BASE_ZONES := 5   # realms are GameData.ZONES 5..9

# Realm metadata (the fighting content is in ZONES below, same order as IDS)
const INFO := {
	"elf": {"name": "The Hushwood", "race": "Elf", "color": "#5b8a72",
		"blurb": "The elves' forest, silent since they died. Their ghosts still walk its paths.",
		"mechanic": {"name": "Mist", "text": "Thick mist: 15% of attacks (yours and theirs) miss."},
		"event": {"name": "The World Tree's Shrine", "text": "A shrine at the foot of a dead tree. Something in it still listens."},
		"camp": "Lanternfall Camp", "merchant": "an elven ghost who still trades",
		"portal_bias": ["Elf", "Fairy"], "locks": {}},
	"fairy": {"name": "The Glimmer Court", "race": "Fairy", "color": "#d870ac",
		"blurb": "The fae realm: beautiful, playful and deadly. Nothing here is what it looks like.",
		"mechanic": {"name": "Glamour", "text": "Illusions: monsters' tiers are hidden until they're hurt, and some foes are only illusions."},
		"event": {"name": "A Fairy Ring", "text": "A fairy asks you a riddle. Answer well."},
		"camp": "The Toadstool Market", "merchant": "a fairy peddler with very fair prices (for her)",
		"portal_bias": ["Fairy", "Elf"], "locks": {}},
	"dwarf": {"name": "The Ironroot Deeps", "race": "Dwarf", "color": "#b45309",
		"blurb": "The dwarven forge-halls under the mountains, still burning and still guarded.",
		"mechanic": {"name": "Forge Heat", "text": "The heat burns 1% of your HP each turn, but salvaging here gives 50% more scrap."},
		"event": {"name": "A Runic Anvil", "text": "An old anvil still humming with runes. It can improve your gear, for a price."},
		"camp": "Hearthstone Hold", "merchant": "a dwarven smith",
		"portal_bias": ["Dwarf", "Golem"], "locks": {}},
	"angel": {"name": "The Gilded Spire", "race": "Angel", "color": "#e8b14a",
		"blurb": "The angels' tower above the clouds. They judge everyone who climbs it.",
		"mechanic": {"name": "Judgement", "text": "Good heroes heal 1% each turn here. Evil heroes take 15% more damage."},
		"event": {"name": "The Choir's Judgement", "text": "The choir weighs your soul."},
		"camp": "The Cloudstair Rest", "merchant": "a tired angel quartermaster",
		"portal_bias": ["Angel", "Human"], "locks": {"evil_below": -60.0}},
	"demon": {"name": "The Cinder Abyss", "race": "Demon", "color": "#be123c",
		"blurb": "The demons' burning homeland, a maze of chains, fire and old bargains.",
		"mechanic": {"name": "Hellfire", "text": "Hellfire burns 1.5% of your HP each turn, but lifesteal heals 50% more."},
		"event": {"name": "A Devil's Bargain", "text": "A smiling devil offers you power. It always costs something."},
		"camp": "The Brimstone Bazaar", "merchant": "a demon broker",
		"portal_bias": ["Demon", "Undead"], "locks": {"good_above": 60.0}},
}

# The fighting content, in the same format as GameData.ZONES.
const ZONES := [
	{"name": "The Hushwood", "realm": "elf", "color": "#5b8a72", "enemies": [
		{"name": "Hollow Sentinel", "shape": "humanoid", "color": "#9fd8c4", "people": true},
		{"name": "Grief Wisp", "shape": "spirit", "color": "#c8f2ee"},
		{"name": "Barkhusk", "shape": "brute", "color": "#6b5a4a"},
		{"name": "Pale Stag", "shape": "beast", "color": "#dfe6f0"},
		{"name": "Rootstrangler", "shape": "serpent", "color": "#5d7a3a"},
	], "subs": [
		{"name": "Ashen Glade", "monster": {"name": "Mourning Dryad", "shape": "humanoid", "color": "#8aa878"}},
		{"name": "Silent Boughs", "monster": {"name": "Owlwraith", "shape": "beast", "color": "#a9b3c6"}},
		{"name": "Lantern Graves", "monster": {"name": "Lantern Keeper", "shape": "humanoid", "color": "#fee761", "people": true}},
		{"name": "Rootless Hall", "monster": {"name": "Blightcap", "shape": "brute", "color": "#8a5a9a"}},
		{"name": "The Withered Heart", "monster": {"name": "Heartrot Treant", "shape": "brute", "color": "#4a3a2a"}},
	], "mid": {"name": "The Weeping Warden", "art": "boss_weeping_warden", "shape": "humanoid", "color": "#9fd8c4", "people": true, "uniques": [
		{"name": "Warden's Last Arrow", "flavor": "She kept one arrow for the day the Tree died. She never fired it.", "slot": "Weapon", "effect": "crit", "value": 18},
	]}, "boss": {"name": "The Withered Queen", "art": "boss_withered_queen", "shape": "humanoid", "color": "#c8f2ee", "people": true, "uniques": [
		{"name": "Crown of Fallen Leaves", "flavor": "Every leaf is a name. She remembers all of them.", "slot": "Helmet", "effect": "regen", "value": 3},
		{"name": "Rootwoven Mantle", "flavor": "Woven from the Tree's last living roots.", "slot": "Chest", "effect": "dodge", "value": 12},
	]}},
	{"name": "The Glimmer Court", "realm": "fairy", "color": "#d870ac", "enemies": [
		{"name": "Pixie Swarm", "shape": "spirit", "color": "#ffc6de"},
		{"name": "Thornling", "shape": "humanoid", "color": "#75a743", "people": true},
		{"name": "Mushroom Knight", "shape": "humanoid", "color": "#e43b44", "people": true},
		{"name": "Glimmermoth", "shape": "beast", "color": "#c4b5fd"},
		{"name": "Changeling", "shape": "humanoid", "color": "#a9c6ee", "people": true},
	], "subs": [
		{"name": "Moonpetal Fields", "monster": {"name": "Moonhare", "shape": "beast", "color": "#eef2f8"}},
		{"name": "The Mirror Pond", "monster": {"name": "Mirror Nymph", "shape": "spirit", "color": "#a4dddb"}},
		{"name": "Mushroom Hollow", "monster": {"name": "Bogle", "shape": "humanoid", "color": "#5a6b3a"}},
		{"name": "Thorn Labyrinth", "monster": {"name": "Briar Knight", "shape": "humanoid", "color": "#468232", "people": true}},
		{"name": "The Queen's Bower", "monster": {"name": "Gilded Fae", "shape": "spirit", "color": "#fee761", "people": true}},
	], "mid": {"name": "The Jester of Thorns", "art": "boss_jester_of_thorns", "shape": "humanoid", "color": "#d870ac", "people": true, "uniques": [
		{"name": "The Jester's Last Joke", "flavor": "Nobody laughed. Then nobody was left.", "slot": "Weapon", "effect": "double_strike", "value": 18},
	]}, "boss": {"name": "The Fairy Queen", "art": "boss_fairy_queen", "shape": "spirit", "color": "#f9a8d4", "people": true, "uniques": [
		{"name": "Gossamer Crown", "flavor": "Light as a promise. Just as easy to break.", "slot": "Helmet", "effect": "dodge", "value": 12},
		{"name": "Queen's Favor", "flavor": "A token from the Queen. It means she owes you. Or you owe her.", "slot": "Off Hand", "effect": "gold_find", "value": 30},
	]}},
	{"name": "The Ironroot Deeps", "realm": "dwarf", "color": "#b45309", "enemies": [
		{"name": "Forge Sentry", "shape": "humanoid", "color": "#c0cbdc", "people": true},
		{"name": "Slag Golem", "shape": "brute", "color": "#5a4a3e"},
		{"name": "Rune Hound", "shape": "beast", "color": "#7fd0f0"},
		{"name": "Cinder Miner", "shape": "humanoid", "color": "#c28569", "people": true},
		{"name": "Steamcrawler", "shape": "serpent", "color": "#8b9bb4"},
	], "subs": [
		{"name": "Slag Gate", "monster": {"name": "Ash Raider", "shape": "humanoid", "color": "#8a5444", "people": true}},
		{"name": "The Rune Halls", "monster": {"name": "Rune Wraith", "shape": "spirit", "color": "#73bed3"}},
		{"name": "The Great Anvil", "monster": {"name": "Anvil Brute", "shape": "brute", "color": "#3a4466"}},
		{"name": "The Gem Vaults", "monster": {"name": "Gem Crawler", "shape": "beast", "color": "#c27ad8"}},
		{"name": "Throne of Stone", "monster": {"name": "Stoneguard", "shape": "humanoid", "color": "#8b9bb4", "people": true}},
	], "mid": {"name": "Forgemaster Brann", "art": "boss_forgemaster_brann", "shape": "humanoid", "color": "#f59e0b", "people": true, "uniques": [
		{"name": "Brann's Hammer", "flavor": "It made a thousand blades. Now it breaks them.", "slot": "Weapon", "effect": "double_strike", "value": 18},
	]}, "boss": {"name": "High King Thrandor", "art": "boss_high_king_thrandor", "shape": "humanoid", "color": "#e8b14a", "people": true, "uniques": [
		{"name": "The Undermountain Crown", "flavor": "Forged from the first gold ever mined.", "slot": "Helmet", "effect": "thorns", "value": 25},
		{"name": "Runewall", "flavor": "Every rune says 'no'. In a different way.", "slot": "Off Hand", "effect": "thorns", "value": 25},
	]}},
	{"name": "The Gilded Spire", "realm": "angel", "color": "#e8b14a", "enemies": [
		{"name": "Choir Sentinel", "shape": "humanoid", "color": "#fde68a", "people": true},
		{"name": "Halo Wisp", "shape": "spirit", "color": "#fff4a3"},
		{"name": "Gilded Lion", "shape": "beast", "color": "#feae34"},
		{"name": "Eye of Judgement", "shape": "spirit", "color": "#ffffff"},
		{"name": "Sky Serpent", "shape": "serpent", "color": "#a9c6ee"},
	], "subs": [
		{"name": "The Cloudstair", "monster": {"name": "Cherub", "shape": "spirit", "color": "#ffc6de", "people": true}},
		{"name": "Choir Gardens", "monster": {"name": "Hymnbird", "shape": "beast", "color": "#7fb2e0"}},
		{"name": "Halls of Judgement", "monster": {"name": "Executor", "shape": "humanoid", "color": "#c0cbdc", "people": true}},
		{"name": "The Sunforge", "monster": {"name": "Sun Golem", "shape": "brute", "color": "#fee761"}},
		{"name": "The Empyrean Gate", "monster": {"name": "Throne Warden", "shape": "humanoid", "color": "#e8b14a", "people": true}},
	], "mid": {"name": "Archon Valeth", "art": "boss_archon_valeth", "shape": "humanoid", "color": "#fde68a", "people": true, "uniques": [
		{"name": "Valeth's Verdict", "flavor": "A sword that has never once been wrong.", "slot": "Weapon", "effect": "crit", "value": 18},
	]}, "boss": {"name": "Seraphiel, the First Light", "art": "boss_seraphiel", "shape": "spirit", "color": "#fff4a3", "people": true, "uniques": [
		{"name": "Wings of the First Light", "flavor": "Not real wings. Real enough.", "slot": "Chest", "effect": "regen", "value": 3},
		{"name": "Dawnbreaker", "flavor": "The first sunrise, hammered into a blade.", "slot": "Weapon", "effect": "lifesteal", "value": 12},
	]}},
	{"name": "The Cinder Abyss", "realm": "demon", "color": "#be123c", "enemies": [
		{"name": "Imp", "shape": "humanoid", "color": "#e43b44", "people": true},
		{"name": "Hellmaw", "shape": "beast", "color": "#8e2e38"},
		{"name": "Chainwraith", "shape": "spirit", "color": "#8b9bb4"},
		{"name": "Brimstone Brute", "shape": "brute", "color": "#be4a2f", "people": true},
		{"name": "Abyssal Worm", "shape": "serpent", "color": "#68386c"},
	], "subs": [
		{"name": "Brimstone Wastes", "monster": {"name": "Ash Fiend", "shape": "spirit", "color": "#5a4a3e"}},
		{"name": "The Chain Bridges", "monster": {"name": "Chain Warden", "shape": "humanoid", "color": "#5a6988", "people": true}},
		{"name": "The Soul Market", "monster": {"name": "Soul Broker", "shape": "humanoid", "color": "#9a4fc0", "people": true}},
		{"name": "Obsidian Citadel", "monster": {"name": "Obsidian Knight", "shape": "humanoid", "color": "#262b44", "people": true}},
		{"name": "The Throne Pit", "monster": {"name": "Hellborn Duke", "shape": "brute", "color": "#a22633", "people": true}},
	], "mid": {"name": "Duke Malgrath", "art": "boss_duke_malgrath", "shape": "brute", "color": "#a22633", "people": true, "uniques": [
		{"name": "Malgrath's Contract", "flavor": "Signed in blood. Not yours. Yet.", "slot": "Off Hand", "effect": "lifesteal", "value": 12},
	]}, "boss": {"name": "Azgaroth, Lord of the Abyss", "art": "boss_azgaroth", "shape": "brute", "color": "#e43b44", "people": true, "uniques": [
		{"name": "Hellbrand", "flavor": "It has burned since before the first sunrise.", "slot": "Weapon", "effect": "double_strike", "value": 25},
		{"name": "Throne-Iron Greaves", "flavor": "Cut from the legs of his throne. He had spares.", "slot": "Legs", "effect": "thorns", "value": 25},
	]}},
]

const MATERIALS := ["Ghostwood Sap", "Fae Dust", "Runesteel Ingot", "Seraph Feather", "Abyssal Ember"]

## 100% of a realm earns a title (an achievement) and one of these looks for the Wardrobe.
const COSMETICS := {
	"elf": {"name": "Crown of the Last Leaf", "slot": "Helmet", "type": "crown", "mat": "pale", "trim": "#9fd8c4"},
	"fairy": {"name": "Moth-Wing Diadem", "slot": "Helmet", "type": "crown", "mat": "coral", "trim": "#f9a8d4"},
	"dwarf": {"name": "Undermountain Warhelm", "slot": "Helmet", "type": "helm", "mat": "gold", "trim": "#f59e0b"},
	"angel": {"name": "Radiant Mantle", "slot": "Chest", "type": "robe", "mat": "pale", "trim": "#fde68a"},
	"demon": {"name": "Hellforged Plate", "slot": "Chest", "type": "plate", "mat": "dark", "trim": "#e43b44"},
}

static func cosmetic_by_art(art: String) -> Dictionary:
	return COSMETICS.get(art.trim_prefix("c_"), {}) if art.begins_with("c_") else {}

static func info(id: String) -> Dictionary:
	return INFO.get(id, {})

static func realm_name(id: String) -> String:
	return info(id).get("name", "a realm")

## The realm id at a zone index (5..9), or "".
static func id_for_zone(zone_i: int) -> String:
	var k := zone_i - BASE_ZONES
	return IDS[k] if k >= 0 and k < IDS.size() else ""

static func zone_for_id(id: String) -> int:
	return BASE_ZONES + IDS.find(id)

## The race whose homeland a zone is ("" for the roots, floors 1-250).
static func zone_race(zone_i: int) -> String:
	var id := id_for_zone(zone_i)
	return info(id).get("race", "") if id != "" else ""

## Is this monster one of the realm race's people?
static func is_people(monster: Dictionary) -> bool:
	return monster.get("people", false)

# =====================================================================
# Realm mechanics (each realm plays a little differently)
# =====================================================================

const MIST_MISS := 15.0        # Hushwood: % of attacks lost in the mist
const FORGE_HEAT := 0.01       # Ironroot: HP lost per turn
const FORGE_SCRAP := 1.5
const HELLFIRE := 0.015        # Cinder Abyss: HP lost per turn
const HELL_LIFESTEAL := 1.5
const JUDGE_HEAL := 0.01       # Gilded Spire: good heroes heal per turn
const JUDGE_HURT := 1.15       # ...evil heroes take more damage
const JUDGE_GOOD := 20.0       # faith above this counts as good, below -this as evil
const ILLUSION_CHANCE := 0.12  # Glimmer Court: some monsters are only illusions

static func here(g: GameState) -> String:
	return GameData.realm_of(g.floor_num) if not g.trial_active else ""

static func misses(g: GameState) -> bool:
	return here(g) == "elf" and randf() * 100.0 < MIST_MISS

static func scrap_mult(g: GameState) -> float:
	return FORGE_SCRAP if here(g) == "dwarf" else 1.0

static func lifesteal_mult(g: GameState) -> float:
	return HELL_LIFESTEAL if here(g) == "demon" else 1.0

static func damage_mult(g: GameState) -> float:
	return JUDGE_HURT if here(g) == "angel" and g.faith < -JUDGE_GOOD else 1.0

## Once per turn. Returns text for the combat log.
static func on_turn(g: GameState) -> String:
	if g.hero_hp <= 0:
		return ""
	var mx := g.get_max_hp()
	match here(g):
		"dwarf":
			var d := maxi(1, int(mx * FORGE_HEAT))
			g.hero_hp -= d
			g.events.append({"type": "enemy_hit", "dmg": d, "burning": true})
		"demon":
			var d := maxi(1, int(mx * HELLFIRE))
			g.hero_hp -= d
			g.events.append({"type": "enemy_hit", "dmg": d, "burning": true})
		"angel":
			if g.faith > JUDGE_GOOD:
				var h := maxi(1, int(mx * JUDGE_HEAL))
				g.hero_hp = mini(mx, g.hero_hp + h)
	return ""

## Glimmer Court: hides a monster's tier until it's hurt.
static func hides_tier(g: GameState) -> bool:
	return here(g) == "fairy" and g.enemy_hp >= g.enemy_max_hp

static func roll_illusion(g: GameState) -> bool:
	return here(g) == "fairy" and not g.enemy_is_boss and not g.enemy_goblin and g.horde_left <= 0 and randf() < ILLUSION_CHANCE

# =====================================================================
# The realm monsters: Bestiary lore, favorite drops and Signature items
# =====================================================================
const MONSTER_INFO := {
	# ---------- The Hushwood (elves' ghost forest) ----------
	"Hollow Sentinel": {"lore": "An elven archer who never left her post. She doesn't know the forest is dead. Don't tell her.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "The Sentinel's Vigil", "slot": "Weapon", "type": "bow", "effect": "crit", "value": 20, "mat": "pale", "trim": "#9fd8c4", "flavor": "Strung with a hair from the last elf who ever laughed."}},
	"Grief Wisp": {"lore": "When an elf died, a little light was left behind. Thousands of them now, drifting and sad.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Jar of Last Lights", "slot": "Off Hand", "type": "orb", "effect": "regen", "value": 3, "mat": "crystal", "trim": "#c8f2ee", "flavor": "They're warmer than you'd think."}},
	"Barkhusk": {"lore": "A tree that died standing up, then decided to keep walking.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Barkhusk Shell", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 25, "mat": "wood", "trim": "#5d7a3a", "flavor": "Splinters included at no extra charge."}},
	"Pale Stag": {"lore": "The elves' sacred deer, still running the old hunting paths with no one left to hunt them.", "drops": ["Feet", "Helmet"],
		"sig": {"name": "Crown of the Pale Stag", "slot": "Helmet", "type": "crown", "effect": "dodge", "value": 12, "mat": "bone", "trim": "#dfe6f0", "flavor": "Antlers that never shed."}},
	"Rootstrangler": {"lore": "Roots of the dying World Tree, grown hungry. They squeeze anything warm.", "drops": ["Legs", "Weapon"],
		"sig": {"name": "Strangleroot Whip", "slot": "Weapon", "type": "spear", "effect": "lifesteal", "value": 12, "mat": "hide", "trim": "#5d7a3a", "flavor": "It squeezes back."}},
	"Mourning Dryad": {"lore": "The spirit of a tree that watched its elves die. She has been crying for a hundred years.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Dryad's Tear", "slot": "Off Hand", "type": "orb", "effect": "regen", "value": 3, "mat": "sea", "trim": "#8aa878", "flavor": "One drop, a hundred years old. Still falling."}},
	"Owlwraith": {"lore": "An owl that died in the Hushwood and kept watching. It sees you even with its eyes closed.", "drops": ["Helmet", "Feet"],
		"sig": {"name": "Hood of the Owlwraith", "slot": "Helmet", "type": "hood", "effect": "crit", "value": 18, "mat": "linen", "trim": "#a9b3c6", "flavor": "Turn your head all the way around. Go on."}},
	"Lantern Keeper": {"lore": "An elf ghost who tends lanterns on the graves of her people, so they can find their way home.", "drops": ["Off Hand", "Chest"],
		"sig": {"name": "The Keeper's Lantern", "slot": "Off Hand", "type": "orb", "effect": "gold_find", "value": 30, "mat": "gold", "trim": "#fee761", "flavor": "The flame never goes out. She made sure."}},
	"Blightcap": {"lore": "A mushroom the size of a bear, grown fat on the Tree's rot. Its spores make you sad for no reason.", "drops": ["Helmet", "Legs"],
		"sig": {"name": "Blightcap Helm", "slot": "Helmet", "type": "cap", "effect": "thorns", "value": 25, "mat": "scale", "trim": "#8a5a9a", "flavor": "Smells like a wet funeral."}},
	"Heartrot Treant": {"lore": "The oldest trees near the Withered Heart. The rot reached them first, and it made them angry.", "drops": ["Weapon", "Chest"],
		"sig": {"name": "Heartwood Maul", "slot": "Weapon", "type": "mace", "effect": "double_strike", "value": 20, "mat": "wood", "trim": "#4a3a2a", "flavor": "Cut from the Tree's heart. It still has a pulse."}},
	# ---------- The Glimmer Court (the fae) ----------
	"Pixie Swarm": {"lore": "A hundred tiny fairies who think biting you is the funniest thing in the world.", "drops": ["Helmet", "Feet"],
		"sig": {"name": "Pixie-Spun Slippers", "slot": "Feet", "type": "sandals", "effect": "dodge", "value": 12, "mat": "cloth", "trim": "#ffc6de", "flavor": "Woven from moonlight and spite."}},
	"Thornling": {"lore": "Fae foot soldiers grown on rose bushes. They're polite right up until they stab you.", "drops": ["Weapon", "Legs"],
		"sig": {"name": "Rosethorn Rapier", "slot": "Weapon", "type": "sword", "effect": "crit", "value": 20, "mat": "hide", "trim": "#e43b44", "flavor": "Smells lovely. Cuts deep."}},
	"Mushroom Knight": {"lore": "Very small, very proud and very sure he's the hero of this story.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "The Toadstool Helm", "slot": "Helmet", "type": "helm", "effect": "thorns", "value": 25, "mat": "coral", "trim": "#fbf3dc", "flavor": "Spotted. Dashing. Slightly poisonous."}},
	"Glimmermoth": {"lore": "A moth with wings like stained glass. Look at them too long and you forget why you're here.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Glimmerwing Cloak", "slot": "Chest", "type": "robe", "effect": "dodge", "value": 12, "mat": "scale", "trim": "#c4b5fd", "flavor": "The pattern moves when you aren't looking."}},
	"Changeling": {"lore": "A fae child left in a human cradle, grown up and come home. It can wear any face, including yours.", "drops": ["Helmet", "Chest"],
		"sig": {"name": "The Borrowed Face", "slot": "Helmet", "type": "hood", "effect": "double_strike", "value": 18, "mat": "linen", "trim": "#a9c6ee", "flavor": "Give it back when you're done."}},
	"Moonhare": {"lore": "A white hare that only runs by moonlight. Fairies race it. They always lose.", "drops": ["Feet", "Legs"],
		"sig": {"name": "Moonhare Boots", "slot": "Feet", "type": "boots", "effect": "dodge", "value": 12, "mat": "pale", "trim": "#eef2f8", "flavor": "You can't catch it. Now nobody can catch you."}},
	"Mirror Nymph": {"lore": "She lives in the Mirror Pond and shows you who you'd be if you'd never come down here.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "The Truthful Mirror", "slot": "Off Hand", "type": "orb", "effect": "crit", "value": 18, "mat": "crystal", "trim": "#a4dddb", "flavor": "It's never lied. That's the problem."}},
	"Bogle": {"lore": "A sour little fae who lives under toadstools and hates everyone, especially other bogles.", "drops": ["Legs", "Weapon"],
		"sig": {"name": "Bogle's Grudge-Knife", "slot": "Weapon", "type": "dagger", "effect": "lifesteal", "value": 12, "mat": "iron", "trim": "#5a6b3a", "flavor": "Every notch is somebody he didn't like."}},
	"Briar Knight": {"lore": "Guardians of the Thorn Labyrinth. Their armor grows back when you cut it.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Briarwall", "slot": "Off Hand", "type": "tower", "effect": "thorns", "value": 25, "mat": "hide", "trim": "#468232", "flavor": "Hiding behind it is a prickly decision."}},
	"Gilded Fae": {"lore": "The Queen's own courtiers, dusted in gold. They don't fight you. They make you fight yourself.", "drops": ["Helmet", "Chest"],
		"sig": {"name": "Courtier's Gilded Mask", "slot": "Helmet", "type": "crown", "effect": "gold_find", "value": 30, "mat": "gold", "trim": "#fee761", "flavor": "Smile. Everyone's watching."}},
	# ---------- The Ironroot Deeps (the dwarves) ----------
	"Forge Sentry": {"lore": "A dwarf guard in full plate. Thirty years at the same door and he's never let anyone in.", "drops": ["Off Hand", "Chest"],
		"sig": {"name": "Doorwarden's Bulwark", "slot": "Off Hand", "type": "tower", "effect": "thorns", "value": 25, "mat": "steel", "trim": "#c0cbdc", "flavor": "'None shall pass.' He meant it."}},
	"Slag Golem": {"lore": "Leftover slag from ten thousand forgings, poured into a mold and told to stand guard.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Slagplate", "slot": "Chest", "type": "plate", "effect": "regen", "value": 3, "mat": "dark", "trim": "#f77622", "flavor": "Still warm from the furnace."}},
	"Rune Hound": {"lore": "Clockwork hunting dogs with a rune for a heart. They can smell gold through stone.", "drops": ["Feet", "Weapon"],
		"sig": {"name": "Runehound Treads", "slot": "Feet", "type": "sabatons", "effect": "gold_find", "value": 30, "mat": "iron", "trim": "#7fd0f0", "flavor": "Your feet start pointing at treasure."}},
	"Cinder Miner": {"lore": "Dwarves who dug too deep and got stuck in the heat. They're still digging.", "drops": ["Helmet", "Weapon"],
		"sig": {"name": "Deepdelver's Pick", "slot": "Weapon", "type": "axe", "effect": "double_strike", "value": 20, "mat": "ember", "trim": "#c28569", "flavor": "It's broken through four mountains."}},
	"Steamcrawler": {"lore": "A mining machine shaped like a centipede. Nobody remembers how to turn it off.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Pistonleg Greaves", "slot": "Legs", "type": "greaves", "effect": "dodge", "value": 12, "mat": "steel", "trim": "#8b9bb4", "flavor": "Hiss. Clank. Hiss."}},
	"Ash Raider": {"lore": "Exiled dwarves who raid their own kin's forges. The dwarves don't talk about them.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Exile's Axe", "slot": "Weapon", "type": "axe", "effect": "lifesteal", "value": 12, "mat": "dark", "trim": "#8a5444", "flavor": "Forged in a stolen furnace."}},
	"Rune Wraith": {"lore": "The ghost of a rune-carver, still carving. Every rune it writes is a curse.", "drops": ["Off Hand", "Chest"],
		"sig": {"name": "Wraith-Carved Tome", "slot": "Off Hand", "type": "tome", "effect": "crit", "value": 18, "mat": "crystal", "trim": "#73bed3", "flavor": "The runes rearrange themselves at night."}},
	"Anvil Brute": {"lore": "A dwarf so big and so stubborn that the smiths started using him as an anvil. He didn't mind.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Anvilback Plate", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 25, "mat": "iron", "trim": "#3a4466", "flavor": "Hit it with a hammer. It likes that."}},
	"Gem Crawler": {"lore": "A beetle that eats gemstones and grows them on its back. Dwarves hunt it for the crown jewels.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "Gembeetle Crown", "slot": "Helmet", "type": "crown", "effect": "gold_find", "value": 30, "mat": "scale", "trim": "#c27ad8", "flavor": "Worth a kingdom. Itches a lot."}},
	"Stoneguard": {"lore": "The High King's honor guard, carved partly from the mountain itself.", "drops": ["Off Hand", "Legs"],
		"sig": {"name": "Mountainheart Shield", "slot": "Off Hand", "type": "shield", "effect": "regen", "value": 3, "mat": "steel", "trim": "#e8b14a", "flavor": "A slice of the mountain's heart."}},
	# ---------- The Gilded Spire (the angels) ----------
	"Choir Sentinel": {"lore": "An angel soldier who sings while she fights. The song judges you. The spear does the rest.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Hymnspear", "slot": "Weapon", "type": "spear", "effect": "crit", "value": 20, "mat": "gold", "trim": "#fde68a", "flavor": "It hums a note no throat could sing."}},
	"Halo Wisp": {"lore": "A halo with nobody under it. It's looking for someone worthy. It hasn't found anyone yet.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "The Wandering Halo", "slot": "Helmet", "type": "crown", "effect": "regen", "value": 3, "mat": "gold", "trim": "#fff4a3", "flavor": "It picked you. Try not to disappoint it."}},
	"Gilded Lion": {"lore": "The Spire's guardian beasts, made of living gold. Their roar sounds like a trumpet.", "drops": ["Chest", "Feet"],
		"sig": {"name": "Lionmane Mantle", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 25, "mat": "gold", "trim": "#feae34", "flavor": "Heavy. Shiny. Roars when it's angry."}},
	"Eye of Judgement": {"lore": "A floating eye ringed with wings. It sees every sin you've ever done and writes them down.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "The Ledger of Sins", "slot": "Off Hand", "type": "tome", "effect": "crit", "value": 18, "mat": "pale", "trim": "#ffffff", "flavor": "Your page is longer than you'd like."}},
	"Sky Serpent": {"lore": "A feathered snake that swims through clouds and eats storms.", "drops": ["Legs", "Weapon"],
		"sig": {"name": "Cloudscale Leggings", "slot": "Legs", "type": "leggings", "effect": "dodge", "value": 12, "mat": "sea", "trim": "#a9c6ee", "flavor": "Light as a cloud. Wet like one too."}},
	"Cherub": {"lore": "Small, chubby and armed with a bow. The arrows don't make you fall in love. They make you fall.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Cherub's Bow", "slot": "Weapon", "type": "bow", "effect": "double_strike", "value": 18, "mat": "gold", "trim": "#ffc6de", "flavor": "Adorable. Lethal."}},
	"Hymnbird": {"lore": "Birds that sing the Spire's hymns forever. Some say the song is holding the tower up.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "Hymnbird Feather Cap", "slot": "Helmet", "type": "cap", "effect": "regen", "value": 3, "mat": "cloth", "trim": "#7fb2e0", "flavor": "It hums when you're happy."}},
	"Executor": {"lore": "The angels' executioners. They don't hate you. They just think you're wrong.", "drops": ["Weapon", "Chest"],
		"sig": {"name": "The Executor's Verdict", "slot": "Weapon", "type": "axe", "effect": "crit", "value": 20, "mat": "steel", "trim": "#c0cbdc", "flavor": "Guilty. Next."}},
	"Sun Golem": {"lore": "A walking piece of the Sunforge. It glows so bright that looking at it hurts.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Sunforged Plate", "slot": "Chest", "type": "plate", "effect": "regen", "value": 3, "mat": "gold", "trim": "#fee761", "flavor": "Warm as a summer noon."}},
	"Throne Warden": {"lore": "The last guards before the Empyrean Gate. They've never had to fight. They're very excited.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Gatewarden's Aegis", "slot": "Off Hand", "type": "shield", "effect": "thorns", "value": 25, "mat": "gold", "trim": "#e8b14a", "flavor": "Polished every morning for a thousand years."}},
	# ---------- The Cinder Abyss (the demons) ----------
	"Imp": {"lore": "A small, giggling demon. It works for whoever paid it last, which is never you.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Imp's Pitchfork", "slot": "Weapon", "type": "spear", "effect": "double_strike", "value": 18, "mat": "ember", "trim": "#e43b44", "flavor": "Comes with a tiny invoice."}},
	"Hellmaw": {"lore": "A demon dog that's mostly mouth. It eats anything, then eats the thing that was eating it.", "drops": ["Legs", "Helmet"],
		"sig": {"name": "Hellmaw Jaw Helm", "slot": "Helmet", "type": "helm", "effect": "lifesteal", "value": 12, "mat": "bone", "trim": "#8e2e38", "flavor": "It still bites sometimes."}},
	"Chainwraith": {"lore": "Souls who sold themselves to demons, wrapped in the chains of their own contracts.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Shackles of the Bargain", "slot": "Off Hand", "type": "tome", "effect": "crit", "value": 18, "mat": "dark", "trim": "#8b9bb4", "flavor": "Read the fine print. All of it."}},
	"Brimstone Brute": {"lore": "A demon foot soldier made of stone and hate. It's not clever, but it doesn't need to be.", "drops": ["Weapon", "Chest"],
		"sig": {"name": "Brimstone Knuckles", "slot": "Weapon", "type": "mace", "effect": "double_strike", "value": 20, "mat": "ember", "trim": "#be4a2f", "flavor": "Smells like a struck match, forever."}},
	"Abyssal Worm": {"lore": "A worm big enough to tunnel through the Abyss's floors. Some say the realm is just the inside of one.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Wormhide Leggings", "slot": "Legs", "type": "leggings", "effect": "regen", "value": 3, "mat": "scale", "trim": "#68386c", "flavor": "Squishy. Unkillable."}},
	"Ash Fiend": {"lore": "A demon made of smoke from the Brimstone Wastes. Breathe in and it's inside you.", "drops": ["Helmet", "Chest"],
		"sig": {"name": "Ashen Shroud", "slot": "Chest", "type": "robe", "effect": "dodge", "value": 12, "mat": "dark", "trim": "#5a4a3e", "flavor": "It drifts even when there's no wind."}},
	"Chain Warden": {"lore": "Demon jailers who guard the bridges over the pit. They collect toll in teeth.", "drops": ["Off Hand", "Legs"],
		"sig": {"name": "Warden's Chainmail", "slot": "Legs", "type": "greaves", "effect": "thorns", "value": 25, "mat": "iron", "trim": "#5a6988", "flavor": "Rattles to warn you it's coming."}},
	"Soul Broker": {"lore": "A demon merchant who buys souls, sells souls and rents souls by the hour.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "The Broker's Ledger", "slot": "Off Hand", "type": "tome", "effect": "gold_find", "value": 30, "mat": "scale", "trim": "#9a4fc0", "flavor": "Your name's in here already."}},
	"Obsidian Knight": {"lore": "The Abyss's knights, armored in volcanic glass. They shatter loudly and come back together slowly.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Obsidian Carapace", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 25, "mat": "dark", "trim": "#262b44", "flavor": "Black glass. Sharp edges. No mirrors."}},
	"Hellborn Duke": {"lore": "A demon noble with a court of a hundred lesser demons and the manners of none of them.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Duke's Burning Circlet", "slot": "Helmet", "type": "crown", "effect": "lifesteal", "value": 12, "mat": "ember", "trim": "#a22633", "flavor": "Rank has its privileges. And its fires."}},
	# ---------- Realm bosses ----------
	"The Weeping Warden": {"lore": "The elves' last guardian. She failed to save them, and she has never stopped grieving.", "drops": [], "boss": true},
	"The Withered Queen": {"lore": "The last ruler of the elves, more ghost than woman now, still sitting on her throne of roots.", "drops": [], "boss": true},
	"The Jester of Thorns": {"lore": "The Fairy Queen's favorite fool. His jokes are terrible. His knives aren't.", "drops": [], "boss": true},
	"The Fairy Queen": {"lore": "The ruler of the Glimmer Court. She is beautiful, ancient, and bored, and you look like fun.", "drops": [], "boss": true},
	"Forgemaster Brann": {"lore": "The greatest smith the dwarves ever had. He's been forging one blade for a hundred years.", "drops": [], "boss": true},
	"High King Thrandor": {"lore": "King under the mountain. He has outlived three wives, six sons and every one of his enemies.", "drops": [], "boss": true},
	"Archon Valeth": {"lore": "The Spire's judge. She has weighed every soul that ever climbed the tower, and found most of them wanting.", "drops": [], "boss": true},
	"Seraphiel, the First Light": {"lore": "The oldest angel, made from the first sunrise. She remembers when the World Tree was a seed.", "drops": [], "boss": true},
	"Duke Malgrath": {"lore": "A demon duke who signs every deal in someone else's blood. He's never lost a bargain.", "drops": [], "boss": true},
	"Azgaroth, Lord of the Abyss": {"lore": "The demons' lord, sitting on a throne made of broken promises. He'd like yours too.", "drops": [], "boss": true},
}

# =====================================================================
# Portals: choosing which realm comes next
# =====================================================================

const PORTALS_SHOWN := 3

## Realm floors start a new realm here (the first floor of each realm slot).
static func is_realm_start(floor_num: int) -> bool:
	return GameData.realm_slot(floor_num) >= 0 and GameData.zone_floor(floor_num) == 1

## Which portals open for you, best matches first. Your race's home and its
## friends come first; your path adds some and locks others (but never all).
static func portal_options(g: GameState) -> Array:
	var rest: Array = []
	for id in IDS:
		if not id in g.realm_order:
			rest.append(id)
	if rest.size() <= 1:
		return rest
	var open: Array = []
	for id in rest:
		if lock_reason(g, id) == "":
			open.append(id)
	if open.is_empty():
		open = rest.duplicate()
	var score := {}
	for id in open:
		score[id] = _bias(g, id)
	open.sort_custom(func(a, b): return float(score[a]) > float(score[b]))
	return open.slice(0, PORTALS_SHOWN)

static func _bias(g: GameState, id: String) -> float:
	var inf := info(id)
	var b := Lineage.rep(g, inf["race"]) / 100.0
	if g.race() in inf["portal_bias"]:
		b += 2.0
	if id == "angel" and g.faith > 30.0:
		b += 1.0
	if id == "demon" and (g.faith < -30.0 or "demonic_disciple" in g.class_path):
		b += 1.0
	if id == "elf" and g.top_tag() == "Nature":
		b += 0.5
	return b + randf() * 0.3

## Why a portal is closed to you ("" = open).
static func lock_reason(g: GameState, id: String) -> String:
	var l: Dictionary = info(id).get("locks", {})
	if l.has("evil_below") and g.faith < float(l["evil_below"]):
		return "Too evil to enter"
	if l.has("good_above") and g.faith > float(l["good_above"]):
		return "Too good to enter"
	return ""

## Heroes already deep in (old saves, or after floor 500) get the realms they
## passed filled in, in the normal order, so nothing moves under their feet.
static func fill_order(g: GameState) -> void:
	var deepest := maxi(g.floor_num, g.best_floor)
	var need := 0
	if GameData.zone_rank(deepest) > 0:
		need = COUNT
	else:
		need = GameData.realm_slot(deepest) + 1 if GameData.realm_slot(deepest) >= 0 else 0
		if GameData.realm_slot(deepest) >= 0 and is_realm_start(deepest) and deepest == g.floor_num and g.fight <= 1:
			need -= 1  # standing on the first floor of a realm you haven't picked yet
	for id in IDS:
		if g.realm_order.size() >= need:
			break
		if not id in g.realm_order:
			g.realm_order.append(id)
	GameData.realm_order = g.realm_order

static func offer_portals(g: GameState) -> void:
	var opts := portal_options(g)
	if opts.size() <= 1:
		if opts.size() == 1:
			enter(g, opts[0])
		return
	g.path_offer.assign(opts.map(func(id): return "portal:" + id))
	g.path_wait = 0
	g.events.append({"type": "portals"})
	g.say("[color=#e8b14a]The roots split open. Portals to other realms shimmer in front of you.[/color]")
	g._page("realms")

static func enter(g: GameState, id: String) -> void:
	if not id in g.realm_order:
		g.realm_order.append(id)
	GameData.realm_order = g.realm_order
	var inf := info(id)
	var lv := Races.rep_level(Lineage.rep(g, inf["race"]))
	g.say("[color=%s]You step through into %s.[/color] The %s see you as [color=%s]%s[/color]." % [inf["color"], inf["name"], Lineage.race_plural(inf["race"]), lv[1], lv[0]])
	if not g.feats.get("seen_realm_" + id, 0):
		g.feats["seen_realm_" + id] = 1
		g.events.append({"type": "realm_enter", "id": id, "name": inf["name"], "blurb": inf["blurb"], "color": inf["color"],
			"mechanic": inf["mechanic"]["name"] + ": " + inf["mechanic"]["text"]})
	g.codex.add("realms_entered")
	g.spawn_enemy()
	g.save_game()

# =====================================================================
# Paths, encounters, the realm's own event, and camps
# =====================================================================

## Name, text and color for path choices that aren't in GameData.PATHS.
static func path_info(g: GameState, kind: String) -> Dictionary:
	if kind.begins_with("portal:"):
		var id := kind.substr(7)
		var inf := info(id)
		var lv := Races.rep_level(Lineage.rep(g, inf["race"]))
		return {"name": inf["name"], "text": "%s. The %s: %s.\n%s" % [inf["mechanic"]["name"], Lineage.race_plural(inf["race"]), lv[0], danger_text(g)], "color": inf["color"]}
	match kind:
		"talk":
			return {"name": "Talk", "text": "Friendly folk might help you. Hostile ones won't.", "color": "#4ade80"}
		"trade":
			return {"name": "Trade", "text": "They'll sell to friends (better prices the more they like you).", "color": "#e8b14a"}
		"attack":
			return {"name": "Attack", "text": "Fight them for their loot. They won't forget it.", "color": "#f87171"}
		"pass":
			return {"name": "Let them pass", "text": "Leave them be. They'll remember that too.", "color": "#cbd5e1"}
		"revent_yes":
			var ev: Dictionary = info(GameData.realm_of(g.floor_num)).get("event", {})
			return {"name": REALM_EVENT_YES.get(GameData.realm_of(g.floor_num), "Go closer"), "text": ev.get("text", ""), "color": "#c084fc"}
		"revent_no":
			return {"name": "Walk on", "text": "Some things are better left alone.", "color": "#cbd5e1"}
		"camp":
			var inf := info(GameData.realm_of(g.floor_num))
			return {"name": inf.get("camp", "Camp"), "text": "Rest, trade with %s, and check the quest board." % inf.get("merchant", "the locals"), "color": "#4ade80"}
	return {"name": kind.capitalize(), "text": "", "color": "#cbd5e1"}

## How hard the next realm's monsters hit you, compared to your health.
static func danger_text(g: GameState) -> String:
	var f := g.floor_num
	var atk := float(3 + f * 2) * pow(GameData.ENEMY_GROWTH, f - 1)
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

const REALM_EVENT_YES := {"elf": "Kneel and pray", "fairy": "Answer the riddle", "dwarf": "Use the anvil", "angel": "Face the choir", "demon": "Hear the offer"}

## The panel title for the current choice.
static func path_title(g: GameState) -> String:
	if g.path_offer.is_empty():
		return ""
	var k: String = g.path_offer[0]
	if k.begins_with("portal:"):
		return "Choose a realm"
	if k == "talk":
		return g.encounter.get("title", "Someone on the road")
	if k == "revent_yes":
		return info(GameData.realm_of(g.floor_num)).get("event", {}).get("name", "Something strange")
	if k == "cenc_yes":
		return String(ClassTree.ITEMS.get(g.class_encounter, {}).get("title", "Someone on the road"))
	return ""

## A meeting on the road (realms only): someone of the realm's race.
static func start_encounter(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	var race: String = info(id).get("race", Races.ORDER.pick_random())
	var who: Array = ENCOUNTERS.get(race, ["a traveler"])
	var rival := _rival_here(g, race)
	g.encounter = {"race": race, "who": who.pick_random() if rival.is_empty() else rival["name"], "rival": rival.get("name", "")}
	var lv := Races.rep_level(Lineage.rep(g, race))
	g.encounter["title"] = "You meet %s" % g.encounter["who"]
	var opts: Array = ["talk", "attack", "pass"]
	if Races.rep_index(Lineage.rep(g, race)) >= 3:
		opts.insert(1, "trade")
	g.path_offer.assign(opts)
	g.path_wait = 0
	g.say("[color=#e8b14a]On the road you meet %s.[/color] (The %s: [color=%s]%s[/color])" % [g.encounter["who"], Lineage.race_plural(race), lv[1], lv[0]])
	g.events.append({"type": "mini_event", "kind": "encounter", "title": "AN ENCOUNTER", "sub": String(g.encounter["who"]).capitalize()})
	g._page("reputation")

const ENCOUNTERS := {
	"Elf": ["an elf patrol of three ghosts", "a ghost archer still on watch", "a weeping elf child's ghost, lost on the path"],
	"Fairy": ["a fairy with a riddle and a grin", "a mushroom knight on a very serious quest", "a pixie who wants to sell you a hat"],
	"Dwarf": ["a dwarf smith on the road with a cart of tools", "a dwarf patrol in heavy plate", "an old dwarf miner, lost in the tunnels"],
	"Angel": ["an angel pilgrim climbing the stairs", "a choir sentinel on patrol", "a tired angel quartermaster counting feathers"],
	"Demon": ["a demon broker with a sly smile", "an imp selling 'genuine' relics", "a demon noble's tax collector"],
}

## Named rivals of other races who turn up across the realms.
const RIVALS := [
	{"name": "Sylwen the Last Archer", "race": "Elf", "art": "hollow_sentinel"},
	{"name": "Pip Thistlewhisk", "race": "Fairy", "art": "thornling"},
	{"name": "Brokk Ironjaw", "race": "Dwarf", "art": "forge_sentry"},
	{"name": "Seraphine of the Choir", "race": "Angel", "art": "choir_sentinel"},
	{"name": "Vex the Smiling", "race": "Demon", "art": "imp"},
]
const RIVAL_CHANCE := 0.3

static func _rival_here(g: GameState, race: String) -> Dictionary:
	if randf() > RIVAL_CHANCE:
		return {}
	for r in RIVALS:
		if r["race"] == race and r["race"] != g.race():
			return r
	return {}

static func encounter_choice(g: GameState, kind: String) -> void:
	var race: String = g.encounter.get("race", "")
	var who: String = g.encounter.get("who", "them")
	var rival: String = g.encounter.get("rival", "")
	var idx := Races.rep_index(Lineage.rep(g, race))
	ClassTree.on_encounter(g, kind, idx < 2)
	match kind:
		"talk":
			if idx >= 2 or ClassTree.charm_chance(g) * 5.0 > randf() * 100.0:
				var gold := (5 + g.floor_num * 4) * (1 + idx)
				g._add_gold(gold)
				Lineage.change_rep(g, race, 3.0 * week_mult(g))
				if rival != "" and idx >= 3:
					g.hero_hp = g.get_max_hp()
					g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
					g.say("[color=#4ade80]%s nods at you like an old friend, patches you up and shares a meal.[/color] +%d gold" % [rival, gold])
				else:
					g.say("[color=#4ade80]You talk with %s. They share news, a little coin and a warning about the road ahead.[/color] +%d gold" % [who, gold])
			else:
				g.say("[color=#f87171]%s doesn't want to talk. They draw steel![/color]" % who.capitalize())
				_ambush(g, race, rival)
		"trade":
			_make_camp_merchant(g, race)
			g.events.append({"type": "merchant"})
		"attack":
			Lineage.change_rep(g, race, -5.0)
			g.say("[color=#f87171]You attack %s.[/color]" % who)
			_ambush(g, race, rival)
		_:
			Lineage.change_rep(g, race, 1.5 * week_mult(g))
			g.say("You let %s pass. They watch you go." % who)
	g.encounter = {}

## The encounter turns into a fight: an elite of the realm's people.
static func _ambush(g: GameState, race: String, rival: String) -> void:
	if g.enemy_is_boss or g.enemy_goblin:
		return
	var z: Dictionary = GameData.zone_for_floor(g.floor_num)
	var people: Array = []
	for e in z["enemies"]:
		if e.get("people", false):
			people.append(e)
	if people.is_empty():
		return
	g.spawn_enemy()
	var def: Dictionary = people.pick_random()
	if rival != "":
		for r in RIVALS:
			if r["name"] == rival:
				g.enemy_art = r["art"]
		g.enemy_name = rival
		g.enemy_species = def["name"]
	else:
		g.enemy_species = def["name"]
		g.enemy_name = GameData.rank_prefix(g.floor_num) + def["name"]
		g.enemy_art = GameData.art_key(def["name"])
	g.enemy_people = race
	g.enemy_illusion = false
	g._apply_tier(Monsters.EPIC if rival == "" else Monsters.LEGENDARY)

## The realm's own event.
static func start_realm_event(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id == "":
		return
	g.path_offer.assign(["revent_yes", "revent_no"])
	g.path_wait = 0
	var ev: Dictionary = info(id)["event"]
	g.say("[color=#c084fc]%s[/color] %s" % [ev["name"], ev["text"]])
	g.events.append({"type": "mini_event", "kind": "realm_event", "title": String(ev["name"]).to_upper(), "sub": ev["text"]})

static func realm_event(g: GameState, yes: bool) -> void:
	var id := GameData.realm_of(g.floor_num)
	if not yes:
		g.say("You walk on.")
		return
	g.codex.add("realm_events")
	match id:
		"elf":
			if "warden" in g.class_path and not g.feats.get("world_tree", 0) and randf() < 0.5:
				g.feats["world_tree"] = 1
				g.say("[color=#4ade80]The dead tree knows a warden of the woods. Its bark warms under your hands: the World Tree's Blessing.[/color]")
			elif g.race() == "Elf" and not "World Tree's Blessing" in g.race_keys and g.awaken == 0 and randf() < 0.5:
				Lineage._give_key(g, "World Tree's Blessing")
				g.say("[color=#4ade80]The dead tree's bark warms under your hands. For one heartbeat, it remembers being alive. You have been blessed.[/color]")
			else:
				g.hero_hp = g.get_max_hp()
				g._faith(3.0)
				Lineage.gain(g, "skill:Nature", 40.0)
				g.say("[color=#4ade80]You kneel. The silence answers: your wounds close.[/color]")
			secret(g, id, "shrine")
		"fairy":
			if randf() < 0.6:
				var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), maxi(3, GameData.roll_rarity(30, GameData.LEGENDARY_CHANCE_BOSS)), g.floor_num, g._new_id())
				g.say("[color=#f9a8d4]\"Correct!\" the fairy laughs, and drops a gift in your hands.[/color]")
				g._give_item(item)
				secret(g, id, "riddle")
			else:
				var lost := int(g.gold * 0.1)
				g.gold -= lost
				g.confuse_turns = 0
				g.say("[color=#f9a8d4]\"Wrong!\" The fairy vanishes with %d of your gold, giggling.[/color]" % lost)
		"dwarf":
			var slots: Array = g.equipped.keys()
			slots.shuffle()
			for s in slots:
				var it: Dictionary = g.equipped[s]
				if int(it["level"]) < GameData.MAX_UPGRADE:
					it["level"] = int(it["level"]) + 1
					g.say("[color=#f59e0b]The anvil rings. Your %s glows: +1 upgrade![/color]" % GameData.display_name(it))
					Lineage.gain(g, "craft", 3.0)
					secret(g, id, "anvil")
					return
			g.say("The anvil hums, but your gear is already as good as it gets.")
		"angel":
			if g.faith > JUDGE_GOOD:
				g.hero_hp = g.get_max_hp()
				g.elixirs["rested"] = int(GameData.ELIXIRS["rested"]["turns"])
				Lineage.gain(g, "good", 10.0)
				g.say("[color=#fde68a]The choir sings your name. You are found worthy.[/color]")
				secret(g, id, "judged")
			elif g.faith < -JUDGE_GOOD:
				g.hero_hp = maxi(1, int(g.hero_hp * 0.6))
				g.say("[color=#f87171]The choir falls silent. Then light burns you for your sins.[/color]")
			else:
				g._add_gold((5 + g.floor_num * 4) * 3)
				g.say("[color=#fde68a]The choir can't decide about you. They give you a small coin for the road.[/color]")
		"demon":
			var cost := int(g.gold * 0.25)
			g.gold -= cost
			g._faith(-5.0)
			var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.LEGENDARY, g.floor_num, g._new_id())
			g.say("[color=#e43b44]\"Pleasure doing business.\" The devil takes %d gold... and something else you can't name.[/color]" % cost)
			g._give_item(item)
			secret(g, id, "bargain")

static func week_mult(g: GameState) -> float:
	return 2.0 if GameData.realm_of(g.floor_num) == realm_of_week() and realm_of_week() != "" else 1.0

## The realm of the week: double reputation and better loot there.
static func realm_of_week() -> String:
	var week := int(Time.get_unix_time_from_system() / 604800.0)
	return IDS[week % IDS.size()]

static func loot_bonus(g: GameState) -> int:
	return 10 if GameData.realm_of(g.floor_num) == realm_of_week() else 0

# ---------- Camps ----------

## The camp in the middle of each realm (after its mid boss).
static func offer_camp(g: GameState) -> void:
	g.path_offer.assign(["camp", "fight"])
	g.path_wait = 0

static func camp(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	g.hero_hp = g.get_max_hp()
	g.skill_cds.clear()
	g.say("[color=#4ade80]You rest at %s.[/color]" % info(id).get("camp", "the camp"))
	var rumor := Hidden.rumor(g)
	if rumor != "":
		g.say("[color=%s]Someone by the fire says:[/color] \"%s\"" % ["#c084fc", rumor])
	_make_camp_merchant(g, info(id).get("race", ""))
	ClassTree.on_camp(g, id)
	if g.quest.is_empty():
		new_quest(g)
	g.events.append({"type": "camp", "id": id})

## The race's merchant: realm gear, and race gear for friends.
static func _make_camp_merchant(g: GameState, race: String) -> void:
	g.merchant = []
	g.merchant_who = race
	var idx := Races.rep_index(Lineage.rep(g, race))
	var discount: float = [1.4, 1.2, 1.0, 1.0, 0.85, 0.7][idx]
	for _i in 2:
		var r := GameData.LEGENDARY if randf() * 100.0 < GameData.MERCHANT_LEGENDARY_CHANCE * 2.0 else 3
		var item := GameData.make_item(GameData.SLOT_ORDER.pick_random(), r, g.best_floor, g._new_id())
		g.merchant.append({"kind": "item", "item": item, "price": int(GameData.shop_price(item) * GameData.MERCHANT_PRICE_MULT * discount), "sold": false})
	if idx >= 4:
		for def in Races.gear_for(race):
			var item := Races.make_race_gear(def, g.best_floor, g._new_id())
			g.merchant.append({"kind": "item", "item": item, "price": int(GameData.shop_price(item) * 2.0 * discount), "sold": false})
	g.merchant.append({"kind": "scroll", "id": "box", "price": int(g._gold_scale() * 8 * discount), "sold": false})

# ---------- The quest board ----------

static func new_quest(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id == "":
		return
	var race: String = info(id)["race"]
	var need := 30
	g.quest = {"realm": id, "race": race, "need": need, "have": 0,
		"text": "The %s ask you to clear %d beasts (not their people) from %s." % [Lineage.race_plural(race), need, info(id)["name"]]}
	g.say("[color=#e8b14a]Quest:[/color] %s" % g.quest["text"])

static func quest_kill(g: GameState) -> void:
	if g.quest.is_empty() or g.enemy_people != "" or GameData.realm_of(g.floor_num) != String(g.quest["realm"]):
		return
	g.quest["have"] = int(g.quest["have"]) + 1
	if int(g.quest["have"]) >= int(g.quest["need"]):
		var race: String = g.quest["race"]
		Lineage.change_rep(g, race, 8.0 * week_mult(g))
		var gold := (5 + g.floor_num * 6) * 5
		g._add_gold(gold)
		g.say("[color=#4ade80]Quest done! The %s are grateful.[/color] +%d gold" % [Lineage.race_plural(race), gold])
		g.codex.add("quests")
		ClassTree.count(g, "quests")
		g.quest = {}

# ---------- Secrets and completion ----------

const SECRETS := {
	"elf": ["shrine", "hidden_path", "exalted"],
	"fairy": ["riddle", "hidden_path", "exalted"],
	"dwarf": ["anvil", "hidden_path", "exalted"],
	"angel": ["judged", "hidden_path", "exalted"],
	"demon": ["bargain", "hidden_path", "exalted"],
}
const HIDDEN_PATH_FLOOR := 37   # realm floor where friends find a hidden path

static func secret(g: GameState, id: String, key: String) -> void:
	var k := "secret_%s_%s" % [id, key]
	if not g.feats.get(k, 0):
		g.feats[k] = 1
		g.codex.add("secrets")
		ClassTree.count(g, "secrets")
		g.say("[color=#c084fc]Secret found! (%d / %d in %s)[/color]" % [secrets_found(g, id), SECRETS[id].size(), realm_name(id)])

static func secrets_found(g: GameState, id: String) -> int:
	var n := 0
	for s in SECRETS.get(id, []):
		if g.feats.get("secret_%s_%s" % [id, s], 0):
			n += 1
	return n

## A new floor in a realm: hidden paths for friends, the realm's spirit for the Exalted.
static func on_floor(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id == "":
		return
	var race: String = info(id)["race"]
	var idx := Races.rep_index(Lineage.rep(g, race))
	if GameData.zone_floor(g.floor_num) == HIDDEN_PATH_FLOOR and (idx >= 3 or ClassTree.scout_bonus(g) >= 30.0):
		ClassTree.count(g, "hidden_paths")
		var g2 := (5 + g.floor_num * 6) * 4
		g._add_gold(g2)
		g._give_item(GameData.make_item(GameData.SLOT_ORDER.pick_random(), GameData.LEGENDARY, g.floor_num, g._new_id()))
		g.say("[color=#c084fc]The %s show you a hidden path only friends know. It leads to an old treasure.[/color] +%d gold" % [Lineage.race_plural(race), g2])
		secret(g, id, "hidden_path")

## Exalted heroes sometimes meet the realm's spirit: a Mythic of its people.
static func maybe_spirit(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id == "" or g.enemy_is_boss or g.enemy_goblin or g.horde_left > 0:
		return
	if Races.rep_index(Lineage.rep(g, info(id)["race"])) < 5 or randf() > 0.02:
		return
	g._apply_tier(Monsters.MYTHIC)
	g.enemy_name = "Spirit of " + realm_name(id).trim_prefix("The ")
	g.feats["spirit_" + id] = 1
	g.say("[color=#e8b14a]Because they trust you, the realm shows you its spirit. It wants to test you.[/color]")

static func on_spirit_kill(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id != "" and g.feats.get("spirit_" + id, 0) and g.enemy_name.begins_with("Spirit of"):
		ClassTree.count(g, "spirits")
		secret(g, id, "exalted")

## 0-100: how much of a realm you've done.
static func completion(g: GameState, id: String) -> int:
	var z: Dictionary = GameData.ZONES[zone_for_id(id)]
	var mons: Array = []
	for e in z["enemies"]:
		mons.append(e["name"])
	for s in z["subs"]:
		mons.append(s["monster"]["name"])
	var seen := 0
	for m in mons:
		if g.codex.seen(m):
			seen += 1
	var parts := 0.0
	parts += float(seen) / mons.size() * 25.0
	parts += clampf((Lineage.rep(g, info(id)["race"]) + 20.0) / 120.0, 0.0, 1.0) * 25.0
	parts += float(secrets_found(g, id)) / SECRETS[id].size() * 20.0
	var uniq := 0
	var all_u: Array = GameData.zone_uniques(zone_for_id(id))
	for u in all_u:
		if g.codex.collection.has(u["name"]):
			uniq += 1
	parts += float(uniq) / maxf(1.0, all_u.size()) * 15.0
	parts += (7.5 if g.codex.kills(z["mid"]["name"]) > 0 else 0.0) + (7.5 if g.codex.kills(z["boss"]["name"]) > 0 else 0.0)
	return int(round(parts))

## The first time you set foot in a realm (however you got there): its entrance scene.
static func note_seen(g: GameState) -> void:
	var id := GameData.realm_of(g.floor_num)
	if id == "" or g.feats.get("seen_realm_" + id, 0):
		return
	if not g.path_offer.is_empty() and String(g.path_offer[0]).begins_with("portal:"):
		return  # you're choosing a portal: the realm isn't decided yet
	if not id in g.realm_order and GameData.realm_slot(g.floor_num) == g.realm_order.size():
		g.realm_order.append(id)
		GameData.realm_order = g.realm_order
	g.feats["seen_realm_" + id] = 1
	var inf := info(id)
	g.events.append({"type": "realm_enter", "id": id, "name": inf["name"], "blurb": inf["blurb"], "color": inf["color"],
		"mechanic": inf["mechanic"]["name"] + ": " + inf["mechanic"]["text"]})
