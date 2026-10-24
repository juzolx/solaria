# Style test v2: dark chibi heroes, pets, walled town (Oct 23 2026)

This is a style test only. Nothing is wired into the game. Each sheet covers one topic, every
piece has a number, and each piece is shown at game size (2x art) next to a zoomed copy.

## How to review (on the phone)
| File | Topic |
|---|---|
| `01_variants_ABC.png` | **Pick a base look:** A chunky chibi, B slimmer, C darker armour (all human warrior) |
| `02_mockup_A/B/C.png` | each look in a 430x932 battle screen: zone 1 background, draugr above, hero from behind at the bottom |
| `03_heroes_races.png` | H1-H5 races in back view (plain clothes + sword) |
| `04_heroes_outfits.png` | H6-H11 warrior, mage and ranger on a tall build (human) and a short build (dwarf) |
| `05_portraits.png` | P1-P5 front portraits for menus |
| `06_weapons_layers.png` | W1 sword, W2 staff; L1-L4 how a hero is layered |
| `07_anim_frames.png`, `hero_anim.gif`, `hero_anim_slow_zoom.gif`, `hero_anim_sheet.png` | I1-I4 idle, K1-K4 attack. The weapon arm is its own layer and swings from the shoulder. The first GIF is game size and speed; the second is 2x zoom at half speed |
| `heroes_layers.png` | overview grid: 5 races x (base, warrior, mage, ranger) |
| `heroes_vs_monsters.png` | back views and portraits next to the five Catacombs monsters, at the same scale |
| `08_pets.png` | PET1-PET3 sample pets (chibi, in our palette) |
| `09_town_day.png`, `10_town_dusk.png`, `11_town_key.png` | the new walled-town concept; the key numbers buildings 1-14 and adds story callouts |
| `12/13/14_town_phone_*.png` | phone views (430x932) at the gate, the market and the dungeon (swipe) |

## Method (repeatable; scripts in `tools/`, raw images in `C:\ai\art_raw\`)
- **One pose for everything:** `mannequin.py` draws a 32 px guide figure in code. There is a back
  three-quarter version (turned up-right, a sliver of cheek, ear and nose showing) and a front
  version. Short and slim versions are squashed or stretched copies. Each guide is placed on a
  white 1024 canvas at 8x, the size at which the pixel LoRA draws at true 32 px density.
- **Generation:** `artjob_gen2.py` runs SDXL base + pixel-art-xl LoRA, euler_ancestral, 24 steps,
  CFG 7. It uses img2img from the mannequin (denoise 0.5 for races, 0.55 for outfits, portraits and
  looks). IP-Adapter plus ViT-H uses `art/enemies/draugr.png` as the style reference ("style
  transfer", weight 0.3; 0.6 for look C). Jobs and prompts are in `mkjobs_v2.py`; seeds are
  731-733. Picks are listed in `heroes2.py` (PICK).
  - Back template: `tiny pixel art battle sprite, chibi {X}, seen from behind, three-quarter rear view turned up and to the right, side of the face and ear visible, right fist raised, full body, dark fantasy, muted cold desaturated colors, thick dark outline, plain white background, 32x32 sprite, cute chunky silhouette`
  - OpenPose ControlNet: tried first (`poses.py`). At this tiny figure size it gave a pure back view
    and ignored the arm, so the code-drawn mannequin plus img2img replaced it.
- **Cleanup** (`heroes2.py` + `pixlib.py`): bg flood, find the 8 px grid, take the median per cell,
  then the fixed 40x42 window. Then: strip the shadow, drop lone stray pixels, smooth in-sprite noise
  (a pixel unlike all 4 neighbours takes their colour), a light cool grade, palette (OKLab, at most
  20 colours), outline #0e0812 and top-left rim.
  - Bald heads and hands are recoloured onto muted palette skin ramps (human, grey-green orc, olive
    goblin). The same mapping can do the runtime recolour.
  - **Face fixes:** 3-5 hand-placed pixels per race in `FACE`: ear, eye, cheek, elf ear tip, orc
    tusk, dwarf beard edge, goblin eye glint.
- **Layers:** race body, then the outfit below the neck (minus the mannequin's skin; the body is
  clipped to the outfit silhouette), then the **weapon arm**. The arm is cut from a fixed box beside
  the torso; the fist is found automatically and the weapon is pinned to it. The arm and weapon
  rotate together around the shoulder with RotSprite.
- **Animation:**
  - Idle: rows above the waist move 0/1/1/0 px and the arm turns 0/-3/-5/-2 degrees, at 4 fps.
  - Attack: wind-up (+55 degrees, body back 1 px), strike (-40 degrees, lunge up-right, 3-colour
    smear arc), follow-through (-75 degrees), recover. Frame times are 180/70/110/200 ms.
- **Pets:** txt2img came out too large (60-87 px), so each was shrunk to 250 px on white and redrawn
  with img2img at 0.5 (`jobs_pet2.json`), then cleaned the same way.
- **Town** (`town2.py`): a new layout, 880x440 art px (1760x880 file, about 4 phone screens to
  swipe).
  - Drawn in code: walls with a tall inner face and towers that face outward, a fog barrier beyond,
    a sealed west gate (portcullis, planks, rubble) with the overgrown road swallowed by fog, the
    cobbled main street, the river with a stone bridge, market stalls, a well, and fenced empty lots.
  - AI sprites (txt2img `mkjobs_town2.py`, seeds 741-742) are used for the buildings.
  - The dusk version keeps it on the palette, lights the windows, and puts a candle glow on the
    dungeon memorial.
  - Artist references (claude/art_refs) were only looked at for direction. Nothing was traced,
    sampled or fed to the AI.

## Known weak points (no need to spend critiques on these)
1. **From behind, races read mainly by head colour and hair.** The face sliver is only a few
   pixels. A bald human is a big skin-coloured ball; a default hood or hair for humans would read
   better.
2. **The weapon arm** is a box cut. When it swings, a few skin pixels of the fist can float, and
   there is no elbow bend. A drawn 2-3 frame arm (or an arm made from the mannequin) would fix it.
3. **Look B** (slim) is a single whole sprite. Its head is barely smaller than A's, so the
   difference is mild.
4. **Look C's "blackened iron"** came out teal-green from the draugr reference. It works as
   "Catacombs-tinted", but it is not black.
5. **The mage robe** maps to a dull navy-violet after the palette snap.
6. **Short-build outfits** (dwarf, goblin) show small edge seams.
7. **The goblin** is better than in v1 (clean olive skin, big ears) but has little facial detail
   from behind.
8. **PET2 moss slime** is noisy and its candle is unclear. PET1 and PET3 are cleaner but not yet at
   the reference artist's level: their shading has more than 3-4 tones.
9. **Town:**
   - Buildings are front-on three-quarter, not true top-down like the reference.
   - The houses repeat (3 designs).
   - The procedural grass is busy.
   - The river passes through the walls with no grate.
   - There is no Mailbox spot yet (add it if that building stays).
   - The dusk grade turns the walls bluish.
10. **The mockup UI** is a placeholder, not the game's UI.
