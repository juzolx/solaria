# PixelLab hero - customization plan

Approved base: PixelLab character `13511359-6f6d-4302-98d9-987f3b7c8790` ("Solaria base hero", v3, 64 px).
Rule: PixelLab only where the *shape* changes; every colour change is code (0 generations).
Check `get_balance` before each batch; show a sample before any batch over ~30 generations.

## What goes where

| Option | How | Cost |
|---|---|---|
| Hair colour (brown, black, blond, red, ash, ...) | code: `recolour.py` ramp swap on the hair mask | 0 |
| Skin tone (fair, tan, brown, deep) | code: same, skin mask | 0 |
| Faces / expressions | code: small pixel overlays on the SOUTH face (portrait only; battle view is from behind) | 0 |
| Outfit dye, rarity trim/gem, Mythic glow | code: ramp swap on cloth/metal masks (same rarity rules as 05_HERO sheet) | 0 |
| Outfit shapes (cloth, leather, plate, robe, ...) | PixelLab `create_character_state` of the base | 10 per outfit (sample: plate = 10) |
| Race base shapes (elf ears, dwarf beard/build, ...) | PixelLab state of the base, then outfits as states of each race | 10 per race |
| Animations per outfit | idle (template) + attack (v3), north + south | ~4 per outfit (1 per direction per clip) |
| Hair styles (shape) | to test: state with a new hairstyle, then code pastes the head onto other outfits | 10 per style + test |

## Rough budget (of 2,000 / month)
- 4 races x 4 outfits = 16 states x (10 + 4 anim) = ~224
- 6 hair styles = ~60, if head swaps work
- Re-rolls / fixes reserve ~100
- Total ~400, leaving most of the month free.

## Gear layers (Juzo: everything interchangeable, 8 slots) - proof in ../layers/01_LAYERS_mix.png
- Slots (Juzo, confirmed): Weapon, Off Hand, Helmet, Chest, Legs, Feet, Ring, Necklace. Visible layers = the
  6 main slots. Necklace = optional small pendant on the portrait (south), at most a 1-2 px hint in battle.
  Ring = no layer (at most a 1 px glint on the weapon hand for Mythic). A chest item owns its arms/hands and
  any cape; the cape is drawn at its own depth (over the back in battle view, behind the body in portrait).
- Every item is a piece cut from a PixelLab edit of the SAME base pose, so pieces line up on the base body.
  Regions per view come from the base body's landmarks (neck line, belt 63%, boot tops 90%, torso columns);
  code: ../layers/layers.py.
- Draw order: back view (battle) legs, feet, chest, gloves, back/cape, head(hair), helmet, weapon, off hand;
  front view (portrait) back/cape first, then the same. Long garments (robe) keep the skirt in the chest piece.
- Production rule (learned from the proof): make each item as its OWN one-slot edit of the base ("change only
  the chest to ..."), not a whole outfit. Cutting finished outfits apart leaves holes (the ranger cape hides
  its chest from behind). Cost: 1 gen per view per body = 4 gens per item for battle + portrait.
- Each body (male, female, later races) needs its own copy of each item; items don't move between bodies.
- Rarity is NOT shown on the worn hero (Juzo, 2026-10-24): rarity colours, trim, gem and Mythic glow appear
  only in the inventory / item screens. Worn pieces keep their own look (robe blue, ranger green, ...).
  Runtime recolours on the hero are for hair, skin and any dye/cosmetic options only.
- OPEN, biggest decision: animation. Static pieces mix freely, but PixelLab's frame animations are whole
  sprites. Options: (a) animate the hero in code from the pieces (idle bob, lean, arm + weapon swing:
  fully interchangeable, cheapest on iPhone, stiffer than PixelLab frames); (b) per-item frame animation
  (an edit per frame per item: ~50 gens per item, too expensive); (c) PixelLab frames for the base body only
  and gear frozen on top (looks broken in the attack). Recommendation: (a).

## iPhone budget (Juzo's rule: must run well on iPhone) - measured 2026-10-24
- One body, battle + portrait clips (idle 4 + attack 9 frames, N + S = 26 frames): ~235 KB RGBA once
  frames are cropped and packed into one sheet (~620 KB if left on full canvases). Pack per body, never per look.
- Hair: one style = 2 small images + 2 hair masks; load only the chosen style (~10 KB), not the library (~800 KB).
- Colours (hair, skin, dye, rarity) stay runtime ramp swaps: store grey/indexed art + masks, recolour in a
  palette shader. No pre-baked colour copies.
- Faces: portrait only, one face patch (~2 KB) laid on at runtime.
- Import with filter off (nearest), no mipmaps; frame counts stay at 4 (idle) / 8-9 (attack).
- SIZE LOCKED (Juzo, 2026-10-24): the hero is ~60 px tall on a 64 px canvas, shown at 3x in battle.
  Every outfit, weapon, race and hair style is built to this; races scale relative to it (dwarf shorter, etc.).

## Known limits
- PixelLab sprites are flat (one image per frame), not layers. Outfit x hair style combinations multiply, so
  hair styles need the head-swap test before we commit to them.
- The sword is baked into every frame. Our hand-made weapons (Juzo likes them) would need either a
  "no weapon" state + code-attached weapon, or one state per weapon type. To test with a small sample.
- Code eyes currently follow the hair colour (blond -> golden eyes); can be locked if unwanted.
