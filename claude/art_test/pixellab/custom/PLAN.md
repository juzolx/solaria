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

## Known limits
- PixelLab sprites are flat (one image per frame), not layers. Outfit x hair style combinations multiply, so
  hair styles need the head-swap test before we commit to them.
- The sword is baked into every frame. Our hand-made weapons (Juzo likes them) would need either a
  "no weapon" state + code-attached weapon, or one state per weapon type. To test with a small sample.
- Code eyes currently follow the hair colour (blond -> golden eyes); can be locked if unwanted.
