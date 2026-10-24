# Style test round 3 (Oct 23 2026)

This is a style test only. Nothing is wired into the game. Pieces are numbered so Juzo can critique
them, and each one is shown at game size and zoomed. **The R3b sheets are the current answer.** The
R3_1 to R3_5 sheets are the first pass of this round and are kept for comparison.

## Sheets
| File | Topic |
|---|---|
| `R3b_1_faces.png` | F1-F15: faces drawn in code (front 32 px, front 48 px, back three-quarter slivers) |
| `R3b_2_race_silhouettes.png` | R1-R10: black silhouettes next to coloured sprites, back and front, for the five races |
| `R3b_3_heroes_32_vs_48.png` | H1-H10: the same races at 32 px and 48 px tall, from behind |
| `R3b_4_portraits.png` | P1-P10: portraits at 32 px vs 48 px |
| `R3b_5_mockup_32px.png`, `R3b_6_mockup_48px.png` | battle screens (430x932), zone 1, draugr; hero and monster at the same pixel scale |
| `R3b_7_gear_weapons.png` | G1-G10: sword, axe, mace, spear, bow, staff, orb, tome, dagger, shield on the same hero |
| `R3b_8_gear_armour.png` | G11-G13: cloth, leather and plate sets, from behind and as portraits |
| `R3b_9_gear_rarity.png` | G14-G19: Common to Mythic on plate, from behind and as portraits |
| `R3b_10_monster_M1.png` | M1 v2 Grendel: AI base, then cleanup, then hand fixes, then dither and outline, plus a game-scale check |
| `R3_6_town_day.png`, `R3_7_town_dusk.png`, `R3_8_town_key.png`, `R3_9/10_town_phone_*.png` | the depth town: day, dusk, numbered key, phone views |

## What changed, and why
- **Each race has its own silhouette** (`tools/guides4.py`), drawn as a code guide. AI img2img
  (denoise 0.5) uses one guide per race, view and size.
  - **Human:** the baseline.
  - **Elf:** slender, with ears up and back and long hair.
  - **Orc:** tall and bulky, with topknot and tusks.
  - **Dwarf:** short and wide, with a heavy helmet and a beard spilling out at the sides from behind.
  - **Goblin:** small, an inverted triangle, hunched, with huge sideways ears and a long nose.
  - Skin colours never overlap: the goblin is yellow-green, the orc grey-green, the dwarf ruddy
    human.
- **Faces are code, not AI** (`tools/details.py`).
  - The face patch is flattened to the sprite's own skin colour, then features are stamped from a
    small library: eyes (1x2 at 32 px, 2x3 at 48 px, with a highlight), brows, nose shadow, mouth,
    orc tusks, goblin nose and eyes. Dwarves get no mouth, because the beard covers it.
  - From behind, an eye, brow, nose tip and ear shadow are stamped only where the head shows skin,
    never on hair.
- **Rule passes on every sprite:**
  - Stray pixels are dropped and in-sprite noise is smoothed.
  - Leftover white background inside the silhouette (for example between the legs) is removed.
  - Anything outside the guide silhouette is clipped, which removes AI extras.
  - The 1 px outline is rebuilt.
  - Dwarf heads from behind are forced to hair, and goblin ears are put back on goblin skin.
- **The palette snap keeps hue** (OKLab with the a/b axes weighted 2.2x), so browns and greens stop
  turning grey.
- **Gear follows claude/research/sprite-design.md and Juzo's answers:**
  - Weapon, off-hand, helmet and chest change the shape.
  - Colour comes from the rarity only.
  - Plain tier: Common has grey trim, Uncommon green trim.
  - Fine tier: Rare has one band. Epic has the same shape with two bands and a 2x2 gem, so it is
    colour-blind safe.
  - Ornate tier: Legendary adds pauldron spikes, a new silhouette.
  - Mythic: emissive runes plus a glow ring and motes. Only Mythic glows.
  - Weapons are drawn in code in the palette and pinned to the hand; goblins get full-size weapons.
- **M1** is an AI base (img2img redrawn at 32 px), then the white holes are removed, then 12
  colours, then eyes, maw, teeth and claws placed in code, then checker dither on the main shade
  transition only, then a bold outline.
- **Town** (`tools/town3.py`), following the art-pipeline playbook section 9:
  - Buildings are 3/4 top-down (roof plus front wall), each from its own code-drawn block-out
    (`bguides.py`) run through img2img with canny. No two houses are the same.
  - Foundations have contact lines, and short cast shadows fall down-right.
  - A raised dungeon plateau has a cliff face and stairs cut into it.
  - Trees, props, lamps and villagers overlap and are drawn in depth order.
  - The grass is calm and desaturated.
  - Dusk uses a palette lookup table that keeps hues, with lit windows and lamp light pools.

## Technique references (technique only; no designs copied)
- SLYNYRD Pixelblog 3, graphical projection (3/4 top-down: roof plus foreshortened facade): https://www.slynyrd.com/blog/2018/3/14/pixelblog-3-graphical-projections-1
- SLYNYRD Pixelblog 51, city builder (structures rising above the footprint for overlap): https://slynyrd.com/blog/2024/7/25/pixelblog-51-city-builder
- SLYNYRD Pixelblog 45, walls and doors (wall tops lighter than faces): https://www.slynyrd.com/blog/2023/7/21/pixelblog-45-bricks-walls-doors-and-more
- Tuts+ "Kandi Runner" sprite tutorial (work at 1 px and check at 100%): https://design.tutsplus.com/tutorials/kandi-runner-create-a-pixel-art-sprite-from-scratch--cms-21705
- Aseprite community thread on small-sprite eyes (simplify; chibi head about 1/3 of the body): https://community.aseprite.org/t/i-cannot-figure-out-these-eyes/24563
- Mega Cat Studios dithering tips, and Divoom on when to stop dithering (dither only on transitions): https://megacatstudios.com/blogs/retro-development/dithering-tips , https://divoom.com/blogs/setup-ideas/pixel-art-dithering-when-to-use-and-stop
- Internal: claude/research/art-pipeline.md and claude/research/sprite-design.md (big-update branch).

## Known weak points (no need to spend critiques on these)
1. The 32 px human from behind still carries a grey slab on its left side, an AI extra that sits
   inside the arm area. It also shows on the weapon sheet.
2. The 48 px hero is much bigger than today's 32 px monsters. Choosing 48 means redrawing monsters
   at 48 too.
3. Faces at 32 px are tiny (eyes 1x2). The 48 px faces read clearly better.
4. The orc's back view is a large green head ball with a small topknot. The tusk from behind is only
   1-2 px.
5. Female dwarves (braids, no beard) are not drawn yet.
6. The armour sets are separate AI sprites on the human only, not yet layered on every race. The
   plate back needed a re-roll to drop an AI helmet.
7. The shield sits a little far left of the hand. The bow is held mid-grip but has no arrow.
8. M1 reads as a hulking ogre, but the pose is still mostly front-on rather than a dynamic lunge.
   Its colours are muted green-grey.
9. Town:
   - The plateau cliff face is thin (16 px). The guide called for 1-2 tile tall faces.
   - The roofs come out alike in colour at dusk.
   - The villagers are tiny placeholders drawn in code.
   - The light grass patches are still a little blotchy.
   - The river has no grate where it passes the walls.
