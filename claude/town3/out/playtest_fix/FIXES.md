# Town playtest fixes (Juzo, 26 Oct)

Crops show the game's picture: the base town art plus the level props drawn over it, the way
town_view draws them. BEFORE = a879a193, AFTER = this commit. `_L1` = buildings at level 1, `_L3` = level 3.

| Crop | What changed |
|---|---|
| shop_L1/L3 | The purple stall is off the Shop's plinth. Its level props no longer cover any stall, and the edge crates are gone |
| market_vault_L1/L3 | The market is re-laid so no stall overlaps a building or stands stacked behind another (7 stalls, with every stall type kept). The cart and shed off the Vault front are gone |
| gate_L1/L3, gate_field_L1/L3 | The walls meet the gatehouse towers flush. The field stays inside, with a fenced border clear of the gatehouse |
| clinic_L1/L3 | The deck sits clear of the wall, with no cart under it. The lamp is out from behind the planter. The pen is one cell smaller, off the wall lane |
| inn_tavern_L1/L3 | The Tavern's props stand east of its door and clear of the Vault, and the torch is off the east road |
| ring_L1/L3 | The ring's west rail and the dummy are gone (they crossed the yard's props) |
| zoom_far_430 / zoom_far_se | The new farthest zoom: the whole walled town on a 430-pt iPhone and on an SE |
| zoom_before_430 / zoom_before_se | The old farthest zoom (2x) on the same phones |

## Not shown in still pictures
- **Pets** keep 14 px apart and stay off the fence.
- **Walkers** keep 7 px apart. They wait a moment or step aside instead of stacking.
- **Zoom steps:** whole-town fit, then 1x (on big screens), then 2x and 3x. Every step except the farthest is a whole number of device pixels; the farthest uses nearest filtering. Pinch and the wheel both reach it, panning stays clamped to the town, and small labels hide below 1x.

## New checks
These run in the export, and it stops if any of them fails:
- A level prop the game would draw over something standing in front of it.
- A prop's foot that is half on a building's base and half off it.
- A stall that overlaps a building, or stands stacked behind another stall.
- A gap in the wall circuit, or a wall run that ends inside the gatehouse.
- A building or deck drawn over another building or over a front wall.

The town tests now also cover:
- the farthest zoom fitting at 430, SE, 1280x720 and 1920x1080;
- pet and walker spacing.
