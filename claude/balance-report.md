# Balance report (headless simulator)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), use no elixirs, pets, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 24 hours of play each (played 9.1 hours to 11.5 hours).
- Floor 100: median time 5.7 hours (4 of 6 heroes got there, fastest 3.5 hours, slowest 7.9 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Deaths: median 66 per hero (410 in total, 6.75 per hour of play).
- Pace: the first 100 floors take about 52 minutes per 25 floors. The slowest stretch is floors 76-100 at about 224 minutes (4.3 times the early pace).
- Defense: from floor 75 the median hero survives fewer than 4 monster hits.
- Offense: from floor 25 a plain hero attack needs more than 12 swings to kill the monster.

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Play time | Deaths | Home trips | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Templar Lord | 109 | 65 | 523 | 10h22 | 61 | 236 | 16.4k | 9 | 0 | real-time budget |
| Mage/Elf | Pyromancer | 91 | 57 | 460 | 9h07 | 68 | 205 | 4564 | 8 | 10 | real-time budget |
| Ranger/Dwarf | Stormcaller | 97 | 57 | 725 | 11h30 | 84 | 233 | 3210 | 1 | 10 | real-time budget |
| Cleric/Angel | Oracle | 111 | 60 | 0 | 9h52 | 65 | 180 | 3254 | 1 | 0 | real-time budget |
| Trickster/Goblin | Illusionist | 100 | 57 | 991 | 10h21 | 74 | 214 | 20.2k | 10 | 0 | real-time budget |
| Knight/Orc | Wyrmlancer | 111 | 63 | 1214 | 9h30 | 58 | 218 | 6683 | 19 | 20 | real-time budget |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h08 | 0h37 | 6h04 | not reached | not reached | not reached |
| Mage/Elf | 0h15 | 0h50 | not reached | not reached | not reached | not reached |
| Ranger/Dwarf | 0h07 | 0h33 | not reached | not reached | not reached | not reached |
| Cleric/Angel | 0h08 | 0h40 | 5h13 | not reached | not reached | not reached |
| Trickster/Goblin | 0h20 | 0h39 | 7h56 | not reached | not reached | not reached |
| Knight/Orc | 0h15 | 0h23 | 3h31 | not reached | not reached | not reached |
| **median** | 0h11 | 0h38 | 5h39 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h08 | 9 | 134 | 112 | 716 | 2115 | 114 | 18.9 | 10.7 | 0 | 1083 | 6 | 0 |
| Mage/Elf | 0h15 | 11 | 121 | 115 | 355 | 2115 | 114 | 18.4 | 4.7 | 2 | 1623 | 2 | 0 |
| Ranger/Dwarf | 0h07 | 9 | 134 | 119 | 561 | 2115 | 114 | 17.8 | 7.4 | 0 | 1298 | 6 | 0 |
| Cleric/Angel | 0h08 | 9 | 154 | 122 | 785 | 2115 | 114 | 17.3 | 10.8 | 0 | 1932 | 11 | 0 |
| Trickster/Goblin | 0h20 | 13 | 206 | 194 | 617 | 2115 | 114 | 10.9 | 9.5 | 2 | 2699 | 11 | 0 |
| Knight/Orc | 0h15 | 12 | 230 | 293 | 1092 | 2115 | 114 | 7.2 | 21.8 | 1 | 2463 | 5 | 0 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h37 | 19 | 433 | 516 | 2026 | 9747 | 414 | 18.9 | 7.8 | 3 | 3664 | 12 | 0 |
| Mage/Elf | 0h50 | 21 | 496 | 589 | 1098 | 9747 | 414 | 16.5 | 4.0 | 5 | 8520 | 16 | 0 |
| Ranger/Dwarf | 0h33 | 17 | 413 | 469 | 1394 | 9747 | 414 | 20.8 | 4.5 | 3 | 6477 | 15 | 0 |
| Cleric/Angel | 0h40 | 19 | 483 | 557 | 1704 | 9747 | 414 | 17.5 | 6.6 | 3 | 4319 | 3 | 0 |
| Trickster/Goblin | 0h39 | 18 | 495 | 475 | 1318 | 9747 | 414 | 20.5 | 5.0 | 3 | 13.8k | 13 | 0 |
| Knight/Orc | 0h23 | 16 | 407 | 470 | 1795 | 9747 | 414 | 20.7 | 6.5 | 1 | 6433 | 5 | 0 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 6h04 | 51 | 1263 | 2155 | 7572 | 92.9k | 2806 | 43.1 | 3.9 | 37 | 7793 | 7 | 0 |
| Cleric/Angel | 5h13 | 45 | 1165 | 1683 | 5940 | 92.9k | 2806 | 55.2 | 2.7 | 32 | 28.6k | 18 | 0 |
| Trickster/Goblin | 7h56 | 52 | 1194 | 1603 | 3916 | 92.9k | 2806 | 57.9 | 1.7 | 55 | 34.1k | 11 | 0 |
| Knight/Orc | 3h31 | 42 | 1400 | 1900 | 6699 | 92.9k | 2806 | 48.9 | 3.3 | 22 | 9455 | 4 | 0 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 8 | 15 | 8 | 9 | 21 | 15 | 12 |
| 26-50 | 29 | 35 | 26 | 31 | 18 | 8 | 28 |
| 51-75 | 74 | 92 | 162 | 78 | 68 | 21 | 76 |
| 76-100 | 253 | - | - | 195 | 370 | 167 | 224 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 5 | Mage/Elf, Trickster/Goblin, Knight/Orc |
| 26-50 | 32 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin |
| 51-75 | 156 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 202 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 15 | Warrior/Human, Cleric/Angel, Knight/Orc |

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 58 | 47 | 53 | 49 | 52 | 64 |
| 1h30 | 66 | 63 | 60 | 63 | 64 | 83 |
| 2h20 | 84 | 73 | 70 | 77 | 75 | 88 |
| 3h10 | 84 | 82 | 73 | 82 | 79 | 94 |
| 4h00 | 90 | 82 | 76 | 91 | 80 | 106 |
| 4h50 | 95 | 82 | 88 | 97 | 80 | 106 |
| 5h40 | 97 | 85 | 88 | 100 | 85 | 106 |
| 6h30 | 100 | 85 | 88 | 100 | 89 | 106 |
| 7h20 | 100 | 91 | 88 | 100 | 90 | 106 |
| 8h10 | 100 | 91 | 90 | 111 | 100 | 111 |
| 9h00 | 109 | 91 | 90 | 111 | 100 | 111 |
| 9h50 | 109 | - | 90 | 111 | 100 | - |
| 10h40 | - | - | 90 | - | - | - |
| 11h30 | - | - | 97 | - | - | - |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 20 | 18 | 18 | 19 | 18 | 22 |
| 1h30 | 28 | 27 | 25 | 26 | 25 | 29 |
| 2h20 | 33 | 32 | 29 | 31 | 31 | 34 |
| 3h10 | 38 | 37 | 33 | 36 | 35 | 40 |
| 4h00 | 43 | 41 | 37 | 40 | 39 | 44 |
| 4h50 | 46 | 44 | 39 | 44 | 42 | 48 |
| 5h40 | 49 | 47 | 42 | 47 | 45 | 52 |
| 6h30 | 53 | 49 | 45 | 50 | 47 | 55 |
| 7h20 | 56 | 52 | 47 | 52 | 50 | 57 |
| 8h10 | 58 | 54 | 49 | 55 | 52 | 59 |
| 9h00 | 61 | 57 | 51 | 57 | 54 | 62 |
| 9h50 | 63 | - | 53 | 60 | 56 | - |
| 10h40 | - | - | 55 | - | - | - |
| 11h30 | - | - | 57 | - | - | - |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 433 | 255 | 278 | 483 | 604 | 593 |
| 1h30 | 361 | 518 | 685 | 531 | 332 | 1042 |
| 2h20 | 12 | 783 | 393 | 616 | 533 | 953 |
| 3h10 | 618 | 557 | 577 | 848 | 380 | 692 |
| 4h00 | 1037 | 601 | 859 | 635 | 708 | 12 |
| 4h50 | 275 | 455 | 492 | 13 | 427 | 1136 |
| 5h40 | 505 | 637 | 467 | 1091 | 363 | 1076 |
| 6h30 | 600 | 715 | 1029 | 1026 | 742 | 551 |
| 7h20 | 390 | 458 | 846 | 902 | 416 | 1381 |
| 8h10 | 494 | 680 | 999 | 0 | 421 | 735 |
| 9h00 | 1231 | 608 | 547 | 400 | 884 | 378 |
| 9h50 | 566 | - | 26 | 0 | 1012 | - |
| 10h40 | - | - | 16 | - | - | - |
| 11h30 | - | - | 0 | - | - | - |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 6368 | 2481 | 1468 | 4319 | 10.8k | 10.9k |
| 1h30 | 7766 | 6883 | 4353 | 7041 | 2479 | 9254 |
| 2h20 | 447 | 1210 | 2355 | 4539 | 16.0k | 8004 |
| 3h10 | 5808 | 2350 | 3712 | 13.0k | 5855 | 12.4k |
| 4h00 | 9998 | 3499 | 23.3k | 13.6k | 8327 | 140 |
| 4h50 | 5613 | 5670 | 3033 | 515 | 3498 | 16.8k |
| 5h40 | 8912 | 5923 | 4559 | 22.6k | 10.7k | 9633 |
| 6h30 | 4905 | 14.8k | 9018 | 13.7k | 11.9k | 7324 |
| 7h20 | 7275 | 7704 | 18.9k | 2813 | 7719 | 6670 |
| 8h10 | 4748 | 5419 | 32.0k | 1699 | 11.0k | 6360 |
| 9h00 | 13.2k | 5278 | 1520 | 8407 | 6441 | 2386 |
| 9h50 | 14.2k | - | 1070 | 1003 | 29.9k | - |
| 10h40 | - | - | 8351 | - | - | - |
| 11h30 | - | - | 3856 | - | - | - |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 12 | 5 | 5 | 3 | 17 | 7 |
| 1h30 | 0 | 0 | 15 | 5 | 4 | 2 |
| 2h20 | 0 | 9 | 0 | 4 | 8 | 15 |
| 3h10 | 2 | 4 | 5 | 3 | 9 | 1 |
| 4h00 | 13 | 1 | 1 | 0 | 7 | 4 |
| 4h50 | 2 | 3 | 0 | 3 | 2 | 12 |
| 5h40 | 1 | 3 | 4 | 0 | 6 | 2 |
| 6h30 | 0 | 14 | 15 | 12 | 3 | 7 |
| 7h20 | 3 | 6 | 14 | 12 | 2 | 11 |
| 8h10 | 2 | 4 | 2 | 9 | 7 | 3 |
| 9h00 | 10 | 8 | 6 | 3 | 7 | 2 |
| 9h50 | 0 | - | 1 | 1 | 3 | - |
| 10h40 | - | - | 0 | - | - | - |
| 11h30 | - | - | 4 | - | - | - |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1h30 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2h20 | 0 | 0 | 0 | 0 | 0 | 0 |
| 3h10 | 0 | 0 | 0 | 0 | 0 | 0 |
| 4h00 | 0 | 0 | 0 | 0 | 0 | 0 |
| 4h50 | 0 | 0 | 0 | 0 | 0 | 0 |
| 5h40 | 0 | 0 | 0 | 0 | 0 | 0 |
| 6h30 | 0 | 0 | 0 | 0 | 0 | 20 |
| 7h20 | 0 | 10 | 0 | 0 | 0 | 20 |
| 8h10 | 0 | 10 | 0 | 0 | 0 | 20 |
| 9h00 | 0 | 10 | 0 | 0 | 0 | 20 |
| 9h50 | 0 | - | 0 | 0 | 0 | - |
| 10h40 | - | - | 0 | - | - | - |
| 11h30 | - | - | 10 | - | - | - |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 3 | 5 | 5 | 3 | 3 | 3 |
| 1h30 | 9 | 10 | 9 | 10 | 12 | 9 |
| 2h20 | 16 | 15 | 17 | 15 | 16 | 15 |
| 3h10 | 21 | 21 | 22 | 20 | 22 | 21 |
| 4h00 | 25 | 27 | 26 | 26 | 28 | 28 |
| 4h50 | 31 | 33 | 33 | 32 | 34 | 31 |
| 5h40 | 36 | 39 | 38 | 35 | 40 | 36 |
| 6h30 | 40 | 45 | 43 | 41 | 46 | 41 |
| 7h20 | 44 | 53 | 50 | 47 | 52 | 45 |
| 8h10 | 49 | 60 | 56 | 53 | 58 | 51 |
| 9h00 | 53 | 67 | 64 | 59 | 64 | 57 |
| 9h50 | 58 | - | 71 | 65 | 70 | - |
| 10h40 | - | - | 77 | - | - | - |
| 11h30 | - | - | 84 | - | - | - |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 524 | 47 | 262 | 552 | 580 | 772 |
| 1h30 | 439 | 1074 | 774 | 479 | 330 | 1037 |
| 2h20 | 196 | 1119 | 385 | 487 | 459 | 1349 |
| 3h10 | 910 | 1683 | 748 | 1229 | 184 | 1499 |
| 4h00 | 1797 | 1747 | 1163 | 1054 | 1091 | 305 |
| 4h50 | 414 | 702 | 565 | 204 | 626 | 1461 |
| 5h40 | 751 | 1897 | 754 | 1403 | 628 | 1294 |
| 6h30 | 986 | 1457 | 1487 | 1899 | 1500 | 1200 |
| 7h20 | 650 | 861 | 1375 | 1927 | 526 | 2020 |
| 8h10 | 1391 | 1899 | 1437 | 282 | 254 | 1198 |
| 9h00 | 2694 | 1024 | 253 | 724 | 1758 | 781 |
| 9h50 | 1125 | - | 289 | 272 | 1798 | - |
| 10h40 | - | - | 306 | - | - | - |
| 11h30 | - | - | 298 | - | - | - |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 2068 | 461 | 701 | 1688 | 1630 | 2064 |
| 1h30 | 2350 | 1121 | 2205 | 2354 | 607 | 4363 |
| 2h20 | 1246 | 2129 | 1696 | 3450 | 1648 | 3692 |
| 3h10 | 3815 | 1360 | 1723 | 3967 | 1337 | 3480 |
| 4h00 | 5991 | 1382 | 3124 | 3222 | 1959 | 1680 |
| 4h50 | 3294 | 1432 | 1950 | 1248 | 1376 | 5510 |
| 5h40 | 4462 | 1956 | 2007 | 5293 | 1100 | 6330 |
| 6h30 | 5345 | 1955 | 4212 | 5423 | 2042 | 4112 |
| 7h20 | 3810 | 1165 | 3138 | 4988 | 1069 | 7483 |
| 8h10 | 3967 | 1832 | 4584 | 1784 | 1438 | 5504 |
| 9h00 | 9299 | 2331 | 1474 | 2461 | 2279 | 3528 |
| 9h50 | 5986 | - | 834 | 2066 | 3157 | - |
| 10h40 | - | - | 779 | - | - | - |
| 11h30 | - | - | 791 | - | - | - |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h40 | 7.1 | 4.9 | 9.1 | 5.3 | 7.3 | 6.0 |
| 1h30 | 6.0 | 6.1 | 7.9 | 8.0 | 6.3 | 6.7 |
| 2h20 | 6.0 | 5.8 | 6.3 | 6.9 | 5.5 | 7.5 |
| 3h10 | 6.7 | 7.4 | 7.8 | 5.7 | 7.1 | 6.1 |
| 4h00 | 6.5 | 5.9 | 7.2 | 5.8 | 4.4 | 6.9 |
| 4h50 | 6.4 | 5.1 | 7.4 | 9.1 | 5.7 | 5.0 |
| 5h40 | 7.8 | 4.6 | 7.0 | 5.8 | 6.7 | 6.2 |
| 6h30 | 7.1 | 5.9 | 7.0 | 5.8 | 5.7 | 6.9 |
| 7h20 | 6.3 | 4.7 | 7.9 | 5.3 | 6.9 | 6.2 |
| 8h10 | 6.1 | 4.7 | 6.8 | 6.9 | 6.8 | 5.3 |
| 9h00 | 5.7 | 5.4 | 6.7 | 5.9 | 5.4 | 6.8 |
| 9h50 | 7.6 | - | 7.5 | 6.0 | 5.4 | - |
| 10h40 | - | - | 8.2 | - | - | - |
| 11h30 | - | - | 6.8 | - | - | - |

## Problems seen while simulating

- Warrior/Human ran out of real-time budget at 10h22 of play (floor 109); later milestones are unknown, not failed.
- Mage/Elf ran out of real-time budget at 9h07 of play (floor 91); later milestones are unknown, not failed.
- Ranger/Dwarf ran out of real-time budget at 11h30 of play (floor 97); later milestones are unknown, not failed.
- Cleric/Angel ran out of real-time budget at 9h52 of play (floor 111); later milestones are unknown, not failed.
- Trickster/Goblin ran out of real-time budget at 10h21 of play (floor 100); later milestones are unknown, not failed.
- Knight/Orc ran out of real-time budget at 9h30 of play (floor 111); later milestones are unknown, not failed.
- Nothing got stuck.
