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

## DIRECTION (Juzo, 2026-10-24) - replaces the per-slot gear layers below
- Armour (helmet, chest, legs, feet, off hand, ring, necklace) changes NO look, only stats.
- Each CLASS has its own outfit (13 base classes in classes.gd ORDER), drawn for both bodies (later every
  race) and worn with every hair style. Suggestion for Juzo (not decided): small upgrade touches at class
  levels 15 / 35 / 75 (trim, colour, one accessory); hidden and God classes may get special outfits later.
- WEAPONS still show: the equipped weapon type (10 types, the weapon style Juzo liked) drawn in the hand.
- Creator: race, body type, skin, face, hair (all old styles), colours - highly customizable.
- Structure = the old creator: fixed frame set (battle: idle 2, attack 4, hit 1; portrait: idle 2), every
  part drawn on exactly those frames, fixed layer order: body+outfit (one image per class per frame),
  hair (per frame, placed on the head), weapon (per frame, drawn in the hand), colours by recolour masks.
- How the parts are made: base frames = picked from the approved PixelLab animations (+ a hit frame);
  sword removed from the base frames (1 edit each) so weapons are their own layer; each class outfit =
  1 PixelLab edit per frame of the weaponless frame; each weapon = 1 edit per frame ("add a mace in the
  right hand"), its layer = the pixels that changed. ~9 gens per outfit per body, ~7 per weapon per body.
- Sample first: Warrior (plate, sword) + Cleric (robe, mace) on both bodies, then batch after Juzo rates.

## Plan review (2026-10-24): go back to the old system's structure, with the new art
Why the old LPC paper doll (lpc.gd, sprites.gd, character_creator.gd) was clean:
- ONE shared frame set: every body, hair and gear part is drawn on the same frames (lpc.gd: combat_idle,
  slash, thrust, spellcast, shoot, walk; 64 px core frame, bigger swing frames centred on it).
- Every part is drawn PER FRAME, so stacking any parts in a fixed layer order animates cleanly.
- Colours are recolour maps on each part (base ramp -> chosen ramp), so no baked copies.
Where the new pipeline broke that:
- Parts exist only on the rest pose; the motion was made by moving pieces in code (B) or by mixing in a few
  PixelLab key poses (D). In-betweens are guesses: floating hands, a visible switch at key poses, legs that
  belong to the chest's key pose.
Simplest clean path (same structure as the old system):
1. Fixed small frame set, battle view (north): idle 2, attack 4 (rest, raised, strike, follow-through),
   hit 1. Portrait (south): idle 2. Town walk later, same rule. Other attack families (thrust, cast, shoot)
   = 4 more frames each, added when weapons need them.
2. Base body drawn by PixelLab on exactly those frames, wearing plain underclothes (from the approved
   attack + idle: pick the frames, 1 edit each = ~9 gens per body).
3. Every chest / legs / feet item drawn on EVERY frame: a PixelLab edit of that base frame that changes only
   that slot ("change only the legs to plate greaves"), then cut out as the pixels that changed. Same pose,
   so all items line up and stack in a fixed order, like LPC. ~9 gens per item per body.
4. Head things ride on the head: hair (37 styles, done) and helmets are placed per frame by matching the head
   (headswap.py already does this on attack frames). Weapons are placed per frame at the hand with a small
   angle table per frame (like LPC weapon sheets, but one drawing per weapon). No extra generations.
5. Plug the new parts into the existing creator: same part list / layer order / recolour idea as lpc.gd,
   new art files. Character creation works like today.
Cost: starter set = 2 bodies x (9 base + 12 items: leather/plate/robe/ranger chest, legs, feet) x 9
   = ~230 gens; each later item ~18 (both bodies). Helmets, hair, weapons, colours: ~0.
What Juzo would see first: one sample of the frame set - 2 bodies x 3 mixed kits, idle + attack + hit,
   battle view and portrait, as a GIF (~40 gens to prove it before the batch).

## Style (Juzo, 2026-10-24): the hero is the reference, the style bible follows it
- Keep the PixelLab hero as drawn: its near-black outline (#000000-#070207) and its richer shading
  (~12-14 shades in hair, ~18-20 across the browns) are the target look, not 3-5 shade ramps.
- Runtime recolours keep each pixel's relative brightness (recolour.py), so they work on the full shading.

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
