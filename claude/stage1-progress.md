# Stage 1 — Build Progress

Juzo said "go" on 2026-10-13 at 8:06 PM: build stage 1 part by part, very thoroughly. Don't install to the PC until Juzo says "install it".

Design: `claude/dungeon-revamp-design.md`. Before changing anything, check `claude/code-map.md`.

**If you're resuming:** run `git status` and `git diff` in /root/solaria first. Usage may have run out mid-part, so finish or fix any uncommitted work before starting new work.

## Saves are reset with this update (Juzo, 8:30 PM)
Juzo said all saves can be reset. Build a one-time reset:
- Add a save "epoch" constant, for example `GameState.SAVE_EPOCH := 12`, stored in the profile.
- On startup, if the stored epoch is older, delete every hero save, the profile (keep only settings like sound, volume, text size and accessibility if easy) and the codex.
- Then show a short notice: "Solaria 0.12 is a fresh start: all heroes have been reset."
- Once this exists, the Part 1 Bank migration (moving old gold into the Bank) no longer matters.
- Do this before the first install of stage 1. Test it with old saves made by the previous version.

## Rules for every part
- Read the code it touches first (`code-map.md` lists what affects what).
- Run the full test suite (`tests/run_tests.gd`, failures: 0) and `tests/town_logic.gd`, and take phone screenshots of any new screen (`tests/town_shots.gd`).
- Update the rules text: patch notes 0.12, guide pages, tips and Inn rumors.
- Commit each part locally in /root/solaria with a clear message, then tick it off here.
- Keep class secrecy: never reveal hidden classes or unlock rules in text.

## Parts
1. **DONE: Bank and carried gold** (f1776af)
2. **DONE: Death penalty, checkpoints, leaving** (da38841, 174afe4)
   - `GameState._death_losses()`: falling loses carried gold, bag, worn gear and carried backpacks. Bound items (`item["bound"]` = "soul"/"account") stay.
   - `GameState.checkpoint_start(f)`: wake at 1, 26, 51...
   - `Town.blocked()` returns `Town.FLOOR_BLOCK` mid-floor (`Town.floor_clear`: fight 1 and the enemy untouched).
   - Tapping Town mid-floor toggles `state.go_home_after`; `_next_floor` sends you home.
   - Floor picker from town: only checkpoint floors up to `last_start()`.
   - The death card lists losses (`last_death["lost"]`, `["woke"]`).
3. **DONE: Backpacks** (95a8547)
   - `bonus_bag` and `packs_carried` (`GameData.PACK_*`).
   - Found on kills (0.15%) and bosses (4%). Banked on `Town.enter`, lost on death.
4. **DONE: Snik the goblin trader and Return Scrolls** (b7e5349)
   - `_make_merchant` (when `merchant_who` is ""): 2 gear, 3 potions, a Return Scroll and a random scroll, at 60% of shop price for the current floor.
   - `goblin_buy_junk()`: buys unlocked Common/Uncommon gear for half its sell value.
   - Snik appears at the boss fork and on random forks (floor × 0.02%, max 20%). Hidden from the town Shop.
   - `return_scrolls`: tap Town mid-floor and confirm to read one (`Town.use_return`).
5. **DONE: Consumable icons** (52e2372)
   - `art/consumables/` (DCSS CC0 + a drawn backpack, credits in CREDITS.md and credits.gd). `Sprites.consumable_icon(id)`.
   - Used in Shop supplies, Snik's popup and the potion button.
6. **DONE: 1,000 floors** (c378bb0)
   - `GameData.MAX_FLOOR 1000`, `REGION_FLOORS 100`, `region_of`, `is_region_boss` (boss HP × `REGION_BOSS_MULT`), `WALLS {250, 500, 750, 1000}` via `wall_mult` (HP × wall, ATK × sqrt(wall)).
   - Zone bosses every 50 keep their "zone" kind (realm rulers, hidden classes and lineage depend on it). `_next_floor` stops at 1,000.
7. **DONE: Roster of 9, team of 3** (55f501e)
   - `GameData.MAX_HEROES 9`, `SLOT_UNLOCKS [0, 10, 25, 50, 100, 150, 250, 350, 500]`. Hero select shows filled slots, one empty slot and the next unlock (compact cards for phones).
   - **Falls:** `Party.hit_member` knocks a companion out and calls `lose_worn_gear()` on them (saved at once). When you fall with a companion still up, `_hero_died` calls `_leader_falls()`: `leader_down = true`, you lose only your worn gear, and `take_turn` runs `_down_turn()` (companions fight, the monster only hits them). No potions or heals on you while down. `get_up()` on the next floor (40% HP) or in town (full). All three down = the normal death penalty.
   - `meta()` now stores `"looks"`; `TownView.set_heroes()` draws every roster hero walking in town with a marker (gold over the one you play). `main._town_heroes()` reads other slots once per town visit.
   - The "Full Party" deed never counted heroes before; `Codex.value("heroes")` now counts slots. New deed "Full Roster" (9 heroes, title Guildmaster). 88 achievements.
   - Decision: a fall is not a death (deaths count only when the whole team is down).
8. **DONE: Pets** (ee5db55)
   - `menagerie.gd` (class Menagerie): owned pets per hero (`pets`, `pets_out`, `eggs`, saved). Tamer brings 3, others 1. Pet power = 8% of Attack + 3%/tier + 0.4%/level; level up every 40 × level kills (max 50).
   - **Class pets (Juzo confirmed):** `World.PETS` keeps Ranger, Knight, Mage, Wanderer, Bard. Warrior, Cleric, Acolyte, Trickster lost theirs (`pet_stage` returns -1).
   - **Bard → Beast Whisperer** (Juzo, 10:04 PM): new Troubadour branch-off, "Calm 150 wild monsters by sparing them" (`spare_beasts` counter in `ClassTree.on_spare`). On the team it adds +20% catch chance and pets hit 25% harder.
   - **Beast Tamer:** unlock is now level 60 + 100 escapes at a sure 100% chance (`sure_escapes`, counted in `Lineage.try_escape`). `Races.ESCAPE_MAX` 90 → 100. The old "beast friend" companion power is removed (real pets replace it).
   - **Catching:** Catch button (`main.catch_button`) when `Menagerie.can_catch` (tamer, run-away chance over 80%, not a boss, goblin, horde or person). Chance 25% + 3%/point over 80 (+20 Whisperer), fail = free hit.
   - **Pets are never lost:** on a full wipe, pets on the run get `hurt` = 10 floors; they rest as floors are cleared or the Clinic heals them (40 gold × floors left × level).
   - **Eggs:** safe at home, hatch after 10 cleared floors into a random zone monster (tier roll). Sources: WANTED/hunt contracts 4% ("a nest was found", mailed), Snik 3% ("Strange Egg"), sparing a wild beast 0.4%, `give_reward({"egg": 1})`. Egg icon drawn (glowing eyes in the crack, talons; Juzo asked for scary eyes and claws).
   - **UI:** Hero > Pets tab (always visible; class companion card moved here from Party; owned pets with Coming/At home and Rename; eggs; hint cards). Town > Clinic page (hidden until you have a pet or egg). Map: a fenced pen with a green-cross sign over the garden plots, pets wander in it.
   - Fixed an old bug: the town shader ignored shape colors, so walker shadows drew white.
9. **DONE: Calamities and bound items** (9b5ae8d)
   - `GameData.MYTHIC 8`, `UNIQUE_MYTHIC 9` (all rarity arrays extended; sell/scrap value 0). Bound items (`bound` = soul/account) can't be sold, salvaged, bulk-sold or bulk-salvaged; Account-bound can't go in the stash. Item text shows binding and `history`.
   - `calamity.gd`: 10 Calamities (one per region, `LIST`), `CHANCE` 0.005% per fight, tuned like a floor-2000 boss × 60 HP and one-shot attack. `calamity_pending` pauses turns; main shows "A CALAMITY APPROACHES" with Fight / Run (50%). Losing → `Calamity.knockout`: black screen, wake on the same floor, nothing lost, not a death (also for companions). Drawn as a dark silhouette with a crimson edge, 1.35× size.
   - Kill → `on_slain`: 6 pieces mailed (5 Mythic Soulbound, 1 Unique Mythic Account-bound with two effects, `registered` hero, `history`), a tier-5 pet, a title (`codex.extra_titles`), max rep with every race, recorded in `profile.calamities` (local until the server owns "gone for everyone").
   - Dev menu: "Summon this region's Calamity".
10. **DONE: Save reset** (11b52a2)
   - `Profile.SAVE_EPOCH 12` + `save_epoch`. `main._fresh_start_check()` wipes old heroes, the legacy saves and the codex once, resets progress (keeps settings, online login and name), shows "A fresh start". New installs start at epoch 12 quietly. `tests/fresh_start.gd` covers it.
   - 0.12 is named "The Deep" (patch notes and the title-screen card).

**Stage 1 is complete and committed locally. Waiting for Juzo to say "install it".** At install: work out which files changed since the PC's version (compare against the PC copy), zip them, commit to Downloads and extract into C:\gamedev\solaria. Note `art/town/town.json`, `art/consumables/egg.png`, and new scripts (menagerie, pet_tab, clinic_tab, calamity) need Godot to reimport.

Juzo also added the room layout (blank doors, random rooms, traps, hidden town entrances that become fast travel points). That's in the design doc under "The dungeon layout" and belongs to stage 2, the room view.

## Notes and decisions made while building
- **No separate Bank page.** In town your purse is the Bank, and the carry choice is made when you head down.
- **Spending in the dungeon** (respec, events, Snik) uses carried gold only. That's intended: the Bank is at home.
- **Potions and Return Scrolls are lost on death** (Juzo, 10:04 PM), along with active elixirs, luck and hunt effects (21c823e). Respec tomes stay.
- **Eggs are safe** (kept at home, not lost on death), since pets are always safe.
- **A fallen leader keeps the team's gold and bag** while the companions fight on; those are only lost if all three go down.
