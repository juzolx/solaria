# Solaria art audit (first pass)

Sheets are made by `tests/_art_audit.gd` into `shots/audit/` (git-ignored; re-make any time):

    "$G" --path . --resolution 1400x1000 -s tests/_art_audit.gd

It also writes `shots/audit/stats.txt` (per-file size, palette depth, soft-alpha %, checker %, 2x-block flatness). Mark each asset below keep / fix / replace. All notes are a first pass from looking at the sheets and the numbers; nothing has been changed.

Pixel-size vocabulary: "1x art" means one art pixel = one screen pixel at the native size; "2x art" means each art pixel is a 2x2 block (the monsters, pets). Mixing the two on one screen is the biggest consistency problem.

## Summary table

| Group | Sheet(s) | Source and license | Native size | First verdict |
|---|---|---|---|---|
| Monsters, bosses (144 files) | monsters_z0..z9, monsters_calamities_unused | DCSS tiles (CC0), via tools/dcss_monsters.py; 10 myth monsters 2x by tools/make_myths.gd | 66x66 (128), 64x64 (11), bosses 66x66 or 66x130 (5) | keep, with fixes (see findings) |
| Heroes | heroes_races, heroes_classes_hair | LPC Universal Spritesheet Generator parts (art/lpc, 2743 files): CC-BY-SA 3.0/4.0, GPL 2/3, OGA-BY 3.0, CC-BY, CC0 mixed per part | 64x64 portrait, 1x art | keep art, FIX licensing check |
| Hero layers art/hero | not shown separately | older drawn layers (tools/make_art.py), unused while USE_LPC is true | 64x64 | candidate to delete |
| Item icons | items_icons, items_gear_layers_raw | art/gear layers drawn for Solaria (tools/art_gear.py), recolored at runtime | 12..42 px, mixed | fix in code (normalise size) |
| Consumables | items_consumables | DCSS tiles + "cc0 potion icons" (CC0); backpack and egg drawn for Solaria | 32x32 | keep |
| Zone backgrounds (60) | backgrounds_z0..z9 | made in-house (tools/make_backgrounds.py) | 320x180, 1x art | keep; fix the sub-area gaps |
| Dungeon props (28) | dungeon_props | DCSS tiles CC0; pot, lever, nest, mimic drawn for Solaria | 32x32 | fix in code / some replace |
| Dungeon floor and wall tiles | dungeon_tiles | DCSS tiles CC0 | 32x32 | keep |
| First-person halls | halls_textures | Screaming Brain Studios Tiny Texture Packs 1-3 (CC0), shrunk and palette-cut; doors drawn for Solaria | 32x32, doors 32x48 | keep, some zones too dark |
| Town map | town_map | LPC Revised (OGA-BY 3.0), [LPC] City outside and LPC Tile Atlas (CC-BY-SA 3.0 / GPL 3.0), bounty board drawn | 704x1088 x4 seasons | keep art, FIX licensing check |
| Effects | fx_frames | drawn for Solaria by tools/make_fx.gd (CC0) | 64px frames, strips | fix in code (see findings) |
| Companions | pets | DCSS tiles CC0, tools/art_pets.py | 66x66 | keep |
| UI skin | ui_pieces | drawn in code (ui_skin.gd), no pack | 2x art | keep |
| Brand | ui_pieces | icon.png 1024x1024, splash.png 504x896: made by tools/make_brand.gd | | keep |

Credits live in `art/*/CREDITS.md` and `credits.gd`. Sources are not in the repo: `art/pets/CREDITS.md` and `art/enemies/CREDITS.md` are copies of the same text; `art/halls/CREDITS.md` still points at `/home/claude/tex`, which no longer exists.

## Measured facts

- Monster sheet: 128 files are 66x66, 11 are 64x64 (afanc, ankou, baku, bog_body, div, gullinbursti, hobyah, jack_in_irons, mare, ningyo, mimic), 5 bosses are 66x130 (azgaroth, charybdis, duke_malgrath, seraphiel, typhon). `ArtInfo.DATA["enemies"]` still claims bosses are 96x96 and others 64x64; it is only used for the foot row, but the sizes in it are wrong. The 64px ones are the newer 0.13+ myth sprites (made by make_myths.gd); the 2px size difference is the outline ring the older pipeline adds.
- Four files in art/enemies are not referenced by any zone: boss_demon_ancestor, boss_sword_spirit, mimic, treasure_goblin (mimic and treasure goblin may be special spawns; check before deleting).
- Monster palette depth: about 59 colors on average (DCSS tiles have hard edges). Hero layers: about 6 colors on average (they are key-color masks that the game recolors, so they look flat on their own).
- Soft alpha (partly transparent pixels, i.e. anti-aliased or glow edges): halo_wisp 81%, grief_wisp 73%, will_o_wisp 62%, hellmaw 38%, umibozu 38%, boss_sword_spirit 22%. Every other monster is under 20% and almost all are 0%. The effects strips are 47 to 100% soft alpha.
- Backgrounds: all 60 are 320x180; about 95% of aligned 2x2 blocks are flat colour, so they are drawn on a 2x pixel grid (6px-ish features). They are the only art at that density besides the monsters.
- Checker-like 2x2 cells (possible fake dither or fake checkerboard): hero hair_buzz 23%, z6 floors 14%, z7 walls 11 to 12%, owlwraith 12%. Dither in the Ember Halls backgrounds is deliberate and clean.

## Top findings (worst first)

1. Mixed pixel density. Heroes are 1x art (LPC, 64px canvas, a head about 11 px wide), monsters, pets and backgrounds are 2x art (DCSS 32px doubled), props and consumables are 32px drawn at 1x but get scaled like the others. In the battle view a fine-pixel hero stands against chunky monsters. Suggest: fix in code first (draw heroes at 2x nearest, or test 1.5x), long term replace one side. Biggest single "does not look like one game" cause.
2. Licensing mix on the hero and town art. LPC parts are CC-BY-SA / GPL / OGA-BY mixed per part, and the town uses CC-BY-SA 3.0 / GPL 3.0 packs. Share-alike and GPL terms are a real problem for a closed App Store build, and the sources are not on this PC to re-check per part. Suggest: decide before release; either audit each used part (keep OGA-BY and CC0, replace CC-BY-SA/GPL ones) or replace. Not a pixel issue but the highest risk.
3. Monster palette clashes. Raw DCSS colours are saturated and unrelated to each other: grendel is blue and orange noise, will-o'-wisp is neon green, rune wraith is flat bright blue, imp is a bright red figure that fills about half the canvas. The dark grade tames some but not the neon ones. Suggest: fix in code (a per-monster hue/saturation clamp, or run the grade harder on a short list), replace grendel (looks like a noisy texture, not a creature).
4. Outline inconsistency. Monsters carry a black outline (added after the 2x upscale, so the ring is thinner than the body pixels on the 66px set; the 64px myths are built by a different script and are 2px smaller); heroes have no black outline at all, only the soft layer shading. Suggest: fix in code (one outline pass for every actor, or rely on the rim light everywhere).
5. Item icons are sized by the sprite, not the slot: sword 34x34, dagger 22x22, spear 42x42, orb 14x14, greaves 15x15. Inventory grids show wildly different sizes. Suggest: fix in code in Sprites.item_icon (pad to one square, e.g. 48x48, and scale small ones 2x).
6. Chest icons (tunic, plate, robe) and legs icons are the hero's clothing drawn flat, so they look like pale mannequin pieces with a rarity-coloured stripe; greaves is two tiny slivers. The weapon icons read well. Suggest: replace chest, legs and feet icons with proper item art (DCSS armour tiles are CC0 and available), keep weapons.
7. Dungeon props that do not match their names or the art style: pillar is a purple blob (not a pillar), trap_flames is a cyan skull ring and trap_frost is a red pentagram (colours look swapped), boulder is a flat brown ball, npc is a realistic-style human at a different style from everything else, nest and pot are simple hand-drawn shapes next to DCSS detail. Suggest: replace pillar, boulder, swap or redraw the two trap rings, keep the rest.
8. Effects (fx) are almost entirely soft-edged: 47 to 100% partially transparent pixels, slash and heal 100%. They read as blurred glows, not pixel art, and are the likeliest "AI-looking" asset (soft gradients, no hard pixel edges). Suggest: fix in code first (quantise alpha to 0/255 on load, optional), replace slash, heal, burst if still soft.
9. Wisp family (halo_wisp, grief_wisp, will_o_wisp) and hellmaw/umibozu have gradient glow edges (38 to 81% soft alpha) unlike the hard-edged rest. Suggest: fix in code (alpha-threshold on load); replace if it still looks smudged.
10. Sub-area backgrounds reuse one base image per zone with small additions: in Ember Halls (zone 3) all six share the same pillars, ground and lava stripes; the Muspel Gate sub-area is a block of noise, not a gate. The room is the same room six times. Suggest: keep the zone defaults, replace the weakest sub-areas (Muspel Gate first).

Also noted:
- Hero masc and fem builds are identical in the portrait (the build setting changes nothing visible); race variety comes only from add-ons (ears, horns, wings, tails). Fairy wings have white dotted edges that look like leftover noise. Suggest: fix in code or replace wings_fairy.
- `art/hero/` (47 files, older drawn layers) is not used while `Sprites.USE_LPC` is true. Delete or archive.
- Town art is clean and consistent with itself (one LPC palette); its pixel density (1x art, 32px tiles) differs from the 2x monsters and backgrounds.
- Halls: the z0, z2, z3, z4, z5 and z9 ceilings are nearly black and show no detail; z0 and z5 floors are both flat mossy green. Seams and repeats should be checked in 3D, not on the sheet.
- Skill icons are fx frames shrunk to 32x32 (stored 64px frames), so they inherit the soft edges of finding 8 and look inconsistent with each other.
- `art/halls/CREDITS.md` source path (`/home/claude/tex`) is stale; `art/pets/CREDITS.md` repeats the monsters text.

## Per-group notes

### Monsters (monsters_z0 ... z9, monsters_calamities_unused)
Each tile shows the raw PNG and the dark-graded version the game uses. Zones 0-4 are the roots, zones 5-9 the realms (Hushwood, Glimmer Court, Ironroot Deeps, Dawn Choir, Cinder Abyss). Most sprites are good DCSS art with a consistent 2x look. Problems: finding 3 (palette), finding 4 (outline), and a few that read poorly small: owlwraith (9 colours, checker pattern) and hellmaw (soft glow). The 66x130 bosses are twice as tall as the others on purpose; check they fit the battle layout. Suggest: keep, fix in code.

### Heroes (heroes_races, heroes_classes_hair)
Every race on the same LPC body. Clean, readable, good. Problems: finding 1, masc/fem sameness, the pale default clothing (all heroes wear the same beige shirt and blue trousers when no gear is on). Class kits look right. Suggest: keep.

### Items (items_icons, items_gear_layers_raw, items_consumables)
Weapons and off-hands good; chest, legs, feet weak (finding 6); sizes inconsistent (finding 5). Rarity is shown as a small coloured band or gem, easy to miss at 1x; Legendary and Mythic differ only by one pixel colour. Consumables (DCSS style) are the nicest icons in the game and set the bar. Suggest: keep consumables, fix weapons' sizing in code, replace armour icons.

### Backgrounds (backgrounds_z0 ... z9)
60 files, 320x180, strong silhouettes, dithered gradients, consistent. The dark grade darkens them well. Weak: the sub-area variants (finding 10). Suggest: keep, replace the weakest sub-areas.

### Dungeon props and tiles (dungeon_props, dungeon_tiles)
DCSS at 32x32: fine. Findings 7. Floors and walls: z6 floors and z7 walls show a checker/regular pattern (11 to 14% checker cells) that will repeat visibly when tiled. Suggest: keep tiles, replace the listed props.

### Halls (halls_textures)
Screaming Brain textures at 32x32, palette cut: consistent with each other, stylistically different from the DCSS sprites placed on them (smoother, more noise). The doors (32x48) are Solaria-drawn and look good. Suggest: keep; brighten the near-black ceilings in code.

### Town (town_map)
Four seasons of one 704x1088 map, tidy LPC look, readable. See licensing (finding 2). Suggest: keep, decide on license.

### Effects (fx_frames)
See findings 8 and the skill icon note. Frame counts are 8 to 16 per effect, 64px frames, and every strip width divides evenly by 64.

### Companions (pets)
20 files, 66x66, DCSS-based, 4 stages per class: consistent with monsters. Keep.

### UI (ui_pieces)
Frames, bevel buttons and backdrop are code-drawn, in a single iron/soot/torch palette: the most consistent part of the game. The backdrop is a 168x300 brick pattern stretched to the screen. Suggest: keep.

## 2.1 "A1 unify art in code" (done on wt/art)

- Rules in `art_style.gd` (palette of 74 colors, outline #0e0812, sizes); `art/palette.gpl` for artists.
- `tools/bake_art.gd` bakes them into the PNGs: monsters/bosses/Calamities/pets on one 2x grid,
  68x68 (giants 68x132), one art-pixel outline, shadows stripped, hard alpha; props and consumables
  palette + 1 px outline; effects palette + 5 hard alpha steps; pillar and boulder redrawn; flame/frost
  trap art swapped; art_info.gd "enemies" sizes and feet rewritten from the files. Re-runnable (a second
  run changes nothing). To bake with a changed palette, restore the originals first
  (`git checkout 87b37477 -- art/enemies art/pets art/dungeon art/consumables art/fx`), then rerun.
- Monsters now stand on their real feet (`Sprites.enemy_by_key` measures the picture; the old table
  put e.g. Azgaroth's feet 37 rows too high, sinking bosses below the ground line).
- Gear icons: one 44x44 frame, no scaling. Hero pixel switch: `Sprites.HERO_PIXEL` (1 today, 2 = 2x grid).
- `tests/stage6_art_rules.gd` guards all of it. Before/after sheets: `shots/art_after/before|after/`.
