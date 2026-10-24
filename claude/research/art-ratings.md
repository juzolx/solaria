# Juzo's ratings (shared by every art session)

Every rating Juzo gives goes here, so all sessions learn what he thinks is really good and what is trash.

**Rules for every session**
- READ this file before generating or drawing anything, and again before each batch.
- Copy what scores high (8-10): its look, proportions, palette, pose, level of detail.
- Avoid what scores low (1-4) and the reason he gave.
- When Juzo rates something in your session, ADD a line right away (append at the bottom, don't edit others' lines). Use his own words for the reason, then one short "lesson" line in your words.
- Path for everyone: `C:\gamedev\solaria_dev\claude\research\art-ratings.md` (edit this exact file in the dev copy, not a copy in your worktree; the lead commits it).

**Format**
`date | session | item (sheet/label) | rating /10 | Juzo's words | lesson`

## Ratings

| date | session | item | rating | Juzo's words | lesson |
|---|---|---|---|---|---|
| 2026-10-23 | lead | art round 2 heroes (look C head, look B armour) | (pick) | "C head b armour" | combine darker head with slimmer armour |
| 2026-10-23 | lead | art round 2 town concept | low | "town looks hella flat" | towns need real 3/4 depth: walls + roofs, shadows, cliffs, layers |
| 2026-10-23 | lead | old dungeon backgrounds and monsters (in game) | low | "the dungeon doesn't look very good and neither does the monsters" | redraw, don't just clean up |
| 2026-10-23 | lead | art rounds 2-3 overall | low | "why does the art feel like it's getting worse" | too many forced rules, code-drawn stiffness, tiny size; quality over coverage |
| 2026-10-23 | lead | round 3b faces | low | "why are the faces so bad" | never let AI draw faces this small; hand-place face pixels |
| 2026-10-24 | lead | hero pass 1 weapons | good | "the weapons look good" | keep the weapon style |
| 2026-10-24 | lead | hero pass 1 body | low | "doesn't give the chibi vibe", "shapes for the body don't look great" | follow the old in-game hero proportions, more chibi |
| 2026-10-24 | lead | hero pass 2 arms | low | "arms are a little weird" | arms must flow shoulder > forearm > hand |
| 2026-10-24 | lead | hero pass 2 arm options | A and C liked | "A and C on arms" | relaxed arm default, rolled sleeves option |
| 2026-10-24 | lead | new hair styles vs old | prefers old | "I like the old hair options more... they seemed to fit well" | rebuild the old style list on the new body |
| 2026-10-24 | lead | old in-game hero creation | good | "they had it pretty clean in game" | one fixed frame set, every part drawn per frame |
| 2026-10-24 | monsters | anchor sample: Grendel G3 (moss-and-bark fen troll, 104x89, wisp-teal eyes) | picked | "g3" (from G1-G4) | creature anchor: bold outline, ~16 colours, chunky readable forms, moss mane + teal accent; PixelLab create_image_pro 112 with hero/zone-1 style strip |
| 2026-10-24 | monsters | anchor sample: ghoul A1 (gaunt crouched, teal-grey, torn grave cloth, 65x66) | picked | "a1" (from A1-A8) | normal monsters ~56-75 px, expressive 3/4 front pose facing the hero |
| 2026-10-24 | monsters | anchor sample: salamander S2 (rearing black-iron lizard with molten cracks) or S5 (horned low newt) | picked | "s2 or s5" | flames with dark cores, black scales + one hot accent read well |
| 2026-10-24 | pets2 | pets sample (baby Barghest/Banshee/Salamander + region eggs, 32 px on game palette, side 3/4 chibi) | good | "they look good" | chibi BABY of the species, big eyes, region accent colour, palette-locked 32 px; same recipe for the full roster |
| 2026-10-24 | pixellab-hero | PixelLab base hero vs hand-made hero (01_PL_vs_ours_compare) | good (picked) | "I prefer the PixelLab hero" / "i think its good especially when we code in multiple face and outfit options" | PixelLab v3 64 px hero with its rich shading is the reference look |
| 2026-10-24 | pixellab-hero | hair: 6 then all 37 old styles on the PixelLab hero (03_HAIR_library) | good | "its okay" | old style names/shapes on the new head, colours in code |
| 2026-10-24 | pixellab-hero | 4 portrait expressions (determined, smile, fierce, wary) | good | "i liked them more than i thought", asked for ten | 1-gen PixelLab face edits laid on in code work |
| 2026-10-24 | pixellab-hero | expressions smirk, sad, hurt | low | "smirk sad and hurt i dont like" | avoid winks / sad / injured faces; he wanted sleepy instead |
| 2026-10-24 | pixellab-hero | hero outline + shading vs style bible | keep hero | "Leave the hero as it is; the bible should follow the hero." | don't flatten to 3-5 shades; the hero sets the style |
| 2026-10-24 | town2 | town sample 1 (front-facing 3/4, 16 px tiles, img2img from code block-outs) | no rating (his later words: liked "the initial mockup more, those were exciting") | (see next rows) | the first, smaller sample beat the enlarged redo |
| 2026-10-24 | town2 | town sample 2 (hero scale: buildings enlarged 2.75x and redrawn, 32 px tiles) | low | "hate the look"; "dungeon looks bad"; "the grass looks bad the town looks bad"; trees "dont look placed right like most of the props" | enlarging small PixelLab art and redrawing it loses detail; scattered single trees/props look wrong: grow trees in belts, group props by purpose |
| 2026-10-24 | town2 | first ISOMETRIC PixelLab buildings (pixen 128 px: inn, smith, house, dungeon gate), 48x64 tree sheet, 32 px prop sheet | good | "why cant it look this good" (showed these as the target) | detailed isometric pixen buildings at native 128 px are the town look; don't force front-facing; keep native size |
| 2026-10-24 | monsters | Sheet B zone 0: 17 Grendel, 19 Black Annis on bone pile, 20 Hel (half corpse), 21 Dullahan (skull lantern) | 10 | "17-10 19-10 20-10 21-10" | big detailed bosses with a story prop (bone pile, own skull, half-skeleton) score top; keep boss detail level |
| 2026-10-24 | monsters | Sheet B zone 0: 1/2 kobold, 8/9 hobyah, 13 pooka, 14 wolpertinger, 18 Annis | 9 | "1-9 2-9 8-9 9-9 13-9 14-9 18-9" | clear silhouette + one prop (candle, antlers, horns) and moss motif = 9 |
| 2026-10-24 | monsters | Sheet B zone 0: 7 barghest, 10 jack-in-irons, 12 spriggan | 8 | "7-8 10-8 12-8" | solid; fine as is |
| 2026-10-24 | monsters | Sheet B zone 0: 3 redcap | 7 | "3-7" | thin pike figure reads smaller/flatter |
| 2026-10-24 | monsters | Sheet B zone 0: 4 boggart, 15 leshy, 16 woodwose, 5 wisp-lantern | 6 | "4-6 15-6 16-6 5-6" | plain round/thin bodies and object-like wisp score low; need more character and detail |
| 2026-10-24 | monsters | Sheet B zone 0: 6 wisp-ghost | 5 | "6-5" | cartoon ghost face = too cute/simple |
| 2026-10-24 | monsters | Sheet B zone 0: 11 jack-alt (skull cage) | 0 (as typed) | "11-0" | may be a typo for 10; not used either way (10 picked) |
