# Fable town review, round 3: what changed

All 16 items are on wt/town2, including round 2's four leftovers (6 → item 11, 8 → item 8, 11 → item 1, 13 → items 6 and 7). Pictures 01-12 come from the composer: the day pictures are the game's base picture, and the dusk pictures add the lit overlay. 13-15 were captured in game at 430x932.

1. **No Market plate.** The Market has `"plate": null`, the Mailbox rule. Its tap is the whole square, and the Map button names it.
   - The new test (no plate over a stop's head box, at 2x and 3x) also caught the Vault's and Clinic's plates over stall-goers. Both now sit on their roofs: Vault [851,690], Clinic [628,652].
2. **Less blank canopy, more outside.**
   - clamp_view lets at most 35% of a view corner leave the diamond (it was 50%).
   - The river runs 4 cells past each culvert as a stream fading into the grass, with the trees kept off it.
   - Outside the walls, within 80 px: a woodcutter's stump and log pile (north-west), a standing stone (north-east), and a gibbet cage by the gate road.
3. **Day is day.**
   - The game's base picture is now the day: lit panes become glass (#3a4660 with a #6b7a95 top-row highlight, including the warm rim within 2 px of each pane's bright heart), and torches, braziers, lanterns and lamps lose their flames. The forge still burns.
   - The export composes each state twice and keeps what lights up as `town_*_lit.png`, a sparse overlay of about 50 KB placed at `lit_pos`. town_view draws it under the walkers when the look's dark > 0.1.
   - Occluders carry a lit texture where they differ, so a walker passing behind a lit window keeps the window lit at dusk.
4. **Pixel glow.** `fx.texture_filter = NEAREST`, so the light texture's five hard steps stay hard.
5. **Pinch keeps the point.** `TownView.zoom_pan(at, m, z, cs)` uses the scale actually drawn (`round(z*cs)/cs`), not the nominal zoom. Tested for cs 1.488 and 2.56 at 2x and 3x.
6. **Chats happen on cells.**
   - A chat is only tried right after a walker reaches a cell, so the walk on afterwards follows the grid.
   - The partner may be standing (at a stall, the well, a board) or walking but on a cell. A standing partner keeps its own wait if that is longer.
7. **Bubbles and chevrons over the head.** TownFolk.walker returns `"head"`, the sprite's own top row. The bubble, chevron and inside-marker sit 8 px above it, so short sprites no longer have a bubble floating a head above them.
8. **The Bounty Board stands free.**
   - Fable's cell (21,7) is the top of the plateau (PLATEAU 13-26 x 1-7), not the lane, so the board can't stand there.
   - It moved instead to (17,8), west of the stair foot, where nothing stands in front of it and it is clear of the Tavern roof (06).
   - Its stops are (16,9), (17,9) and (18,9), facing it. (22,8) is back on the walk grid.
9. **Wall variety** (fix_r3_art.py).
   - Three run variants, picked by position: moss at the foot / moss on the left third with a cracked block / no moss, with a drain hole and stain.
   - The middle run of each side has an arrow slit.
   - Mirrored runs vary too.
10. **A muted river.** Water 30% less saturated and 15% darker, dashes #6fa2b0 instead of white, and a 1 px dark line on the south bank.
11. **The ruin's details read at dusk.**
    - Rubble: 8 blocks in the wall's light stone (#8d8f99) with #4a4c58 shadow rows.
    - The fallen cross: light stone on 2 px of dark earth.
    - The crows: 3x2 pure black with a pale eye, perched up against the sky.
12. **Graveyard scale (Hardcore).** A sarcophagus (24x20), an obelisk (16x28) and a mausoleum front with an iron door against the north wall, in free cells. The 49 graves are unchanged.
13. **Per-frame waste.**
    - `_live_occluders()` runs once a frame and is passed to every `_cover` (walkers and pets).
    - Weather counts are a `const WANT`, and dead particles are removed in place.
    - The lit overlay is looked up only when the mode or look changes.
14. **Wall shadows outside.** A 4 px band at 25% under the outer south-west and south-east faces, 6 px under the corner towers.
15. **Smoother first second.** Walkers are built one every third frame (Fable's second option). A WorkerThreadPool build would race HeroArt's static caches, which the battle screen uses at the same time, so I didn't do it.
16. **Tests.**
    - Every stop faces a non-walk cell within 24 px of its face_x. This caught the training-ring gate; each gate cell now faces the dummy or rack beside it.
    - No plate over a stop's head box, at 2x and 3x.
    - The pinch keeps its point.
    - The plate overlap test runs at font sizes 20 and 22.
