# Licenses audit (for the App Store release)

Sources checked: art/*/CREDITS.md, sounds/CREDITS.md, credits.gd, settings_menu.gd, tools/*.py headers, project.godot (no custom fonts), no addons/ folder. The reference copy C:\gamedev\solaria\_free_assets\LICENSES.md does not exist on this PC, so nothing was cross-checked against it. In-game screen: Menu > Credits and licenses (credits_screen.gd, data in credits_data.gd).

## Sources

| Source | Author | License | Used in | Credit text required |
|---|---|---|---|---|
| LPC character parts (Universal LPC Spritesheet Character Generator), 168 parts | Redshrike, Sharm, ElizaWy, bluecarrot16, wulax, makrohn, bigbeargames, JaidynReiman and ~25 more (per part in art/lpc/CREDITS.md) | Per part: CC-BY-SA 3.0/4.0, CC-BY 3.0/4.0, OGA-BY 3.0, GPL 2.0/3.0, CC0 | Hero bodies, hair, heads, armor, clothes, weapons (art/lpc) | Yes: author, license, source, "modified" (all shown in Credits, full per-part list at the bottom) |
| LPC Revised | Sharm, ElizaWy, Hyptosis, Demetrius, BlueCarrot16 | OGA-BY 3.0 | Town art | Yes (shown) |
| [LPC] City Outside | Reemax (Tuomo Untinen) + Sharm, daneeklu, Hyptosis, Johann C, William.Thompsonj, wulax | CC-BY-SA 3.0 / GPL 3.0 | Town: market stall, banners, well, planters | Yes (shown) |
| LPC Tile Atlas | Sharm and others | CC-BY-SA 3.0 / GPL 3.0 | Town: gravestones | Yes (shown) |
| Dungeon Crawl Stone Soup tiles | DCSS artists | CC0 | All monsters, bosses, pets, props, item icons | No (shown anyway) |
| cc0 potion icons | DCSS, collected by AntumDeluge | CC0 | Potion icons | No (shown anyway) |
| Tiny Texture Packs 1-3 | Screaming Brain Studios | CC0 | First-person room textures | No (shown anyway) |
| Original art (gear, backgrounds, FX, doors, icon, logo) | Juzo / made for Solaria | Own work (FX and a few icons marked CC0 in CREDITS.md) | Everywhere | No |
| Sound effects, ambience | Generated in code (tools/make_sounds*) | Own work | sounds/*.wav | No |
| Music (music_*.wav) | Generated in code | Own work | sounds/music_*.wav | No |
| Fonts | None added. Godot built-in default font: Open Sans SemiBold (thirdparty/fonts/OpenSans*.woff2) | Copyright 2020 The Open Sans Project Authors, SIL OFL 1.1 (VERIFIED against Godot COPYRIGHT.txt) | All text | Listed in Credits |
| Godot Engine 4.7 | Godot Engine contributors | MIT (+ bundled permissive third-party libs) | Engine | Yes: MIT notice must ship with the game (shown in Credits, full text) |
| Supabase (online features) | Supabase Inc | Hosted service, not bundled code | Leaderboard, backup | No, but mention in privacy policy |

## FLAGS

1. RESOLVED (2026 cleanup): tools/fx_extract.py is deleted, art/fx/CREDITS.md and every script/comment no longer name the non-commercial "750 Effect and FX" pack (only this audit and a credits test that asserts it is NOT credited still mention it by name). art/fx is drawn by tools/make_fx.gd. Still open, outside the repo: C:gamedevsolaria_sourcesold_fx, and git history before commit 91516b08 (2c53b8ea and earlier contain the pack): never ship a build from those commits.
2. SHARE-ALIKE / GPL ART (the real App Store risk): 42 of 168 LPC hero parts (hair, beards, robe, vest, crown, tiara, wizard hat, kite shield, flail, war axe, halberd, scythe, spear, muscular and pregnant bodies, minotaur, wolf, zombie and elven heads) offer ONLY CC-BY-SA 3.0 and/or GPL (no OGA-BY, CC-BY or CC0 option). The town also uses [LPC] City Outside and LPC Tile Atlas (CC-BY-SA 3.0 / GPL 3.0 only). Obligations: credit the author, name the license, say the art was modified, and release the modified artwork under the same license (CC-BY-SA). CC-BY-SA 3.0 also forbids technical measures that restrict use (the App Store's DRM is the usual objection), and GPL is widely held to conflict with App Store terms. Commonly accepted reading: the sprites are separate artwork, not code, so Solaria's code is not affected, but the modified sprite files must stay available under CC-BY-SA (for example, a public repo or page with the modified art). Decision for Juzo: (a) accept this and publish the modified art under CC-BY-SA (low risk, common among LPC games), or (b) replace the 42 share-alike-only parts and the two city/atlas packs with OGA-BY/CC0 parts (safest). The in-game list shows each part's license so attribution is complete either way.
3. VERIFIED: Godot's default project font is Open Sans SemiBold, Copyright 2020 The Open Sans Project Authors, SIL OFL 1.1 (Godot COPYRIGHT.txt, thirdparty/fonts/OpenSans*.woff2). credits_data.gd says exactly that. The full third-party list is linked, not bundled; Godot MIT text is in the Credits screen.
4. MODIFICATION NOTICES: CC-BY requires saying the art was changed. Credits says "Cropped and recolored" (LPC) and "Recolored, outlined and upscaled" (DCSS).
5. MISSING CREDITS that existed before this work (now fixed): the old Art credits page had no entry for Godot, fonts, sounds or music, and listed no author names for the DCSS tiles (now points to the DCSS ARTISTS.md; add names if desired).
6. NOT CHECKED: the LPC source folder (523 MB) is not on the PC, so each part's license rests on the generator's CREDITS.csv as copied into art/lpc/CREDITS.md. art/lpc/CREDITS.md line for "hair/long_messy" and "head/heads/troll" lists CC-BY only, so attribution is mandatory there (it is shown).
7. FILE NAME NOTE: the art/pets and art/enemies CREDITS.md files are word-for-word duplicates (pets are built from monster art); harmless.

## Cleanup pass (branch wt/license)

- Deleted tools/fx_extract.py. Fixed stale paths/wording in art/fx/CREDITS.md, art/halls/CREDITS.md, tools/make_credits.py, battle_view.gd comment.
- art/pets/CREDITS.md duplicates art/enemies/CREDITS.md; it is accurate (pets are built from DCSS monsters), left as is.
- Removed art/hero/ (47 files). Only runtime use is the old non-LPC fallback in sprites.gd, reached only when USE_LPC is false or the LPC manifest is empty (neither in the shipped game); the missing image just returns null there. Git history keeps the files; tools/art_races.py can regenerate them.
- Sounds: all 73 wav files in sounds/ are generated by tools/make_sounds.py (sfx, zone/menu music, realms), tools/make_sounds_v11.py or tools/make_sounds.gd. No other audio files (ogg/mp3/wav) exist in the repo. Verdict: all own work, no third-party samples. No fonts are bundled either.
- Remaining tools/*.py with /home/claude/... source paths are build scripts for third-party packs (not shipped, excluded from export); they are only documentation of where sources were.

## Still for the owner

1. Decide the CC-BY-SA / GPL LPC art question (flag 2): accept and publish the modified art under CC-BY-SA, or replace the 42 share-alike-only hero parts plus [LPC] City Outside and LPC Tile Atlas.
2. Delete C:\gamedev\solaria_sources\old_fx (contains the non-commercial pack).
3. Do not ship from git commits 2c53b8ea or earlier (pack in history); consider the repo history if the repo is ever made public.
4. Check the other folders outside the repo (C:\gamedev\solaria_sources, C:\gamedev\solaria\_free_assets) for the pack and for the missing LICENSES.md.
5. Privacy policy must mention Supabase.
6. Re-check the LPC per-part licenses against the generator's CREDITS.csv if the LPC source folder is ever recovered (flag 6).
