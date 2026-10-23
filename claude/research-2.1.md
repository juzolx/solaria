# Solaria research 2.1 (written 2026-10-23)

Plain-words findings. "Verified" = I read the primary page this session. "Unverified" = secondary source or my own general knowledge; double-check before relying on it.

## Top recommendations (10 lines)
1. FORTUNE WHEEL / AGE RATING: Apple's reference puts "infrequent simulated gambling" at 13+ and "frequent" at 18+. In Australia even infrequent simulated gambling becomes R18+. Keep the wheel optional and rare, answer the questionnaire honestly, and expect 13+ (dark fantasy violence/horror already pushes you there).
2. If gold can ever be bought with real money, a gold-cost wheel is effectively a loot box: Guideline 3.1.1 then requires showing the odds of each prize BEFORE purchase. Show the odds on the wheel screen anyway. It is free insurance.
3. BUILD DEADLINE RISK: since Apr 28 2026 every upload must be built with Xcode 26+ (iOS 26 SDK). Codemagic's macOS image must have Xcode 26 or newer. Do a first TestFlight upload NOW, not in November.
4. Codemagic free tier is 500 macOS M2 minutes/month (verified). Plenty. There is NO official Codemagic Godot guide; you assemble it yourself (Section 7). Upload the very first build to App Store Connect early to catch signing problems.
5. Palette + outline: bake it at import time with a script (Python tool, one-off), NOT runtime shaders. Use a tiny runtime outline/flash shader only on a few sprites; it is cheap but unnecessary if baked.
6. AI art: run it through "proper-pixel-art" or "spritefusion-pixel-snapper" (both MIT) to snap to a real grid and your 16-32 color palette, then hand-fix. Apple has no AI-art-specific rule I could find in the Oct 16 2026 guidelines; Steam-style disclosure is not required on the App Store.
7. Free CC0 sources that are safe: Kenney (CC0), Foozle "Pixel Magic Effects" (CC0, 32x32, 10 spells) and 0x72 DungeonTileset II (CC0, but 16x16 scale). Pixelify Sans is under the SIL Open Font License (OFL.txt present in Google Fonts repo; free for commercial/app embedding). Pack gaps remain for region-specific monsters at 64x64.
8. Juice priority for a watch-mostly game: hit flash + damage numbers + short hit-stop first; squash/stretch and particles second; screen shake only on big events (crits, boss, player hurt). Keep it skippable/low-intensity.
9. App Store page: upload 6-8 portrait screenshots at 1290x2796 (or 1320x2868) with big captions, first 3 show the core loop; add a 15-30 s portrait preview at 886x1920.
10. Do not use "750 Effect and FX" (non-commercial) in the shipped build. Swap to Foozle + hand-made hit sparks; list every used asset and its license in a credits file.

---

## 1. Godot 4 pixel art shaders: palette snapping, outline, rim light

**What we found**
- Palette snapping (Godot 4):
  - "Posterize to Palette" (Godot Asset Library, repo on Codeberg): snaps screen colors to any palette using OKLAB distance. Listed MIT (page also says "MIT NON-AI"; read the license text before using). Targets Godot 4.6, so should run on 4.7 but test it.
  - "OKLCH Posterization/Color Palette Shader" (godotshaders.com): Godot 4.4; page states MIT, which differs from the site default CC0. Check the header in the file.
  - "4 level posterization (godot 4.3+)" (godotshaders.com, LiathTheCrow): CC0, but only 4 brightness levels, not a custom palette.
  - I did not find a CC0 shader that does true custom-palette matching. The usual CC0 trick (a 1D palette lookup texture) is easy to write yourself (roughly 15 lines).
- Outline: "Lightweight Pixel Perfect Outline" (godotshaders.com, license not shown in my results, check page) needs 1 px of transparent border on the sprite. Asset Library "2D outline shader" is MIT but poor on anti-aliased edges.
- Rim light: "2D Rim Light" by MightyMochiGames is CC0 (no normal map needed, ignores light direction). Another "2D Rim Light" is MIT, needs normal maps, and a commenter says it fails in Godot 4.
- Godotshaders.com rule: code is CC0 unless the page says otherwise; the demo art on a page is NOT covered.
- Cost on phones: a one-texture-read fragment shader on a small sprite is cheap even on Compatibility/OpenGL. What hurts is full-screen post-process (the screen-reading palette shaders) because it forces an extra render pass on mobile GPUs, and outline shaders that sample 4-8 neighbours per pixel on many sprites at once. (This is general mobile-GPU knowledge, not benchmarked by me; unverified. Test on the oldest iPhone you target.)

**Sources**
- https://godotshaders.com/shader/oklch-posterization-color-palette-shader/
- https://godotshaders.com/shader/4-level-posterization-godot-4-3/
- https://www.godotengine.org/asset-library/asset/4887 (Posterize to Palette)
- https://godotshaders.com/shader/2d-rim-light/ and https://godotshaders.com/shader/2d-rim-light-2/
- https://godotshaders.com/?p=12031 (Lightweight Pixel Perfect Outline)

**Recommendation**
- Bake, do not run live. Make a one-time script that maps every sprite to the Solaria palette and adds a 1 px dark outline into the PNG. Result: identical look across mixed packs, zero runtime cost, nothing to break on iOS.
- Keep ONE tiny runtime shader for hit flash (white tint). That is all you need live.
- Skip rim light for sprites; fake it by painting a 1 px light edge during the bake if you want it.
- Avoid full-screen palette shaders on phones.

---

## 2. Cleaning AI pixel art, and AI-art policy

**What we found**
- proper-pixel-art (KennethJAllen, MIT, Python): upscales, edge-detects, uses a Hough transform to find the true pixel grid, picks one color per cell. CLI: `ppa input -o out -c 16`. Palette size (-c) is the knob to tune. Works best when the source is already roughly on a grid. Note: a dependency ships a GPL FFmpeg build; irrelevant if you only use it as a tool on your PC, not shipped inside the game.
- Sprite Fusion Pixel Snapper (Hugo-Dz, MIT, Rust CLI, also web/WASM): snaps to a grid, quantizes to N colors or YOUR OWN palette (`--palette hex,hex,...`), batch folders, keeps dithering. Best fit for Solaria because it accepts a fixed palette.
- unfake (PyPI): scale detection plus quantization plus downscale. Alternative.
- Writing it in GDScript: possible (detect scale by finding repeated runs of equal pixels, downscale with nearest/mode color, map each pixel to nearest palette color in OKLAB or simple RGB), but not worth it; use the existing tools in an offline batch, then inspect.
- Honest limit from the tools' own docs: they align and quantize, they do not understand the art. Expect to hand-fix faces, eyes and thin weapon lines.
- Apple policy (verified on the Guidelines page, last updated October 16, 2026): I found no rule about AI-generated game art and no disclosure requirement for art. AI mentions are about user-generated/AI content-creation apps (1.2) and sharing personal data with third-party AI (5.1.2(i)). Guideline 2.5.19 (hidden/undocumented features) was newly added in the Oct 2026 revision per one secondary source (unverified). Your game ships fixed art, so none apply.
- Players: Steam requires AI disclosure (rewritten Jan 16, 2026, now only for player-visible/audible content). GameDiscoverCo survey of ~3,800 Steam players (summer 2026): 43% fine, 26% neutral, 31% negative, 8% would refuse to buy; 35% distrust that devs disclose honestly. No pixel-art-specific data found. Tim Sweeney publicly called disclosure a "Scarlet Letter".
- Legal side (not researched deeply): pure AI output may not be copyrightable in the US, and some tools' terms limit commercial use. Check the terms of the generator you used.

**Sources**
- https://github.com/KennethJAllen/proper-pixel-art
- https://github.com/Hugo-Dz/spritefusion-pixel-snapper
- https://pypi.org/project/unfake/
- https://developer.apple.com/app-store/review/guidelines/
- https://www.pcguide.com/news/pc-gamers-remain-skeptical-of-steams-ai-disclaimers-poll-shows-many-believe-game-devs-are-hiding-it/
- https://videogameschronicle.com/news/epic-games-ceo-says-its-really-irresponsible-of-steam-to-make-studios-disclose-ai-use

**Recommendation**
- Pipeline: AI image -> Pixel Snapper with the Solaria palette -> hand touch-up -> bake outline. Keep a small `assets/SOURCES.md` noting which sprites are AI-assisted.
- No App Store disclosure needed today. If you ever expand to Steam, fill in the AI form honestly. Consider mentioning "hand-polished" only if true.
- Hand-fix faces/eyes of every monster; that is what players notice.

---

## 3. Free, commercial-OK pixel packs

**Verified license pages**
- Foozle "Pixel Magic Effects" (CC0, 101 kB): 10 spell effects at 32x32 with icons (fire ball, molten spear, water, geyser, rocks, earth spikes, wind, tornado, portal, explosion). Replacement for part of "750 Effect and FX". https://foozlecc.itch.io/pixel-magic-sprite-effects
- 0x72 "DungeonTileset II" (CC0, art; MIT, code): dungeon tiles plus a few monsters (zombie, slugs, dwarfs, etc.), BUT at 16x16 scale, so only usable if you upscale 2x to match 32 px; styles may clash. https://0x72.itch.io/dungeontileset-ii
- Kenney (all assets CC0, commercial OK, credit optional). https://kenney.nl/support . Kenney art is clean/cartoony, so it needs palette baking to fit dark fantasy. Good for UI frames and icons (his UI packs, game icons).
- OpenGameArt CC0 items (license shown on listing; verify each page): Zombie and Skeleton 32x48 (Reemax), Undead King (Reemax), pixel art skeleton 32x32, Zombies & Skeletons (artisticdude), 32x32 CC0 JRPG-ish style (includes bat), CC0 Walk Cycles (bat, slime). Crypt/undead region is well covered. https://opengameart.org/content/zombie-and-skeleton-32x48 , https://opengameart.org/content/undead-king , https://opengameart.org/content/cc0-walk-cycles
- Pixelify Sans font: SIL Open Font License (the repo folder contains OFL.txt; I could not read its text, but OFL is standard: free for commercial use and embedding, do not sell the font by itself, keep the license file). https://github.com/google/fonts/tree/main/ofl/pixelifysans

**Unverified leads (check license page before using)**
- itch.io "20 Free Pixel Spells & Effects - Animated" (16/32/64/128 px, said to be free for commercial games), "Free Elemental Spellcraft" (69 effects, Godot files). Free Game Assets listings are often Craftpix-derived; Craftpix free packs have their own license (usually commercial OK but no redistribution), so read each one.
- Not found this session: free, quality packs for forest, water, fire and shadow monsters at 64x64. That gap is real. I did not check the BDragon1727 license page itself (you already know it is non-commercial).

**Recommendation**
- Effects: Foozle CC0 pack + hand-made 4-6 frame hit sparks and slashes (easy, and consistent with your palette).
- Monsters: crypt from OpenGameArt CC0 skeleton/zombie sets; for other regions, commission or hand-draw/AI-snap your own bosses. Treat packs as placeholders.
- UI frames/icons: Kenney, then recolor to the palette in the bake step.
- Font: Pixelify Sans (OFL). Ship the OFL text in a credits screen/file.
- Keep a license ledger: asset, URL, license, date checked.

---

## 4. Juice for auto-battle / idle RPGs

**What we found (thin evidence)**
- No postmortems or playtest data on which effects matter when the player only watches. Searches returned mostly generic briefs. I am giving design-craft guidance, not proven data.
- Reliable primary talks: Jonasson and Purho, "Juice it or lose it" (2012, Breakout example) and Jan Willem Nijman (Vlambeer) "The Art of Screenshake" (2013). Nuclear Throne figures from the latter: camera kicks back 6 px and adds 4 shake on a pistol shot, decaying fast (short burst, not a wobble).
- Counterpoint (Folmer Kelly, GDC): too much polish can distract from the goal.
- Practitioner notes: hit-stop (a tiny freeze on both attacker and target at impact) gives weight; floating damage numbers rise and fade; white flash and squash/stretch on the target; gold/XP drops on kills give a visible reward beat.

**Sources**
- https://rpgplayground.com/research-making-a-juicy-game/
- https://kenney.nl/learn/must-see-videos-for-indie-developers (links the talks)
- https://www.patreon.com/Azaleadev/posts/progress-report-139493232

**Recommendation (ranked for a watch-mostly game)**
1. Hit flash (1-2 frames white) on every hit: cheapest and clearest.
2. Damage numbers: color by type, bigger and slightly longer for crits; cap how many are on screen so fast fights stay readable.
3. Hit-stop 40-80 ms on crits and kills only, not on every hit (avoids a stuttery auto-battle).
4. Attack lunge / recoil (move attacker 4-6 px toward the target and back) plus squash/stretch on the target.
5. Death: shrink/dissolve plus loot pop and a coin sound; this is the dopamine beat of idle games.
6. Particles: 3-6 sparks per hit, small. Heavy particle counts hurt phones and the clarity.
7. Screen shake: only big events (crit, boss slam, player takes a big hit), 100-150 ms, low amplitude, and add an on/off option in Settings (accessibility, and Apple reviewers like it).
8. Sound pairs with every one of these; a hit without a sound feels dead.

---

## 5. App Store screenshots, icon, preview

**Verified (Apple pages)**
- Screenshots: up to 10 per device size; JPEG/PNG; no transparency/alpha. Required: at least one set for "iPhone with Dynamic Island, medium display" (1179x2556 or 1206x2622) and one "large" set (Dynamic Island large 1260x2736, 1290x2796 or 1320x2868; or Face ID large 1284x2778). If you give only the largest set, App Store Connect scales it down. Practical choice: make one 1320x2868 (or 1290x2796) set; check in App Store Connect that it accepts it for both groups.
- App preview: optional, up to 3 per size/language, 15-30 seconds, max 500 MB, H.264 (.mov/.m4v/.mp4) at 10-12 Mbps, max 30 fps, stereo AAC 256 kbps (ProRes 422 HQ also allowed), portrait allowed. Accepted resolution for modern iPhones: 886x1920 portrait (1920x886 landscape). Poster frame defaults to second 5. Previews play before screenshots. Processing can take up to 24 hours. Content must follow the Review Guidelines (it must show the real app).
- Upcoming: iPhone Duo sizes become required for apps built with the iOS 27.1 SDK or later starting April 2027 (not relevant for launch).

**Unverified general advice (industry practice, no primary source)**
- Most people only see the first 2-3 screenshots in search results, so put the strongest first.
- Big short captions (3-6 words, high contrast) beat plain screenshots. Show combat with big damage numbers, a boss, loot, and the character/class choice. The last shot can show the extraction/risk hook.
- Icon: one strong focal character/object, high contrast, no text, no transparency, 1024x1024, readable at small sizes. Test against a dark and a light wallpaper.
- Consider Apple's Product Page Optimization tests (free) to A/B icon and screenshots after launch.

**Sources**
- https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications

**Recommendation**
- 6-8 portrait screenshots at 1320x2868, captions in Pixelify Sans, order: 1 combat with big numbers, 2 boss, 3 loot/wheel, 4 choices mid-battle, 5 regions, 6 extraction risk.
- A 20-25 s portrait preview recorded from the actual game at 886x1920, 30 fps, with sound; first 3 seconds must show action.
- Do not show the wheel with "gambling" wording in captions (see Section 6).

---

## 6. Apple age rating and the fortune wheel

**Verified (Apple's age ratings reference, read this session)**
- New scale: 4+, 9+, 13+, 16+, 18+ (12+ and 17+ were removed). Apple converted existing apps automatically and required the new questionnaire answered by Jan 31, 2026, otherwise updates can be blocked. Ratings apply on iOS 26 and later.
- Mapping:
  - Contests: infrequent 4+, frequent 13+.
  - Loot boxes: 9+.
  - Simulated gambling: infrequent 13+, frequent 18+. (Apple defines it as betting without real money or exchangeable in-game currency.)
  - Real-money gambling: 18+.
  - Fantasy/cartoon violence: infrequent 9+, frequent 13+. Infrequent horror 9+, frequent horror 13+. Frequent guns/weapons 13+.
- Regional: Australia raises loot boxes to 16+ and infrequent simulated gambling to R18+. Brazil uses its own scale and needs a license for fixed-odds betting.
- Guideline 3.1.1 (verified text): apps offering loot boxes or other mechanisms that provide randomized virtual items for purchase must disclose the odds of each type of item before purchase.
- Guideline 5.3 concerns real-money gaming, sweepstakes and lotteries (needs licenses, geo-restriction). Your wheel with game gold is outside it as long as nothing pays out real value and gold cannot be cashed out.
- Interpretation (mine, not Apple's wording): "frequent vs infrequent" is your own honest answer. A wheel you spin occasionally as a bonus is arguably infrequent. A core, always-on spin loop is frequent (18+).

**Sources**
- https://developer.apple.com/help/app-store-connect/reference/age-ratings
- https://developer.apple.com/app-store/review/guidelines/ (3.1.1, 5.3; last updated Oct 16, 2026)
- https://developer.apple.com/news/upcoming-requirements/

**Recommendation**
- Design the wheel as an optional bonus, not the main loop, so it is "infrequent". Avoid casino visuals (slot machine, chips, "bet", "jackpot"). Call it "Fortune Wheel", prizes are items/gold.
- Answer the questionnaire truthfully for "simulated gambling: infrequent" and "fantasy violence: frequent". Expected result: 13+ globally; accept that Australia may show R18+ or you can remove the wheel for the AU storefront if that matters (probably not worth it).
- If gold is purchasable with real money (IAP), show the odds table on the wheel before spinning, and make sure the odds match the code exactly. Do this even if you sell nothing, to be safe.
- No ad-network or purchase of "spins" with real money for launch: that turns it into a loot-box, raises the rating (Australia 16+) and review scrutiny.

---

## 7. Codemagic + Godot iOS (no Mac) to TestFlight

**Verified facts**
- Godot 4.7 docs: iOS export must run on a Mac with Xcode installed; export produces an `.xcodeproj` which Xcode builds. Team ID (10-character code, not the name) and bundle ID are required. Environment variables can override provisioning profile UUIDs (`GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG/RELEASE`). The simulator only supports the Compatibility renderer (which you use). https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Codemagic pricing page: Free plan = 500 free macOS M2 minutes/month, 1 build at a time, 120-minute max build, 3 GB cache. After that Mac mini M2 $0.095/min, M4 $0.114/min (pay as you go). https://codemagic.io/pricing/
- Codemagic App Store Connect publishing (codemagic.yaml only): needs an App Store Connect API key with App Manager access (Issuer ID, Key ID, .p8 file you can download only once); `publishing: app_store_connect:` with `submit_to_testflight` (defaults false) and `beta_groups`; publishing happens in post-processing and doesn't use build minutes; waits up to 15 minutes for the build to show in App Store Connect. Apple recommends uploading the first version manually. https://docs.codemagic.io/yaml-publishing/app-store-connect/
- Apple requirement: since Apr 28 2026 apps must be built with Xcode 26 or later (iOS 26 SDK); iOS apps must target iOS 13+ since Sep 9 2026. https://developer.apple.com/news/upcoming-requirements/
- I found NO official Codemagic or Godot guide for this exact combination. The closest are GitHub Actions workflows (dulvui/godot-ios-upload, now archived; it says Godot 4.3 can archive and sign inside the export preset) and paid ShipGodot. Everything below is a recipe built from the verified pieces, not a tested guide.

**Recipe (untested, build it step by step)**
1. Apple Developer account ($99/yr), create app record + bundle ID in App Store Connect. Create the API key (App Manager) and add it in Codemagic (Teams > Integrations).
2. Code signing: use Codemagic's automatic iOS signing (Distribution certificate + App Store profile via `ios_signing` in codemagic.yaml), or upload a .p12 and profile manually.
3. In `codemagic.yaml`, workflow on `mac_mini_m2` (or newer), `xcode: latest` (must resolve to Xcode 26+).
4. Script steps: download the Godot 4.7.2 macOS build and export templates (templates go to `~/Library/Application Support/Godot/export_templates/<version>/`); put team ID/bundle ID in `export_presets.cfg`; run `godot --headless --path . --export-release "iOS" build/ios/Solaria.xcodeproj` (the first headless run often needs `--import` first to build the asset cache).
5. Then `xcodebuild archive` (scheme = project name) and `xcodebuild -exportArchive` with an ExportOptions.plist (method app-store), or Codemagic's `xcode-project use-profiles` then `xcode-project build-ipa`.
6. Set the build number from a Codemagic counter (e.g. `app-store-connect get-latest-testflight-build-number` + 1); TestFlight rejects duplicate build numbers.
7. `publishing: app_store_connect` with `submit_to_testflight: true` and a beta group (or internal testers only).

**Gotchas**
- Godot may overwrite hand edits in the Xcode project on each export; keep all settings in the export preset.
- Icons and launch screen are required by the exporter (blank = export error). Add privacy manifest/required-reason entries if any plugin uses them.
- Free minutes: a Godot export + archive typically takes 10-20 minutes (my estimate), so ~25-50 builds/month on the free tier. Don't build on every commit.
- Apple Silicon Mac runners only; Godot macOS universal binary works.
- First upload by hand is Apple's recommendation; with API key you can usually do it through Codemagic too, but check.
- Export pitfall: spaces in the project file name break the exporter (Godot docs).

**Recommendation**
- Start the pipeline this week with an empty "hello world" Godot project to prove signing and TestFlight, then swap in Solaria. Budget 1-2 days for the first green build.
- If it stalls, ShipGodot (paid service) is the fallback; GitHub Actions macOS runners are another (they bill macOS minutes at 10x Linux).

---

## Surprising / urgent
- Australia: even "infrequent" simulated gambling is R18+. Not blocking, but it affects the AU store listing.
- Xcode 26 minimum since Apr 28 2026: an old Codemagic Xcode image would cause upload rejection.
- The fortune wheel is the single feature most likely to draw review questions; keep the odds visible.
- "750 Effect and FX" is non-commercial: it must be removed from the shipped build.
- Evidence for juice priorities and for Apple "AI art" policy is thin; the Apple guidelines contain no AI-art rule, but I could not read the whole page character for character (read in two parts, covered all).
