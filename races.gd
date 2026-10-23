class_name Races
extends RefCounted
## The 12 races, their racial power and awakening, the 4 earned
## transformations, and how the races feel about you (reputation).
##
## Racial power: every race has a meter (Divine Power, Demonic Energy...).
## It grows from playing your race's way, and from stat points (0.1 each,
## like a special stat). Each point of it gives a small bonus.
##
## Awakening: each race climbs its own ranks (3 to 5 of them). A rank needs
## a level, enough racial power, and often a key: an item from somewhere
## special, or a trial fight. Angels and Demons climb on power alone.
##
## Transformations: Vampire and Werewolf come from a bite (sudden!) and can
## be cured with a long quest. Fallen Angel and Lich are forever: the only
## way back is starting the hero over.
##
## Story text here is a placeholder until the lore is written.

const POWER_POINT := 0.06  # a stat point put into racial power is worth this much (5 points a level)

# ---------- The races ----------
# stats: base stat bonus. passive: same keys as class passives.
# power: the racial meter. gains: action -> power per action.
# bonus: per point of power (atk/hp/def/skill are +x per point, the rest add).
# tag_power: extra power for skills with that tag.
# ranks: awakening. key = {"item": name, "from": {...}} or {"trial": {...}} or {}.
# "from": {"boss": <monster id>} / {"realm", "kind"} / {"goblin"}. Form "biters" are monster ids.
const ORDER := ["Human", "Elf", "Fairy", "Angel", "Demon", "Dwarf", "Beastkin", "Dragonkin", "Undead", "Orc", "Goblin", "Golem"]
const INFO := {
	"Human": {"text": "Balanced and quick to learn. +2 CHA, +2 LUK, +10% XP.", "stats": {"CHA": 2, "LUK": 2}, "passive": {}, "xp": 1.1,
		"color": "#e8b14a",
		"power": {"name": "Willpower", "color": "#e8b14a", "gains": {"boss": 1.0, "floor": 0.05, "rare_kill": 0.1, "death": 0.02},
			"bonus": {"atk": 0.0005, "hp": 0.0005}, "how": "Grows from beating bosses, rare monsters, new floors and getting back up after a defeat."},
		"ranks": [
			{"name": "Hero", "level": 40, "power": 30, "key": {"trial": {"name": "The Trial of Courage", "art": "boss_grendel", "lore": "No blessing, no birthright. Just you."}},
				"bonus": {"atk": 1.05, "hp": 1.05}, "text": "+5% Attack and HP."},
			{"name": "Champion", "level": 85, "power": 120, "key": {"trial": {"name": "The Champion's Duel", "art": "boss_dullahan", "lore": "Every race has a champion. Now so do yours."}},
				"bonus": {"atk": 1.08, "xp": 10}, "text": "+8% Attack, +10% XP."},
			{"name": "Legend", "level": 140, "power": 300, "key": {"trial": {"name": "The Trial of Legends", "art": "boss_surtr", "lore": "Songs will be sung either way."}},
				"bonus": {"atk": 1.1, "hp": 1.1, "def": 1.05}, "text": "+10% Attack and HP, +5% Defense."},
		]},
	"Elf": {"text": "Quick and sharp-eyed. +4 AGI, +3 DEX, +3 INT, but -8% HP.", "stats": {"AGI": 4, "DEX": 3, "INT": 3}, "passive": {"hp": 0.92},
		"color": "#4ade80",
		"power": {"name": "Verdance", "color": "#4ade80", "gains": {"skill:Nature": 0.015, "dodge": 0.01, "kill": 0.01, "realm:elf": 0.03},
			"bonus": {"dodge": 0.01, "skill": 0.0005}, "how": "Grows from Nature skills, dodging, and fighting in the elven forest."},
		"ranks": [
			{"name": "Blessed Elf", "level": 30, "power": 20, "key": {"item": "World Tree's Blessing", "from": {"realm": "elf", "kind": "mid", "chance": 40}},
				"bonus": {"dodge": 4, "regen": 1}, "text": "+4% dodge, heal 1% HP each turn.", "look": "glow"},
			{"name": "High Elf", "level": 70, "power": 90, "key": {"trial": {"name": "The Last Warden", "art": "boss_black_annis", "lore": "She guarded the Tree when it was still alive."}},
				"bonus": {"skill": 1.1, "crit": 5}, "text": "+10% skill damage, +5% crit.", "look": "glow"},
			{"name": "Elf Sovereign", "level": 120, "power": 250, "key": {"item": "Heartseed of the World Tree", "from": {"realm": "elf", "kind": "zone", "chance": 35}},
				"bonus": {"skill": 1.12, "dodge": 5, "hp": 1.1}, "text": "+12% skill damage, +5% dodge, +10% HP.", "look": "glow"},
		]},
	"Fairy": {"text": "Tiny, magic and hard to hit. +5 INT, +3 CHA, +3% dodge, but -15% HP.", "stats": {"INT": 5, "CHA": 3}, "passive": {"dodge": 3, "hp": 0.85},
		"color": "#f9a8d4",
		"power": {"name": "Glamour", "color": "#f9a8d4", "gains": {"dodge": 0.01, "skill:Trick": 0.015, "skill:Arcane": 0.015, "confuse": 0.1},
			"bonus": {"dodge": 0.0075, "crit": 0.0075}, "how": "Grows from dodging, tricks, arcane magic and confusing monsters."},
		"ranks": [
			{"name": "Fae Courtier", "level": 25, "power": 15, "key": {"item": "Fruit of the Fairy Queen", "from": {"realm": "fairy", "kind": "mid", "chance": 40}},
				"bonus": {"dodge": 4, "skill": 1.05}, "text": "+4% dodge, +5% skill damage.", "look": "wings_big"},
			{"name": "Fae Lord", "level": 60, "power": 60, "key": {"trial": {"name": "The Thorn Court", "art": "boss_echidna", "lore": "The court does not judge you. It plays with you."}},
				"bonus": {"crit": 6, "double_strike": 4}, "text": "+6% crit, +4% double strike.", "look": "wings_big"},
			{"name": "Fae Archon", "level": 100, "power": 150, "key": {"item": "Golden Fruit of the Queen", "from": {"realm": "fairy", "kind": "zone", "chance": 35}},
				"bonus": {"skill": 1.12, "dodge": 4}, "text": "+12% skill damage, +4% dodge.", "look": "wings_big"},
			{"name": "Fairy Monarch", "level": 150, "power": 350, "key": {"trial": {"name": "The Fairy Queen's Game", "art": "boss_scylla", "lore": "She has never lost a game. She has never played fair."}},
				"bonus": {"skill": 1.15, "hp": 1.15, "crit": 5}, "text": "+15% skill damage and HP, +5% crit.", "look": "wings_big"},
		]},
	"Angel": {"text": "Blessed and sturdy. +5 VIT, +3 WIS, heals 1% HP every turn.", "stats": {"VIT": 5, "WIS": 3}, "passive": {"regen": 1},
		"color": "#fde68a",
		"power": {"name": "Divine Power", "color": "#fde68a", "gains": {"skill:Holy": 0.015, "boss": 1.0, "good": 0.3, "heal": 0.03},
			"bonus": {"regen": 0.0025, "hp": 0.0005}, "how": "Grows from Holy skills, healing, beating bosses and good deeds. More of it means more wings."},
		"ranks": [
			{"name": "Archangel", "level": 40, "power": 40, "key": {}, "bonus": {"hp": 1.08, "regen": 1}, "text": "A second pair of wings. +8% HP, +1% regen.", "look": "wings2"},
			{"name": "Seraph", "level": 90, "power": 150, "key": {}, "bonus": {"skill": 1.1, "def": 1.08}, "text": "A third pair of wings. +10% skill damage, +8% Defense.", "look": "wings3"},
			{"name": "Throne", "level": 140, "power": 400, "key": {"item": "Crown of the First Light", "from": {"realm": "angel", "kind": "zone", "chance": 35}},
				"bonus": {"hp": 1.12, "skill": 1.12, "regen": 1}, "text": "A crown of light. +12% HP and skill damage, +1% regen.", "look": "wings3"},
		]},
	"Demon": {"text": "Brutal and bloodthirsty. +8 STR, +3% lifesteal, but -7% Defense.", "stats": {"STR": 8}, "passive": {"lifesteal": 3, "def": 0.93},
		"color": "#e43b44",
		"power": {"name": "Demonic Energy", "color": "#e43b44", "gains": {"skill:Shadow": 0.015, "skill:Blood": 0.015, "low_hp_kill": 0.1, "shrine": 3.0, "kill": 0.01, "evil": 0.3},
			"bonus": {"lifesteal": 0.0075, "atk": 0.0005}, "how": "Grows from Shadow and Blood skills, cursed shrines, kills, and fighting near death. Enough of it raises your rank."},
		"ranks": [
			{"name": "Greater Demon", "level": 25, "power": 20, "key": {}, "bonus": {"atk": 1.05}, "text": "+5% Attack."},
			{"name": "Demon Noble", "level": 50, "power": 70, "key": {}, "bonus": {"lifesteal": 3, "hp": 1.05}, "text": "Great horns. +3% lifesteal, +5% HP.", "look": "horns_big"},
			{"name": "Archdemon", "level": 80, "power": 160, "key": {}, "bonus": {"atk": 1.08}, "text": "+8% Attack.", "look": "horns_big"},
			{"name": "Demon Prince", "level": 115, "power": 300, "key": {"trial": {"name": "A Prince of the Abyss", "art": "boss_typhon", "lore": "Only one prince leaves this fight."}},
				"bonus": {"atk": 1.08, "lifesteal": 3}, "text": "+8% Attack, +3% lifesteal.", "look": "horns_big"},
			{"name": "Demon Lord", "level": 150, "power": 500, "key": {"item": "Crown of the Abyss", "from": {"realm": "demon", "kind": "zone", "chance": 35}},
				"bonus": {"atk": 1.12, "hp": 1.1, "lifesteal": 4}, "text": "Demon royalty. +12% Attack, +10% HP, +4% lifesteal.", "look": "crown"},
		]},
	"Dwarf": {"text": "Stout and stubborn. +5 VIT, +3 STR, +10% Defense, +15% scrap from salvaging.", "stats": {"VIT": 5, "STR": 3}, "passive": {"def": 1.1, "scrap": 15},
		"color": "#f59e0b",
		"power": {"name": "Forgecraft", "color": "#f59e0b", "gains": {"craft": 0.1, "boss": 1.0, "realm:dwarf": 0.03},
			"bonus": {"def": 0.00075, "thorns": 0.0125}, "how": "Grows from upgrading, salvaging and crafting, beating bosses, and fighting in the dwarven forge."},
		"ranks": [
			{"name": "Thane", "level": 30, "power": 20, "key": {"item": "Ancestor's Rune", "from": {"realm": "dwarf", "kind": "mid", "chance": 40}},
				"bonus": {"def": 1.08, "scrap": 10}, "text": "+8% Defense, +10% scrap.", "look": "glow"},
			{"name": "Rune Lord", "level": 75, "power": 90, "key": {"trial": {"name": "The Forge Guardian", "art": "boss_surtr", "lore": "It was built to test dwarves. It has never been impressed."}},
				"bonus": {"def": 1.1, "thorns": 8}, "text": "+10% Defense, reflect 8% of damage.", "look": "glow"},
			{"name": "Mountain King", "level": 125, "power": 250, "key": {"item": "Heart of the Mountain", "from": {"realm": "dwarf", "kind": "zone", "chance": 35}},
				"bonus": {"def": 1.12, "hp": 1.12, "atk": 1.05}, "text": "+12% Defense and HP, +5% Attack.", "look": "crown"},
		]},
	"Beastkin": {"text": "Wild and fast. +4 AGI, +3 DEX, +2 STR, +4% crit, +2% dodge, but -5% Defense.", "stats": {"AGI": 4, "DEX": 3, "STR": 2}, "passive": {"crit": 4, "dodge": 2, "def": 0.95},
		"color": "#d9a066",
		"power": {"name": "Instinct", "color": "#d9a066", "gains": {"crit": 0.01, "dodge": 0.01, "streak": 1.0},
			"bonus": {"crit": 0.01, "double_strike": 0.0075}, "how": "Grows from crits, dodges and long kill streaks."},
		"ranks": [
			{"name": "Alpha", "level": 35, "power": 30, "key": {"trial": {"name": "The Pack Leader", "art": "boss_grendel", "lore": "Beat the alpha, become the alpha."}},
				"bonus": {"crit": 5, "atk": 1.04}, "text": "+5% crit, +4% Attack.", "look": "glow"},
			{"name": "Primal", "level": 80, "power": 120, "key": {"trial": {"name": "The Great Beast", "art": "boss_fafnir", "lore": "Older than the first hunt."}},
				"bonus": {"double_strike": 6, "dodge": 3}, "text": "+6% double strike, +3% dodge.", "look": "glow"},
			{"name": "Beast Sovereign", "level": 130, "power": 300, "key": {"trial": {"name": "The Wild King", "art": "boss_typhon", "lore": "Every beast bows to someone."}},
				"bonus": {"atk": 1.1, "crit": 6, "hp": 1.08}, "text": "+10% Attack, +6% crit, +8% HP.", "look": "glow"},
		]},
	"Dragonkin": {"text": "Dragon-blooded. +5 STR, +3 VIT, +10% HP, Fire skills +10%.", "stats": {"STR": 5, "VIT": 3}, "passive": {"hp": 1.1}, "tag_power": {"Fire": 0.1},
		"color": "#f77622",
		"power": {"name": "Dragon Blood", "color": "#f77622", "gains": {"skill:Fire": 0.015, "boss": 1.0, "rare_kill": 0.1},
			"bonus": {"hp": 0.00075, "atk": 0.0005}, "how": "Grows from Fire skills, beating bosses and rare monsters."},
		"ranks": [
			{"name": "Drakeblood", "level": 25, "power": 20, "key": {}, "bonus": {"hp": 1.06}, "text": "+6% HP."},
			{"name": "Wyrmkin", "level": 60, "power": 80, "key": {"trial": {"name": "Fafnir's Shade", "art": "boss_fafnir", "lore": "The dragon's ghost wants its blood back."}},
				"bonus": {"atk": 1.06, "hp": 1.06}, "text": "Dragon wings. +6% Attack and HP.", "look": "dragon_wings"},
			{"name": "Elder Wyrmkin", "level": 100, "power": 180, "key": {"item": "Dragon Heart", "from": {"boss": "fafnir", "chance": 25}},
				"bonus": {"def": 1.1, "regen": 1}, "text": "+10% Defense, +1% regen.", "look": "dragon_wings"},
			{"name": "Dragon Lord", "level": 150, "power": 400, "key": {"trial": {"name": "The Elder Wyrm", "art": "boss_charybdis", "lore": "The last true dragon. It remembers your ancestors."}},
				"bonus": {"atk": 1.12, "hp": 1.12}, "text": "+12% Attack and HP.", "look": "dragon_wings"},
		]},
	"Undead": {"text": "Dead, but not done. +6 VIT, +2 INT, Shadow skills +10%, but potions heal 20% less.", "stats": {"VIT": 6, "INT": 2}, "passive": {"potion": -20}, "tag_power": {"Shadow": 0.1},
		"color": "#86c06c", "skins": [8, 9],
		"power": {"name": "Necrotic Energy", "color": "#86c06c", "gains": {"skill:Shadow": 0.015, "death": 0.05, "kill": 0.01},
			"bonus": {"lifesteal": 0.0075, "hp": 0.0005}, "how": "Grows from Shadow skills, kills, and every time you die."},
		"ranks": [
			{"name": "Revenant", "level": 30, "power": 25, "key": {}, "bonus": {"lifesteal": 3}, "text": "+3% lifesteal.", "look": "glow"},
			{"name": "Wight Lord", "level": 75, "power": 100, "key": {"trial": {"name": "The Barrow King", "art": "boss_dullahan", "lore": "He has ruled the dead for a thousand years. He would like a successor."}},
				"bonus": {"hp": 1.1, "lifesteal": 3}, "text": "+10% HP, +3% lifesteal.", "look": "glow"},
			{"name": "Undying King", "level": 125, "power": 280, "key": {"item": "Hel's Crown", "from": {"boss": "hel", "chance": 20}},
				"bonus": {"hp": 1.12, "atk": 1.08, "regen": 1}, "text": "+12% HP, +8% Attack, +1% regen.", "look": "crown"},
		]},
	"Orc": {"text": "Brutal strength. +8 STR, +2 VIT, up to +15% damage when hurt, but -5% skill damage.", "stats": {"STR": 8, "VIT": 2}, "passive": {"rage": 15, "skill": 0.95},
		"color": "#75a743", "skins": [6, 3, 4, 7],
		"power": {"name": "Bloodrage", "color": "#dc2626", "gains": {"low_hp_kill": 0.1, "kill": 0.01, "boss": 1.0},
			"bonus": {"rage": 0.025, "atk": 0.0005}, "how": "Grows from kills, bosses, and winning fights near death."},
		"ranks": [
			{"name": "Blooded", "level": 30, "power": 25, "key": {"trial": {"name": "The Trial of Scars", "art": "boss_grendel", "lore": "Every scar is a story. Earn one more."}},
				"bonus": {"rage": 10, "hp": 1.05}, "text": "+10% rage damage, +5% HP.", "look": "glow"},
			{"name": "Warchief", "level": 70, "power": 100, "key": {"trial": {"name": "The Warchief's Challenge", "art": "boss_surtr", "lore": "Take his axe, take his tribe."}},
				"bonus": {"atk": 1.08, "double_strike": 4}, "text": "+8% Attack, +4% double strike.", "look": "glow"},
			{"name": "Great Khan", "level": 120, "power": 260, "key": {"trial": {"name": "The Great Khan", "art": "boss_typhon", "lore": "One Khan. Every tribe. Forever."}},
				"bonus": {"atk": 1.12, "hp": 1.1, "rage": 10}, "text": "+12% Attack, +10% HP, +10% rage damage.", "look": "crown"},
		]},
	"Goblin": {"text": "Greedy and sneaky. +3 AGI, +3 DEX, +4 LUK, +2 CHA, +15% gold, but -5% HP.", "stats": {"AGI": 3, "DEX": 3, "LUK": 4, "CHA": 2}, "passive": {"gold_find": 15, "hp": 0.95},
		"color": "#a8ca58", "skins": [6, 2, 3],
		"power": {"name": "Greed", "color": "#facc15", "gains": {"goblin": 2.0, "rare_kill": 0.1, "kill": 0.01, "gamble": 0.3},
			"bonus": {"gold_find": 0.025, "crit": 0.005}, "how": "Grows from catching treasure goblins, rare monsters, kills and the Wheel."},
		"ranks": [
			{"name": "Hobgoblin", "level": 25, "power": 20, "key": {}, "bonus": {"hp": 1.08, "gold_find": 10}, "text": "+8% HP, +10% gold."},
			{"name": "Goblin Boss", "level": 65, "power": 80, "key": {"item": "Golden Tooth", "from": {"goblin": true, "chance": 30}},
				"bonus": {"crit": 5, "gold_find": 15}, "text": "+5% crit, +15% gold.", "look": "glow"},
			{"name": "Goblin King", "level": 115, "power": 220, "key": {"trial": {"name": "The Goblin King", "art": "boss_black_annis", "lore": "There can only be one. Everything else belongs to him."}},
				"bonus": {"atk": 1.1, "gold_find": 20, "stone_find": 20}, "text": "+10% Attack, +20% gold, +20% stone finds.", "look": "crown"},
		]},
	"Golem": {"text": "Living stone. +10 VIT, +15% Defense, reflects 5% of damage, but -5% Attack.", "stats": {"VIT": 10}, "passive": {"def": 1.15, "thorns": 5, "atk": 0.95},
		"color": "#94a3b8", "skins": [10, 11],
		"power": {"name": "Core Charge", "color": "#7fd0f0", "gains": {"hit": 0.004, "boss": 1.0},
			"bonus": {"def": 0.00075, "thorns": 0.02}, "how": "Grows every time you're hit, and from beating bosses."},
		"ranks": [
			{"name": "Awakened Golem", "level": 30, "power": 25, "key": {}, "bonus": {"def": 1.06, "atk": 1.04}, "text": "+6% Defense, +4% Attack.", "look": "glow"},
			{"name": "Colossus", "level": 75, "power": 100, "key": {"item": "Living Core", "from": {"boss": "surtr", "chance": 25}},
				"bonus": {"def": 1.1, "hp": 1.1}, "text": "+10% Defense and HP.", "look": "glow"},
			{"name": "Titan", "level": 125, "power": 260, "key": {"trial": {"name": "The First Titan", "art": "boss_surtr", "lore": "It made the first golems. It wants to see what they became."}},
				"bonus": {"def": 1.12, "atk": 1.1, "thorns": 10}, "text": "+12% Defense, +10% Attack, reflect 10% more.", "look": "crown"},
		]},
}

# ---------- Transformations ----------
# Vampire and Werewolf: a bite, out of nowhere. Curable with a long quest.
# Fallen Angel and Lich: forever (only starting the hero over undoes them).
const FORMS := {
	"Vampire": {"from": ["Human"], "color": "#b8263a", "curable": true,
		"text": "Bitten. You drink the life of what you kill. +8% lifesteal, +6% Attack, +5 STR, +3 AGI, but no more natural healing.",
		"stats": {"STR": 5, "AGI": 3}, "passive": {"lifesteal": 8, "atk": 1.06}, "no_regen": true,
		"biters": ["strigoi", "moroi", "vetala"], "bite_chance": 0.05,
		"cure": {"kills": 100, "text": "Hunt %d of the bloodline (Strigoi, Moroi, Vetala), then face the Elder Vampire.",
			"trial": {"name": "The Elder Vampire", "art": "boss_hel", "lore": "The one whose blood runs in you. Kill it and the thirst dies too."}}},
	"Werewolf": {"from": ["Human", "Beastkin"], "color": "#8b9bb4", "curable": true,
		"text": "Cursed by the moon. +6% crit, +6% double strike, +8% Attack, but -6% Defense. Even stronger on full-moon floors.",
		"stats": {"STR": 3, "DEX": 4}, "passive": {"crit": 6, "double_strike": 6, "atk": 1.08, "def": 0.94},
		"biters": ["barghest", "garmr", "hellhound"], "bite_chance": 0.04, "moon": 30,
		"cure": {"kills": 100, "text": "Hunt %d of the cursed hounds (Barghest, Garmr, Hellhound), then find a Silver Moonbloom in the elven forest.",
			"item": "Silver Moonbloom", "from": {"realm": "elf", "kind": "any", "chance": 2}}},
	"Fallen Angel": {"from": ["Angel"], "color": "#5a6988", "curable": false,
		"text": "Your faith broke and you fell. Black wings, a cracked halo. +12% Attack, +4% lifesteal, but no more healing light.",
		"stats": {"STR": 5, "INT": 3}, "passive": {"atk": 1.12, "lifesteal": 4}, "replaces": true, "fall_at": -40.0},
	"Lich": {"from": [], "color": "#7fd0f0", "curable": false,
		"text": "You traded your soul for power. +18% skill damage, -10% HP, and once per floor you survive a killing blow.",
		"stats": {"INT": 7}, "passive": {"skill": 1.18, "hp": 0.9}, "phylactery": true,
		"need": {"level": 60, "classes": ["Mage", "Acolyte", "Cleric", "Bard"], "tag": "Shadow", "item": "Phylactery"},
		"item_from": {"boss": "hel", "chance": 30}},
}

# ---------- Reputation ----------
const REP_MIN := -100.0
const REP_MAX := 100.0
const REP_LEVELS := [
	[-60.0, "Hated", "#dc2626"], [-20.0, "Hostile", "#f97316"], [20.0, "Wary", "#a3a3a3"],
	[60.0, "Friendly", "#4ade80"], [90.0, "Honored", "#38bdf8"], [999.0, "Exalted", "#e8b14a"],
]
const REP_START_OWN := 30.0      # your own race starts Friendly
const REP_START_RIVAL := -30.0   # your race's rivals start Hostile
const RIVALS := {
	"Angel": ["Demon"], "Demon": ["Angel"], "Elf": ["Orc"], "Orc": ["Elf"],
	"Dwarf": ["Goblin"], "Goblin": ["Dwarf"], "Human": ["Undead"], "Undead": ["Human"],
}
const RIVAL_SHARE := 0.5     # helping a race costs half as much standing with its rivals
const REP_KILL := -0.15      # killing one of a race's people
const REP_SPARE := 0.6       # letting one go
const REP_HATED_ATK := 1.15  # their people hit harder when they hate you

# ---------- Escaping ----------
const ESCAPE_BASE := 35.0
const ESCAPE_PER_AGI := 0.6
const ESCAPE_PER_TIER := 7.0
const ESCAPE_MIN := 10.0
const ESCAPE_MAX := 100.0  # 100% is possible but takes real Agility (0.12: the tamer's road)
const SPARE_AT := 0.25   # a monster under 25% HP can be spared (befriended)

static func info(race: String) -> Dictionary:
	return INFO.get(race, INFO["Human"])

## Skin colors this race can pick (indexes into the skin list).
static func skins(race: String) -> Array:
	return info(race).get("skins", [0, 1, 2, 3, 4, 5, 6, 7])

static func ranks(race: String) -> Array:
	return info(race)["ranks"]

static func power_info(race: String) -> Dictionary:
	return info(race)["power"]

## The bonus dict for an amount of racial power.
static func power_bonus(race: String, power: float) -> Dictionary:
	var out := {}
	var b: Dictionary = power_info(race)["bonus"]
	for k in b:
		if k in ["atk", "hp", "def", "skill"]:
			out[k] = 1.0 + float(b[k]) * power
		else:
			out[k] = float(b[k]) * power
	return out

static func rep_level(value: float) -> Array:
	for lv in REP_LEVELS:
		if value < float(lv[0]):
			return [lv[1], lv[2]]
	return [REP_LEVELS[-1][1], REP_LEVELS[-1][2]]

static func rep_index(value: float) -> int:
	for i in REP_LEVELS.size():
		if value < float(REP_LEVELS[i][0]):
			return i
	return REP_LEVELS.size() - 1

## Starting standings for a hero of this race.
static func start_rep(race: String) -> Dictionary:
	var out := {}
	for r in ORDER:
		out[r] = 0.0
	out[race] = REP_START_OWN
	for rv in RIVALS.get(race, []):
		out[rv] = REP_START_RIVAL
	return out

## What a rank's key is, in words.
static func key_text(key: Dictionary) -> String:
	if key.has("trial"):
		return "Win the trial: %s" % key["trial"]["name"]
	if key.has("item"):
		return "Find %s (%s)" % [key["item"], source_text(key["from"])]
	return ""

static func source_text(src: Dictionary) -> String:
	if src.get("goblin", false):
		return "treasure goblins"
	if src.has("boss"):
		return "dropped by %s" % Monsters.name_of(String(src["boss"]))
	if src.has("realm"):
		var rname := Realms.realm_name(String(src["realm"]))
		match String(src.get("kind", "any")):
			"mid":
				return "the mid boss of %s" % rname
			"zone":
				return "the ruler of %s" % rname
		return "monsters of %s" % rname
	return "somewhere"

static func bonus_text(b: Dictionary) -> String:
	return Classes.bonus_text(b)

# ---------- Race-exclusive gear ----------
# Only heroes of that race can wear these. Sold by a race's merchant to its
# Honored friends; very rarely dropped by bosses for heroes of that race.
const RACE_GEAR := {
	"Human": [{"id": "banner_knights_longsword", "name": "Banner-Knight's Longsword", "slot": "Weapon", "type": "sword", "effect": "crit", "value": 16, "mat": "steel", "trim": "#e8b14a", "flavor": "Humans don't have magic. They have stubbornness."}],
	"Elf": [{"id": "elven_longbow_of_the_last_light", "name": "Elven Longbow of the Last Light", "slot": "Weapon", "type": "bow", "effect": "crit", "value": 20, "mat": "pale", "trim": "#4ade80", "flavor": "Only an elf can draw it. The string remembers."},
		{"id": "leafsilver_circlet", "name": "Leafsilver Circlet", "slot": "Helmet", "type": "crown", "effect": "dodge", "value": 10, "mat": "pale", "trim": "#9fd8c4", "flavor": "Worn by elven wardens for a thousand years."}],
	"Fairy": [{"id": "dewdrop_wand", "name": "Dewdrop Wand", "slot": "Weapon", "type": "staff", "effect": "double_strike", "value": 18, "mat": "crystal", "trim": "#f9a8d4", "flavor": "Too small for anyone else's hand."},
		{"id": "petalweave_dress", "name": "Petalweave Dress", "slot": "Chest", "type": "robe", "effect": "dodge", "value": 12, "mat": "coral", "trim": "#f9a8d4", "flavor": "Fairy-sized. Fairy-magic. Fairy-only."}],
	"Angel": [{"id": "halo_of_the_faithful", "name": "Halo of the Faithful", "slot": "Helmet", "type": "crown", "effect": "regen", "value": 3, "mat": "gold", "trim": "#fde68a", "flavor": "A real halo. It only floats over an angel."},
		{"id": "wingguard_plate", "name": "Wingguard Plate", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 20, "mat": "gold", "trim": "#fde68a", "flavor": "Cut to fit around wings."}],
	"Demon": [{"id": "hornbreaker_axe", "name": "Hornbreaker Axe", "slot": "Weapon", "type": "axe", "effect": "lifesteal", "value": 12, "mat": "ember", "trim": "#e43b44", "flavor": "Only demon blood can hold its grip."},
		{"id": "infernal_crown", "name": "Infernal Crown", "slot": "Helmet", "type": "crown", "effect": "lifesteal", "value": 10, "mat": "dark", "trim": "#e43b44", "flavor": "Burns anyone who isn't a demon."}],
	"Dwarf": [{"id": "dwarven_runeplate", "name": "Dwarven Runeplate", "slot": "Chest", "type": "plate", "effect": "thorns", "value": 25, "mat": "iron", "trim": "#f59e0b", "flavor": "Made for dwarven shoulders. Nobody else's."},
		{"id": "clan_warhammer", "name": "Clan Warhammer", "slot": "Weapon", "type": "mace", "effect": "double_strike", "value": 18, "mat": "iron", "trim": "#f59e0b", "flavor": "Every dwarf clan has one. Yours does now."}],
	"Beastkin": [{"id": "fang_and_claw_gauntlets", "name": "Fang-and-Claw Gauntlets", "slot": "Off Hand", "type": "buckler", "effect": "crit", "value": 16, "mat": "hide", "trim": "#d9a066", "flavor": "Fit only hands that are half paw."}],
	"Dragonkin": [{"id": "wyrmscale_mail", "name": "Wyrmscale Mail", "slot": "Chest", "type": "plate", "effect": "regen", "value": 3, "mat": "scale", "trim": "#f77622", "flavor": "Shed by a dragon. Only its kin can wear it."}],
	"Undead": [{"id": "gravecloth_shroud", "name": "Gravecloth Shroud", "slot": "Chest", "type": "robe", "effect": "lifesteal", "value": 12, "mat": "dark", "trim": "#86c06c", "flavor": "The living get cold just touching it."}],
	"Orc": [{"id": "skullsplitter", "name": "Skullsplitter", "slot": "Weapon", "type": "axe", "effect": "double_strike", "value": 20, "mat": "iron", "trim": "#75a743", "flavor": "Too heavy for anyone but an orc."}],
	"Goblin": [{"id": "goblin_kings_purse", "name": "Goblin King's Purse", "slot": "Off Hand", "type": "orb", "effect": "gold_find", "value": 35, "mat": "gold", "trim": "#facc15", "flavor": "It only opens for goblin fingers."}],
	"Golem": [{"id": "core_bulwark", "name": "Core Bulwark", "slot": "Off Hand", "type": "tower", "effect": "thorns", "value": 25, "mat": "steel", "trim": "#7fd0f0", "flavor": "Slots right into a golem's arm."}],
}
const RACE_GEAR_BOSS_CHANCE := 1.0  # % per boss kill for a hero of that race

static func gear_for(race: String) -> Array:
	return RACE_GEAR.get(race, [])

static func make_race_gear(def: Dictionary, floor_num: int, id: int) -> Dictionary:
	var info: Dictionary = GameData.SLOT_INFO[def["slot"]]
	return {"id": id, "def": def["id"], "base_name": def["name"], "name": def["name"], "type": def["type"], "flavor": def["flavor"],
		"slot": def["slot"], "stat": info["stat"], "rarity": GameData.UNIQUE,
		"bonus": maxi(1, int(GameData.base_bonus(def["slot"], floor_num) * float(GameData.RARITY_MULTS[GameData.UNIQUE]) * 1.1)),
		"level": 0, "floor": floor_num, "effect": def["effect"], "effect_value": def["value"], "race_only": def_race(def["id"]),
		"art": "r_" + String(def["id"])}

static func gear_by_art(art: String) -> Dictionary:
	for r in RACE_GEAR:
		for d in RACE_GEAR[r]:
			if "r_" + String(d["id"]) == art:
				return d
	return {}

## Which race a piece of race gear (by id) belongs to.
static func def_race(gear_id: String) -> String:
	for r in RACE_GEAR:
		for d in RACE_GEAR[r]:
			if d["id"] == gear_id:
				return r
	return ""

## Can this hero wear this item?
static func can_wear(g: GameState, item: Dictionary) -> bool:
	var r: String = item.get("race_only", "")
	return r == "" or r == g.race()
