# Fable art critique (Oct 23 2026) — the Art Director's fix list

Sheets: shots/fable_art/*.png (regenerate: `"$G" --path . --resolution 1400x1000 --position 3000,3000 -s tests/_art_audit.gd -- --out=res://shots/fable_art`; `--headless` hangs because the script waits for frame_post_draw).

## Top 10 (what hurts the look most)
1. Hero vs monster pixel density (1x LPC hero at ~5x vs 2x monsters at 4x; brighter LPC palette). Fix: new 2x heroes.
2. No consistent style within zones: chunky cartoon (Jack-in-Irons, Cyclops, Anvil Brute, Woodwose), dithered noise (Grendel, Hellmaw, Chain Warden, Rootstrangler, calamity_3/6, Barkhusk), tiny (Halo Wisp, Imp, Grief Wisp), LPC humanoids (Cinder Miner, Black Annis, Mirror Nymph, Fairy Queen, Treasure Goblin).
3. boss_grendel (first boss) is an unreadable noise blob.
4. Dungeon wall/floor tiles are photo/AI textures (z1/z2/z4/z8 walls, z4/z8 floors; 565-986 colours, no outlines).
5. Zone backgrounds (art/bg) are flat geometric placeholders; sub-areas are one stamped overlay.
6. Zone 8 Gilded Spire is bright pastel daytime (also zone 6 lavender); white monsters vanish.
7. Item icons for feet/legs/helmets are 6-12px blobs; rarity only a 2px underline; hero helms/hoods clip.
8. Off-genre monsters: Gilded Lion, Sun Golem, Forge Sentry, Stoneguard (mecha), Throne Warden, calamity_5, Owlwraith (dither ghost), Will-o'-Wisp, Pixie Swarm, Kelpie.
9. FX soft and mismatched in size (burst, holy, heal, crit, lightning, shadow, impact soft; claw/slash_crit slabs cover the hero).
10. Town is a bright Stardew-style tileset (being replaced).

## Redraw/replace list (HIGH)
- Monsters: boss_grendel, will_o_wisp, kelpie, boss_charybdis, pixie_swarm, forge_sentry, stoneguard, gem_crawler, sun_golem, gilded_lion, calamity_3, calamity_5, calamity_6; zone 8 set recolour to tarnished gold/dark bronze (choir_sentinel, cherub, boss_archon_valeth, boss_seraphiel, eye_of_judgement).
- All 80 dungeon tiles as 32x32 palette art (reference: z5_wall, z7_wall, z0_wall brick + moss).
- All 10 zone backgrounds as real 320x180 pixel art, 3+ compositions per zone, dark vignette, empty stage band y 100-150, stage ellipse under the monster. Zone 8 dusk/interior, zone 6 deep violet night.
- Item icon set: dedicated 32x32, rarity by frame colour + gem tint, 45-degree weapons, 2px shafts.
- FX: hard-alpha 2x frames, one ~48px footprint, code adds glow; hit flash as 1-frame white/red additive, not a pink tint.

## MEDIUM
- Monsters: boss_black_annis (too small), jack_in_irons, kobold, hobyah/pooka/spriggan, boss_hel (too white), revenant, vetala, boss_scylla, umibozu (add rim), selkie, cyclops, cherufe/firebird/boss_surtr (flames need dark core), gullinbursti, div, tikbalang, gorgon/boss_echidna/lamia (differentiate; Echidna giant), boss_typhon, owlwraith, rootstrangler/barkhusk/heartrot_treant, pale_stag, grief_wisp, hollow_sentinel, thornling, mirror_nymph/boss_fairy_queen/changeling, glimmermoth, cinder_miner, boss_forgemaster_brann, boss_high_king_thrandor, anvil_brute, ash_raider, throne_warden, halo_wisp, hellmaw, chain_warden, brimstone_brute, imp, abyssal_worm, boss_duke_malgrath, boss_azgaroth robes, calamity_8, calamity_1.
- Unused: boss_demon_ancestor, boss_sword_spirit, mimic, treasure_goblin (wire in or delete).
- Pets reuse zone monsters (bard_2/3, knight_2/3, mage_3, ranger_2/3, wanderer_*); growth stages are different animals. One creature per line, growing; pet marker (collar/harness). Eggs need zone patterns.
- Consumables: potions/scrolls are soft DCSS tiles — redraw in palette with outline.
- Props: altar, pillar flat; npc is LPC; traps are 1px rings or UI-like panels — make floor plates with clear hazard marks.
- Floors z1/z3/z9 near-black noise, z7 yellow sand, z0 green static — readable 2-3 value patterns.
- Skill icons: dedicated 24x24 set on a uniform plate.
- UI: too many accent colours (8 stat cards in 8 colours); limit to gold/grey + one state colour; logo corona clean rings; real logotype.
- Codex/Pet Book show monsters dark-graded into silhouettes — show raw sprites on a lit plate.
- Tier outlines: outline only, no body colour wash.

## Keep as the reference bar
Zone 1 set (ghoul, draugr, barrow_wight, banshee, strigoi, ankou, moroi, garmr, boss_dullahan) = house style. Also bakunawa, ash_fiend, manticore, hellhound, rune_hound, kappa, afanc, chimera, calamity_4, obsidian_knight, lantern_keeper. Props chest/chest_open, mimic, door_runed, sarcophagus, torch, key; consumables backpack, box, key. Tiles z5/z7/z0 walls and art/halls. FX slash, slash_crit, shatter, poison, nature. Backgrounds zone 1 and zone 7. UI milestone popups, floor picker, 3D hall view, sun-disc mark.

## Hero redraw notes
New 2x base in palette with #0e0812 outline, darker desaturated skin, muted cloth; each race its own head (not hue swaps); wings/tails/heads same outline and light; back views get the most care (that's what the player sees in fights); 2px minimum weapon lines with highlights; hair ramps from palette.gpl.

## Juzo's critique of art round 2 (Oct 23 2026)
- Hero: take the HEAD from look C and the ARMOUR from look B (slimmer). Dark chibi, three-quarter from behind.
- The dungeon (current zone backgrounds/tiles in the mockup) does not look good.
- The current monsters do not look good either (so monster redraws are needed, not just cleanup).
- The town concept looks "hella flat": it needs depth (3/4 view buildings with visible walls and roofs, cast shadows, height/elevation, layered trees and props), like his reference.

## Juzo's art direction (Oct 23 2026, with references in claude/art_refs, not committed)
- TOWN = "dark fantasy Stardew Valley": the same 3/4 top-down depth and richness (raised cliffs and terraces, layered trees, detailed varied buildings with walls and roofs, fences, props, crops, paths, lively small villagers) but in a dark-fantasy palette and mood (dusk, stone and old wood, lanterns, the walled prison town).
- DUNGEON and MONSTERS = "old 2D Pokemon sprites (Gen 2-3, GBC/GBA era), heavily fantasy-themed": bold dark outlines, few colours per sprite, dithering for texture, dynamic expressive poses, strong readable silhouettes, big personality; monsters are mythic fantasy creatures, not cute pocket animals. Dungeon rooms in that crisp handheld style with fantasy architecture.
- STYLE ONLY: never copy Pokemon or Stardew designs, characters or layouts (Nintendo/ConcernedApe IP). Original creatures and places only.

## Juzo's decision (Oct 23 2026): ONE GREAT HERO FIRST
No other art work (town, monsters, dungeon, icons) until one base hero looks good AND is fully customizable.
Base: Human, dark chibi, three-quarter from behind for battle + front portrait, 48-64 px.
Customization to prove on that one base: skin tones, hair styles + colours, faces, outfits (cloth/leather/plate),
weapons, rarity looks. Loop: Art Director makes it -> Fable art critique -> fix -> Juzo critiques -> repeat.
Fewer forced rules (style from Juzo's refs via IP-Adapter), quality over coverage.
