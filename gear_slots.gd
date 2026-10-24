class_name GearSlots
extends RefCounted
## 2.1: the Ring and Necklace slots (8 gear slots in all, GameData.SLOT_ORDER).
##
## Balance (for the balance helper to re-check, see claude/economy.md):
## - A jewelry slot weighs about half a normal slot. Its main stat is small: a Ring gives
##   Attack at 15% of a weapon's, a Necklace gives HP at 25% of a helmet's (GameData.SLOT_INFO).
##   Weapon is the only other Attack slot, so a bigger ring would swing damage too far.
##   base : per_floor keeps the same ratio as the weapon / helmet, so Gear Score (which divides
##   by the floor-1 value) puts jewelry on the same scale as everything else.
## - Its character comes from a small "charm" effect from Uncommon up (CHARMS), and Legendary
##   jewelry rolls its effect from a slot pool (LEGENDARY_POOL): rings lean crit, luck (ability
##   stones) and gold find; necklaces lean life (regen, lifesteal, potions) and the mind (XP, haste).
## - Prices, scrap, dust, upgrades, rerolls and the Wheel are by rarity, the same as every slot.
##   A blessing (Church) on jewelry gives half its usual bonus (HALF).
## - Sets stay 3 pieces of body gear: no set gains a ring or necklace piece (owner can change).
## - No look on the hero: rings never show; a pendant layer for portraits may come later.

const JEWELRY := ["Ring", "Necklace"]
## A jewelry slot's weight next to a normal slot (used where a slot gives a flat % bonus: blessings).
const HALF := 0.5
## The slots that change how the hero looks (wardrobe, transmog, paper doll).
const LOOK_SLOTS := ["Weapon", "Off Hand", "Helmet", "Chest", "Legs", "Feet"]

## [effect, [Uncommon, Rare, Epic] value]; 0 = can't roll at that rarity.
const CHARMS := {
	"Ring": [["crit", [2, 3, 4]], ["gold_find", [5, 8, 12]], ["stone_find", [8, 12, 15]], ["double_strike", [2, 3, 4]]],
	"Necklace": [["regen", [0, 0, 1]], ["lifesteal", [1, 2, 3]], ["xp", [3, 5, 8]], ["potion", [8, 12, 15]]],
}
## Which Legendary effects (GameData.LEGENDARY_EFFECTS) a piece of jewelry can roll.
const LEGENDARY_POOL := {
	"Ring": ["crit", "gold_find", "double_strike", "stone_find", "execute", "boss"],
	"Necklace": ["regen", "lifesteal", "xp", "cdr", "potion"],
}

static func is_jewelry(slot: String) -> bool:
	return slot in JEWELRY

static func has_look(slot: String) -> bool:
	return slot in LOOK_SLOTS

## The Legendary effects an item of this slot can roll (every effect for body gear).
static func legendary_effects(slot: String) -> Array:
	if not LEGENDARY_POOL.has(slot):
		return GameData.LEGENDARY_EFFECTS
	var pool: Array = LEGENDARY_POOL[slot]
	return GameData.LEGENDARY_EFFECTS.filter(func(fx): return String(fx["effect"]) in pool)

## Gives Uncommon to Epic jewelry its charm, or updates the value after a rarity change
## (a reroll or Wheel win keeps the same charm, only stronger). Other items: untouched.
static func apply_charm(item: Dictionary) -> Dictionary:
	var slot := String(item.get("slot", ""))
	var r := int(item.get("rarity", 0))
	if not CHARMS.has(slot) or r < 1 or r > 3:
		return item
	var list: Array = CHARMS[slot]
	var keep := String(item.get("effect", ""))
	for c in list:
		if String(c[0]) == keep and int(c[1][r - 1]) > 0:
			item["effect_value"] = int(c[1][r - 1])
			return item
	var ok: Array = list.filter(func(c): return int(c[1][r - 1]) > 0)
	var pick: Array = ok.pick_random()
	item["effect"] = String(pick[0])
	item["effect_value"] = int(pick[1][r - 1])
	return item

## Old or odd saves: an item for a slot this version doesn't know is put away (never crash).
## Returns how many were removed.
static func drop_unknown(g: GameState) -> int:
	var n := 0
	for s in g.equipped.keys():
		var it = g.equipped[s]
		if not GameData.SLOT_INFO.has(String(s)) or not (it is Dictionary) or String((it as Dictionary).get("slot", "")) != String(s):
			g.equipped.erase(s)
			n += 1
	for list in [g.bag, g.shop]:
		for i in range((list as Array).size() - 1, -1, -1):
			var it = list[i]
			if not (it is Dictionary) or not GameData.SLOT_INFO.has(String((it as Dictionary).get("slot", ""))):
				list.remove_at(i)
				n += 1
	if not g.featured.is_empty() and not GameData.SLOT_INFO.has(String(g.featured.get("slot", ""))):
		g.featured = {}
		n += 1
	return n

## Hand-made jewelry per zone, like ItemPool.ZONES: ["Name", "type", "Flavor"].
## Types: Ring = band signet, Necklace = pendant amulet.
const POOL := [
	{  # 0: Mossy Hollows
		"Ring": [
			["Acorn Band", "band", "Carved from one acorn. The oak wants it back."],
			["Kobold's Lucky Loop", "band", "Bent from a nail. The kobold swore by it."],
			["Hedge-Witch Signet", "signet", "Stamps a little toad into the wax."],
		],
		"Necklace": [
			["Hagstone on a String", "amulet", "Look through the hole and you see the fae. They see you too."],
			["Rowan-Berry Beads", "pendant", "Red berries keep the wicked off. Mostly."],
			["Boggart's Bell", "amulet", "It rang every time he stole something. It rings a lot."],
		],
	},
	{  # 1: Sunken Catacombs
		"Ring": [
			["Gravedigger's Band", "band", "Worn smooth by a shovel handle."],
			["Barrow Gold Ring", "band", "Taken from a barrow. The barrow noticed."],
			["Signet of the Drowned Lord", "signet", "His seal still opens doors. Mostly tomb doors."],
		],
		"Necklace": [
			["Coffin-Nail Charm", "pendant", "Bent nails, tied in a knot, for luck you shouldn't need."],
			["Banshee's Locket", "amulet", "Open it and you hear her. Keep it shut."],
			["Rosary of Grave Dust", "pendant", "Each bead is packed with a little of someone."],
		],
	},
	{  # 2: Flooded Depths
		"Ring": [
			["Pearl-Set Band", "band", "The pearl is still growing. Slowly."],
			["Selkie's Ring", "band", "She left it on the shore with her skin."],
			["Tide-Lord's Signet", "signet", "Pressed into wet sand, the sea comes to look."],
		],
		"Necklace": [
			["Kappa's Cucumber Charm", "pendant", "Kappa love cucumbers. Bow, and keep this close."],
			["Bunyip Tooth", "pendant", "Pulled from a billabong. It still smells of one."],
			["Siren's Shell", "amulet", "Hold it to your ear. Don't swim toward the singing."],
		],
	},
	{  # 3: Ember Halls
		"Ring": [
			["Cinder Band", "band", "Warm to the touch. Always."],
			["Simurgh-Feather Ring", "band", "One feather, coiled. It is said to heal."],
			["Forge-Master's Signet", "signet", "It brands the wax instead of pressing it."],
		],
		"Necklace": [
			["Salamander Scale", "pendant", "Still flickers, as if remembering a fire."],
			["Ember in a Cage", "amulet", "A coal that never went out. It knows your name."],
			["Phoenix-Ash Vial", "pendant", "The ash is warm. Some days it moves."],
		],
	},
	{  # 4: The Shadow Deep
		"Ring": [
			["Band of Long Shadows", "band", "Your shadow falls a little longer wearing it."],
			["Naga-Coil Ring", "band", "A snake biting its own tail, in black silver."],
			["Wendigo-Bone Signet", "signet", "Cold enough to burn. Do not get hungry."],
		],
		"Necklace": [
			["Gorgon-Eye Pendant", "pendant", "The eye is shut. Keep it that way."],
			["Rakshasa's Prayer Beads", "pendant", "Counted backward, they undo a prayer."],
			["Oni-Horn Amulet", "amulet", "Filed down from a demon's horn. It still pokes."],
		],
	},
	{  # 5: The Hushwood
		"Ring": [
			["Moonsilver Band", "band", "Elven silver, pale as a ghost."],
			["Leafwoven Ring", "band", "A living vine that never browns."],
			["Warden's Signet", "signet", "The seal of a forest guard that fell asleep a thousand years ago."],
		],
		"Necklace": [
			["Starseed Pendant", "pendant", "Glows faintly when nothing is watching."],
			["Hushwood Torc", "amulet", "Worn by the elves who never spoke again."],
			["Ghostlight Locket", "amulet", "Inside, a face you almost recognise."],
		],
	},
	{  # 6: The Glimmer Court
		"Ring": [
			["Fairy-Gold Band", "band", "It will be leaves by morning. Unless it likes you."],
			["Glamour Ring", "band", "You look better wearing it. Everyone agrees, suspiciously."],
			["Signet of a Fae Debt", "signet", "Proof that someone owes you. Or that you owe them."],
		],
		"Necklace": [
			["Dewdrop Choker", "pendant", "A drop of dew that never dries."],
			["Mirror-Shard Pendant", "pendant", "It shows you a moment from now."],
			["Courtly Cameo", "amulet", "The lady on it winks when you win."],
		],
	},
	{  # 7: The Ironroot Deeps
		"Ring": [
			["Rune-Cut Band", "band", "A dwarven rune for 'mine', on every side."],
			["Anvil-Struck Ring", "band", "Hammered on the same anvil as a king's crown."],
			["Clan Signet", "signet", "Show it in any dwarf hall and get a seat. And a bill."],
		],
		"Necklace": [
			["Lodestone Amulet", "amulet", "Points to treasure. Or to north. Hard to tell."],
			["Miner's Lucky Tooth", "pendant", "Knocked out in a tunnel collapse. He lived."],
			["Deepforge Medallion", "amulet", "Struck to honour a smith nobody remembers."],
		],
	},
	{  # 8: The Gilded Spire
		"Ring": [
			["Halo-Gold Band", "band", "Melted down from a halo that fell."],
			["Band of the Seventh Choir", "band", "It hums a single, perfect note."],
			["Seraph's Signet", "signet", "Six wings on the seal. It burns liars."],
		],
		"Necklace": [
			["Feather of Grace", "pendant", "Light as nothing. Heavy as a promise."],
			["Sunstone Amulet", "amulet", "Holds the dawn in a stone. Warm at night."],
			["Choir Bell Pendant", "pendant", "Ring it, and somewhere far above, someone answers."],
		],
	},
	{  # 9: The Cinder Abyss
		"Ring": [
			["Brimstone Band", "band", "Smells of rotten eggs and ambition."],
			["Ring of the Broken Pact", "band", "The demon who made it is still looking for it."],
			["Infernal Signet", "signet", "Seals a contract in blood. Yours, by default."],
		],
		"Necklace": [
			["Soul-Gem Pendant", "pendant", "Someone is inside. They are fine. Probably."],
			["Hellhound Collar Tag", "amulet", "The hound wants it back. The hound wants everything back."],
			["Chain of the Damned", "pendant", "Each link a promise somebody broke."],
		],
	},
]

static func pick(slot: String, zone_index: int) -> Array:
	var list: Array = POOL[clampi(zone_index, 0, POOL.size() - 1)][slot]
	return list.pick_random()

static func count() -> int:
	var n := 0
	for z in POOL:
		for slot in z:
			n += (z[slot] as Array).size()
	return n
