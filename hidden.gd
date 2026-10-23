class_name Hidden
extends RefCounted
## Hidden classes (reworked with Juzo, Oct 20): secret classes you earn by doing
## hard, unusual things in the game, often by accident. You are never told the
## requirements (rumors only). What you have earned stays a surprise until you
## reach level 15, 35 or 75: then every hidden class you have earned is offered
## beside your normal evolution choices, and you can take one until your next
## level-up. Past 75 nothing new is offered here; only a God class can still
## answer (god_classes.gd), and most of those only a hero on the main route.
##
## Taking a hidden class is for good: it becomes your class instead of the main
## route (no more evolutions; you keep what you already have). Each one is strong
## and grows in three clear steps, at levels 15, 35 and 75 (STAGE_LEVELS), each
## adding raw power (STAGE_POWER) plus that class's own specialty.
##
##  * Discoveries, Masteries and Legends differ in how hard they are to earn.
##    Some Legends can only be held by one hero on your account at a time.
##
## Story text here is a placeholder until the lore is written.

const TIER_NAMES := ["", "Discovery", "Mastery", "Legend"]
const TIER_COLORS := ["", "#4ade80", "#38bdf8", "#e8b14a"]
const STAT_SCALE := [0.0, 1.0, 1.4, 2.0]  # how far a tier's special stat scales

# need: [label, feat key or special, amount]. Special keys are worked out in _have().
# stages: the three names (levels 15, 35, 75); stage_bonus: that class's specialty added at each step.
# grow: action -> special stat per action (only while this is your hidden class).
# per_point: bonus per point of its special stat.
const CLASSES := {
	"jester": {"name": "Jester", "tier": 1, "stat": "Luck", "color": "#a8ca58",
		"lore": "Fortune favors the foolish. You've noticed.",
		"rumor": "They say the Wheel loves someone who keeps winning...",
		"need": [["Win the Wheel 5 times in a row", "wheel_best", 5]],
		"stages": ["Jester", "Grand Jester", "The Laughing Fate"], "stage_bonus": [{"crit": 5, "gold_find": 10, "dodge": 3}, {"crit": 6, "gold_find": 15, "dodge": 3}, {"crit": 8, "gold_find": 20, "dodge": 5}],
		"grow": {"gamble": 1.0, "crit": 0.005}, "per_point": {"crit": 0.04, "gold_find": 0.1}},
	"treasure_hunter": {"name": "Treasure Hunter", "tier": 1, "stat": "Fortune", "color": "#facc15",
		"lore": "Some people hear a goblin's coins jingle three floors away.",
		"rumor": "Catch enough of those little thieves and you start thinking like one...",
		"need": [["Catch 25 treasure goblins", "goblins", 25]],
		"stages": ["Treasure Hunter", "Goldseeker", "Lord of Hoards"], "stage_bonus": [{"gold_find": 20, "stone_find": 10}, {"gold_find": 25, "stone_find": 10, "crit": 3}, {"gold_find": 35, "stone_find": 15, "crit": 4}],
		"grow": {"goblin": 2.0, "rare_kill": 0.2}, "per_point": {"gold_find": 0.15, "stone_find": 0.05}},
	"fool": {"name": "The Fool", "tier": 1, "stat": "Folly", "color": "#f472b6",
		"lore": "Fall down two hundred and fifty times. Get up once more.",
		"rumor": "Some say dying enough times teaches you something...",
		"need": [["Fall 250 times on this hero", "deaths", 250]],
		"stages": ["The Fool", "The Undying Fool", "The Last Laugh"], "stage_bonus": [{"hp": 1.1, "rage": 10}, {"hp": 1.1, "regen": 1}, {"hp": 1.15, "rage": 10, "regen": 1}],
		"grow": {"death": 0.1, "hit": 0.001}, "per_point": {"hp": 0.001, "regen": 0.002}},
	"alchemist": {"name": "Alchemist", "tier": 1, "stat": "Elixir", "color": "#2dd4bf",
		"lore": "You've drunk enough potions to know what's really in them.",
		"rumor": "Drink enough potions and you start to taste the recipe...",
		"need": [["Craft 200 potions", "potions_crafted", 200], ["Drink 300 potions", "potions_drunk", 300]],
		"stages": ["Alchemist", "Master Alchemist", "The Philosopher"], "stage_bonus": [{"potion": 30, "regen": 1}, {"potion": 30, "regen": 1, "skill": 1.05}, {"potion": 40, "regen": 2, "skill": 1.08}],
		"grow": {"potion": 0.5, "craft": 0.2}, "per_point": {"potion": 0.5, "regen": 0.01}},

	"gladiator": {"name": "Gladiator", "tier": 2, "stat": "Glory", "color": "#dc2626",
		"lore": "A thousand fights. No running, no potions, no excuses.",
		"rumor": "The arena only respects those who never run and never drink...",
		"need": [["Reach level 60", "level", 60], ["Win 1,000 fights in a row without escaping, dying or a potion", "clean_best", 1000],
			["Beat the Arena Champion", "trial", 1]],
		"trial": {"name": "The Arena Champion", "art": "boss_grendel", "lore": "Undefeated in nine hundred fights. Ten if you count the ones he lost."},
		"stages": ["Gladiator", "Arena Lord", "The Undefeated"], "stage_bonus": [{"atk": 1.06, "def": 1.06}, {"atk": 1.1, "hp": 1.1}, {"atk": 1.12, "def": 1.1}],
		"grow": {"kill": 0.01, "boss": 1.0}, "per_point": {"atk": 0.001, "def": 0.001}},
	"executioner": {"name": "Executioner", "tier": 2, "stat": "Dread", "color": "#8b5cf6",
		"lore": "You don't fight monsters anymore. You end them.",
		"rumor": "They say a hero who finishes enough fights with a skill earns a darker name...",
		"need": [["Reach level 60", "level", 60], ["Finish 5,000 monsters with a skill", "skill_kills", 5000],
			["Finish 25 Legendary or Mythic monsters with a skill", "skill_kills_elite", 25], ["Finish a zone boss with a skill", "boss_skill_finish", 1]],
		"stages": ["Executioner", "Headsman of Kings", "The Final Blade"], "stage_bonus": [{"execute": 25, "crit": 4}, {"execute": 25, "atk": 1.08}, {"execute": 30, "crit": 6}],
		"grow": {"skill_kill": 0.05}, "per_point": {"execute": 0.2, "crit": 0.02}},
	"plague_doctor": {"name": "Plague Doctor", "tier": 2, "stat": "Miasma", "color": "#84cc16",
		"lore": "You don't kill them. The rot does. You just help it along.",
		"rumor": "Burn enough monsters to ash and the smoke starts to talk...",
		"need": [["Reach level 60", "level", 60], ["5,000 kills from burns", "burn_kills", 5000], ["Kill a zone boss with a burn", "burn_boss", 1]],
		"stages": ["Plague Doctor", "Pestilence", "The Black Death"], "stage_bonus": [{"skill": 1.08, "regen": 1}, {"skill": 1.1, "hp": 1.08}, {"skill": 1.12, "lifesteal": 3}],
		"grow": {"burn_kill": 0.05}, "per_point": {"skill": 0.002, "lifesteal": 0.02}, "burn_power": 0.5},
	"beast_tamer": {"name": "Beast Tamer", "tier": 2, "stat": "Bond", "color": "#d9a066",
		"lore": "Every monster you let go remembers you. Some of them come back.",
		"rumor": "They say a hero nothing can hold, who walks away from a hundred fights untouched, starts to hear the beasts...",
		"need": [["Reach level 60", "level", 60], ["Walk away from 100 monsters with a sure (100%) run-away chance", "sure_escapes", 100]],
		"stages": ["Beast Tamer", "Beast Lord", "Wild King"], "stage_bonus": [{"hp": 1.06, "dodge": 3}, {"atk": 1.06, "hp": 1.08}, {"atk": 1.08, "hp": 1.1}],
		"grow": {"spare": 1.0, "kill": 0.005}, "per_point": {"hp": 0.001, "dodge": 0.02}},

	"chosen_hero": {"name": "Chosen Hero", "tier": 3, "stat": "Destiny", "color": "#fde68a", "one_per_account": true,
		"lore": "Nobody chose you. You reached the bottom of the world anyway, with one life.",
		"rumor": "They say only one hero, with only one life, will ever reach the deepest realm...",
		"need": [["Reach floor 500 on Hardcore", "hc_floor", 500]],
		"stages": ["Chosen Hero", "Hero of the Realms", "The Hero of Legend"],
		"stage_bonus": [{"atk": 1.08, "hp": 1.08, "xp": 10}, {"atk": 1.08, "hp": 1.08}, {"atk": 1.1, "hp": 1.1, "def": 1.08}],
		"grow": {"boss": 1.0, "floor": 0.05}, "per_point": {"atk": 0.001, "hp": 0.001}},
	"demon_king": {"name": "Demon King", "tier": 3, "stat": "Dominion", "color": "#e43b44", "one_per_account": true,
		"lore": "The Abyss has had many lords. It has only ever had one king at a time.",
		"rumor": "A demon lord who takes the Abyss's throne with a heart of pure evil...",
		"need": [["A Demon at the top Demonic rank", "demon_top", 1], ["Defeat the ruler of the Cinder Abyss", "boss:azgaroth", 1],
			["Evil faith of 95 or more", "evil", 95]],
		"stages": ["Demon King", "Abyssal Sovereign", "The Demon God"],
		"stage_bonus": [{"atk": 1.1, "lifesteal": 4}, {"atk": 1.08, "hp": 1.08}, {"atk": 1.1, "hp": 1.1, "lifesteal": 3}],
		"grow": {"kill": 0.01, "evil": 0.3, "low_hp_kill": 0.1}, "per_point": {"atk": 0.001, "lifesteal": 0.02}},

	# ---- More hidden classes. Some are for one race or one class route only. ----
	# Discoveries (race- or class-bound, earned by living a certain way)
	"grave_warden": {"name": "Grave Warden", "tier": 1, "stat": "Gravechill", "color": "#94a3b8",
		"lore": "The dead keep your secrets, and you keep theirs. Nothing that touches you leaves warm.",
		"rumor": "The risen who keep coming back for their own bones are said to learn the cold...",
		"need": [["Be Undead", "race:Undead", 1], ["Recover your grave 8 times", "codex:graves", 8], ["Fall 25 times on this hero", "deaths", 25]],
		"stages": ["Grave Warden", "Crypt Keeper", "The Deathless Sentinel"], "stage_bonus": [{"thorns": 8, "regen": 1}, {"thorns": 12, "regen": 1, "def": 1.06}, {"thorns": 18, "regen": 2, "def": 1.08}],
		"grow": {"death": 0.5, "hit": 0.002}, "per_point": {"thorns": 0.1, "regen": 0.004}},
	"packrunner": {"name": "Packrunner", "tier": 1, "stat": "Instinct", "color": "#d9a066",
		"lore": "You stopped thinking about the way out. Your legs know it.",
		"rumor": "A beast-blooded hero who is never caught, and who keeps company with strays, may be called by the pack...",
		"need": [["Be Beastkin", "race:Beastkin", 1], ["Walk away from 30 monsters with a sure run-away chance", "sure_escapes", 30], ["Keep 3 pets", "codex:pets", 3]],
		"stages": ["Packrunner", "Wolfhearted", "Voice of the Pack"], "stage_bonus": [{"dodge": 5, "escape": 10}, {"dodge": 6, "escape": 12, "crit": 4}, {"dodge": 8, "escape": 15, "crit": 6}],
		"grow": {"flee": 0.5, "dodge": 0.05}, "per_point": {"dodge": 0.03, "escape": 0.05}},
	"moon_sentinel": {"name": "Moon Sentinel", "tier": 1, "stat": "Moonlight", "color": "#a5f3fc",
		"lore": "Every snare was laid by someone. You always know who, and where they were standing.",
		"rumor": "An elf who spots every trap before it springs begins to see in the dark...",
		"need": [["Be an Elf", "race:Elf", 1], ["Spot 30 traps before they spring", "codex:traps_spotted", 30], ["Befriend 5 kinds of monster", "befriended", 5]],
		"stages": ["Moon Sentinel", "Warden of the Pale Wood", "The Unseen Archer"], "stage_bonus": [{"crit": 5, "dodge": 4}, {"crit": 6, "dodge": 5, "skill": 1.05}, {"crit": 8, "dodge": 6, "skill": 1.08}],
		"grow": {"crit": 0.01, "dodge": 0.01}, "per_point": {"crit": 0.03, "dodge": 0.03}},
	"deepdelver": {"name": "Deepdelver", "tier": 1, "stat": "Delve", "color": "#b45309",
		"lore": "Stone sings when you strike it right. Most of what you carry up was never meant to be found.",
		"rumor": "A dwarf who keeps hauling stones out of the deep and sets after set at the forge may hear the mountain...",
		"need": [["Be a Dwarf", "race:Dwarf", 1], ["Find 60 skill stones", "codex:stones", 60], ["Craft 5 sets", "codex:sets_crafted", 5]],
		"stages": ["Deepdelver", "Mountainheart", "Under-King"], "stage_bonus": [{"stone_find": 20, "scrap": 20, "def": 1.04}, {"stone_find": 25, "scrap": 30, "def": 1.06}, {"stone_find": 35, "scrap": 40, "def": 1.1}],
		"grow": {"craft": 0.3, "rare_kill": 0.2}, "per_point": {"stone_find": 0.1, "scrap": 0.1}},
	"pocket_king": {"name": "Pocket King", "tier": 1, "stat": "Cunning", "color": "#bef264",
		"lore": "Everything has a price, and you know how to make it a little lower and a little lighter.",
		"rumor": "A goblin who haggles for sport and buys more than they need might be crowned in a back alley...",
		"need": [["Be a Goblin", "race:Goblin", 1], ["Buy from the merchant 40 times", "codex:merchant_buys", 40], ["Win 8 haggles", "codex:haggles_won", 8]],
		"stages": ["Pocket King", "Prince of Thieves", "The Goblin Emperor"], "stage_bonus": [{"gold_find": 25, "escape": 8}, {"gold_find": 30, "escape": 8, "scrap": 20}, {"gold_find": 40, "escape": 10, "scrap": 30}],
		"grow": {"goblin": 1.0, "flee": 0.3}, "per_point": {"gold_find": 0.12, "escape": 0.04}},
	"warchief": {"name": "Warchief", "tier": 1, "stat": "Bloodlust", "color": "#65a30d",
		"lore": "They follow the one who is still standing. You are always still standing.",
		"rumor": "An orc who breaks horde after horde, and never staggers, may be named in the camps...",
		"need": [["Be an Orc", "race:Orc", 1], ["Break 10 hordes", "codex:hordes", 10], ["Win 100 fights in a row without escaping, dying or a potion", "clean_best", 100]],
		"stages": ["Warchief", "Bloodied Warlord", "The Horde Itself"], "stage_bonus": [{"rage": 12, "atk": 1.04}, {"rage": 15, "atk": 1.05, "hp": 1.05}, {"rage": 20, "atk": 1.08, "hp": 1.06}],
		"grow": {"kill": 0.02, "low_hp_kill": 0.2}, "per_point": {"rage": 0.03, "atk": 0.0005}},
	"dewspinner": {"name": "Dewspinner", "tier": 1, "stat": "Glamour", "color": "#f0abfc",
		"lore": "A wrong turn, a borrowed name, a smile that was never there. They never find where you went.",
		"rumor": "A fairy who muddles a hundred minds and bows at shrines may be taught to disappear...",
		"need": [["Be a Fairy", "race:Fairy", 1], ["Confuse monsters with skills 60 times", "confuses", 60], ["Pray at 5 shrines", "codex:shrines", 5]],
		"stages": ["Dewspinner", "Mistweaver", "Queen of the Hollow Hill"], "stage_bonus": [{"charm": 8, "dodge": 5}, {"charm": 10, "dodge": 6, "escape": 8}, {"charm": 14, "dodge": 8, "escape": 10}],
		"grow": {"confuse": 0.5, "dodge": 0.05}, "per_point": {"charm": 0.05, "dodge": 0.03}},
	"fallen_knight": {"name": "Fallen Knight", "tier": 1, "stat": "Oath-Ruin", "color": "#7c3aed",
		"lore": "You swore to protect. Then you swore to something else. The armor remembers both.",
		"rumor": "A Knight who breaks oaths and lets no blow land clean may take up a blacker banner...",
		"need": [["Start as a Knight", "class:Knight", 1], ["Evil faith of 50 or more", "evil", 50], ["Defeat 1,500 monsters", "kills_total", 1500]],
		"stages": ["Fallen Knight", "Oathbreaker", "The Black Banner"], "stage_bonus": [{"lifesteal": 3, "thorns": 8}, {"lifesteal": 4, "thorns": 12, "atk": 1.05}, {"lifesteal": 5, "thorns": 16, "atk": 1.08}],
		"grow": {"evil": 0.2, "hit": 0.002}, "per_point": {"lifesteal": 0.02, "thorns": 0.08}},

	# Masteries (a level-35 feat or more)
	"seraph_of_mercy": {"name": "Seraph of Mercy", "tier": 2, "stat": "Mercy", "color": "#fef3c7",
		"lore": "You spared what begged. Some of them were only pretending. You would do it again.",
		"rumor": "An angel who forgives a great many monsters is said to be given a second pair of wings...",
		"need": [["Be an Angel", "race:Angel", 1], ["Reach level 35", "level", 35], ["Spare 60 monsters", "codex:spared", 60], ["Good faith of 80 or more", "good", 80]],
		"stages": ["Seraph of Mercy", "Dawn Seraph", "The Last Mercy"], "stage_bonus": [{"regen": 2, "potion": 30, "hp": 1.06}, {"regen": 2, "potion": 40, "hp": 1.08}, {"regen": 3, "potion": 50, "hp": 1.1}],
		"grow": {"spare": 0.5, "good": 0.05, "heal": 0.2}, "per_point": {"regen": 0.01, "potion": 0.3}},
	"wyrmheart": {"name": "Wyrmheart", "tier": 2, "stat": "Dragonfire", "color": "#f97316",
		"lore": "Your breath is a verdict. The things you burn do not get up, and neither do their friends.",
		"rumor": "A dragon's child who has burned the dungeon black may find the old flame in their chest...",
		"need": [["Be Dragonkin", "race:Dragonkin", 1], ["Reach level 35", "level", 35], ["1,500 kills from burns", "burn_kills", 1500]],
		"stages": ["Wyrmheart", "Flamebound Drake", "Wyrm Ascendant"], "stage_bonus": [{"skill": 1.08, "boss": 8}, {"skill": 1.1, "boss": 10, "atk": 1.05}, {"skill": 1.12, "boss": 15, "atk": 1.08}],
		"grow": {"burn_kill": 0.05, "boss": 1.0}, "per_point": {"skill": 0.002, "boss": 0.04}, "burn_power": 0.4},
	"ironbound": {"name": "Ironbound", "tier": 2, "stat": "Bulwark", "color": "#9ca3af",
		"lore": "Something was carved into your chest once. It says: do not stop. You have not.",
		"rumor": "A thing of stone and gears that never once yields may be given a second, harder shell...",
		"need": [["Be a Golem", "race:Golem", 1], ["Reach level 35", "level", 35], ["Win 400 fights in a row without escaping, dying or a potion", "clean_best", 400]],
		"stages": ["Ironbound", "Bastion Colossus", "The Unmoved"], "stage_bonus": [{"def": 1.08, "thorns": 10}, {"def": 1.1, "thorns": 14, "hp": 1.08}, {"def": 1.12, "thorns": 20, "hp": 1.1}],
		"grow": {"hit": 0.003, "kill": 0.01}, "per_point": {"def": 0.001, "thorns": 0.1}},
	"wayfarer_prince": {"name": "Wayfarer Prince", "tier": 2, "stat": "Renown", "color": "#fcd34d",
		"lore": "You are the only one who ever walks out again, and the roads have started to say your name first.",
		"rumor": "A plain traveler who meets everyone on the road and always comes home may be crowned by strangers...",
		"need": [["Be Human", "race:Human", 1], ["Reach level 35", "level", 35], ["Meet 30 travelers", "codex:travelers", 30], ["Come home safe from 40 dives", "codex:home_trips", 40]],
		"stages": ["Wayfarer Prince", "Road King", "Sovereign of the Open Road"], "stage_bonus": [{"xp": 12, "gold_find": 12, "escape": 8}, {"xp": 15, "gold_find": 15, "escape": 10}, {"xp": 20, "gold_find": 20, "escape": 12}],
		"grow": {"floor": 0.1, "flee": 0.2}, "per_point": {"xp": 0.1, "gold_find": 0.08}},
	"soul_broker": {"name": "Soul Broker", "tier": 2, "stat": "Contracts", "color": "#be123c",
		"lore": "Every bargain has a clause, and you wrote them all. The fine print drinks.",
		"rumor": "A demon who kneels at every cursed shrine learns to read the small print of damnation...",
		"need": [["Be a Demon", "race:Demon", 1], ["Reach level 35", "level", 35], ["Evil faith of 60 or more", "evil", 60], ["Pray at 20 shrines", "codex:shrines", 20]],
		"stages": ["Soul Broker", "Pact Lord", "The Collector"], "stage_bonus": [{"lifesteal": 4, "execute": 12}, {"lifesteal": 5, "execute": 15, "atk": 1.06}, {"lifesteal": 6, "execute": 20, "atk": 1.08}],
		"grow": {"evil": 0.2, "shrine": 1.0}, "per_point": {"lifesteal": 0.02, "execute": 0.1}},
	"voidweaver": {"name": "Voidweaver", "tier": 2, "stat": "Void", "color": "#6366f1",
		"lore": "Your spells do not cast. They happen. Reality is only slow to agree.",
		"rumor": "A mage who ends fights with spells alone, and sells off what spells they spare, may be offered the Gap between...",
		"need": [["Start as a Mage", "class:Mage", 1], ["Reach level 35", "level", 35], ["Finish 2,000 monsters with a skill", "skill_kills", 2000], ["Sell 5 skills", "codex:skills_sold", 5]],
		"stages": ["Voidweaver", "Rift Mage", "The Unwritten"], "stage_bonus": [{"skill": 1.1, "crit": 4}, {"skill": 1.12, "crit": 5, "atk": 1.05}, {"skill": 1.15, "crit": 6, "atk": 1.08}],
		"grow": {"skill_kill": 0.05, "confuse": 0.2}, "per_point": {"skill": 0.002, "crit": 0.03}},
	"quiet_death": {"name": "Quiet Death", "tier": 2, "stat": "Silence", "color": "#475569",
		"lore": "The last thing they hear is nothing at all.",
		"rumor": "An assassin who ends the great ones without a breath of noise may no longer be seen at all...",
		"need": [["Take the Assassin path", "path:assassin", 1], ["Reach level 35", "level", 35], ["Finish 40 Legendary or Mythic monsters with a skill", "skill_kills_elite", 40], ["Win 150 fights in a row without escaping, dying or a potion", "clean_best", 150]],
		"stages": ["Quiet Death", "Hush Incarnate", "The Last Silence"], "stage_bonus": [{"execute": 15, "crit": 6, "dodge": 3}, {"execute": 18, "crit": 6, "dodge": 4}, {"execute": 25, "crit": 8, "dodge": 5}],
		"grow": {"rare_kill": 0.2, "low_hp_kill": 0.2}, "per_point": {"execute": 0.15, "crit": 0.03}},
	"grail_warden": {"name": "Grail Warden", "tier": 2, "stat": "Vow", "color": "#fde047",
		"lore": "You were handed a cup and told never to spill it. You have walked a thousand miles with it.",
		"rumor": "A paladin who is good to the bone and helps every pilgrim may be given something to carry...",
		"need": [["Take the Paladin path", "path:paladin", 1], ["Reach level 35", "level", 35], ["Good faith of 90 or more", "good", 90], ["Help 5 pilgrims", "codex:pilgrims_helped", 5]],
		"stages": ["Grail Warden", "Keeper of the Cup", "The Holy Vessel"], "stage_bonus": [{"def": 1.06, "regen": 2, "thorns": 8}, {"def": 1.08, "regen": 2, "thorns": 12, "hp": 1.06}, {"def": 1.1, "regen": 3, "thorns": 16, "hp": 1.08}],
		"grow": {"good": 0.1, "hit": 0.002, "boss": 1.0}, "per_point": {"def": 0.001, "regen": 0.008}},

	# Legends (very hard, some can be held by only one hero on the account)
	"ancient_wyrm": {"name": "Ancient Wyrm", "tier": 3, "stat": "Wyrmblood", "color": "#dc2626", "one_per_account": true,
		"lore": "The first wyrm is dead. You woke up wearing her scales and nobody dared correct you.",
		"rumor": "A dragon's child, fully awakened, who has walked the deepest rifts and the deepest floors, may be recognised by the old ones...",
		"need": [["Be Dragonkin", "race:Dragonkin", 1], ["Reach the top Dragonkin awakening rank", "top_rank", 1], ["Clear 20 deep rifts", "codex:deep_rifts", 20], ["Reach floor 250", "floor", 250]],
		"stages": ["Ancient Wyrm", "Wyrm Sovereign", "The World-Eater"], "stage_bonus": [{"atk": 1.08, "boss": 12, "execute": 10}, {"atk": 1.08, "hp": 1.08, "boss": 15}, {"atk": 1.1, "hp": 1.1, "boss": 20, "execute": 10}],
		"grow": {"boss": 1.0, "burn_kill": 0.05, "floor": 0.05}, "per_point": {"atk": 0.001, "boss": 0.05}, "burn_power": 0.6},
	"lich_sovereign": {"name": "Lich Sovereign", "tier": 3, "stat": "Unlife", "color": "#22d3ee", "one_per_account": true,
		"lore": "You gave up breath, then pulse, then name. What is left sits on a throne of other people's bones.",
		"rumor": "Only a dead mage, awakened to the last, who has cast the world to death, may sit the Bone Throne...",
		"need": [["Start as a Mage", "class:Mage", 1], ["Be Undead", "race:Undead", 1], ["Reach the top Undead awakening rank", "top_rank", 1],
			["Reach level 60", "level", 60], ["Finish 4,000 monsters with a skill", "skill_kills", 4000]],
		"stages": ["Lich Sovereign", "Bone Emperor", "The Lord of Endings"], "stage_bonus": [{"skill": 1.1, "lifesteal": 4, "regen": 2}, {"skill": 1.12, "hp": 1.08, "lifesteal": 4}, {"skill": 1.15, "lifesteal": 5, "execute": 15}],
		"grow": {"skill_kill": 0.08, "death": 0.3}, "per_point": {"skill": 0.002, "lifesteal": 0.02}},
	"last_wanderer": {"name": "The Last Wanderer", "tier": 3, "stat": "Journey", "color": "#fdba74",
		"lore": "You never took a class. You took a road, and it took you all the way to the edge of the map.",
		"rumor": "A martial wanderer who comes home from a hundred dives and has seen the far floors may be named by the road itself...",
		"need": [["Start as a Wanderer", "class:Wanderer", 1], ["Reach level 60", "level", 60], ["Clear 25 deep rifts", "codex:deep_rifts", 25], ["Come home safe from 120 dives", "codex:home_trips", 120], ["Reach floor 300", "floor", 300]],
		"stages": ["The Last Wanderer", "Walker Between Worlds", "The Road Made Flesh"], "stage_bonus": [{"crit": 6, "double_strike": 8, "dodge": 4}, {"crit": 7, "double_strike": 10, "dodge": 5, "atk": 1.06}, {"crit": 9, "double_strike": 14, "dodge": 6, "atk": 1.08}],
		"grow": {"floor": 0.1, "boss": 0.5, "flee": 0.2}, "per_point": {"double_strike": 0.04, "crit": 0.03}},
	"mythbreaker": {"name": "Mythbreaker", "tier": 3, "stat": "Infamy", "color": "#f43f5e",
		"lore": "Legends are only stories that nobody finished. You finish them.",
		"rumor": "They say a hero who ends the great ones without a scratch, over and over, becomes a story the stories fear...",
		"need": [["Reach level 60", "level", 60], ["Finish 250 Legendary or Mythic monsters with a skill", "skill_kills_elite", 250], ["Defeat 30 champions", "codex:champions", 30],
			["Win 1,500 fights in a row without escaping, dying or a potion", "clean_best", 1500]],
		"stages": ["Mythbreaker", "Legend-Slayer", "The Last Story"], "stage_bonus": [{"boss": 15, "atk": 1.08, "crit": 5}, {"boss": 18, "atk": 1.08, "crit": 6, "execute": 10}, {"boss": 25, "atk": 1.1, "crit": 8, "execute": 15}],
		"grow": {"boss": 1.0, "rare_kill": 0.3, "skill_kill": 0.05}, "per_point": {"boss": 0.06, "atk": 0.001}},
}
const ORDER := ["jester", "treasure_hunter", "fool", "alchemist", "gladiator", "executioner", "plague_doctor", "beast_tamer",
	"chosen_hero", "demon_king",
	"grave_warden", "packrunner", "moon_sentinel", "deepdelver", "pocket_king", "warchief", "dewspinner", "fallen_knight",
	"seraph_of_mercy", "wyrmheart", "ironbound", "wayfarer_prince", "soul_broker", "voidweaver", "quiet_death", "grail_warden",
	"ancient_wyrm", "lich_sovereign", "last_wanderer", "mythbreaker"]

static func info(id: String) -> Dictionary:
	return CLASSES.get(id, {})

# ---------- Counting what you do ----------

static func count(g: GameState, key: String, n := 1) -> void:
	g.feats[key] = int(g.feats.get(key, 0)) + n

static func best(g: GameState, key: String, value: int) -> void:
	g.feats[key] = maxi(int(g.feats.get(key, 0)), value)

static func flag(g: GameState, key: String) -> void:
	g.feats[key] = 1

## How much of a requirement you have.
static func _have(g: GameState, key: String) -> int:
	match key:
		"level":
			return g.level
		"befriended":
			return (g.feats.get("befriended", {}) as Dictionary).size()
		"befriended_tiers":
			return (g.feats.get("befriended_tiers", {}) as Dictionary).size()
		"wanderer_level":
			return g.level if g.hero_class == "Wanderer" else 0
		"hc_floor":
			return g.best_floor if g.hardcore else 0
		"demon_top":
			return 1 if g.race() == "Demon" and g.awaken >= Races.ranks("Demon").size() else 0
		"evil":
			return int(-g.faith)
		"good":
			return int(g.faith)
		"floor":
			return g.best_floor
		"top_rank":
			return 1 if g.awaken >= Races.ranks(g.race()).size() else 0
		"class_kills":
			return int((g.feats.get("class_kills", {}) as Dictionary).get(g.hidden_class, 0))
	if key.begins_with("boss:"):
		return g.codex.kills(key.substr(5))
	# boss:<monster id> (account kills of that boss), race:Elf, class:Knight (your base class),
	# path:<class node id> (any evolution you took, e.g. path:paladin),
	# codex:<stat> (an account counter that the game really adds to)
	if key.begins_with("race:"):
		return 1 if g.race() == key.substr(5) else 0
	if key.begins_with("class:"):
		return 1 if g.hero_class == key.substr(6) else 0
	if key.begins_with("path:"):
		for n in ClassTree.path_nodes(g):
			if String((n as Dictionary).get("id", "")) == key.substr(5):
				return 1
		return 0
	if key.begins_with("codex:"):
		return g.codex.stat(key.substr(6))
	return int(g.feats.get(key, 0))

## [[label, have, need], ...] for what unlocks a class.
static func progress(g: GameState, id: String) -> Array:
	var out: Array = []
	for n in info(id)["need"]:
		if n[1] == "trial":
			out.append([n[0], 1 if g.feats.get("trial_" + id, 0) else 0, 1])
		else:
			out.append([n[0], _have(g, n[1]), int(n[2])])
	return out

## 0..1: how close you are (used for ??? hints).
static func closeness(g: GameState, id: String) -> float:
	var p := progress(g, id)
	var t := 0.0
	for line in p:
		t += clampf(float(line[1]) / maxf(1.0, float(line[2])), 0.0, 1.0)
	return t / maxf(1.0, p.size())

## Everything but the trial is done.
static func ready_for_trial(g: GameState, id: String) -> bool:
	for line in progress(g, id):
		if line[0] != "" and int(line[1]) < int(line[2]) and not String(line[0]).begins_with("Beat"):
			return false
	return info(id).has("trial") and not g.feats.get("trial_" + id, 0)

## Who holds a one-per-account Legend (a slot number, 0 = nobody).
static func holder(g: GameState, id: String) -> int:
	var slot := g.codex.stat("legend_" + id)
	if slot > 0 and slot != g.slot and not GameState.has_slot(slot):
		return 0
	return slot

static func block_reason(g: GameState, id: String) -> String:
	if g.hidden.has(id):
		return ""
	var c := info(id)
	if c.get("one_per_account", false):
		var h := holder(g, id)
		if h > 0 and h != g.slot:
			return "Another of your heroes already holds this title"
	for line in progress(g, id):
		if String(line[0]).begins_with("Beat"):
			continue  # a champion trial is fought when you take the class, not to earn it
		if int(line[1]) < int(line[2]):
			return line[0]
	return ""

## Checks every hidden class and quietly banks any you've earned.
static func check(g: GameState) -> void:
	GodClasses.check(g)  # a God class answers the moment its deeds are done
	if g.hidden_class != "" or g.god_class != "":
		return  # you already walk a hidden path
	for id in ORDER:
		if not g.hidden.has(id) and block_reason(g, id) == "":
			unlock(g, id)

## Earned, but it stays a surprise: you only see it at level 15, 35 or 75.
static func unlock(g: GameState, id: String) -> void:
	var c := info(id)
	g.hidden[id] = true
	if c.get("one_per_account", false):
		g.codex.stats["legend_" + id] = g.slot
		g.codex.dirty = true
	g.codex.add("hidden_classes")
	g.say("[color=#c4b5fd]Something in you shifts.[/color] You'll understand at your next turning point.")
	g.save_game()

# ---------- The reveal, the choice and the steps ----------

const STAGE_LEVELS := [15, 35, 75]
const STAGE_POWER := [1.18, 1.28, 1.40]   # Attack, HP and Defense, each step (about x2.1 by 75; the main route gives about x1.9 to its own stats)

## How far your hidden class has grown (1..3) at your level.
static func stage(g: GameState) -> int:
	var s := 1
	for lv in STAGE_LEVELS:
		if g.level >= int(lv):
			s = STAGE_LEVELS.find(lv) + 1
	return s

## Called on every level-up (GameState.gain_xp). start_level: your level before
## this batch of level-ups (one fight can give two levels, 14 -> 16): an offer
## made during the batch stays open; one from before it has passed.
static func on_level(g: GameState, start_level := -1) -> void:
	if start_level < 0:
		start_level = g.level - 1
	GodClasses.check(g)
	if g.hidden_class != "":
		if g.level in STAGE_LEVELS and g.level > int(STAGE_LEVELS[0]):
			var c := info(g.hidden_class)
			var nm: String = c["stages"][stage(g) - 1]
			g.hidden_stage[g.hidden_class] = stage(g)
			g.events.append({"type": "hidden_class", "id": g.hidden_class, "name": nm, "tier": int(c["tier"]), "color": c["color"],
				"lore": "Your %s grows stronger: you are now %s." % [c["name"], nm]})
			g.say("[color=%s]Your hidden class grows: %s![/color]" % [c["color"], nm])
		return
	if not g.hidden_offer.is_empty() and g.level > g.hidden_offer_level and g.hidden_offer_level <= start_level:
		g.hidden_offer = []
		g.say("[color=#a89d84]The hidden path you passed by fades... for now.[/color]")
	if not g.level in STAGE_LEVELS or g.god_class != "":  # offered only at 15, 35 and 75; past 75 only God classes answer
		return
	var ids: Array = []
	for id in ORDER:
		if g.hidden.has(id) and block_reason(g, id) == "":
			ids.append(id)
	if ids.is_empty():
		return
	g.hidden_offer = ids
	g.hidden_offer_level = g.level
	for id in ids:
		g.hidden_seen[id] = true
	g.events.append({"type": "hidden_offer", "count": ids.size()})
	g.say("[color=#c4b5fd]*** A hidden path opens: %d secret class%s you can take instead of your evolution, until your next level-up. ***[/color]" % [ids.size(), "" if ids.size() == 1 else "es"])

## Take a hidden class from the offer. It's for good. Classes with a champion
## start that trial first and are yours if you win.
static func take(g: GameState, id: String) -> bool:
	if g.hidden_class != "" or not id in g.hidden_offer:
		return false
	var c := info(id)
	if c.has("trial") and not g.feats.get("trial_" + id, 0):
		return start_trial(g, id)
	_take(g, id)
	return true

static func _take(g: GameState, id: String) -> void:
	var c := info(id)
	g.hidden_class = id
	g.hidden_offer = []
	# A God class that only answers the main route can't be taken any more
	var keep: Array = []
	for o in g.god_offers:
		if not bool(GodClasses.info(String(o)).get("main_route", false)):
			keep.append(o)
	g.god_offers = keep
	g.hidden_stage[id] = stage(g)
	var nm := title(g)
	g.discovered[id] = true
	g._page("hidden")
	g.events.append({"type": "hidden_class", "id": id, "name": nm, "tier": int(c["tier"]), "color": c["color"], "lore": c["lore"]})
	g.say("[color=%s]*** HIDDEN CLASS: %s ***[/color] %s This is your class now." % [c["color"], nm, c["lore"]])
	g.hero_hp = mini(g.hero_hp, g.get_max_hp())
	Lineage.update_look(g)
	g.save_game()

## A camp-fire rumor about a hidden class you don't have yet.
static func rumor(g: GameState) -> String:
	var opts: Array = []
	for id in ORDER:
		if not g.hidden.has(id):
			opts.append(info(id)["rumor"])
	return opts.pick_random() if not opts.is_empty() else ""

## Your hidden-class title ("" if none).
static func title(g: GameState) -> String:
	if g.hidden_class == "":
		return ""
	var c := info(g.hidden_class)
	return c["stages"][clampi(stage(g) - 1, 0, c["stages"].size() - 1)]

static func stat_name(g: GameState) -> String:
	return info(g.hidden_class).get("stat", "") if g.hidden_class != "" else ""

## What a hidden class gives at a step (1..3): raw power plus its specialty, added up.
static func stage_bonuses(id: String, st: int) -> Array:
	var c := info(id)
	var out: Array = []
	var p := 1.0
	for i in clampi(st, 1, 3):
		p *= float(STAGE_POWER[i])
	out.append({"atk": p, "hp": p, "def": p})
	for i in clampi(st, 1, c["stage_bonus"].size()):
		out.append(c["stage_bonus"][i])
	return out

static func stage_text(id: String, st: int) -> String:
	var total := {}
	for b in stage_bonuses(id, st):
		for k in b:
			if k in ["atk", "hp", "def", "skill"]:
				total[k] = float(total.get(k, 1.0)) * float(b[k])
			else:
				total[k] = float(total.get(k, 0.0)) + float(b[k])
	return Classes.bonus_text(total)

static func bonus_sources(g: GameState) -> Array:
	if g.hidden_class == "":
		return []
	var c := info(g.hidden_class)
	var out := stage_bonuses(g.hidden_class, stage(g))
	var v := g.unique_value(c["stat"]) * float(STAT_SCALE[int(c["tier"])])
	var per: Dictionary = c["per_point"]
	var d := {}
	for k in per:
		d[k] = 1.0 + float(per[k]) * v if k in ["atk", "hp", "def", "skill"] else float(per[k]) * v
	out.append(d)
	return out
## What your hidden class's special stat gives now, and what grows it.
static func stat_text(g: GameState) -> String:
	if g.hidden_class == "":
		return ""
	var c := info(g.hidden_class)
	var b := bonus_sources(g)
	var gives := Classes.bonus_text(b[b.size() - 1]) if not b.is_empty() else ""
	var acts: Array = []
	for k in (c.get("grow", {}) as Dictionary):
		acts.append(String(k).replace("_", " "))
	return "Gives %s\nGrows from: %s." % [gives.trim_suffix("."), ", ".join(acts)]

## Your hidden class's special stat grows from an action.
static func gain(g: GameState, action: String, amount := 1.0) -> void:
	if g.hidden_class == "":
		return
	var c := info(g.hidden_class)
	var gr: Dictionary = c.get("grow", {})
	if gr.has(action):
		var n: String = c["stat"]
		g.unique[n] = float(g.unique.get(n, 0.0)) + float(gr[action]) * amount

# ---------- Hooks from the game ----------

static func on_kill(g: GameState, _species: String, tier: int, boss_kind: String, was_goblin: bool) -> void:
	count(g, "kills_total")
	if was_goblin:
		count(g, "goblins")
	if g.last_hit == "skill":
		count(g, "skill_kills")
		gain(g, "skill_kill")
		if tier >= Monsters.LEGENDARY:
			count(g, "skill_kills_elite")
		if boss_kind == "zone":
			flag(g, "boss_skill_finish")
	elif g.last_hit == "burn":
		count(g, "burn_kills")
		gain(g, "burn_kill")
		if boss_kind == "zone":
			flag(g, "burn_boss")
	count(g, "clean_streak")
	best(g, "clean_best", int(g.feats.get("clean_streak", 0)))
	if g.hidden_class != "":
		var ck: Dictionary = g.feats.get("class_kills", {})
		ck[g.hidden_class] = int(ck.get(g.hidden_class, 0)) + 1
		g.feats["class_kills"] = ck
	if int(g.feats.get("kills_total", 0)) % 25 == 0 or boss_kind != "":
		check(g)

static func on_death(g: GameState) -> void:
	count(g, "deaths")
	g.feats["clean_streak"] = 0
	check(g)

static func on_potion(g: GameState) -> void:
	count(g, "potions_drunk")
	g.feats["clean_streak"] = 0
	gain(g, "potion")

static func on_craft_potion(g: GameState) -> void:
	count(g, "potions_crafted")
	gain(g, "craft")
	check(g)

static func on_wheel(g: GameState, won: bool) -> void:
	if won:
		count(g, "wheel_streak")
		best(g, "wheel_best", int(g.feats.get("wheel_streak", 0)))
	else:
		g.feats["wheel_streak"] = 0
	check(g)

## Gladiator-style trial: taking that hidden class means beating its champion first.
static func start_trial(g: GameState, id: String) -> bool:
	return g.start_special_trial(info(id)["trial"], "hidden", {"id": id})

static func trial_won(g: GameState, data: Dictionary) -> void:
	var id := String(data.get("id", ""))
	g.feats["trial_" + id] = 1
	if id in g.hidden_offer and g.hidden_class == "":
		_take(g, id)

## Beast Tamer: a befriended beast fights beside you. Returns its damage (0 = none).
static func companion_power(g: GameState) -> float:
	if g.hidden_class == "":
		return 0.0
	var c := info(g.hidden_class)
	if not c.has("companion"):
		return 0.0
	return float(c["companion"]) + g.unique_value(c["stat"]) * 0.002
