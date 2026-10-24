# One portal system (2.1, F3)

Systems Designer, Oct 23 2026, branch `wt/portals`. Code: `portals.gd` (new), `rifts.gd`,
`halls.gd`, `realms.gd`, `town.gd`, small hooks in `game_state.gd`. Test: `tests/stage6_portals.gd`.
Decision followed: "keep realms plus one rift type with depth levels (merge Rifts and Deep Rifts)"
(update-2.1-ideas.md, Oct 20).

## Before: every portal-like thing in the game

| Feature | Where | What it did | How you got in / out |
|---|---|---|---|
| Hidden portal (Rift) | rifts.gd, halls.gd "rift" room | 1.5% of doors from floor 10 (never before a boss): a room with a violet oval. 3 fights you can't run from (2 Epic, then the Legendary Vault Keeper, 1.25x HP), then a vault (2 Epic+ items, 6x gold, 3 dust). Floors don't move. | Tapping the rift entered at once (no choice, no info). Out: the vault, a fall, or a Return Scroll. Banner "HIDDEN PORTAL". |
| Deep Rift | rifts.gd | From floor 30, 30% of rifts secretly became 3 pocket floors (+15% HP per floor, 25% heal between), vault x3 gold, 6 pieces incl. 1 Legendary. | Rolled only *after* stepping through: the player never knew beforehand. Banner "DEEP RIFT". Separate Codex counter and deeds ("Clear 15 Deep Rifts"). |
| Realm portals | realms.gd offer_portals / enter | Floors 251-500: after each ruler, up to 3 portals to realms you haven't entered (race/faith bias, locks). | The path-choice panel ("Choose a realm"), own card code and own danger line; gold-colored log line. |
| Trials | game_state start_special_trial; race_tab (awakening), hidden.gd (champion classes), lineage.gd (Vampire cure) | One fight against a named champion; win = the thing it was for + gold; lose = back where you were, no losses (Hardcore: final). | Started from a page button. Town: "Finish the trial first." Return Scroll: blocked. |
| Return Scroll | town.gd use_return | Home right now, even mid-fight. | Worked in rifts ("The portal holds you. Only a Return Scroll gets you out before the end."), not in trials. |
| Floor picker / checkpoints | floor_picker.gd | The way down from town: last checkpoint, floor 1, or any reached floor; carry, team, presets. | Not a portal: unchanged. |
| Descenders' Camp, realm camps | camp.gd, realms.gd | Rest; the courier sends gold home. | Not travel: unchanged. |
| Calamity, Wanderers, Grave | calamity.gd, wanderers.gd, grave.gd | Encounters in normal rooms. | Not portals: unchanged. |

Wording was mixed: "hidden portal", "portal", "rift", "Deep Rift", "The rift holds you",
"The portal snaps shut", "Finish the trial first."

Bugs found on the way (all fixed, all tested):
1. Loading a save inside a rift spawned an ordinary monster that counted as a rift fight.
2. A realm choice was lost if you closed the game or walked home before picking: the realm
   was silently picked for you, and the next realm choice could reorder realms under your feet.
3. A trial started in town: going down replaced the champion with an ordinary monster but the
   trial stayed on, so beating that monster won the trial.
4. A trial could be started inside a rift (the rift then counted the wrong fights).

## After: one system

- **Three kinds, one word.** "Portal" is the system; the kinds are **Rift**, **Realm gate**, **Trial**.
- **One place to choose.** Rifts and realm gates appear as *portal cards* in the same panel
  (`Portals.offer` -> `GameState.path_offer` "portal:<key>" -> `main._show_path_choice`). Every
  card has the same shape: name, what's inside, a Danger line (same formula for all), one color.
  A rift card adds **Walk on**. Trials keep their start button on their own page (they belong
  to awakening / cure / class), but follow the same rules.
- **One rift type with a depth.** Depth is rolled when you walk into the rift room and shown on
  the card ("Rift, depth 3"). Depth 1 = old Rift, depth 3 = old Deep Rift. Same odds, same numbers.
- **One state and one exit path.** `GameState.portal = {"kind": "rift", "depth", "floor", "left"}`;
  `Portals.inside/kind/hold_text/no_run_text/open_block/leave/on_fall/lose_trial/leave_for_scroll/resume`
  are used by town.gd, lineage.gd (run/spare), peoples.gd, variants.gd, rifts.gd and the fall code.
  Removed: `Halls.leave_portal`, `Realms.danger_text`, `Town.PORTAL_BLOCK`, the realm card code.
- **Coming back.** `Portals.resume` runs after loading a save and when you go down from town: the
  rift fight starts again, an untouched rift's card comes back, a realm choice you never made opens again.

## Rules table

| | Rift | Realm gate | Trial |
|---|---|---|---|
| Found | ~1 door in 70 from floor 10, never before a boss | Floors 251-500, after each ruler | A champion's gate (~1 door in 70 while a trial waits for you) or its page |
| Opens | In the dungeon, one portal at a time | — | In the dungeon only, one portal at a time, not during a boss fight |
| Cost | Free | Free | Free |
| You choose | The door (always shown), then step through or Walk on (Auto: at half health+) | One of up to 3 gates (Auto takes the first) | The gate door, then its card, or its page button (Auto: awakening/cure only, 75%+ health, never Hardcore) |
| Inside | Depth 1: 3 fights; depth 3: 3 floors of 3, +15% HP per floor, 25% heal between | The next 50 floors (normal floors) | One fight |
| Run / spare | No / no | As usual | No / no |
| Go home | Return Scroll only (rift closes, no vault) | As usual | Return Scroll only (trial ends, try again later) |
| Floors | Don't move; you come out to your doors | — | You come back to the floor you left |
| Fall | Normal fall (grave, checkpoint, losses); the rift closes | Normal fall | No losses, full health, same floor |
| Hardcore | Final | Final | Final (unchanged; see open question 2) |
| Team | Leader falls, team fights on (as everywhere) | Same | A trial is your fight alone (unchanged) |
| Reward | Vault: (2 + 2 per extra depth) Epic+ pieces (depth 3: one Legendary), (10 + 8 x floor) x 6 x depth gold, 3 dust per depth | The realm's people, mechanic, camp, set, uniques | What it was for, plus (2 + best floor) x 200 gold |
| Close the game | Same fight / same card when you come back | The gates open again | The trial ends with no loss; start it again from its page |
| Codex | rifts_found, rifts, deep_rifts (= depth 3 cleared; stable id kept) | realms_entered | (its own feats) |

## What changed (balance numbers: none)

- Rift depth is rolled on entering the room instead of after stepping through (same 30% from floor 30).
- Rifts can now be skipped (Walk on). Auto still steps through.
- Return Scroll now also ends a trial (before: blocked). Losing a trial was already free, so this
  only adds a way out for Hardcore heroes.
- Trials can't start in town or inside another portal (fixes bugs 3 and 4); the page button says why.
- Run button in a trial says "No running in a trial" (was "You can't run from a boss").
- Rift banners and lines use one violet (`Portals.COLOR`).
- Deeds "Clear N Deep Rifts" now read "Clear N depth 3 rifts" (same counter).

## Player-facing text

- Rift card: **Rift, depth 1** "3 fights, then a vault. Danger: ..." /
  **Rift, depth 3** "3 floors x 3 fights, then a great vault. Danger: ..." (checked at phone size: shots/rift/rift_card.png, tests/_portal_shot.gd);
  **Walk on** "Leave it be. It closes behind you: no risk, no reward."
- Panel titles: "A rift (depth N)", "Choose a realm".
- Log: "A rift hangs in the air, depth N. Step through, or walk on?" / "The roots split open.
  Realm gates shimmer in front of you." / "You leave the rift be. It folds shut without a sound." /
  "The rift closes behind you." / "The trial fades around you. You can face it again later."
- Banners: "RIFT, DEPTH N", "DEEPER" (rift floor n of N), "THE VAULT".
- Hold lines: "The rift holds you: finish it, or read a Return Scroll." / "The trial holds you: win
  it, or read a Return Scroll." Run: "No running in a rift" / "No running in a trial".
- Can't open: "Trials and rifts open only in the dungeon. Head down first." / "Finish the portal
  you're in first." / "Not in the middle of a boss fight."
- Return Scroll prompt adds " The rift closes behind you: no vault." or " The trial ends; you can
  face it again later."
- New guide page **Portals** (Codex > Guide, unlocks the first time a portal card shows).
- Loading tip: "A shimmer in the air might be a rift. Its depth tells you how far down it goes."

## Juzo's answers (Oct 23) and what was built (wt/portals2)

1. Rift depth stays 1 or 3. 2. A lost trial stays final for Hardcore. 4. A trial does not survive
closing the game (ends with no loss). 5. Walk on is OK. 3 was built:

**Champion's gates: trials as portal cards among the doors ("three doors, your choice").**
- While a trial waits for you, about 1 door in 70 (1.5% per door, same as a rift, from floor 3,
  never before a boss) is a champion's gate. At most one portal door (rift or gate) per set of three.
- Which trial (`Portals.trial_offer`, same order as the pages): your next race awakening when only
  its trial is left; a Vampire cure you started and finished hunting for; a champion's hidden class
  (Gladiator) on offer at 15/35/75. Fixed when you walk into the room; if nothing waits any more the
  gate is dark and the doors open.
- **Portal doors always show** (`Portals.read_door`): "Rift" / "Trial" in portal violet, even for
  heroes who can't read doors (before: a rift door was blank unless a reader saw it). You pick that
  door or another one; in the room the card offers step through / Walk on.
- The card: **Trial: <champion>** "Win: awaken as X." / "Win: the cure." / "Win: become X, for good."
  + "Lose: no losses." (Hardcore: "Lose: your run ends."). Panel title "A champion's gate".
- Entering starts the trial exactly like its page (`start_race_trial`, `Lineage.finish_cure`,
  `Hidden.take`), marked `trial_data.gate`; win or lose, you come back out to your doors.
- The page buttons still work (no conflict: one portal at a time, `Portals.open_block`).
- **Auto** (`Portals.auto_wants/auto_pick/auto_door_score`, used by `auto_path` and `auto_door`):
  rifts when at half health or better (before: always); trials only for an awakening or a cure you
  started, at 75%+ health, never as Hardcore, never a class (that choice is for good). Otherwise
  Auto picks another door / Walk on.
- Save/load at a gate: the same trial card comes back.
- Test: tests/stage6_portals.gd (trial door only when eligible, door always shows, card -> trial
  through Portals -> back to doors, Auto rules, lost gate trial, Walk on, load at the gate, page still works).

No open questions left.
