# HERO pass 2: chibi base seen from behind (Oct 23 2026)

**Status:** pass 2 delivers the BASE only (back view + portrait + mockup), as Juzo asked ("buff it
out one thing at a time; base first"). Customisation sheets 02-05 are from pass 1 and live in
`pass1/`; each piece (hair styles, faces, outfits) will be rebuilt on this base next.

| # | File | Shows |
|---|---|---|
| 01 | `01_HERO_base.png` | back view 1x/2x/3x/7x, portrait with chiselled cheekbones, layers, old in-game hero vs new at 3x |
| 01b | `01b_HERO_base_mockup_430x932.png` | phone mockup laid out like the current game (hero centred low, monster above) |

### What changed after Juzo's critique of pass 1
- **Chibi like the old heroes.** Proportions measured from the in-game LPC heroes (body + head
  layers, `idle@up`): 47 px tall, head ~20 px (43 %), short legs, arms at the sides, seen straight
  from behind. The new hero is 53 px: head 23 px (43 %), torso 11, legs + boots 16, drawn as our own
  pixels (LPC parts are partly CC-BY-SA/GPL, so nothing is copied; the old sprite appears on sheet 01
  only as a comparison).
- **Battle view straight from behind** (like the game's `hero_back`), not three-quarter.
- New AI guide `v2_back_s71` -> density pass `v2_d56_s82` (56 px) used for the head/hair mass and
  the shirt + vest layout; every pixel then placed by hand (`tools/draw_v2.py`).
- Hair: a big clumped mop with partings, small tufts, ears sticking out; no horn-like spike.
- Body: white shirt shoulders and puffed sleeves, short leather vest lit from the top-left, belt +
  pouch, compact trousers, chunky boots, near leg one step back (weight on the left leg).
- Weapons kept as they were (Juzo: good); the hand moved to the new arm.
- Portrait: male cheekbones chiselled: the temple steps in 1 px and the cheekbone back out with a lit
  ridge, a shade run under each cheekbone, straighter jaw planes, flatter chin.
- Downloads: none were needed (no external assets used).

### Fable check on the pass-2 base (1 pass so far)
Scores: back view 7, portrait 4 (cheekbones looked unchanged), mockup 7; VERDICT FIX. Fixed: portrait
cheekbones redone with a real outline step + planes; sword hand no longer floats (forearm added
between cuff and fist); vest pillow shading replaced by one top-left light; trouser/boot banding broken
up with staggered folds and a darker near leg; hair spike removed; mockup hero moved so the shadow sits
on the floor and the blade clears the torch, shadow given a lighter edge. Not changed: the blade stripes
(the weapons were approved as they are).

### Self-score (vs Juzo's references)
| Piece | Score | Why |
|---|---|---|
| Back view | 7.5 | chibi build matches the old heroes, clean clusters; hair is good, could be fluffier |
| Portrait | 6.5 | cheekbones now read at 3x+, but the portrait hair is still the pass-1 helmet-like crop |
| Mockup | 7.5 | same layout as the current game, scale right against the ghoul |

### Next pieces (in order)
1. Portrait hair to match the new mop; 2. hair styles (long, close crop, tail) on the new head;
3. faces; 4. cloth and plate outfits on the new body; 5. sheets 02-05 again.

---

# Pass 1 notes (kept for history)

Style test for Juzo. Nothing here is wired into the game (`claude/art_test` has a `.gdignore`).

## Sheets (open in order)
| # | File | Shows |
|---|---|---|
| 01 | `01_HERO_base.png` | battle view (three-quarter from behind) at 1x/2x/3x/7x, front portrait 1x/3x/7x, the 5 layers, 48 vs 64 px test, mockup |
| 01b | `01b_HERO_base_mockup_430x932.png` | true-size phone mockup: Catacombs background + the existing zone 1 ghoul, both at 3x pixel scale |
| 02 | `02_HERO_custom_skin_hair.png` | 4 skin tones, 4 hair styles (short, long, close crop, tied tail), every style in 4 colours, battle + portrait |
| 03 | `03_HERO_custom_faces.png` | 3 expressions (determined, fierce, smile) on the portrait, on other skins / hair / eye colours |
| 04 | `04_HERO_custom_outfits.png` | cloth robe, leather, plate (battle + portrait) and ramp recolours; plate Rare vs Epic |
| 05 | `05_HERO_custom_weapons_rarity.png` | sword, staff, bow, sword + shield; sword in 6 rarities; full heroes with Rare / Epic / Mythic items |

## Size
**64 px body** (canvas 60 x 84 + 1 px outline + 8 px shield margin; the raised sword makes it taller).
48 px is shown once on sheet 01: it is the same drawing reduced by code, and the face, ear, belt and
grip blur together, so everything is built at 64. In the mockup both hero and ghoul are at 3x.

## Method
1. **AI for design, not for final pixels.** ComfyUI SDXL + pixel-art-xl LoRA + IP-Adapter (style
   transfer 0.35-0.5) fed with a collage of Juzo's pet references. About 50 images: txt2img for the
   design (`r1`/`r2`), then img2img "density passes" (`r3`-`r6`) so the model redraws the chosen hero at
   48, 64 and 96 art px tall. Picked `r6_d64_s53` (64 px) as the guide, `r4_d96_s32` for the design and
   `p1_front_s61` for the portrait. Raws, prompts and seeds: `C:\ai\art_raw\hero\` (`log.jsonl`, not committed).
2. **Hand pixelling over the guide.** Every visible pixel is written by hand as text (`tools/draw_*.py`):
   one char = material + shade (1-4), e.g. hair `1-4`, skin `a-d`, leather `m-p`. Head, face, ear, eye,
   fist, vest, legs, boots, outfits, hair styles and weapons are drawn this way, cluster by cluster.
   An early automatic route (trace + AI colours, `bake.py`) gave noisy clusters and was dropped for the
   visible art.
3. **Renderer** (`tools/hero.py`): stacks layers, adds an inner line (shade 0 of the lower material)
   where a later layer or a deeper material covers a pixel, adds one near-black (#120c14) outer
   outline, then colours each pixel from its material's ramp. Speckle filter (`denoise`) on hair.
4. **Ramps**: 4 shades + inner line per material, hue-shifted (purple/cool shadows, warm highlights).
   Skin 4, hair 5, linen, leather, dark leather, trousers, boots, steel, blackened iron, wood,
   3 robe colours, 4 iris colours, 6 rarity ramps.

## Layers and runtime recolour
Battle, bottom to top: `w_shield` (under the far arm, shifted 9 px left) - `base_body` - `outfit_*` -
`hair_*` - `w_*` (weapon) - `base_body_front` (the sword hand, over the grip).
Portrait: `port_body` - `port_outfit_*` - `port_hair_*` - `port_face_*`.
All layers share one canvas, so they line up with no offsets. Exports for the game are in `layers/`:
one PNG per layer with **R = shade x 60 (0 = inner line)** and **G = material id**, plus `layers.json`
(material ids, every ramp, default assignment, outline colour). The game colours a pixel as
`ramps[assigned_ramp[material]][shade]`, so skin, hair, eyes, cloth, metal and rarity are swaps, not redraws.
Item-local ramps: weapon and armour each carry their own trim, so a Rare sword on Epic plate works.

### Rarity (Juzo's rules)
Slots: `R` trim, `U` band 1, `Q` band 2, `J` gem. Common = plain metal; Uncommon = trim; Rare = trim +
1 band; Epic and up = trim + 2 bands + gem (plate: chest band + 3x3 belt gem); colour comes only from
rarity; **glow only on Mythic** (2-step hard-alpha ring on the blade + 4 sparks, a code effect).

## Reference study (Juzo's art_refs, measured at pixel level)
- Pet sprites: 28-32 art px, 1 px near-black outline everywhere, outline + inner lines are 18-37 % of
  the pixels, 12-16 real colours, 3-4 shades per material, big flat clusters, eyes 2x2-2x3 dark with
  a 1 px glint, light from the top-left.
- Gen 2-3 sprites: same bold outline, few colours, strong silhouettes, dithering only for texture.
- Stardew villagers: tiny full figures, readability from hair silhouette and 2-3 colour blocks.
Target taken from this: chunky 1 px outline, inner lines between parts, 4-shade ramps, no noise.

## Fable art check (2 passes)
Pass 1 (scores 5-6, FIX) flagged 15 items. Fixed: pose did not address the monster (sword now leans
up-right, near leg steps back); striped long hair (rebuilt as 3 tapered locks with strand breaks);
hair speckle (denoise); mismatched arms (both white sleeves + short cuff); portrait vs battle mismatch
(vest tone, sleeves, jagged crown); plate column of grey (leather sabatons, bluer steel); Rare vs Epic
unreadable (2 px trims, chest band, 3x3 gem); deep skin lost the face (lighter deep ramp); tail invisible
from the front (tips beside the neck); Mythic glow was a flat outline (blade-only, 2-step falloff);
bow without arrow (arrow nocked); orphan far hand (cuff); no hero shadow in mockup; blackened plate
too close to ash robe (blue-black).
Pass 2 (scores 7-8.5, FIX for one must-fix): plate portrait chest was leather -> now steel like the
battle view. Also fixed: arrow moved to the string at the hand, glow removed from the crossguard,
portrait sleeves made a corner instead of a bar, plate gem enlarged. Not fixed (optional polish): see below.

## Self-score vs the references (1-10)
| Sheet | Score | Why |
|---|---|---|
| 01 base | 7.5 | clean clusters and outline, reads at 3x; near arm still a straight tube, legs a bit stiff |
| 01b mockup | 7 | grounded and readable; the hero is twice the old ghoul's height (monsters are due a redraw) |
| 02 skin/hair | 7.5 | 16 combos consistent; close crop is plain, long hair is good not great |
| 03 faces | 7.5 | 3 expressions read at 1x on every skin; faces live on the portrait only |
| 04 outfits | 7 | three outfits clearly different; portrait outfits are recolours of one shape |
| 05 weapons/rarity | 7.5 | clear rarity ladder, restrained Mythic; bow pose is simple |

## Known weak points
- The near arm is straight (no elbow bend) and the head does not turn toward the monster.
- Expressions show only on the portrait; from behind you see only cheek, ear and lash.
- Portrait cloth/plate are the leather shape recoloured (no hood, no pauldrons in the portrait).
- Skin tone barely shows in the back view (only cheek, ear and hands).
- A few single hair pixels remain at the crown edge; no animation yet (static pose only).
- Hero 64 px vs current 34 px monsters: the monster set needs the same density.

## Rebuild
```
cd claude/art_test/hero/tools
PY=/c/ai/ComfyUI/python_embeded/python.exe
$PY -I draw_master.py && $PY -I draw_custom.py && $PY -I draw_portrait.py && $PY -I make_sheets.py
```
`gen.py jobs.json` re-runs ComfyUI jobs (raws go to `C:\ai\art_raw\hero\`).
