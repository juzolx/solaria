# Fable review: MONSTERS and PETS, round 1 of 5 (Oct 25 2026, big-update)

Reviewed: claude/art_test/monsters/* (sheets B-M, IN_GAME_zone0, M_in_game_all), art/enemies (144 PNG),
art/pets/32 (150 stills + 140 idle strips), battle_view.gd, sprites.gd, sprite_light.gd, art_info.gd,
bestiary_tab.gd, pet_book_tab.gd, pet_tab.gd, pets.gd, menagerie.gd, pet_abilities.gd, main.gd (_fit_layout).
Numbers below come from a PNG audit (bounding boxes, colour counts, outline darkness, mean luminance)
and from the phone layout maths: PORTRAIT_DESIGN 504 wide (main.gd:9), so on a 430 pt phone the
stretch factor sc = 0.853 and ArtStyle.unit() = 3 screen px per art px.

Worst first inside each section.

## MONSTERS

1. **Bosses and Calamities draw SMALLER than common monsters on the phone (one-scale rule broken).**
   where: battle_view.gd:1476-1477 `ui = min(ui, floor(size.x * 0.56 * sc / span))`.
   what: with size.x = 504 and sc = 0.853 the cap is floor(240.7 / art width). A 76 px common gets 3x.
   boss_grendel (106 wide) gets 2x, boss_hel (95) 2x, and everything 121 px or wider gets **1x**:
   boss_charybdis 126, boss_forgemaster_brann 121, boss_scylla 121, boss_fairy_queen 120 (2x) and all ten
   Calamities (117-135 wide, art_info.gd). A Calamity at 1x is 134 screen px wide; a kobold at 3x is 189 px.
   Evidence in the picture: M_in_game_all.png row 2 (boss_black_annis, boss_grendel) and row 5
   (boss_scylla, boss_charybdis) look no bigger than the commons next to them.
   fix: (a) for `boss` let the width cap be `size.x * 0.92` (bosses may touch the stage edges) and keep
   the height cap; (b) amend the style bible: on a 430 pt phone 3x means a boss can be at most ~110 px
   wide (330 pt) and a Calamity ~125 px, so re-crop/scale the 7 bosses wider than 110 px and the 5
   Calamities wider than 125 px (calamity_2 134, calamity_3 135, calamity_6 133, calamity_8 133, calamity_1 129).
   Add a test in tests/stage6_art_rules.gd: every enemy PNG width x 3 <= 504 * 0.92 * 0.853 (= 395).

2. **Legendary/Mythic tier scale gives thin monsters 4x and wide ones 3x.**
   where: battle_view.gd:1465 `ui = max(ui + 1 (if scale >= 1.28), round(ui * scale_mult))`, then the width cap.
   what: Epic 1.2 rounds 3 -> 4 (3.6), Legendary/Mythic get +1 = 4x, but the cap 240/width only allows 4x
   when the art is <= 60 px wide: bog_body 49, briar_knight 51, mourning_dryad 51, banshee 57, tikbalang 57,
   wolpertinger 57, executor 58, abyssal_worm 60, salamander 60, ash_raider 60, ningyo 60, vetala 60.
   So a Mythic banshee is 33% bigger than a Common one, a Mythic leshy (76 wide) is the same size.
   Second pixel size on screen next to the 3x hero, which the 2.1 "ONE scale" comment at :1279 forbids.
   fix: drop the per-tier pixel scale (Monsters.TIERS "scale" only for Giant mod hit boxes), show rank with
   the aura (_draw_aura) + pips + name colour, which already exist. Or make it one whole step for ALL
   Legendary+ (4x) and give the stage the room (bosses are then the only thing that may differ).

3. **Twenty monsters are too dark to read on their dark halls (Juzo: "easier for everyone to read").**
   where: art/enemies, mean luminance of opaque pixels (0-255): chain_warden 47, ankou 48, krampus 48,
   briar_knight 49, jorogumo 50, kelpie 50, boss_jester_of_thorns 51, ahuizotl 52, hellmaw 52, bog_body 53,
   garmr 53, pixie_swarm 53, thornling 53, abyssal_worm 54, boss_charybdis 54, boss_dullahan 54,
   boss_surtr 54, executor 54, hobyah 54, pooka 54. Hall backdrops art/bg/zone_*_0.png average 38-94
   (zone 4 and 9: 38, zone 1: 49, zone 7: 50). DarkGrade then darkens the picture again (sprites.gd:559).
   Evidence: IN_GAME_zone0.png frames 1 and 3 (grendel, annis): black fur on a black-green hall, only the
   eyes read. Sheet H: pixie_swarm (1), thornling (2), briar_knight (9) are purple-black on near-black.
   fix: for these 20, lift mid-tones ~15% and add the zone's rim colour on the shadow edge (a PixelLab
   edit "lighter mid-tones, keep outline", same recipe pets2 used for cherub/ash_fiend); then in code skip
   DarkGrade for "hd":1 art (it is already palette-locked) and keep only SpriteLight. Re-check each at 1x on
   a 430x932 shot against its real zone (the lead's rule), not on the sheet's flat grey.

4. **The only in-game evidence is stale; current plate/name readability is unverified.**
   where: claude/art_test/monsters/IN_GAME_zone0.png and M_in_game_all.png (Oct 24 02:14), battle_view.gd
   committed Oct 25 13:50 (plate pass: NAME_FS 18, plate at :2130-2137).
   what: the pictures still show the "Weak Fire - Res. Nature" chip the code removed (:2260-2262 keeps an
   always-empty `chips` array and still draws it at :2303) and a 10 px name. Nobody has looked at the new
   plate on a phone with a boss or a Calamity.
   fix: monsters dev regenerates claude/art_test/monsters/ingame/ at 430x932: one common, one Mythic, the
   zone boss and a Calamity for zones 0, 3, 8, 9 with the hero and a pet out; delete the dead `chips`
   array. Until then this review cannot score the plate.

5. **Horde pack-mates draw at 2.34x (mixels) behind a 3x monster.**
   where: battle_view.gd:1548 `pr.size * 0.78`.
   fix: `pr.size * (2.0 / 3.0)` (exactly 2x) and snap with `_snap`, or draw them at 3x and tuck them behind.

6. **Same-zone near-duplicates: two mushroom caps in one zone, two lions in one zone, five black dogs.**
   where: Sheet H (zone 6) 3 mushroom_knight and 8 bogle wear the identical pink-spotted purple cap;
   Sheet F/G (zone 3) manticore and chimera are both lion-bodied; barghest (z0), garmr (z1), ahuizotl (z2),
   hellhound (z3), rune_hound (z7) are five black quadruped dogs with glowing eyes (M_in_game_all rows 1,
   3, 4, 6, 10). Juzo's bible: "each has a distinct silhouette".
   fix: re-roll bogle without the cap (a hunched goblin with a toadstool lantern), give chimera its goat
   head and snake tail as the silhouette, and change two of the dogs' stance (garmr sitting chained,
   rune_hound as a long low rune-lit hound, already 52 tall) so no two share a pose.

7. **First sight of every monster costs 3 per-pixel GDScript passes (hitch on iPhone), death a 4th.**
   where: sprites.gd:556-562 DarkGrade + _silhouette; sprite_light.gd:43-88 shade() (two separable box
   blurs, radius w/12, per pixel get/set_pixel); sprites.gd:623-642 poses_for 11 poses x pose_image per
   pixel; battle_view.gd:2392-2420 _dissolve 8 frames x per pixel + FastNoiseLite.
   what: a Calamity is 134x137 = 18k px: poses 11 x 18k set_pixel, shade ~1.7M float adds + 18k get/set,
   dissolve 147k noise calls: 150-400 ms stalls on an A15, right at "FIGHT!" and at the kill.
   fix: in pose_image the x-shift `dx` is constant per row, so replace the inner loop with one
   `blend_rect(src, Rect2i(0, y, w, 1), Vector2i(dx, ny))` per row (137 blits instead of 18k set_pixel);
   move SpriteLight.shade and the dissolve into a CanvasItem shader (normal from a baked blurred-alpha
   texture, noise texture for the burn); bake `white` silhouettes at import (tools/bake_art.gd).

8. **Bestiary draws monsters at non-integer scale, and its list icons are 0.29x blobs.**
   where: bestiary_tab.gd:58-69 (backdrop 168x168, pic offsets 10/6/10/10 = 148x152 box,
   STRETCH_KEEP_ASPECT_CENTERED) and :73 `fixed_icon_size = 22x22`.
   what: a 76 px common shows at 1.95x, a 121 px boss at 1.22x, a 137 px Calamity at 1.08x: mixels in
   the one screen where the player studies the monster. 76 px art squeezed to 22 px is unreadable, and
   the "???" silhouettes (goal: hide unmet monsters as silhouettes, which works at :104-106) are grey dots.
   fix: size `pic` to art.size x 2 for commons (max 160 fits in a 168 plate) and x 1 for bosses/Calamities,
   never KEEP_ASPECT; list icons at 2x of a baked 12x12 head crop or no icon (name + rank colour only).
   Also show `ia["white"]` in the plate for an unmet monster (_show :120-122 sets the texture to null).

9. **Two old 2x-grid pictures are still in art/enemies and go through the LPC-era fallback path.**
   where: art/enemies/boss_sword_spirit.png (68x68, a 60 px sword icon, see the file), boss_demon_ancestor.png
   (68x68), no "hd" in art_info.gd; sprites.gd:566 marks them "grid": 2 and battle_view.gd:1473-1474 draws
   them at half unit. Used as God class reveal art (god_classes.gd:47, :52; tests/run_tests.gd:680 requires
   them). Lpc.MONSTERS no longer exists: no monster falls back to LPC art any more (grep: no hits), and
   every ZONES monster id has native art (comm of ids vs files). These two are the last non-native pictures.
   fix: redraw both as native 96-110 px reveal art in the boss style (a sword spirit figure, a demon
   ancestor on a throne), add "hd": 1, then delete the `grid` 2 branch in _rect_for.

10. **Four normals sit under the bible's 60 px floor; one boss is barely taller than a common.**
    where: art_info.gd: rune_hound 76x52, baku 74x57, barghest 76x58, garmr 74x60, halo_wisp 62x59;
    boss_grendel 106x91 (foot 89) vs boggart 66x79, firebird 71x79, gashadokuro 74x79.
    what: at 3x a rune_hound is 156 pt, the hero 180 pt: fine for "a wolf lying low", but a boss only 12
    rows taller than a common reads as a big common. Grendel is Juzo's anchor (10/10), so don't redraw it.
    fix: give Grendel's stage the boss pulse ring already in code (:1562) plus the bone-pile prop at
    full 3x (fix 1 makes it 3x again: 318 pt wide, which is then clearly a boss); leave the hounds.

Score MONSTERS: **6 / 10**. The art itself is at the bar Juzo set ("they look amazing"); the code throws
most of it away on the phone: bosses shrink to 1-2x, rares grow unevenly, pack-mates mixel, and 20 of 144
vanish into their halls. Biggest opportunity: fix 1 + 2 + 3 together and reshoot (4): one 3x scale for
hero, commons and bosses with lifted mid-tones is the single change that answers "easier for everyone to read".

## PETS

1. **Pets on the run are drawn with the MONSTER picture at a non-integer scale, not the 32 px pet art.**
   where: battle_view.gd:2333 `Sprites.enemy_by_key(String(p["art"]))`, :2338-2340
   `h = hc.size.y * lerp(0.26, 0.46, grow)`; room_view.gd:343-355 the same.
   what: hero canvas = 96 x 3.52 = 338 design px, so a pet is 88-155 px tall = the 70 px monster art at
   1.25x-2.2x (any fraction, grows per level): mixels, and the "baby" art the whole Pets 2 batch was made
   for (art/pets/32, 150 files, Juzo "pets look solid") never appears in a fight. The egg hatch pop-up
   (main.gd:1579) does use it, so the player sees a cute baby hatch and then a blurry adult fight.
   fix: `Pets.art(species)` / `Pets.idle(species)` (the 2-frame strips already exist for all 140), drawn at
   exactly `32 * _u()`, feet on `_team_ground()` using the still's used rect; growth by level as a +1
   step at level 30 at most (or none: rank colour aura instead). Same in room_view.

2. **The class companion floats 114 pt above the ground.**
   where: battle_view.gd:1927 `y = _team_ground() - 70.0 * pu`, pets.gd:10 "Drawn in the same 64-unit box
   the old 68x68 art used".
   what: the offset is for the old 68 px art (68 x 3 = 204 tall, bottom at ground - 6). The new 32 px
   companion is 96 tall, so its bottom is 210 - 96 = 114 pt in the air beside the hero's hip.
   fix: `y = _team_ground() - (foot + 1) * pu` with foot = the used rect bottom of the 32 px still
   (knight_0 row 30, mage_0 row 26: pets.gd can cache it like Sprites.enemy_by_key does).

3. **Codex > Pets shows monster art shrunk to 56 px, and its ability text needs a mouse.**
   where: pet_book_tab.gd:69-71 `Sprites.enemy_by_key(... "art")` in a 56x56 KEEP_ASPECT box (70 px at 0.8x);
   :79-85 passive/trick/signature only in `tooltip_text`; :89 "Hold a pet below to see its own".
   what: mixels on every cell, the unowned-but-met "shadow" is the monster not the pet, and tooltips never
   show on iPhone, so a player can never read what their species does from the Codex.
   fix: `Pets.art(n)` at a clean 2x (64 px, like pet_tab.gd:82), `Sprites`' `white` of the pet still for
   met-not-owned, and a tap on the cell that expands it (or main.confirm-style popup) with the three lines.

4. **Eleven pets have no dark outline; they disappear on light halls and clash with the heroes' 1 px #0e0812 line.**
   where: art/pets/32, share of edge pixels darker than 70/255: calamity_4_pet 0.00, calamity_6_pet 0.00,
   grief_wisp 0.00, mage_0 0.00, mirror_nymph 0.00, moroi 0.00, pixie_swarm 0.00, will_o_wisp 0.00,
   banshee 0.01, gilded_fae 0.03, pale_stag 0.06, owlwraith 0.08 (all other 138 pets are >= 0.6).
   Sheet pets_sheet (scratchpad) row 1 banshee, row 2 calamity_4_pet/calamity_6_pet, row 8 moroi, row 9
   pale_stag: pale shapes with soft edges on the dark grey. On zone 8 (bg luminance 207) they vanish.
   fix: PixelLab edit "add a 1 px near-black outline, keep the inside" on these 11; the bible lets the
   outline lighten inside, not on the silhouette.

5. **Twenty pets are shorter than the 24 px floor, including a Calamity pet and the Mage's companion.**
   where: used-rect heights: eye_of_judgement 18, mage_0 19, calamity_5_pet 20, ranger_0 20, jorogumo 21,
   ranger_1 21, throne_warden 21, bard_2 22, halo_wisp 22, mage_1 22, baku 23, bard_0 23, + 8 more at 23-24
   (histogram: 18:1 19:1 20:2 21:3 22:3 23:6 24:4, the body of the roster is 26-30).
   what: at 3x an 18 px eye is 54 pt beside a 180 pt hero; calamity_5_pet (the rarest pet, 0.5% Mythic)
   is a 20 px yellow ball. Companion stage 0 being small is fine (it grows 23 -> 30), the others are not.
   fix: redraw the 12 non-companion ones at 26-30 px tall inside the 32 canvas (same recipe), keep the
   companion stage ladder as is.

6. **Venom (and Ember Breath/Hellfire) refresh the hero's stronger poison/burn every time they proc.**
   where: pet_abilities.gd:283-285 `enemy_poison_dmg = max(current, pet)` then
   `enemy_poison_turns = Combat.POISON_TURNS` unconditionally; :278-282 burn the same.
   what: a Serpent pet's weak venom (15-22% per turn) keeps a hero's big poison at full duration forever:
   a free permanent DoT, and the text "poison the monster for 0.5x its hit" is not what happens.
   fix: only reset turns when the pet's damage >= the current damage; otherwise `turns = max(turns, 2)`.

7. **"A stronger passive" at Uncommon is the same number for Serpents (and Epic = Rare for Beasts).**
   where: pet_abilities.gd:36 serpent values [1, 1, 2, 2, 3, 3]; :30 beast [1, 2, 3, 3, 4, 5];
   RANK_TEXT :22-24 promises "a stronger passive" at Uncommon and Rare; the Pet tab shows "Uncommon
   Salamander ... +1% lifesteal", identical to a Common (06_pets_ingame.png card 3).
   fix: strictly increasing values with one decimal (serpent [1, 1.5, 2, 2.5, 3, 4]; beast [1, 2, 3, 3.5, 4, 5]);
   `_num` already prints decimals. Add a test: every family's values are strictly increasing.

8. **Pickpocket (Folk's Epic trick) is worth less than Folk's Common passive.**
   where: pet_abilities.gd:39-40 and :305 `gold = (2 + floor) * 0.5`, once a fight.
   what: floor 100: 51 gold once per fight at a 15% chance = ~8 gold per fight; Sticky Fingers +3% on a
   floor-100 fight's gold is more. The one "trick" Folk pets get is a non-event, and the text "0.5x the
   floor's coin" reads like a fraction of a coin.
   fix: value as a % of the fight's gold drop (e.g. +25/+40%), text "steals a quarter of the monster's gold".

9. **Regen cap is silent on the card; "low" wording is vague.**
   where: pet_abilities.gd:150-157 REGEN_CAP 1.5 drops the 3rd Spirit's share with no message; the Pet tab
   (pet_tab.gd:146) still prints "+0.7%" per pet. LOW_HP 0.35 (:18) but every "low" signature text says
   "when you drop low" and Mend says "below half health" (:34).
   fix: card line "(team regen capped at 1.5%)" when capped; texts "below 35% health".

Score PETS: **5 / 10**. The roster (150 stills + idle strips, palette-locked, 32x32 verified, no size
errors, no pixel duplicates) is the strongest art batch in the project; the game then shows the wrong
picture in fights and the Codex, floats the companion, and hides abilities behind hover. Biggest
opportunity: items 1 + 2 + 3 are a one-day code change that puts the art Juzo approved on screen, at 3x,
feet on the ground, with the idle frames the batch already made.

## Checked and fine
- Weaknesses/resists are no longer drawn over the monster (battle_view.gd:2260-2303); Bestiary shows them
  after 10 kills (bestiary_tab.gd:171-176).
- Every ZONES monster id has a native "hd":1 picture; only mimic and treasure_goblin lack pet art and
  neither can be caught/hatched (menagerie.gd:107-116, hatch pool = zone enemies + subs).
- All 10 region eggs exist and match the zone ids used by Pets.egg; idle strips are 64x32 with two
  different frames for all 140; companion stages grow 23 -> 30 px.
- Pet count: 110 species + 10 Calamity + 20 companion stages + 10 eggs = 150 stills.
