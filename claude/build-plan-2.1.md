# Solaria 2.1 build plan (agreed Oct 20 2026)

Target: everything on claude/update-2.1-ideas.md, released **November 10**.
Build days: Sun-Tue (Oct 25-27, Nov 1-3, Nov 8-9). Playtesting the rest of the week.

## Order (dependencies first)
1. Foundations (Sun Oct 25): class rules (15/35/75, unique + God classes, cuts),
   the save wipe, the merges (gold/scrap/dust; one loot filter; one presets screen;
   one portal system; one pet system).
2. Features on top: nest pets, town building levels, Church + cursed loot, trophy
   cabin, Legendary Wheel table, collections, pet abilities, hidden-class hints,
   auto-dive settings, share card.
3. Art after systems settle (unify in code, license swap, icons; then motion).
4. Story renames, then the store face (icon, title, screenshots, preview video).

## Dates
- Week 1: get the TestFlight build working early (Apple account must be approved).
- **Nov 3: feature freeze** (only bugs, balance, polish after).
- **Nov 8: release candidate** to testers. Nov 9-10: buffer, fix, submit.

## Every build day ends with
All checks pass, commit, install for testers, a short plain-words "what changed"
list, and one batched review message for Juzo (sheets, screenshots, decisions).
Reality check: where we stand against this plan.

## Working smart
- Helpers (cheaper models) do data-heavy content in parallel (building levels,
  writing pass, collections, pet tricks); Claude keeps systems and design calls.
- Tunable tables, not hard-coded numbers; one balance file for the key numbers
  (drop odds, costs, power steps, nest odds, Wheel odds).
- An on/off switch for each big new feature: if one is buggy on Nov 9, switch it off.

## Fine-tuning
- Balance simulator: hundreds of headless runs per build day reporting time to
  floors 100/250/500/750, gold/scrap/dust curves, hero vs monster power.
- Tester run logs: a small file of each tester's dives (floors, deaths and killers,
  gold, time) they can send.
- Split game_state.gd (over 4,600 lines) into smaller files (one build day).
- Hunt down every flaky test once.
- Phone performance budget (frame time, battery) checked by the perf run.
- Patch notes drafted from each day's changes (What's New writes itself).
