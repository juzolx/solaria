# Art style test: AI-made 2x heroes and town (Oct 23 2026)

This is a style test for Juzo to approve. Nothing here is used by the game yet. The folder has a
`.gdignore`, so Godot does not import it.

## What to look at
| Sheet | What it shows |
|---|---|
| `heroes_vs_monsters.png` | 5 heroes next to the Zone 1 Catacombs monsters (ghoul, draugr, barrow-wight, banshee, strigoi), 2x art, shown at 3x |
| `heroes_layers.png` | 5 races x (base body, warrior plate, mage robe, ranger leather), each built as body + outfit + weapon layers, plus the 2 weapons |
| `heroes_pipeline.png` | each chosen piece: raw AI image, then the pixel grid it found, then the cleaned result |
| `heroes_battle_mock.png` | a hero and a ghoul on the zone_0 background |
| `hero_anim.gif`, `hero_anim_sheet.png`, `hero_anim_preview.png` | a 4-frame idle and a 3-frame attack (sheet at 2x: row 1 idle, row 2 attack, 64x52 art px per frame) |
| `town_compare.png` | today's LPC town next to the new concept (day and dusk) on the same layout |
| `town_concept_day.png`, `town_concept_dusk.png` | the full town, 704x1360 (2x art, 352x680 art px) |
| `town_buildings.png`, `building_*.png` | 3 buildings: raw AI, then grid, then palette and outline, then dusk; the sprites are at their native size, saved at 2x |
| `candidates_overview.png` | how the method was found: probes, small-figure prompts, mannequin img2img candidates |

## Settings (all images)
ComfyUI v0.42.1 portable, `C:\ai\workflows\pixel_sdxl.json`: SDXL base 1.0, pixel-art-xl LoRA at
1.0/1.0, sdxl-vae-fp16-fix, euler_ancestral, normal scheduler, 24 steps, CFG 7, 1024x1024. Driven by
`tools/artjob_gen.py jobs.json`. It also does img2img: LoadImage, VAEEncode, then `denoise`. Every
image is logged with its prompt and seed in `C:\ai\art_raw\log.jsonl`. All raws (about 200) stay in
`C:\ai\art_raw\` and are not committed.

Default negative prompt: `3d render, realistic, photo, blurry, text, watermark, signature, multiple
characters, cropped, cut off, frame, border, scenery, landscape, ground shadow, gradient background`.

### What did not work, and what did
1. **A large single figure** (about 90 AI pixels tall), shrunk 3x to 32 px, turns to mush: faces
   disappear. Dropped.
2. **Small figures** ("tiny ... small in the center of a large empty plain white background, 32x32
   sprite", or sprite-sheet prompts): the model draws at the real target size (about 30 AI pixels
   tall), with real 1-pixel eyes. This works. Facing is unreliable (mostly front or three-quarter).
   "Facing right" prompts tend to give tiny, poor side-view sprites.
3. **Mannequin img2img** (what was used): one small base figure (`tools/base_tall.png`, and
   `base_short.png`, the same figure squashed to 80% height and 108% width for dwarf and goblin).
   Every race and outfit is img2img from it, so all of them land in the same pose and the same
   22x32 box. That alignment makes layers possible.
   - The mannequin came from: probe `probe2_ff_s204` (3/4 knight, mirrored), then img2img d0.72
     (`i2i_human_d72_s32`, sword erased), then shrunk to 256 px tall on white, then img2img d0.65
     (`mq256_human_s42`). That last image is `base_tall.png`.
   - Template: `tiny pixel art battle sprite, chibi {X}, fighting stance, three-quarter view facing
     right, full body, dark fantasy, thick dark outline, plain white background, 32x32 sprite`

| Piece | Raw file (name_s<seed>) | denoise | {X} |
|---|---|---|---|
| Human | r2_human_d60_s52 | 0.60 | bald human man in a plain linen shirt and brown trousers, bare hands |
| Elf | r2_elf_d72_s53 | 0.72 | elf man with long pointed ears and long blond hair, pale skin, plain linen shirt and brown trousers, bare hands |
| Orc | r2_orc_d60_s53 | 0.60 | muscular green-skinned orc with tusks and a black topknot, plain linen shirt ... |
| Dwarf (short) | r2_dwarf_d60_s52 | 0.60 | stocky dwarf with a big braided red beard, plain linen shirt ... |
| Goblin (short) | r2_goblin_d60_s51 | 0.60 | small green goblin with huge pointed ears and yellow eyes, plain linen shirt ... |
| Warrior tall / short | o2_warrior_tall_d55_s52 / o2_warrior_short_d68_s52 | 0.55 / 0.68 | human knight wearing dark steel plate armor with pauldrons, gauntlets and greaves, no helmet, bald |
| Mage tall / short | o2_mage_tall_d55_s51 / o2_mage_short_d68_s52 | 0.55 / 0.68 | human mage wearing a long deep purple robe with gold trim and a hood down, bald |
| Ranger tall / short | o2_ranger_tall_d55_s51 / o2_ranger_short_d68_s52 | 0.55 / 0.68 | human ranger wearing brown leather armor, bracers, and a short green hooded cloak, hood down, bald |
| Sword | weapon_sword_s12, figure 9 (flipped) | txt2img | `pixel art game item icons sheet, steel longswords and broadswords, each drawn diagonally, low resolution, few colors, thick dark outline, plain white background, dark fantasy rpg inventory` |
| Staff | weapon_staff_s12, figure 0 | txt2img | same, `wooden wizard staffs with glowing crystals` |

Town buildings (txt2img, seeds 21-24, `tools/mkjobs_town.py`): `pixel art, top-down three-quarter view
rpg game building sprite, {building}, dark fantasy village at dusk, warm glowing windows, single
building isolated on a plain white background, whole building visible, crisp pixels, dark outline`.
Picks: gate s23, guild s23, inn s23, shop s23, smith s22, tavern s23 (the wheel is on the front),
vault s23, market s23, clinic s23, church s22, trophy s22, fountain s24, bounty board from
bld_bounty_s21 (native box 51,72,73,93). Trees came from a second job (`tools/jobs_tree.json`):
tree_pine s61/s63, tree_oak s61/s62.

## Cleanup steps (`tools/pixlib.py`, all in code, re-runnable)
1. `remove_bg`: flood-fill the white background from the image border, then fill the grey drop
   shadow (low-chroma mid greys that touch the background).
2. `find_grid`: edge energy per column and row, testing periods 5-14 px in steps of 1/8. It takes
   the largest period that scores within 3% of the best. The answer was 8.0 px at phase 7 on every
   image.
3. `grid_sample`: the median colour of the centre half of each cell, giving the true pixel image
   (128x128).
4. Figures: `figures()` cuts sheets into connected figures. Heroes use a fixed window (40,46)-(86,90),
   so every layer stays aligned.
5. `strip_shadow`: peel any leftover grey under the feet.
6. `shrink_mode`, only when a piece is too big (weapons, buildings fitted to map slots): palette
   first, then each output cell takes its most common colour, and dark line pixels win at 30% or
   more.
7. `quantize`: OKLab nearest colour in the 74-colour `ArtStyle.PALETTE`, capped at 18 colours
   (heroes) or 24 (buildings).
8. `outline`: dark edge pixels become #0e0812, then a 1 art-pixel ring goes around the body pixels
   (no doubled ring).
9. `rim`: top-left light. Upper-left silhouette edge pixels move one palette step lighter.
10. Layers (`tools/heroes.py`): body = race sprite. Outfit = outfit sprite below the neck row (22
    tall, 26 short), minus the mannequin's skin colours (so hands show the race's skin). Below the
    neck the body is clipped to the outfit silhouette. Then re-outline and rim. The weapon is pinned
    by its grip point to the hand point (`HAND`).
11. Animation (`tools/anim.py`, `make_anim.py`): idle moves every row above the waist down 1 px,
    in the order 0,1,1,0, and dips the sword tip. The attack is wind-up (sword raised, body back
    1 px), strike (body forward 2 px, sword at -105 degrees, a 3-colour smear arc), and recover.
    Weapon rotation is a small RotSprite (8x nearest, rotate, most common colour per block), so no
    new colours appear. Everything snaps to whole art pixels and is re-outlined.
12. Town (`tools/town_concept.py`): procedural palette ground (`town_ground.py`: grass, wobbly dirt
    roads, cobbled plaza, cliff), buildings fitted to the `art/town/town.json` rects (halved to art
    pixels), flat down-right shadows, and lamps at the json light points. Dusk is a darken plus blue
    shift snapped back to the palette, with warm lights untouched, auto-lit windows (small enclosed
    dark pockets) and 3 hard-alpha glow rings.

Re-run: start ComfyUI and run `artjob_gen.py` with the job files (same seeds give the same images).
Then run `make_hero_sheets.py <out>`, `make_town_sheets.py <out>` and `make_anim.py <out>` with
`C:\ai\ComfyUI\python_embeded\python.exe -I`. The scripts expect `C:\ai\scripts` (copies are in
`tools/`) and `C:\ai\art_raw`.

## Quality verdict (honest)
- **Heroes: close to shippable as a base, but not final.** They read at game scale and sit well
  with the monsters (same 2x grid, outline, palette). Layering works because of the mannequin.
  Problems:
  - They are chibi, warm and bright. The Catacombs house style is gaunt, cool and desaturated, so
    the heroes look a bit "cuter" than the monsters. Fix: a slimmer mannequin, darker/cooler prompts,
    or a saturation clamp in quantize.
  - Faces are only 2-3 pixels of detail and need hand touch-ups.
  - The goblin base is the weakest piece (messy cloak, odd colours).
  - Short builds show small seams where body and outfit disagree.
  - Pose is front three-quarter, not profile.
- **Outfits as layers: works for tall vs short builds**, with one outfit sprite per build. Hair and
  helmets would need their own head layer (same method, cropped above the neck). Full LPC-style
  freedom (any armor piece on any slot) is not realistic from AI output. Proposed system:
  race body x outfit per build (2 builds) + weapon layer + runtime recolour of the outfit's material
  ramp.
- **Weapons: OK.** The sword needed picking from about 30 options. AI weapon icons often have odd
  proportions.
- **Animation: a proof only.** Moving whole rows works for breathing. A convincing attack needs a
  separate arm layer, because the arm can't move today: only the sword turns.
- **Town buildings: good.** The best AI result here. They clean up well and keep their detail at
  native size. Fitting them into today's slots means shrinking them about 25%, which costs texture,
  so the new map should be about 1.3x bigger.
- **Town map: concept only.** The ground is procedural and plain. Buildings are front-on, not seen
  from above like today's town. The cliff and gate need real art. Dusk windows are lit
  automatically and miss some windows.

## Animation plan for the town (not done)
- Torches and lamps: 3-4 frame flicker from palette swaps (fee761, feae34, f77622) plus the glow
  ring radius changing by 1 px.
- Chimney smoke: a 6-frame strip of 3-4 grey puffs rising 1 px per frame, spawned at each chimney
  top (one shared strip).
- Fountain water: a 3-frame palette cycle on the water pixels (4fb0c6, a4dddb, c8f2ee).
- Banners: a 3-frame row shift (the same `shift_rows` idea, sideways).
- Tavern wheel: RotSprite the wheel disc in 8 steps (it is a separate crop).
- Walkers: reuse the new hero layers at 1x on the map (2-frame bob).

## Next steps
1. Juzo picks: chibi vs gaunt proportions, and front three-quarter vs profile.
2. Make the mannequin v2 to match the Catacombs (slimmer, cooler), then re-run the same jobs
   (about 30 minutes of generation).
3. Add a head/hair layer and a front-arm layer. Recolour masks per outfit: map each outfit's colours
   to `ArtInfo` material ramps.
4. Hand-fix faces (2-3 pixels per race) in a small code table.
5. Town: grow the map 1.3x, generate the ground (or tiles) by AI too, redo the gate and cliff, and
   generate upgrade looks per building with img2img from the level-1 sprite.
