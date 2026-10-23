# Solaria 2.1 dispatch plan (planner, Oct 23 2026)

Done Oct 23: class rules (15/35/75, God classes in god_classes.gd, cuts, save
wipe), pets from region nests, Credits & Licenses screen + licenses audit, art
audit tool + sheets, research (claude/research-2.1.md), balance simulator
(tools/balance_sim.gd, report claude/balance-report.md).

Balance sim findings (feed R5 + D10): floor 100 median 5.7 h (3.5-7.9 h); nobody
past ~111 in 10 h. Cliff at floors 51-100 (monster HP outgrows hero attack;
~7 deaths/hour, 76-100 takes 224 min). Casters thinnest. Death = naked restart
snowball. Dust has no sink, gold piles up, shop reroll (30 g) nearly free.
Boss cooldown uses real clock time.

Rule: game_state.gd is touched by everything; helpers add new files and only
small hooks there; the lead merges worktrees one at a time.

## Wave 2 (Oct 25-27, foundations)
1. F1 Stable IDs (monsters, items, classes, pets; names become display only). Merge first.
2. F2 Currency merge to gold/scrap/dust + economy sheet (after F1). Needs D3.
3. R1 TestFlight pipeline on Codemagic (Xcode 26+, hello-world first) + R2 privacy page. Needs D9.
4. G6 Wheel Legendary table + odds screen, then R3 age-rating answers. Needs D2.
5. A1 unify art in code + A3 license cleanup + A5 sound check ("art plumbing").

## Wave 3 (Nov 1-3, features; freeze Nov 3)
1. G1 town building levels -> G2 Church + cursed loot -> G3 trophy cabin (one agent). Needs D5.
2. G4 collection rewards + G8 share card. Needs D6.
3. G5 pet abilities by rank.
4. F4 loot filter + auto-dive settings, F5 one presets screen.
5. F3 one portal system. Side lane: R4 save safety, R5 balance pass. Needs D10.

## Wave 4 (Nov 8-9, release candidate)
G7 hidden-class hints, G9 onboarding + What's New, A6 motion/juice, A2 asset swaps,
R6 logs/perf, R7 store face, R8 story renames (after F1), A7 wide town only if ready.
F6 (split game_state.gd): after release (D7 recommended a).
Cut order if behind: A7, G9, A2, A6, G7. Keep F1, F2, R1-R5.

## Release risks
- Xcode 26 required since Apr 28 2026: first TestFlight build early (Juzo: Apple account, API key).
- CC-BY-SA / GPL LPC art (42 hero parts, 2 town packs) vs App Store: decision D1.
- Non-commercial FX leftovers: delete tools/fx_extract.py and solaria_sources/old_fx.
- Wheel odds screen from the same table the code uses; never sell spins.
- Age rating: infrequent simulated gambling = 13+ (Australia R18+); avoid casino words.
- Verify Godot's default font license (Open Sans OFL) against COPYRIGHT.txt.

## Decisions for Juzo
D1 LPC share-alike art: publish modified art under CC-BY-SA / replace 42 parts / replace all incl. town.
D2 Wheel Legendary table: unlock at a floor (e.g. 250) / one-off gold fee / extra row; spins never for money.
D3 Materials in the currency merge: convert to scrap+dust / display label only / drop rare costs.
D4 Hero pixel look: 2x like monsters / test 1.5x / keep 1x with outlines.
D5 Town buildings: levels 1-3 for all + Church + cabin / levels for Inn, Smith, Vault only / cabin+Church later.
D6 Collection rewards: titles / titles + cosmetics / titles + small stat bonuses.
D7 Split game_state.gd: after release / Oct 27 / Nov 4-5.
D8 Story timing: before Nov 3 / Nov 4-7 / after release; artist town: ship current town for 2.1?
D9 Apple Developer account paid and approved? App Store Connect API key into Codemagic (Juzo).
D10 Balance target: floor 100 in ~2 hours / ~5 hours / ~1 day of play.
