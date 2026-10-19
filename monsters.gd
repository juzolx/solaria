class_name Monsters
extends RefCounted
## Everything about the creatures themselves: their lore for the Bestiary,
## which gear they like to drop, their 1-in-1,000 Signature items, monster
## tiers (Common to Mythic) and the modifiers rare monsters roll.
## Which monsters live where is in GameData.ZONES.

# ---------- Monster tiers ----------
# weight: spawn chance in % (adds up to 100). Higher tiers are bigger, tougher,
# roll more modifiers and pay out much better.
const TIER_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const TIERS := [
	{"color": "#cbd5e1", "weight": 60.0, "hp": 1.0, "atk": 1.0, "scale": 1.0, "mods": 0, "gold": 1.0, "xp": 1.0, "loot": 0, "extra": 0, "mats": [0, 0]},
	{"color": "#4ade80", "weight": 25.0, "hp": 1.35, "atk": 1.12, "scale": 1.06, "mods": 1, "gold": 1.6, "xp": 1.5, "loot": 4, "extra": 0, "mats": [0, 0]},
	{"color": "#60a5fa", "weight": 10.0, "hp": 2.0, "atk": 1.25, "scale": 1.12, "mods": 1, "gold": 2.5, "xp": 2.2, "loot": 9, "extra": 1, "mats": [1, 2]},
	{"color": "#c084fc", "weight": 3.5, "hp": 3.2, "atk": 1.4, "scale": 1.2, "mods": 2, "gold": 4.0, "xp": 3.5, "loot": 15, "extra": 1, "mats": [1, 2]},
	{"color": "#fb923c", "weight": 1.0, "hp": 4.5, "atk": 1.6, "scale": 1.28, "mods": 3, "gold": 7.0, "xp": 5.0, "loot": 22, "extra": 2, "mats": [1, 2]},
	{"color": "#ff4d6d", "weight": 0.5, "hp": 6.5, "atk": 1.8, "scale": 1.36, "mods": 4, "gold": 12.0, "xp": 8.0, "loot": 30, "extra": 3, "mats": [2, 2]},
]
const RARE := 2
const EPIC := 3
const LEGENDARY := 4
const MYTHIC := 5
const HARDCORE_RARE_BONUS := 1.5  # Hardcore: Rare and better spawn 50% more often

# ---------- Modifiers ----------
# kind: "stat" (just tougher), "nasty" (hurts you), "tricky" (messes with you)
const MODS := {
	"Swift": {"kind": "stat", "color": "#7dd3fc", "text": "Attacks twice 30% of the time"},
	"Armored": {"kind": "stat", "color": "#94a3b8", "text": "Takes 25% less damage"},
	"Giant": {"kind": "stat", "color": "#fbbf24", "text": "50% more health, bigger"},
	"Vampiric": {"kind": "nasty", "color": "#f87171", "text": "Heals for 30% of the damage it deals"},
	"Thorny": {"kind": "nasty", "color": "#a3e635", "text": "Reflects 10% of your damage"},
	"Burning": {"kind": "nasty", "color": "#fb923c", "text": "Sets you on fire: 2% of your max HP every turn"},
	"Enraged": {"kind": "nasty", "color": "#ef4444", "text": "Hits 40% harder below half health"},
	"Teleporting": {"kind": "tricky", "color": "#c084fc", "text": "Blinks away from 20% of your attacks"},
	"Shielded": {"kind": "tricky", "color": "#60a5fa", "text": "A shield soaks up the first 25% of its health"},
	"Venomous": {"kind": "nasty", "color": "#a3e635", "text": "Its hits can poison you (Wisdom resists)"},
	"Frigid": {"kind": "nasty", "color": "#7fd0f0", "text": "Its hits can chill you: -25% Attack for a while (Wisdom resists)"},
	"Explosive": {"kind": "nasty", "color": "#fb923c", "text": "Explodes when it dies, for 12% of your max HP (dodge it)"},
	"Regenerating": {"kind": "stat", "color": "#4ade80", "text": "Heals 3% of its health every turn"},
	"Elemental": {"kind": "tricky", "color": "#c084fc", "text": "Resists one more element than usual"},
}

# ---------- Signature items ----------
const SIGNATURE_CHANCE := 1000  # 1 in this many kills of that monster. No pity.
const SIGNATURE := 7            # rarity number of a Signature item

# ---------- Monster info ----------
# lore: one line for the Bestiary. drops: the 2 gear slots it favors.
# sig: its Signature item (mat/trim pick the colors of the item's sprite).
const INFO := {
	# ----- 0.13+ myth monsters -----
	"Hobyah": {"lore": "Goblin-dogs from an old Scottish tale. They creep up at night shouting 'Tear down the hemp stalks!' and only a barking dog keeps them away.", "drops": ["Feet", "Helmet"],
		"sig": {"name": "Hobyah Hemp-Boots", "slot": "Feet", "type": "boots", "effect": "dodge", "value": 14, "mat": "hide", "trim": "#a16207", "flavor": "They creak like hemp stalks. Nothing can hear you coming."}},
	"Jack-in-Irons": {"lore": "A giant who walks the lonely roads of Yorkshire dragging the chains he broke. He takes the heads of travelers out after dark.", "drops": ["Chest", "Weapon"],
		"sig": {"name": "Jack's Broken Chain", "slot": "Weapon", "type": "mace", "effect": "double_strike", "value": 23, "mat": "iron", "trim": "#9ca3af", "flavor": "Every link of it was snapped by a giant's pull."}},
	"Ankou": {"lore": "The Breton reaper: the last person to die each year must drive the death-cart for the next. The axle creaks before it arrives.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "The Ankou's Scythe-Spear", "slot": "Weapon", "type": "spear", "effect": "lifesteal", "value": 14, "mat": "bone", "trim": "#e5e7eb", "flavor": "The axle of the death-cart, sharpened."}},
	"Bog Body": {"lore": "The peat keeps the dead whole. Some were put there on purpose, with a rope or a stone, and they have not forgiven anyone.", "drops": ["Legs", "Chest"],
		"sig": {"name": "Peat-Wrapped Leggings", "slot": "Legs", "type": "leggings", "effect": "regen", "value": 3, "mat": "hide", "trim": "#78716c", "flavor": "The bog kept their owner whole for two thousand years. It will keep you a while longer."}},
	"Ningyo": {"lore": "A fish with a woman's face. Eating its flesh grants a long, long life, and the sea always comes to collect.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Ningyo Scale", "slot": "Off Hand", "type": "orb", "effect": "regen", "value": 3, "mat": "sea", "trim": "#5eead4", "flavor": "A single scale is enough to add years. The sea counts them."}},
	"Afanc": {"lore": "A Welsh lake monster that drags anyone into the water. It was chained once, by oxen, but the chains are old now.", "drops": ["Off Hand", "Legs"],
		"sig": {"name": "Afanc Shell", "slot": "Off Hand", "type": "shield", "effect": "thorns", "value": 30, "mat": "scale", "trim": "#365314", "flavor": "Oxen could not drag it. Monsters will not get through it."}},
	"Gullinbursti": {"lore": "The boar with golden bristles that shine in the darkest place. In the deep it lights the way for no one but itself.", "drops": ["Chest", "Feet"],
		"sig": {"name": "Golden-Bristle Mantle", "slot": "Chest", "type": "plate", "effect": "gold_find", "value": 32, "mat": "gold", "trim": "#fbbf24", "flavor": "It glows in the dark, and gold seems to notice."}},
	"Div": {"lore": "A Persian demon made of smoke and spite. It breaks oaths and wrecks walls, and laughs in a voice like a fire catching.", "drops": ["Weapon", "Off Hand"],
		"sig": {"name": "Smoke-Oath Dagger", "slot": "Weapon", "type": "dagger", "effect": "crit", "value": 24, "mat": "dark", "trim": "#9ca3af", "flavor": "Sworn on, it breaks every promise but the one you make with it."}},
	"Mare": {"lore": "The night-rider who sits on sleepers' chests. Down here nobody sleeps, so it rides whoever is closest.", "drops": ["Helmet", "Legs"],
		"sig": {"name": "Night-Rider's Hood", "slot": "Helmet", "type": "hood", "effect": "crit", "value": 22, "mat": "cloth", "trim": "#4c1d95", "flavor": "Wear it and others dream of you. They don't enjoy it."}},
	"Baku": {"lore": "The dream-eater with an elephant's trunk. Once it ate nightmares. In the Shadow Deep there are only nightmares, and it is very hungry.", "drops": ["Chest", "Feet"],
		"sig": {"name": "Dream-Eater's Robe", "slot": "Chest", "type": "robe", "effect": "lifesteal", "value": 13, "mat": "dark", "trim": "#334155", "flavor": "It feeds on nightmares. Down here it never goes hungry."}},
	# ----- Mossy Hollows -----
	"Kobold": {"lore": "German mine spirits that steal ore and leave poisoned rock behind.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Kobold's Candlehelm", "slot": "Helmet", "type": "helm", "effect": "gold_find", "value": 30, "mat": "iron", "trim": "#feae34", "flavor": "The candle has burned since the first mine was dug."}},
	"Redcap": {"lore": "Border goblins who dye their caps in travelers' blood. If the cap dries out, they die.", "drops": ["Helmet", "Feet"],
		"sig": {"name": "The Red Cap", "slot": "Helmet", "type": "cap", "effect": "lifesteal", "value": 12, "mat": "leather", "trim": "#e43b44", "flavor": "Still wet. It will always be wet."}},
	"Boggart": {"lore": "A house spirit turned sour. Never give one a name, or it can't be reasoned with.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Boggart's Patchcoat", "slot": "Chest", "type": "tunic", "effect": "thorns", "value": 25, "mat": "hide", "trim": "#c28569", "flavor": "Sewn from the coats of everyone it chased out."}},
	"Will-o'-Wisp": {"lore": "Lights over the marsh that lead travelers off the safe path.", "drops": ["Off Hand", "Weapon"],
		"sig": {"name": "Lantern of the Lost", "slot": "Off Hand", "type": "orb", "effect": "dodge", "value": 12, "mat": "crystal", "trim": "#7dd3fc", "flavor": "Follow it and you'll never be found."}},
	"Barghest": {"lore": "A black dog as big as a calf with eyes like coals. Seeing one is an omen.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Barghest Fang", "slot": "Weapon", "type": "dagger", "effect": "crit", "value": 22, "mat": "bone", "trim": "#ff4a4a", "flavor": "It still growls when you draw it."}},
	"Spriggan": {"lore": "Cornish fairy guards that swell to giant size when their treasure is threatened.", "drops": ["Off Hand", "Chest"],
		"sig": {"name": "Spriggan Barkshield", "slot": "Off Hand", "type": "shield", "effect": "thorns", "value": 28, "mat": "wood", "trim": "#63c74d", "flavor": "It grows back every time it's split."}},
	"Pooka": {"lore": "An Irish shapeshifter that offers wild rides on its back. Riders never come back the same.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Pooka's Midnight Treads", "slot": "Feet", "type": "boots", "effect": "dodge", "value": 14, "mat": "dark", "trim": "#fee761", "flavor": "They only leave hoofprints."}},
	"Wolpertinger": {"lore": "A Bavarian horned hare with wings. Hunters only find it under a full moon.", "drops": ["Helmet", "Weapon"],
		"sig": {"name": "Antlered Crown", "slot": "Helmet", "type": "crown", "effect": "double_strike", "value": 20, "mat": "gold", "trim": "#e8b8f0", "flavor": "Nobody believes you when you tell them where you got it."}},
	"Leshy": {"lore": "The Slavic lord of the forest. It can be tall as a pine or small as a blade of grass.", "drops": ["Weapon", "Chest"],
		"sig": {"name": "Leshy's Crook", "slot": "Weapon", "type": "staff", "effect": "regen", "value": 3, "mat": "wood", "trim": "#a8ca58", "flavor": "Moss grows wherever you plant it."}},
	"Woodwose": {"lore": "The hairy wild man of the woods, carved on old churches as a warning.", "drops": ["Weapon", "Legs"],
		"sig": {"name": "Wildman's Club", "slot": "Weapon", "type": "mace", "effect": "lifesteal", "value": 12, "mat": "hide", "trim": "#c28569", "flavor": "A whole oak root, ripped out by hand."}},
	# ----- Sunken Catacombs -----
	"Ghoul": {"lore": "Desert grave-robbers that take the shape of the last thing they ate.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Ghoul-Stitched Robe", "slot": "Chest", "type": "robe", "effect": "lifesteal", "value": 12, "mat": "pale", "trim": "#a8ca58", "flavor": "Every stitch is someone's last meal."}},
	"Draugr": {"lore": "Norse dead who guard their burial mounds and grow heavier than an ox.", "drops": ["Chest", "Helmet"],
		"sig": {"name": "Barrow-King's Helm", "slot": "Helmet", "type": "helm", "effect": "thorns", "value": 30, "mat": "iron", "trim": "#7dd3fc", "flavor": "Frost forms on it even in summer."}},
	"Barrow-Wight": {"lore": "A cold spirit of old barrows. Its touch steals your will to move.", "drops": ["Off Hand", "Feet"],
		"sig": {"name": "Gravecold Buckler", "slot": "Off Hand", "type": "buckler", "effect": "dodge", "value": 12, "mat": "pale", "trim": "#c0cbdc", "flavor": "Blows slow down as they reach it."}},
	"Banshee": {"lore": "Her wail warns a family that one of them will soon die.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "Keening Veil", "slot": "Helmet", "type": "hood", "effect": "crit", "value": 20, "mat": "cloth", "trim": "#e9d5ff", "flavor": "You can hear her singing when it's quiet."}},
	"Strigoi": {"lore": "Romanian restless dead who rise at night to drain the living.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Strigoi's Kiss", "slot": "Weapon", "type": "dagger", "effect": "lifesteal", "value": 14, "mat": "dark", "trim": "#9f1239", "flavor": "Thin as a fang and twice as thirsty."}},
	"Revenant": {"lore": "A corpse that crawls out of its grave to settle an old score.", "drops": ["Weapon", "Legs"],
		"sig": {"name": "Grudgeblade", "slot": "Weapon", "type": "sword", "effect": "double_strike", "value": 22, "mat": "iron", "trim": "#a8ca58", "flavor": "It remembers every enemy you've ever had."}},
	"Gashadokuro": {"lore": "A giant skeleton made from the bones of the starved. Your ears ring when it's near.", "drops": ["Chest", "Weapon"],
		"sig": {"name": "Ribcage Plate", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 30, "mat": "bone", "trim": "#e8e4d8", "flavor": "A hundred ribs, all still hungry."}},
	"Vetala": {"lore": "A spirit that lives in corpses and asks riddles. Answer wrong and it laughs.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Riddler's Tome", "slot": "Off Hand", "type": "tome", "effect": "crit", "value": 22, "mat": "leather", "trim": "#c084fc", "flavor": "Every page asks a question. None give answers."}},
	"Moroi": {"lore": "A pale ghost that feeds on the strength of the living.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Moroi Shroudwraps", "slot": "Legs", "type": "leggings", "effect": "regen", "value": 3, "mat": "pale", "trim": "#8b9bb4", "flavor": "Woven from strength that wasn't yours."}},
	"Garmr": {"lore": "The blood-soaked hound that guards the gates of Hel.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Gatehound Spear", "slot": "Weapon", "type": "spear", "effect": "crit", "value": 24, "mat": "dark", "trim": "#e43b44", "flavor": "Tipped with one of Garm's own teeth."}},
	# ----- Flooded Depths -----
	"Kappa": {"lore": "River imps with a dish of water on their heads. Bow, and they'll bow back and spill it.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Kappa Shell", "slot": "Off Hand", "type": "buckler", "effect": "thorns", "value": 28, "mat": "scale", "trim": "#63c74d", "flavor": "Smells faintly of cucumbers."}},
	"Kelpie": {"lore": "A water horse that drowns anyone who climbs on its back.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Kelpie-Hide Boots", "slot": "Feet", "type": "boots", "effect": "dodge", "value": 14, "mat": "sea", "trim": "#a4dddb", "flavor": "Always damp. Always fast."}},
	"Nuckelavee": {"lore": "The skinless horse-demon of Orkney. Fresh water is its only weakness.", "drops": ["Weapon", "Chest"],
		"sig": {"name": "Skinless Cleaver", "slot": "Weapon", "type": "axe", "effect": "lifesteal", "value": 14, "mat": "iron", "trim": "#be123c", "flavor": "Don't think about what the grip is wrapped in."}},
	"Bunyip": {"lore": "Something big in the billabong. Its roar shakes the reeds at night.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Billabong Hide", "slot": "Chest", "type": "tunic", "effect": "regen", "value": 3, "mat": "hide", "trim": "#a16207", "flavor": "Nobody has ever seen the whole animal."}},
	"Umibozu": {"lore": "A giant shadow that rises from calm seas and asks sailors for a barrel.", "drops": ["Off Hand", "Helmet"],
		"sig": {"name": "Stillwater Orb", "slot": "Off Hand", "type": "orb", "effect": "dodge", "value": 13, "mat": "sea", "trim": "#4c6ef5", "flavor": "The sea goes flat around it."}},
	"Selkie": {"lore": "Seal-folk who shed their skins to walk on land, and always go back to the sea.", "drops": ["Chest", "Feet"],
		"sig": {"name": "Selkie Pelt", "slot": "Chest", "type": "robe", "effect": "dodge", "value": 14, "mat": "sea", "trim": "#c0cbdc", "flavor": "Someone, somewhere, is looking for this."}},
	"Vodyanoy": {"lore": "A frog-faced old man of the millponds who keeps drowned souls in teacups.", "drops": ["Off Hand", "Legs"],
		"sig": {"name": "Teacup of Souls", "slot": "Off Hand", "type": "orb", "effect": "lifesteal", "value": 12, "mat": "coral", "trim": "#a8ca58", "flavor": "Put your ear to it. Someone's talking."}},
	"Merrow": {"lore": "Irish merfolk. Steal a merrow's red cap and it can never go back to the sea.", "drops": ["Helmet", "Weapon"],
		"sig": {"name": "Merrow's Red Cap", "slot": "Helmet", "type": "cap", "effect": "gold_find", "value": 35, "mat": "coral", "trim": "#e43b44", "flavor": "Finders keepers."}},
	"Grindylow": {"lore": "Long-armed water demons that grab anyone who plays too near the edge.", "drops": ["Weapon", "Legs"],
		"sig": {"name": "Grasping Trident", "slot": "Weapon", "type": "spear", "effect": "double_strike", "value": 22, "mat": "sea", "trim": "#63c74d", "flavor": "The prongs curl in, like fingers."}},
	"Ahuizotl": {"lore": "An Aztec water-dog with a hand on the end of its tail. It drags fishermen under.", "drops": ["Weapon", "Feet"],
		"sig": {"name": "Drowner's Hook", "slot": "Weapon", "type": "dagger", "effect": "crit", "value": 24, "mat": "coral", "trim": "#2ce8f5", "flavor": "Bent like a beckoning finger."}},
	# ----- Ember Halls -----
	"Salamander": {"lore": "Alchemists said it is born from fire and can live inside it.", "drops": ["Off Hand", "Feet"],
		"sig": {"name": "Salamander Sandals", "slot": "Feet", "type": "sandals", "effect": "regen", "value": 3, "mat": "ember", "trim": "#fee761", "flavor": "Walk on coals. Your feet won't mind."}},
	"Ifrit": {"lore": "A djinn of smokeless fire, proud and quick to anger.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Smokeless Scimitar", "slot": "Weapon", "type": "sword", "effect": "crit", "value": 24, "mat": "gold", "trim": "#f77622", "flavor": "It burns without a single wisp of smoke."}},
	"Hellhound": {"lore": "Hounds that guard the underworld and track souls by smell.", "drops": ["Feet", "Legs"],
		"sig": {"name": "Hellhound Greaves", "slot": "Legs", "type": "greaves", "effect": "thorns", "value": 30, "mat": "dark", "trim": "#f77622", "flavor": "Anything that bites them gets burned."}},
	"Chimera": {"lore": "Lion, goat and snake in one body, and all three breathe fire.", "drops": ["Chest", "Weapon"],
		"sig": {"name": "Three-Beast Plate", "slot": "Chest", "type": "plate", "effect": "double_strike", "value": 22, "mat": "gold", "trim": "#a8ca58", "flavor": "Three heads are better than one."}},
	"Manticore": {"lore": "A lion with a man's face and a tail full of poison spikes.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Manticore Quill Bow", "slot": "Weapon", "type": "bow", "effect": "crit", "value": 25, "mat": "ember", "trim": "#d9480f", "flavor": "Fires its spikes. They grow back."}},
	"Cherufe": {"lore": "A magma giant from the volcanoes of Chile, made of rock and fire.", "drops": ["Chest", "Legs"],
		"sig": {"name": "Cinder Mantle", "slot": "Chest", "type": "tunic", "effect": "thorns", "value": 32, "mat": "ember", "trim": "#feae34", "flavor": "Still glowing, deep in the weave."}},
	"Cyclops": {"lore": "One-eyed giant smiths who forged Zeus's thunderbolts.", "drops": ["Weapon", "Off Hand"],
		"sig": {"name": "Thunderforge Hammer", "slot": "Weapon", "type": "mace", "effect": "double_strike", "value": 24, "mat": "iron", "trim": "#7fe9ff", "flavor": "Sparks fly when it lands, every time."}},
	"Firebird": {"lore": "A glowing bird whose single feather can light a whole hall.", "drops": ["Helmet", "Off Hand"],
		"sig": {"name": "Firebird Plume", "slot": "Helmet", "type": "crown", "effect": "regen", "value": 3, "mat": "gold", "trim": "#ff8a3a", "flavor": "Brighter than any torch."}},
	"Tatzelwurm": {"lore": "An Alpine worm with a cat's head and poisonous breath.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Wurmskin Leggings", "slot": "Legs", "type": "leggings", "effect": "dodge", "value": 14, "mat": "scale", "trim": "#c28569", "flavor": "They purr when you sit down."}},
	"Basilisk": {"lore": "The king of serpents. Its gaze turns living things to stone.", "drops": ["Off Hand", "Weapon"],
		"sig": {"name": "Basilisk Eye", "slot": "Off Hand", "type": "orb", "effect": "crit", "value": 25, "mat": "crystal", "trim": "#a8ca58", "flavor": "Don't look into it. Seriously."}},
	# ----- The Shadow Deep -----
	"Wendigo": {"lore": "Hunger in the shape of a gaunt giant. The more it eats, the bigger it grows.", "drops": ["Chest", "Weapon"],
		"sig": {"name": "Hunger's Antler Axe", "slot": "Weapon", "type": "axe", "effect": "lifesteal", "value": 15, "mat": "bone", "trim": "#c0cbdc", "flavor": "Always hungry. Always."}},
	"Jorogumo": {"lore": "A spider that becomes a beautiful woman and plays music to lure her prey.", "drops": ["Off Hand", "Legs"],
		"sig": {"name": "Silkweaver Leggings", "slot": "Legs", "type": "leggings", "effect": "dodge", "value": 15, "mat": "cloth", "trim": "#8b5cf6", "flavor": "Light as a web, strong as one too."}},
	"Rakshasa": {"lore": "Shape-shifting demons whose hands are on backwards.", "drops": ["Helmet", "Chest"],
		"sig": {"name": "Backhand Crown", "slot": "Helmet", "type": "crown", "effect": "double_strike", "value": 24, "mat": "gold", "trim": "#f59e0b", "flavor": "Worn the wrong way round, on purpose."}},
	"Lamia": {"lore": "A queen cursed into a serpent, who can take out her own eyes.", "drops": ["Off Hand", "Feet"],
		"sig": {"name": "Lamia's Mirror", "slot": "Off Hand", "type": "shield", "effect": "thorns", "value": 32, "mat": "scale", "trim": "#a8ca58", "flavor": "It shows you what you'll lose."}},
	"Gorgon": {"lore": "Snakes for hair and a stare that turns you to stone.", "drops": ["Helmet", "Weapon"],
		"sig": {"name": "Snakelock Hood", "slot": "Helmet", "type": "hood", "effect": "crit", "value": 25, "mat": "scale", "trim": "#63c74d", "flavor": "Something moves under the hood."}},
	"Kitsune": {"lore": "A fox spirit. Every hundred years it grows another tail.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Ninetail Bow", "slot": "Weapon", "type": "bow", "effect": "crit", "value": 26, "mat": "gold", "trim": "#f77622", "flavor": "Nine strings, nine arrows, one shot."}},
	"Tikbalang": {"lore": "A horse-headed trickster that makes travelers walk in circles.", "drops": ["Legs", "Feet"],
		"sig": {"name": "Tikbalang Hooves", "slot": "Feet", "type": "sabatons", "effect": "dodge", "value": 15, "mat": "dark", "trim": "#c28569", "flavor": "You'll never get lost again. Probably."}},
	"Doppelganger": {"lore": "Your double. Meeting it means your time is running short.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Mirrorself Mantle", "slot": "Chest", "type": "robe", "effect": "lifesteal", "value": 15, "mat": "dark", "trim": "#c0cbdc", "flavor": "Sometimes it moves a moment after you do."}},
	"Krampus": {"lore": "The horned shadow of winter, who carries a birch switch for the wicked.", "drops": ["Weapon", "Helmet"],
		"sig": {"name": "Birch Switch", "slot": "Weapon", "type": "staff", "effect": "double_strike", "value": 25, "mat": "wood", "trim": "#e43b44", "flavor": "Bad children know this sound."}},
	"Bakunawa": {"lore": "A sea serpent so big it tries to swallow the moon.", "drops": ["Chest", "Off Hand"],
		"sig": {"name": "Moon-Eater Scale", "slot": "Chest", "type": "plate", "effect": "regen", "value": 4, "mat": "scale", "trim": "#c0cbdc", "flavor": "It glows faintly at night, like a stolen moon."}},
	# ----- Mid bosses -----
	"Black Annis": {"lore": "A blue-faced hag of the Dane Hills who hangs her victims' skins in an old oak.", "drops": [], "boss": true},
	"The Dullahan": {"lore": "The headless rider. When he stops, someone dies. He carries his own head.", "drops": [], "boss": true},
	"Scylla": {"lore": "Six heads on six long necks. Sailors who pass her lose one man per head.", "drops": [], "boss": true},
	"Fafnir": {"lore": "A dwarf turned into a dragon by greed, sleeping on cursed gold.", "drops": [], "boss": true},
	"Echidna": {"lore": "Half woman, half serpent: the mother of every monster you've fought.", "drops": [], "boss": true},
	# ----- Zone bosses -----
	"Grendel": {"lore": "The monster of Beowulf. He hated the sound of feasting in the hall.", "drops": [], "boss": true},
	"Hel, Queen of the Dead": {"lore": "Loki's daughter, half living and half dead, who rules everyone who dies of old age.", "drops": [], "boss": true},
	"Charybdis": {"lore": "A whirlpool with a mouth. She swallows the sea three times a day.", "drops": [], "boss": true},
	"Surtr the Fire Giant": {"lore": "The fire giant who will burn the world at Ragnarok.", "drops": [], "boss": true},
	"Typhon, Father of Monsters": {"lore": "The deadliest monster of Greek myth, with a hundred dragon heads.", "drops": [], "boss": true},
}

# ---------- Bestiary milestones ----------
# Kills of one monster -> bonus damage and gold against that monster (in %)
const MILESTONES := [[10, 2], [100, 4], [500, 7], [1000, 10]]

static func info(monster: String) -> Dictionary:
	if INFO.has(monster):
		return INFO[monster]
	for w in Wanderers.LIST:
		if w["name"] == monster:
			return {"lore": w["lore"], "drops": []}
	return Realms.MONSTER_INFO.get(monster, {"lore": "", "drops": []})

## Every monster's info: the roots' and the realms'.
static func all_info() -> Array:
	return [INFO, Realms.MONSTER_INFO]

static func tier_name(tier: int) -> String:
	return TIER_NAMES[clampi(tier, 0, TIER_NAMES.size() - 1)]

static func tier_color(tier: int) -> String:
	return TIERS[clampi(tier, 0, TIERS.size() - 1)]["color"]

## Spawn chances (%) for each tier. Hardcore heroes see more rare monsters.
static func tier_weights(hardcore: bool, rare_boost := 1.0) -> Array:
	var w: Array = []
	for t in TIERS.size():
		var v := float(TIERS[t]["weight"])
		if t >= RARE:
			v *= (HARDCORE_RARE_BONUS if hardcore else 1.0) * rare_boost
		w.append(v)
	var total := 0.0
	for v in w:
		total += v
	for i in w.size():
		w[i] = float(w[i]) * 100.0 / total
	return w

static func roll_tier(hardcore: bool, rare_boost := 1.0) -> int:
	var w := tier_weights(hardcore, rare_boost)
	var roll := randf() * 100.0
	for t in range(w.size() - 1, -1, -1):
		roll -= float(w[t])
		if roll < 0.0:
			return t
	return 0

static func roll_mods(count: int) -> Array:
	var names := MODS.keys()
	names.shuffle()
	return names.slice(0, count)

## Bonus % (damage and gold) from your kill count of a monster.
static func milestone_bonus(kills: int) -> int:
	var b := 0
	for m in MILESTONES:
		if kills >= int(m[0]):
			b = int(m[1])
	return b

static func next_milestone(kills: int) -> int:
	for m in MILESTONES:
		if kills < int(m[0]):
			return int(m[0])
	return 0

## Every regular monster name, zone by zone (5 old ones, then the 5 sub-area ones).
static func all_monsters() -> Array:
	var out: Array = []
	for z in GameData.ZONES:
		for e in z["enemies"]:
			out.append(e["name"])
		for s in z["subs"]:
			out.append(s["monster"]["name"])
	return out

static func all_bosses() -> Array:
	var out: Array = []
	for z in GameData.ZONES:
		out.append(z["mid"]["name"])
		out.append(z["boss"]["name"])
	return out

static func has_signature(monster: String) -> bool:
	return info(monster).has("sig")

static func signature_def(monster: String) -> Dictionary:
	return info(monster).get("sig", {})

## Which monster a Signature item belongs to ("" if none).
static func signature_owner(item_name: String) -> String:
	for table in all_info():
		for m in table:
			var s: Dictionary = table[m].get("sig", {})
			if s.get("name", "") == item_name:
				return m
	return ""

## A Signature's colors from its sprite name ("s_red_cap").
static func sig_by_art(art: String) -> Dictionary:
	for table in all_info():
		for m in table:
			var s: Dictionary = table[m].get("sig", {})
			if not s.is_empty() and "s_" + GameData.art_key(s["name"]) == art:
				return s
	return {}
