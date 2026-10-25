# Town Fable review, round 1 of 5 (Oct 25). Score 6.5/10

The reviewer looked at the out/optional 01-06 and round4 pictures and at the code on big-update 0a116210 (town_view.gd, town.json, tests/town_logic.gd, main.gd _build_town/_sync_town/_fit_layout, buildings.gd, town_map.gd).

1. **The Tavern collides with the dungeon plateau, and the Bounty Board doesn't exist in the art.**
   - In 03_town_day around (860-1000, 300-420), the gate rect in town.json:19 [907,327,178,170] ends at y=497, but the tavern rect in town.json:82 [886,458,...] starts at y=458, a 39 px overlap.
   - The bounty rect (town.json:250 [954,493,52,53]), its door cell (22,9) and its stops (22,8),(23,9),(24,8) all sit on the Tavern's upper-left roof and wall. There is no board sprite.
   - The plateau stair is cut off under the Tavern roof ridge, and the Tavern chimney butts against the plateau's retaining wall.
   - Fix:
     - Move the Tavern one lot down and right so the stair foot lands on clear street.
     - Paint a real notice board (post, planks and pinned papers, about 32x40 px) on the street beside the stair foot.
     - Set bounty.rect, its door and its 3 stops on the street cells in front of the board.
     - Rebuild the occluders.
     - Add a test that no spot rect overlaps another, except the market.

2. **The dungeon door and its plate are in the wrong place, and no walker climbs the hope path.**
   - The gate door [19,7] in town.json:19 sits on the Tavern roof ridge.
   - The raised cells (18-21,5-7) at town.json:2496 are not in walk (town.json:714), so walkers "enter the dungeon" by fading out on the Tavern roof.
   - town_view.gd:857-858 puts the gate plate at rect bottom+10, which is (996,507). That covers the top 16 px of the bounty rect. Plates take tap priority (town_view.gd:298-300), so a tap on the Bounty Board opens the floor picker.
   - Fix:
     - Add the stair cells and the plateau top to walk.
     - Set gate.door to the cell in front of the portal (about (19,5)).
     - Anchor the gate plate above the portal or on the plateau's lower-left corner.
     - Add a test that no two plate rects intersect at zoom 2.

3. **You can pan into the void.** In 05_phone_2x_gate, the bottom 45% of the screen is flat navy, because town_view.gd:260-262 only clamps pan_v to the 1480x1030 picture.
   - Fix:
     - Clamp the view centre to the diamond: c = to_map(size/2), with |c.x-740|/740 + |c.y-515|/515 <= 0.92. Do the same in _zoom_to.
     - Paint the outside of the walls with dark ground, trees and fog.

4. **2x is not an integer number of device pixels, so the town shimmers.**
   - The phone layout (main.gd:824, 504x896) gives a canvas scale of 2.56 or 1.49. town_view.gd:255 uses scale_f = zoom = 2, which means 5.12 or 2.98 device px per map pixel. town_view.gd:263 rounds the origin to design px.
   - The smooth draw_circle shadow and wisps (town_view.gd:614, 835-837) look like cartoon shapes under the pixel art.
   - Fix:
     - Take cs from get_viewport().get_final_transform().get_scale().x.
     - Set scale_f = round(zoom*cs)/cs and origin = (pan_v*cs).round()/cs.
     - Use a 2-row pixel ellipse texture for the shadow, and 2x2 or 4x4 squares for the wisps and motes.

5. **Walkers fade out into the Blacksmith chimney and onto bare dirt.**
   - The church door [7,13] (town.json:103) is the smithy chimney base, 50 px right of the church's real arched door (about (592,430)).
   - inn_doors [10,14] (town.json:2486) is the chimney's right foot, not an Inn door.
   - town_view.gd:112-113 adds every door regardless of state, so walkers "go inside" empty lots for an unbuilt Church or Cabin (_arrive 503-506).
   - town_view.gd:621-627 draws the hero marker after _cover, so the marker floats over buildings.
   - Fix:
     - Move church.door to the street in front of its real door (about (6,15)/(5,15)).
     - Move inn_doors[1] to the annex and paint a visible door there.
     - In _pick_goal, skip doors on unbuilt lots or hidden_spots.
     - Draw the marker before the cover, or not at all when covered.

6. **Dusk lights ignore their colour and radius, so the portal glows orange.**
   - town_view.gd:805-811 reads only l[0] and l[1], but the lights in town.json:292 are [x,y,[r,g,b],radius]. The portal and stair lights draw as orange discs over the blue beam.
   - Lights off screen are still drawn.
   - Fix:
     - col = Color(l[2]/255), rad = l[3].
     - Draw 5 rings: rad*(0.3+0.175*i)*scale_f, with alpha 0.05*dark*fl.
     - Cull lights outside the view.

7. **The Market plate sits on the Inn doorstep, and four plates pile up on the hub** (Blacksmith (630,413), Mailbox (708,462), Market (740,494), Inn (777,355)).
   - The market anchor (town_view.gd:854) covers the Inn porch at (740,528).
   - The Mailbox plate hides the mailbox and duplicates the Mail button (main.gd:1104).
   - Fix:
     - Let a spot carry an optional "plate":[x,y] in town.json, read by _plate_rect.
     - Put the Market plate at the well (about (740,600)).
     - Drop the Mailbox plate; keep its tap and the badge on the Mail button.

8. **The walls and plateau sides are flat slabs.** The front curtain walls are flat lavender with a few grey dots, and the plateau's retaining faces are untextured bands.
   - Fix:
     - Paint stone courses on the walls: 2-tone rows with 1 px dark mortar every 8 px, a 3-4 px shadow under the battlements, and moss and cracks.
     - Give the plateau faces stacked rock.
     - Re-export the pictures and the wall occluders.

9. **Dead zones and copy-paste repetition** in 03_town_day:
   - the Training yard (1180-1300, 400-480) is bare lawn with one tree;
   - the north lawn by the garden (650-900, 170-260) is big and empty;
   - the orchard (900-1100, 450-560) is the same tree pasted 10 times on a grid;
   - the fields (170-500, 380-540) repeat sprites on a strict grid.
   - Fix:
     - Training yard: a fenced ring, dummies, a target, hay and a weapon rack, plus a walker stop.
     - Garden: gravel paths, benches, a hedge and a shrine.
     - Orchard: 3 tree variants, flipped, at irregular spacing, with baskets and a ladder.
     - Fields: alternate the crop per row, add a bare row, a scarecrow and a cart.

10. **Per-frame churn.**
    - town_view.gd:404-406 redraws everything every frame.
    - _draw_labels (889-913) allocates StyleBoxFlats per plate per frame.
    - 599-600 duplicates and sorts the folk every frame.
    - 497-498 allocates walk.keys() per goal.
    - 805-811 has no light culling.
    - 656 calls load() inside a draw callback.
    - Fix:
      - Cache 2 StyleBoxFlats and add a dirty flag for the labels.
      - Insertion-sort the folk in place.
      - Cache walk.keys() in _ready.
      - Cull lights and particles.
      - Preload the up/*.png textures in _ready.

Not counted: the walkers are LPC 64 px frames drawn at 0.5 with NEAREST (town_view.gd:610-617). That's fine until the new hero walkers land.

Biggest opportunity: move the Tavern and build a real Bounty Board, so the plateau stands alone with walkers climbing it (fixes 1 and 2). Then the pan clamp and integer device scale (fixes 3 and 4).
