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

## Built to scale (for growing after release)
1. **Stable IDs** for every monster, item, class and pet (today much is keyed by
   name: Codex bestiary, pet species, some classes). Story renames make this urgent.
2. Content as data: classes, unique classes, monsters, buildings, collections and
   Wheel prizes in tables, so new content is filling in a table.
3. Save versions with tested migrations (2.1 wipes; from 3.0 on saves must survive).
4. Remote settings once online is up: odds, events and switches from the server,
   no App Store review needed for a balance fix or a weekend event.
5. All on-screen text in one table (writing pass; translations later).
6. Screenshot checks: compare the screen tour with the last approved one each day.
7. Bake the art processing (palette, outline, rim) at build time, not every frame.
8. One event and season framework: weekly modifiers, holidays, seasons as data.
