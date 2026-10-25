# Fable town review, round 1: what changed

All 10 fixes are on wt/town2. Pictures 01-12 are from the composer; 13-14 were captured in game at 430x932.

1. **The Tavern no longer collides with the plateau.**
   - The Tavern moved down and right to lot (27-31, 14-18), with its door on the east cross street at (29,19). The stair foot is now on clear street (06, 07).
   - The Bounty Board sprite (props48 #6, a post with planks and pinned papers, 40x41) was already there at (23,8). It was hidden behind the old Tavern roof, and it now stands free beside the stair foot.
   - Its door (22,9) and stops are on the lane in front of it.
   - The old Tavern lot is a small fenced public garden.
   - Occluders were rebuilt, and 17 stale occluder pngs were removed.
   - New test: no two building tap areas overlap. The export trims the one behind; the building drawn in front keeps the overlap.
   - Deviation from the brief: the test leaves out the Market and the two small points. The Market is the square under everything. The Bounty Board and Mailbox already win taps inside a building's area by being the smaller rect, which is how `_spot_at` picks.
2. **Walkers climb the hope path.**
   - town.json `raised` is now `[i, j, z]` per cell, measured on the sprites:
     - (19,8) at 12 px, halfway up the wide stair
     - (19,7) and (19,6) at 24 px, the plateau top
     - (19,5) at 30 px and (19,4) at 44 px, the dungeon's own steps up to the portal
   - The Dungeon door is (19,4), at the portal.
   - Walkers on the path sort by the ground under them and are never covered by the dungeon sprite they stand in front of (GIF, strip frames 4-5).
   - The Dungeon plate sits above the portal.
   - New tests: no two name plates overlap at 2x, and the Dungeon door is up the stairs and on the walk grid.
3. **No more pan into the void.**
   - The view centre is clamped to the town's diamond (|dx|/hw + |dy|/hh <= 0.92), on top of the picture clamp.
   - The composer paints dusk ground over the whole picture: darker and foggier each cell out, with a dark wood thick behind the north walls and sparse and far out in front of the south ones, so the walls stay clear. The gate road runs off into it.
   - Strip frame 6 is panned hard into a corner.
4. **Whole device pixels.**
   - `scale_f = round(zoom * cs) / cs` and `origin = round(pan * cs) / cs`, where cs is the viewport's final transform scale.
   - The walker shadow is a 2-row pixel ellipse texture.
   - Wisps, smoke and motes are pixel squares on whole map pixels, and fog is drawn as low hard-edged bands.
5. **Doors and the marker.**
   - Church door: (5,14), in front of its arched door. Its facade sits about 3 cells back in the lot, and the forecourt now reaches it through (6,14).
   - Inn wing: the sprite is flipped, so its drawn door faces the Inn yard, and inn_doors[1] is (11,14), in front of it.
   - `_pick_goal` skips doors of hidden spots and of an unbuilt Church or Trophy Cabin.
   - The hero marker is drawn before the cover, so it hides with the walker behind a building.
6. **Lights.**
   - Each light uses its own colour and radius, as 5 rings at rad*(0.3+0.175*i), so the portal and the stair glow blue.
   - Lights off screen are culled.
   - The composed portal glow on the stairs is softer, so the steps read as stone, not water.
7. **Plates.**
   - A spot can carry `"plate": [x, y]`. The Market's sits by the well, the Dungeon's above the portal, and the Bounty Board's above the board.
   - The Mailbox has `"plate": null`, so no plate; its tap and the badge on the Mail button stay.
   - An unbuilt lot's plate sits on its ground (`lot_plate`) instead of in the air.
8. **Stone walls** (fix_r1_stone.py, originals kept as art/orig_*.png).
   - Curtain walls: 2-tone stone courses with 1 px dark mortar every 6 px and staggered joints, a lit top edge per stone, a 4 px shadow under the battlements, and moss in low joints.
   - Plateau faces: stacked rock with uneven stones and moss.
9. **Dead zones.**
   - Guild training ring: a fenced dirt ring with 3 dummies, a shield target, a weapon rack, hay, a grindstone, a bench and a barrel. A gate path runs down to the north lane, and walkers stop at the gate (09).
   - Church garden (Regular): the east half has a gravel walk to a bell shrine, hedges, a bench under the oak and potted flowers. The benches moved off the paths.
   - Orchard: 9 trees from 3 kinds, half mirrored, with loose jittered spacing, plus baskets, sacks and a wheelbarrow.
   - Fields: one crop per row, with a bare row, scarecrows, a cart, a wheelbarrow and a bucket. The plots behind the gatehouse alternate crops by half.
10. **Per-frame churn.**
    - Name plates redraw only when something they show changes (view, hover, badges, locks, notes).
    - Four StyleBoxFlats, one per state (normal, hot, locked, note), are made once in _ready instead of per plate per frame.
    - Folk are insertion-sorted in place.
    - walk.keys() is cached.
    - Lights and weather particles are culled off screen.
    - The up/*.png textures are preloaded in _ready.
    - Walkers and fx still redraw every frame, because they move and flicker.

Also in this commit:
- **The town walkers are the PixelLab heroes** (TownFolk, c488000c), so the "not counted" LPC note is resolved. They now really walk with hero dev's `HeroArt.steps()` (idle, left step, idle, right step), built once per look.
- **Juzo's caps** (town_view.gd constants):
  - `MAX_FOLK = 6` townsfolk. The first six of TownFolk.PEOPLE mix Human, Dwarf, Elf, Orc, Goblin and Beastkin, 3 women and 3 men.
  - `MAX_WALKERS = 10` in all. Your heroes fill the rest: you first, then the roster, so at most 4.
  - `MAX_TOWN_PETS = 4` in the pen: your class companion, then the pets you take on runs, then the rest. Never the whole collection. main.gd orders them and town_view caps them.
  - Before/after on the square: 17 (before: 12 townsfolk + 4 heroes), 18 (after), and 19 side by side.
- **A stray error**: `_plate_shown` no longer builds a negative Rect2 before the view is laid out.
