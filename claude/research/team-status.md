# Team status board (every session keeps up with the others here)

**Rules:** before starting each step, READ this board, `art-ratings.md`, `style-bible.md` and the latest `meeting-2026-10-24.md`. After finishing each step, UPDATE your own row (replace your row only; keep it to 1-2 lines: what changed, branch/commit, what's next, what you need from whom). If another session's change affects you (scale, palette, layout, file names, merged branches), adapt and note it in your row. Edit this exact file: `C:\gamedev\solaria_dev\claude\research\team-status.md` (the lead commits it).

| session | status (latest) | branch / commit | next | needs from |
|---|---|---|---|---|
| lead | Merged into big-update: ui (design system, readable battle names), pets2 (150 pets), slots (Ring/Necklace), onboarding/hints, juice, tune (Elite/scrap). Full suite ALL GOOD before pets merge. | big-update 95d04bf1 | merge halls + monsters when committed; run one-scale pass after hero lands | sessions: commit and ping when ready to merge |
| hero dev | Warrior tier sample done (base > 15 pauldrons > 35 cape > 75 ornate, 9 frames, consistent size), sent to Juzo; class sample (Warrior + Cleric, both bodies, real mace) rated good; ~280 gens used | wt/newart 74edb744 | Juzo rating; then batch 11 base outfits (~198) + level 75 versions (~234) | lead: one-scale battle switch (hero 60 px at 3x); town2: walker size (mini hero 24-32 px later); halls: 7 room people after outfits |
| dungeon dev (3D rooms) | All 10 zones' halls committed (2732388d); room props/traps + Juzo's 3 placement fixes coded, not yet committed | wt/halls | commit props, then merge review | monsters: matching palettes (zone-palettes.md) |
| monsters dev | Zones 0-1 + bosses in worktree with readability fixes; Sheet D (zone 2 + 4 bosses) awaits Juzo's ratings | wt/monsters (uncommitted) | ratings, zones 3-9, Calamities | lead: one integer battle scale decision |
| pets dev | DONE and merged (150 pets) | merged 95d04bf1 | idle | - |
| interface dev | Stone style picked; v3 mockups await Juzo's rating; branch synced to big-update | wt/interface | build the approved style | - |
| town dev 2 | Layout map sent to Juzo (Fiverr-artist reference), waiting for OK | wt/town2 | build exactly to the map | hero: small town walker |
| balance + cleanups (helper) | Started: sim rerun with Ring/Necklace, XP after floor 50 toward 4.5 h, small UI/pet/test fixes | wt/tune2 | - | - |
| lore + store (helper) | Started: lore draft from Juzo's story, App Store listing text | (docs only) | - | - |
