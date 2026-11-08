# Weapon icons audit (7 Nov 2026, branch big-update)

Owner: "weapon icons need to be fixed that is the last big art fix" / "new art for the solaria weapons there trash lowkey" / "I need 1 demo, we fix it and make the rest using the same logic".
Status: diagnosis done, ONE demo made (4 icons, 20 PixelLab generations). Nothing in the game changed. Waiting for owner OK on the demo.

## 1. What exists and where it is used

**There is no real icon set.** Every weapon icon is made at run time by `Sprites.item_icon()` (sprites.gd:514) from
the 7 old hero-overlay layers `art/gear/{sword,axe,dagger,mace,spear,bow,staff}.png` (key-coloured masks drawn for the
old LPC hero, recoloured by material + a rarity "trim" colour, cropped, centred in a 44x44 frame, `ArtStyle.ICON_FRAME`).
So 7 drawings are the whole weapon art. Everything else is recolour.

149 weapon icons are produced (dump: tests/_weapon_icons_dump.gd, sheets C:\Users\count\heads\pics\weapon_icons_sheet_1..5.png):

| Group | Count | Shapes used |
|---|---|---|
| 7 types x 6 rarities that change the look (Common, Uncommon, Rare, Epic, Legendary, Mythic) | 42 | 7 |
| Zone drops (ItemPool.ZONES, 5 per zone x 10 zones) | 50 | 7 |
| Uniques (GameData.zone_uniques) | 11 | 3 |
| Set weapons (SETS 6) + evolution sets (4) | 10 | 5 |
| Monster signatures (Monsters sig) | 26 | 7 |
| Race gear weapons | 6 | 5 |
| **Total** | **149** (107 named items + 42 generic) | **7 drawings** |

Calamity (Mythic) weapons use the generic types. No weapon cosmetics exist (Realms.COSMETICS has none).
Only 91 of the 149 pictures are pixel-different; the rest are literal copies (e.g. 11 swords, 10 spears share one picture).

Where they show (all through `Sprites.item_icon`): Bag grid (item_grid.gd `UiIcons.big(icon, 44)`), bag detail (56), Gear tab doll and
slot list (48), Hero tab doll (52), Stash (48), Shop list (44) and featured (64), Craft (44), Merchant popup (40), Collection/codex
tab (40), loot drop on the fight floor (battle_view `_drop_item`, raw 44 texture scaled by the fight unit), item popups, drag ghost.
The Wheel tab and codex.gd do not show weapon art. `UiIcons.STAT_ICON` also reuses the old art/gear pictures: STR = mace, DEX = dagger (stat tiles on the Hero tab), so those change too.
Hero held weapons are separate: PixelLab sheets `art/heroes/<body>/weapon_<type>.png` (7 types x 10 bodies, 9 frames, ~12-16 px weapon, rated 10/10 "warrior ten") through hero_art.gd. They are per type, not per item.

## 2. What the owner already said (claude/research/art-ratings.md, art-critique.md, art-audit.md)
- 24 Oct: hero weapons (the PixelLab ones) "look good" and "warrior ten good work": keep the held-weapon look.
- art-critique: wanted a "dedicated 32x32 icon set, rarity by frame colour + gem tint, 45-degree weapons, 2 px shafts". Never done.
- art-audit finding 5: icons sized by sprite not slot (sword 34, dagger 22, spear 42): partly fixed with the 44 frame, not the real problem.
- art-audit: consumables (DCSS 32x32) "are the nicest icons in the game and set the bar".
- "the ui has to match the game... everything cohesive": no one-off AI pieces; use the game's palette, outline and pixel scale.
- Standing rule: monsters must read on a phone: strong silhouette, bright accent, fewer tiny details.

## 3. Concrete problems (see sheets 1-5)
1. **Not the game's art language.** Old LPC-era hero overlay recoloured; soft 12-16-colour shading, no consistent dark outline (the hero, monsters and potions have the #0e0812 1 px outline). Next to potions/monsters they look like a different game.
2. **Tiny and thin in the cell.** Sword 12x32, spear 12x40 (2 px shaft), bow 12x32, staff 12x36, in a 44 px frame at 1x: skinny sticks. The bow's "string" is a 1 px white bar that reads as a white line, not a bow.
3. **Inconsistent pixel size on the same screen.** `UiIcons.big` doubles an icon only if 2x still fits: the dagger (10x20) is doubled in the bag grid (fat blocky pixels) while the sword/axe/mace/spear/bow/staff stay 1x. In the Shop (64) and detail (56) boxes other icons get doubled. The same sword is 1x in the bag and 2x in the shop.
4. **Non-integer scaling.** 44 px texture shown in a 40 px box (Merchant popup, Collection tab) and 48 px box (Stash, `info_pic`): nearest-neighbour drops or doubles rows/columns, so edges look uneven/blurry.
5. **Only 7 pictures for 107 named items.** All 10 zone swords look identical, 10 spears identical, etc. Rarity/material is a 1-3 px hilt-band colour change; Legendary and Mythic differ by one pixel colour (art-audit saw this too).
6. **Duplicates / mismatches:** 6 uniques (Warden's Last Arrow, Jester's Last Joke, Brann's Hammer, Dawnbreaker, Valeth's Verdict, Hellbrand) have no `SPECIAL_TYPES` entry so fall back to the plain steel sword, pixel-identical to each other (idx 097-102 on sheet 3). Brann's Hammer and Warden's Last Arrow are swords. Zone names do not match the shape: Gravedigger's Spade, Drowned Harpoon, Thornwhip Spear, Strangleroot Whip, Hymnspear = the same spear; Clockwork Crossbow = a longbow; Wand of Bad Ideas = a staff with an orb; Birch Switch is pixel-identical to the Mythic staff.
7. **Palette clashes.** Materials come from ArtInfo.materials (LPC-era ramps), not `art/palette.gpl`; trim colours are the UI rarity colours (#60a5fa blue, #c084fc, #fb923c) which are not palette colours.
8. **Silhouettes:** sword/mace/spear read OK at 3x but at 1x (what the player sees) the 12 px wide shapes are specks; dagger at 2x is the only readable one. Axe head is a grey blob without a clear edge.
9. **Do not match the hero's held weapon.** The hero holds a PixelLab-drawn sword/axe etc. (shape, steel + wood ramp); the icon is a different drawing. The hero never changes its weapon with rarity, so the icon should be the same design family.
10. Missing icons: none (every item resolves). Placeholder: none.

## 4. Full-set plan (new art, as the owner asked)
**Style:** 32x32 native pixel art (the same size as the potion/consumable "bar", 1x art, one pixel scale), palette-locked to `art/palette.gpl`, 1 px #0e0812 outline, 3-4 tone shading, bright edge highlight, diagonal pose tip to the upper right (the old critique's "45-degree weapons"), transparent background, no cast shadow.
**Rarity is NOT new art.** The item cell already draws a rarity-coloured border (item_grid.gd `edge = rarity colour`). Keep that, plus in code: a small 2-3 px glow/sparkle overlay for Legendary and above, and (optional) a tint of the gem/trim only if the art is made with a recolourable key colour. So no tier x rarity multiplication: 6 rarities = 0 extra pictures.

Icon counts (each icon = one 32x32 picture):
| Phase | What | Icons | Gens @5 each | With ~50% rerolls |
|---|---|---|---|---|
| P1 | 7 base types (sword, axe, dagger, mace, spear, bow, staff). Covers every generic item, all 50 zone drops, mythic, etc. | 7 (4 already in the demo) | 35 (15 left to spend) | ~50 |
| P2 | One distinct icon for each of the 11 uniques, 10 set/evo weapons, 26 signatures, 6 race weapons | 53 | 265 | ~400 |
| P3 (optional) | Distinct icon per zone drop (50 names). Fixes the name/shape mismatches | 50 | 250 | ~375 |
Total all phases: 110 icons, 550 generations, about 825 with rerolls. Today: 187 generations left (reset 24 Nov, then 2000). P1 fits now; P2 and P3 fit after 24 Nov. Credits balance in USD is $0, so only the plan generations count.

**Method comparison** (prices from the PixelLab tool docs / get_pro_flash_capabilities):
- A. pixelart_workbench free hand redraw: 0 credits, but I would be drawing 32x32 pixels by hand; the owner preferred PixelLab over hand-made hero; high risk of "stiff" art. Use it only for fixes (see below).
- B. PixelLab Pro Flash `create_object_pro_flash` n_directions=1, 32x32: 5 gens each, palette lock supported, ~26-33 s each, runs in parallel. Best consistency/quality. **Recommended.**
- `create_1_direction_object`: 10 gens for 16 candidates (pick one): more choice, double the price. `create_image_pixen`: 1 gen but no palette lock or style image; maybe for P3 drafts then free `reduce_colors`/palette snap.
- C. Mix (recommended): B for all pictures, workbench `edit` (free, exact) to fix stray pixels, thicken a thin blade, restore the outline, and `reduce_colors` to the palette. Code (free): rarity border/glow, material tint if wanted.

**Held weapons stay matched.** The hero's held weapon sheets are not touched (type-level, rated 10/10). The icon for each of the 7 types must be the same design as that type's held weapon: for P1 use the upright frame from `art/heroes/m/weapon_<type>.png` (crop to the weapon) as the reference (`style_image`, must fit inside the 32x32 canvas, usage_description "same blade/head shape and steel+wood colours") or describe the held sprite's shape in the prompt. P2/P3 items inherit their type's base shape and add the story detail. Test this on the sword in demo 2 (not done yet, owner said one demo only).

**Code change after art is approved (not done):** ICON_FRAME 44 -> 48 or 36 so 32 px art fits an integer multiple; make `UiIcons.big`/`item_icon` use one fixed scale per screen (no per-icon doubling) and fix the 40/48 boxes (Merchant, Collection, Stash) to integer scales; add SPECIAL_TYPES for the 6 mapping holes; swap `art/gear/*.png` icon use for `art/icons/weapons/<type>.png` (+ per-item `<id>.png`) with a fallback to the base type; update STAT_ICON mace/dagger. Tests to change: stage6_art_rules.gd 405-406, stage6_slots.gd 66-67 (ICON_FRAME size checks).

## 5. Demo 1 (the only one made)
Sheet: C:\Users\count\heads\pics\weapon_demo_1.png (new vs old at 1x and 3x, next to the hero, the Ankou and a potion at the same 3x scale).
Cost: **20 generations** (4 icons x 5, one try each, no rerolls). Balance 207 -> 187 generations. $0 credits used.
Honest read: clean 1 px outline, palette-locked, consistent with the potion bar, a big step up from the old icons (axe and staff especially). Weak points: the sword is thin (~10 px wide) and the bow thin/small and both only fill about 60-70% of the 32 px box; the next prompt should say "fills the whole canvas, thick chunky blade/limbs". Not yet matched to the hero's held weapon (no style image used).

### Exact recipe (use the same for every icon)
- Tool: `mcp__pixellab__create_object_pro_flash`, `n_directions=1`, `width=32`, `height=32`, `view="side"`, `max_colors` unset, `seed` unset (0), one icon per call, send 4 in parallel then `wait_for_jobs`, then `get_object` (the inline PNG is saved to the session tool-results folder; the PNG URL in the reply is the 32x32 source).
- Palette (every drawn pixel is locked to these 45 colours = the 44 core palette colours from art/palette.gpl + the outline):
  `#0e0812 #be4a2f #d77643 #ead4aa #e4a672 #b86f50 #733e39 #3e2731 #a22633 #e43b44 #f77622 #feae34 #fee761 #63c74d #3e8948 #265c42 #193c3e #124e89 #0099db #2ce8f5 #ffffff #c0cbdc #8b9bb4 #5a6988 #3a4466 #262b44 #181425 #68386c #a8624a #8f563b #5a3f35 #a3825f #c8b08a #fff4a3 #c28569 #7d8798 #545d70 #a8a8ba #4a4852 #34323b #1f1d24 #625f6a #c8a060 #9a7040 #6a4a28`
  (the full 74-colour list can be passed too; the narrower one gives steel/iron/wood/gold/ember tones.)
- Prompt template: `pixel art game item icon of <THING with 2-3 defining parts>, lying diagonally, tip/head pointing to the upper right, bold 1 px near-black outline, chunky readable shapes, 3-4 tone shading with a bright edge highlight, dark fantasy, transparent background, single object centered`
  Demo things used: "a steel longsword ... simple crossguard and leather-wrapped grip"; "a one-handed steel battle axe ... crescent axe head at the upper right, dark wood haft with leather wrap"; "a wooden hunting longbow with a taut pale string, bow curved, arrow nocked"; "a gnarled wooden mage staff ... glowing blue crystal held in twisted wood claws".
- Add for the next batch: "fills the whole 32x32 canvas, thick chunky blade/limbs, at least 4 px wide" and (to match the hero) the `style_image` = the held-weapon crop, `style_options` colour_palette/outline/shading true.
- Outline rules: 1 px #0e0812 on the outside only; inside lines may be a darker local tone; no anti-aliasing, no semi-transparent pixels (run `correct_pixelart` or workbench `edit` for strays), transparent background, no ground shadow.
- Size rules: 32x32 files, 1x art, shown at integer multiples only. One fixed scale per screen.
- Rarity: border colour (existing) + glow overlay in code. Never separate art per rarity.
- Per-item named weapons (P2/P3): keep the type's base shape; change ONLY a story prop/colour: e.g. Hrunting = steel blade with a red gem pommel; Flame of Muspelheim = ember blade with flame edge; Scylla's Fang = bone spearhead with cyan tint. Use materials: steel #c0cbdc/#8b9bb4/#5a6988, iron #5a6988/#3a4466, wood #b86f50/#8f563b/#5a3f35, bone #ead4aa/#c8b08a, gold #fee761/#feae34, ember #fee761/#f77622/#be4a2f, crystal #a4dddb/#4fb0c6.
- Check each icon at 1x in a 44 px cell and at 3x next to a potion before accepting; save to `art/icons/weapons/<id>.png`.

PixelLab object ids of the demo (all private to the owner's account): sword c82c5bd4-b0a4-46fc-80a0-9bdb0787b9cc, axe bb15de54-97e5-4e28-858e-47d9e9053706, bow d1029e29-23ce-43ee-a2eb-eff7abf772ae, staff f62bc3fb-3980-418a-acb9-58ae7b555dc6.

## 6. Files made by this audit
- tests/_weapon_icons_dump.gd, tests/_demo_refs.gd: read-only helpers (headless, override.cfg in place). New files, uncommitted.
- Sheets: C:\Users\count\heads\pics\weapon_icons_sheet_1.png ... _5.png (149 icons, red text = pixel-identical to an earlier icon), weapon_demo_1.png.
- Note: running Godot touched tracked `.godot/` cache files (git status shows them modified); not committed.

## 7. Demo 2 (owner: "not dark fantasy, must work with the character holding them")
Sheet: C:\Users\count\heads\pics\weapon_demo_2.png (demo 2 vs demo 1 vs the hero holding each weapon, 1x and 3x). Cost: **20 generations** (4 x 5, one try each; the first bow call failed on a bad base64 and was not charged). Balance 187 -> 167.
Object ids: sword 665a0574-e161-4ed7-9222-9257799fad51, axe 16d68007-0e88-4a86-b8fd-1809951e81ea, bow 713b7387-e58e-4d0c-a7f0-e6b02a320ef3, staff 743614ac-fb62-422c-b2c8-a30516d83d4f.

Read: clearly darker (blackened iron, worn wood, bone, one accent), thicker, outlined, and the axe/bow/staff follow the hero's held shapes (staff = twisted wood + crystal in claws, cyan accent; bow = recurve; axe = bearded head). Problems to fix in the next round, if the owner picks this direction:
- **Dark on dark.** The bag cell is dark, so the sword and bow lose contrast at 1x. The old monster rule applies: lighter mid-tones or a 1 px light rim on the blade/limbs, and the bright metal edge must stay one of the brightest pixels.
- Fill is about 85-90% for the sword, 70-80% for the axe/bow/staff (the bow string is a busy hatch pattern; ask for "no string detail, a single 1 px light line").
- Axe came out as a double-bit axe (two heads); the hero's is single-bit: say "single-bladed" explicitly.
- **The hero's held sword is a 1-3 px white sliver** (art/heroes/m/weapon_sword.png cells are 3x14 to 17x8 px), not a usable reference; the sword icon was made from text only. Fixing the hero's held sword (a visible blade) is a separate small job and is the one place "icon matches what the hero holds" cannot be met today. Cost estimate: 7 weapon types x 9 frames are redrawn only for sword (rated art, so ask the owner first).

### Recipe v2 (replaces the prompt rules in section 5; tool, size and palette method unchanged)
1. **Reference crop** (style_image, must fit INSIDE 32x32, so crop to the weapon): from `art/heroes/m/weapon_<type>.png` (sheet = 9 cells of 128 px; cell 0 = back idle, 7 = front idle). Crop the used rect of the front cell: axe cell 7 (18x28), bow cell 7 (30x31), staff top 28 rows of cell 0 (21x28; the full staff is 57 px tall and is refused). `tests/_demo_refs2.gd` dumps the crops. Pass as `style_image.base64`, `usage_description` = "The weapon the hero holds: copy its silhouette and steel/wood colours, make it darker, thicker, more worn. Ignore the hand." Leave `style_options` at the default (all true). A re-saved PNG (System.Drawing) is safer: PNGs with extra chunks broke in transit once; a failed call is not billed.
2. **Palette** (23 colours max, outline included; one accent colour family per icon): `#0e0812` outline; steel/iron `#c0cbdc #8b9bb4 #7d8798 #5a6988 #545d70 #4a4852 #3a4466 #34323b #262b44 #1f1d24 #181425 #625f6a`; leather/wood `#a3825f #8f563b #733e39 #5a3f35 #3e2731 #2a1a1e #6a4a28`; bone `#ead4aa #c8b08a`. Accent (pick ONE per icon): ember red `#a22633 #e43b44` (blade rune), cyan `#2ce8f5 #0099db #4fb0c6 #a4dddb #124e89` (crystal), etc.
3. **Prompt template:** `pixel art dark fantasy item icon: <weapon> like the reference the hero holds but worn blackened iron / dark weathered wood, leather wraps, bone detail, <ONE accent glow>. Lying diagonally, tip/head to the upper right, fills about 90% of the canvas, thick chunky parts at least 3-5 px wide, bold 1 px near-black outline, muted desaturated tones, a light 1 px edge highlight on the metal, menacing, transparent background, single object.` Say "single-bladed" for the axe, "no string detail" for the bow. Never "wood brown/bright/clean".
4. Same size/outline/rarity rules as section 5 (32x32, 1x, #0e0812 outline, rarity = cell border + code glow). Contrast check: view each icon on the bag cell colour at 1x; if it dissolves, add the light rim with workbench `edit` (free).
5. P1 order if approved: finalise sword (needs the hero sword fix or a text-only icon), then dagger, mace, spear from the same recipe (use `weapon_<type>.png` crops, dagger/mace/spear not yet checked for crop size).

## 8. Built (wt/weapons, 7 Nov 2026)
Generations: demo 1 20 + demo 2 20 + build 115 (6 base redos 30, 11 uniques 55, 6 set weapons 30) = 155 of the 207 at the start; **52 left** (reset 24 Nov). In `art/icons/weapons/`: sword, axe, dagger, mace, spear, bow, staff (staff is the demo 2 icon), 11 `u_<id>`, 6 `set_<piece id>`. Not drawn (use their type's picture): 26 signatures, 6 race weapons, 4 evolution-set weapons, the 50 zone drops. At 5 generations each these are 86 icons = 430 (about 645 with rerolls): next cycle.
Known weak spots: the bow keeps two pale dashes where the string should be; Hrunting and Flame of Muspelheim are upright, not diagonal; the sword is a broad blade.
Code: see `claude/stage2-progress.md` (7 Nov entry). Rule for new icons: save as `art/icons/weapons/<key>.png` (key = the item's `art` e.g. `s_barghest`, `r_<id>`, or `set_<piece id>`), no code change needed.
