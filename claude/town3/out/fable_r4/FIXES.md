# Fable town review, round 4: what changed

All 16 items and both partials (3 → item 1, 11 → the ruin picture) are on wt/town2. Pictures 01-15 come from the composer: the day pictures are the game's base, and the dusk pictures add the lit overlay. 16-20 were captured in game at 430x932.

New pictures:
- **13:** the ruin at 4x.
- **14-15:** both empty lots by day.
- **16:** the first 1.5 s of a visit, then the square, zoom, hope path and corner.
- **19:** the level props, levels 1-3, at the Inn and the Guild.
- **20:** the dark zones in game: the Shadow Deep, Ember Halls and Flooded Depths.

1. **No flame burns by day.**
   - The torches' tongues are yellow, and the old flame rule only caught orange and red. compose.py `fire()` now takes the yellow tongue, the orange body and the dark red rim.
   - The gatehouse lantern's pale yellow glass counts as a pane, and its flame as the rim.
   - All nine of Fable's spots (wall torches, plateau torches, gatehouse lanterns) are dark bowls or glass in all six bases.
   - **Guard:** `compose.day_flames()` runs on every day compose in export_town.py. It fails the export if a bright flame pixel lies within 6 px of any light, except the forge (its light and the smithy's own box) and the blue portal and beam. A test checks the shipped bases the same way. Checked both ways: the day bases pass, and the lit pictures fail it.
2. **Lit windows survive the night grade.** The SHADER uses Fable's two lines: `lit = smoothstep(0.3,0.5,r-b) * smoothstep(0.6,0.8,lum)`, then the dark grade times `(1 - 0.75*lit)`. Panes and flames keep about 80% of their light; roofs and the blue beam don't change. Picture 20 shows the three dark zones in game.
3. **A clamped plate can't steal a tap.**
   - `TownView.clamp_plate(rect, view, building)`: if pulling a plate into the view moves it off its own building (grown 8 px), the plate is hidden instead. `_plate_shown` treats an empty rect as hidden.
   - A plate that wasn't moved always stays. The Bounty Board's plate sits 8 px above its tap area by design.
   - **Test:** the view is swept over the town (430 and 375 wide, 2x and 3x, a 60 px grid). No moved plate leaves its building, and a building wholly in view always keeps its plate.
4. **No more pile-up at the Inn door, and a new cast each day.**
   - New walkers start about town: 45% on a stall, the well or a board (facing it), 35% on a street cell, 20% at an Inn door. Each fades in after 0.2-2.5 s. Picture 16 (start1, start2) shows the first second and a half.
   - `TownView.cast()` picks six of the twelve PEOPLE by the day (the same cast all day), with no race twice among any three in a row. So the Fairy Mage, Dragonkin Knight, Angel, Demon, Undead and the second Human now walk too.
   - Still 6 townsfolk and 10 walkers on screen. Every walker is drawn with HeroArt looks, so 0 generations.
5. **Hardcore walkers stay out of the ruin and the Vault.** The `TownView.enterable(id, hardcore, built, hidden)` helper is used by `_pick_goal`. In Hardcore, `set_mode` makes the church door a stop facing the ruin, so people stand and look at it.
6. **Nothing on the Tavern chimney.**
   - The flame "on the chimney top" in 07 was two things. The brazier pillar at (21,10) moved one cell south-east to (22,10), its light with it. The torch on the stair rail (20,8, 12 px up) is gone; the plateau torches and the braziers light the stair.
   - The four braziers were also missing from the game's base: the composer left out every props_up, but their lights still glowed in game over bare paving. They're town dressing, so they're in the base now (`decor.BRAZIERS`) and their occluders come with them. Picture 07 shows the clean chimney.
7. **Empty lots read "build here".**
   - A yellow 28x17 sign on a post with hazard strokes (props48/p20), and a stack of three planks (p21), drawn in fix_r4_art.py. Pictures 14-15.
   - The old lot's lantern post was a props_up, so the game never drew it. The sign replaces it and its light is gone.
   - The plate reads "Church · lot" in the locked grey.
8. **Level props in pictures and tests.**
   - walker_capture.gd sets levels 1-3 and captures the Inn and the Guild, centred on their level props. Picture 19 shows them, small at 2x: scaffold and timber by the porch at level 1, the lantern post and sign at level 2, banners at level 3.
   - refresh_levels skips a null level texture instead of crashing on `get_size()`.
   - A test checks every occluder (day and lit), level prop, base, overlay and second flame frame exists.
9. **The town moves.**
   - (a) The forge chimney smokes in every look: 4 puffs, using the existing smoke draw.
   - (b) Two flame frames: the export writes `town_*_lit2.png`, where each flame tongue near a flame light reaches 1 px higher and burns brighter. town_view swaps the two 4 times a second. Each is ~50 KB.
   - (c) The river: pale 2x1 dashes drift down the water at 6 px/s and fade at each cell's ends, under the walkers and off the bridge.
   - I used one dash per 4 water cells rather than Fable's 6 per 100. At 6 per 100 the whole river gets 4 dashes and a phone view shows about one.
10. **Roster walkers refresh.** The key hashes the roster (`hash(_roster_cache)`), so a slot refilled by a new hero rebuilds the walkers.
11. **Pets keep to the pen's free cells.** town.json `pen_cells` now lists the 14 free cells (not the kennel or hay cells). Pets pick a cell centre with 6 px of jitter, and have a 16 px shadow under their 32 px art.
12. **Glow matches the windows.** `TownView.glow_alpha(dark) = 0.2 + 0.3 * smoothstep(0.1, 0.5, dark)`: 0.35 at the rainy 0.3, 0.5 at 0.75 as before. Tested.
13. **Lot plates.** Both lot plates sit on the lot's lower half (lot centre + 16 px; the Church's is now [596,440]), clear of the Blacksmith's. The overlap test checks each lot plate with its " · lot" text against every other plate at 20 and 22.
14. **Town sounds.**
    - TownView emits `zoomed(z)`, `chatted(pos)` and `door_used(id, pos)`.
    - main.gd plays a click on zoom (pitch 1.3, -8 dB), a low "tap" murmur on a chat (pitch 0.6-0.7, -14 dB) and the door sound (-10 dB). Chat and door sounds play only when on screen (`TownView.in_view`).
    - `Sfx.play` takes an optional dB offset.
    - There's no new "mumble" clip; it would be a recorded or generated sound, which is outside this round.
15. **No measuring on every mouse move.** Plate widths are cached per (label, font size) and cleared when the look changes. Hover, taps and drawing all use the cache.
16. **Tests** (town_logic.gd):
    - (a) every picture exists;
    - (b) lot plates in the overlap test;
    - (c) a clamped plate stays on its building over the swept views;
    - (d) `chat_ok`: no chat with a walker between cells, yes with someone standing or on a cell, no across 22 px;
    - (e) no flame by day in any shipped base, plus the export-side assert;
    - (f) `enterable` for Hardcore, regular, lots and hidden buildings;
    - the daily cast (six different, mixed, a new cast most days, the same all day);
    - the glow curve.
    - 0 failures.

**Round-3 partial 11, the ruin:** picture 13 is the ruined Church at dusk, 4x.
- The crows are bigger now: a 5x3 body with a raised head and tail, a pale eye and a 1 px moonlit back. On the broken tower top they read against the night sky.
- The rubble and the fallen cross are in the sprite, at the forecourt's foot. In the town, the Inn wing's roofs stand in front of that ground from this camera, so no view shows them. Moving them onto the tower face would be wrong (they lie on the ground), so I left them.
