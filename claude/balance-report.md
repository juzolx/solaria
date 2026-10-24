# Balance report (headless simulator)

## R6 balance pass (2.1 + big update, Oct 24): elite doors, scrap, curve

All runs: 6 heroes, 7 hours of play each, same seeds, `BALANCE_BUDGET=600`, 3 heroes at once. "Before" is
`wt/tune` as branched (big update in: God classes, hidden classes x1.9 by 75, portals, buildings); "after"
is the final tuning, whose full report follows below the R5 section. The sim now also counts elite rooms
and deaths in them, and the worn-gear upgrade level on reaching floor 100.

| | Before | After |
|---|---|---|
| Floor 25 / 50 median | 0h11 / 0h29 | 0h11 / 0h35 |
| Floor 100 median (range) | 3h43 (2h30-4h30, 5 of 6) | 3h32 (1h49-5h15, 6 of 6) |
| Furthest floor in 7 h (median) | 122 | 126 |
| Minutes for floors 1-25 / 26-50 / 51-75 / 76-100 / 101-125 | 11 / 18 / 72 / 127 / 164 | 11 / 21 / 39 / 142 / 132 |
| Deaths (all heroes, 42 h) | 233 (5.55 / h) | 212 (5.05 / h), -9% |
| Deaths on floors 51-100 | 160 (7.4 / h there) | 122 (7.2 / h there), -24% |
| Elite rooms entered / deaths there | 847 / 23 (9% of deaths) | 741 / 5 (2% of deaths) |
| Killer's tier Epic / Legendary / Mythic | 108 / 31 / 9 | 79 / 26 / 15 |
| Worn gear upgrade level at floor 100 (median) | +0.2 | +3.0 |
| Average upgrade at 7 h (per hero) | +0.0 to +1.2 | +0.0 to +3.3 |
| Scrap on hand at 7 h | 5-16 | 1-75 (spent, not piling up) |

Two in-between runs: the first set of changes (HP bands 3.7% / 3.4% on 51-75 / 76-100, salvage x(1 +
floor/50)) gave floor 100 at 3h08, 217 deaths, +2.6 upgrades. A third run with even more HP growth
(26-50 4.0%, 51-75 5.0%, 101-150 0.6%) gave 2h49 and 213 deaths: run-to-run noise (about +-0.5 h, and
one slow hero swings the median) is bigger than this lever, so it was reverted to the second set.

What the numbers say:
- Elite doors: the old note ("2 in 3 deaths are to Epic+, mostly behind blind Elite doors") was only
  half right. Elite rooms were 9% of deaths (2.7% of elite rooms killed the hero); most Epic+ deaths
  are ordinary Epic spawns (3.5% of monsters, 2 modifiers). Both are addressed: elite doors now show
  claw marks and Auto stays out when hurt (elite deaths 23 -> 5, 0.7% of rooms, still a real risk),
  and Epic+ hit a bit softer (Epic deaths 108 -> 79).
- Scrap: upgrades are now a real progression: about +3 on worn gear by floor 100 (+3.2 to +6.0 for
  heroes who keep their gear; heroes who just replaced gear sit at 0 to +1 for a while). No flood:
  scrap on hand stays under ~120.
- Curve: floor 100 is still about 3.5 h median, short of the 4.5 h goal. Upgrades added about +30%
  gear power, which the extra 51-100 HP growth roughly paid back, so pace barely moved while deaths
  fell. The HP bands do not steer the floor-100 median reliably (see the third run).

### What changed (numbers)

| Where | Change |
|---|---|
| `halls.gd` `read_door` | An elite door is never blind: without a door reader it shows red "Claw marks" ("Deep claw marks. Something strong waits here: at least Epic, with better loot."). Readers still tell every other door. |
| `game_state.gd` `auto_door` | Auto with no reader skips the claw-marked door below 75% HP (same rule readers already used); healthy it still picks at random. |
| `economy.gd` `elite_reward` | An elite room's monster pays a plain chest of scrap x (1 + floor/40) (28-42 on floor 100) and 1 dust (`ELITE_DUST`), on top of its Epic loot. Elite path text says so. |
| `monsters.gd` TIERS | Attack: Epic 1.3 -> 1.22, Legendary 1.4 -> 1.32, Mythic 1.55 -> 1.45 (HP and modifiers unchanged). |
| `economy.gd` `salvage_scrap` (via `GameData.scrap_value`) | Salvage = rarity base x (1 + item floor / 40) (`SALVAGE_FLOOR_STEP`; Epic on floor 100: 28, was 8) + half the scrap really paid for its upgrades (`item.upg_scrap`, `SALVAGE_UPGRADE_REFUND` 0.5; was +2 per level). The scrap bonus (Dwarf, Forge realm...) multiplies only the base, so there is no upgrade/salvage loop (Fable fix; test in stage6_currency). Upgrade costs unchanged. |
| `game_data.gd` HP bands | 51-75 3.4% -> 4.4%, 76-100 3.0% -> 4.3% a floor (monster HP x1.47 at floor 100 and beyond). Attack bands unchanged. |
| `game_state.gd` `spawn_enemy` | Bug fix: the elite flag was left on after a fall, so the next ordinary monster could wind up elite heavy blows. Now cleared on every spawn. |
| `combat.gd` `recap` | Death recap records `elite` (for the sim). |
| Sim | Counts elite rooms and elite deaths, upgrade level at floor 100, and an upgrade curve. |

### Left for a later pass (R6)
- Floor 100 median 3.5 h, goal 4.5 h. Monster HP is not a dependable lever (more power from upgrades
  cancels it, and noise is +-0.5 h). Next try: slower XP from floor 50 on, or item bonus growth per
  floor, and run 12 heroes (or two seeds) so one slow hero doesn't move the median.
- Boss-floor deaths went 12 -> 21 (bosses kept their HP scaling via the bands); watch it.
- Monster HP is now x1.47 from floor 100 down; the 101-150 band (1.2%) may need easing if the deep
  game feels slow once upgrades are spent out (+10 needs dust).
- One hero in after-run 1 reached 1.0M gold at floor 232 (deep kill gold); gold sinks past 200 deserve a look.
- big-update now has Ring and Necklace slots (8 gear slots, charm effects) that this branch did not have: a full balance_sim rerun is needed after merging (more slots also mean more upgrade scrap demand). Check the Epic charm values (crit 5, stone 18, potion 18).

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

### Left for a later pass (R5)
- Floor 100 median is 3.5-3.9 h, a little under 4-6 h. Next lever: the 51-100 attack bands (1.014 / 1.011) or early bands, or slower XP; every step there costs deaths.
- Deaths per hour at the frontier are unchanged (dive-until-death behaviour). Biggest single cause: blind Elite doors (Epic+). Ideas: show "danger" on doors without Sense, Auto skipping Elite doors when below 75% HP, or Elite = one tier up instead of "at least Epic".
- Casters: base HP/Def raised, but Mage and Ranger still die most (64 / 69 vs 43-58). A caster-only shield or evasion passive would be the next step.
- Scrap/upgrades: consider carrying part of an item's upgrade levels to its replacement, or more scrap from salvage, so upgrading is worth it.
- Sim: run deeper (BALANCE_BUDGET 1500+, 20+ h) to check 250-750; the God-class, hidden-class (x1.9 by 75) and egg changes on big-update were not in this branch.
- Sim heroes stay at 0-2 pets (nests are rare); pet abilities have little effect on these numbers.

---

# Full sim report: R6 final tuning (7 h per hero)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 7 hours of play each (played 7.0 hours to 7.0 hours).
- Floor 100: median time 3.5 hours (6 of 6 heroes got there, fastest 1.8 hours, slowest 5.3 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 126 (lowest 115, highest 200). Floors beyond that need more play time than was simulated.
- Deaths: median 37 per hero (212 in total, 5.05 per hour of play).
- Pace: the first 100 floors take about 30 minutes per 25 floors. Heroes slow to 4 times that or worse from floors 101-125. The slowest stretch is floors 76-100 at about 142 minutes (4.7 times the early pace).
- Defense: from floor 150 the median hero survives fewer than 4 monster hits.
- Offense: from floor 50 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 122 deaths in 17.0 hours there (7.17 per hour).
- Of all deaths, 5 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Weaponmaster | 121 | 55 | 1117 | +0.3 | 7h00 | 41 | 135 | 0 | 17.8k | 7 | 63 | full time |
| Mage/Elf | Lightbinder | 165 | 60 | 856 | +0.0 | 7h00 | 44 | 147 | 0 | 13.1k | 1 | 50 | full time |
| Ranger/Dwarf | Beastmaster | 120 | 54 | 979 | +0.5 | 7h00 | 44 | 147 | 1 | 20.7k | 75 | 48 | full time |
| Cleric/Angel | Grove Keeper | 200 | 52 | 1317 | +0.2 | 7h00 | 19 | 79 | 0 | 23.5k | 2 | 1 | full time |
| Trickster/Goblin | Shadowdancer | 115 | 50 | 1770 | +3.3 | 7h00 | 34 | 120 | 1 | 137.6k | 44 | 16 | full time |
| Knight/Orc | Paladin | 132 | 50 | 2462 | +3.2 | 7h00 | 30 | 120 | 1 | 83.1k | 46 | 29 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h09 | 0h33 | 5h15 | not reached | not reached | not reached |
| Mage/Elf | 0h13 | 0h46 | 2h01 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h09 | 0h36 | 4h16 | not reached | not reached | not reached |
| Cleric/Angel | 0h16 | 0h33 | 1h49 | not reached | not reached | not reached |
| Trickster/Goblin | 0h21 | 0h39 | 3h56 | not reached | not reached | not reached |
| Knight/Orc | 0h08 | 0h16 | 3h08 | not reached | not reached | not reached |
| **median** | 0h11 | 0h35 | 3h32 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h09 | 10 | 161 | 141 | 730 | 2217 | 120 | 15.7 | 11.4 | 0 | 3877 | 6 | 16 |
| Mage/Elf | 0h13 | 12 | 189 | 149 | 562 | 2217 | 120 | 14.9 | 8.6 | 1 | 3750 | 6 | 15 |
| Ranger/Dwarf | 0h09 | 9 | 141 | 127 | 596 | 2217 | 120 | 17.5 | 8.2 | 0 | 2662 | 15 | 11 |
| Cleric/Angel | 0h16 | 11 | 236 | 250 | 996 | 2217 | 120 | 8.9 | 14.9 | 1 | 5584 | 4 | 22 |
| Trickster/Goblin | 0h21 | 13 | 201 | 248 | 576 | 2217 | 120 | 8.9 | 6.8 | 2 | 3138 | 22 | 15 |
| Knight/Orc | 0h08 | 10 | 229 | 304 | 1011 | 2217 | 120 | 7.3 | 15.6 | 0 | 4451 | 1 | 18 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h33 | 19 | 593 | 489 | 3003 | 12.7k | 514 | 26.0 | 10.1 | 2 | 19.2k | 16 | 31 |
| Mage/Elf | 0h46 | 22 | 719 | 632 | 1964 | 12.7k | 514 | 20.1 | 6.6 | 3 | 19.0k | 12 | 20 |
| Ranger/Dwarf | 0h36 | 18 | 580 | 664 | 2232 | 12.7k | 514 | 19.1 | 6.9 | 3 | 10.2k | 63 | 32 |
| Cleric/Angel | 0h33 | 17 | 476 | 479 | 1943 | 12.7k | 514 | 26.5 | 5.6 | 2 | 10.3k | 11 | 16 |
| Trickster/Goblin | 0h39 | 18 | 436 | 501 | 1225 | 12.7k | 514 | 25.4 | 3.2 | 3 | 14.3k | 53 | 18 |
| Knight/Orc | 0h16 | 14 | 464 | 450 | 2134 | 12.7k | 514 | 28.2 | 6.3 | 0 | 9754 | 21 | 7 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 5h15 | 47 | 1950 | 3649 | 13.6k | 296.2k | 1887 | 81.2 | 12.6 | 32 | 127.5k | 104 | 67 |
| Mage/Elf | 2h01 | 34 | 1580 | 1437 | 4479 | 296.2k | 1887 | 206.2 | 3.4 | 9 | 45.0k | 102 | 53 |
| Ranger/Dwarf | 4h16 | 44 | 1655 | 3243 | 7309 | 296.2k | 1887 | 91.3 | 5.9 | 24 | 76.4k | 148 | 58 |
| Cleric/Angel | 1h49 | 29 | 1437 | 1252 | 5986 | 296.2k | 1887 | 236.6 | 4.5 | 7 | 51.5k | 52 | 42 |
| Trickster/Goblin | 3h56 | 39 | 1394 | 1587 | 5009 | 296.2k | 1887 | 186.7 | 3.4 | 20 | 104.4k | 70 | 39 |
| Knight/Orc | 3h08 | 37 | 1693 | 1465 | 7610 | 296.2k | 1887 | 202.2 | 8.0 | 16 | 58.1k | 164 | 50 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 9 | 13 | 9 | 16 | 21 | 8 | 11 |
| 26-50 | 25 | 34 | 27 | 17 | 18 | 8 | 21 |
| 51-75 | 40 | 39 | 76 | 28 | 57 | 24 | 39 |
| 76-100 | 242 | 35 | 143 | 48 | 140 | 148 | 142 |
| 101-125 | - | 132 | - | 64 | - | 181 | 132 |
| 126-150 | - | 137 | - | 87 | - | - | 112 |
| 151-175 | - | - | - | 109 | - | - | 109 |
| 176-200 | - | - | - | 50 | - | - | 50 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 11 | Warrior/Human, Mage/Elf, Cleric/Angel, Trickster/Goblin |
| 26-50 | 15 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 51-75 | 44 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 78 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 43 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 126-150 | 13 | Mage/Elf, Cleric/Angel, Knight/Orc |
| 151-175 | 6 | Mage/Elf, Cleric/Angel |
| 176-200 | 2 | Cleric/Angel |

## How heroes fall

- 212 deaths: 0 with 2 or fewer gear pieces worn (re-gearing after a fall), 21 to bosses, 174 to monsters with modifiers.
- Fight length at death: median 6 turns. Monster HP left when the hero fell: median 46%.
- Elite rooms: 741 entered, 5 deaths there (2% of all deaths, 0.7% of elite rooms).
- Worn gear upgrade level on reaching floor 100: median +3.0.
- Killer's tier: Mythic 15, Common 38, Epic 79, Legendary 26, Rare 21, Uncommon 33.
- Biggest damage source in the fatal fight: hits 212.
- Killer's modifiers: Regenerating 30, Explosive 13, Frigid 24, Giant 22, Burning 14, Swift 38, Elemental 17, Armored 24, Thorny 21, Enraged 33, Teleporting 18, Venomous 23, Shielded 16, Vampiric 16.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 39 | 45 | 35 | 33 | 24 | 59 |
| 0h50 | 66 | 61 | 59 | 69 | 67 | 76 |
| 1h20 | 84 | 73 | 74 | 80 | 70 | 91 |
| 1h50 | 92 | 89 | 74 | 100 | 81 | 94 |
| 2h20 | 94 | 104 | 77 | 107 | 81 | 94 |
| 2h50 | 94 | 104 | 90 | 119 | 86 | 94 |
| 3h20 | 98 | 119 | 90 | 138 | 91 | 105 |
| 3h50 | 98 | 119 | 95 | 138 | 91 | 105 |
| 4h20 | 98 | 126 | 109 | 148 | 100 | 110 |
| 4h50 | 98 | 126 | 109 | 167 | 100 | 117 |
| 5h20 | 111 | 126 | 120 | 167 | 100 | 120 |
| 5h50 | 121 | 146 | 120 | 167 | 100 | 120 |
| 6h20 | 121 | 146 | 120 | 188 | 100 | 132 |
| 6h50 | 121 | 165 | 120 | 197 | 104 | 132 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 15 | 15 | 13 | 13 | 13 | 16 |
| 0h50 | 22 | 22 | 21 | 20 | 20 | 23 |
| 1h20 | 28 | 27 | 26 | 25 | 25 | 27 |
| 1h50 | 31 | 32 | 30 | 29 | 29 | 31 |
| 2h20 | 34 | 36 | 33 | 33 | 32 | 33 |
| 2h50 | 37 | 39 | 37 | 35 | 34 | 35 |
| 3h20 | 40 | 42 | 39 | 38 | 37 | 37 |
| 3h50 | 41 | 46 | 42 | 40 | 39 | 40 |
| 4h20 | 43 | 48 | 44 | 42 | 41 | 42 |
| 4h50 | 45 | 50 | 46 | 44 | 43 | 43 |
| 5h20 | 47 | 52 | 48 | 46 | 44 | 45 |
| 5h50 | 49 | 54 | 50 | 48 | 46 | 46 |
| 6h20 | 52 | 57 | 52 | 50 | 48 | 48 |
| 6h50 | 54 | 59 | 54 | 52 | 49 | 49 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 207 | 385 | 301 | 200 | 201 | 547 |
| 0h50 | 815 | 840 | 573 | 360 | 351 | 518 |
| 1h20 | 1314 | 974 | 582 | 992 | 540 | 1419 |
| 1h50 | 1455 | 1440 | 1061 | 1437 | 772 | 1198 |
| 2h20 | 1202 | 542 | 1258 | 1780 | 482 | 516 |
| 2h50 | 628 | 1268 | 497 | 1902 | 545 | 1526 |
| 3h20 | 815 | 1762 | 1381 | 1652 | 755 | 548 |
| 3h50 | 1531 | 619 | 739 | 2588 | 1394 | 1805 |
| 4h20 | 1876 | 691 | 0 | 2491 | 929 | 1328 |
| 4h50 | 1633 | 2166 | 1349 | 1237 | 808 | 2029 |
| 5h20 | 1950 | 2153 | 731 | 2740 | 605 | 1375 |
| 5h50 | 1967 | 1678 | 1539 | 3431 | 569 | 2032 |
| 6h20 | 1306 | 2470 | 1448 | 3580 | 1760 | 686 |
| 6h50 | 1067 | 2675 | 1934 | 3200 | 1684 | 2292 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2503 | 10.9k | 3240 | 2944 | 1562 | 11.9k |
| 0h50 | 12.7k | 23.1k | 5776 | 8279 | 13.2k | 5713 |
| 1h20 | 20.0k | 17.2k | 11.3k | 12.6k | 7334 | 18.7k |
| 1h50 | 26.0k | 31.8k | 23.2k | 51.5k | 12.9k | 19.2k |
| 2h20 | 18.4k | 12.1k | 21.3k | 46.1k | 11.9k | 662 |
| 2h50 | 6484 | 20.2k | 5857 | 78.3k | 8824 | 51.5k |
| 3h20 | 14.0k | 43.4k | 22.4k | 28.6k | 19.4k | 10.4k |
| 3h50 | 12.6k | 17.2k | 20.9k | 70.4k | 77.8k | 57.3k |
| 4h20 | 50.6k | 23.8k | 47.4k | 137.5k | 16.3k | 34.0k |
| 4h50 | 23.0k | 58.8k | 4514 | 23.2k | 18.5k | 97.5k |
| 5h20 | 136.9k | 35.9k | 19.5k | 57.4k | 23.9k | 52.1k |
| 5h50 | 40.3k | 39.7k | 38.2k | 154.4k | 6801 | 45.6k |
| 6h20 | 28.8k | 90.7k | 29.8k | 228.2k | 117.2k | 4735 |
| 6h50 | 17.8k | 63.7k | 49.2k | 106.8k | 98.0k | 74.4k |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 16 | 9 | 24 | 3 | 4 | 5 |
| 0h50 | 2 | 43 | 67 | 4 | 23 | 9 |
| 1h20 | 4 | 22 | 20 | 33 | 13 | 60 |
| 1h50 | 42 | 29 | 70 | 52 | 64 | 5 |
| 2h20 | 53 | 6 | 40 | 73 | 8 | 4 |
| 2h50 | 17 | 19 | 1 | 110 | 8 | 16 |
| 3h20 | 8 | 57 | 22 | 127 | 6 | 23 |
| 3h50 | 44 | 49 | 105 | 3 | 70 | 96 |
| 4h20 | 0 | 32 | 96 | 168 | 5 | 60 |
| 4h50 | 69 | 94 | 15 | 0 | 8 | 124 |
| 5h20 | 104 | 21 | 5 | 77 | 3 | 40 |
| 5h50 | 138 | 21 | 63 | 133 | 18 | 59 |
| 6h20 | 16 | 117 | 40 | 54 | 108 | 7 |
| 6h50 | 9 | 46 | 42 | 86 | 15 | 34 |

### Average upgrade level of worn gear

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0.0 | 0.2 | 0.5 | 0.0 | 0.3 | 1.0 |
| 0h50 | 0.0 | 2.0 | 0.3 | 0.0 | 0.0 | 0.3 |
| 1h20 | 2.8 | 1.2 | 0.5 | 0.8 | 0.7 | 2.7 |
| 1h50 | 1.5 | 1.8 | 1.0 | 3.2 | 0.3 | 0.7 |
| 2h20 | 0.2 | 0.0 | 2.0 | 2.3 | 0.0 | 0.5 |
| 2h50 | 0.5 | 0.2 | 0.5 | 3.2 | 0.3 | 2.0 |
| 3h20 | 0.0 | 2.0 | 1.3 | 0.5 | 0.0 | 0.0 |
| 3h50 | 2.0 | 0.0 | 0.2 | 3.5 | 3.0 | 2.3 |
| 4h20 | 3.3 | 0.0 | 0.0 | 3.8 | 0.0 | 0.2 |
| 4h50 | 2.2 | 2.7 | 0.5 | 0.0 | 0.5 | 3.3 |
| 5h20 | 4.5 | 2.5 | 0.3 | 2.0 | 0.0 | 0.3 |
| 5h50 | 2.0 | 0.0 | 0.8 | 4.5 | 0.3 | 2.2 |
| 6h20 | 1.2 | 3.2 | 0.7 | 5.5 | 3.0 | 0.0 |
| 6h50 | 0.2 | 2.2 | 2.2 | 2.2 | 2.8 | 3.2 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 8 | 16 | 29 | 21 | 9 | 11 |
| 0h50 | 13 | 44 | 46 | 26 | 25 | 24 |
| 1h20 | 16 | 38 | 24 | 8 | 22 | 7 |
| 1h50 | 28 | 55 | 25 | 42 | 27 | 10 |
| 2h20 | 27 | 25 | 21 | 12 | 29 | 26 |
| 2h50 | 17 | 24 | 0 | 34 | 26 | 35 |
| 3h20 | 7 | 61 | 5 | 31 | 38 | 26 |
| 3h50 | 28 | 30 | 60 | 23 | 26 | 24 |
| 4h20 | 57 | 75 | 77 | 42 | 16 | 26 |
| 4h50 | 51 | 84 | 10 | 13 | 23 | 63 |
| 5h20 | 73 | 51 | 7 | 44 | 76 | 31 |
| 5h50 | 76 | 48 | 28 | 71 | 54 | 25 |
| 6h20 | 12 | 75 | 15 | 7 | 19 | 61 |
| 6h50 | 44 | 45 | 46 | 5 | 77 | 65 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2 | 1 | 2 | 2 | 2 | 0 |
| 0h50 | 4 | 3 | 5 | 4 | 5 | 5 |
| 1h20 | 5 | 6 | 8 | 7 | 8 | 5 |
| 1h50 | 8 | 9 | 10 | 7 | 11 | 9 |
| 2h20 | 10 | 14 | 13 | 10 | 14 | 14 |
| 2h50 | 15 | 17 | 18 | 10 | 17 | 16 |
| 3h20 | 16 | 20 | 20 | 13 | 18 | 19 |
| 3h50 | 24 | 25 | 23 | 13 | 20 | 19 |
| 4h20 | 28 | 28 | 25 | 13 | 23 | 22 |
| 4h50 | 32 | 29 | 30 | 16 | 25 | 22 |
| 5h20 | 32 | 32 | 32 | 17 | 28 | 24 |
| 5h50 | 35 | 35 | 36 | 17 | 31 | 27 |
| 6h20 | 37 | 38 | 39 | 17 | 31 | 30 |
| 6h50 | 40 | 41 | 42 | 18 | 34 | 30 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 201 | 401 | 367 | 179 | 331 | 576 |
| 0h50 | 781 | 718 | 804 | 391 | 323 | 821 |
| 1h20 | 980 | 963 | 1490 | 1182 | 858 | 2027 |
| 1h50 | 1187 | 1300 | 1954 | 1252 | 1021 | 1893 |
| 2h20 | 1611 | 422 | 1177 | 1674 | 493 | 556 |
| 2h50 | 1083 | 1552 | 564 | 1698 | 499 | 2246 |
| 3h20 | 1225 | 1870 | 1430 | 1736 | 882 | 1066 |
| 3h50 | 1768 | 651 | 1418 | 2401 | 1569 | 2830 |
| 4h20 | 1694 | 791 | 174 | 2432 | 1369 | 1434 |
| 4h50 | 1531 | 2592 | 1679 | 2113 | 1386 | 3359 |
| 5h20 | 3652 | 2649 | 1315 | 2604 | 1004 | 1582 |
| 5h50 | 2036 | 2084 | 2705 | 3280 | 609 | 1884 |
| 6h20 | 3112 | 3127 | 3696 | 3526 | 2486 | 926 |
| 6h50 | 1856 | 2855 | 3518 | 2380 | 2256 | 2244 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 1284 | 1102 | 1035 | 813 | 576 | 2220 |
| 0h50 | 4614 | 2244 | 1959 | 1658 | 974 | 2114 |
| 1h20 | 6526 | 3078 | 2148 | 4715 | 1155 | 5014 |
| 1h50 | 7552 | 4108 | 4232 | 5987 | 2355 | 5751 |
| 2h20 | 7247 | 1800 | 4837 | 7533 | 1329 | 2852 |
| 2h50 | 4702 | 4236 | 2348 | 9671 | 1868 | 7000 |
| 3h20 | 4146 | 5761 | 6026 | 10.2k | 2004 | 3298 |
| 3h50 | 10.9k | 2223 | 3428 | 12.1k | 5009 | 8096 |
| 4h20 | 12.2k | 2361 | 722 | 13.5k | 2885 | 7430 |
| 4h50 | 11.0k | 6629 | 6921 | 5520 | 2425 | 9202 |
| 5h20 | 13.6k | 6718 | 3115 | 15.5k | 1662 | 6543 |
| 5h50 | 14.5k | 6366 | 8063 | 18.2k | 1773 | 9490 |
| 6h20 | 9595 | 7622 | 7821 | 20.9k | 5553 | 4413 |
| 6h50 | 7664 | 8585 | 9305 | 19.7k | 5393 | 11.2k |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 6.7 | 5.4 | 6.7 | 7.4 | 5.8 | 7.0 |
| 0h50 | 8.7 | 6.5 | 7.2 | 8.8 | 9.0 | 8.6 |
| 1h20 | 12.2 | 5.1 | 9.1 | 5.7 | 7.7 | 13.0 |
| 1h50 | 5.7 | 5.4 | 8.2 | 17.6 | 5.2 | 8.0 |
| 2h20 | 10.2 | 6.0 | 6.1 | 9.2 | 7.7 | 7.2 |
| 2h50 | 6.6 | 6.7 | 9.2 | 22.2 | 7.2 | 6.0 |
| 3h20 | 10.7 | 5.1 | 7.8 | 7.6 | 14.6 | 12.5 |
| 3h50 | 5.8 | 6.5 | 7.0 | 27.3 | 10.9 | 22.2 |
| 4h20 | 7.3 | 7.8 | 14.3 | 20.0 | 8.6 | 8.1 |
| 4h50 | 6.5 | 6.4 | 5.2 | 12.0 | 9.4 | 17.1 |
| 5h20 | 11.5 | 5.3 | 13.6 | 8.6 | 15.8 | 15.0 |
| 5h50 | 5.6 | 6.5 | 6.0 | 11.5 | 7.3 | 10.5 |
| 6h20 | 8.2 | 5.7 | 8.3 | 17.6 | 10.9 | 16.2 |
| 6h50 | 8.7 | 6.5 | 8.8 | 20.7 | 14.6 | 12.0 |

## Problems seen while simulating

- Nothing got stuck.
