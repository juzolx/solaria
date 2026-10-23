class_name ClassTree
extends RefCounted
## The Evolution Tree, simplified with Juzo (Oct 20). Two kinds of class only:
##  * The main route: a starting class, upgraded at levels 15, 35 and 75 (pick 1
##    of 2 each time): 1 > 2 > 4 > 8. Your deeds limit you: every class is Good,
##    Neutral or Evil (faith). A Good hero can't take an Evil class, an Evil hero
##    can't take a Good one, a Neutral hero can take either. The level 75 finals
##    have a rank (C to SS) and a special stat; each class grants a signature skill.
##  * Unique classes, off the main route: the hidden classes (hidden.gd), offered
##    at 15, 35 or 75 once earned, and the God classes (god_classes.gd), the rank
##    above SS, which answer the moment their secret deeds are done.
##  * Rank sets fighting strength. Utility classes (crafting, wealth, scouting,
##    hypnosis) get their full rank on their perks but fight two ranks lower.

const PICK_LEVELS := [15, 35, 75]   # Juzo (Oct 20): the main route upgrades at 15, 35 and 75
const GOOD_AT := 25.0
const EVIL_AT := -25.0

const RANK_ORDER := ["C", "B", "A", "S", "SS", "God"]
const RANKS := {"C": 1.0, "B": 1.25, "A": 1.5, "S": 2.0, "SS": 2.5, "God": 3.0}
const RANK_COLORS := {"C": "#94a3b8", "B": "#4ade80", "A": "#60a5fa", "S": "#c084fc", "SS": "#fb923c", "God": "#fde047"}
const TIER_SCALE := [1.0, 1.5]          # level 15 and level 35 classes
const POWER := 1.4                      # one "scale" of fighting bonus, in units (tuned with tests/balance_races.gd)
const TAG_UNIT := 0.12                   # skill tag power per unit of scale
const STAT_PER_POINT := 0.005            # special stat: units of the main bonus per point (x rank)
const STAT_GROW := {"kill": 0.005, "rare": 0.25, "boss": 1.0}
# Special stats grow mostly from the one thing the class is about.
# action -> [growth per action, what to tell the player]
const GROW_ACTIONS := {
	"crit": [0.012, "land critical hits"],
	"double": [0.015, "land double strikes"],
	"big_hit": [0.06, "land huge hits (3x your Attack or more)"],
	"dodge": [0.018, "dodge attacks"],
	"hit_taken": [0.01, "take hits and block"],
	"heal": [0.004, "heal (every 1% of your max HP healed)"],
	"skill": [0.025, "use your skills"],
	"song": [0.06, "sing songs"],
	"gold": [0.02, "earn gold"],
	"charm": [0.1, "charm and confuse monsters"],
	"floor": [0.3, "explore new floors"],
	"craft": [0.04, "salvage, craft and upgrade"],
	"kill": [0.03, "defeat monsters"],
}
# The class's main bonus -> what grows its special stat
const GROW_BY_KEY := {"atk": "big_hit", "crit": "crit", "double_strike": "double", "def": "hit_taken", "thorns": "hit_taken",
	"hp": "hit_taken", "dodge": "dodge", "lifesteal": "heal", "regen": "heal", "skill": "skill", "execute": "big_hit", "rage": "big_hit",
	"boss": "big_hit", "gold_find": "gold", "charm": "charm", "scout": "floor", "escape": "floor", "xp": "kill", "scrap": "craft",
	"stone_find": "craft", "potion": "heal"}
const ALIGN_NAMES := {"G": "Good", "N": "Neutral", "E": "Evil"}
const ALIGN_COLORS := {"G": "#86efac", "N": "#cbd5e1", "E": "#f87171"}

## One unit of each bonus. Multipliers (atk, hp, def, skill) become 1 + amount.
const UNIT := {"atk": 0.12, "hp": 0.15, "def": 0.15, "skill": 0.12, "crit": 6.0, "dodge": 5.0, "lifesteal": 4.0, "regen": 1.0,
	"thorns": 12.0, "double_strike": 7.0, "execute": 20.0, "rage": 18.0, "boss": 15.0,
	"gold_find": 25.0, "xp": 12.0, "potion": 25.0, "scrap": 25.0, "stone_find": 25.0, "escape": 12.0, "scout": 30.0, "charm": 5.0}
const MULT_KEYS := ["atk", "hp", "def", "skill"]
const UTILITY_KEYS := ["gold_find", "xp", "potion", "scrap", "stone_find", "escape", "scout", "charm"]
const ROLE_NAMES := {"combat": "Combat", "crafting": "Crafting", "wealth": "Wealth", "scouting": "Scouting", "hypnosis": "Hypnosis", "utility": "Utility"}

# =====================================================================
# The trees
# =====================================================================
# Node: [name, side, focus, tags, role text, children or final extras]
# focus: "atk:.6 lifesteal:.4" (units, shared out). A final's extras dict can
# have: rank, role (utility kind), util (utility focus), trial, item, extra.
const TREES := {
	"Warrior": [
		["Berserker", "N", "atk:.6 lifesteal:.4", "", "All-out fury", [
			["Bloodreaver", "E", "lifesteal:.5 atk:.5", "Blood", "Drinks the battle", [
				["Slaughter King", "E", "atk:.6 execute:.4", "Blood", "Ends every fight", {}],
				["Crimson Juggernaut", "E", "hp:.5 lifesteal:.5", "Blood", "Heals by hitting", {}]]],
			["Warlord", "N", "atk:.5 def:.5", "", "Leads from the front", [
				["Conqueror", "E", "atk:.5 crit:.5", "Blade", "Takes what it wants", {}],
				["Grand Marshal", "N", "def:.4 hp:.3 atk:.3", "", "Never loses a war", {}]]]]],
		["Champion", "G", "hp:.5 def:.5", "", "The people's shield", [
			["Crusader", "G", "def:.5 regen:.5", "Holy", "Faith and steel", [
				["Holy Avenger", "G", "atk:.5 crit:.5", "Holy", "Righteous wrath", {}],
				["Templar Lord", "G", "def:.5 thorns:.5", "Holy", "An unbreakable oath", {}]]],
			["Weaponmaster", "N", "crit:.5 double_strike:.5", "Blade", "Every weapon, mastered", [
				["Blademaster", "N", "crit:.5 double_strike:.5", "Blade", "The perfect cut", {}],
				["Colossus", "N", "atk:.5 hp:.5", "", "A mountain that walks", {}]]]]],
	],
	"Knight": [
		["Guardian", "G", "def:.6 thorns:.4", "", "Living fortress", [
			["Paladin", "G", "def:.5 regen:.5", "Holy", "Holy knight", [
				["Holy Bulwark", "G", "def:.6 hp:.4", "Holy", "Nothing gets past", {}],
				["Lightsworn", "G", "atk:.5 regen:.5", "Holy", "Sworn to the dawn", {}]]],
			["Juggernaut", "N", "hp:.6 def:.4", "", "Unstoppable", [
				["Iron Colossus", "N", "hp:.5 def:.5", "", "A walking wall", {}],
				["Warden of Ruin", "E", "thorns:.5 atk:.5", "Shadow", "Guards the end of things", {}]]]]],
		["Lancer", "N", "double_strike:.5 atk:.5", "", "First to strike", [
			["Dragoon", "N", "atk:.5 crit:.5", "", "Diving lancer", [
				["Stormdiver", "N", "atk:.5 crit:.5", "", "Falls on the enemy like lightning", {}],
				["Wyrmlancer", "N", "atk:.5 double_strike:.5", "", "Dragon-slaying lance", {}]]],
			["Death Knight", "E", "lifesteal:.5 def:.5", "Shadow Frost", "Cursed armor", [
				["Dread Lord", "E", "atk:.5 lifesteal:.5", "Shadow", "Rules through fear", {}],
				["Hellrider", "E", "atk:.6 rage:.4", "Fire", "Rides out of the fire", {}]]]]],
	],
	"Wanderer": [
		["Swordsman", "N", "crit:.5 double_strike:.5", "Blade", "Fast, precise cuts", [
			["Sword Saint", "N", "crit:.5 double_strike:.5", "Blade", "Every cut lands twice", [
				["Blade Sovereign", "N", "atk:.4 crit:.3 double_strike:.3", "Blade", "Rules the field with one sword", {}],
				["Sword Immortal", "N", "crit:.5 hp:.5", "Blade", "A blade that outlives its wielders", {"rank": "SS"}]]],
			["Blade Phantom", "N", "dodge:.5 crit:.5", "Blade", "Cuts from nowhere", [
				["Ghost Blade", "N", "dodge:.5 crit:.5", "Blade Shadow", "Half here, half gone", {"rank": "SS"}],
				["Thousand Edges", "N", "double_strike:.7 atk:.3", "Blade", "A storm of swords", {"rank": "SS"}]]]]],
		["Demonic Disciple", "N", "lifesteal:.5 atk:.5", "Fist Blood", "Brutal, draining fists", [
			["Demon Saint", "N", "atk:.5 lifesteal:.5", "Fist Blood", "The demon path's master", [
				["Abyssal Master", "N", "atk:.4 lifesteal:.3 hp:.3", "Fist Blood Shadow", "Master of the demonic arts", {}],
				["Asura", "N", "atk:.4 rage:.6", "Fist Blood", "Rage of many arms", {"rank": "SS"}]]],
			["Blood Fiend", "N", "lifesteal:.6 hp:.4", "Blood", "Lives on blood", [
				["Blood Demon King", "N", "lifesteal:.5 atk:.5", "Blood", "Crowned in red", {"rank": "SS"}],
				["Poison Sovereign", "N", "execute:.5 atk:.5", "Blood Shadow", "Every wound festers", {"rank": "SS"}]]]]],
	],
	"Cleric": [
		["Priest", "G", "regen:.6 hp:.4", "Holy", "The temple's healer", [
			["High Priest", "G", "regen:.5 skill:.5", "Holy", "Master healer", [
				["Saint", "G", "regen:.5 hp:.5", "Holy", "A living miracle", {}],
				["Oracle", "G", "dodge:.5 crit:.5", "Holy", "Sees it coming", {}]]],
			["Inquisitor", "N", "atk:.5 crit:.5", "Holy", "Hunter of evil", [
				["Zealot", "N", "atk:.6 crit:.4", "Holy", "Burning certainty", {}],
				["Purifier", "G", "skill:.5 execute:.5", "Holy", "Cleanses with fire and light", {}]]]]],
		["Druid", "N", "hp:.5 regen:.5", "Nature", "The wild's balance", [
			["Grove Keeper", "N", "hp:.5 thorns:.5", "Nature", "Tends the old groves", [
				["Elder Druid", "N", "regen:.5 skill:.5", "Nature", "Brews and grows what others cannot", {"role": "crafting", "util": "potion:.4 scrap:.3 stone_find:.3"}],
				["Lifebinder", "G", "regen:.6 hp:.4", "Nature Holy", "Binds wounds with roots", {}]]],
			["Storm Druid", "N", "double_strike:.5 skill:.5", "Storm Nature", "Calls the storm", [
				["Thunder Shaman", "N", "skill:.5 double_strike:.5", "Storm", "Speaks with thunder", {}],
				["Wildshaper", "N", "atk:.5 hp:.5", "Nature", "Becomes the beast", {}]]]]],
	],
	"Acolyte": [
		["Dawn Disciple", "G", "regen:.5 def:.5", "Holy", "A priest of the dawn", [
			["Templar", "G", "def:.5 thorns:.5", "Holy", "Shield of light", [
				["Sun Templar", "G", "atk:.5 def:.5", "Holy", "Burns like noon", {}],
				["Battle Saint", "G", "atk:.4 regen:.3 def:.3", "Holy", "Prays with a sword", {}]]],
			["Seer", "N", "crit:.5 dodge:.5", "Arcane", "Guided strikes", [
				["Prophet", "N", "crit:.5 skill:.5", "Arcane", "Knows how it ends", {}],
				["Star Seer", "N", "skill:.5 crit:.5", "Arcane Holy", "Reads the stars", {}]]]]],
		["Cultist", "E", "atk:.7 lifesteal:.3", "Shadow", "Power for a price", [
			["Warlock", "E", "skill:.5 atk:.5", "Shadow", "A demon's pact", [
				["Hexlord", "E", "skill:.6 execute:.4", "Shadow", "Curses that kill", {}],
				["Void Caller", "E", "atk:.5 skill:.5", "Shadow Arcane", "Opens the dark between stars", {}]]],
			["Blood Knight", "E", "lifesteal:.5 hp:.5", "Blood", "Drinks to heal", [
				["Blood Lord", "E", "lifesteal:.6 atk:.4", "Blood", "Lord of the red", {}],
				["Reaper", "E", "crit:.5 execute:.5", "Shadow", "Cuts down the weak", {}]]]]],
	],
	"Mage": [
		["Elementalist", "N", "skill:.6 atk:.4", "Fire Frost Storm", "Every element", [
			["Pyromancer", "N", "atk:.5 skill:.5", "Fire", "Master of flame", [
				["Inferno Archmage", "N", "atk:.6 skill:.4", "Fire", "Burns the world", {}],
				["Storm Sovereign", "N", "double_strike:.5 skill:.5", "Storm Fire", "Lightning and fire", {}]]],
			["Cryomancer", "N", "def:.5 skill:.5", "Frost", "Absolute zero", [
				["Glacial Sage", "N", "def:.5 skill:.5", "Frost", "Patient as ice", {}],
				["Frost Witch", "E", "crit:.5 dodge:.5", "Frost Shadow", "Ice and hexes", {}]]]]],
		["Arcanist", "N", "skill:.7 crit:.3", "Arcane", "Pure magic", [
			["Lightbinder", "G", "regen:.4 skill:.6", "Holy Arcane", "Weaves light", [
				["Archmage of Dawn", "G", "skill:.6 regen:.4", "Holy Arcane", "The dawn's own mage", {}],
				["Timeweaver", "N", "skill:.5 double_strike:.5", "Arcane", "Bends the moment", {"extra": {"cdr": 1}}]]],
			["Necromancer", "E", "lifesteal:.5 skill:.5", "Shadow", "Raises the dead", [
				["Necrolord", "E", "hp:.5 regen:.5", "Blood Shadow", "Undying", {"extra": {"summon_turns": 2}}],
				["Bone Sovereign", "E", "skill:.5 lifesteal:.5", "Shadow", "Commands the bones", {"extra": {"summon_turns": 2}}]]]]],
	],
	"Trickster": [
		["Rogue", "N", "crit:.5 dodge:.5", "Shadow", "Knives in the dark", [
			["Assassin", "E", "crit:.5 execute:.5", "Shadow", "One perfect strike", [
				["Nightblade", "E", "crit:.6 dodge:.4", "Shadow", "Death at night", {}],
				["Kingslayer", "E", "boss:.5 crit:.5", "Shadow", "Bosses fall first", {}]]],
			["Shadowdancer", "N", "dodge:.6 double_strike:.4", "Shadow Trick", "Never where you look", [
				["Shade Dancer", "N", "dodge:.5 crit:.5", "Shadow Trick", "Never where the blow lands", {}],
				["Mirage", "N", "dodge:.7 thorns:.3", "Trick", "Was never there", {}]]]]],
		["Gambler", "N", "crit:.5 gold_find:.5", "Trick", "Lives on luck", [
			["Illusionist", "N", "dodge:.6 skill:.4", "Trick", "Tricks of the light", [
				["Grand Illusionist", "N", "dodge:.5 skill:.5", "Trick", "The greatest show", {}],
				["Dreamweaver", "G", "regen:.5 dodge:.5", "Trick Song", "Weaves good dreams", {}]]],
			["Pirate", "E", "gold_find:.5 atk:.5", "Trick", "Plunderer", [
				["Corsair King", "E", "atk:.5 gold_find:.5", "Trick", "King of the waves", {}],
				["Fortune's Fool", "N", "crit:.5 dodge:.5", "Trick", "Gold, luck and the best prices", {"role": "wealth", "util": "gold_find:.5 stone_find:.25 xp:.25"}]]]]],
	],
	"Ranger": [
		["Hunter", "N", "atk:.5 crit:.5", "Nature", "Big game", [
			["Beastmaster", "N", "double_strike:.6 hp:.4", "Nature", "Fights with a beast", [
				["Pack Lord", "N", "double_strike:.5 atk:.5", "Nature", "Leads the pack", {"extra": {"summon_turns": 2}}],
				["Wild King", "N", "hp:.5 atk:.5", "Nature", "King of the wilds", {}]]],
			["Deadeye", "N", "crit:.6 atk:.4", "Storm", "Never misses", [
				["Eagle Eye", "N", "crit:.5 atk:.5", "Storm", "Sees what is ahead and finds every secret", {"role": "scouting", "util": "escape:.4 scout:.4 stone_find:.2"}],
				["Death's Arrow", "E", "crit:.5 execute:.5", "Shadow", "The last arrow", {}]]]]],
		["Warden", "G", "hp:.5 thorns:.5", "Nature", "Forest guard", [
			["Grove Ranger", "G", "regen:.5 dodge:.5", "Nature", "Keeps the grove", [
				["Sylvan Guardian", "G", "hp:.5 regen:.5", "Nature", "The forest's guardian", {}],
				["Moonbow", "G", "crit:.5 skill:.5", "Nature Holy", "Arrows of moonlight", {}]]],
			["Stormcaller", "N", "double_strike:.5 skill:.5", "Storm", "Calls down the sky", [
				["Tempest Archer", "N", "double_strike:.6 crit:.4", "Storm", "Arrows like rain", {}],
				["Sky Hunter", "N", "atk:.5 dodge:.5", "Storm", "Hunts from above", {}]]]]],
	],
	"Bard": [
		["Minstrel", "G", "regen:.5 hp:.5", "Song", "Healing songs", [
			["Troubadour", "G", "regen:.5 skill:.5", "Song", "Songs of the road", [
				["Grand Bard", "G", "regen:.5 skill:.5", "Song", "Charms the room, then the battle", {"role": "hypnosis", "util": "charm:.6 escape:.4"}],
				["Choir Saint", "G", "regen:.6 hp:.4", "Song Holy", "Sings with the angels", {}]]],
			["Siren", "E", "skill:.6 dodge:.4", "Song", "Charms monsters", [
				["Dirge Singer", "E", "skill:.5 execute:.5", "Song Shadow", "Sings the dead to sleep", {"extra": {"confuse": 1}}],
				["Doom Chanter", "E", "atk:.5 skill:.5", "Song Shadow", "Chants the end", {"extra": {"confuse": 1}}]]]]],
		["Skald", "N", "atk:.5 hp:.5", "Song", "War songs", [
			["War Chanter", "N", "atk:.6 double_strike:.4", "Song", "Battle chants", [
				["Warhorn", "N", "atk:.5 def:.5", "Song", "The horn before the charge", {"extra": {"buff_turns": 2}}],
				["Skald King", "N", "atk:.5 hp:.5", "Song", "Sings the sagas", {"extra": {"buff_turns": 2}}]]],
			["Spellsinger", "N", "skill:.6 crit:.4", "Song Arcane", "Magic in every note", [
				["Arcane Harpist", "N", "skill:.6 double_strike:.4", "Arcane Song", "Strings of starlight", {}],
				["Echo Mage", "N", "skill:.5 double_strike:.5", "Arcane", "Every spell twice", {}]]]]],
	],
	# ----- v0.14: four more base classes. Sentinel and Ironbark are tanks. -----
	"Sentinel": [
		["Oathguard", "G", "def:.6 hp:.4", "Holy", "Sworn to hold the line", [
			["Aegis Bearer", "G", "def:.5 regen:.5", "Holy", "Carries the sacred shield", [
				["Aegis Eternal", "G", "def:.6 hp:.4", "Holy", "A shield that never breaks", {}],
				["Dawnwall", "G", "def:.5 regen:.3 thorns:.2", "Holy", "The sun shines off its armor", {}]]],
			["Vowkeeper", "G", "hp:.5 def:.5", "Holy", "Never breaks a promise", [
				["Oath Eternal", "G", "hp:.5 thorns:.5", "Holy", "Dies last, falls never", {}],
				["Last Vow", "G", "hp:.4 def:.4 regen:.2", "Holy", "Holds on for one more sunrise", {}]]]]],
		["Ironclad", "N", "def:.6 hp:.4", "Frost", "Cold iron from head to toe", [
			["Frostwall", "N", "def:.5 hp:.5", "Frost", "A wall of ice and plate", [
				["Glacier Lord", "N", "def:.6 hp:.4", "Frost", "Moves like a glacier", {}],
				["Permafrost Colossus", "N", "hp:.5 def:.5", "Frost", "Nothing thaws it", {}]]],
			["Barrow Warden", "E", "def:.5 lifesteal:.5", "Shadow Frost", "Guards the tombs", [
				["Tomb Sentinel", "E", "def:.6 lifesteal:.4", "Shadow", "Drinks the cold of the grave", {}],
				["Bone Rampart", "E", "hp:.5 thorns:.5", "Shadow Frost", "Walls of bone and spite", {}]]]]],
	],
	"Ironbark": [
		["Thornback", "N", "hp:.5 thorns:.5", "Nature", "Wears the briar", [
			["Briarheart", "N", "thorns:.6 hp:.4", "Nature", "Hurts whoever hits it", [
				["Bramble King", "N", "thorns:.5 hp:.5", "Nature", "Crowned in thorns", {}],
				["Thornlord", "N", "thorns:.6 def:.4", "Nature", "Every blow comes back", {}]]],
			["Mossback", "G", "hp:.5 regen:.5", "Nature", "Slow, green and tough", [
				["Elder Oak", "G", "hp:.5 regen:.5", "Nature", "Older than the dungeon", {}],
				["Heartwood Guardian", "G", "def:.5 regen:.5", "Nature", "Hard heart, soft moss", {}]]]]],
		["Stonefist", "N", "def:.5 atk:.5", "Fist", "Fights like a landslide", [
			["Rockbreaker", "N", "atk:.5 def:.5", "Fist", "Breaks rock, then the monster", [
				["Mountain Fist", "N", "atk:.5 hp:.5", "Fist", "A punch with a mountain behind it", {}],
				["Quake Lord", "N", "atk:.6 double_strike:.4", "Fist", "The floor shakes first", {}]]],
			["Cragborn", "N", "hp:.6 def:.4", "Nature", "Born of the cliffs", [
				["Granite Titan", "N", "hp:.5 def:.5", "Nature", "Cannot be moved", {}],
				["Avalanche", "N", "atk:.5 hp:.5", "Nature Fist", "Once it starts, it doesn't stop", {}]]]]],
	],
	"Nightstalker": [
		["Stalker", "N", "dodge:.5 crit:.5", "Shadow", "Hunts from the dark", [
			["Cutthroat", "E", "crit:.5 execute:.5", "Shadow Blade", "Ends it quietly", [
				["Night Reaper", "E", "crit:.6 execute:.4", "Shadow", "Harvests the sleeping", {}],
				["Gloom Blade", "E", "crit:.5 lifesteal:.5", "Shadow Blade", "Feeds on every cut", {}]]],
			["Duskrunner", "N", "dodge:.6 double_strike:.4", "Shadow", "Faster than its own shadow", [
				["Moonlit Ghost", "N", "dodge:.5 crit:.5", "Shadow", "Seen once, never twice", {}],
				["Dusk Marauder", "N", "double_strike:.5 dodge:.5", "Shadow", "Strikes and is gone", {}]]]]],
		["Skirmisher", "N", "crit:.5 double_strike:.5", "Blade Shadow", "Hit and run", [
			["Knife Dancer", "N", "double_strike:.6 crit:.4", "Blade", "A dance of small cuts", [
				["Razor Storm", "N", "double_strike:.6 atk:.4", "Blade", "A whirl of knives", {}],
				["Whirling Fang", "N", "double_strike:.5 dodge:.5", "Blade Shadow", "Never stops moving", {}]]],
			["Ambusher", "N", "atk:.5 crit:.5", "Shadow", "Waits, then strikes", [
				["Silent Death", "N", "atk:.5 crit:.5", "Shadow", "The first blow is the last", {}],
				["Pouncer", "N", "boss:.5 crit:.5", "Shadow", "Hunts what hunts others", {}]]]]],
	],
	"Conjurer": [
		["Binder", "N", "skill:.6 atk:.4", "Arcane", "Binds spirits to serve", [
			["Spiritcaller", "G", "skill:.5 regen:.5", "Arcane Holy", "Calls the kind dead", [
				["Ancestor Speaker", "G", "skill:.5 regen:.5", "Arcane Holy", "The ancestors fight beside it", {"extra": {"summon_turns": 2}}],
				["Spirit Warden", "G", "hp:.5 regen:.5", "Arcane Holy", "Spirits stand between it and harm", {"extra": {"summon_turns": 2}}]]],
			["Golemwright", "N", "def:.4 skill:.6", "Arcane", "Builds things that fight", [
				["Stone Artificer", "N", "skill:.5 def:.5", "Arcane", "Golems of living stone", {"extra": {"summon_turns": 2}}],
				["Clockwork Sovereign", "N", "skill:.5 atk:.5", "Arcane", "An army of gears", {"extra": {"summon_turns": 2}}]]]]],
		["Demonologist", "E", "skill:.6 lifesteal:.4", "Shadow", "Bargains with the pit", [
			["Imp Master", "E", "skill:.5 atk:.5", "Shadow", "Imps do the dirty work", [
				["Hellgate Keeper", "E", "skill:.6 execute:.4", "Shadow", "Keeps the gate open", {"extra": {"summon_turns": 2}}],
				["Legion Lord", "E", "atk:.5 skill:.5", "Shadow", "A thousand small devils", {"extra": {"summon_turns": 2}}]]],
			["Voidbinder", "E", "skill:.5 crit:.5", "Shadow Arcane", "Chains what lives between stars", [
				["Abyss Caller", "E", "skill:.6 execute:.4", "Shadow Arcane", "Calls what answers", {"extra": {"summon_turns": 2}}],
				["Elder Summoner", "E", "skill:.5 atk:.5", "Arcane", "The oldest contracts", {"extra": {"summon_turns": 2}}]]]]],
	],
}

## Extras on mid classes (level 15/35): same idea as a final's "extra".
const MID_EXTRA := {"Skald": {"buff_turns": 2}, "Siren": {"confuse": 1}, "Beastmaster": {"summon_turns": 2},
	"Necromancer": {"summon_turns": 2}, "Gambler": {"gamble": 5}, "Binder": {"summon_turns": 2}}

# =====================================================================
# Building the node table
# =====================================================================

static var _nodes := {}
static var _roots := {}

static func slug(s: String) -> String:
	var out := ""
	for ch in s.to_lower():
		out += ch if ((ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")) else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	return out.trim_prefix("_").trim_suffix("_")

static func _focus(s: String) -> Dictionary:
	var out := {}
	for part in s.split(" ", false):
		var kv := part.split(":")
		out[kv[0]] = float(kv[1])
	return out

static func _build() -> void:
	if not _nodes.is_empty():
		return
	for cls in TREES:
		var roots: Array = []
		for n in TREES[cls]:
			roots.append(_add(cls, n, 1, ""))
		_roots[cls] = roots
	# God classes (god_classes.gd): unique classes outside the trees, rank God
	for id in GodClasses.LIST:
		var c: Dictionary = GodClasses.LIST[id]
		_nodes[id] = {"id": id, "name": c["name"], "cls": c["cls"], "tier": 3, "parent": "", "side": c["side"],
			"focus": _focus(String(c["focus"])), "tags": Array(String(c["tags"]).split(" ", false)), "role_text": c["role_text"],
			"children": [], "god": true, "rank": "God", "role": String(c.get("role", "combat")), "util": _focus(String(c.get("util", ""))),
			"extra": c.get("extra", {}), "stat": _final_stat(String(c["name"]))}

static func _add(cls: String, n: Array, tier: int, parent: String) -> String:
	var id := slug(String(n[0]))
	var tags: Array = Array(String(n[3]).split(" ", false))
	var node := {"id": id, "name": n[0], "cls": cls, "tier": tier, "parent": parent, "side": n[1], "focus": _focus(String(n[2])),
		"tags": tags, "role_text": n[4], "children": [], "rank": "", "role": "combat", "util": {}, "stat": "",
		"extra": MID_EXTRA.get(n[0], {})}
	_nodes[id] = node
	if n[5] is Array:
		for c in n[5]:
			node["children"].append(_add(cls, c, tier + 1, id))
	else:
		var ex: Dictionary = n[5]
		node["rank"] = String(ex.get("rank", "S"))
		node["role"] = String(ex.get("role", "combat"))
		node["util"] = _focus(String(ex.get("util", "")))
		node["extra"] = ex.get("extra", {})
		node["stat"] = _final_stat(String(n[0]))
	return id

## The special stat a level 75 final grows (named after the class).
const FINAL_STATS := {"Sword God": "Sword Intent", "Heavenly Demon": "Demonic Qi", "Asura": "Wrath", "Titan": "Might",
	"Sky Dragoon": "Sky", "Archdruid": "Verdance", "Saint Militant": "Sanctity", "Chronomancer": "Hours", "Phantom": "Shade",
	"Hawkeye": "Sight", "Songweaver": "Melody", "Fortune's Fool": "Luck"}

static func _final_stat(name: String) -> String:
	if FINAL_STATS.has(name):
		return FINAL_STATS[name]
	var words := name.split(" ")
	return "%s's Mark" % words[words.size() - 1] if words.size() > 1 else "%s's Mark" % name

static func node(id: String) -> Dictionary:
	_build()
	return _nodes.get(id, {})

static func all_nodes() -> Dictionary:
	_build()
	return _nodes

static func roots(cls: String) -> Array:
	_build()
	return _roots.get(cls, [])

static func children(id: String) -> Array:
	return node(id).get("children", [])

static func by_name(n: String) -> Dictionary:
	return node(slug(n))

# =====================================================================
# Bonuses
# =====================================================================

static func rank_of(n: Dictionary) -> String:
	return String(n.get("rank", ""))

## How strong a class's fighting bonuses are. Utility classes fight two ranks lower.
static func combat_scale(n: Dictionary) -> float:
	var r := rank_of(n)
	if r == "":
		return float(TIER_SCALE[clampi(int(n["tier"]) - 1, 0, 1)])
	var i := RANK_ORDER.find(r)
	if String(n.get("role", "combat")) != "combat":
		i = maxi(0, i - 2)
	return float(RANKS[RANK_ORDER[i]])

static func util_scale(n: Dictionary) -> float:
	var r := rank_of(n)
	return float(RANKS.get(r, 1.0)) if r != "" else 1.0

## The class's passive bonus dict (multipliers for atk/hp/def/skill, flat for the rest).
static func passive(n: Dictionary) -> Dictionary:
	var out := {}
	var cs := combat_scale(n)
	var us := util_scale(n)
	var f: Dictionary = n.get("focus", {})
	for k in f:
		_add_bonus(out, k, float(UNIT.get(k, 0.0)) * float(f[k]) * cs * POWER)
	var u: Dictionary = n.get("util", {})
	for k in u:
		_add_bonus(out, k, float(UNIT.get(k, 0.0)) * float(u[k]) * us)
	var ex: Dictionary = n.get("extra", {})
	for k in ex:
		if k == "cdr":
			out["cdr"] = float(out.get("cdr", 0.0)) + float(ex[k])
	return out

static func _add_bonus(out: Dictionary, k: String, amount: float) -> void:
	if k in MULT_KEYS:
		out[k] = float(out.get(k, 1.0)) * (1.0 + amount)
	else:
		out[k] = float(out.get(k, 0.0)) + amount

static func tag_power_of(n: Dictionary) -> Dictionary:
	var tags: Array = n.get("tags", [])
	if tags.is_empty():
		return {}
	var each := TAG_UNIT * combat_scale(n) / sqrt(float(tags.size()))
	var out := {}
	for t in tags:
		out[t] = each
	return out

static func bonus_text(n: Dictionary) -> String:
	var t := Classes.bonus_text(passive(n))
	var tp := tag_power_of(n)
	if not tp.is_empty():
		var parts: Array = []
		for k in tp:
			parts.append(k)
		t += " %s skills +%d%%." % ["/".join(parts), int(round(float(tp[parts[0]]) * 100.0))]
	var ex: Dictionary = n.get("extra", {})
	if ex.has("summon_turns"):
		t += " Summons last longer."
	if ex.has("buff_turns"):
		t += " Songs and buffs last longer."
	if ex.has("confuse"):
		t += " Charms last a turn longer."
	if ex.has("gamble"):
		t += " Better odds at the Wheel."
	var u: Dictionary = n.get("util", {})
	if u.has("scout"):
		t += " Shows what's ahead and finds more secrets."
	if u.has("charm"):
		t += " Enemies are sometimes charmed and skip their attack."
	if u.has("escape"):
		t += " Escapes more often."
	return t

# =====================================================================
# The hero's path
# =====================================================================

static func alignment(g: GameState) -> String:
	if g.hero_class == "Wanderer":
		return "N"
	if g.faith >= GOOD_AT:
		return "G"
	if g.faith <= EVIL_AT:
		return "E"
	return "N"

static func side_ok(g: GameState, side: String) -> bool:
	var a := alignment(g)
	return side == "N" or a == "N" or side == a

## The classes on your path, in order (plus a God class at the end, once you swap into one).
static func path_nodes(g: GameState) -> Array:
	var out: Array = []
	for id in g.class_path:
		var n := node(String(id))
		if not n.is_empty():
			out.append(n)
	if g.god_class != "":
		var gn := node(g.god_class)
		if not gn.is_empty():
			out.append(gn)
	return out

static func current(g: GameState) -> Dictionary:
	if g.god_class != "":
		return node(g.god_class)
	if g.class_path.is_empty():
		return {}
	return node(String(g.class_path[g.class_path.size() - 1]))

static func title(g: GameState) -> String:
	var c := current(g)
	return String(c["name"]) if not c.is_empty() else g.hero_class

## The unique class you are (a level 75 final or a God class), or {}.
static func unique_class(g: GameState) -> Dictionary:
	var c := current(g)
	if c.is_empty() or rank_of(c) == "":
		return {}
	return c

static func stat_name(g: GameState) -> String:
	var u := unique_class(g)
	return String(u.get("stat", "")) if not u.is_empty() else ""

## Which tier you can pick next (0, 1, 2), or -1. A hidden or God class ends the main route.
static func pick_tier(g: GameState) -> int:
	if g.hero_class == "" or g.hidden_class != "" or g.god_class != "":
		return -1
	var t := g.class_path.size()
	if t >= PICK_LEVELS.size() or g.level < int(PICK_LEVELS[t]):
		return -1
	return t

## The classes you can choose between now (or next).
static func options(g: GameState) -> Array:
	if g.hero_class == "" or g.hidden_class != "" or g.god_class != "":
		return []
	if g.class_path.is_empty():
		return roots(g.hero_class).map(func(id): return node(String(id)))
	if g.class_path.size() >= 3:
		return []
	return children(String(g.class_path[g.class_path.size() - 1])).map(func(id): return node(String(id)))

## Why you can't take a class right now ("" = you can).
static func lock_reason(g: GameState, n: Dictionary, ignore_level := false) -> String:
	var t := int(n["tier"]) - 1
	if not ignore_level and g.level < int(PICK_LEVELS[clampi(t, 0, 2)]):
		return "Reach level %d" % int(PICK_LEVELS[clampi(t, 0, 2)])
	if not side_ok(g, String(n["side"])):
		return "Your deeds are too %s for a %s class" % ["good" if alignment(g) == "G" else "evil", String(ALIGN_NAMES[n["side"]]).to_lower()]
	return ""

## Choose the next class on the main route.
static func pick(g: GameState, id: String) -> bool:
	var n := node(id)
	if n.is_empty() or pick_tier(g) < 0:
		return false
	if not options(g).any(func(o): return String(o["id"]) == id):
		return false
	if lock_reason(g, n) != "":
		return false
	_take(g, n)
	return true

static func _take(g: GameState, n: Dictionary) -> void:
	g.class_path.append(String(n["id"]))
	g.discovered[n["name"]] = true
	g.codex.add("class_picks")
	_on_new_class(g, n)

static func _on_new_class(g: GameState, n: Dictionary) -> void:
	var r := rank_of(n)
	var sig := Signatures.id_of(String(n["id"]))
	g.sig_slot = sig
	g.skill_cds.erase(sig)
	g.events.append({"type": "class_up", "name": n["name"], "role": n["role_text"], "rank": r, "side": n["side"], "color": g.class_info().get("color", "#ffffff"),
		"skill": SkillData.skill_name(sig), "skill_text": SkillData.info(sig).get("text", ""), "tier": int(n["tier"])})
	g.say("[color=#fde047]New signature skill: %s![/color] %s" % [SkillData.skill_name(sig), SkillData.info(sig).get("text", "")])
	World.check_pet(g)
	if r != "":
		g.codex.add("unique_classes")
		g.say("[color=%s]*** UNIQUE CLASS: %s (%s rank) ***[/color] %s" % [RANK_COLORS[r], n["name"], r, n["role_text"]])
		if r == "God":
			g.codex.add("gods")
	else:
		g.say("[color=#e8b14a]You are now a %s.[/color] %s" % [n["name"], n["role_text"]])
	g.hero_hp = mini(g.hero_hp, g.get_max_hp())
	Lineage.update_look(g)
	g.save_game()

## Picks the first class you can take (for auto mode and simulations).
static func auto_pick(g: GameState) -> void:
	var guard := 0
	while pick_tier(g) >= 0 and guard < 4:
		guard += 1
		var picked := false
		var opts := options(g)
		opts.shuffle()
		for o in opts:
			if lock_reason(g, o) == "":
				_take(g, o)
				picked = true
				break
		if not picked:
			return

# =====================================================================
# Bonuses from the path and the special stat
# =====================================================================

static func bonus_sources(g: GameState) -> Array:
	var out: Array = []
	for n in path_nodes(g):
		out.append(passive(n))
	var u := unique_class(g)
	if not u.is_empty():
		var sb := stat_bonus(g)
		if not sb.is_empty():
			out.append(sb)
	return out

## What your special stat adds right now.
static func stat_bonus(g: GameState) -> Dictionary:
	var u := unique_class(g)
	if u.is_empty():
		return {}
	var v := g.unique_value(String(u["stat"]))
	if v <= 0.0:
		return {}
	var key := _main_key(u)
	var scale := util_scale(u) if key in UTILITY_KEYS else combat_scale(u)
	var out := {}
	_add_bonus(out, key, float(UNIT.get(key, 0.0)) * STAT_PER_POINT * v * scale)
	return out

static func _main_key(n: Dictionary) -> String:
	var best := ""
	var bw := -1.0
	var pool: Dictionary = n.get("util", {}) if String(n.get("role", "combat")) != "combat" else n.get("focus", {})
	if pool.is_empty():
		pool = n.get("focus", {})
	for k in pool:
		if float(pool[k]) > bw:
			bw = float(pool[k])
			best = k
	return best if best != "" else "atk"

static func stat_text(g: GameState) -> String:
	var sb := stat_bonus(g)
	return Classes.bonus_text(sb) if not sb.is_empty() else "Nothing yet."

static func tag_power(g: GameState, tags: Array) -> float:
	var p := 0.0
	for n in path_nodes(g):
		var tp := tag_power_of(n)
		for t in tags:
			p += float(tp.get(t, 0.0))
	return p

static func extra(g: GameState, key: String) -> int:
	var t := 0
	for n in path_nodes(g):
		t += int((n.get("extra", {}) as Dictionary).get(key, 0))
	return t

static func rank_text(n: Dictionary) -> String:
	var r := rank_of(n)
	if r == "":
		return ""
	var role := String(n.get("role", "combat"))
	return "%s rank %s" % [r, ROLE_NAMES.get(role, "Utility")]

# =====================================================================
# Tracking what you do (for branch-offs and special stats)
# =====================================================================

static func count(g: GameState, key: String, n := 1.0) -> void:
	g.ctrack[key] = float(g.ctrack.get(key, 0.0)) + n

static func at_least(g: GameState, key: String, v: float) -> void:
	g.ctrack[key] = maxf(float(g.ctrack.get(key, 0.0)), v)

static func _grow_stat(g: GameState, amount: float) -> void:
	var s := stat_name(g)
	if s != "":
		g.unique[s] = float(g.unique.get(s, 0.0)) + amount

## Which action grows a unique class's special stat.
static func grow_action(n: Dictionary) -> String:
	if n.is_empty():
		return ""
	if "Song" in (n.get("tags", []) as Array):
		return "song"
	return String(GROW_BY_KEY.get(_main_key(n), "kill"))

## "land critical hits" for the class you are now ("" if you aren't a unique class).
static func grow_text(g: GameState) -> String:
	var a := grow_action(unique_class(g))
	return String(GROW_ACTIONS[a][1]) if a != "" else ""

## Something happened: if it's what your special stat feeds on, it grows.
static func grow(g: GameState, action: String, amount := 1.0) -> void:
	var u := unique_class(g)
	if u.is_empty() or grow_action(u) != action:
		return
	_grow_stat(g, float(GROW_ACTIONS[action][0]) * amount)

## A new monster: reset the fight's notes.
static func on_fight_start(g: GameState) -> void:
	g.cfight = {"turns": 0, "min_hp": 1.0, "potion": false, "taken": 0, "enemy_acted": false, "hits": 0, "tags": {}, "song": false,
		"burned": false, "froze": false, "first": true}

static func on_turn(g: GameState) -> void:
	g.cfight["turns"] = int(g.cfight.get("turns", 0)) + 1
	if g.song_turns > 0:
		g.cfight["song"] = true
	if g.cfight.get("burned", false) and g.cfight.get("froze", false) and not g.cfight.get("bf_done", false):
		g.cfight["bf_done"] = true
		count(g, "burn_freeze")
	_note_hp(g)

static func _note_hp(g: GameState) -> void:
	var f := clampf(float(g.hero_hp) / maxf(1.0, g.get_max_hp()), 0.0, 1.0)
	g.cfight["min_hp"] = minf(float(g.cfight.get("min_hp", 1.0)), f)

static func on_hero_hit(g: GameState, crit: bool, double: bool) -> void:
	if crit:
		count(g, "crits")
		grow(g, "crit")
	if double:
		count(g, "double_strikes")
		grow(g, "double")
	g.cfight["hits"] = int(g.cfight.get("hits", 0)) + 1

static func on_skill(g: GameState, id: String, tags: Array, s: Dictionary) -> void:
	grow(g, "skill")
	if s.has("song") or ("Song" in tags and s.has("buff")):
		grow(g, "song")
	if s.has("confuse"):
		grow(g, "charm")
	for t in tags:
		count(g, "use_tag:" + String(t))
		if s.has("power"):
			count(g, "hit_tag:" + String(t), float(s.get("hits", 1)))
		(g.cfight["tags"] as Dictionary)[t] = true
	if s.has("song") or ("Song" in tags and s.has("buff")):
		count(g, "songs")
	if s.has("hp_cost") and "Blood" in tags:
		count(g, "hp_paid", g.get_max_hp() * float(s["hp_cost"]) / 100.0)
	if float(s.get("burn", 0.0)) > 0.0:
		count(g, "burns")
		g.cfight["burned"] = true
	if s.has("weaken") and "Frost" in tags:
		count(g, "freezes")
		g.cfight["froze"] = true
	var ft: Dictionary = g.cfight["tags"]
	if ft.has("Fire") and ft.has("Frost") and ft.has("Storm") and not g.cfight.get("prism", false):
		g.cfight["prism"] = true
		count(g, "prism_fights")
	# The same skill over and over
	if String(g.ctrack.get("last_skill", "")) == id:
		g.ctrack["skill_run"] = int(g.ctrack.get("skill_run", 0)) + 1
		if int(g.ctrack["skill_run"]) == 10:
			count(g, "skill_repeat10")
	else:
		g.ctrack["last_skill"] = id
		g.ctrack["skill_run"] = 1
	g.cfight["last_tags"] = tags

static func on_dodge(g: GameState) -> void:
	count(g, "dodges")
	grow(g, "dodge")
	g.ctrack["dodge_run"] = int(g.ctrack.get("dodge_run", 0)) + 1
	at_least(g, "dodge_streak", float(g.ctrack["dodge_run"]))
	if (g.cfight.get("tags", {}) as Dictionary).has("Storm"):
		count(g, "dodge_storm")
	g.cfight["enemy_acted"] = true

static func on_hit_taken(g: GameState, dmg: int, shielded: bool) -> void:
	grow(g, "hit_taken")
	g.ctrack["dodge_run"] = 0
	g.cfight["enemy_acted"] = true
	g.cfight["taken"] = int(g.cfight.get("taken", 0)) + dmg
	count(g, "dmg_taken", dmg)
	var oh: Dictionary = g.equipped.get("Off Hand", {})
	if not oh.is_empty() and GameData.item_type(oh) in ["buckler", "shield", "tower"]:
		count(g, "blocks")
	if shielded:
		count(g, "hits_shielded")
	_note_hp(g)

static func on_heal(g: GameState, kind: String, amount: int) -> void:
	if amount <= 0:
		return
	count(g, "healed", amount)
	grow(g, "heal", amount * 100.0 / maxf(1.0, g.get_max_hp()))
	if kind == "lifesteal":
		count(g, "lifesteal_hp", amount)

static func on_potion(g: GameState) -> void:
	g.cfight["potion"] = true

## A monster died. Called before the fight's notes reset.
static func on_kill(g: GameState, boss: bool, tier: int, goblin: bool) -> void:
	if goblin:
		return
	var fl := g.cfight
	var min_hp := float(fl.get("min_hp", 1.0))
	var turns := int(fl.get("turns", 0))
	var lh := g.last_hit
	var tags: Array = fl.get("last_tags", []) if lh == "skill" else []
	count(g, "kills")
	_grow_stat(g, STAT_GROW["kill"])
	grow(g, "kill")
	var w: Dictionary = g.equipped.get("Weapon", {})
	var wt := GameData.item_type(w) if not w.is_empty() else ""
	if wt == "":
		count(g, "kill_unarmed")
	else:
		count(g, "kill_w:" + wt)
	if lh == "skill":
		for t in tags:
			count(g, "kill_tag:" + String(t))
		if "Shadow" in tags or "Blood" in tags:
			count(g, "kill_dark")
	if lh == "burn":
		count(g, "dot_kill")
	if lh == "hit" and int(fl.get("hits", 0)) <= 1 and fl.get("first", true) and turns <= 1:
		count(g, "first_hit_kill")
		if wt == "bow":
			count(g, "first_hit_kill_bow")
	if not fl.get("enemy_acted", false):
		count(g, "quick_win")
	if int(fl.get("taken", 0)) == 0:
		count(g, "flawless_fights")
	if turns <= 3:
		count(g, "short_fights")
	if min_hp < 0.2 and not fl.get("potion", false):
		count(g, "win_low20_nopot")
	if min_hp < 0.05:
		count(g, "win_low5")
	if g.enemy_stun > 0 or g.enemy_weaken_turns > 0 or g.confuse_turns > 0:
		count(g, "kill_debuffed")
	if g.faith <= -75.0:
		count(g, "kill_faith_m75")
	if tier >= Monsters.RARE:
		count(g, "kill_rare")
		_grow_stat(g, STAT_GROW["rare"])
	var fam := family(g)
	if fam == "beast":
		count(g, "kill_beast")
		if tier >= Monsters.RARE:
			count(g, "kill_rare_beast")
	if fam in ["undead", "demon"]:
		count(g, "kill_unholy")
	if fam == "stone":
		count(g, "kill_stone")
	count(g, "kill_zone:%d" % GameData.zone_index(g.floor_num))
	if g.enemy_people != "":
		count(g, "kill_people")
		count(g, "kill_race:" + g.enemy_people)
		var idx := Races.rep_index(Lineage.rep(g, g.enemy_people))
		if idx >= 3:
			count(g, "kill_friendly_people")
			g.ctrack["clean_floors"] = 0
		var realm := GameData.realm_of(g.floor_num)
		if realm != "":
			count(g, "realm_kills_race:" + realm)
	if boss:
		count(g, "boss_kills")
		_grow_stat(g, STAT_GROW["boss"])
		if g.faith >= 50.0:
			count(g, "boss_holy50")
		if min_hp < 0.1:
			count(g, "boss_low10")
		if not fl.get("potion", false):
			count(g, "boss_nopot")
		if min_hp >= 0.5:
			count(g, "boss_above50")
		if fl.get("song", false):
			count(g, "boss_song")
		if fam in ["undead", "demon"]:
			count(g, "boss_unholy")
		for t in tags:
			count(g, "boss_kill_tag:" + String(t))
		var ft: Dictionary = fl.get("tags", {})
		if not ft.is_empty() and ft.keys().all(func(t): return t in ["Holy", "Arcane"]):
			count(g, "boss_holyarcane")
		if not g.ctrack.get("boss_lost_%d" % g.floor_num, 0):
			count(g, "boss_first_try")
		var realm := GameData.realm_of(g.floor_num)
		if realm != "" and g.enemy_boss_kind == "zone":
			_realm_cleared(g, realm)

static func on_big_hit(g: GameState, dealt: int, crit: bool) -> void:
	if dealt >= g.get_attack() * 3:
		grow(g, "big_hit")
	if g.enemy_is_boss and dealt >= g.enemy_max_hp * 0.5:
		at_least(g, "boss_half_hit", 1)
	if crit and dealt >= g.get_attack() * 3 and g.enemy_hp <= 0:
		count(g, "big_crit_kill")

static func _realm_cleared(g: GameState, realm: String) -> void:
	var race: String = Realms.info(realm).get("race", "")
	if Races.rep_index(Lineage.rep(g, race)) >= 3:
		count(g, "realm_friendly_clear")
		count(g, "realm_friendly_clear:" + realm)
	if int(g.ctrack.get("realm_deaths:" + realm, 0)) == 0:
		count(g, "realm_flawless")
	if int(g.ctrack.get("realm_kills_race:" + realm, 0)) == 0:
		count(g, "realm_peace:" + realm)

## Rough monster families (for Exorcist, Trapper, Geomancer...).
static func family(g: GameState) -> String:
	var p := g.enemy_people
	if p == "Undead":
		return "undead"
	if p == "Demon":
		return "demon"
	if p == "Golem":
		return "stone"
	var n := g.enemy_species.to_lower()
	for w in ["golem", "sentry", "stone", "gargoyle", "construct", "anvil", "slag", "sentinel", "obsidian"]:
		if n.contains(w):
			return "stone"
	var zi := GameData.zone_index(g.floor_num)
	if zi == 1:
		return "undead"
	if GameData.realm_of(g.floor_num) == "demon" or n.contains("imp") or n.contains("fiend") or n.contains("hell"):
		return "demon"
	if g.enemy_shape == "beast":
		return "beast"
	return ""

static func on_floor(g: GameState) -> void:
	grow(g, "floor")
	count(g, "clean_floors")
	count(g, "no_retreat_run")
	at_least(g, "no_retreat_streak", float(g.ctrack.get("no_retreat_run", 0)))
	if Lineage.full_moon(g.floor_num):
		count(g, "full_moons")
	if g.form != "":
		count(g, "form_floors")
	if g.faith >= 50.0:
		g.ctrack["faith_peak"] = 1
	if g.ctrack.get("faith_peak", 0) and g.faith <= -50.0:
		at_least(g, "oathbreak", 1)
	var w: Dictionary = g.equipped.get("Weapon", {})
	var wid := int(w.get("id", -1)) if not w.is_empty() else -1
	if wid >= 0 and GameData.item_type(w) == "sword" and wid == int(g.ctrack.get("sword_id", -2)):
		count(g, "sword_run")
		at_least(g, "same_sword_floors", float(g.ctrack["sword_run"]))
	else:
		g.ctrack["sword_id"] = wid
		g.ctrack["sword_run"] = 0
	if GameData.realm_of(g.floor_num) != "":
		count(g, "realm_nocamp_run")
		at_least(g, "realm_nocamp_streak", float(g.ctrack["realm_nocamp_run"]))

static func on_death(g: GameState) -> void:
	count(g, "deaths")
	g.ctrack["no_retreat_run"] = 0
	var realm := GameData.realm_of(g.floor_num)
	if realm != "":
		count(g, "realm_deaths:" + realm)
	if g.enemy_is_boss:
		g.ctrack["boss_lost_%d" % g.floor_num] = 1

static func on_death_save(g: GameState) -> void:
	count(g, "death_saves")
	var realm := GameData.realm_of(g.floor_num)
	if realm != "":
		count(g, "realm_saves_in:" + realm)
		at_least(g, "realm_saves", float(g.ctrack["realm_saves_in:" + realm]))

static func on_camp(g: GameState, realm: String) -> void:
	count(g, "camps")
	g.ctrack["camp_" + realm] = 1
	g.ctrack["realm_nocamp_run"] = 0

static func on_spare(g: GameState) -> void:
	count(g, "spares")
	if g.enemy_people == "":
		count(g, "spare_beasts")
	if g.enemy_people != "" and Races.rep_index(Lineage.rep(g, g.enemy_people)) == 0:
		count(g, "spare_hated")

static func on_encounter(g: GameState, kind: String, hostile: bool) -> void:
	match kind:
		"talk":
			count(g, "talks")
			count(g, "peaceful")
			if hostile:
				count(g, "talk_hostile")
		"attack":
			count(g, "attacks")
		"pass":
			count(g, "peaceful")

# =====================================================================
# Utility powers: charm (enemies skip attacks), escape, scouting
# =====================================================================

static func charm_chance(g: GameState) -> float:
	return g._flat("charm")

static func escape_bonus(g: GameState) -> float:
	return g._flat("escape")

static func scout_bonus(g: GameState) -> float:
	return g._flat("scout")

# =====================================================================
# Saving
# =====================================================================

static func to_save(g: GameState) -> Dictionary:
	return {"path": g.class_path, "track": g.ctrack, "auto": g.class_auto, "god": g.god_class, "god_offers": g.god_offers}

static func from_save(g: GameState, d: Dictionary) -> void:
	g.class_path.assign(d.get("path", []))
	g.ctrack = d.get("track", {})
	g.class_auto = bool(d.get("auto", false))
	g.god_class = String(d.get("god", ""))
	g.god_offers = d.get("god_offers", [])
	# Drop anything that no longer exists
	var keep: Array[String] = []
	for id in g.class_path:
		if not node(String(id)).is_empty() and node(String(id))["cls"] == g.hero_class and not node(String(id)).get("god", false):
			keep.append(String(id))
	g.class_path = keep
	if g.god_class != "" and node(g.god_class).is_empty():
		g.god_class = ""
