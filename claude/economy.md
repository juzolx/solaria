# Solaria 2.1 economy sheet: gold, scrap, dust

Owner decision D3 (a), Oct 2026: the game has exactly **three currencies**.
Every number lives in `economy.gd` (new in 2.1) or the file named in the row.
"f" = the floor you are on, "best" = your best floor, "L" = item upgrade level,
"r" = rarity (0 Common, 1 Uncommon, 2 Rare, 3 Epic, 4 Legendary).

| Currency | Feels like | Where it shows |
|---|---|---|
| Gold | money: buys things in town | top bar (Risk/Bank in the dungeon), shop, smith, wheel |
| Scrap | metal: fixes and improves gear | top bar, Smith > Forge, bag item buttons |
| Dust | magic: skills, sets, the last upgrades | top bar, Smith chips, Skills tab, bag item buttons |

## What happened to the old materials

2.0 had ten zone materials (Grendel's Claw, Grave Silk, Charybdis Pearl, Surtr's Ember,
Typhon Scale, Ghostwood Sap, Fae Dust, Runesteel Ingot, Seraph Feather, Abyssal Ember),
one per zone and realm. They are gone (no field in the save, no constants).

| Old source (materials) | 2.1 pays | Why |
|---|---|---|
| Boss kill: 5-8 | 5-8 dust | magic, rare |
| Rare / Epic / Legendary monster: 1-2, Mythic: 2 | same in dust (`Monsters.TIERS[].dust`) | magic, rare |
| Milestone Champion chest: 2-3 | 2-3 dust | rare |
| Rift vault: 3 per rift floor | 3 dust per rift floor | rare |
| Salvage Epic: 1, Legendary: 2 | 1 / 2 dust (plus their normal scrap) | magic gear |
| Treasure goblin: 1-2 | 8-12 scrap (`MAT_TO_SCRAP` 4 x 2-3; R5) | plain chest |
| Horde chest: 1-2 | 8-12 scrap | plain chest |
| Daily bounty: 2, weekly: 6 | 2 / 6 dust | reward |
| Achievements: 3 or 5 | 3 or 5 dust | reward |
| Login day 5: 3 materials | 3 dust | reward |
| Mystery Box: 4 | 4 dust | reward |
| Weekly raid: 2 of each zone reached | 2 dust per zone reached | reward |
| Old mail letter holding "mats" | paid as dust (no crash) | 2.0 leftovers |

| Old cost (materials) | 2.1 cost |
|---|---|
| Set piece: 10 of its zone's material + 40 scrap | **10 + 5 x zone dust** + 40 scrap; you must have reached the set's zone. First set 10 dust, fifth 30, last realm set 55 |
| Crafted bag: 5 + L/4 of any material + 30 + 10L scrap | scrap only: 30 + 10L + 4 x (5 + L/4). Level 0: 50, level 10: 138, level 19: 254 |

Ability stones are not a currency (they are skill drops) and stay as they are.
The Wheel (gold fee, no money for spins beyond its fee) and the premium/cosmetic
rules are untouched.

## Gold

### Sources

| Source | Formula | f 1-50 (25) | f 51-100 (75) | f 101-250 (175) | f 251-500 (375) | f 501-1000 (750) |
|---|---|---|---|---|---|---|
| Common kill | (2 + f), x tier gold (Uncommon 1.6 ... Mythic 12), x gold find | 27 | 77 | 177 | 377 | 752 |
| Boss kill | (2 + f) x 10 | 270 | 770 | 1,770 | 3,770 | 7,520 |
| Treasure goblin | (2 + f) x 25 | 675 | 1,925 | 4,425 | 9,425 | 18,800 |
| Horde chest | (5 + 6f) x 4 | 620 | 1,820 | 4,220 | 9,020 | 18,020 |
| Champion chest | (10 + 8f) x 4 | 840 | 2,440 | 5,640 | 12,040 | 24,040 |
| Rift vault (per rift floor) | (10 + 8f) x 6 | 1,260 | 3,660 | 8,460 | 18,060 | 36,060 |
| Selling an Epic (L0) | 8 x (2 + 0.5 x item floor), + Charisma | 116 | 316 | 716 | 1,516 | 3,016 |
| Bounty / deed gold | base x (1 + best/25) (daily base 300, weekly 1,500) | 600 / 3,000 | 1,200 / 6,000 | 2,400 / 12,000 | 4,800 / 24,000 | 9,300 / 46,500 |
| Benched heroes | 8% of each kill's base gold per hero, by class | small | small | small | small | small |
| Wheel clean sweep | fees back x wheels | - | - | - | - | - |

### Sinks

| Sink | Formula | best 25 | best 75 | best 175 | best 375 | best 750 |
|---|---|---|---|---|---|---|
| **Shop restock (2.1: scales)** | 30 + 10 x best (was a flat 30) | 280 | 780 | 1,780 | 3,780 | 7,530 |
| Shop Epic piece | sell value x 4 | 464 | 1,264 | 2,864 | 6,064 | 12,064 |
| Featured deal | shop price x 3 | ~1,400 | ~3,800 | ~8,600 | ~18,200 | ~36,200 |
| Smith's wares (Epic/Legendary) | shop price x 1.4 | ~650 | ~1,770 | ~4,000 | ~8,500 | ~16,900 |
| New bounty postings | 150 x (1 + best/25) | 300 | 600 | 1,200 | 2,400 | 4,650 |
| Potion / Greater potion | 25 / 90 | 25 / 90 | same | same | same | same |
| Elixirs | 100-120 | flat | flat | flat | flat | flat |
| Bigger bag (shop) | 10 x 1.5^level (20 levels) | 10 ... 33k | | | | |
| Inn rest | 4 x hero level (free under 6) | ~80 | ~160 | ~250 | ~350 | ~450 |
| Looks shop | 25 x price x (1 + best/20) | grows with depth | | | | |
| Wheel fee | item sell value x fee | per spin | | | | |
| Travelers (map, fortune, gifts) | price x (2 + f) | 135-810 | | | | |

All gold prices go through `price()`: Charisma discount and town events apply.
The restock was nearly free (30 gold against 5-30k gold in the bank at floor 100 in
the balance sim); at 1,030 gold at best floor 100 it is now a real choice.

## Scrap

### Sources

| Source | Amount |
|---|---|
| Salvage | Common 1, Uncommon 2, Rare 4, Epic 8, Legendary 16, Unique 40, Set 20, Signature 80; +2 per upgrade level; x Dwarf / forge-heat bonus |
| Auto-salvage and bag overflow | same values |
| Plain chests (goblin, horde) | 8-12 (was 1-2 materials; 4-8 before the R5 balance pass) |
| Benched heroes | 10% per hero per kill, 1 + zone each, by class |
| Rewards (deeds, login day 3) | base x (1 + best/50) (login 40: 60 at best 25, 640 at best 750) |
| Traveler "hone" refund | gives the price back if it can't help |

### Sinks

| Sink | Formula | Examples |
|---|---|---|
| Upgrade to L+1 | 5 x (L + 1) x (min(r, 4) + 1) | Epic +1: 20, Epic +10: 200, whole Epic 0 to 10: 1,100 |
| Reroll try | 10 x (r + 1) | Common 10, Rare 30, Epic 40 |
| Potion | 5 | |
| Mystery gear | 20 | |
| Set piece | 40 (+ dust) | |
| Crafted bag | 30 + 10L + 4 x (5 + L/4) | 50 / 138 / 254 |
| Traveler hone | 4 x (1 + zone) | |

Scrap stays tight (the sim ends most checkpoints with under 20): it is the gear
currency and every bit goes into upgrades.

## Dust

Before 2.1 dust only came from stones of maxed skills, so the sim heroes had 0-20 dust
after 10 hours and never spent any. Now the old material sources feed it, and it has
sinks all game long.

### Sources

| Source | Amount | Per 50-floor band (first pass) |
|---|---|---|
| Boss | 5-8 | 2 bosses: ~13; re-fights by travel pay again (15-30 s rest) |
| Rare / Epic / Legendary monster | 1-2 | ~15% of spawns are Rare or better: ~0.2 dust per kill on average |
| Mythic monster | 2 | 1 in 200 |
| Champion (every 10th floor of a zone) | 2-3 | 5 champions: ~12 |
| Rift vault | 3 per rift floor | per rift |
| Salvage Epic / Legendary | 1 / 2 | depends on loot habits |
| Stone of a maxed skill | 10 / 25 / 60 by skill rarity | late game |
| Selling a skill | half its craft cost | |
| Daily / weekly bounty | 2 / 6 | |
| Achievements | 3 or 5 | one time |
| Login day 5, Mystery Box | 3, 4 | |
| Weekly raid | 2 per zone reached | |

### Sinks

| Sink | Cost | Notes |
|---|---|---|
| Craft a new skill | 60 x (rarity + 1)^2: 60 / 240 / 540 | any skill in the game |
| Rank up a skill | 20 x (rarity + 1) x rank: 20-120 | to rank 5 |
| Set piece | 10 + 5 x zone (10 ... 55) + 40 scrap | 3 pieces per set |
| **Upgrade past +5 (new)** | 2 per level past +5: +6 2, +7 4, +8 6, +9 8, +10 10 | 30 dust to take one item from +5 to +10 |
| **Reroll Rare / Epic (new)** | 3 / 10 per try (plus the scrap) | Epic to Legendary is 5% a try: ~200 dust on average |

## Floor bands at a glance

| Band | Gold in | Big gold out | Scrap | Dust in | Dust out |
|---|---|---|---|---|---|
| 1-50 | ~30 a kill, 270 a boss | gear, potions, restock 40-530 | salvage commons, first upgrades | bosses + rare monsters: tens | first skill ranks, first set (10/piece) |
| 51-100 | ~80 a kill, 770 a boss | Epic shop gear 1-1.3k, restock 540-1,030 | Epic upgrades 20-200 each | ~50-100 per band | skill crafts (60-240), +6 to +10 on best items |
| 101-250 | ~180 a kill | smith wares 4k, restock ~1-2.5k | Legendary upgrades | ~100+ per band | all five base sets (10-30/piece), Rare/Epic rerolls |
| 251-500 | ~380 a kill | featured deals ~18k, restock 2.5-5k | heavy upgrade spend | realms add vaults and Champions | realm sets (35-55/piece), rank 5 skills |
| 501-1000 | ~750 a kill | restock 5-10k, looks shop | | maxed stones turn into lots of dust | Epic to Legendary rerolls, new Rare skills (540) |

Tests: `tests/stage6_currency.gd` (only three currencies in state, every old cost payable,
conversion, sinks, old saves load).
