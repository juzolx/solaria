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
| 2026-10-24 | town2 | isometric town sample (iso.py: liked iso buildings + tree sheet + 32 px props, iso ground tiles, code wall, fog outside) | good | "i like it it needs major cleanup and idk how the people are gonna be in there" | isometric direction approved; next: clean seams/slabs/edges and prove small walkers fit |
| 2026-10-24 | lead | hero direction | decision | "each class has their own outfit... their weapons still change" | class outfits + visible weapon; armour stats only |
| 2026-10-24 | monsters | Sheet C 5 ankou (hooded skeleton reaper, scythe with hanging candle lantern) | 10+ | "5- 20" | iconic silhouette + a light-source prop (lantern/candle) = his favourite; reuse props that glow |
| 2026-10-24 | monsters | Sheet C 1 draugr, 3 banshee, 4 strigoi, 8 gashadokuro, 12 ghoul, 15 woodwose redo (deer-skull mask), 17 redcap redo (dripping cap, pike-axe) | 9 | "1-9 3-9 4-9 8-9 12-9 15-9 179" | redos with a story prop beat the plain versions (woodwose 6 -> 9, redcap 7 -> 9) |
| 2026-10-24 | monsters | Sheet C 6 bog body, 10 moroi, 11 garmr, 13 boggart redo, 16 wisp redo (ghost-fire creature) | 8 | "6- 8 108 11- 8 13- 8 16- 8" | wisp as a creature with a lure lantern beats the object (6 -> 8) |
| 2026-10-24 | monsters | Sheet C 2 barrow-wight, 7 revenant, 9 vetala, 14 leshy redo | 7 | "2 - 7 7-7 9-7 14-7" | thin upright armoured/limb figures read weaker; redo only if budget allows |
| 2026-10-24 | town2 | iso sample cleanup + 24 px townsfolk | ok, placement off | "yes but the placement of everyhting is off" | lay out streets first; anchor buildings by their base corner on the grid with doors facing a street; props against walls/doors; trees in belts only |
| 2026-10-24 | lead | UI pass before/after | low | "it looks the same" | cleanup is not a redesign: needs real UI art, layout changes |
| 2026-10-24 | lead | monster names and monsters | low | "the names for the monster and the monster themselves need to be easier for everyone to read" | bigger outlined names; strong silhouettes, contrast vs zone background |
| 2026-10-24 | monsters (via lead) | all monsters: readability on the phone | rule | "EASIER FOR EVERYONE TO READ on the phone": strong simple silhouette, clear contrast vs the zone's dark hall (lighter mid-tones or a subtle rim light, no dark-on-dark), big readable eyes/mouth/claws/weapon as the brightest accents, fewer tiny details, consistent size filling the frame | check every monster at 1x on a 430x932 battle shot against its real zone background before sending; redo any that blend in |
| 2026-10-24 | halls | 3D halls zone 1 Catacombs sample (PixelLab 32x32 skull-stone walls, mossy slabs, vaults, skull-keystone door) | approved | "Approved. Do the other 9 zones" | seamless 32x32 tiles_pro textures snapped to the house palette, one signature motif per zone |
| 2026-10-24 | halls | 3D halls, all 10 zones (before/after per zone) | good | "3d rooms look good" | keep textures dark and muted (light/brighter versions washed out under zone lighting); bright accent only in doors/torches |
| 2026-10-24 | town2 | grid placement v2 (iso2) | still off | picked: "Pasted-on buildings", "Walls too blocky", "Too empty / spread out" | strip the ground slab PixelLab bakes under iso buildings; walls darker and lower with small merlons; fill the town with real buildings ~1.5 tiles apart and 3-tile streets |
| 2026-10-24 | halls | room props + events (chest, mimic, shrine, nest, campfire, camp, champion gate, traps) before/after | good | "these all look pretty good"; fix placement: champions gate "needs to fit the door and look like a portal", camp "more to the side not on the doors", statues "there every step of the way no bueno" | place events so they never cover the doors; a gate fits its doorway; repeated decor (statues) must be rare, not in every room |
| 2026-10-24 | pets2 | full pet roster (150 sprites: 110 baby species, 10 Calamity pets, 20 companion stages, 10 eggs) + re-rolls of cherub/throne warden/ash fiend/root grub | good | "pets look solid" | the 32 px palette-locked chibi recipe holds across a whole roster; re-rolls with a prop/light source and lighter mid-tones fixed the weak ones |
| 2026-10-24 | town dev 2 | town layout v3 (labeled iso block map: wall ring, sealed gatehouse, main street gate -> bridge -> market square -> dungeon plateau, every building lot) | approved | "i like the layout but the art needs to fit the layout as well i liked the vibe but it didnt fit"; "dont reuse the art" | plan the layout first, then draw NEW art sized to each lot's footprint (same detailed iso vibe); old pieces didn't fit their spots |
| 2026-10-24 | interface | UI redesign mockups (Hero + Fight screens, A iron & leather / B clean stone / C parchment journal) | B picked | "stone looks the best but it still doesnt look perfect we definitley need a lot of touch up and redesign but iu like the direction" | clean dark stone panels + crypt-arches backdrop is the UI direction; hero-centrepiece and icon layout liked; next round polishes stone (contrast, spacing, fewer empty areas) before any game code |
| 2026-10-24 | pixellab-hero | class sample: Warrior + Cleric outfits on both bodies, battle idle/attack/hit + portrait (classes/01_CLASS_sample.gif) | good | "class samples look good where gonna have to make uniqe outfits for a lot of classes though especially upgrades" | per-frame PixelLab outfit edits with a precise, identical outfit description per frame work; plan cheap upgrade looks |
| 2026-10-24 | town2 | iso layout 3 (all 11 buildings, slabs stripped, walls all round) | still off | "Still off:" (no detail); town restarted in a fresh session | see claude/town_handover.md on wt/town2 |
| 2026-10-24 | interface | stone v2 mockups (PixelLab frames/buttons/icons + crypt bg) | low (direction rejected for the art source) | "the ui has to match the game we cant randomly use weird ai art for things we have to make everything cohesive and playable" | UI must be built from the game's own art language (palette, outline, pixel scale, same sprites/icons the game uses), not one-off AI pieces; study great game UIs first |
| 2026-10-24 | halls | champion gate redo: the middle door itself becomes a glowing portal (PixelLab 32x48 portal arch replacing the door art) | good | "champions gate looks good" | event that belongs to a door should replace that door, not stand in front of it |
| 2026-10-24 | halls | trap plates (square framed stone plates with icon-like spikes/darts/fire/frost/smoke/alarm) | low | "traps look cheesy" | traps should not look like UI tiles: no square frames or icon symbols; blend into the floor as subtle, natural details |
| 2026-10-24 | interface | UI v3 mockups built only from game art (palette.gpl chrome, Pixelify Sans on the art grid, real hero/ankou/gear/potion icons, zone backdrop) | ok, promising | "dont hate it but would need to see it on the actual game a worthy beginning" | game-art-only, one-grid UI is the right base; prove it in the real game before more mockups |
| 2026-10-24 | pixellab-hero | Warrior class tiers base > 15 > 35 > 75 (tiers/02_WARRIOR_tiers.gif) | good ("definitely on the right path") | "weapons change mid swing just needs some touch up but definitely on the right path" | tier chaining works; weapons must keep ONE shape across frames: place one weapon drawing per frame in code |
| 2026-10-24 | pixellab-hero | Warrior: class outfit + tiers + one-shape weapons (tiers/02, classes/03_WEAPONS_fixed) | 10/10 | "warrior ten good work" | this is the bar for every class: precise per-frame outfit wording, chained tier edits, same-size frame set, one drawing per weapon |
| 2026-10-24 | monsters | all 142 redrawn monsters, sheets E-L (zones 3-9, every boss, 10 Calamities) + in-game sheet M | top | "they look amazing" | the monster bar for every session: native ~60-78 px (bosses ~110, Calamities ~130), bold outline, story prop + one glowing zone accent, lifted mid-tones so they read on the dark halls |
| 2026-10-24 | interface | v3 look in the real game (palette-only chrome, Pixelify Sans, 2x-grid icons from game art, Hero stage with plinth + gear paper doll) | good | "it looks super solid" | game-art-only, one-grid UI works in-game; extend it to the Fight panel, enemy plate and the remaining screens |
| 2026-10-24 | town dev 2 | town layout: market square | decision | "mailbox can move the market should be where the well market square and market stalls are as one big thing" | the Market is the whole square (well in the centre, ring of stalls, one tap area); small services (Mailbox by the Inn, Bounty Board by the dungeon stairs) sit off the square |
| 2026-10-24 | town dev 2 | composed town with all-new fitted art + one-place Market | good ("much better") | "town looks much better its a little crowded so maybe a map would be nice ... work on making the walls and church look better everything else is pretty good other than tree routes n water" | pixen buildings at lot size work; next: better walls + church, tree placement, river; town map handed to UI dev |
| 2026-10-24 | halls | traps as one magic circle tinted by effect (crimson/green/ember/ice/violet/gold) | liked, refine | "like the blue circle size but made like the colored ones and make them cleaner" (before: "the amount of traps is clutter id rather there be a cool magic circle that changes colors") | one readable symbol per mechanic beats many props; match the size of the shrine rune; fewer stray pixels |
| 2026-10-24 | pixellab-hero | the other 11 base class outfits on both bodies (classes/batch/<class>_frames.png + _loop.gif) | good | "looks good" | the batch method holds for every class: same wording on all 9 frames, re-roll any frame that drops the female hair; next is level 75 after the lead ok |
| 2026-10-24 | interface | all 19 screen mockups (sheets 1-5: Fight, Hero, Class, Skills, Party, Pets, Bag, Gear, Item popup, Town map, Blacksmith, Shop, Wheel, Bestiary, Rewards, Menu, Title, Death Regular/Hardcore), game-art-only v3 system | good (approved) | "this looks really good" | build these screens in the game as drawn; the same system covers every screen |
| 2026-10-24 | town dev 2 | town mockup set 4 (22 images, after 3 Fable passes) | ok | "its okay some things dont look like they fit the path" | every door needs a visible path to a street and nothing may stand in a doorway; check door-to-street links before sending |
| 2026-10-24 | dungeon dev | people in game 1-18 (stranger, travelers, keepers) | 7-9 | "I like the in games now" | keep them; this is the bar for people |
| 2026-10-24 | dungeon dev | people alternates 19-32 | 6-8 | "maybe some of the alternates can be used later, specifically Mirella" | keep alternates on file; Mirella alternate wanted later |
| 2026-10-24 | town dev 2 | town after path fixes | better | "the town looks better... certain areas need to not clash and buildings must face the right directions; no door on the opposite side of the street" | doors always face their street; distinct tidy areas |
| 2026-10-24 | town dev 2 | town after door paths (set 5) | better ("the town looks better") | "we do need certain areas to not clash, and the buildings to face the right directions, we cant have a door on the side facing away from the street" | every door face must touch its street directly (no paths across yards); zones (market, homes, forge, church/graveyard, plateau, walls) stay distinct with their own props/ground and gaps between |
| 2026-10-24 | town dev 2 | buildings vs walls | bug | "certain buildings are in the walls" | keep a clear margin between buildings and walls; check depth sorting |
| 2026-10-24 | town dev 2 | town walkers | bug | "heroes follow the paths and aren't shown if behind building... they keep going on roofs... they need to just walk around and interact" | walkers on a path graph, depth-sorted behind buildings, visit doors/stalls |

- Oct 24: Race sample (Goblin + Dwarf, M/F, Warrior + Mage, claude/art_test/races/RACE_SAMPLE_goblin_dwarf.png): Juzo "Goblins and dwarfs are solid" (approved, no number given).
| 2026-10-25 | interface | Pets page: "a higher-ranked pet would know" hints moved behind each pet's More (fewer words) | ok | "I'm cool with it" | keep cards short; detail one tap away |
- Oct 24: Juzo: Beastkin "look good". Fairy butterfly wings v1 (13_fairy_butterfly.png) "look bad, why circles" -> wants luna moth or monarch wing shapes. Grey werewolf, orc fixes shown.
- Oct 25: Fairy wings: Juzo rejected luna/monarch (16_fairy_wings_pick.png); wants the ORIGINAL 2.0 fairy wings look (slim pink-lilac petal wings; ref claude/art_test/races/fairy_wing_refs/old_race_wings_fairy.png).

- Oct 25: build hair (orc/goblin/dwarf/fairy) from the free human hair layers: "Free hair is okay for now". No PixelLab redraw for now.

- Oct 25: monster redraws R2: chimera 9/10, hellhound 9/10 ("easy 9s"). Keep both.

- Oct 25: town after Fable round 4: Juzo rates it 8/10 ("excited to see your work"). Requested: Blacksmith moved to the west farm corner by the gate; that field removed.

- Oct 25: smithy move "looks really good". Biggest mistake Juzo sees, town-wide and in the dungeon: props covered by buildings or looking like they float (base hidden or unsupported). Always check prop grounding in art reviews.

- Oct 25: monster zone-light tint on the 13 grey monsters: Juzo "likes the color changes".

- Oct 26: fights: Juzo prefers the old Surtr look (boss across from the hero, "facing off", clearly standing) over the round-5 2x boss that fills the stage. Merge of monsters r5 held; asking whether it applies to all fights.
