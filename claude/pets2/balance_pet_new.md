# Balance report (headless simulator)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 6 hours of play each (played 6.0 hours to 6.0 hours).
- Gear: 8 slots. Ring and Necklace are about half a slot each (a ring is 15% of a weapon's Attack, a necklace 25% of a helmet's HP, plus a small charm from Uncommon up).
- Floor 100: median time 3.2 hours (6 of 6 heroes got there, fastest 1.9 hours, slowest 5.2 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 120 (lowest 100, highest 169). Floors beyond that need more play time than was simulated.
- Deaths: median 30 per hero (182 in total, 5.06 per hour of play).
- Pace: the first 100 floors take about 28 minutes per 25 floors. Heroes slow to 4 times that or worse from floors 101-125. The slowest stretch is floors 76-100 at about 141 minutes (5.1 times the early pace).
- Defense: at every milestone the median hero survives 4 or more hits.
- Offense: from floor 25 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 125 deaths in 17.4 hours there (7.20 per hour).
- Of all deaths, 6 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Crusader | 130 | 48 | 1981 | +1.5 | 6h00 | 30 | 106 | 2 | 23.3k | 11 | 27 | full time |
| Mage/Elf | Lightbinder | 110 | 54 | 1661 | +2.4 | 6h00 | 41 | 140 | 4 | 25.9k | 85 | 70 | full time |
| Ranger/Dwarf | Stormcaller | 100 | 48 | 989 | +0.5 | 6h00 | 34 | 129 | 2 | 11.1k | 31 | 12 | full time |
| Cleric/Angel | Inquisitor | 169 | 50 | 2996 | +3.8 | 6h00 | 25 | 93 | 4 | 74.6k | 57 | 10 | full time |
| Trickster/Goblin | Illusionist | 100 | 47 | 1063 | +0.4 | 6h00 | 31 | 116 | 1 | 29.2k | 8 | 25 | full time |
| Knight/Orc | Paladin | 130 | 45 | 2216 | +2.6 | 6h00 | 21 | 93 | 1 | 51.5k | 8 | 40 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h06 | 0h25 | 1h53 | not reached | not reached | not reached |
| Mage/Elf | 0h08 | 0h29 | 3h23 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h08 | 0h28 | 5h12 | not reached | not reached | not reached |
| Cleric/Angel | 0h10 | 0h36 | 2h09 | not reached | not reached | not reached |
| Trickster/Goblin | 0h10 | 0h31 | 4h27 | not reached | not reached | not reached |
| Knight/Orc | 0h08 | 0h16 | 3h05 | not reached | not reached | not reached |
| **median** | 0h08 | 0h29 | 3h14 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h06 | 9 | 126 | 126 | 762 | 2217 | 120 | 17.6 | 10.0 | 0 | 521 | 6 | 11 |
| Mage/Elf | 0h08 | 11 | 157 | 134 | 527 | 2217 | 120 | 16.5 | 6.9 | 0 | 3930 | 5 | 21 |
| Ranger/Dwarf | 0h08 | 10 | 179 | 210 | 627 | 2217 | 120 | 10.6 | 9.6 | 0 | 2794 | 3 | 6 |
| Cleric/Angel | 0h10 | 11 | 172 | 237 | 761 | 2217 | 120 | 9.4 | 10.3 | 0 | 3923 | 16 | 6 |
| Trickster/Goblin | 0h10 | 11 | 130 | 131 | 398 | 2217 | 120 | 16.9 | 5.3 | 0 | 2984 | 17 | 13 |
| Knight/Orc | 0h08 | 11 | 177 | 213 | 905 | 2217 | 120 | 10.4 | 13.7 | 0 | 1388 | 12 | 6 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h25 | 17 | 384 | 468 | 2156 | 12.7k | 514 | 27.2 | 6.3 | 2 | 10.6k | 36 | 30 |
| Mage/Elf | 0h29 | 20 | 465 | 536 | 1288 | 12.7k | 514 | 23.7 | 3.9 | 2 | 11.0k | 10 | 8 |
| Ranger/Dwarf | 0h28 | 18 | 460 | 619 | 2004 | 12.7k | 514 | 20.5 | 5.8 | 2 | 8943 | 16 | 2 |
| Cleric/Angel | 0h36 | 21 | 538 | 629 | 2719 | 12.7k | 514 | 20.2 | 8.0 | 2 | 8212 | 26 | 20 |
| Trickster/Goblin | 0h31 | 19 | 437 | 572 | 1579 | 12.7k | 514 | 22.2 | 4.4 | 2 | 17.5k | 24 | 17 |
| Knight/Orc | 0h16 | 16 | 305 | 417 | 1431 | 12.7k | 514 | 30.5 | 4.2 | 0 | 5285 | 4 | 13 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 1h53 | 31 | 1480 | 1367 | 8234 | 385.3k | 1887 | 281.9 | 7.0 | 7 | 23.0k | 42 | 21 |
| Mage/Elf | 3h23 | 42 | 1401 | 1711 | 4997 | 385.3k | 1887 | 225.2 | 3.8 | 21 | 25.5k | 13 | 41 |
| Ranger/Dwarf | 5h12 | 45 | 1483 | 1743 | 7924 | 385.3k | 1887 | 221.1 | 6.8 | 28 | 28.7k | 8 | 12 |
| Cleric/Angel | 2h09 | 34 | 1666 | 1588 | 7540 | 385.3k | 1887 | 242.6 | 5.9 | 10 | 25.0k | 58 | 29 |
| Trickster/Goblin | 4h27 | 42 | 1290 | 1897 | 5281 | 385.3k | 1887 | 203.1 | 3.8 | 23 | 40.5k | 35 | 69 |
| Knight/Orc | 3h05 | 37 | 1534 | 1780 | 7929 | 385.3k | 1887 | 216.5 | 7.9 | 12 | 27.4k | 50 | 35 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 7 | 8 | 8 | 11 | 10 | 8 | 8 |
| 26-50 | 19 | 22 | 20 | 26 | 21 | 9 | 21 |
| 51-75 | 30 | 21 | 39 | 26 | 39 | 39 | 35 |
| 76-100 | 57 | 152 | 245 | 67 | 197 | 130 | 141 |
| 101-125 | 210 | - | - | 131 | - | 76 | 131 |
| 126-150 | - | - | - | 51 | - | - | 51 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 2 | Warrior/Human |
| 26-50 | 18 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 51-75 | 42 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 83 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 26 | Warrior/Human, Mage/Elf, Cleric/Angel, Knight/Orc |
| 126-150 | 9 | Warrior/Human, Cleric/Angel, Knight/Orc |
| 151-175 | 2 | Cleric/Angel |

## How heroes fall

- 182 deaths: 1 with 2 or fewer gear pieces worn (re-gearing after a fall), 15 to bosses, 156 to monsters with modifiers.
- Fight length at death: median 7 turns. Monster HP left when the hero fell: median 47%.
- Elite rooms: 598 entered, 7 deaths there (3% of all deaths, 1.2% of elite rooms).
- Worn gear upgrade level on reaching floor 100: median +2.1.
- Killer's tier: Uncommon 34, Common 26, Epic 69, Legendary 22, Rare 18, Mythic 13.
- Biggest damage source in the fatal fight: hits 182.
- Killer's modifiers: Giant 20, Vampiric 19, Venomous 23, Shielded 14, Teleporting 11, Burning 15, Swift 31, Thorny 28, Frigid 15, Regenerating 20, Enraged 29, Explosive 15, Armored 22, Elemental 11.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 36 | 40 | 40 | 45 | 38 | 59 |
| 0h50 | 70 | 72 | 70 | 64 | 58 | 65 |
| 1h20 | 88 | 81 | 87 | 76 | 84 | 81 |
| 1h50 | 97 | 84 | 87 | 94 | 88 | 98 |
| 2h20 | 100 | 84 | 87 | 116 | 88 | 98 |
| 2h50 | 100 | 90 | 90 | 117 | 88 | 98 |
| 3h20 | 110 | 91 | 98 | 122 | 90 | 109 |
| 3h50 | 110 | 100 | 98 | 122 | 96 | 109 |
| 4h20 | 110 | 106 | 98 | 122 | 96 | 124 |
| 4h50 | 110 | 106 | 98 | 140 | 100 | 130 |
| 5h20 | 122 | 106 | 100 | 157 | 100 | 130 |
| 5h50 | 130 | 110 | 100 | 157 | 100 | 130 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 15 | 16 | 15 | 17 | 15 | 18 |
| 0h50 | 24 | 24 | 23 | 24 | 23 | 23 |
| 1h20 | 28 | 30 | 27 | 28 | 27 | 27 |
| 1h50 | 31 | 33 | 30 | 32 | 30 | 30 |
| 2h20 | 34 | 37 | 33 | 35 | 33 | 33 |
| 2h50 | 37 | 40 | 36 | 38 | 36 | 36 |
| 3h20 | 39 | 42 | 38 | 41 | 38 | 37 |
| 3h50 | 40 | 45 | 40 | 42 | 40 | 40 |
| 4h20 | 42 | 47 | 42 | 44 | 42 | 41 |
| 4h50 | 43 | 49 | 44 | 46 | 43 | 42 |
| 5h20 | 46 | 51 | 45 | 48 | 45 | 43 |
| 5h50 | 47 | 53 | 47 | 49 | 46 | 45 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 292 | 275 | 208 | 257 | 217 | 571 |
| 0h50 | 700 | 949 | 672 | 345 | 752 | 981 |
| 1h20 | 881 | 702 | 468 | 1104 | 509 | 1050 |
| 1h50 | 1451 | 791 | 575 | 993 | 482 | 546 |
| 2h20 | 535 | 949 | 520 | 1666 | 588 | 1363 |
| 2h50 | 1555 | 1320 | 503 | 2000 | 589 | 1313 |
| 3h20 | 1419 | 1252 | 550 | 1478 | 718 | 774 |
| 3h50 | 639 | 1530 | 1587 | 700 | 1348 | 1639 |
| 4h20 | 1737 | 713 | 1472 | 2118 | 1290 | 1812 |
| 4h50 | 1999 | 1117 | 1057 | 1793 | 1271 | 1378 |
| 5h20 | 2283 | 0 | 699 | 837 | 619 | 1973 |
| 5h50 | 1719 | 1065 | 639 | 2937 | 605 | 1899 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 6389 | 2843 | 2050 | 5631 | 1645 | 5027 |
| 0h50 | 10.8k | 14.1k | 14.6k | 8800 | 17.3k | 8680 |
| 1h20 | 6863 | 13.9k | 1783 | 22.8k | 3478 | 16.7k |
| 1h50 | 23.6k | 13.8k | 2777 | 13.7k | 2268 | 8459 |
| 2h20 | 4958 | 28.8k | 13.1k | 41.7k | 8929 | 22.1k |
| 2h50 | 43.6k | 18.6k | 7142 | 46.8k | 8348 | 31.6k |
| 3h20 | 27.7k | 37.2k | 13.7k | 24.0k | 8825 | 8370 |
| 3h50 | 7901 | 41.2k | 29.4k | 5472 | 67.4k | 31.6k |
| 4h20 | 23.3k | 20.3k | 71.3k | 47.7k | 30.3k | 69.4k |
| 4h50 | 37.7k | 27.0k | 33.7k | 40.5k | 33.3k | 34.0k |
| 5h20 | 111.6k | 4297 | 24.0k | 18.1k | 17.7k | 41.1k |
| 5h50 | 26.3k | 18.3k | 13.7k | 49.2k | 6582 | 52.6k |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 1 | 3 | 10 | 28 | 43 | 6 |
| 0h50 | 3 | 16 | 17 | 7 | 29 | 37 |
| 1h20 | 6 | 1 | 35 | 40 | 26 | 18 |
| 1h50 | 69 | 14 | 8 | 56 | 0 | 2 |
| 2h20 | 5 | 4 | 55 | 58 | 8 | 40 |
| 2h50 | 116 | 24 | 40 | 65 | 35 | 34 |
| 3h20 | 54 | 86 | 34 | 10 | 28 | 4 |
| 3h50 | 24 | 131 | 4 | 22 | 49 | 19 |
| 4h20 | 25 | 57 | 14 | 35 | 35 | 131 |
| 4h50 | 61 | 68 | 8 | 133 | 47 | 59 |
| 5h20 | 114 | 17 | 61 | 74 | 59 | 94 |
| 5h50 | 13 | 114 | 29 | 27 | 8 | 80 |

### Average upgrade level of worn gear

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0.0 | 0.3 | 0.3 | 0.0 | 0.4 | 0.5 |
| 0h50 | 0.6 | 1.3 | 0.5 | 0.0 | 0.5 | 1.4 |
| 1h20 | 0.4 | 0.5 | 0.0 | 1.4 | 0.3 | 1.5 |
| 1h50 | 2.1 | 0.4 | 0.4 | 0.3 | 0.3 | 0.0 |
| 2h20 | 0.0 | 0.3 | 0.1 | 2.6 | 0.3 | 1.1 |
| 2h50 | 2.0 | 1.4 | 0.4 | 2.9 | 0.0 | 0.9 |
| 3h20 | 1.0 | 1.3 | 0.0 | 0.6 | 0.3 | 0.4 |
| 3h50 | 0.4 | 2.4 | 1.9 | 0.5 | 1.6 | 2.1 |
| 4h20 | 1.6 | 0.6 | 1.3 | 2.8 | 1.8 | 2.5 |
| 4h50 | 2.6 | 0.4 | 0.6 | 1.0 | 1.3 | 0.4 |
| 5h20 | 4.4 | 0.0 | 0.3 | 0.0 | 0.4 | 1.8 |
| 5h50 | 0.5 | 0.3 | 0.0 | 3.5 | 0.0 | 1.8 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 13 | 8 | 25 | 18 | 28 | 7 |
| 0h50 | 8 | 2 | 10 | 36 | 26 | 5 |
| 1h20 | 8 | 5 | 30 | 40 | 19 | 38 |
| 1h50 | 21 | 21 | 1 | 34 | 33 | 20 |
| 2h20 | 12 | 71 | 54 | 49 | 7 | 38 |
| 2h50 | 30 | 19 | 35 | 2 | 21 | 40 |
| 3h20 | 29 | 34 | 35 | 23 | 37 | 39 |
| 3h50 | 41 | 50 | 52 | 44 | 56 | 58 |
| 4h20 | 45 | 41 | 53 | 35 | 58 | 72 |
| 4h50 | 9 | 21 | 20 | 38 | 72 | 20 |
| 5h20 | 78 | 20 | 27 | 44 | 42 | 41 |
| 5h50 | 22 | 49 | 19 | 60 | 1 | 55 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2 | 2 | 2 | 1 | 2 | 0 |
| 0h50 | 4 | 4 | 4 | 4 | 5 | 3 |
| 1h20 | 7 | 8 | 8 | 7 | 9 | 6 |
| 1h50 | 7 | 12 | 11 | 10 | 12 | 8 |
| 2h20 | 11 | 15 | 14 | 10 | 14 | 9 |
| 2h50 | 12 | 18 | 17 | 13 | 17 | 12 |
| 3h20 | 15 | 21 | 19 | 16 | 20 | 14 |
| 3h50 | 20 | 24 | 20 | 19 | 20 | 15 |
| 4h20 | 23 | 30 | 23 | 19 | 23 | 15 |
| 4h50 | 27 | 32 | 26 | 22 | 26 | 18 |
| 5h20 | 27 | 38 | 30 | 25 | 28 | 18 |
| 5h50 | 30 | 41 | 33 | 25 | 31 | 21 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 368 | 531 | 450 | 260 | 265 | 614 |
| 0h50 | 852 | 995 | 844 | 381 | 984 | 875 |
| 1h20 | 1051 | 1047 | 568 | 1143 | 529 | 1103 |
| 1h50 | 1355 | 1122 | 1103 | 1476 | 584 | 588 |
| 2h20 | 677 | 1197 | 649 | 1980 | 692 | 1502 |
| 2h50 | 1596 | 1662 | 450 | 2475 | 1046 | 1558 |
| 3h20 | 1846 | 1488 | 782 | 2086 | 1098 | 862 |
| 3h50 | 822 | 2202 | 1686 | 268 | 1630 | 1624 |
| 4h20 | 2163 | 1554 | 1882 | 2491 | 1897 | 2250 |
| 4h50 | 2610 | 1834 | 1411 | 2492 | 1594 | 1943 |
| 5h20 | 2893 | 104 | 712 | 1123 | 757 | 2372 |
| 5h50 | 1808 | 1915 | 1689 | 3811 | 653 | 2737 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 1761 | 781 | 438 | 1366 | 712 | 2886 |
| 0h50 | 4161 | 2806 | 3056 | 1796 | 2612 | 4373 |
| 1h20 | 6544 | 2244 | 2149 | 5165 | 1635 | 5316 |
| 1h50 | 8180 | 2758 | 2289 | 5747 | 1624 | 2899 |
| 2h20 | 3763 | 3704 | 2278 | 7656 | 2232 | 6193 |
| 2h50 | 10.2k | 4538 | 2484 | 9831 | 1849 | 7325 |
| 3h20 | 10.7k | 4646 | 2606 | 8311 | 2465 | 4605 |
| 3h50 | 4778 | 5518 | 7661 | 4151 | 5212 | 9297 |
| 4h20 | 11.6k | 2391 | 7070 | 11.5k | 5281 | 9629 |
| 4h50 | 13.9k | 5103 | 6340 | 11.2k | 5547 | 8932 |
| 5h20 | 15.8k | 739 | 4029 | 5318 | 2415 | 10.4k |
| 5h50 | 13.5k | 5398 | 3007 | 16.0k | 3311 | 10.9k |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 7.9 | 6.2 | 9.1 | 6.8 | 7.5 | 7.7 |
| 0h50 | 5.8 | 6.6 | 8.8 | 7.1 | 6.0 | 6.9 |
| 1h20 | 5.1 | 7.1 | 10.5 | 5.6 | 8.8 | 5.6 |
| 1h50 | 16.7 | 4.7 | 7.7 | 4.6 | 8.5 | 12.0 |
| 2h20 | 12.8 | 6.5 | 9.4 | 14.3 | 9.8 | 10.9 |
| 2h50 | 9.5 | 5.8 | 6.9 | 15.0 | 12.2 | 7.6 |
| 3h20 | 6.7 | 6.5 | 12.2 | 6.2 | 6.4 | 18.2 |
| 3h50 | 7.2 | 4.9 | 12.2 | 8.3 | 16.2 | 14.3 |
| 4h20 | 6.5 | 5.6 | 9.1 | 15.4 | 8.3 | 35.3 |
| 4h50 | 5.2 | 6.2 | 6.1 | 8.5 | 5.0 | 11.5 |
| 5h20 | 22.2 | 5.7 | 11.8 | 10.7 | 11.8 | 28.6 |
| 5h50 | 10.0 | 5.4 | 10.2 | 17.1 | 13.3 | 15.4 |

## Problems seen while simulating

- Nothing got stuck.
