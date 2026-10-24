# Balance report (headless simulator)

## R7 balance pass (big update with Ring + Necklace, Oct 24): XP, charms, 51-100 HP

All runs: 6 heroes, 7 hours of play each, same seeds, `BALANCE_BUDGET=600`, 3 heroes at once. "Before" is
`wt/tune2` as branched (8 gear slots with charms, fairer elites, scrap refunds). The full report of the
final run follows the R5 section.

| | Before | Run 2: slower XP + charms | Run 3 (kept): + 51-100 HP |
|---|---|---|---|
| Floor 25 / 50 median | 0h09 / 0h30 | 0h09 / 0h30 | 0h09 / 0h30 |
| Floor 100 median (range) | 2h43 (1h15-4h36) | 3h07 (1h28-3h52) | 2h48 (2h03-5h09) |
| Floor 100 mean | 2h49 | 2h57 | 3h14 |
| Furthest floor in 7 h (median) | 131 | 145 | 126 |
| Minutes for floors 51-75 / 76-100 / 101-125 (median) | 36 / 107 / 123 | 39 / 118 / 152 | 38 / 109 / 151 |
| Deaths (all heroes, 42 h) | 209 (4.98 / h) | 207 (4.93 / h) | 222 (5.29 / h) |
| Deaths on floors 51-100 | 127 (9.0 / h there) | 121 (8.1 / h there) | 141 (8.4 / h there) |
| Elite rooms entered / deaths there | 711 / 14 | 710 / 13 | 730 / 9 |
| Worn gear upgrade level at floor 100 (median) | +2.1 | +2.3 | +2.6 |

What the numbers say:
- Ring and Necklace made the game faster: floor 100 went from 3h32 (R6, 6 slots) to 2h43. The fastest
  hero (Cleric/Angel, Grove Keeper) reached floor 100 at level 26 in 1h15, so levels are not what holds a
  hero back: gear is.
- Slower XP past floor 50 (run 2) worked a little (+0h24 median, +0h08 mean). Levels at 7 h fell by about
  4 (49-58 -> 41-54). It slows the slow heroes more than the fast ones.
- Run 3 added more monster HP on floors 51-100. The median went *down* (2h48) while the mean went up
  (3h14): the fast heroes now take 2h+ (none under 2h), and two slow heroes passed 4h20. This is the same
  noise the R6 pass saw (about +-0.5 h, and the order of six heroes swaps between runs). Run 3 is kept
  because it is slower on average and holds back the fast outliers, with no wall: growth stays smooth
  and eases to 1.2% a floor from 101.
- Epic charms: crit 5 and potion/stone 18 were not a problem by themselves, but with jewelry already
  speeding things up they were trimmed a step (crit 4, stone 15, potion 15), still clearly above Rare.
- Floor 100 is still well short of the 4.5 h goal (median 2h48, mean 3h14). See "Left for later".

### What changed (numbers)

| Where | Change |
|---|---|
| `game_data.gd` `xp_for_kill` | Kill XP grows 2 a floor to floor 50 (`XP_SLOW_FROM`), then 0.5 a floor (`XP_DEEP_STEP`): floor 100 gives 129 XP a kill (was 204), floor 150 154 (was 304). Bosses still x8. |
| `gear_slots.gd` CHARMS | Epic ring crit 5 -> 4, ring stone find 18 -> 15, necklace potion 18 -> 15 (Uncommon/Rare and the other charms unchanged). |
| `game_data.gd` HP bands | 51-75 4.4% -> 4.9%, 76-100 4.3% -> 4.9% a floor (monster HP about x1.3 at floor 100 and below). Attack bands unchanged. |
| `game_data.gd` `gear_score` | Jewelry Gear Score uses the unrounded roll (a ring's bonus is truncated to a whole number, so early rings scored 13, 13, 27...). Display and the shop's featured deal only; stats unchanged. |

### Left for a later pass (R7)
- Floor 100 median 2h48, mean 3h14; goal 4.5 h. Neither XP nor monster HP moves it far, because better
  gear from deeper floors keeps pace. Next levers to try: item bonus growth per floor (`per_floor` in
  `SLOT_INFO`, all slots alike), or a smaller ring share (15% -> 10% of a weapon). Run 12 heroes (or two
  seed sets) so one hero doesn't swing the median.
- Deaths went up 6% in run 3 (fights on 51-100 last longer); watch it in play.
- Grove Keeper (Cleric/Angel) is the fastest in every run (1h15-2h03 to floor 100); worth a look by the
  systems designer.

## R6 balance pass (2.1 + big update, Oct 24): elite doors, scrap, curve

All runs: 6 heroes, 7 hours of play each, same seeds, `BALANCE_BUDGET=600`, 3 heroes at once. "Before" is
`wt/tune` as branched (big update in: God classes, hidden classes x1.9 by 75, portals, buildings); "after"
is the final tuning of that pass (its full report was replaced by R7's). The sim now also counts elite rooms
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

# Full sim report: R7 final tuning (run 3, 7 h per hero)

Made by `tools/balance_sim.gd` (full mode). One turn = 1 second at normal speed, so 3,600 turns = 1 hour of play. Heroes play on Auto like a sensible player: dive, go home when the bag is full or potions run low, buy potions, equip the best, upgrade gear, spend stats and pick classes automatically. They do not fetch graves on purpose (the dive does it by itself if the killer is beaten on the way), take their strongest pets along when they find one (nests are rare), and use no elixirs, parties or realms. Fixed seeds, so a rerun gives the same numbers.

## In plain words

- 6 heroes, up to 7 hours of play each (played 7.0 hours to 7.0 hours).
- Gear: 8 slots. Ring and Necklace are about half a slot each (a ring is 15% of a weapon's Attack, a necklace 25% of a helmet's HP, plus a small charm from Uncommon up).
- Floor 100: median time 2.8 hours (6 of 6 heroes got there, fastest 2.1 hours, slowest 5.2 hours).
- Floor 250: not reached by any hero.
- Floor 500: not reached by any hero.
- Floor 750: not reached by any hero.
- Furthest floor when play stopped: median 126 (lowest 102, highest 152). Floors beyond that need more play time than was simulated.
- Deaths: median 37 per hero (222 in total, 5.29 per hour of play).
- Pace: the first 100 floors take about 28 minutes per 25 floors. Heroes slow to 4 times that or worse from floors 101-125. The slowest stretch is floors 101-125 at about 151 minutes (5.4 times the early pace).
- Defense: at every milestone the median hero survives 4 or more hits.
- Offense: from floor 50 a plain hero attack needs more than 12 swings to kill the monster.
- Floors 51-100: 141 deaths in 16.7 hours there (8.43 per hour).
- Of all deaths, 9 were on boss floors (every 25th floor).

## The heroes

| Hero | Final class | Floor | Level | Gear Score | Avg upgrade | Play time | Deaths | Home trips | Pets | Gold+bank | Scrap | Dust | Stopped |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | Warlord | 107 | 48 | 1592 | +2.1 | 7h00 | 47 | 157 | 0 | 22.3k | 43 | 85 | full time |
| Mage/Elf | Lightbinder | 139 | 54 | 1966 | +1.3 | 7h00 | 43 | 164 | 0 | 27.2k | 84 | 63 | full time |
| Ranger/Dwarf | Grove Ranger | 102 | 47 | 1346 | +2.5 | 7h00 | 44 | 143 | 0 | 50.6k | 20 | 21 | full time |
| Cleric/Angel | Storm Druid | 152 | 47 | 2041 | +1.5 | 7h00 | 30 | 112 | 0 | 47.3k | 49 | 53 | full time |
| Trickster/Goblin | Illusionist | 123 | 46 | 1727 | +1.5 | 7h00 | 32 | 115 | 0 | 81.4k | 124 | 43 | full time |
| Knight/Orc | Juggernaut | 130 | 44 | 2118 | +2.0 | 7h00 | 26 | 97 | 0 | 55.8k | 208 | 82 | full time |

## Time to reach each floor (play time, h:mm)

| Hero | Floor 25 | Floor 50 | Floor 100 | Floor 250 | Floor 500 | Floor 750 |
|---|---|---|---|---|---|---|
| Warrior/Human | 0h15 | 0h32 | 5h09 | not reached | not reached | not reached |
| Mage/Elf | 0h08 | 0h32 | 2h32 | not reached | not reached | not reached |
| Ranger/Dwarf | 0h16 | 0h34 | 3h05 | not reached | not reached | not reached |
| Cleric/Angel | 0h10 | 0h21 | 2h03 | not reached | not reached | not reached |
| Trickster/Goblin | 0h09 | 0h28 | 4h21 | not reached | not reached | not reached |
| Knight/Orc | 0h08 | 0h16 | 2h17 | not reached | not reached | not reached |
| **median** | 0h09 | 0h30 | 2h48 | not reached | not reached | not reached |

### Floor 25: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h15 | 11 | 228 | 316 | 1159 | 2217 | 120 | 7.0 | 18.7 | 1 | 4072 | 19 | 5 |
| Mage/Elf | 0h08 | 9 | 111 | 122 | 457 | 2217 | 120 | 18.2 | 5.4 | 0 | 2225 | 4 | 11 |
| Ranger/Dwarf | 0h16 | 12 | 185 | 187 | 748 | 2217 | 120 | 11.9 | 11.5 | 2 | 3746 | 16 | 10 |
| Cleric/Angel | 0h10 | 10 | 218 | 280 | 878 | 2217 | 120 | 7.9 | 12.7 | 0 | 4627 | 7 | 2 |
| Trickster/Goblin | 0h09 | 9 | 122 | 114 | 379 | 2217 | 120 | 19.4 | 4.7 | 0 | 3517 | 34 | 6 |
| Knight/Orc | 0h08 | 10 | 212 | 264 | 969 | 2217 | 120 | 8.4 | 19.0 | 0 | 3313 | 0 | 5 |

### Floor 50: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 0h32 | 17 | 459 | 770 | 2433 | 12.7k | 514 | 16.5 | 6.3 | 2 | 5248 | 13 | 9 |
| Mage/Elf | 0h32 | 19 | 549 | 552 | 1744 | 12.7k | 514 | 23.0 | 5.2 | 2 | 11.2k | 71 | 49 |
| Ranger/Dwarf | 0h34 | 18 | 546 | 642 | 2313 | 12.7k | 514 | 19.8 | 7.1 | 3 | 9267 | 40 | 14 |
| Cleric/Angel | 0h21 | 17 | 640 | 650 | 2847 | 12.7k | 514 | 19.5 | 8.6 | 0 | 8805 | 10 | 19 |
| Trickster/Goblin | 0h28 | 16 | 608 | 625 | 2022 | 12.7k | 514 | 20.3 | 5.5 | 1 | 11.1k | 14 | 3 |
| Knight/Orc | 0h16 | 14 | 421 | 542 | 1794 | 12.7k | 514 | 23.4 | 5.1 | 0 | 7803 | 22 | 9 |

### Floor 100: hero against the monster there

| Hero | Time | Level | Gear Score | Hero attack | Hero max HP | Monster HP | Monster attack | Swings to kill | Hits to die | Deaths so far | Gold+bank | Scrap | Dust |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior/Human | 5h09 | 44 | 1417 | 2260 | 9889 | 385.3k | 1887 | 170.5 | 8.0 | 29 | 24.1k | 45 | 40 |
| Mage/Elf | 2h32 | 35 | 1551 | 1593 | 4685 | 385.3k | 1887 | 241.9 | 3.6 | 14 | 38.3k | 37 | 72 |
| Ranger/Dwarf | 3h05 | 34 | 1474 | 1589 | 7201 | 385.3k | 1887 | 242.5 | 5.3 | 21 | 21.5k | 28 | 16 |
| Cleric/Angel | 2h03 | 30 | 1747 | 2032 | 7699 | 385.3k | 1887 | 189.6 | 6.0 | 6 | 102.0k | 61 | 41 |
| Trickster/Goblin | 4h21 | 38 | 1812 | 2006 | 5507 | 385.3k | 1887 | 192.1 | 4.3 | 19 | 95.7k | 10 | 2 |
| Knight/Orc | 2h17 | 31 | 1475 | 1448 | 6529 | 385.3k | 1887 | 266.1 | 6.0 | 9 | 33.5k | 65 | 25 |

Swings to kill = monster HP divided by one plain hero attack (skills and crits make it faster). Hits to die = hero max HP divided by one monster hit after defense. Under about 4 hits to die the hero is in danger.

## Pace: minutes of play for each 25 floors

| Floors | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc | median |
|---|---|---|---|---|---|---|---|
| 1-25 | 15 | 8 | 16 | 10 | 9 | 8 | 10 |
| 26-50 | 17 | 24 | 19 | 11 | 19 | 8 | 18 |
| 51-75 | 83 | 39 | 22 | 13 | 38 | 38 | 38 |
| 76-100 | 195 | 81 | 128 | 90 | 195 | 83 | 109 |
| 101-125 | - | 151 | - | 118 | - | 219 | 151 |
| 126-150 | - | - | - | 150 | - | - | 150 |

## Where heroes die

| Floors | Deaths | Heroes who died here |
|---|---|---|
| 1-25 | 11 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Trickster/Goblin |
| 26-50 | 10 | Warrior/Human, Mage/Elf, Ranger/Dwarf |
| 51-75 | 53 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 76-100 | 88 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 101-125 | 43 | Warrior/Human, Mage/Elf, Ranger/Dwarf, Cleric/Angel, Trickster/Goblin, Knight/Orc |
| 126-150 | 14 | Mage/Elf, Cleric/Angel, Knight/Orc |
| 151-175 | 3 | Cleric/Angel |

## How heroes fall

- 222 deaths: 11 with 2 or fewer gear pieces worn (re-gearing after a fall), 23 to bosses, 169 to monsters with modifiers.
- Fight length at death: median 6 turns. Monster HP left when the hero fell: median 47%.
- Elite rooms: 730 entered, 9 deaths there (4% of all deaths, 1.2% of elite rooms).
- Worn gear upgrade level on reaching floor 100: median +2.6.
- Killer's tier: Epic 77, Legendary 28, Common 53, Uncommon 28, Rare 25, Mythic 11.
- Biggest damage source in the fatal fight: hits 222.
- Killer's modifiers: Giant 25, Burning 27, Swift 35, Frigid 12, Enraged 32, Elemental 19, Vampiric 12, Teleporting 20, Regenerating 24, Shielded 19, Explosive 20, Armored 12, Thorny 21, Venomous 18.

## Curves over play time

Every row is a play time; one column per hero.

### Best floor

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 30 | 38 | 36 | 48 | 29 | 59 |
| 0h50 | 62 | 68 | 65 | 83 | 70 | 64 |
| 1h20 | 66 | 82 | 76 | 98 | 85 | 77 |
| 1h50 | 74 | 90 | 77 | 98 | 92 | 86 |
| 2h20 | 80 | 90 | 78 | 105 | 92 | 100 |
| 2h50 | 80 | 100 | 94 | 109 | 99 | 100 |
| 3h20 | 89 | 110 | 100 | 109 | 99 | 100 |
| 3h50 | 90 | 110 | 102 | 109 | 99 | 112 |
| 4h20 | 90 | 118 | 102 | 126 | 99 | 112 |
| 4h50 | 94 | 118 | 102 | 127 | 102 | 112 |
| 5h20 | 100 | 125 | 102 | 127 | 113 | 112 |
| 5h50 | 100 | 125 | 102 | 141 | 123 | 119 |
| 6h20 | 102 | 129 | 102 | 148 | 123 | 130 |
| 6h50 | 107 | 139 | 102 | 152 | 123 | 130 |

### Level

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 13 | 14 | 14 | 16 | 13 | 16 |
| 0h50 | 21 | 23 | 21 | 22 | 21 | 22 |
| 1h20 | 26 | 27 | 24 | 26 | 25 | 26 |
| 1h50 | 30 | 30 | 28 | 29 | 27 | 29 |
| 2h20 | 32 | 34 | 31 | 32 | 30 | 31 |
| 2h50 | 35 | 36 | 33 | 34 | 32 | 33 |
| 3h20 | 37 | 40 | 35 | 36 | 34 | 35 |
| 3h50 | 39 | 42 | 37 | 38 | 36 | 36 |
| 4h20 | 41 | 44 | 39 | 40 | 38 | 38 |
| 4h50 | 43 | 46 | 41 | 42 | 40 | 39 |
| 5h20 | 45 | 48 | 42 | 43 | 41 | 41 |
| 5h50 | 46 | 50 | 44 | 45 | 43 | 42 |
| 6h20 | 47 | 52 | 45 | 46 | 44 | 43 |
| 6h50 | 48 | 53 | 46 | 47 | 46 | 43 |

### Gear Score (average of worn gear)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 172 | 220 | 328 | 468 | 225 | 382 |
| 0h50 | 349 | 880 | 531 | 890 | 582 | 734 |
| 1h20 | 812 | 446 | 757 | 1439 | 491 | 1002 |
| 1h50 | 895 | 596 | 476 | 1615 | 598 | 919 |
| 2h20 | 562 | 1186 | 1250 | 1392 | 1534 | 612 |
| 2h50 | 584 | 1152 | 1177 | 998 | 1192 | 735 |
| 3h20 | 484 | 1297 | 957 | 1554 | 1299 | 1710 |
| 3h50 | 509 | 1117 | 611 | 1816 | 860 | 869 |
| 4h20 | 649 | 1216 | 573 | 1641 | 1653 | 540 |
| 4h50 | 1438 | 1688 | 1064 | 2093 | 1463 | 1463 |
| 5h20 | 932 | 1477 | 1816 | 2214 | 1878 | 1750 |
| 5h50 | 1434 | 1053 | 1351 | 2549 | 1864 | 2022 |
| 6h20 | 1837 | 2285 | 812 | 2654 | 1861 | 1324 |
| 6h50 | 1423 | 743 | 1742 | 1346 | 1705 | 2118 |

### Gold + bank

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 1905 | 1843 | 4783 | 9024 | 5482 | 3577 |
| 0h50 | 5419 | 15.3k | 12.6k | 14.1k | 7676 | 17.6k |
| 1h20 | 13.8k | 5912 | 26.2k | 67.4k | 7037 | 21.0k |
| 1h50 | 15.3k | 5967 | 12.0k | 50.4k | 11.0k | 15.3k |
| 2h20 | 12.8k | 20.1k | 16.3k | 22.0k | 89.9k | 5878 |
| 2h50 | 10.5k | 23.2k | 32.5k | 15.2k | 27.5k | 12.5k |
| 3h20 | 6651 | 40.3k | 20.9k | 64.9k | 56.6k | 40.9k |
| 3h50 | 6809 | 16.3k | 13.1k | 59.4k | 17.0k | 21.5k |
| 4h20 | 11.0k | 21.4k | 12.0k | 37.0k | 105.3k | 7123 |
| 4h50 | 49.7k | 49.0k | 24.7k | 222.4k | 20.9k | 50.3k |
| 5h20 | 21.3k | 25.2k | 62.0k | 77.5k | 73.9k | 27.2k |
| 5h50 | 31.6k | 28.1k | 41.2k | 283.2k | 41.1k | 65.0k |
| 6h20 | 114.8k | 88.9k | 13.7k | 73.3k | 31.1k | 37.6k |
| 6h50 | 26.8k | 6826 | 41.8k | 25.1k | 50.2k | 43.0k |

### Scrap

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2 | 4 | 15 | 30 | 24 | 0 |
| 0h50 | 9 | 21 | 50 | 12 | 21 | 19 |
| 1h20 | 8 | 40 | 49 | 83 | 14 | 18 |
| 1h50 | 0 | 7 | 45 | 38 | 6 | 15 |
| 2h20 | 8 | 3 | 11 | 21 | 15 | 7 |
| 2h50 | 9 | 40 | 121 | 2 | 23 | 5 |
| 3h20 | 25 | 7 | 28 | 81 | 69 | 76 |
| 3h50 | 28 | 4 | 120 | 40 | 24 | 20 |
| 4h20 | 5 | 16 | 55 | 44 | 91 | 30 |
| 4h50 | 45 | 93 | 0 | 110 | 14 | 85 |
| 5h20 | 10 | 23 | 123 | 15 | 59 | 50 |
| 5h50 | 65 | 11 | 121 | 162 | 36 | 58 |
| 6h20 | 27 | 66 | 4 | 56 | 0 | 100 |
| 6h50 | 34 | 4 | 38 | 13 | 70 | 208 |

### Average upgrade level of worn gear

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 0.4 | 0.0 | 0.4 | 0.8 | 0.4 | 0.3 |
| 0h50 | 0.4 | 0.4 | 0.0 | 0.3 | 0.0 | 0.3 |
| 1h20 | 0.8 | 0.1 | 0.9 | 2.6 | 0.3 | 0.9 |
| 1h50 | 0.5 | 0.4 | 0.0 | 2.1 | 0.1 | 0.4 |
| 2h20 | 0.3 | 0.9 | 2.1 | 0.5 | 2.1 | 0.1 |
| 2h50 | 0.0 | 0.5 | 1.4 | 0.3 | 1.0 | 0.8 |
| 3h20 | 0.1 | 1.1 | 0.0 | 2.6 | 1.5 | 2.6 |
| 3h50 | 0.0 | 0.4 | 0.1 | 2.6 | 0.5 | 0.5 |
| 4h20 | 0.3 | 0.3 | 0.5 | 1.5 | 2.6 | 0.0 |
| 4h50 | 2.0 | 1.3 | 0.5 | 2.8 | 1.3 | 0.4 |
| 5h20 | 0.5 | 0.6 | 2.6 | 3.3 | 2.8 | 1.9 |
| 5h50 | 1.6 | 0.3 | 1.5 | 4.3 | 1.4 | 3.1 |
| 6h20 | 3.9 | 3.5 | 0.1 | 3.0 | 2.3 | 0.0 |
| 6h50 | 1.3 | 0.0 | 2.6 | 0.4 | 1.4 | 2.0 |

### Dust

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 28 | 16 | 13 | 20 | 20 | 8 |
| 0h50 | 15 | 1 | 23 | 30 | 12 | 23 |
| 1h20 | 14 | 48 | 33 | 13 | 20 | 21 |
| 1h50 | 5 | 27 | 42 | 64 | 3 | 12 |
| 2h20 | 7 | 1 | 21 | 36 | 9 | 17 |
| 2h50 | 38 | 40 | 59 | 14 | 14 | 12 |
| 3h20 | 16 | 30 | 56 | 31 | 32 | 29 |
| 3h50 | 14 | 14 | 71 | 41 | 65 | 16 |
| 4h20 | 37 | 44 | 29 | 32 | 58 | 30 |
| 4h50 | 53 | 80 | 17 | 69 | 45 | 33 |
| 5h20 | 45 | 21 | 40 | 14 | 74 | 64 |
| 5h50 | 72 | 73 | 54 | 115 | 14 | 61 |
| 6h20 | 21 | 114 | 49 | 22 | 54 | 54 |
| 6h50 | 94 | 98 | 40 | 72 | 21 | 69 |

### Deaths so far

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 2 | 2 | 2 | 0 | 1 | 1 |
| 0h50 | 5 | 4 | 5 | 3 | 4 | 3 |
| 1h20 | 7 | 8 | 9 | 3 | 7 | 6 |
| 1h50 | 10 | 11 | 15 | 6 | 9 | 9 |
| 2h20 | 14 | 14 | 18 | 9 | 10 | 11 |
| 2h50 | 18 | 17 | 21 | 11 | 13 | 12 |
| 3h20 | 21 | 20 | 24 | 12 | 16 | 14 |
| 3h50 | 23 | 23 | 27 | 15 | 19 | 17 |
| 4h20 | 25 | 26 | 30 | 19 | 19 | 20 |
| 4h50 | 27 | 29 | 32 | 19 | 23 | 20 |
| 5h20 | 31 | 32 | 34 | 23 | 23 | 23 |
| 5h50 | 36 | 36 | 37 | 23 | 26 | 23 |
| 6h20 | 37 | 37 | 41 | 25 | 29 | 26 |
| 6h50 | 45 | 43 | 43 | 30 | 32 | 26 |

### Hero attack

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 269 | 203 | 392 | 550 | 181 | 266 |
| 0h50 | 473 | 895 | 737 | 1013 | 1049 | 728 |
| 1h20 | 911 | 558 | 693 | 1425 | 618 | 1215 |
| 1h50 | 1115 | 1164 | 1058 | 1570 | 558 | 1038 |
| 2h20 | 2468 | 1379 | 1199 | 1550 | 1587 | 622 |
| 2h50 | 2878 | 1572 | 1553 | 1505 | 1719 | 1240 |
| 3h20 | 830 | 1680 | 1240 | 1974 | 1713 | 1943 |
| 3h50 | 1592 | 1636 | 783 | 2042 | 1603 | 1491 |
| 4h20 | 1503 | 1768 | 647 | 2245 | 1858 | 372 |
| 4h50 | 2166 | 1992 | 1557 | 2415 | 1876 | 1566 |
| 5h20 | 2073 | 2113 | 1880 | 2500 | 2120 | 1897 |
| 5h50 | 2488 | 1883 | 1640 | 2712 | 1828 | 2208 |
| 6h20 | 4690 | 2640 | 1466 | 2944 | 2337 | 1740 |
| 6h50 | 5262 | 873 | 1878 | 2202 | 2347 | 2248 |

### Hero max HP

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 1089 | 784 | 1095 | 2176 | 715 | 2030 |
| 0h50 | 2034 | 2804 | 2333 | 4588 | 1246 | 3660 |
| 1h20 | 4780 | 1486 | 4231 | 6172 | 1568 | 4926 |
| 1h50 | 5503 | 1704 | 2014 | 7344 | 1495 | 5265 |
| 2h20 | 2957 | 4044 | 5577 | 6775 | 4544 | 3746 |
| 2h50 | 3338 | 4364 | 6187 | 4269 | 4296 | 3265 |
| 3h20 | 3502 | 5204 | 5812 | 7656 | 4291 | 9462 |
| 3h50 | 4009 | 4728 | 3091 | 9215 | 3010 | 4874 |
| 4h20 | 3977 | 5086 | 2833 | 9543 | 5315 | 4468 |
| 4h50 | 9529 | 5943 | 6248 | 11.3k | 4836 | 9391 |
| 5h20 | 7113 | 5577 | 8160 | 12.0k | 5884 | 11.0k |
| 5h50 | 10.5k | 3461 | 7093 | 14.3k | 6031 | 11.8k |
| 6h20 | 12.5k | 7781 | 3174 | 14.6k | 6150 | 10.9k |
| 6h50 | 10.5k | 2888 | 8347 | 9286 | 5868 | 12.4k |

### Turns per kill (over the last 10 minutes)

| Play time | Warrior/Human | Mage/Elf | Ranger/Dwarf | Cleric/Angel | Trickster/Goblin | Knight/Orc |
|---|---|---|---|---|---|---|
| 0h20 | 7.4 | 6.6 | 6.2 | 7.7 | 7.4 | 7.6 |
| 0h50 | 7.1 | 5.7 | 8.2 | 5.4 | 5.0 | 9.1 |
| 1h20 | 6.7 | 5.3 | 9.7 | 17.6 | 7.1 | 7.6 |
| 1h50 | 5.4 | 5.5 | 7.2 | 10.9 | 14.0 | 9.0 |
| 2h20 | 7.8 | 5.2 | 7.8 | 5.7 | 9.8 | 16.2 |
| 2h50 | 6.4 | 5.4 | 6.8 | 17.1 | 6.6 | 17.6 |
| 3h20 | 6.3 | 5.5 | 6.4 | 10.3 | 6.5 | 10.2 |
| 3h50 | 8.0 | 4.8 | 10.0 | 9.7 | 4.9 | 5.6 |
| 4h20 | 11.5 | 4.8 | 9.4 | 7.4 | 14.0 | 14.6 |
| 4h50 | 9.4 | 5.0 | 13.6 | 16.2 | 5.3 | 19.4 |
| 5h20 | 6.7 | 5.2 | 9.4 | 8.2 | 16.2 | 9.8 |
| 5h50 | 5.0 | 7.1 | 7.7 | 13.3 | 8.6 | 22.2 |
| 6h20 | 11.8 | 8.1 | 14.3 | 13.0 | 9.7 | 9.7 |
| 6h50 | 6.1 | 8.5 | 7.8 | 5.0 | 7.0 | 20.0 |

## Problems seen while simulating

- Nothing got stuck.
