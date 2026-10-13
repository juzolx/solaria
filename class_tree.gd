class_name ClassTree
extends RefCounted
## The class family trees (v0.10).
##
## Every starting class splits in two at level 15, each of those in two at
## level 35 and each of those in two at level 60: 1 > 2 > 4 > 8.
##  * You pick freely, but your deeds limit you: every class is Good, Neutral
##    or Evil (from the faith meter). A Good hero can't take an Evil class, an
##    Evil hero can't take a Good one, and a Neutral hero can take either.
##  * The level 60 finals are UNIQUE CLASSES: each has a rank (C to God) and a
##    special stat. God rank classes need a god trial.
##  * Every level 15 and level 35 class has 2-3 hidden BRANCH-OFFS: unique
##    classes you unlock by doing something specific. Taking one ends your tree.
##  * The Wanderer is always Neutral. Sword Saint and every Wanderer final but
##    Asura need a special item, won in a unique fight or conversation.
##  * Rank sets fighting strength. Utility classes (crafting, wealth, scouting,
##    hypnosis) get their full rank on their perks but fight two ranks lower.

const PICK_LEVELS := [15, 35, 60]
const GOOD_AT := 25.0
const EVIL_AT := -25.0

const RANK_ORDER := ["C", "B", "A", "S", "SS", "God"]
const RANKS := {"C": 1.0, "B": 1.25, "A": 1.5, "S": 2.0, "SS": 2.5, "God": 3.0}
const RANK_COLORS := {"C": "#94a3b8", "B": "#4ade80", "A": "#60a5fa", "S": "#c084fc", "SS": "#fb923c", "God": "#fde047"}
const TIER_SCALE := [1.0, 1.5]          # level 15 and level 35 classes
const POWER := 1.4                      # one "scale" of fighting bonus, in units (tuned with tests/balance_races.gd)
const TAG_UNIT := 0.12                   # skill tag power per unit of scale
const STAT_PER_POINT := 0.005            # special stat: units of the main bonus per point (x rank)
const STAT_GROW := {"kill": 0.02, "rare": 0.25, "boss": 1.0}
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
				["Titan", "N", "atk:.5 hp:.5", "", "Raw strength and endless health", {"rank": "God",
					"trial": {"name": "The Elder Titan", "art": "boss_typhon", "lore": "The first giant. Lift what he lifts, and the title is yours."}}]]]]],
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
				["Sky Dragoon", "N", "atk:.5 crit:.5", "", "Diving strikes that ignore defense", {"rank": "God",
					"trial": {"name": "Fafnir Reborn", "art": "boss_fafnir", "lore": "The dragon came back for its hoard. Meet it in the sky."}}],
				["Wyrmlancer", "N", "atk:.5 double_strike:.5", "", "Dragon-slaying lance", {}]]],
			["Death Knight", "E", "lifesteal:.5 def:.5", "Shadow Frost", "Cursed armor", [
				["Dread Lord", "E", "atk:.5 lifesteal:.5", "Shadow", "Rules through fear", {}],
				["Hellrider", "E", "atk:.6 rage:.4", "Fire", "Rides out of the fire", {}]]]]],
	],
	"Wanderer": [
		["Swordsman", "N", "crit:.5 double_strike:.5", "Blade", "Fast, precise cuts", [
			["Sword Saint", "N", "crit:.5 double_strike:.5", "Blade", "Every cut lands twice", [
				["Sword God", "N", "atk:.4 crit:.3 double_strike:.3", "Blade", "The peak of the blade", {"rank": "God", "item": "heavens_edge",
					"trial": {"name": "The Sword Spirit", "art": "boss_sword_spirit", "lore": "The first sword ever forged, still looking for a worthy hand."}}],
				["Sword Immortal", "N", "crit:.5 hp:.5", "Blade", "A blade that outlives its wielders", {"rank": "SS", "item": "undying_scabbard"}]]],
			["Blade Phantom", "N", "dodge:.5 crit:.5", "Blade", "Cuts from nowhere", [
				["Ghost Blade", "N", "dodge:.5 crit:.5", "Blade Shadow", "Half here, half gone", {"rank": "SS", "item": "phantom_tassel"}],
				["Thousand Edges", "N", "double_strike:.7 atk:.3", "Blade", "A storm of swords", {"rank": "SS", "item": "thousand_swords"}]]]]],
		["Demonic Disciple", "N", "lifesteal:.5 atk:.5", "Fist Blood", "Brutal, draining fists", [
			["Demon Saint", "N", "atk:.5 lifesteal:.5", "Fist Blood", "The demon path's master", [
				["Heavenly Demon", "N", "atk:.4 lifesteal:.3 hp:.3", "Fist Blood Shadow", "Ruler of the demonic path", {"rank": "God", "item": "demon_seal",
					"trial": {"name": "The Demon Cult's Ancestor", "art": "boss_demon_ancestor", "lore": "The old master of the demon cult. Take his throne, or take his place in the grave."}}],
				["Asura", "N", "atk:.4 rage:.6", "Fist Blood", "Rage of many arms", {"rank": "SS"}]]],
			["Blood Fiend", "N", "lifesteal:.6 hp:.4", "Blood", "Lives on blood", [
				["Blood Demon King", "N", "lifesteal:.5 atk:.5", "Blood", "Crowned in red", {"rank": "SS", "item": "crimson_crown"}],
				["Poison Sovereign", "N", "execute:.5 atk:.5", "Blood Shadow", "Every wound festers", {"rank": "SS", "item": "viper_heart"}]]]]],
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
				["Archdruid", "N", "regen:.5 skill:.5", "Nature", "Potions and gear no one else can make", {"rank": "God", "role": "crafting",
					"util": "potion:.4 scrap:.3 stone_find:.3",
					"trial": {"name": "The Withered Queen", "art": "boss_withered_queen", "lore": "The forest's sick heart. Heal it, or it will bury you."}}],
				["Lifebinder", "G", "regen:.6 hp:.4", "Nature Holy", "Binds wounds with roots", {}]]],
			["Storm Druid", "N", "double_strike:.5 skill:.5", "Storm Nature", "Calls the storm", [
				["Thunder Shaman", "N", "skill:.5 double_strike:.5", "Storm", "Speaks with thunder", {}],
				["Wildshaper", "N", "atk:.5 hp:.5", "Nature", "Becomes the beast", {}]]]]],
	],
	"Acolyte": [
		["Dawn Disciple", "G", "regen:.5 def:.5", "Holy", "A priest of the dawn", [
			["Templar", "G", "def:.5 thorns:.5", "Holy", "Shield of light", [
				["Sun Templar", "G", "atk:.5 def:.5", "Holy", "Burns like noon", {}],
				["Saint Militant", "G", "atk:.4 regen:.3 def:.3", "Holy", "Holy damage and healing in battle", {"rank": "God",
					"trial": {"name": "Seraphiel's Test", "art": "boss_seraphiel", "lore": "The highest angel asks one question, with a sword."}}]]],
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
				["Chronomancer", "N", "skill:.5 double_strike:.5", "Arcane", "Extra turns and slowed enemies", {"rank": "God", "extra": {"cdr": 1},
					"trial": {"name": "Archon Valeth, Keeper of Hours", "art": "boss_archon_valeth", "lore": "He has watched every second since the first. He will not give you one."}}]]],
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
				["Phantom", "N", "dodge:.5 crit:.5", "Shadow Trick", "Can't be pinned down; strikes from the shadows", {"rank": "God",
					"trial": {"name": "The Weeping Warden", "art": "boss_weeping_warden", "lore": "It sees everything. Make it lose sight of you."}}],
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
				["Hawkeye", "N", "crit:.5 atk:.5", "Storm", "Sees floors and bosses ahead, finds every secret, almost always escapes", {"rank": "God", "role": "scouting",
					"util": "escape:.4 scout:.4 stone_find:.2",
					"trial": {"name": "Dullahan, the Headless Rider", "art": "boss_dullahan", "lore": "He holds his eyes in his hand and still sees further than you."}}],
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
				["Songweaver", "G", "regen:.5 skill:.5", "Song", "Charms enemies to skip fights or turn on each other", {"rank": "God", "role": "hypnosis",
					"util": "charm:.6 escape:.4",
					"trial": {"name": "The Fairy Queen's Song", "art": "boss_fairy_queen", "lore": "She has never lost a song. She has never heard yours."}}],
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
}

## Extras on mid classes (level 15/35): same idea as a final's "extra".
const MID_EXTRA := {"Skald": {"buff_turns": 2}, "Siren": {"confuse": 1}, "Beastmaster": {"summon_turns": 2},
	"Necromancer": {"summon_turns": 2}, "Gambler": {"gamble": 5}}

# =====================================================================
# Branch-offs: [from, name, special stat, focus, requirements, how-to text, easy]
# A requirement is [counter, need]; "live:" counters are checked from the hero.
# =====================================================================
const BRANCHES := [
	# ----- Warrior -----
	["Berserker", "Raging Bull", "Fury", "atk:.5 rage:.5", [["win_low20_nopot", 50]], "Win 50 fights below 20% HP without drinking a potion", false],
	["Berserker", "Pit Fighter", "Grit", "atk:.5 double_strike:.5", [["kill_unarmed", 300]], "Kill 300 enemies with no weapon equipped", false],
	["Champion", "Oathkeeper", "Honor", "def:.5 regen:.5", [["spares", 50], ["clean_floors", 20]], "Spare 50 enemies and kill none of a Friendly race for 20 floors", false],
	["Champion", "Banner Knight", "Valor", "hp:.5 atk:.5", [["boss_holy50", 10]], "Beat 10 bosses while your faith is +50 or higher", false],
	["Bloodreaver", "Gorehound", "Bloodlust", "lifesteal:.6 atk:.4", [["lifesteal_hp", 100000]], "Heal 100,000 HP from lifesteal", false],
	["Bloodreaver", "Butcher of Hosts", "Carnage", "atk:.6 execute:.4", [["kill_people", 500]], "Kill 500 people of other races", false],
	["Bloodreaver", "Red Mist", "Frenzy", "rage:.6 atk:.4", [["boss_low10", 10]], "Kill 10 bosses while below 10% HP", false],
	["Warlord", "Warbringer", "Conquest", "atk:.5 crit:.5", [["live:hated", 3]], "Be Hated by 3 races at once", false],
	["Warlord", "Siege Lord", "Ruin", "atk:.5 boss:.5", [["shield_break", 200]], "Break 200 enemy shields", false],
	["Crusader", "Flagbearer of Dawn", "Zeal", "def:.5 hp:.5", [["realm_friendly_clear", 1]], "Clear a realm with its people Friendly or better", false],
	["Crusader", "Martyr", "Sacrifice", "hp:.6 regen:.4", [["death_saves", 5]], "Be saved from death 5 times", false],
	["Weaponmaster", "Hundred Arms", "Arsenal", "double_strike:.5 crit:.5", [["live:weapon_types", 5]], "Get 500 kills with each of 5 weapon types", false],
	["Weaponmaster", "Duelist", "Poise", "crit:.5 boss:.5", [["boss_nopot", 20]], "Kill 20 bosses without drinking a potion", false],
	["Weaponmaster", "Ironbreaker", "Temper", "scrap:.6 def:.4", [["scrapped", 1000]], "Scrap 1,000 items", true],
	# ----- Knight -----
	["Guardian", "Shieldbearer", "Bulwark", "def:.6 thorns:.4", [["blocks", 2000]], "Block 2,000 hits with a shield", true],
	["Guardian", "Vigil Keeper", "Vigil", "def:.5 hp:.5", [["live:exalted", 1]], "Reach Exalted with any race", false],
	["Lancer", "Charger", "Momentum", "atk:.5 double_strike:.5", [["first_hit_kill", 100]], "Win 100 fights with your first hit", false],
	["Lancer", "Outrider", "Ride", "atk:.5 dodge:.5", [["realm_nocamp_streak", 100]], "Clear 100 realm floors in a row without resting at a camp", false],
	["Paladin", "Lightbearer", "Radiance", "regen:.5 skill:.5", [["use_tag:Holy", 5000]], "Use Holy skills 5,000 times", false],
	["Paladin", "Exorcist", "Sanctity", "atk:.5 execute:.5", [["kill_unholy", 300]], "Kill 300 Undead or Demons", false],
	["Paladin", "Shepherd", "Mercy", "regen:.5 charm:.5", [["spares", 100]], "Spare 100 enemies", false],
	["Juggernaut", "Unbroken", "Fortitude", "hp:.6 def:.4", [["dmg_taken", 1000000]], "Take 1,000,000 damage in total", false],
	["Juggernaut", "Rampart", "Stone", "def:.6 thorns:.4", [["boss_above50", 20]], "Win 20 boss fights without dropping below 50% HP", false],
	["Dragoon", "Dragon Rider", "Wyrmbond", "atk:.5 crit:.5", [["live:rep_honored:Dragonkin", 1]], "Reach Honored with the Dragonkin", false],
	["Dragoon", "Skybreaker", "Ascent", "atk:.6 boss:.4", [["realm_flawless", 1]], "Beat every boss in one realm without dying there", false],
	["Death Knight", "Oathbreaker", "Betrayal", "atk:.5 lifesteal:.5", [["oathbreak", 1]], "Fall from faith +50 to -50", false],
	["Death Knight", "Bone Rider", "Requiem", "lifesteal:.5 def:.5", [["kill_faith_m75", 500]], "Kill 500 enemies while your faith is -75 or lower", false],
	# ----- Wanderer -----
	["Swordsman", "Iaido Master", "Draw", "crit:.6 atk:.4", [["first_hit_kill", 1000]], "Kill 1,000 enemies with your first hit", false],
	["Swordsman", "Wandering Blade", "Path", "double_strike:.5 dodge:.5", [["live:realms_half", 5]], "Clear 25 floors in each of 5 realms", false],
	["Demonic Disciple", "Qi Devourer", "Hunger", "lifesteal:.5 atk:.5", [["kill_rare", 200]], "Kill 200 rare monsters", false],
	["Demonic Disciple", "Heart Demon", "Madness", "rage:.6 lifesteal:.4", [["win_low5", 50]], "Win 50 fights after dropping below 5% HP", false],
	["Sword Saint", "Sword Hermit", "Stillness", "crit:.5 atk:.5", [["same_sword_floors", 250]], "Keep the same sword for 250 floors", false],
	["Sword Saint", "Heaven Splitter", "Edge", "atk:.5 boss:.5", [["boss_half_hit", 1]], "Deal 50% of a boss's HP in one hit", false],
	["Blade Phantom", "Shadow Blade", "Phase", "dodge:.6 crit:.4", [["dodges", 3000]], "Dodge 3,000 attacks", false],
	["Blade Phantom", "Mist Walker", "Drift", "dodge:.5 escape:.5", [["escapes", 100]], "Escape 100 fights", false],
	["Demon Saint", "Fallen Sage", "Corruption", "skill:.5 lifesteal:.5", [["cursed_shrines", 50]], "Pray at 50 cursed shrines", false],
	["Demon Saint", "Thousand Hands", "Many Arms", "double_strike:.7 atk:.3", [["double_strikes", 1000]], "Land 1,000 double strikes", false],
	["Blood Fiend", "Blood River", "Crimson", "lifesteal:.6 hp:.4", [["lifesteal_hp", 250000]], "Heal 250,000 HP from lifesteal", false],
	["Blood Fiend", "Venom Saint", "Toxin", "execute:.5 skill:.5", [["burns", 2000]], "Poison or burn 2,000 enemies", false],
	# ----- Cleric -----
	["Priest", "Healer of Hosts", "Grace", "regen:.6 hp:.4", [["healed", 500000]], "Heal 500,000 HP", false],
	["Priest", "Pilgrim", "Devotion", "regen:.5 xp:.5", [["live:camp_realms", 5]], "Rest at a camp in all 5 realms", true],
	["Druid", "Moonwalker", "Lunar", "atk:.5 regen:.5", [["full_moons", 20]], "Fight through 20 full moons", false],
	["Druid", "Thornwarden", "Bramble", "thorns:.6 hp:.4", [["live:rep_honored:Elf", 1], ["live:rep_honored:Fairy", 1]], "Reach Honored with the Elves and the Fairies", false],
	["High Priest", "Hierophant", "Sanctum", "skill:.5 regen:.5", [["live:faith_100", 1]], "Reach faith +100", false],
	["High Priest", "Miracle Worker", "Miracle", "regen:.6 hp:.4", [["cures", 1]], "Finish a Vampire or Werewolf cure", false],
	["Inquisitor", "Witch Hunter", "Verdict", "boss:.5 crit:.5", [["boss_unholy", 50]], "Kill 50 Demon or Undead bosses", false],
	["Inquisitor", "Confessor", "Penance", "def:.5 charm:.5", [["spare_hated", 50]], "Spare 50 enemies of a race that Hates you", false],
	["Grove Keeper", "Treant Speaker", "Rootbond", "hp:.5 thorns:.5", [["realm_peace:elf", 1]], "Clear the Elf realm without killing an Elf", false],
	["Grove Keeper", "Herb Sage", "Bloom", "potion:.6 regen:.4", [["materials", 500]], "Gather 500 materials", true],
	["Storm Druid", "Thunderborn", "Static", "double_strike:.5 skill:.5", [["hit_tag:Storm", 1000]], "Land 1,000 Storm skill hits", false],
	["Storm Druid", "Eye of the Storm", "Calm", "dodge:.5 skill:.5", [["no_retreat_streak", 50]], "Clear 50 floors in a row without retreating", false],
	# ----- Acolyte -----
	["Dawn Disciple", "Sunwalker", "Daybreak", "atk:.5 regen:.5", [["boss_kill_tag:Holy", 25]], "Finish 25 bosses with a Holy skill", false],
	["Dawn Disciple", "Lantern Bearer", "Hope", "hp:.5 def:.5", [["live:floor100_nodeath", 1]], "Reach floor 100 without dying", false],
	["Cultist", "Doomsayer", "Omen", "atk:.6 skill:.4", [["cursed_shrines", 30]], "Take 30 dark bargains at cursed shrines", false],
	["Cultist", "Heretic", "Blasphemy", "atk:.5 crit:.5", [["kill_race:Angel", 100]], "Kill 100 Angels", false],
	["Templar", "Covenant Knight", "Covenant", "def:.5 hp:.5", [["live:rep_honored:Angel", 1], ["live:rep_honored:Dwarf", 1]], "Reach Honored with the Angels and the Dwarves", false],
	["Templar", "Relic Guard", "Relic", "def:.6 regen:.4", [["live:race_keys", 3]], "Carry 3 race keys at once", false],
	["Seer", "Fate Reader", "Foresight", "crit:.5 scout:.5", [["secrets", 10]], "Find 10 realm secrets", false],
	["Seer", "Dream Oracle", "Visions", "dodge:.5 xp:.5", [["camps", 100]], "Rest at 100 camps", true],
	["Warlock", "Pact Lord", "Pact", "skill:.6 lifesteal:.4", [["form_floors", 100]], "Keep a transformation for 100 floors", false],
	["Warlock", "Soul Binder", "Soul", "skill:.5 lifesteal:.5", [["spirits", 100]], "Kill 100 realm spirits", false],
	["Blood Knight", "Sanguine Lord", "Thirst", "lifesteal:.6 atk:.4", [["live:vampire80", 1]], "Reach level 80 as a Vampire", false],
	["Blood Knight", "Crimson Oath", "Sacrament", "atk:.5 lifesteal:.5", [["hp_paid", 50000]], "Spend 50,000 HP on Blood skills", false],
	# ----- Mage -----
	["Elementalist", "Prism Mage", "Prism", "skill:.7 crit:.3", [["prism_fights", 500]], "Use Fire, Frost and Storm skills in one fight, 500 times", false],
	["Elementalist", "Geomancer", "Bedrock", "def:.5 skill:.5", [["kill_stone", 300]], "Kill 300 Golems or stone monsters", false],
	["Elementalist", "Aeromancer", "Zephyr", "dodge:.6 skill:.4", [["dodge_storm", 1000]], "Dodge 1,000 attacks in fights where you used a Storm skill", false],
	["Arcanist", "Spellblade", "Weave", "atk:.5 skill:.5", [["kill_w:sword", 1000]], "Kill 1,000 enemies with a sword equipped", false],
	["Arcanist", "Rune Scribe", "Rune", "skill:.6 crit:.4", [["live:mage_skills", 1]], "Learn every Fire, Frost, Storm and Arcane skill", false],
	["Arcanist", "Archivist", "Lore", "xp:.6 stone_find:.4", [["live:achievements", 60]], "Unlock 60 achievements", true],
	["Pyromancer", "Ash Prophet", "Cinder", "atk:.6 skill:.4", [["kill_tag:Fire", 5000]], "Kill 5,000 enemies with Fire skills", false],
	["Pyromancer", "Phoenix Heir", "Rebirth", "regen:.5 hp:.5", [["realm_saves", 3]], "Be saved from death 3 times in one realm", false],
	["Pyromancer", "Magmancer", "Magma", "skill:.5 def:.5", [["burn_freeze", 500]], "Burn and freeze the same enemy 500 times", false],
	["Cryomancer", "Winter Hermit", "Rime", "def:.5 skill:.5", [["freezes", 2000]], "Freeze 2,000 enemies", false],
	["Cryomancer", "Glass Mage", "Clarity", "skill:.6 crit:.4", [["flawless_fights", 200]], "Win 200 fights without taking damage", false],
	["Cryomancer", "Tidecaller", "Tide", "def:.5 regen:.5", [["hits_shielded", 300]], "Take 300 hits while a shield or Frozen Armor is up", false],
	["Lightbinder", "Starcaller", "Starlight", "skill:.5 regen:.5", [["live:rep_exalted:Angel", 1]], "Reach Exalted with the Angels", false],
	["Lightbinder", "Lumen Sage", "Lumen", "skill:.6 regen:.4", [["boss_holyarcane", 20]], "Beat 20 bosses using only Holy and Arcane skills", false],
	["Necromancer", "Gravecaller", "Grave", "skill:.5 lifesteal:.5", [["kill_dark", 2000]], "Kill 2,000 enemies with Shadow or Blood skills", false],
	["Necromancer", "Soul Harvester", "Harvest", "lifesteal:.5 execute:.5", [["kill_zone:4", 1000]], "Kill 1,000 enemies in Hel's domain, the Shadow Deep", false],
	# ----- Trickster -----
	["Rogue", "Cutpurse", "Greed", "gold_find:.7 crit:.3", [["gold_earned", 1000000]], "Earn 1,000,000 gold", true],
	["Rogue", "Pathfinder", "Stealth", "scout:.5 dodge:.5", [["hidden_paths", 20]], "Find 20 hidden paths in realms", false],
	["Gambler", "High Roller", "Stakes", "crit:.5 gold_find:.5", [["wheel_max_wins", 20]], "Win the wheel at max bet 20 times", false],
	["Gambler", "Cardsharp", "Bargain", "gold_find:.5 stone_find:.5", [["bought", 500]], "Buy 500 items from merchants", false],
	["Assassin", "Silent Knife", "Silence", "crit:.6 execute:.4", [["big_crit_kill", 500]], "Kill 500 enemies with crits of 3x or more", false],
	["Assassin", "Poisoner", "Venom", "execute:.5 crit:.5", [["dot_kill", 1000]], "Kill 1,000 enemies with poison or burns", false],
	["Shadowdancer", "Night Dancer", "Twilight", "dodge:.6 double_strike:.4", [["dodge_streak", 10]], "Dodge 10 attacks in a row", false],
	["Shadowdancer", "Shade", "Umbra", "dodge:.5 crit:.5", [["use_tag:Shadow", 3000]], "Use Shadow skills 3,000 times", false],
	["Illusionist", "Mirror Mage", "Reflection", "dodge:.5 skill:.5", [["illusions", 100]], "See through 100 fae illusions", false],
	["Illusionist", "Puppeteer", "Strings", "charm:.6 skill:.4", [["talks", 100]], "Talk your way past 100 realm encounters", false],
	["Pirate", "Smuggler King", "Contraband", "gold_find:.6 atk:.4", [["sold", 2000]], "Sell 2,000 items", false],
	["Pirate", "Plunderer", "Plunder", "atk:.5 gold_find:.5", [["attacks", 100]], "Attack 100 travelers you could have talked to", false],
	# ----- Ranger -----
	["Hunter", "Trapper", "Snare", "atk:.5 execute:.5", [["kill_beast", 500]], "Kill 500 beasts", false],
	["Hunter", "Bounty Hunter", "Bounty", "gold_find:.5 atk:.5", [["quests", 50]], "Finish 50 realm quests", false],
	["Warden", "Forest Ward", "Ward", "hp:.5 thorns:.5", [["live:rep_honored:Beastkin", 1], ["live:rep_honored:Elf", 1]], "Reach Honored with the Beastkin and the Elves", false],
	["Warden", "Elfsworn", "Leafsong", "regen:.5 crit:.5", [["live:world_tree", 1]], "Receive the World Tree's Blessing", false],
	["Beastmaster", "Packmind", "Instinct", "double_strike:.6 hp:.4", [["kill_rare_beast", 100]], "Kill 100 elite beasts", false],
	["Beastmaster", "Wild Heart", "Wild", "atk:.5 hp:.5", [["live:beastkin_awake", 1]], "Fully awaken as a Beastkin", false],
	["Deadeye", "Sniper", "Aim", "crit:.7 atk:.3", [["crits", 2000]], "Land 2,000 crits", true],
	["Deadeye", "One-Shot", "Mark", "crit:.5 boss:.5", [["first_hit_kill_bow", 300]], "Kill 300 enemies with a single arrow", false],
	["Grove Ranger", "Glade Keeper", "Glade", "regen:.5 dodge:.5", [["realm_friendly_clear:fairy", 1]], "Clear the Fairy realm with the Fairies Friendly or better", false],
	["Grove Ranger", "Root Warden", "Root", "hp:.5 regen:.5", [["peaceful", 150]], "Pass peacefully through 150 realm encounters", false],
	["Stormcaller", "Windrunner", "Gale", "double_strike:.5 dodge:.5", [["quick_win", 300]], "Win 300 fights before the enemy acts", false],
	["Stormcaller", "Thunderbow", "Thunder", "skill:.5 crit:.5", [["boss_kill_tag:Storm", 50]], "Kill 50 bosses with Storm skills", false],
	# ----- Bard -----
	["Minstrel", "Lullaby Singer", "Lull", "charm:.6 regen:.4", [["talk_hostile", 150]], "Calm 150 hostile encounters by talking", false],
	["Minstrel", "Wandering Poet", "Verse", "xp:.6 regen:.4", [["live:codex_entries", 150]], "Discover 150 Codex entries", true],
	["Skald", "Saga Keeper", "Saga", "atk:.5 boss:.5", [["boss_kills", 100]], "Beat 100 bosses", false],
	["Skald", "Drummer", "Rhythm", "atk:.5 double_strike:.5", [["songs", 5000]], "Use buff songs 5,000 times", false],
	["Troubadour", "Heartstring", "Charm", "charm:.5 regen:.5", [["live:friendly_races", 8]], "Be Friendly or better with 8 races at once", false],
	["Troubadour", "Ballad Knight", "Ballad", "atk:.5 def:.5", [["boss_song", 50]], "Win 50 boss fights with a song active", false],
	["Siren", "Tide Witch", "Lure", "charm:.5 skill:.5", [["kill_friendly_people", 300]], "Kill 300 people of races that were Friendly to you", false],
	["Siren", "Banshee", "Wail", "skill:.6 execute:.4", [["kill_debuffed", 1000]], "Kill 1,000 enemies while they're weakened, stunned or charmed", false],
	["War Chanter", "Warcry", "Roar", "atk:.6 double_strike:.4", [["short_fights", 1000]], "Win 1,000 fights in 3 turns or less", false],
	["War Chanter", "Battle Hymnist", "Anthem", "atk:.5 boss:.5", [["boss_first_try", 20]], "Beat 20 bosses on your first try", false],
	["Spellsinger", "Chorus Mage", "Harmony", "skill:.6 regen:.4", [["use_tag:Arcane", 3000]], "Use Arcane skills 3,000 times", false],
	["Spellsinger", "Resonant", "Resonance", "skill:.5 double_strike:.5", [["skill_repeat10", 100]], "Use the same skill 10 times in a row, 100 times", false],
]

# =====================================================================
# The Wanderer's items: one unique encounter each (a fight or a conversation)
# =====================================================================
# node: the class it opens; at: the class you must be to meet it; fight: a
# trial (else the item is given by talking); where: "elf"/"demon"/"dwarf" realm
# or "moon" (a full-moon floor) or "" (anywhere from floor 30).
const ITEMS := {
	"masters_blade": {"name": "Broken Master's Blade", "node": "sword_saint", "at": "swordsman", "level": 35, "where": "",
		"title": "The Old Swordmaster", "talk": "An old man sits by the road with a broken sword across his knees. \"Show me your cut,\" he says, \"and I'll show you mine.\"",
		"yes": "Accept his duel", "fight": {"name": "The Old Swordmaster", "art": "obsidian_knight", "lore": "He was the best once. He still might be.", "hp": 4.0, "atk": 1.3}},
	"heavens_edge": {"name": "Heaven's Edge", "node": "sword_god", "at": "sword_saint", "level": 55, "where": "",
		"title": "The Blade Hermit", "talk": "A hermit blocks the mountain path. \"I fight only the whole. Come at full strength, and drink nothing.\"",
		"yes": "Face the hermit", "full_hp": true, "no_potions": true,
		"fight": {"name": "The Blade Hermit", "art": "hollow_sentinel", "lore": "He hasn't spoken a word in forty years. His sword says enough.", "hp": 6.0, "atk": 1.5}},
	"undying_scabbard": {"name": "Undying Scabbard", "node": "sword_immortal", "at": "sword_saint", "level": 55, "where": "",
		"title": "A ghost swordsman", "talk": "A swordsman made of mist challenges you. He can't die, so he can't lose. Beat him, and let him go.",
		"yes": "Fight, then spare him", "spare": true,
		"fight": {"name": "The Ghost Swordsman", "art": "barrow_wight", "lore": "He has been waiting for someone to beat him for three hundred years.", "hp": 5.0, "atk": 1.4}},
	"phantom_tassel": {"name": "Phantom Tassel", "node": "ghost_blade", "at": "blade_phantom", "level": 55, "where": "elf",
		"title": "Something in the mist", "talk": "In the Hushwood's mist a phantom walks without footprints. It turns toward you.",
		"yes": "Follow the phantom", "fight": {"name": "The Mist Phantom", "art": "owlwraith", "lore": "It walks only in the mist, and only for those who walk like it.", "hp": 5.0, "atk": 1.4}},
	"thousand_swords": {"name": "Shard of a Thousand Swords", "node": "thousand_edges", "at": "blade_phantom", "level": 55, "where": "dwarf", "rep": "Dwarf",
		"title": "The Dwarf master smith", "talk": "The master smith of the Ironroot looks you over. \"Friend of the hold. I have something for a blade like you: a shard of every sword I ever broke.\"",
		"yes": "Take the shard"},
	"demon_seal": {"name": "Heavenly Demon Seal", "node": "heavenly_demon", "at": "demon_saint", "level": 55, "where": "demon",
		"title": "A Demon prince", "talk": "A demon prince steps out of the fire. \"They say you walk the demon path. Prove it, and take my seal.\"",
		"yes": "Accept his challenge", "fight": {"name": "The Demon Prince", "art": "hellborn_duke", "lore": "Heir to a throne of ash. He doesn't intend to share it.", "hp": 6.0, "atk": 1.5}},
	"crimson_crown": {"name": "Crimson Crown", "node": "blood_demon_king", "at": "blood_fiend", "level": 55, "where": "moon",
		"title": "The Blood Moon champion", "talk": "Under the full moon a champion in red waits on a pile of bones. \"The crown goes to whoever is left.\"",
		"yes": "Fight for the crown", "fight": {"name": "The Blood Moon Champion", "art": "strigoi", "lore": "Crowned every full moon. Never for long.", "hp": 6.0, "atk": 1.5}},
	"viper_heart": {"name": "Viper Heart", "node": "poison_sovereign", "at": "blood_fiend", "level": 55, "where": "",
		"title": "A Goblin poison seller", "talk": "A goblin with a tray of vials grins. \"The Viper Heart? Not for sale. But my bodyguard is, if you can beat him.\"",
		"yes": "Pay and fight the bodyguard", "cost": 40,
		"fight": {"name": "The Goblin's Bodyguard", "art": "brimstone_brute", "lore": "Paid in poison. Very well paid.", "hp": 5.0, "atk": 1.5}},
}
const ITEM_CHANCE := 4.0     # % per new floor when you can meet one
const ITEM_PITY := 40        # guaranteed after this many floors of eligibility

# =====================================================================
# Building the node table
# =====================================================================

static var _nodes := {}
static var _roots := {}
static var _branches := {}   # parent id -> [branch nodes]

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
	for b in BRANCHES:
		var parent := slug(String(b[0]))
		var p: Dictionary = _nodes[parent]
		var easy: bool = b[6]
		var rank := ("C" if easy else "B") if int(p["tier"]) == 1 else ("B" if easy else "A")
		var focus := _focus(String(b[3]))
		var util := {}
		var combat := {}
		for k in focus:
			if k in UTILITY_KEYS:
				util[k] = focus[k]
			else:
				combat[k] = focus[k]
		var id := slug(String(b[1]))
		var node := {"id": id, "name": b[1], "cls": p["cls"], "tier": int(p["tier"]) + 1, "parent": parent, "side": p["side"],
			"focus": combat, "util": util, "tags": p["tags"], "role_text": String(b[5]), "children": [], "branch": true,
			"rank": rank, "role": "utility" if combat.is_empty() else "combat", "stat": String(b[2]), "reqs": b[4], "how": String(b[5]), "easy": easy,
			"extra": {}, "item": "", "trial": {}}
		_nodes[id] = node
		if not _branches.has(parent):
			_branches[parent] = []
		_branches[parent].append(node)

static func _add(cls: String, n: Array, tier: int, parent: String) -> String:
	var id := slug(String(n[0]))
	var tags: Array = Array(String(n[3]).split(" ", false))
	var node := {"id": id, "name": n[0], "cls": cls, "tier": tier, "parent": parent, "side": n[1], "focus": _focus(String(n[2])),
		"tags": tags, "role_text": n[4], "children": [], "branch": false, "rank": "", "role": "combat", "util": {}, "stat": "",
		"extra": MID_EXTRA.get(n[0], {}), "item": "", "trial": {}}
	_nodes[id] = node
	if n[5] is Array:
		for c in n[5]:
			node["children"].append(_add(cls, c, tier + 1, id))
	else:
		var ex: Dictionary = n[5]
		node["rank"] = String(ex.get("rank", "S"))
		node["role"] = String(ex.get("role", "combat"))
		node["util"] = _focus(String(ex.get("util", "")))
		node["trial"] = ex.get("trial", {})
		node["item"] = String(ex.get("item", ""))
		node["extra"] = ex.get("extra", {})
		node["stat"] = _final_stat(String(n[0]))
	# Sword Saint needs an item too (it's a level 35 class)
	if id == "sword_saint":
		node["item"] = "masters_blade"
	return id

## The special stat a level 60 final grows (named after the class).
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

static func branches(id: String) -> Array:
	_build()
	return _branches.get(id, [])

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

## The classes on your path, in order (plus a branch-off at the end).
static func path_nodes(g: GameState) -> Array:
	var out: Array = []
	for id in g.class_path:
		var n := node(String(id))
		if not n.is_empty():
			out.append(n)
	if g.class_branch != "":
		var b := node(g.class_branch)
		if not b.is_empty():
			out.append(b)
	return out

static func current(g: GameState) -> Dictionary:
	if g.class_branch != "":
		return node(g.class_branch)
	if g.class_path.is_empty():
		return {}
	return node(String(g.class_path[g.class_path.size() - 1]))

static func title(g: GameState) -> String:
	var c := current(g)
	return String(c["name"]) if not c.is_empty() else g.hero_class

## The unique class you are (a level 60 final or a branch-off), or {}.
static func unique_class(g: GameState) -> Dictionary:
	var c := current(g)
	if c.is_empty() or rank_of(c) == "":
		return {}
	return c

static func stat_name(g: GameState) -> String:
	var u := unique_class(g)
	return String(u.get("stat", "")) if not u.is_empty() else ""

## Which tier you can pick next (0, 1, 2), or -1.
static func pick_tier(g: GameState) -> int:
	if g.hero_class == "" or g.class_branch != "":
		return -1
	var t := g.class_path.size()
	if t >= PICK_LEVELS.size() or g.level < int(PICK_LEVELS[t]):
		return -1
	return t

## The classes you can choose between now (or next).
static func options(g: GameState) -> Array:
	if g.hero_class == "" or g.class_branch != "":
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
	var it := String(n.get("item", ""))
	if it != "" and not it in g.class_items:
		return "Needs the %s" % ITEMS[it]["name"]
	return ""

## Choose a class. God classes start their trial first (you get the class if you win).
static func pick(g: GameState, id: String) -> bool:
	var n := node(id)
	if n.is_empty() or pick_tier(g) < 0:
		return false
	var opts := options(g)
	if not opts.any(func(o): return String(o["id"]) == id):
		return false
	if lock_reason(g, n) != "":
		return false
	if not (n.get("trial", {}) as Dictionary).is_empty() and not g.ctrack.get("trial_" + id, 0):
		return g.start_special_trial(n["trial"], "class_god", {"node": id})
	_take(g, n)
	return true

static func _take(g: GameState, n: Dictionary) -> void:
	g.class_path.append(String(n["id"]))
	g.discovered[n["name"]] = true
	g.codex.add("class_picks")
	_on_new_class(g, n)

static func _on_new_class(g: GameState, n: Dictionary) -> void:
	var r := rank_of(n)
	g.events.append({"type": "class_up", "name": n["name"], "role": n["role_text"], "rank": r, "side": n["side"], "color": g.class_info().get("color", "#ffffff")})
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

## Won a god trial: the class is yours.
static func trial_won(g: GameState, data: Dictionary) -> void:
	var id := String(data.get("node", ""))
	if data.has("item"):
		_give_item(g, String(data["item"]))
		return
	g.ctrack["trial_" + id] = 1
	var n := node(id)
	if n.is_empty():
		return
	if pick_tier(g) >= 0 and options(g).any(func(o): return String(o["id"]) == id) and lock_reason(g, n) == "":
		_take(g, n)

## Picks the first class you can take (for auto mode and simulations).
static func auto_pick(g: GameState) -> void:
	var guard := 0
	while pick_tier(g) >= 0 and guard < 4:
		guard += 1
		var picked := false
		var opts := options(g)
		opts.shuffle()
		for o in opts:
			if lock_reason(g, o) == "" and (o.get("trial", {}) as Dictionary).is_empty():
				_take(g, o)
				picked = true
				break
		if not picked:
			return

# =====================================================================
# Branch-offs
# =====================================================================

## The branch-offs you could take right now (you must be their parent class).
static func open_branches(g: GameState) -> Array:
	if g.class_branch != "" or g.class_path.is_empty() or g.class_path.size() >= 3:
		return []
	return branches(String(g.class_path[g.class_path.size() - 1]))

static func req_value(g: GameState, key: String) -> float:
	if not key.begins_with("live:"):
		return float(g.ctrack.get(key, 0))
	var k := key.substr(5)
	var parts := k.split(":")
	match parts[0]:
		"hated":
			var n := 0
			for r in Races.ORDER:
				if Races.rep_index(Lineage.rep(g, r)) == 0:
					n += 1
			return n
		"exalted":
			for r in Races.ORDER:
				if Races.rep_index(Lineage.rep(g, r)) >= 5:
					return 1
			return 0
		"rep_honored":
			return 1 if Races.rep_index(Lineage.rep(g, parts[1])) >= 4 else 0
		"rep_exalted":
			return 1 if Races.rep_index(Lineage.rep(g, parts[1])) >= 5 else 0
		"friendly_races":
			var n := 0
			for r in Races.ORDER:
				if Races.rep_index(Lineage.rep(g, r)) >= 3:
					n += 1
			return n
		"weapon_types":
			var n := 0
			for t in ["sword", "dagger", "axe", "mace", "spear", "bow", "staff"]:
				if int(g.ctrack.get("kill_w:" + t, 0)) >= 500:
					n += 1
			return n
		"realms_half":
			var n := 0
			for id in Realms.IDS:
				if Realms.completion(g, id) >= 50:
					n += 1
			return n
		"camp_realms":
			var n := 0
			for id in Realms.IDS:
				if g.ctrack.get("camp_" + id, 0):
					n += 1
			return n
		"faith_100":
			return 1 if g.faith >= 99.9 else 0
		"floor100_nodeath":
			return 1 if g.best_floor >= 100 and int(g.ctrack.get("deaths", 0)) == 0 else 0
		"race_keys":
			return g.race_keys.size()
		"vampire80":
			return 1 if g.form == "Vampire" and g.level >= 80 else 0
		"mage_skills":
			for id in SkillData.SKILLS:
				var s: Dictionary = SkillData.SKILLS[id]
				var tags: Array = s.get("tags", [])
				if tags.any(func(t): return t in ["Fire", "Frost", "Storm", "Arcane"]) and not g.skill_book.has(id):
					return 0
			return 1
		"achievements":
			return g.codex.achievements.size()
		"codex_entries":
			return g.codex.bestiary.size() + g.codex.collection.size()
		"world_tree":
			return 1 if "World Tree's Blessing" in g.race_keys or g.feats.get("world_tree", 0) else 0
		"beastkin_awake":
			return 1 if g.race() == "Beastkin" and Lineage.next_rank(g).is_empty() else 0
	return 0

static func progress(g: GameState, b: Dictionary) -> float:
	var reqs: Array = b.get("reqs", [])
	if reqs.is_empty():
		return 1.0
	var p := 0.0
	for r in reqs:
		p += clampf(req_value(g, String(r[0])) / maxf(1.0, float(r[1])), 0.0, 1.0)
	return p / reqs.size()

static func progress_text(g: GameState, b: Dictionary) -> String:
	var parts: Array = []
	for r in b.get("reqs", []):
		var need := float(r[1])
		var have := minf(req_value(g, String(r[0])), need)
		if need <= 1.0:
			parts.append("done" if have >= need else "not yet")
		else:
			parts.append("%s / %s" % [_short(have), _short(need)])
	return ", ".join(parts)

static func _short(v: float) -> String:
	if v >= 1000000.0:
		return "%.1fM" % (v / 1000000.0)
	if v >= 10000.0:
		return "%dk" % int(v / 1000.0)
	return str(int(v))

static func branch_ready(g: GameState, b: Dictionary) -> bool:
	return progress(g, b) >= 1.0

static func take_branch(g: GameState, id: String) -> bool:
	var b := node(id)
	if b.is_empty() or not open_branches(g).any(func(o): return String(o["id"]) == id) or not branch_ready(g, b):
		return false
	g.class_branch = id
	g.discovered[b["name"]] = true
	g.codex.add("branch_offs")
	_on_new_class(g, b)
	return true

## A branch-off became ready: tell the player once.
static func _check_branches(g: GameState) -> void:
	for b in open_branches(g):
		var k := "told_" + String(b["id"])
		if not g.ctrack.get(k, 0) and branch_ready(g, b):
			g.ctrack[k] = 1
			g.events.append({"type": "branch_ready", "name": b["name"], "rank": b["rank"]})
			g.say("[color=%s]A hidden class opens up: %s (%s rank). Take it in the Class tab, or keep climbing your tree.[/color]" % [RANK_COLORS[b["rank"]], b["name"], b["rank"]])

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
	if double:
		count(g, "double_strikes")
	g.cfight["hits"] = int(g.cfight.get("hits", 0)) + 1

static func on_skill(g: GameState, id: String, tags: Array, s: Dictionary) -> void:
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
	g.ctrack["dodge_run"] = int(g.ctrack.get("dodge_run", 0)) + 1
	at_least(g, "dodge_streak", float(g.ctrack["dodge_run"]))
	if (g.cfight.get("tags", {}) as Dictionary).has("Storm"):
		count(g, "dodge_storm")
	g.cfight["enemy_acted"] = true

static func on_hit_taken(g: GameState, dmg: int, shielded: bool) -> void:
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
	_check_branches(g)

static func on_big_hit(g: GameState, dealt: int, crit: bool) -> void:
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
	_maybe_item_encounter(g)
	_check_branches(g)

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
# The Wanderer's item encounters
# =====================================================================

static func _maybe_item_encounter(g: GameState) -> void:
	if g.hero_class != "Wanderer" or not g.path_offer.is_empty() or g.trial_active or g.enemy_is_boss:
		return
	var it := _eligible_item(g)
	if it == "":
		return
	count(g, "item_wait")
	var chance := ITEM_CHANCE * (1.0 + scout_bonus(g) / 100.0)
	if randf() * 100.0 >= chance and float(g.ctrack.get("item_wait", 0)) < ITEM_PITY:
		return
	g.ctrack["item_wait"] = 0
	var d: Dictionary = ITEMS[it]
	g.class_encounter = it
	g.path_offer.assign(["cenc_yes", "cenc_no"])
	g.path_wait = 0
	g.say("[color=#e8b14a]%s.[/color] %s" % [d["title"], d["talk"]])
	g.events.append({"type": "mini_event", "kind": "class_item", "title": String(d["title"]).to_upper(), "sub": "A meeting on the road"})

static func _eligible_item(g: GameState) -> String:
	if g.class_path.is_empty():
		return ""
	var here := String(g.class_path[g.class_path.size() - 1])
	for it in ITEMS:
		var d: Dictionary = ITEMS[it]
		if it in g.class_items or String(d["at"]) != here or g.level < int(d["level"]):
			continue
		match String(d["where"]):
			"elf", "dwarf", "demon":
				if GameData.realm_of(g.floor_num) != String(d["where"]):
					continue
			"moon":
				if not Lineage.full_moon(g.floor_num):
					continue
			_:
				if g.floor_num < 30:
					continue
		if d.has("rep") and Races.rep_index(Lineage.rep(g, String(d["rep"]))) < 4:
			continue
		return it
	return ""

static func path_info(kind: String, g: GameState) -> Dictionary:
	var d: Dictionary = ITEMS.get(g.class_encounter, {})
	if kind == "cenc_yes":
		var t := "Win the %s." % d["name"] if d.has("fight") else "Receive the %s." % d.get("name", "item")
		if d.has("cost"):
			t += " Costs %d gold." % item_cost(g, d)
		if d.get("full_hp", false):
			t += " You start at full HP and can't drink potions."
		return {"name": d.get("yes", "Go"), "text": t, "color": "#e8b14a"}
	return {"name": "Walk on", "text": "It may come your way again.", "color": "#cbd5e1"}

static func item_cost(g: GameState, d: Dictionary) -> int:
	return int(d.get("cost", 0)) * (5 + g.floor_num * 4)

static func encounter_choice(g: GameState, yes: bool) -> void:
	var it := g.class_encounter
	g.class_encounter = ""
	if not ITEMS.has(it):
		return
	var d: Dictionary = ITEMS[it]
	if not yes:
		g.say("You leave %s behind. Maybe you'll meet again." % String(d["title"]).to_lower())
		g.ctrack["item_wait"] = ITEM_PITY / 2
		return
	if d.has("cost"):
		var c := item_cost(g, d)
		if g.gold < c:
			g.say("[color=#f87171]You can't pay (%d gold).[/color]" % c)
			return
		g.gold -= c
	if not d.has("fight"):
		_give_item(g, it)
		return
	if d.get("full_hp", false):
		g.hero_hp = g.get_max_hp()
	g.start_special_trial(d["fight"], "class_item", {"item": it, "no_potions": d.get("no_potions", false)})

static func _give_item(g: GameState, it: String) -> void:
	if it in g.class_items:
		return
	g.class_items.append(it)
	var d: Dictionary = ITEMS[it]
	var n := node(String(d["node"]))
	var line := "spare him, and he gives you" if d.get("spare", false) else "receive"
	g.say("[color=#fbbf24]You %s the %s![/color] It opens the way to %s." % [line, d["name"], n.get("name", "?")])
	g.events.append({"type": "class_item", "name": d["name"], "opens": n.get("name", "")})
	g.save_game()

# =====================================================================
# Saving
# =====================================================================

static func to_save(g: GameState) -> Dictionary:
	return {"path": g.class_path, "branch": g.class_branch, "track": g.ctrack, "items": g.class_items, "auto": g.class_auto}

static func from_save(g: GameState, d: Dictionary) -> void:
	g.class_path.assign(d.get("path", []))
	g.class_branch = String(d.get("branch", ""))
	g.ctrack = d.get("track", {})
	g.class_items.assign(d.get("items", []))
	g.class_auto = bool(d.get("auto", false))
	# Drop anything that no longer exists
	var keep: Array[String] = []
	for id in g.class_path:
		if not node(String(id)).is_empty() and node(String(id))["cls"] == g.hero_class:
			keep.append(String(id))
	g.class_path = keep
	if g.class_branch != "" and node(g.class_branch).is_empty():
		g.class_branch = ""
