# Balance report (headless simulator)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 6 hours of play each (played 6.0 hours to 6.0 hours).
- Gear: 8 slots. Ring and Necklace are about half a slot each (a ring is 15% of a weapon's Attack, a necklace 25% of a helmet's HP, plus a small charm from Uncommon up).
- Floor 100: median time 2.6 hours (6 of 6 heroes got there, fastest 1.5 hours, slowest 5.2 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 130 (lowest 100, highest 164). Floors beyond that need more play time than was simulated.
- Deaths: median 30 per hero (176 in total, 4.89 per hour of play).
- Pace: the first 100 floors take about 26 minutes per 25 floors. Heroes slow to 4 times that or worse from floors 101-125. The slowest stretch is floors 101-125 at about 178 minutes (6.7 times the early pace).
- Defense: at every milestone the median hero survives 4 or more hits.
- Offense: from floor 25 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 114 deaths in 15.4 hours there (7.43 per hour).
- Of all deaths, 6 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Crusader | 123 | 49 | 1331 | +0.8 | 6h00 | 26 | 95 | 1 | 25.1k | 16 | 28 | full time |
| Mage/Elf | Lightbinder | 137 | 55 | 1897 | +1.8 | 6h00 | 42 | 142 | 1 | 28.1k | 23 | 32 | full time |
| Ranger/Dwarf | Stormcaller | 119 | 46 | 1015 | +0.6 | 6h00 | 34 | 119 | 2 | 29.4k | 38 | 13 | full time |
| Cleric/Angel | Storm Druid | 164 | 46 | 3186 | +3.6 | 6h00 | 18 | 77 | 1 | 79.2k | 34 | 39 | full time |
| Trickster/Goblin | Illusionist | 100 | 50 | 1413 | +1.0 | 6h00 | 34 | 133 | 2 | 19.9k | 36 | 2 | full time |
| Knight/Orc | Juggernaut | 140 | 46 | 1291 | +0.3 | 6h00 | 22 | 96 | 3 | 42.7k | 41 | 88 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h07 | 0h16 | 4h01 | not reached | not reached | not reached |
| Mage/Elf | 0h08 | 0h29 | 2h04 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h07 | 0h35 | 3h11 | not reached | not reached | not reached |
| Cleric/Angel | 0h09 | 0h19 | 1h30 | not reached | not reached | not reached |
| Trickster/Goblin | 0h09 | 0h29 | 5h10 | not reached | not reached | not reached |
| Knight/Orc | 0h08 | 0h16 | 1h50 | not reached | not reached | not reached |
| **median** | 0h08 | 0h24 | 2h38 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h07 | 11 | 122 | 145 | 762 | 2217 | 120 | 15.3 | 9.9 | 0 | 3066 | 4 | 27 |
| Mage/Elf | 0h08 | 11 | 157 | 245 | 581 | 2217 | 120 | 9.0 | 7.4 | 0 | 2427 | 9 | 4 |
| Ranger/Dwarf | 0h07 | 9 | 137 | 182 | 566 | 2217 | 120 | 12.2 | 7.5 | 0 | 1776 | 5 | 17 |
| Cleric/Angel | 0h09 | 11 | 167 | 200 | 735 | 2217 | 120 | 11.1 | 10.8 | 0 | 2205 | 4 | 12 |
| Trickster/Goblin | 0h09 | 11 | 161 | 167 | 622 | 2217 | 120 | 13.3 | 7.7 | 0 | 2981 | 15 | 3 |
| Knight/Orc | 0h08 | 11 | 145 | 158 | 854 | 2217 | 120 | 14.0 | 12.2 | 0 | 4037 | 5 | 10 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h16 | 16 | 318 | 357 | 1662 | 12.7k | 514 | 35.6 | 4.4 | 0 | 13.2k | 3 | 23 |
| Mage/Elf | 0h29 | 20 | 583 | 659 | 1862 | 12.7k | 514 | 19.3 | 5.5 | 2 | 6754 | 11 | 10 |
| Ranger/Dwarf | 0h35 | 18 | 485 | 550 | 2324 | 12.7k | 514 | 23.1 | 7.0 | 3 | 9678 | 6 | 1 |
| Cleric/Angel | 0h19 | 17 | 424 | 685 | 1485 | 12.7k | 514 | 18.6 | 4.1 | 0 | 9612 | 4 | 4 |
| Trickster/Goblin | 0h29 | 18 | 460 | 570 | 1360 | 12.7k | 514 | 22.3 | 3.7 | 2 | 16.0k | 36 | 18 |
| Knight/Orc | 0h16 | 16 | 407 | 489 | 1956 | 12.7k | 514 | 26.0 | 6.2 | 0 | 10.4k | 40 | 19 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 4h01 | 43 | 1500 | 2176 | 10.5k | 385.3k | 1887 | 177.1 | 9.0 | 15 | 60.7k | 56 | 27 |
| Mage/Elf | 2h04 | 34 | 1307 | 1398 | 4547 | 385.3k | 1887 | 275.6 | 3.3 | 13 | 17.4k | 4 | 7 |
| Ranger/Dwarf | 3h11 | 36 | 1390 | 1599 | 6544 | 385.3k | 1887 | 241.0 | 5.1 | 17 | 72.9k | 84 | 35 |
| Cleric/Angel | 1h30 | 29 | 1342 | 1322 | 6664 | 385.3k | 1887 | 291.5 | 4.8 | 5 | 31.8k | 42 | 15 |
| Trickster/Goblin | 5h10 | 47 | 1373 | 1833 | 4830 | 385.3k | 1887 | 210.2 | 3.7 | 29 | 64.4k | 15 | 6 |
| Knight/Orc | 1h50 | 31 | 1617 | 1115 | 6843 | 385.3k | 1887 | 345.6 | 6.7 | 5 | 42.2k | 76 | 9 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 8 | 8 | 7 | 9 | 10 | 8 | 8 |
| 26-50 | 9 | 22 | 29 | 10 | 20 | 9 | 15 |
| 51-75 | 43 | 23 | 66 | 24 | 87 | 33 | 38 |
| 76-100 | 182 | 72 | 90 | 47 | 193 | 61 | 81 |
| 101-125 | - | 178 | - | 67 | - | 220 | 178 |
| 126-150 | - | - | - | 118 | - | - | 118 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 2 | Warrior/Human |
| 26-50 | 12 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Trickster/Goblin |
| 51-75 | 40 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 74 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 35 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Knight/Orc |
| 126-150 | 11 | Mage/Elf, Cleric/Angel, Knight/Orc |
| 151-175 | 2 | Cleric/Angel |

## How heroes fall

- 176 deaths: 1 with 2 or fewer gear pieces worn (re-gearing after a fall), 13 to bosses, 143 to monsters with modifiers.
- Fight length at death: median 7 turns. Monster HP left when the hero fell: median 49%.
- Elite rooms: 605 entered, 7 deaths there (3% of all deaths, 1.2% of elite rooms).
- Worn gear upgrade level on reaching floor 100: median +2.0.
- Killer's tier: Epic 69, Uncommon 34, Legendary 20, Rare 12, Mythic 8, Common 33.
- Biggest damage source in the fatal fight: hits 176.
- Killer's modifiers: Giant 19, Teleporting 14, Swift 29, Thorny 20, Explosive 23, Venomous 12, Armored 18, Elemental 9, Regenerating 18, Shielded 13, Burning 17, Frigid 13, Vampiric 19, Enraged 24.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 57 | 47 | 36 | 53 | 35 | 57 |
| 0h50 | 63 | 66 | 55 | 80 | 60 | 75 |
| 1h20 | 86 | 82 | 70 | 90 | 63 | 89 |
| 1h50 | 89 | 82 | 79 | 107 | 69 | 98 |
| 2h20 | 91 | 100 | 90 | 107 | 77 | 100 |
| 2h50 | 97 | 106 | 95 | 126 | 86 | 100 |
| 3h20 | 97 | 106 | 100 | 126 | 90 | 102 |
| 3h50 | 97 | 112 | 100 | 138 | 90 | 110 |
| 4h20 | 118 | 114 | 115 | 138 | 90 | 110 |
| 4h50 | 118 | 114 | 115 | 160 | 95 | 117 |
| 5h20 | 118 | 126 | 115 | 160 | 100 | 117 |
| 5h50 | 123 | 137 | 115 | 160 | 100 | 140 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 18 | 17 | 14 | 17 | 14 | 17 |
| 0h50 | 26 | 24 | 21 | 24 | 23 | 24 |
| 1h20 | 29 | 29 | 25 | 28 | 28 | 28 |
| 1h50 | 32 | 33 | 29 | 31 | 32 | 31 |
| 2h20 | 35 | 36 | 32 | 33 | 35 | 33 |
| 2h50 | 38 | 39 | 34 | 35 | 38 | 35 |
| 3h20 | 40 | 42 | 36 | 37 | 40 | 38 |
| 3h50 | 42 | 45 | 39 | 39 | 42 | 39 |
| 4h20 | 44 | 47 | 41 | 41 | 44 | 41 |
| 4h50 | 45 | 50 | 43 | 42 | 46 | 43 |
| 5h20 | 47 | 52 | 44 | 44 | 48 | 45 |
| 5h50 | 49 | 54 | 46 | 45 | 49 | 46 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 484 | 306 | 183 | 474 | 209 | 465 |
| 0h50 | 730 | 882 | 341 | 453 | 470 | 1029 |
| 1h20 | 632 | 440 | 419 | 1229 | 734 | 681 |
| 1h50 | 1416 | 769 | 522 | 1254 | 922 | 1617 |
| 2h20 | 1202 | 810 | 566 | 1771 | 1094 | 535 |
| 2h50 | 617 | 1223 | 818 | 1308 | 1277 | 754 |
| 3h20 | 1027 | 1520 | 828 | 2105 | 1426 | 1533 |
| 3h50 | 1350 | 610 | 1688 | 1673 | 1211 | 1483 |
| 4h20 | 1227 | 610 | 1822 | 2365 | 1155 | 1860 |
| 4h50 | 1870 | 1236 | 1829 | 853 | 833 | 1112 |
| 5h20 | 2245 | 2002 | 1670 | 2576 | 823 | 1833 |
| 5h50 | 692 | 891 | 2100 | 2985 | 731 | 776 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 12.6k | 1918 | 4122 | 9183 | 1376 | 11.1k |
| 0h50 | 17.3k | 15.9k | 14.0k | 7947 | 9031 | 26.5k |
| 1h20 | 9478 | 1164 | 12.6k | 30.5k | 21.6k | 12.1k |
| 1h50 | 25.1k | 16.2k | 18.5k | 20.7k | 27.1k | 40.5k |
| 2h20 | 25.7k | 10.5k | 6288 | 19.0k | 25.3k | 22.8k |
| 2h50 | 14.2k | 32.2k | 8653 | 30.5k | 46.2k | 3661 |
| 3h20 | 37.9k | 54.2k | 21.5k | 77.4k | 50.8k | 61.6k |
| 3h50 | 42.1k | 3419 | 21.5k | 28.6k | 15.8k | 51.2k |
| 4h20 | 23.2k | 11.3k | 53.1k | 73.9k | 32.4k | 104.0k |
| 4h50 | 26.1k | 29.5k | 47.1k | 20.9k | 20.5k | 31.0k |
| 5h20 | 106.4k | 48.7k | 60.1k | 33.6k | 18.9k | 73.6k |
| 5h50 | 13.1k | 4685 | 19.4k | 85.9k | 6410 | 16.3k |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 10 | 29 | 38 | 7 | 6 | 17 |
| 0h50 | 13 | 0 | 40 | 8 | 37 | 39 |
| 1h20 | 3 | 2 | 49 | 30 | 12 | 19 |
| 1h50 | 37 | 7 | 54 | 21 | 23 | 76 |
| 2h20 | 42 | 4 | 1 | 33 | 63 | 0 |
| 2h50 | 22 | 36 | 13 | 27 | 34 | 50 |
| 3h20 | 47 | 43 | 87 | 90 | 42 | 107 |
| 3h50 | 57 | 22 | 48 | 14 | 16 | 9 |
| 4h20 | 8 | 34 | 28 | 54 | 43 | 34 |
| 4h50 | 38 | 19 | 13 | 31 | 38 | 93 |
| 5h20 | 37 | 23 | 37 | 72 | 11 | 12 |
| 5h50 | 44 | 31 | 75 | 149 | 2 | 66 |

### Average upgrade level of worn gear

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0.5 | 0.0 | 0.4 | 1.0 | 0.0 | 0.3 |
| 0h50 | 0.1 | 1.3 | 0.1 | 0.0 | 0.3 | 2.1 |
| 1h20 | 0.1 | 0.0 | 0.1 | 1.3 | 0.3 | 0.3 |
| 1h50 | 2.4 | 0.5 | 0.0 | 0.5 | 1.3 | 2.8 |
| 2h20 | 1.0 | 0.3 | 0.0 | 2.0 | 1.6 | 0.0 |
| 2h50 | 0.1 | 0.4 | 0.6 | 0.6 | 2.0 | 0.6 |
| 3h20 | 0.1 | 2.5 | 0.0 | 2.4 | 1.4 | 1.9 |
| 3h50 | 1.4 | 0.4 | 1.9 | 0.9 | 0.9 | 0.6 |
| 4h20 | 0.4 | 0.0 | 2.0 | 2.8 | 1.4 | 2.9 |
| 4h50 | 1.6 | 0.4 | 2.0 | 0.0 | 0.1 | 0.4 |
| 5h20 | 3.4 | 2.5 | 2.1 | 1.8 | 0.4 | 2.9 |
| 5h50 | 0.0 | 0.3 | 3.4 | 3.4 | 0.0 | 0.0 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 5 | 23 | 19 | 9 | 6 | 9 |
| 0h50 | 21 | 25 | 18 | 17 | 50 | 21 |
| 1h20 | 27 | 2 | 23 | 25 | 44 | 60 |
| 1h50 | 22 | 41 | 12 | 8 | 22 | 6 |
| 2h20 | 36 | 40 | 9 | 35 | 53 | 68 |
| 2h50 | 18 | 39 | 19 | 39 | 42 | 49 |
| 3h20 | 31 | 38 | 26 | 42 | 28 | 81 |
| 3h50 | 57 | 12 | 49 | 4 | 32 | 44 |
| 4h20 | 1 | 61 | 40 | 30 | 13 | 83 |
| 4h50 | 50 | 25 | 36 | 35 | 50 | 20 |
| 5h20 | 61 | 72 | 59 | 4 | 1 | 29 |
| 5h50 | 35 | 41 | 11 | 24 | 0 | 82 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0 | 2 | 2 | 0 | 2 | 0 |
| 0h50 | 3 | 4 | 5 | 4 | 5 | 2 |
| 1h20 | 6 | 10 | 8 | 5 | 8 | 5 |
| 1h50 | 6 | 13 | 11 | 8 | 11 | 5 |
| 2h20 | 9 | 16 | 14 | 8 | 14 | 9 |
| 2h50 | 11 | 19 | 17 | 11 | 17 | 12 |
| 3h20 | 12 | 22 | 19 | 11 | 20 | 12 |
| 3h50 | 15 | 28 | 21 | 14 | 23 | 16 |
| 4h20 | 16 | 31 | 24 | 14 | 26 | 16 |
| 4h50 | 21 | 33 | 27 | 17 | 29 | 19 |
| 5h20 | 22 | 36 | 30 | 18 | 31 | 19 |
| 5h50 | 25 | 42 | 33 | 18 | 34 | 22 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 578 | 633 | 202 | 636 | 423 | 607 |
| 0h50 | 752 | 1025 | 334 | 531 | 880 | 1144 |
| 1h20 | 1119 | 527 | 493 | 1413 | 1012 | 786 |
| 1h50 | 1497 | 1238 | 531 | 1687 | 1087 | 1487 |
| 2h20 | 1009 | 1534 | 423 | 2232 | 1013 | 598 |
| 2h50 | 655 | 1468 | 1049 | 1693 | 1698 | 1087 |
| 3h20 | 1261 | 2027 | 1649 | 2150 | 1655 | 1579 |
| 3h50 | 1401 | 737 | 1728 | 2499 | 1743 | 1621 |
| 4h20 | 1888 | 889 | 2123 | 2608 | 1775 | 1971 |
| 4h50 | 1943 | 1954 | 2041 | 1109 | 1669 | 1582 |
| 5h20 | 2140 | 1967 | 1929 | 3446 | 1549 | 2130 |
| 5h50 | 1027 | 2072 | 2591 | 3837 | 1548 | 899 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2239 | 860 | 672 | 1771 | 465 | 1998 |
| 0h50 | 5030 | 2803 | 1842 | 2367 | 1393 | 4843 |
| 1h20 | 3600 | 1523 | 1786 | 5480 | 2627 | 3073 |
| 1h50 | 8457 | 2670 | 2671 | 6534 | 3194 | 6843 |
| 2h20 | 8153 | 2797 | 3047 | 8124 | 3706 | 3200 |
| 2h50 | 5124 | 4506 | 4158 | 7877 | 4386 | 2990 |
| 3h20 | 8698 | 5678 | 2600 | 9887 | 4405 | 9602 |
| 3h50 | 9710 | 1560 | 6949 | 9433 | 4325 | 9878 |
| 4h20 | 10.3k | 2368 | 8493 | 11.8k | 4273 | 11.8k |
| 4h50 | 12.4k | 5426 | 8703 | 4857 | 3124 | 9866 |
| 5h20 | 14.4k | 7138 | 8645 | 13.3k | 2821 | 12.4k |
| 5h50 | 6397 | 2976 | 9477 | 17.4k | 2554 | 5677 |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 7.1 | 6.1 | 9.1 | 6.3 | 6.3 | 9.2 |
| 0h50 | 7.3 | 6.0 | 13.6 | 11.5 | 6.2 | 11.3 |
| 1h20 | 5.7 | 5.8 | 10.0 | 12.2 | 5.0 | 6.0 |
| 1h50 | 15.4 | 5.0 | 17.6 | 6.2 | 6.2 | 20.0 |
| 2h20 | 5.1 | 6.0 | 9.8 | 19.4 | 5.4 | 10.3 |
| 2h50 | 10.2 | 5.3 | 8.5 | 7.1 | 7.4 | 7.5 |
| 3h20 | 20.0 | 6.7 | 9.8 | 16.2 | 6.1 | 22.2 |
| 3h50 | 10.3 | 6.6 | 12.5 | 9.8 | 5.2 | 8.0 |
| 4h20 | 16.7 | 6.7 | 12.0 | 12.8 | 5.4 | 13.6 |
| 4h50 | 5.0 | 6.5 | 9.5 | 14.6 | 4.9 | 4.7 |
| 5h20 | 15.0 | 5.9 | 14.6 | 7.4 | 8.0 | 17.6 |
| 5h50 | 7.8 | 6.7 | 15.8 | 17.1 | 8.5 | 10.2 |

## Problems seen while simulating

- Nothing got stuck.
