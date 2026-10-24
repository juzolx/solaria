class_name ItemPool
## Every hand-made item that can drop. No random affixes: each item has a fixed
## name, a look ("type", which picks its sprite) and a line of flavor text.
## Items drop in their own zone. Rarity is still rolled, which sets the power
## and the color of the item's trim.
##
## To add an item, add a line to the right zone and slot:
##   ["Name", "type", "Flavor text."]
## Types per slot (each one has a sprite):
##   Weapon:   sword axe dagger mace spear bow staff
##   Off Hand: buckler shield tower orb tome
##   Helmet:   cap helm hood crown
##   Chest:    tunic plate robe
##   Legs:     pants greaves leggings
##   Feet:     boots sandals sabatons
##   Ring:     band signet       (2.1; their items live in gear_slots.gd, GearSlots.POOL)
##   Necklace: pendant amulet

const TYPES := {
	"Weapon": ["sword", "axe", "dagger", "mace", "spear", "bow", "staff"],
	"Off Hand": ["buckler", "shield", "tower", "orb", "tome"],
	"Helmet": ["cap", "helm", "hood", "crown"],
	"Chest": ["tunic", "plate", "robe"],
	"Legs": ["pants", "greaves", "leggings"],
	"Feet": ["boots", "sandals", "sabatons"],
	"Ring": ["band", "signet"],
	"Necklace": ["pendant", "amulet"],
}

## Old generic names (from earlier versions) mapped to a type.
const OLD_NAMES := {
	"Sword": "sword", "Axe": "axe", "Dagger": "dagger", "Mace": "mace", "Spear": "spear",
	"Buckler": "buckler", "Shield": "shield", "Tower Shield": "tower",
	"Cap": "cap", "Helm": "helm", "Hood": "hood",
	"Tunic": "tunic", "Chestplate": "plate", "Robe": "robe",
	"Pants": "pants", "Greaves": "greaves", "Leggings": "leggings",
	"Boots": "boots", "Sandals": "sandals", "Sabatons": "sabatons",
}

## Types for the uniques and set pieces (they also get their own art key).
const SPECIAL_TYPES := {
	"hrunting": "sword", "grendels_hide": "plate", "helskor": "boots", "mask_of_half_death": "helm",
	"scyllas_fang": "spear", "drowned_captains_boots": "boots", "flame_of_muspelheim": "sword",
	"emberforged_greaves": "greaves", "aegis_fragment": "shield", "crown_of_a_hundred_heads": "crown",
	"anniss_skinning_claw": "dagger", "the_hollow_helm": "helm", "sailors_bane": "spear",
	"dragonblood_plate": "plate", "book_of_every_monster": "tome",
	# 2.1 jewelry
	"anniss_bone_charm": "amulet", "draupnir": "band", "pearl_of_the_strait": "pendant", "andvaranaut": "band",
	"brisingamen": "pendant", "ring_of_gyges": "signet",
}

const ZONES := [
	# ---------- 0: Mossy Hollows (English and Germanic forest folklore) ----------
	{
		"Weapon": [
			["Briarwood Club", "mace", "Still has thorns on it. That's a feature."],
			["Kobold Shiv", "dagger", "Stolen from a kobold, who stole it from a miner."],
			["Hunter's Shortbow", "bow", "Strung with gut. Don't ask whose."],
			["Woodcutter's Axe", "axe", "Chopped a lot of trees. Now it chops other things."],
			["Mossy Longsword", "sword", "Green with age, sharp with grudge."],
		],
		"Off Hand": [
			["Barkhide Buckler", "buckler", "A slab of oak with a strap nailed on."],
			["Redcap's Lid", "buckler", "A pot lid. The redcap was very proud of it."],
			["Hedge Knight's Shield", "shield", "The crest is a hedge. He was a literal hedge knight."],
			["Wisp Lantern", "orb", "A trapped will-o'-wisp. It does not like you."],
			["Herbalist's Notes", "tome", "Mostly recipes for soup."],
		],
		"Helmet": [
			["Leaf-Woven Cap", "cap", "Smells like a forest floor after rain."],
			["Kobold Miner's Helm", "helm", "The candle on top went out years ago."],
			["Poacher's Hood", "hood", "Deep enough to hide a guilty face."],
			["Boggart Skullcap", "cap", "Made from something's skull. Don't think about it."],
			["Rusted Sallet", "helm", "Squeaks when you nod."],
		],
		"Chest": [
			["Mossweave Tunic", "tunic", "Grows a little bit every spring."],
			["Barghest-Hide Jerkin", "tunic", "The black dog's coat. It's always slightly warm."],
			["Woodward's Mail", "plate", "Standard issue for forest wardens."],
			["Hermit's Robe", "robe", "Belonged to a hermit who really liked being alone."],
			["Greenwood Brigandine", "plate", "Plates sewn into leather, painted green."],
		],
		"Legs": [
			["Patched Trousers", "pants", "More patch than trouser at this point."],
			["Thornguard Greaves", "greaves", "Brambles don't bother you anymore."],
			["Ranger's Leggings", "leggings", "Quiet on leaves, quiet on stone."],
			["Kobold Kneepads", "greaves", "Kobolds kneel a lot. Mining is hard."],
			["Fernstep Breeches", "pants", "Soft as moss, tough as root."],
		],
		"Feet": [
			["Muddy Boots", "boots", "The mud is load-bearing now."],
			["Rootwalker Sandals", "sandals", "Laced with living vine."],
			["Redcap's Iron Boots", "sabatons", "Redcaps wear these to stomp travelers. Now you can too."],
			["Trapper's Moccasins", "sandals", "Silent. Smelly. Effective."],
			["Old Road Boots", "boots", "Walked every path in the Hollows twice."],
		],
	},
	# ---------- 1: Sunken Catacombs (undead from Norse, Irish and Eastern European tales) ----------
	{
		"Weapon": [
			["Gravedigger's Spade", "spear", "Digs graves. Fills them too."],
			["Draugr Greataxe", "axe", "Cold to the touch, even in summer."],
			["Bone Shiv", "dagger", "Whittled from a femur. Very sharp femur."],
			["Barrow Blade", "sword", "Buried with a king. The king won't be needing it."],
			["Crypt Warden's Staff", "staff", "The skull on top whispers directions. Usually wrong ones."],
		],
		"Off Hand": [
			["Coffin Lid", "tower", "Surprisingly sturdy. Surprisingly heavy."],
			["Ossuary Buckler", "buckler", "Ribs, lashed together. It rattles."],
			["Banshee's Mirror", "orb", "Your reflection screams. You don't."],
			["Book of the Dead", "tome", "Most of the names are crossed out."],
			["Grave Knight's Shield", "shield", "Dented by a thousand years of nothing."],
		],
		"Helmet": [
			["Mourner's Veil", "hood", "Black lace that never gets dusty."],
			["Draugr Helm", "helm", "Frost forms on the inside. Lovely."],
			["Wight's Circlet", "crown", "A pale glow follows it in the dark."],
			["Sexton's Cowl", "hood", "Smells like candle wax and old earth."],
			["Barrow Crown", "crown", "The barrow king's. He's still looking for it."],
		],
		"Chest": [
			["Burial Shroud", "robe", "Clean, white, and worryingly well-fitted."],
			["Draugr Mail", "plate", "Rings rusted together into one solid shirt."],
			["Ghoul-Leather Vest", "tunic", "Stitched by something with too many fingers."],
			["Strigoi's Coat", "tunic", "High collar. Very fashionable, for a corpse."],
			["Catacomb Plate", "plate", "Polished bone over black iron."],
		],
		"Legs": [
			["Gravecloth Wraps", "leggings", "Wrapped tight, like they're expecting you to stay still."],
			["Bone Greaves", "greaves", "Shinbones protecting your shinbones."],
			["Sexton's Trousers", "pants", "Knees worn out from digging."],
			["Wight-Iron Cuisses", "greaves", "Ice-cold steel. Keeps you awake."],
			["Mourner's Skirts", "leggings", "They swish ominously."],
		],
		"Feet": [
			["Tomb Slippers", "sandals", "You can't hear yourself walk. Neither can they."],
			["Draugr Sabatons", "sabatons", "Heavy enough to anchor a ship."],
			["Pallbearer's Boots", "boots", "Built for carrying heavy things slowly."],
			["Banshee Steps", "sandals", "They float a tiny bit off the ground."],
			["Ossuary Boots", "boots", "Toe caps made of actual toes."],
		],
	},
	# ---------- 2: Flooded Depths (water spirits from Japan, Scotland, Australia and Greece) ----------
	{
		"Weapon": [
			["Kappa's Trident", "spear", "Three prongs for three times the cucumber."],
			["Kelpie-Bone Cutlass", "sword", "Curved like a wave about to break."],
			["Coral Dirk", "dagger", "Still growing. Sharpen it with a fish."],
			["Drowned Harpoon", "spear", "The rope's long gone. The point isn't."],
			["Tidecaller Staff", "staff", "Smells like salt and lightning."],
		],
		"Off Hand": [
			["Turtle-Shell Buckler", "buckler", "The kappa wanted it back. He can't have it."],
			["Barnacled Shield", "shield", "Weighs twice what it should. Worth it."],
			["Pearl of the Deep", "orb", "Hold it to your ear and hear the ocean scream."],
			["Waterlogged Grimoire", "tome", "The ink runs, but the spells still work. Mostly."],
			["Bunyip Hide Shield", "tower", "Thick, wet and bad-tempered, like its owner."],
		],
		"Helmet": [
			["Diver's Helm", "helm", "A brass bowl with a window. Breathing optional."],
			["Kelp Hood", "hood", "Slimy. Fashionable in certain reefs."],
			["Umibozu Mask", "helm", "Smooth, black, and staring."],
			["Shell Circlet", "crown", "Every shell is from a different sea."],
			["Fisher's Cap", "cap", "Smells like the catch of the day, every day."],
		],
		"Chest": [
			["Sharkskin Vest", "tunic", "Rough one way, smooth the other."],
			["Coral Plate", "plate", "Living armor. Feed it once a week."],
			["Sea-Witch Robe", "robe", "Always damp. Never drips."],
			["Nuckelavee Hide", "plate", "No skin, all muscle. You get the idea."],
			["Sailor's Oilskin", "tunic", "Waterproof, windproof, monster-resistant."],
		],
		"Legs": [
			["Scaled Leggings", "leggings", "Fish scales overlapped like shingles."],
			["Tideguard Greaves", "greaves", "The current breaks around your shins."],
			["Rolled-Up Trousers", "pants", "For wading. And fighting while wading."],
			["Coral Cuisses", "greaves", "Pink, sharp, and very protective."],
			["Kelpweave Hose", "leggings", "Stretchy. Smells of the shore."],
		],
		"Feet": [
			["Waders", "boots", "Keep the water out. Most of it."],
			["Kappa Sandals", "sandals", "Webbed for speed. And style."],
			["Anchor Boots", "sabatons", "You will not be knocked down. You may sink."],
			["Pearl-Diver's Fins", "sandals", "Great in water. Hilarious on land."],
			["Tidewalker Boots", "boots", "Leave footprints on the waves."],
		],
	},
	# ---------- 3: Ember Halls (fire beasts from Norse, Persian and Greek myth) ----------
	{
		"Weapon": [
			["Salamander Fang", "dagger", "Still warm. Will always be warm."],
			["Ifrit's Scimitar", "sword", "Flames lick along the edge when it's angry."],
			["Hellhound Cleaver", "axe", "Forged in a forge made of hellhound."],
			["Molten Maul", "mace", "Dripping. Please don't touch the dripping part."],
			["Cinder Staff", "staff", "A charred branch from the world tree's lowest root."],
		],
		"Off Hand": [
			["Obsidian Buckler", "buckler", "Volcanic glass. Shatters swords, not itself."],
			["Chimera Shield", "shield", "Three heads painted on it, all looking different ways."],
			["Heart of Embers", "orb", "Beats like a drum. A hot drum."],
			["Ashen Codex", "tome", "Pages of thin iron, etched with fire."],
			["Forge Door", "tower", "Pulled straight off a giant's furnace."],
		],
		"Helmet": [
			["Smith's Goggles", "cap", "Protects your eyes from sparks. And from good taste."],
			["Horned Firehelm", "helm", "The horns glow when you're angry."],
			["Ashcloth Hood", "hood", "Can't burn. Already did."],
			["Manticore Mane", "hood", "Itchy. Majestic."],
			["Crown of Cinders", "crown", "Smoke curls off it constantly."],
		],
		"Chest": [
			["Smith's Apron", "tunic", "Leather, singed, full of pockets."],
			["Magma Plate", "plate", "Glows cherry red along the seams."],
			["Ifrit's Silks", "robe", "Light as smoke. Hot as coal."],
			["Hellhound Harness", "tunic", "Chains and leather. Very dramatic."],
			["Furnace Cuirass", "plate", "It's a furnace. You're wearing a furnace."],
		],
		"Legs": [
			["Charred Breeches", "pants", "Holes everywhere. Stylish holes."],
			["Basalt Greaves", "greaves", "Cooled lava, shaped into shins."],
			["Fire-Dancer Wraps", "leggings", "For leaping over flames without losing anything."],
			["Chimera-Scale Tassets", "greaves", "Goat, lion and snake. All in one."],
			["Ashen Leggings", "leggings", "Leaves a gray trail where you walk."],
		],
		"Feet": [
			["Coal-Walker Boots", "boots", "Walk on hot coals. Show off at parties."],
			["Ember Sandals", "sandals", "Toes toasty forever."],
			["Giant's Toecaps", "sabatons", "Just the toecaps. The rest would not fit."],
			["Salamander Slippers", "sandals", "They wriggle a bit. Normal."],
			["Forgefoot Sabatons", "sabatons", "Each step rings like an anvil."],
		],
	},
	# ---------- 4: The Shadow Deep (monsters of Greek, Japanese, Hindu and Algonquian legend) ----------
	{
		"Weapon": [
			["Wendigo Claw", "dagger", "Always hungry. Always."],
			["Rakshasa's Kris", "dagger", "The blade waves like a snake, because it is one."],
			["Gorgon's Glaive", "spear", "Don't look at the reflection on the blade."],
			["Spider-Silk Longbow", "bow", "Strung with jorogumo silk. Twangs in a whisper."],
			["Abyssal Greatsword", "sword", "Made of shadow that forgot to leave."],
		],
		"Off Hand": [
			["Medusa's Mirror", "shield", "Polished to a dangerous shine."],
			["Void Orb", "orb", "Light goes in. Nothing comes out."],
			["Lamia's Grimoire", "tome", "Bound in snakeskin. It hisses when opened."],
			["Shadow Buckler", "buckler", "Hard to see. Harder to hit around."],
			["Titan's Bulwark", "tower", "A slab of stone carved for a god's arm."],
		],
		"Helmet": [
			["Wendigo Skull", "helm", "Antlers included. Hunger not included."],
			["Veil of the Deep", "hood", "Darkness that sits on your shoulders like a cloak."],
			["Gorgon Diadem", "crown", "The snakes are just decoration. Probably."],
			["Rakshasa Mask", "helm", "Shows a different face to everyone."],
			["Silk-Spun Cowl", "hood", "Soft, strong, and slightly sticky."],
		],
		"Chest": [
			["Shadowweave Robe", "robe", "Swallows the light around you."],
			["Wendigo Pelt", "tunic", "Frost and hunger stitched into fur."],
			["Gorgon-Scale Mail", "plate", "Each scale was a statue once."],
			["Jorogumo Silk Vest", "tunic", "Lighter than air. Stronger than steel."],
			["Abyssal Plate", "plate", "Black metal from the bottom of the world."],
		],
		"Legs": [
			["Shadowstep Leggings", "leggings", "Your shadow moves a half-second early."],
			["Lamia-Scale Greaves", "greaves", "Cold-blooded protection."],
			["Void-Touched Trousers", "pants", "The pockets go somewhere else entirely."],
			["Rakshasa Silks", "leggings", "Gold-threaded and wicked fast."],
			["Abyssal Cuisses", "greaves", "Heavy as regret."],
		],
		"Feet": [
			["Wendigo Treads", "boots", "Leave frozen footprints."],
			["Spider-Step Slippers", "sandals", "Walk on walls. Try not to."],
			["Abyssal Sabatons", "sabatons", "The ground cracks a little under each step."],
			["Night-Runner Boots", "boots", "Silent on stone, silent on bone."],
			["Gorgon-Hide Sandals", "sandals", "Anything you step on turns a bit gray."],
		],
	},
	# ---------- 5: The Hushwood (the elves' ghost forest) ----------
	{
		"Weapon": [
			["Ghostwood Longbow", "bow", "Made from a tree that died mid-sentence."],
			["Sentinel's Glaive", "spear", "An elven guard's blade. It still points at intruders."],
			["Rootbound Blade", "sword", "Roots grew around the hilt while its owner slept for a century."],
			["Mourner's Knife", "dagger", "Used to cut flowers for graves. Now it cuts other things."],
			["Staff of Fallen Leaves", "staff", "Drops a leaf every time you swing it. It never runs out."],
		],
		"Off Hand": [
			["Leafward Buckler", "buckler", "Woven from leaves that refuse to rot."],
			["Lantern of the Lost", "orb", "Elves used these to find each other in the dark."],
			["Book of Elven Names", "tome", "Every name in it belongs to someone who died."],
			["Barkhide Ward", "shield", "A slab of the World Tree's bark. Very, very old bark."],
			["Wisp in a Bottle", "orb", "It's sad. You can hear it sighing."],
		],
		"Helmet": [
			["Circlet of Silence", "crown", "Elven silver. Makes the world a little quieter."],
			["Warden's Leafhelm", "helm", "Shaped like an oak leaf, light as one too."],
			["Mourning Veil", "hood", "Worn for a funeral that never ended."],
			["Owl-Feather Cap", "cap", "Your neck feels oddly flexible."],
			["Pale Antler Crown", "crown", "Shed by a stag that doesn't exist anymore."],
		],
		"Chest": [
			["Ghostweave Robe", "robe", "Half there, half not. Like its old owner."],
			["Elven Scale Mail", "plate", "Each scale is a single dried leaf, hard as steel."],
			["Grave-Keeper's Tunic", "tunic", "Smells of candle wax and old earth."],
			["Mistwalker's Coat", "tunic", "Damp. Always damp."],
			["Rootplate Cuirass", "plate", "Living roots, braided tight. They squeeze when you're scared."],
		],
		"Legs": [
			["Silent-Step Leggings", "leggings", "Elves walked without a sound. Now you do too."],
			["Barkguard Greaves", "greaves", "Grows a new ring every year."],
			["Moss-Lined Trousers", "pants", "Soft. Green. Slightly alive."],
			["Hollow Warden's Legguards", "greaves", "Polished every morning by a ghost."],
			["Mistcloth Breeches", "pants", "You can see through them a little. Don't worry about it."],
		],
		"Feet": [
			["Elven Softboots", "boots", "Leave no footprints, even in snow."],
			["Rootwalker Treads", "sandals", "The roots move out of your way."],
			["Ghost-Path Slippers", "sandals", "Find the old roads by themselves."],
			["Graveyard Boots", "boots", "Muddy from a hundred funerals."],
			["Stag-Hoof Sabatons", "sabatons", "You run a little faster downhill."],
		],
	},
	# ---------- 6: The Glimmer Court (the fae) ----------
	{
		"Weapon": [
			["Pixie-Sting Rapier", "sword", "Tiny, sharp and very rude."],
			["Toadstool Mallet", "mace", "Spotted red. Bonks with a squish."],
			["Thornwhip Spear", "spear", "Grows new thorns while you sleep."],
			["Moonhare's Shortbow", "bow", "Arrows fly in very fast circles."],
			["Wand of Bad Ideas", "staff", "Every spell is a dare."],
		],
		"Off Hand": [
			["Petal Shield", "buckler", "A rose petal the size of a door. Tougher than it looks."],
			["Fae Bargain Scroll", "tome", "Everything you sign comes true. Read carefully."],
			["Glimmer Orb", "orb", "Shows you something nice. It's lying."],
			["Briar Bulwark", "tower", "A wall of thorns that folds up for travel."],
			["Mirror Buckler", "buckler", "Monsters hate seeing themselves."],
		],
		"Helmet": [
			["Mushroom Cap", "cap", "Real mushroom. Still growing."],
			["Crown of Dewdrops", "crown", "Each drop holds a tiny sunrise."],
			["Changeling's Hood", "hood", "Your face looks different in it. Better? Different."],
			["Thornknight Helm", "helm", "A fae knight's helm, sized for a child, stretched for you."],
			["Moth-Wing Circlet", "crown", "The wings flutter when you think about lying."],
		],
		"Chest": [
			["Gossamer Tunic", "tunic", "Spider silk and moonbeams. Very itchy."],
			["Petalplate", "plate", "Rose petals pressed into armor. Smells lovely in a fight."],
			["Courtier's Robe", "robe", "Every courtier in the Glimmer Court owns nine of these."],
			["Glimmerwing Vest", "tunic", "Shimmers in colors that don't have names."],
			["Briarmail", "plate", "Thorns on the outside. Mostly."],
		],
		"Legs": [
			["Dancing Breeches", "pants", "Your feet want to dance. Let them."],
			["Rosebriar Greaves", "greaves", "Grown, not forged."],
			["Moonpetal Leggings", "leggings", "Glow faintly at night."],
			["Jester's Motley Pants", "pants", "Every leg a different color."],
			["Toadstool Legguards", "greaves", "Bouncy. Unexpectedly bouncy."],
		],
		"Feet": [
			["Curly-Toed Shoes", "sandals", "Fae fashion. Nobody knows why."],
			["Fairy-Ring Boots", "boots", "You keep ending up back where you started."],
			["Moonhare Slippers", "sandals", "Quiet, quick and very fluffy."],
			["Dewstep Boots", "boots", "Always wet. You get used to it."],
			["Thornknight Sabatons", "sabatons", "Tiny spurs. Big attitude."],
		],
	},
	# ---------- 7: The Ironroot Deeps (the dwarves) ----------
	{
		"Weapon": [
			["Runeforged Axe", "axe", "Every rune means 'sharp'. Dwarves are thorough."],
			["Deepmine Hammer", "mace", "Made to break rock. Monsters are softer."],
			["Forgeguard Halberd", "spear", "The guards' halberd, still warm from the forge."],
			["Clockwork Crossbow", "bow", "Clicks and whirs. Reloads itself, mostly."],
			["Ember-Core Sword", "sword", "There's a coal in the hilt that never goes out."],
		],
		"Off Hand": [
			["Gatewarden's Tower Shield", "tower", "Thick enough to stop a cave-in."],
			["Runestone", "orb", "A palm-sized stone with one rune. You're not sure which."],
			["Smith's Ledger", "tome", "Every blade ever made in the Deeps, and who it killed."],
			["Iron-Banded Shield", "shield", "Dwarven work. It'll outlive you."],
			["Anvil Buckler", "buckler", "Basically a small anvil with a strap."],
		],
		"Helmet": [
			["Miner's Lamp-Helm", "helm", "The lamp runs on stubbornness."],
			["Runecrested Helm", "helm", "A dwarven warhelm with the clan's runes on the brow."],
			["Soot-Stained Cap", "cap", "Never once been clean."],
			["Thane's Circlet", "crown", "Plain iron. A dwarf thane doesn't need gold to be obeyed."],
			["Smelter's Hood", "hood", "Thick leather against the forge-heat."],
		],
		"Chest": [
			["Ironroot Plate", "plate", "Heavy enough to make you a little shorter."],
			["Forgehand Apron", "tunic", "Scorched, patched and proud."],
			["Runesteel Hauberk", "plate", "Every ring is engraved. It took one dwarf his whole life."],
			["Deepdelver's Jacket", "tunic", "Pockets for every kind of rock."],
			["Rune-Priest's Robe", "robe", "Dwarves have priests. They pray to the forge."],
		],
		"Legs": [
			["Ironshod Greaves", "greaves", "Clank. Clank. Clank."],
			["Miner's Trousers", "pants", "Reinforced knees. Dwarves kneel to dig, not to kings."],
			["Runesteel Legplates", "greaves", "Short, sturdy and somehow fits you."],
			["Smith's Leggings", "leggings", "Fireproof, mostly."],
			["Stoneguard Tassets", "greaves", "Carved from the mountain itself."],
		],
		"Feet": [
			["Steel-Toed Boots", "boots", "Dwarven safety standards are very high."],
			["Forge-Walker Sabatons", "sabatons", "Walk on hot coals. Literally."],
			["Tunnel Boots", "boots", "Grip on any stone, wet or dry."],
			["Ironroot Sabatons", "sabatons", "Heavy. Unbudging. Like their owner."],
			["Hearthstone Sandals", "sandals", "Warm feet, always."],
		],
	},
	# ---------- 8: The Gilded Spire (the angels) ----------
	{
		"Weapon": [
			["Sunsteel Spear", "spear", "Forged in the Sunforge. Glows like noon."],
			["Choir Blade", "sword", "It sings when you swing it. Badly."],
			["Gilded Mace", "mace", "Made for smiting. It's very good at smiting."],
			["Halo-Strung Bow", "bow", "The string is a stretched halo."],
			["Staff of the Choir", "staff", "A conductor's baton for very large choirs."],
		],
		"Off Hand": [
			["Featherwall Shield", "shield", "Made of feathers. Somehow stops swords."],
			["Book of Hymns", "tome", "Every hymn the Spire has ever sung."],
			["Orb of Morning", "orb", "Holds a bit of sunrise. It's warm."],
			["Gilded Tower Shield", "tower", "Big, gold and very hard to miss."],
			["Seraph's Buckler", "buckler", "Small, round and blindingly polished."],
		],
		"Helmet": [
			["Halo of Bronze", "crown", "A junior angel's halo. Slightly dented."],
			["Winged Helm", "helm", "Little wings on the side. They flap when you're excited."],
			["Choir Hood", "hood", "White linen, perfectly pressed."],
			["Sunburst Crown", "crown", "Rays of gold. Hard to sleep in."],
			["Cloudsilk Cap", "cap", "Fluffy. Literally made of cloud."],
		],
		"Chest": [
			["Gilded Breastplate", "plate", "Gold over steel. The angels like things shiny."],
			["Choir Robe", "robe", "White as snow, and somehow stays that way."],
			["Featherweave Tunic", "tunic", "Light as air. Itches a bit."],
			["Judgement Plate", "plate", "Engraved with every law of the Spire."],
			["Sunforged Hauberk", "plate", "Hot from the Sunforge. It cools down eventually."],
		],
		"Legs": [
			["Cloudwalker Leggings", "leggings", "You feel a little lighter."],
			["Gilded Greaves", "greaves", "Shine so bright monsters squint."],
			["Choir Trousers", "pants", "Holy. Comfortable. Slightly too long."],
			["Feathered Legguards", "greaves", "Every feather from a different angel."],
			["Sunsteel Tassets", "greaves", "Warm in winter, warmer in summer."],
		],
		"Feet": [
			["Cloudstep Sandals", "sandals", "Walk on clouds. Don't look down."],
			["Gilded Sabatons", "sabatons", "Gold boots. Of course they're gold boots."],
			["Pilgrim's Boots", "boots", "Worn out climbing the Spire's ten thousand steps."],
			["Winged Boots", "boots", "Tiny wings on the heels. They help, a little."],
			["Sunrise Sandals", "sandals", "Leave golden footprints that fade by noon."],
		],
	},
	# ---------- 9: The Cinder Abyss (the demons) ----------
	{
		"Weapon": [
			["Hellforged Cleaver", "axe", "Built for one thing. It's very good at that thing."],
			["Brimstone Morningstar", "mace", "Smoking spikes. Smells terrible."],
			["Chainblade", "sword", "A sword with a chain for a guard. Demons like chains."],
			["Imp's Trident", "spear", "Three points, all of them rude."],
			["Staff of Bargains", "staff", "Every spell costs something. It'll tell you what later."],
		],
		"Off Hand": [
			["Contract of Flesh", "tome", "Signed. Sealed. Regretted."],
			["Obsidian Shield", "shield", "Volcanic glass, polished to a nasty shine."],
			["Soul Jar", "orb", "Somebody's in there. They want out."],
			["Spiked Buckler", "buckler", "For punching with your shield hand."],
			["Hellgate Tower", "tower", "A slab of the Abyss's own gate."],
		],
		"Helmet": [
			["Horned Helm", "helm", "Real horns. From what, you'd rather not know."],
			["Imp-Skin Cap", "cap", "It giggles sometimes."],
			["Hood of Ashes", "hood", "Leaves a trail of ash wherever you go."],
			["Brimstone Crown", "crown", "A minor demon lord's crown. He won't miss it."],
			["Chain-Wrapped Helm", "helm", "Rattles when you turn your head."],
		],
		"Chest": [
			["Hellplate", "plate", "Hot to the touch. Always."],
			["Chainmail of the Damned", "plate", "Every link was once a promise."],
			["Ash-Cloth Robe", "robe", "Made from the cloaks of burned souls."],
			["Brimstone Jerkin", "tunic", "Smells like a match that never stops being struck."],
			["Duke's Doublet", "tunic", "Demon nobility. Very red. Very rich."],
		],
		"Legs": [
			["Cinderstep Greaves", "greaves", "Leave scorch marks on the floor."],
			["Chain Leggings", "leggings", "Heavy chains, worn as a fashion statement."],
			["Obsidian Tassets", "greaves", "Sharp edges. Sit carefully."],
			["Soot-Black Trousers", "pants", "Everything in the Abyss is this color eventually."],
			["Hellhide Breeches", "pants", "Tanned from something with too many legs."],
		],
		"Feet": [
			["Brimstone Boots", "boots", "The soles never cool."],
			["Hoofed Sabatons", "sabatons", "Demon-shaped. Clop clop clop."],
			["Chainwalker Boots", "boots", "Made for walking the chain bridges over the pit."],
			["Ember Treads", "sandals", "Toasty."],
			["Obsidian Sabatons", "sabatons", "Black glass boots. Don't kick anything."],
		],
	},
]

## Picks a random hand-made item for this slot from the zone of this floor.
static func pick(slot: String, zone_index: int) -> Array:
	if GearSlots.is_jewelry(slot):
		return GearSlots.pick(slot, zone_index)  # 2.1: rings and necklaces
	var list: Array = ZONES[clampi(zone_index, 0, ZONES.size() - 1)][slot]
	return list.pick_random()

## Every type key an item can have (used for the wardrobe and art checks).
static func all_types() -> Array:
	var out := []
	for slot in TYPES:
		out.append_array(TYPES[slot])
	return out

static func count() -> int:
	var n := GearSlots.count()
	for z in ZONES:
		for slot in z:
			n += (z[slot] as Array).size()
	return n
