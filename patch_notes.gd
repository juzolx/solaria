class_name PatchNotes
extends RefCounted
## What changed in each version. Shown on the title screen.
## Add the newest version at the top of NOTES.

const VERSION := "0.11"

const NOTES := [
	{"version": "0.11", "name": "Evolution", "lines": [
		"The Family Tree is now the Evolution Tree. Classes you haven't reached show as ???, and every evolution has a big moment and teaches a signature skill for a new 4th skill slot.",
		"8 stats: STR, VIT, AGI, DEX, INT, WIS, LUK and CHA, at 5 points a level. Your old points were converted. Suggested builds, Auto-spend, respec tomes and 3 saved builds (stats, skills and gear).",
		"Special stats now grow from what you do, not from points. Weapon mastery grows with each weapon type you use.",
		"Combat: elemental weaknesses and resistances, status combos (freeze, shatter, conduct, toxic), new elite modifiers, boss mechanics, auto-battle settings and a death recap with tips.",
		"Loot: upgrade arrows with a percent, gear sets for every class tree, and living legendaries that awaken as they kill.",
		"World: floor hazards, events between fights, milestone floors with Champions and checkpoints, opt-in curses, bestiary mastery bonuses, companions that evolve, achievement rewards and a Next goal line under the fight.",
		"God trials rotate every week. Unique classes get a cape and God rank an aura.",
		"New dark fantasy art: heroes and 32 monsters are built from the LPC character parts, with real attack animations (slash, thrust, cast, shoot), 37 hairstyles, 18 hair colors and all 12 races. Hit and spell effects, and the game now scales to fit your window.",
		"Phones: a bottom bar (Fight, Hero, Items, Town, Codex, Online) and the fight fills the screen. Art credits are in Settings.",
		"A faster first 10 minutes, hit impact, new sounds and a balance pass.",
	]},
	{"version": "0.10", "name": "Family Trees", "lines": [
		"Every class is now a family tree: it splits in two at level 15, again at 35 and again at 60. You choose each step in the Class tab, which draws your whole tree.",
		"Your deeds limit you: every class is Good, Neutral or Evil. Good heroes can't take Evil classes, Evil heroes can't take Good ones, and Neutral heroes can take either.",
		"The 72 level 60 classes are unique classes with a rank (C to God) and their own special stat. Each tree has a God rank class behind a god trial: Titan, Sky Dragoon, Sword God, Heavenly Demon, Archdruid, Saint Militant, Chronomancer, Phantom, Hawkeye and Songweaver.",
		"115 hidden branch-offs: unique classes you unlock by how you play (win 50 fights below 20% HP, spare 100 enemies, keep the same sword for 250 floors...). Taking one ends your tree.",
		"Utility classes (crafting, wealth, scouting, hypnosis) get their full rank on their perks but fight two ranks lower.",
		"The Wanderer is always Neutral. Sword Saint and his best classes need special items, each won in one rare fight or conversation on the road. Asura needs none, and an Asura can never become the Heavenly Demon.",
		"Special stats now come only from unique and hidden classes. Sword Intent and Demonic Qi belong to the Sword God and the Heavenly Demon. Ronin is gone: the Wanderer is the Ronin.",
		"HD art: every hero, piece of gear, monster, boss and background is redrawn at twice the resolution, with crisp 1-pixel highlights and outlines, smoother curves, brows and eye glints.",
		"Unique classes wear a cape in their class color, trimmed in their rank color, and glow by rank.",
		"A cleaner battle screen: bigger fighters, health plates under their feet, damage numbers that pop, hold and fan out instead of piling up, a zone-colored rim light, a vignette and tips along the bottom edge.",
		"4 new achievements for your class tree.",
	]},
	{"version": "0.9", "name": "Realms Awaken", "lines": [
		"Floors 251-500 are now 5 realms you invade: the Hushwood, the Glimmer Court, the Ironroot Deeps, the Gilded Spire and the Cinder Abyss. You choose the order through portals, and your race, faith and road open some and lock others.",
		"50 new monsters and 10 new bosses, each realm with its own mechanic (mist, illusions, forge heat, judgement, hellfire), event, camp, quest board, set, uniques, material, music and secrets.",
		"12 races: Human, Elf, Fairy, Angel, Demon, Dwarf, Beastkin, Dragonkin, Undead, Orc, Goblin and Golem (new races are for new heroes).",
		"Racial power and awakening: every race grows its own power and climbs its own ranks. Angels grow more wings, Demons rise to royalty, Elves seek the World Tree's blessing. Awakening changes your look.",
		"Transformations: a bite can make you a Vampire or a Werewolf (both curable, if you want). An Angel who falls becomes a Fallen Angel, and a dark caster can become a Lich. Those are forever.",
		"Reputation: every race likes or hates you. Spare their people, help them on the road and do their quests. Helping one race annoys its rivals. Friends trade and show you secrets.",
		"Run and Spare: try to escape a fight (not bosses), or let a beaten monster go.",
		"7 new Legendary effects (Executioner, Slayer, Wrath, Discovery, Wisdom, Haste, Alchemist), and race-only gear sold to friends of each race.",
		"The Mage's Death-school evolution 'Lich' is now called 'Necrolord', so Lich can be the transformation.",
		"Hidden classes in 3 tiers (Discoveries, Masteries, Legends): Jester, Treasure Hunter, The Fool, Alchemist, Gladiator, Executioner, Plague Doctor, Beast Tamer, Ronin, Chosen Hero and Demon King. Find them by how you play.",
		"Big moments: realm entrances, realm boss intros, awakening ceremonies and hidden-class reveals. 23 new achievements (with realm titles and looks) and new guide pages.",
	]},
	{"version": "0.8", "name": "Heroes and Paths", "lines": [
		"9 classes: Warrior, Knight, Wanderer, Cleric, Acolyte, Mage, Trickster, Ranger and Bard, each with its own starting skills and outfit.",
		"Skills now come from ability stones that monsters drop (bosses always). Equip 3 active and 5 passive skills; duplicates rank them up, extras become dust, and dust crafts any skill.",
		"Over 90 skills with tags (Fire, Holy, Blade, Song...). At level 35 you evolve by the tag you use most: Inferno Berserker, Radiant Guardian, and many more.",
		"The Acolyte's faith follows a Good vs Evil meter. The Mage picks one of 5 schools, each splitting in two.",
		"The Wanderer walks the road of the Sword or the Demon (Sword Intent vs Demonic Qi), with a god trial at level 60: become the Sword God or the Heavenly Demon.",
		"Parties: bring up to 2 of your other Regular heroes. They fight with their own gear and skills, heal and protect each other, and level up with you.",
		"New pose animations: wind-ups, strikes, hits, casting and falling, all in crisp whole pixels. Magic circles when you cast, auras for the Wanderer's roads.",
		"Old heroes keep going: their skills became stones, and Archers are now Rangers.",
	]},
	{"version": "0.7.5", "name": "The Foundation Update", "lines": [
		"The dungeon is now split into zones of 50 floors, each with 5 areas, a mid boss on floor 25 and a zone boss on floor 50.",
		"25 new monsters (one per area) and 5 new mid bosses: Black Annis, the Dullahan, Scylla, Fafnir and Echidna.",
		"Monsters now come in 6 tiers, Common to Mythic. Rare ones are bigger, tougher, roll modifiers and drop much better loot.",
		"Every monster drops its own kind of gear, and has a Signature item it drops once in 1,000 kills.",
		"Dungeon events: treasure goblins, monster hordes and cursed shrines. A wandering merchant appears after bosses.",
		"Losing to a boss sends you back to the start of its area. Bosses can be re-fought after a short rest.",
		"New Codex tab: Bestiary with real drop odds, a trophy Collection, Stats, 60 Achievements with titles, daily and weekly Bounties and the Guide.",
		"Up to 3 heroes, picked on the new title screen. Regular heroes share a stash.",
		"Fortune's Wheel (Town > Wheel, from floor 10): bet an item for a chance at the next rarity. Lose and it's gone.",
		"Dev Mode has a bigger toolbox: jump to bosses, make monsters any tier, start any event, and more.",
		"Daily login rewards, item compare popups, loot filter rules, gear loadouts, cloud backup and accessibility options.",
	]},
	{"version": "0.6", "name": "Heroes and Online", "lines": [
		"New 32x32 art, 5 races, the character creator, 150 hand-made items and the Wardrobe.",
		"Hardcore mode, the online leaderboard, guilds and weekly guild raids.",
		"Choose-your-path rooms, weekly events and a phone layout.",
	]},
]

## One tip a day on the title screen.
const TIPS := [
	"Your race has its own power. Check Character > Race to see how it grows.",
	"Sparing a beaten monster earns standing with its people. Killing them costs it.",
	"The realm of the week gives double reputation and better loot.",
	"Hidden classes leave hints in the Class tab when you get close.",
	"Your highest stat decides your specialization at level 15. Plan your points!",
	"Tap the monster to hit it yourself. It adds up, especially on bosses.",
	"Rare monsters glow. The rarer they are, the better they pay.",
	"Each monster favors 2 gear slots. The Bestiary shows which.",
	"Lose to a boss and you go back to the start of its area. Get stronger first!",
	"Salvaging Epic and Legendary gear gives materials for Set items.",
	"Lock your favorite items so you never sell them by accident.",
	"The Hunter's Scroll makes rare monsters show up 3x as often.",
	"Bestiary milestones (10, 100, 500, 1,000 kills) give lasting bonuses against that monster.",
	"Bounties reset every day and every week. Check the Codex tab.",
	"A cursed shrine doubles your gold. Worth it if your hero is strong enough.",
	"Hardcore heroes meet rare monsters more often. High risk, high reward.",
	"Save your favorite gear as a loadout to swap builds in one tap.",
	"Signature items have no pity timer. Every kill is a fresh 1 in 1,000.",
]

static func tip_of_the_day() -> String:
	var day := floori(Time.get_unix_time_from_system() / 86400.0)
	return TIPS[day % TIPS.size()]
