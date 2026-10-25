# License audit for the App Store (decision D1), 25 Oct 2026

Branch wt/license from big-update 0a116210. D1: no CC-BY-SA / GPL LPC art and no non-commercial leftovers in the shipped game. The full source table is in claude/licenses-audit.md.

## Removed now (it was not used)
- **The old top-down town pictures**: art/town/town_{spring,summer,autumn,winter}.png. These were the only art made from [LPC] City Outside and LPC Tile Atlas (CC-BY-SA 3.0 / GPL 3.0) and from LPC Revised. town.json has `"iso": true`, so the game only draws the PixelLab iso town (art/town/iso). town_view.gd `_season_tex` now returns null if a picture is missing.
- **tools/town_compose.py**, which built those pictures from the LPC packs.
- **LPC-built monsters**: the `Lpc.MONSTERS` table, `Lpc.monster_spec` and the fallback in `Sprites.enemy_by_key`. Every key already had its own art/enemies picture, so the LPC version was never shown. tests/lpc_monsters.gd was removed too.
- **Credits**:
  - The LPC Revised, [LPC] City Outside and LPC Tile Atlas entries are gone from credits_data.gd.
  - The LPC entry now says it covers the townsfolk walkers.
  - "Solaria original art" now names the PixelLab art: heroes, people and keepers, the town, rooms, props and baby pets.
  - art/town/CREDITS.md and art/lpc/CREDITS.md were rewritten, and credits.gd was regenerated. tools/make_credits.py now writes UTF-8 with LF line endings and keeps its header, so it reproduces the file exactly.
- Already gone before this pass (ad93ac67): tools/fx_extract.py and the old art/hero folder.

## Still shipped and still LPC (left as asked; town dev 2 is switching them to the new heroes)
- **art/lpc**: 2743 files, 23 MB, including the CC-BY-SA/GPL-only parts.
  - It is loaded only by `Lpc.build_walker`, from town_view.gd `_make_folk` (the FOLK townsfolk) and `set_heroes` (your own heroes walking in the town). `set_heroes` can use any hair or gear part, so the whole folder is still needed until the switch.
- **Dead fallbacks**: `Sprites.hero` / `hero_back` use LPC only when `HeroArt.available()` is false, which happens only if art/heroes/heroes.json is missing. That never happens in the shipped game.
- **Code-only names** in lpc.gd: `HAIR_ORDER` (= `Sprites.HAIR_STYLES`), `CREST_ORDER`, `GOLEM_HAIR`, `FUR`, `CORE`, `attack_anim`. These are only names and numbers, with no art license, but they live in lpc.gd, so lpc.gd cannot be deleted as a whole.
- **After the walker switch, remove in one go**:
  - art/lpc and credits.gd.
  - The LPC credit entry and the "Townsfolk parts" section in credits_screen.gd.
  - tools/lpc_extract.py and tools/make_credits.py.
  - The LPC branches in sprites.gd (`USE_LPC`).
  - The LPC walker checks in tests/run_tests.gd (about lines 1025-1029) and stage6_credits.gd (`Credits.TEXT` contains "Redshrike").
  - Move the name constants out of lpc.gd first.

## Non-commercial leftovers
- Nothing is left in the repo's files. The "750 Effect and FX" pack is named only in claude/licenses-audit.md and in a test that asserts it is not credited.
- **Outside the repo**: C:\gamedev\solaria_sources\old_fx still exists (21 files, the BDragon1727 pack). It is not in the repo or the build. I did not delete it because it is outside the repo and the delete is permanent; that is Juzo's call.
- **Git history**: commits 2c53b8ea and earlier contain the pack. Never ship from them, and clean the history if the repo is ever made public.

## Export filter
- export_presets.cfg has one preset (iOS). It already excluded tests, proto, tools, claude (which includes claude/art_test), store and shots.
- I added `art_test/*, */art_test/*, _free_assets/*, */_free_assets/*, build/*`.
- Markdown, .py and .sql files are not resources, so they are not exported with `all_resources` anyway.

## tests/test_phase11.gd (7 failures): stale test, not game bugs
- **"Stat points into power are 0.1 each"**: the test hard-coded 0.1. `Races.POWER_POINT` has been 0.06 since v0.11 (eba50210). The test now uses the constant.
- **The vampire bite and the werewolf bite**: the test set `enemy_species` to shown names ("Strigoi", "Barghest"). Since the stable-ids change (aaeb3ace), `enemy_species` and `Races.FORMS[...]["biters"]` use monster ids ("strigoi", "barghest"). The game sets ids everywhere (game_state, halls, realms), so bites work in play. The other 4 failures were knock-ons of "never bitten": drink, cure started, cure trial and full moon. The test now uses ids.
- **One real small bug, fixed**: the Race tab tooltip printed "(each is worth 0.1)" with `%.1f` for 0.06. It now uses `%.2f`, which shows 0.06.
- phase11 now passes (0 failures) and runs in tools/check.sh as "phase 11".
