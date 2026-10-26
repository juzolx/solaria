# Balance report (headless simulator)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 6 hours of play each (played 6.0 hours to 6.0 hours).
- Gear: 8 slots. Ring and Necklace are about half a slot each (a ring is 15% of a weapon's Attack, a necklace 25% of a helmet's HP, plus a small charm from Uncommon up).
- Floor 100: median time 3.3 hours (5 of 6 heroes got there, fastest 1.5 hours, slowest 3.9 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 119 (lowest 99, highest 158). Floors beyond that need more play time than was simulated.
- Deaths: median 34 per hero (187 in total, 5.19 per hour of play).
- Pace: the first 100 floors take about 31 minutes per 25 floors. The slowest stretch is floors 76-100 at about 126 minutes (4.0 times the early pace).
- Defense: at every milestone the median hero survives 4 or more hits.
- Offense: from floor 50 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 128 deaths in 18.8 hours there (6.82 per hour).
- Of all deaths, 9 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Crusader | 104 | 49 | 979 | +0.1 | 6h00 | 34 | 108 | 0 | 14.8k | 3 | 67 | full time |
| Mage/Elf | Lightbinder | 130 | 56 | 919 | +0.1 | 6h00 | 35 | 127 | 0 | 10.5k | 16 | 28 | full time |
| Ranger/Dwarf | Deadeye | 111 | 49 | 1598 | +1.4 | 6h00 | 35 | 121 | 0 | 27.1k | 47 | 20 | full time |
| Cleric/Angel | Grove Keeper | 158 | 47 | 2899 | +3.4 | 6h00 | 18 | 80 | 1 | 268.9k | 145 | 30 | full time |
| Trickster/Goblin | Shadowdancer | 99 | 50 | 807 | +0.1 | 6h00 | 31 | 113 | 1 | 14.0k | 26 | 34 | full time |
| Knight/Orc | Dragoon | 128 | 48 | 960 | +0.5 | 6h00 | 34 | 122 | 0 | 30.3k | 29 | 38 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h10 | 0h19 | 3h07 | not reached | not reached | not reached |
| Mage/Elf | 0h13 | 0h33 | 3h30 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h08 | 0h16 | 3h18 | not reached | not reached | not reached |
| Cleric/Angel | 0h10 | 0h30 | 1h27 | not reached | not reached | not reached |
| Trickster/Goblin | 0h11 | 0h31 | not reached | not reached | not reached | not reached |
| Knight/Orc | 0h09 | 0h17 | 3h51 | not reached | not reached | not reached |
| **median** | 0h10 | 0h25 | 3h18 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h10 | 12 | 235 | 268 | 1201 | 2217 | 120 | 8.3 | 17.4 | 0 | 5161 | 1 | 15 |
| Mage/Elf | 0h13 | 12 | 163 | 194 | 558 | 2217 | 120 | 11.4 | 8.0 | 1 | 4069 | 21 | 14 |
| Ranger/Dwarf | 0h08 | 11 | 150 | 215 | 675 | 2217 | 120 | 10.3 | 9.2 | 0 | 3945 | 2 | 7 |
| Cleric/Angel | 0h10 | 11 | 159 | 188 | 742 | 2217 | 120 | 11.8 | 10.5 | 0 | 2845 | 12 | 20 |
| Trickster/Goblin | 0h11 | 11 | 164 | 144 | 486 | 2217 | 120 | 15.4 | 6.8 | 0 | 3561 | 3 | 21 |
| Knight/Orc | 0h09 | 12 | 211 | 275 | 1064 | 2217 | 120 | 8.1 | 18.3 | 0 | 4948 | 21 | 16 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h19 | 17 | 436 | 495 | 2313 | 12.7k | 514 | 25.7 | 7.0 | 0 | 10.2k | 13 | 5 |
| Mage/Elf | 0h33 | 21 | 692 | 819 | 2164 | 12.7k | 514 | 15.5 | 6.9 | 2 | 12.6k | 33 | 26 |
| Ranger/Dwarf | 0h16 | 15 | 307 | 593 | 1159 | 12.7k | 514 | 21.4 | 2.9 | 0 | 8087 | 19 | 7 |
| Cleric/Angel | 0h30 | 18 | 354 | 471 | 1879 | 12.7k | 514 | 27.0 | 5.0 | 2 | 11.1k | 24 | 23 |
| Trickster/Goblin | 0h31 | 18 | 398 | 543 | 1168 | 12.7k | 514 | 23.4 | 3.0 | 2 | 11.8k | 0 | 25 |
| Knight/Orc | 0h17 | 16 | 354 | 523 | 2021 | 12.7k | 514 | 24.3 | 5.6 | 0 | 10.9k | 16 | 6 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 3h07 | 39 | 1510 | 1605 | 10.0k | 385.3k | 1887 | 240.1 | 9.4 | 14 | 34.5k | 59 | 2 |
| Mage/Elf | 3h30 | 45 | 1561 | 1805 | 5354 | 385.3k | 1887 | 213.5 | 4.2 | 19 | 34.4k | 98 | 39 |
| Ranger/Dwarf | 3h18 | 39 | 1607 | 2097 | 6643 | 385.3k | 1887 | 183.7 | 5.7 | 18 | 57.3k | 190 | 29 |
| Cleric/Angel | 1h27 | 28 | 1450 | 1673 | 6780 | 385.3k | 1887 | 230.3 | 5.0 | 5 | 63.7k | 22 | 7 |
| Knight/Orc | 3h51 | 41 | 2052 | 2500 | 9601 | 385.3k | 1887 | 154.1 | 9.1 | 22 | 80.5k | 73 | 8 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 11 | 14 | 9 | 11 | 11 | 9 | 11 |
| 26-50 | 9 | 20 | 7 | 20 | 20 | 8 | 14 |
| 51-75 | 49 | 39 | 56 | 40 | 87 | 47 | 48 |
| 76-100 | 119 | 138 | 126 | 17 | - | 167 | 126 |
| 101-125 | - | 102 | - | 123 | - | 88 | 102 |
| 126-150 | - | - | - | 95 | - | - | 95 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 7 | Warrior/Human, Mage/Elf, Knight/Orc |
| 26-50 | 18 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 51-75 | 47 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 81 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 23 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Knight/Orc |
| 126-150 | 9 | Mage/Elf, Cleric/Angel, Knight/Orc |
| 151-175 | 2 | Cleric/Angel |

## How heroes fall

- 187 deaths: 1 with 2 or fewer gear pieces worn (re-gearing after a fall), 29 to bosses, 135 to monsters with modifiers.
- Fight length at death: median 9 turns. Monster HP left when the hero fell: median 40%.
- Elite rooms: 619 entered, 13 deaths there (6% of all deaths, 2.1% of elite rooms).
- Worn gear upgrade level on reaching floor 100: median +2.5.
- Killer's tier: Uncommon 19, Epic 72, Legendary 22, Rare 17, Common 52, Mythic 5.
- Biggest damage source in the fatal fight: hits 187.
- Killer's modifiers: Shielded 16, Armored 14, Elemental 11, Giant 14, Swift 36, Explosive 9, Regenerating 21, Enraged 29, Teleporting 17, Frigid 15, Vampiric 9, Burning 15, Thorny 17, Venomous 16.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 50 | 44 | 63 | 34 | 37 | 58 |
| 0h50 | 70 | 70 | 70 | 64 | 50 | 73 |
| 1h20 | 84 | 89 | 89 | 89 | 62 | 77 |
| 1h50 | 90 | 99 | 93 | 100 | 72 | 78 |
| 2h20 | 90 | 99 | 93 | 100 | 87 | 93 |
| 2h50 | 95 | 99 | 98 | 108 | 87 | 98 |
| 3h20 | 100 | 99 | 101 | 116 | 87 | 98 |
| 3h50 | 100 | 100 | 111 | 140 | 99 | 98 |
| 4h20 | 100 | 100 | 111 | 140 | 99 | 110 |
| 4h50 | 100 | 106 | 111 | 140 | 99 | 119 |
| 5h20 | 104 | 129 | 111 | 158 | 99 | 126 |
| 5h50 | 104 | 130 | 111 | 158 | 99 | 128 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 17 | 16 | 17 | 15 | 14 | 18 |
| 0h50 | 23 | 25 | 23 | 23 | 22 | 25 |
| 1h20 | 28 | 30 | 28 | 28 | 27 | 30 |
| 1h50 | 32 | 33 | 31 | 31 | 32 | 33 |
| 2h20 | 35 | 37 | 34 | 34 | 35 | 36 |
| 2h50 | 38 | 40 | 37 | 37 | 38 | 37 |
| 3h20 | 40 | 44 | 39 | 39 | 40 | 39 |
| 3h50 | 42 | 46 | 41 | 40 | 42 | 41 |
| 4h20 | 43 | 48 | 43 | 42 | 45 | 43 |
| 4h50 | 45 | 51 | 45 | 44 | 47 | 45 |
| 5h20 | 47 | 53 | 47 | 45 | 48 | 46 |
| 5h50 | 48 | 55 | 49 | 46 | 50 | 48 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 436 | 329 | 444 | 243 | 196 | 450 |
| 0h50 | 414 | 809 | 626 | 354 | 475 | 579 |
| 1h20 | 586 | 579 | 515 | 1130 | 397 | 980 |
| 1h50 | 559 | 552 | 499 | 1500 | 1020 | 1085 |
| 2h20 | 1341 | 552 | 22 | 1412 | 944 | 1154 |
| 2h50 | 1307 | 841 | 550 | 1214 | 781 | 1063 |
| 3h20 | 909 | 901 | 1728 | 1954 | 731 | 1469 |
| 3h50 | 1202 | 987 | 899 | 1524 | 622 | 1981 |
| 4h20 | 1760 | 1018 | 645 | 1294 | 897 | 1745 |
| 4h50 | 1962 | 1275 | 1630 | 2340 | 1320 | 1245 |
| 5h20 | 2146 | 722 | 669 | 2841 | 1036 | 1987 |
| 5h50 | 1225 | 1240 | 665 | 2811 | 601 | 735 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 11.3k | 9190 | 2373 | 3816 | 611 | 12.1k |
| 0h50 | 5273 | 15.6k | 9394 | 3209 | 15.9k | 12.5k |
| 1h20 | 8711 | 6982 | 11.3k | 77.6k | 18.7k | 26.1k |
| 1h50 | 11.7k | 12.6k | 11.6k | 48.8k | 20.1k | 27.6k |
| 2h20 | 30.4k | 4202 | 153 | 70.1k | 17.7k | 30.3k |
| 2h50 | 18.7k | 19.5k | 11.0k | 26.3k | 7155 | 17.3k |
| 3h20 | 30.2k | 25.4k | 38.4k | 144.1k | 14.4k | 20.3k |
| 3h50 | 16.9k | 8581 | 16.6k | 165.3k | 16.4k | 75.1k |
| 4h20 | 17.2k | 17.1k | 10.3k | 74.8k | 18.5k | 31.9k |
| 4h50 | 46.7k | 17.5k | 28.2k | 209.7k | 52.1k | 26.5k |
| 5h20 | 118.5k | 24.8k | 7774 | 401.9k | 19.0k | 56.5k |
| 5h50 | 18.2k | 30.7k | 15.6k | 183.2k | 15.6k | 8088 |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 13 | 5 | 0 | 33 | 2 | 11 |
| 0h50 | 6 | 7 | 3 | 3 | 32 | 34 |
| 1h20 | 0 | 8 | 1 | 8 | 20 | 16 |
| 1h50 | 2 | 9 | 44 | 41 | 4 | 64 |
| 2h20 | 39 | 3 | 8 | 99 | 14 | 5 |
| 2h50 | 59 | 3 | 92 | 6 | 6 | 7 |
| 3h20 | 27 | 0 | 34 | 28 | 4 | 54 |
| 3h50 | 18 | 3 | 33 | 10 | 7 | 97 |
| 4h20 | 15 | 6 | 66 | 111 | 3 | 64 |
| 4h50 | 59 | 8 | 59 | 121 | 30 | 0 |
| 5h20 | 74 | 36 | 0 | 2 | 14 | 14 |
| 5h50 | 7 | 50 | 91 | 61 | 2 | 15 |

### Average upgrade level of worn gear

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0.6 | 0.3 | 0.1 | 0.5 | 0.1 | 0.5 |
| 0h50 | 0.1 | 0.4 | 0.0 | 0.3 | 0.3 | 0.0 |
| 1h20 | 0.3 | 0.1 | 0.3 | 2.0 | 0.3 | 0.8 |
| 1h50 | 0.3 | 0.4 | 0.0 | 2.3 | 1.6 | 1.4 |
| 2h20 | 1.5 | 0.4 | 0.6 | 1.4 | 0.3 | 0.6 |
| 2h50 | 1.4 | 0.3 | 0.0 | 0.6 | 0.0 | 0.4 |
| 3h20 | 0.3 | 0.0 | 3.1 | 2.9 | 0.4 | 2.5 |
| 3h50 | 0.9 | 0.1 | 0.4 | 0.0 | 0.0 | 4.0 |
| 4h20 | 2.3 | 0.1 | 0.4 | 0.4 | 0.3 | 1.9 |
| 4h50 | 3.6 | 0.9 | 1.8 | 2.4 | 2.0 | 1.3 |
| 5h20 | 4.9 | 0.0 | 0.3 | 3.8 | 0.3 | 2.5 |
| 5h50 | 0.3 | 0.1 | 0.0 | 3.0 | 0.0 | 0.3 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 10 | 12 | 3 | 14 | 6 | 7 |
| 0h50 | 8 | 11 | 30 | 40 | 36 | 7 |
| 1h20 | 14 | 10 | 12 | 21 | 31 | 17 |
| 1h50 | 10 | 32 | 19 | 29 | 45 | 44 |
| 2h20 | 60 | 46 | 21 | 50 | 30 | 39 |
| 2h50 | 45 | 53 | 42 | 11 | 20 | 30 |
| 3h20 | 37 | 22 | 44 | 13 | 81 | 14 |
| 3h50 | 58 | 6 | 28 | 51 | 7 | 74 |
| 4h20 | 22 | 12 | 56 | 41 | 77 | 49 |
| 4h50 | 89 | 18 | 18 | 54 | 32 | 24 |
| 5h20 | 73 | 70 | 13 | 21 | 25 | 67 |
| 5h50 | 51 | 15 | 62 | 13 | 89 | 14 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0 | 1 | 1 | 2 | 2 | 0 |
| 0h50 | 4 | 4 | 5 | 5 | 4 | 3 |
| 1h20 | 7 | 7 | 8 | 5 | 7 | 6 |
| 1h50 | 9 | 9 | 11 | 7 | 10 | 9 |
| 2h20 | 11 | 14 | 15 | 9 | 13 | 12 |
| 2h50 | 14 | 16 | 17 | 12 | 16 | 17 |
| 3h20 | 16 | 19 | 18 | 12 | 19 | 21 |
| 3h50 | 20 | 22 | 22 | 13 | 21 | 22 |
| 4h20 | 25 | 24 | 25 | 15 | 23 | 25 |
| 4h50 | 27 | 28 | 27 | 15 | 25 | 28 |
| 5h20 | 30 | 31 | 31 | 15 | 28 | 28 |
| 5h50 | 32 | 34 | 35 | 18 | 30 | 34 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 495 | 518 | 724 | 421 | 223 | 636 |
| 0h50 | 470 | 913 | 853 | 421 | 641 | 964 |
| 1h20 | 424 | 584 | 585 | 1170 | 436 | 1304 |
| 1h50 | 570 | 602 | 559 | 1617 | 1244 | 1446 |
| 2h20 | 1359 | 620 | 180 | 1587 | 1228 | 1487 |
| 2h50 | 1392 | 1136 | 852 | 1695 | 1416 | 1804 |
| 3h20 | 1357 | 1408 | 2111 | 2021 | 1506 | 2163 |
| 3h50 | 1669 | 1660 | 1715 | 1429 | 686 | 2479 |
| 4h20 | 1487 | 1538 | 1021 | 1937 | 882 | 2333 |
| 4h50 | 2009 | 1452 | 2517 | 2654 | 1849 | 2305 |
| 5h20 | 2216 | 853 | 890 | 3005 | 1744 | 3111 |
| 5h50 | 1631 | 1974 | 1066 | 3123 | 665 | 1499 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2314 | 1051 | 1398 | 1080 | 636 | 2266 |
| 0h50 | 2473 | 2908 | 2829 | 1803 | 1579 | 2431 |
| 1h20 | 4171 | 1834 | 2062 | 5330 | 1087 | 5258 |
| 1h50 | 4288 | 1892 | 2126 | 7089 | 3053 | 5732 |
| 2h20 | 8538 | 1976 | 566 | 7154 | 3676 | 6482 |
| 2h50 | 8772 | 2351 | 2337 | 8399 | 2661 | 6195 |
| 3h20 | 5648 | 3433 | 7214 | 11.4k | 2041 | 7289 |
| 3h50 | 9314 | 4509 | 3694 | 9296 | 1848 | 9291 |
| 4h20 | 11.6k | 3291 | 2831 | 8318 | 2840 | 9362 |
| 4h50 | 12.7k | 5397 | 7217 | 14.0k | 4973 | 8789 |
| 5h20 | 14.7k | 2736 | 2926 | 16.0k | 4322 | 10.6k |
| 5h50 | 10.6k | 6054 | 2877 | 17.6k | 2074 | 5088 |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 8.0 | 6.7 | 8.1 | 7.0 | 8.6 | 6.5 |
| 0h50 | 9.7 | 7.2 | 11.3 | 7.1 | 7.0 | 7.6 |
| 1h20 | 9.7 | 6.5 | 12.2 | 13.0 | 9.7 | 5.2 |
| 1h50 | 12.8 | 9.1 | 10.0 | 8.2 | 5.6 | 7.5 |
| 2h20 | 8.0 | 5.6 | 11.8 | 12.0 | 5.1 | 5.2 |
| 2h50 | 4.3 | 6.3 | 7.6 | 5.3 | 5.9 | 5.7 |
| 3h20 | 7.0 | 6.4 | 12.5 | 25.0 | 5.8 | 7.2 |
| 3h50 | 4.8 | 6.3 | 10.0 | 27.3 | 11.3 | 11.3 |
| 4h20 | 5.8 | 6.4 | 12.5 | 8.7 | 11.5 | 7.7 |
| 4h50 | 13.0 | 5.8 | 7.0 | 16.7 | 5.8 | 6.4 |
| 5h20 | 7.7 | 6.5 | 10.3 | 30.0 | 7.0 | 11.1 |
| 5h50 | 9.8 | 5.8 | 10.2 | 14.3 | 8.8 | 7.1 |

## Problems seen while simulating

- Nothing got stuck.
