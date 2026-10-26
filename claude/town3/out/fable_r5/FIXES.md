# Fable town round 5: fixes (town dev 2, uncommitted on wt/town2)

Top item (Juzo: the dungeon entrance looked floating). Pictures: plateau_{2x,3x}_{day,dusk}_before_after.png and 12_phone_2x_day_plateau.png:
- The Dungeon sprite stood on a cut-soil slab, whose brown underside read like a floating island. In compose.stone_base:
  - the band is now a stacked-stone retaining face, as dark as the plateau's walls, with the south-east face in shadow;
  - under the stair, the steps carry on down to the plateau's path.
- compose._foot adds a 3-row contact shadow plus grass tufts and fallen stones along the foot of the Dungeon base and of the plateau's walls. The stairs' feet are left clear. The shadow stays under alpha 128, so no anchor moves.
- The ruins and the portal sit on the stone top. The blue beam starts at the portal floor (at(19.9, 4, PLATEAU_Z + 30) is the arch's floor line), and the dusk renders show it rising from there.
- The plateau's own walls already reached the street. Now they also have the shadow and clutter at their foot.

Game side, all 15 items:
- **Item 1:** glow shared out per light cluster (light_counts and sqrt), core capped at 0.7. Tested with glow_sum ≤ 0.9 at the porch and the stair foot.
- **Item 2:** "arriving" flag. door_marker shows only once you're inside.
- **Item 3:** a door synth fallback in sfx.gd, plus a 1.5 s per-sound rate limit in main.gd. Note: sounds/door.wav already existed and differs from tap.wav, so Fable's premise that door was only the tap alias was wrong.
- **Item 4:** hardcore_stops needs Buildings.built("church").
- **Item 5:** no chat with anyone fading in or out.
- **Item 6:** touches reset on focus-out.
- **Item 7:** chimney smoke drawn with normal blending in _draw_people.
- **Item 8:** jittered flame flip.
- **Item 9:** the cast is rebuilt when the day changes.
- **Item 10:** "Now level N" note plus sparkles on an upgrade. Level props get lit textures.
- **Item 11:** bigger, brighter river dashes.
- **Item 12:** the overlay is cleared in the Vault's merlon gaps.
- **Item 14:** tests (a)–(f), plus the stop_face check. Town tests: 0 failures.
- **Item 15:** _spots() is cached.

Props (00_prop_contact_sheet.png and 00b_texture_P5_sign_post.png):
- **P1:** statue removed.
- **P2:** bell cote moved to the lane.
- **P3:** dummies moved clear of the east wall, each on a mound.
- **P4:** cross moved onto the front gable's peak.
- **P5:** the gilded sign has an iron post and a foot. The post is on the in-game level texture, so it doesn't show in composer renders.
- **P6/P7:** the Vault's chest and bowl lifted 4 px up the grass, off the water line.
- **P8:** the awning doesn't show above the battlement in the current render.
- **Item 12 picture** (00c_item12_vault_overlay.png): the lit pixels in the merlon gaps are gone. The one yellow pixel left at the far right is the Tavern's window, outside the Vault's outline.
- **P9/P10:** no rail under either lamp now.
- **P11:** stone removed.
- **P12:** block removed.

Wall sweep: the floating check now counts the wall runs as covering. Props hidden behind the walls were removed or moved one row in:
- the gate courtyard props,
- the east-wall orchard props,
- the Hardcore sarcophagus,
- one grave.

Fences under buildings are culled automatically.

Notes:
- The outside forest reshuffles, because the tree rng order changed.
- The gate field was left alone, as asked.
