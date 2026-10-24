# Town handover (town2 session, Oct 24 2026)

Juzo is restarting the town in a fresh session. Everything below is in `claude/town2/` on
branch `wt/town2` (worktree `C:\gamedev\solaria_wt_town2`). Nothing in the game uses it yet:
`art/town/town.json`, `town_view.gd` and the old season pictures are unchanged.
Juzo's words are also logged in `claude/research/art-ratings.md` (rows marked town2).

## What Juzo approved (keep and build from)
He showed these himself as the target: "why cant it look this good".
- **Isometric buildings**: PixelLab pixen, 128x128, transparent, `view high top-down`, `selective outline`, `highly detailed`.
  - Approved originals: `gen/inn_iso.png` (Inn), `gen/inn_iso2.png` (second Inn look or a house), `gen/house_iso.png` (cottage; door on the RIGHT face), `gen/smith_iso.png` (Blacksmith), `gen/gate_iso.png` (dungeon entrance).
  - Made later in the same style, never rated on their own (they only appeared in the last layout): `gen4/shop.png`, `gen4/tavern.png` (Fortune Wheel on the front), `gen4/church.png` (holy look), `gen4/guild.png`, `gen4/vault.png`, `gen4/clinic.png`.
  - The prompt template that matches: "dark fantasy medieval <building>, <details>, top-down three-quarter view RPG town building, weathered dark wood and grey stone, muted desaturated colors, single building isolated" (seed 11-16). 1 generation each.
  - Doors are on the LEFT face (it looks toward +j in iso.py) unless noted; mirror a sprite to swap faces.
- **Tree sheet** (Juzo: "the trees look good"): `gen/trees/t0..t15.png`, 48x64. Oaks 0-3, dead 4-7, black pines 8-11, willows 12-13, dead/willow 14-15.
- **Prop sheet** (he showed it as good): `gen/props/p0..p63.png`, 32x32. Contact sheet: `blockout/props_sheet.png`.
  - Barrels 0-7, crates 8-15, lanterns 16-23, signs 24-26, graves 27 and 40-43, notice boards 28-30, wells 32-35, troughs 36-39, scarecrows 44-47, hay 48-49, sacks 50-52, carts 53-55, wood 56-58, fences 59-61, wheels 62-63.
  - Drawn at 3/4 size in the iso town so they sit below the doors.
- **Iso direction overall**: "i like it it needs major cleanup".

Pieces made to match, never rated on their own:
- Watchtower `gen3/tower.png` and sealed gatehouse `gen3/gatehouse.png` (pixen, same template; door/arch on the RIGHT face).
- Wall block `gen3/wallblock.png` (create_isometric_tile, block, 32 px; stacked two high in code, toned grey).
- Iso ground tiles `gen3/iso/tile_0..15.png` (create_tiles_pro, isometric 32 px: grass 0-3, cobble 4-7, mud 8-9, puddle 10-11, flagstone 12-13, leafy grass 14-15).
- Townsfolk, 24 px PixelLab characters in 8 directions (Juzo asked how people fit; they fit at about door height):
  - `gen3/folk/woman_*.png`: character 9ceab403-15ef-4ac7-8c64-90e63d999afb.
  - `gen3/folk/oldman_*.png`: character 94336c26-1333-48c5-8579-07c4faed568a.
  - `gen3/folk/hero_*.png`: character b62761bc-b6cf-4104-806d-90cf415dd9c0, with a 4-frame walk on the 4 diagonals in `hero_walk_*`.
- Grave set (48 px, 25 pieces) `gen2/graves/g0..g24.png`, sheet `out/graves_sheet.png`: headstones, crosses, fresh mounds, open graves, candle shrines 8/18, angel statues 4/14, iron fences 5/15, prophecy tablet 6 and obelisk 16. At 48 px they are too big for the iso town; the 32 px graves in the prop sheet fit it.

## What Juzo rejected, and why
- **Front-facing 3/4 town at 16 px tiles** (`out/sample_*.png`): no score. He later said he liked "the initial mockup more, those were exciting", meaning the first isometric buildings above.
- **Hero-scale front-facing town** (`out/sample2_*.png`): approved buildings enlarged 2.75x and redrawn, on 32 px tiles. Verdict: "hate the look", "dungeon looks bad", "the grass looks bad the town looks bad", trees and props "dont look placed right". Lesson: enlarging small PixelLab art and redrawing it loses the detail; keep buildings at their native 128 px.
- **Iso layouts 1 and 2** (`out/iso_*`, `out/iso2_*`): "placement of everything is off". He then picked:
  - "Pasted-on buildings": PixelLab bakes a grass or dirt slab under each building; `deslab.py` removes it.
  - "Walls too blocky": full-block merlons looked like toy bricks.
  - "Too empty / spread out": big bare grass and a forest blob.
- **Iso layout 3** (`out/iso3_*`, `layout2.py`): all 11 buildings, slabs stripped, slimmer walls, 3-tile streets. Verdict: "Still off" (no detail given), then the restart.

## Lessons for the next attempt
- Text-only pixen/pixflux buildings come out isometric. That was what Juzo liked; don't force front-facing.
- `create_image_pro` gives great value for small things: 32 px props (64 candidates) or 48x64 trees (16 candidates) for 10 generations.
- Standard topdown Wang tilesets came out garish; iso tiles from `create_tiles_pro` with a palette fit better.
- Place by each building's measured base corner on the grid, doors onto streets. Iso roofs are tall and hide what is behind them, so streets need 3 tiles and buildings about 1.5 tiles apart.
- Scale: these buildings have about 18 px doors, so heroes in town must be small walkers (24-32 px). The style bible's single 3x scale doesn't fit this town; the lead and Juzo need to settle that.
- PixelLab allows 8 jobs at once across all sessions; submit one at a time when busy.
- Spend by this session: about 125 generations.

## Tools in claude/town2 (Python 3 + Pillow; run from that folder)
- `iso.py`: iso ground, walls, contact shadows, fog outside the walls.
- `layout2.py`: the last full layout.
- `deslab.py`: strips baked ground slabs.
- `compose.py`: `dusk()` and `day()` grades with warm window glow.
- `clean.py`: flood-fills a solid background to transparency.
- `walkgif.py`: phone walking clip.
- Older front-facing tools (rejected direction): `blockout.py`, `compose.py sample` and `sample2`.
- Run the last layout: `py layout2.py out` writes `out/iso3_*.png`.
