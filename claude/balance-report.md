# Balance report (headless simulator)

## R5 balance pass (2.1, Oct 23): before / after

Both runs: 6 heroes, 10 hours of play each, same seeds, `BALANCE_BUDGET=700`, at most 3 heroes at once
(`BALANCE_PARALLEL`). "Before" is the game as merged (currency merge + pet abilities) with the old
sim's town routine; "after" is the tuning below with the fixed sim routine. The full "after" report
follows this section. Sim noise is large: the same settings vary by about +-0.5 h on the floor-100
median between runs (a run with 51-100 attack bands of 1.015 / 1.012 gave 3.5 h; the final 1.014 / 1.011, below, 3.9 h).
The run below was made just before the plain-chest scrap bump (4-8 -> 8-12), a small change.

| | Before | After |
|---|---|---|
| Floor 25 median | 0h11 | 0h09 |
| Floor 50 median | 0h41 | 0h30 |
| Floor 100 median (range) | 4h48 (3h00-7h38, 5 of 6) | 3h53 (2h43-5h08, 6 of 6) |
| Furthest floor in 10 h (median) | 115 | 136 |
| Minutes for floors 1-25 / 26-50 / 51-75 / 76-100 / 101-125 | 12 / 26 / 61 / 208 / - | 9 / 21 / 66 / 115 / 135 |
| Slowest 25 floors vs early pace | 4.8x (76-100) | 3.1x (101-125) |
| Deaths on floors 51-100 (all heroes) | 291 | 177 (-39%) |
| Deaths per hour spent on floors 51-100 | ~9.2 | 9.2 |
| Deaths per hour overall | 6.45 | 5.57 |
| Deaths: Mage / Ranger / Warrior / Knight / Cleric / Trickster | 71 / 67 / 58 / 63 / 66 / 62 | 64 / 69 / 58 / 48 / 43 / 52 |
| Gold+bank at 10 h | 85-111k (piled up) | 11-37k (restocks spend it) |
| Dust over the run | 10-280, mostly idle | 10-160, spent on skills |
| Scrap | 0-22 | 0-37 (still the tight one) |

What the "after" numbers say:
- The 51-100 wall is gone as a cliff: 76-100 now takes about 1.7x the 51-75 stretch (was 3.4x), and
  the next stretches (101-150) take a similar 2-3 hours each instead of a new cliff.
- Floor 100 lands at about 3.9 h median (3.5 h in a near-identical run): just under the 4-6 h target. Raising the attack bands of
  51-100 a little (1.014 -> 1.017) gave 3.4 h with more deaths, so time and deaths trade 1:1 here.
- Half the deaths to get through 51-100, but not half per hour: the sim heroes dive until they fall,
  so they always die at about the same rate at their frontier. Fewer deaths per floor is the real gain.
- 2 in 3 deaths are to Epic or better monsters, mostly from blind Elite doors (12% of doors, at least
  Epic). Fights at death last ~5 turns: spikes kill, not attrition.

### What changed (numbers)

| Where | Change |
|---|---|
| `game_data.gd` | Monster growth per floor is now banded, with separate HP and Attack tables (`ENEMY_GROWTH_BANDS`, `ENEMY_ATK_GROWTH_BANDS`, `GameData.enemy_growth()` / `enemy_attack_growth()`; spawn, trials, realm danger text and raid HP use them). Was 2.5% a floor everywhere. HP: 1-25 2.7%, 26-50 3.4%, 51-75 3.4%, 76-100 3.0%, 101-150 1.2%, 151-250 0.8%, 251+ 0.6%. Attack: 1-25 2.7%, 26-50 3.2%, 51-75 1.4%, 76-100 1.1%, 101-250 0.6%, 251+ 0.5%. Calamity strength is untouched. |
| `monsters.gd` TIERS | Rare atk 1.25 -> 1.2; Epic hp 3.2 -> 3.0, atk 1.4 -> 1.3; Legendary hp 4.5 -> 4.0, atk 1.6 -> 1.4, mods 3 -> 2; Mythic hp 6.5 -> 5.5, atk 1.8 -> 1.55, mods 4 -> 3. Regenerating stops healing after 40 turns of a fight (`REGEN_TURNS`): the softer attack curve made endless heal-vs-regen fights possible (3 seen). |
| `classes.gd` | Mage hp 0.85 -> 1.0, def 0.9 -> 1.05; Ranger hp 1.05 -> 1.2, def 1.0 -> 1.1 (tanks stay 1.25-1.5). Blurbs updated. |
| Death (not Hardcore) | Keep 2 potions on a fall (`DEATH_KEEP_POTIONS`); the shop restock fills every empty gear slot first, so a fall never leaves you unable to re-gear. Texts: death tip, Guide, town-founding blurb. |
| `economy.gd` | Plain chests (goblin, horde) 8-12 scrap (was 4-8). Gold and dust left as they are (see below). |
| Sim (`tools/balance_sim.gd`) | Upgrades: cheapest *affordable* upgrade (skips ones needing missing dust). Set pieces: only crafted when the piece beats what is worn (it re-crafted every set piece on every visit and salvaged the copies: a dust and scrap drain). Bags: sewn with scrap only when the gold one is out of reach. Shop re-rolls with 20 restocks of gold to spare (was 100, why gold piled to 100k). Takes its strongest pets along. Runs from a fight with no kill for 300 turns. New report lines: deaths/hour on 51-100, boss-floor deaths, "How heroes fall", average upgrade level, pets. `BALANCE_PARALLEL`, `BALANCE_REPORT` env vars. |

### Floors 100-1000 by extrapolation (growth multiplier on top of the linear part)

| Floor | Old HP and Attack | New HP | New Attack |
|---|---|---|---|
| 50 | 3.35 | 4.37 | 4.17 |
| 100 | 11.5 | 21.1 | 8.14 |
| 150 | 39.6 | 38.3 | 11.0 |
| 250 | 468 | 85.1 | 20.0 |
| 500 | 224,000 | 380 | 69.5 |
| 750 | 108,000,000 | 1,690 | 242 |
| 1000 | 5.2e10 | 7,550 | 842 |

The old curve made 250+ unreachable by any gear (items grow linearly with depth). The new one asks
for roughly 2-3 hours per 25 floors around 100-200 in the sim; one hero reached 200-310 in 10 h in
several runs. Deeper than 250 was not simulated to the end (no time this pass).

### Economy by band (after)
- Gold: floats 10-60k from floor 50 on; the restock (30 + 10 x best floor) absorbs it once a player
  re-rolls the shop. Not flooded.
- Dust: 10-160 at any time, spent on skill ranks and set pieces as it comes; slow build-up after 8 h.
  Neither starved nor flooded.
- Scrap: still always near 0, and worn gear averages only +0.0 to +0.7 upgrade levels at 10 h,
  because gear is replaced by deeper drops long before upgrades pay off. Upgrades (and the
  dust-for-+6..+10 sink) barely matter before floor 150.

### Left for a later pass
- Floor 100 median is 3.5-3.9 h, a little under 4-6 h. Next lever: the 51-100 attack bands (1.014 / 1.011) or early bands, or slower XP; every step there costs deaths.
- Deaths per hour at the frontier are unchanged (dive-until-death behaviour). Biggest single cause: blind Elite doors (Epic+). Ideas: show "danger" on doors without Sense, Auto skipping Elite doors when below 75% HP, or Elite = one tier up instead of "at least Epic".
- Casters: base HP/Def raised, but Mage and Ranger still die most (64 / 69 vs 43-58). A caster-only shield or evasion passive would be the next step.
- Scrap/upgrades: consider carrying part of an item's upgrade levels to its replacement, or more scrap from salvage, so upgrading is worth it.
- Sim: run deeper (BALANCE_BUDGET 1500+, 20+ h) to check 250-750; the God-class, hidden-class (x1.9 by 75) and egg changes on big-update were not in this branch.
- Sim heroes stay at 0-2 pets (nests are rare); pet abilities have little effect on these numbers.

---


Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 10 hours of play each (played 10.0 hours to 10.0 hours).
- Floor 100: median time 3.9 hours (6 of 6 heroes got there, fastest 2.7 hours, slowest 5.1 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 136 (lowest 115, highest 200). Floors beyond that need more play time than was simulated.
- Deaths: median 55 per hero (334 in total, 5.57 per hour of play).
- Pace: the first 100 floors take about 44 minutes per 25 floors. The slowest stretch is floors 101-125 at about 135 minutes (3.1 times the early pace).
- Defense: from floor 150 the median hero survives fewer than 4 monster hits.
- Offense: from floor 25 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 177 deaths in 19.3 hours there (9.15 per hour).
- Of all deaths, 15 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Warlord | 136 | 65 | 708 | +0.0 | 10h00 | 58 | 221 | 1 | 11.1k | 4 | 15 | full time |
| Mage/Elf | Cryomancer | 177 | 69 | 1379 | +0.2 | 10h00 | 64 | 201 | 1 | 36.5k | 7 | 143 | full time |
| Ranger/Dwarf | Beastmaster | 115 | 58 | 699 | +0.3 | 10h00 | 69 | 215 | 1 | 26.7k | 10 | 84 | full time |
| Cleric/Angel | Storm Druid | 200 | 65 | 1177 | +0.0 | 10h00 | 43 | 145 | 0 | 26.6k | 5 | 144 | full time |
| Trickster/Goblin | Illusionist | 131 | 60 | 895 | +0.0 | 10h00 | 52 | 178 | 2 | 12.3k | 4 | 73 | full time |
| Knight/Orc | Juggernaut | 136 | 58 | 1433 | +0.3 | 10h00 | 48 | 185 | 0 | 22.3k | 8 | 80 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h08 | 0h34 | 3h55 | not reached | not reached | not reached |
| Mage/Elf | 0h16 | 0h44 | 2h44 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h08 | 0h25 | 4h06 | not reached | not reached | not reached |
| Cleric/Angel | 0h09 | 0h26 | 2h43 | not reached | not reached | not reached |
| Trickster/Goblin | 0h09 | 0h38 | 3h50 | not reached | not reached | not reached |
| Knight/Orc | 0h08 | 0h19 | 5h08 | not reached | not reached | not reached |
| **median** | 0h09 | 0h30 | 3h53 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h08 | 10 | 180 | 171 | 960 | 2217 | 120 | 13.0 | 13.5 | 0 | 1593 | 0 | 10 |
| Mage/Elf | 0h16 | 12 | 185 | 172 | 645 | 2217 | 120 | 12.9 | 8.8 | 2 | 4377 | 3 | 24 |
| Ranger/Dwarf | 0h08 | 9 | 139 | 127 | 662 | 2217 | 120 | 17.5 | 8.4 | 0 | 2204 | 18 | 2 |
| Cleric/Angel | 0h09 | 10 | 163 | 242 | 740 | 2217 | 120 | 9.2 | 9.3 | 0 | 4169 | 12 | 11 |
| Trickster/Goblin | 0h09 | 10 | 143 | 187 | 354 | 2217 | 120 | 11.9 | 4.5 | 0 | 2048 | 8 | 5 |
| Knight/Orc | 0h08 | 11 | 228 | 208 | 1030 | 2217 | 120 | 10.7 | 20.2 | 0 | 4079 | 4 | 8 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h34 | 19 | 509 | 504 | 2500 | 12.7k | 514 | 25.2 | 7.6 | 2 | 12.3k | 11 | 26 |
| Mage/Elf | 0h44 | 20 | 553 | 601 | 1483 | 12.7k | 514 | 21.1 | 4.4 | 4 | 9328 | 0 | 16 |
| Ranger/Dwarf | 0h25 | 16 | 446 | 629 | 1440 | 12.7k | 514 | 20.2 | 4.0 | 2 | 7669 | 4 | 14 |
| Cleric/Angel | 0h26 | 17 | 425 | 527 | 1819 | 12.7k | 514 | 24.1 | 4.5 | 1 | 8604 | 4 | 19 |
| Trickster/Goblin | 0h38 | 19 | 525 | 549 | 1349 | 12.7k | 514 | 23.1 | 3.8 | 3 | 11.5k | 0 | 40 |
| Knight/Orc | 0h19 | 16 | 444 | 513 | 1747 | 12.7k | 514 | 24.8 | 5.5 | 0 | 8022 | 17 | 10 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 3h55 | 42 | 1431 | 1709 | 8595 | 170.2k | 1887 | 99.6 | 7.1 | 21 | 24.5k | 21 | 49 |
| Mage/Elf | 2h44 | 38 | 1447 | 1669 | 4385 | 170.2k | 1887 | 102.0 | 3.4 | 16 | 40.0k | 8 | 27 |
| Ranger/Dwarf | 4h06 | 40 | 1325 | 1426 | 5774 | 170.2k | 1887 | 119.4 | 4.1 | 26 | 29.1k | 10 | 45 |
| Cleric/Angel | 2h43 | 35 | 1395 | 1278 | 7636 | 170.2k | 1887 | 133.2 | 5.7 | 12 | 21.8k | 23 | 66 |
| Trickster/Goblin | 3h50 | 39 | 1388 | 1437 | 5162 | 170.2k | 1887 | 118.4 | 3.7 | 20 | 33.8k | 21 | 39 |
| Knight/Orc | 5h08 | 44 | 1249 | 1311 | 8688 | 170.2k | 1887 | 129.8 | 8.4 | 25 | 19.6k | 18 | 53 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 9 | 16 | 8 | 10 | 10 | 8 | 9 |
| 26-50 | 26 | 28 | 17 | 17 | 29 | 11 | 21 |
| 51-75 | 45 | 62 | 70 | 63 | 112 | 124 | 66 |
| 76-100 | 157 | 58 | 151 | 74 | 80 | 165 | 115 |
| 101-125 | 183 | 135 | - | 10 | 77 | 184 | 135 |
| 126-150 | - | 194 | - | 62 | - | - | 128 |
| 151-175 | - | 93 | - | 260 | - | - | 176 |
| 176-200 | - | - | - | 14 | - | - | 14 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 2 | Mage/Elf |
| 26-50 | 16 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin |
| 51-75 | 70 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 107 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 74 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 126-150 | 44 | Warrior/Human, Mage/Elf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 151-175 | 15 | Mage/Elf, Cleric/Angel |
| 176-200 | 6 | Mage/Elf, Cleric/Angel |

## How heroes fall

- 334 deaths: 2 with 2 or fewer gear pieces worn (re-gearing after a fall), 15 to bosses, 280 to monsters with modifiers.
- Fight length at death: median 5 turns. Monster HP left when the hero fell: median 43%.
- Killer's tier: Rare 41, Common 54, Mythic 22, Epic 122, Uncommon 65, Legendary 30.
- Biggest damage source in the fatal fight: hits 334.
- Killer's modifiers: Shielded 25, Swift 63, Armored 34, Elemental 35, Explosive 27, Giant 42, Regenerating 36, Venomous 25, Teleporting 32, Thorny 37, Vampiric 22, Enraged 46, Burning 30, Frigid 22.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 44 | 41 | 55 | 55 | 45 | 54 |
| 1h10 | 60 | 64 | 66 | 67 | 59 | 60 |
| 1h50 | 80 | 86 | 78 | 76 | 72 | 73 |
| 2h30 | 88 | 97 | 78 | 94 | 72 | 85 |
| 3h10 | 99 | 114 | 80 | 137 | 90 | 85 |
| 3h50 | 99 | 114 | 89 | 140 | 98 | 85 |
| 4h30 | 110 | 114 | 100 | 156 | 108 | 88 |
| 5h10 | 110 | 125 | 103 | 170 | 127 | 100 |
| 5h50 | 110 | 130 | 105 | 170 | 129 | 100 |
| 6h30 | 114 | 139 | 109 | 173 | 129 | 106 |
| 7h10 | 130 | 139 | 109 | 173 | 129 | 113 |
| 7h50 | 136 | 145 | 112 | 173 | 129 | 113 |
| 8h30 | 136 | 151 | 112 | 200 | 129 | 136 |
| 9h10 | 136 | 167 | 115 | 200 | 130 | 136 |
| 9h50 | 136 | 177 | 115 | 200 | 131 | 136 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 18 | 16 | 17 | 18 | 16 | 18 |
| 1h10 | 24 | 24 | 24 | 25 | 24 | 24 |
| 1h50 | 30 | 31 | 29 | 30 | 28 | 29 |
| 2h30 | 34 | 36 | 32 | 33 | 32 | 32 |
| 3h10 | 38 | 41 | 35 | 37 | 36 | 36 |
| 3h50 | 42 | 44 | 38 | 41 | 39 | 39 |
| 4h30 | 45 | 48 | 41 | 44 | 42 | 41 |
| 5h10 | 48 | 51 | 43 | 48 | 45 | 44 |
| 5h50 | 51 | 54 | 46 | 51 | 48 | 46 |
| 6h30 | 53 | 57 | 48 | 53 | 50 | 49 |
| 7h10 | 56 | 59 | 50 | 56 | 52 | 51 |
| 7h50 | 59 | 61 | 52 | 58 | 54 | 52 |
| 8h30 | 61 | 64 | 53 | 60 | 56 | 54 |
| 9h10 | 63 | 66 | 55 | 63 | 57 | 56 |
| 9h50 | 65 | 69 | 57 | 65 | 59 | 58 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 460 | 329 | 295 | 290 | 344 | 367 |
| 1h10 | 581 | 394 | 345 | 498 | 354 | 593 |
| 1h50 | 632 | 1019 | 705 | 865 | 448 | 614 |
| 2h30 | 621 | 777 | 610 | 1147 | 904 | 444 |
| 3h10 | 888 | 916 | 419 | 1070 | 1312 | 620 |
| 3h50 | 1136 | 1339 | 707 | 1996 | 1388 | 1151 |
| 4h30 | 573 | 647 | 1296 | 2192 | 563 | 648 |
| 5h10 | 994 | 661 | 536 | 962 | 1724 | 672 |
| 5h50 | 957 | 1152 | 548 | 2595 | 895 | 601 |
| 6h30 | 594 | 1101 | 912 | 2005 | 671 | 913 |
| 7h10 | 677 | 1535 | 1572 | 1219 | 814 | 588 |
| 7h50 | 804 | 1424 | 1371 | 1783 | 1070 | 1059 |
| 8h30 | 1173 | 1427 | 837 | 1224 | 1979 | 880 |
| 9h10 | 1140 | 1546 | 1411 | 2053 | 1929 | 1889 |
| 9h50 | 1632 | 908 | 886 | 1037 | 1563 | 1027 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 7316 | 5202 | 6917 | 5079 | 4324 | 4277 |
| 1h10 | 11.9k | 11.5k | 4017 | 17.3k | 13.1k | 9456 |
| 1h50 | 11.8k | 28.6k | 14.4k | 19.5k | 9125 | 13.3k |
| 2h30 | 9654 | 13.7k | 6974 | 19.0k | 39.9k | 10.7k |
| 3h10 | 15.3k | 16.7k | 7199 | 7312 | 36.1k | 17.2k |
| 3h50 | 23.8k | 21.3k | 13.8k | 52.0k | 31.4k | 23.2k |
| 4h30 | 7819 | 23.6k | 34.2k | 30.5k | 10.8k | 11.5k |
| 5h10 | 28.1k | 21.9k | 13.3k | 9738 | 34.8k | 5807 |
| 5h50 | 28.5k | 20.6k | 14.7k | 83.1k | 7651 | 19.7k |
| 6h30 | 7518 | 18.1k | 17.3k | 42.7k | 10.9k | 13.6k |
| 7h10 | 18.1k | 27.4k | 21.5k | 28.8k | 20.5k | 9270 |
| 7h50 | 13.4k | 32.0k | 21.7k | 49.4k | 36.2k | 23.2k |
| 8h30 | 44.2k | 31.7k | 7354 | 14.6k | 85.3k | 12.7k |
| 9h10 | 28.2k | 16.3k | 28.5k | 53.5k | 35.8k | 61.5k |
| 9h50 | 26.3k | 4082 | 24.5k | 30.1k | 47.1k | 17.0k |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 15 | 6 | 3 | 4 | 7 | 5 |
| 1h10 | 6 | 2 | 6 | 2 | 0 | 11 |
| 1h50 | 3 | 0 | 2 | 19 | 6 | 3 |
| 2h30 | 13 | 9 | 1 | 14 | 13 | 13 |
| 3h10 | 6 | 14 | 8 | 9 | 10 | 4 |
| 3h50 | 19 | 12 | 4 | 16 | 21 | 6 |
| 4h30 | 1 | 1 | 12 | 6 | 9 | 0 |
| 5h10 | 8 | 10 | 6 | 0 | 7 | 8 |
| 5h50 | 2 | 4 | 8 | 6 | 2 | 5 |
| 6h30 | 0 | 6 | 5 | 14 | 8 | 0 |
| 7h10 | 2 | 22 | 6 | 14 | 0 | 8 |
| 7h50 | 5 | 11 | 12 | 12 | 12 | 4 |
| 8h30 | 2 | 9 | 4 | 2 | 37 | 3 |
| 9h10 | 4 | 4 | 1 | 12 | 8 | 0 |
| 9h50 | 2 | 9 | 14 | 5 | 16 | 7 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 18 | 14 | 18 | 15 | 17 | 40 |
| 1h10 | 55 | 28 | 33 | 47 | 16 | 31 |
| 1h50 | 28 | 33 | 38 | 31 | 79 | 65 |
| 2h30 | 65 | 13 | 19 | 30 | 61 | 44 |
| 3h10 | 9 | 63 | 38 | 34 | 5 | 67 |
| 3h50 | 30 | 68 | 87 | 15 | 39 | 52 |
| 4h30 | 34 | 51 | 32 | 78 | 24 | 69 |
| 5h10 | 30 | 47 | 70 | 3 | 21 | 56 |
| 5h50 | 22 | 41 | 24 | 39 | 33 | 46 |
| 6h30 | 18 | 131 | 50 | 45 | 43 | 41 |
| 7h10 | 86 | 79 | 71 | 52 | 31 | 35 |
| 7h50 | 47 | 67 | 67 | 27 | 109 | 16 |
| 8h30 | 158 | 124 | 43 | 109 | 103 | 63 |
| 9h10 | 109 | 107 | 136 | 64 | 98 | 64 |
| 9h50 | 20 | 85 | 54 | 121 | 92 | 58 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 2 | 3 | 3 | 2 | 3 | 2 |
| 1h10 | 6 | 7 | 8 | 5 | 7 | 6 |
| 1h50 | 11 | 10 | 12 | 9 | 11 | 9 |
| 2h30 | 15 | 16 | 17 | 12 | 14 | 13 |
| 3h10 | 18 | 20 | 22 | 16 | 17 | 16 |
| 3h50 | 21 | 25 | 26 | 16 | 20 | 19 |
| 4h30 | 27 | 30 | 29 | 20 | 26 | 23 |
| 5h10 | 30 | 34 | 35 | 24 | 26 | 26 |
| 5h50 | 33 | 40 | 40 | 24 | 31 | 30 |
| 6h30 | 39 | 44 | 44 | 27 | 36 | 33 |
| 7h10 | 42 | 48 | 47 | 31 | 39 | 37 |
| 7h50 | 46 | 52 | 53 | 34 | 42 | 40 |
| 8h30 | 49 | 56 | 59 | 36 | 43 | 43 |
| 9h10 | 53 | 60 | 62 | 39 | 47 | 45 |
| 9h50 | 56 | 64 | 68 | 42 | 50 | 48 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 489 | 491 | 344 | 277 | 242 | 296 |
| 1h10 | 717 | 365 | 370 | 917 | 307 | 790 |
| 1h50 | 1397 | 1223 | 1167 | 942 | 497 | 528 |
| 2h30 | 1606 | 1507 | 1053 | 1175 | 934 | 482 |
| 3h10 | 1491 | 1151 | 500 | 1693 | 1384 | 785 |
| 3h50 | 1583 | 1877 | 1468 | 1940 | 1437 | 1199 |
| 4h30 | 878 | 842 | 1461 | 2253 | 682 | 884 |
| 5h10 | 2173 | 485 | 839 | 1028 | 1681 | 678 |
| 5h50 | 1957 | 2271 | 716 | 2788 | 793 | 762 |
| 6h30 | 1019 | 2483 | 1378 | 2789 | 739 | 1118 |
| 7h10 | 1151 | 2510 | 1424 | 1113 | 937 | 959 |
| 7h50 | 1416 | 1979 | 1813 | 2502 | 1929 | 1638 |
| 8h30 | 2615 | 2111 | 1845 | 1192 | 2315 | 974 |
| 9h10 | 2678 | 3121 | 2202 | 2967 | 2161 | 2481 |
| 9h50 | 2771 | 180 | 2233 | 1238 | 2314 | 798 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 2229 | 761 | 1123 | 1496 | 1028 | 1929 |
| 1h10 | 2897 | 1142 | 1407 | 1966 | 928 | 2568 |
| 1h50 | 3218 | 3029 | 2464 | 5523 | 1168 | 2617 |
| 2h30 | 3563 | 1714 | 1789 | 6888 | 3137 | 2966 |
| 3h10 | 5296 | 2263 | 2042 | 4750 | 4402 | 4992 |
| 3h50 | 6757 | 4804 | 3112 | 10.8k | 5162 | 7685 |
| 4h30 | 4431 | 2483 | 5916 | 13.3k | 2089 | 5351 |
| 5h10 | 6562 | 2416 | 2665 | 6900 | 7090 | 4846 |
| 5h50 | 6514 | 3811 | 2777 | 16.6k | 4412 | 5037 |
| 6h30 | 5340 | 3133 | 3404 | 16.0k | 3232 | 7102 |
| 7h10 | 6011 | 6314 | 7129 | 11.7k | 4808 | 5978 |
| 7h50 | 6428 | 4682 | 7084 | 14.4k | 4924 | 8967 |
| 8h30 | 7497 | 5321 | 3202 | 11.7k | 9623 | 6848 |
| 9h10 | 8056 | 5717 | 6656 | 14.7k | 9744 | 15.1k |
| 9h50 | 12.9k | 3607 | 3388 | 9424 | 8104 | 8710 |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h30 | 7.1 | 4.8 | 7.1 | 8.0 | 6.6 | 8.8 |
| 1h10 | 6.1 | 6.1 | 6.3 | 6.7 | 7.1 | 5.3 |
| 1h50 | 5.7 | 5.5 | 8.7 | 6.1 | 6.1 | 8.0 |
| 2h30 | 4.8 | 4.8 | 6.6 | 6.2 | 7.3 | 10.2 |
| 3h10 | 5.5 | 5.1 | 8.7 | 6.1 | 8.8 | 5.1 |
| 3h50 | 7.4 | 6.0 | 7.0 | 11.8 | 9.2 | 7.0 |
| 4h30 | 7.1 | 6.4 | 8.0 | 6.3 | 8.8 | 11.3 |
| 5h10 | 5.3 | 7.1 | 8.2 | 8.7 | 9.8 | 11.3 |
| 5h50 | 6.7 | 5.6 | 10.2 | 8.7 | 13.6 | 8.1 |
| 6h30 | 7.9 | 5.9 | 8.0 | 8.6 | 9.4 | 9.4 |
| 7h10 | 7.7 | 5.9 | 7.9 | 7.2 | 7.4 | 7.0 |
| 7h50 | 7.9 | 6.4 | 6.3 | 7.7 | 6.4 | 5.7 |
| 8h30 | 4.8 | 4.9 | 7.1 | 10.3 | 12.5 | 7.8 |
| 9h10 | 6.0 | 4.8 | 8.6 | 8.0 | 6.6 | 8.5 |
| 9h50 | 7.3 | 6.7 | 7.6 | 11.5 | 12.2 | 8.5 |

## Problems seen while simulating

- Nothing got stuck.
