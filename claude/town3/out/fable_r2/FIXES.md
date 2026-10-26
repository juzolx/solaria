# Fable town review, round 2: what changed

All 17 fixes are on wt/town2. Pictures 01-12 come from the composer (the same base picture the game uses, graded day / dusk). 13-15 were captured in game at 430x932.

1. **Daylight exterior** (compose.py `outside`, `outside_trees`).
   - The country outside the walls is painted in daylight: grass 15% darker than the lawns inside, the same tree kinds as the orchard, and light fog only past ring 9. The game's look shader darkens it at dusk, so 02 and 03 show what the phone shows.
   - The gate road runs out as a dirt track with two cart ruts for about 120 px before the trees close in.
2. **Level props stand off the street.**
   - town.json `levels` entries now carry the street cell each prop stands on: `[file, x, y, level, i, j]`.
   - `TownView.refresh_levels()` runs from main._sync_town and only does work when a building's level changes. It takes those cells off the walk grid (`blocked_walk` never cuts a door or stop off from the Inn), caches the props to draw, and adds each live prop as an occluder, so walkers pass behind it.
   - The Clinic's props were the only link to its door along the wall lane. They now stand east of the door.
   - New test: at levels 1, 2 and 3, no prop's cell is walked through and every door and stop stays reachable. Street lamps were already taken off the walk grid by the export, which removes the cells of big props.
3. **Real steps** (hero_art.gd `steps()`, hero dev told).
   - On a step frame the body rises 2 px (1 map px after halving), and the lifted foot swings 2 px forward as well as up.
   - The walk frame is driven by distance: one frame per 4 map px walked, so the feet stay planted. Speed is 26 px/s.
   - The shadow narrows to 10 px on step frames.
4. **The view rect is clamped, not just its centre.**
   - `TownView.clamp_view` keeps |x|/hx + |y|/hy <= 1 - (hv.x/2/hx + hv.y/2/hy), with hv the half view. A view wider than the town falls back to the old 0.92 centre rule.
   - A plate shows only when at least 30% of its building's rect is on screen.
5. **Whole device pixels from the screen.**
   - `TownView.snap_origin(global position, pan, cs, window offset)` rounds the map's position on the screen, not inside the panel.
   - The map is laid out again when the view moves in the UI (NOTIFICATION_TRANSFORM_CHANGED).
   - New test: whole device pixels for cs 1.488 / 2.56 / 3 at odd UI offsets.
6. **The Hardcore church is a ruin** (prep_ruin.py).
   - The near nave roof has caved in: a ragged hole with the dark inside and three bare rafters.
   - The tower's break slants, because one side fell further, so it no longer reads as a crenellated keep.
   - Ivy climbs the tower's left face, a heap of fallen blocks lies at its foot, two crows sit on the break, and a stone cross lies fallen in the forecourt.
7. **Pets** are halved once with TownFolk.half (outline kept, cached per texture) and drawn 1:1 at whole map px. The hop is rounded, the shadow is the walker's pixel shadow, and the pets are sorted in place.
8. **No build hitch.**
   - Walkers are queued and built one per frame once the town is on screen (your heroes first), not in `_ready` at launch.
   - TownFolk.half works on raw bytes instead of get_pixel/set_pixel.
9. **The dead trees** in the Hardcore graveyard moved to (5,6) and (10,4) and use the narrower dead tree, so both crowns are clear of the walls.
10. **The Bounty Board** (fix_r2_art.py).
    - A new 56x64 board: two posts, a planked frame, a little shingled roof, and three 8x10 cream papers with red seals. One is a black WANTED silhouette.
    - It stands at (22,8), and its stops are (21,9), (22,9) and (23,9).
    - The Tavern chimney moved to the far gable.
    - Left over: at 2x the Tavern roof still hides the lower part of the board's posts, because the board stands behind the tall Tavern. The papers are fully visible.
11. **The Market plate** sits just above the well's roof: [740, 548].
12. **The stump** is on the river bank at (36,30), not in the water.
13. **Walkers interact.**
    - town.json `stops` are `[i, j, face_x]`. A walker who stops at a stall, the well, the board or the training ring turns to face it.
    - A chat shows a 7x3 "..." bubble over both heads. Heroes join chats; your own hero only half the time, so you keep moving.
14. **Hero markers** are 7x5 pixel chevrons with a 1 px dark edge (gold for you, pale for the roster), at whole map px with no bob. While your hero is inside a building, your chevron stays over its door at 50%.
15. **Lights** are one 64x64 texture with 5 hard steps each, drawn once per lamp and modulated by its colour, instead of 6 filled discs.
16. **The hope-path stair** (fix_r2_art.py).
    - The stone is 15% darker, with a dark shadow row under each riser and a lit front edge on each tread.
    - Moss grows in the joints, and a torch on the rail halfway up (with its own light) breaks the slab.
17. **Tests** (tests/town_logic.gd).
    - Plates are measured with the project theme's font.
    - A point must sit wholly inside at most one bigger building tap area. The export now trims buildings off the points, so taps are never ambiguous.
    - New tests for level props (item 2) and whole device pixels (item 5).
