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
| Fonts | None added. Godot's built-in default font (Open Sans) | SIL OFL 1.1 (verify in Godot's COPYRIGHT.txt) | All text | Listed in Credits |
| Godot Engine 4.7 | Godot Engine contributors | MIT (+ bundled permissive third-party libs) | Engine | Yes: MIT notice must ship with the game (shown in Credits, full text) |
| Supabase (online features) | Supabase Inc | Hosted service, not bundled code | Leaderboard, backup | No, but mention in privacy policy |

## FLAGS

1. RESOLVED, but keep it that way: "750 Effect and FX Pixel All" (free version) by BDragon1727 is NON-COMMERCIAL ONLY. It was replaced by original effects (commit 91516b08, art/fx now drawn by tools/make_fx.gd). Still present and should be cleaned up: tools/fx_extract.py (its header and the CREDITS text it writes still name the pack; it is excluded from export, but running it would overwrite art/fx/CREDITS.md and reintroduce the pack's files); the old files in C:\gamedev\solaria_sources\old_fx; and the git history of art/fx (commits 2c53b8ea and earlier contain the pack). Do not ship a build from those commits. Recommend deleting tools/fx_extract.py and old_fx before release. The in-game credits no longer mention the pack.
2. SHARE-ALIKE / GPL ART (the real App Store risk): 42 of 168 LPC hero parts (hair, beards, robe, vest, crown, tiara, wizard hat, kite shield, flail, war axe, halberd, scythe, spear, muscular and pregnant bodies, minotaur, wolf, zombie and elven heads) offer ONLY CC-BY-SA 3.0 and/or GPL (no OGA-BY, CC-BY or CC0 option). The town also uses [LPC] City Outside and LPC Tile Atlas (CC-BY-SA 3.0 / GPL 3.0 only). Obligations: credit the author, name the license, say the art was modified, and release the modified artwork under the same license (CC-BY-SA). CC-BY-SA 3.0 also forbids technical measures that restrict use (the App Store's DRM is the usual objection), and GPL is widely held to conflict with App Store terms. Commonly accepted reading: the sprites are separate artwork, not code, so Solaria's code is not affected, but the modified sprite files must stay available under CC-BY-SA (for example, a public repo or page with the modified art). Decision for Juzo: (a) accept this and publish the modified art under CC-BY-SA (low risk, common among LPC games), or (b) replace the 42 share-alike-only parts and the two city/atlas packs with OGA-BY/CC0 parts (safest). The in-game list shows each part's license so attribution is complete either way.
3. UNVERIFIED: the Godot default font's license (Open Sans, OFL 1.1) is listed from memory; confirm against Godot's COPYRIGHT.txt and the Godot license page. The Godot MIT text and an "also uses third-party components" line are in the Credits screen, but the full third-party list is only linked, not bundled. Apple does not require more than this, but Godot's docs ask that the engine license is reachable inside the app, which the screen now satisfies.
4. MODIFICATION NOTICES: CC-BY requires saying the art was changed. Credits says "Cropped and recolored" (LPC) and "Recolored, outlined and upscaled" (DCSS).
5. MISSING CREDITS that existed before this work (now fixed): the old Art credits page had no entry for Godot, fonts, sounds or music, and listed no author names for the DCSS tiles (now points to the DCSS ARTISTS.md; add names if desired).
6. NOT CHECKED: the LPC source folder (523 MB) is not on the PC, so each part's license rests on the generator's CREDITS.csv as copied into art/lpc/CREDITS.md. art/lpc/CREDITS.md line for "hair/long_messy" and "head/heads/troll" lists CC-BY only, so attribution is mandatory there (it is shown).
7. FILE NAME NOTE: the art/pets and art/enemies CREDITS.md files are word-for-word duplicates (pets are built from monster art); harmless.
