# Solaria art plan (2.1), no budget (agreed Oct 20 2026)

No money for commissions now: commissions come later, paid from store income.
Rule: art quality comes from consistency. Mixed free packs look cheap because
sizes, palettes, outlines and lighting don't match: fix those and the same
assets look like one game.

Schedule: Juzo builds Sunday, Monday, Tuesday (a bigger update plus bug fixes);
playtesting the rest of the week. Each session: playtest bugs first, then art.

## Working method (most improvement per session)
- Contact sheets, not single screenshots: many assets in one image, before/after.
- Fix in code with tunable dials (palette, outline, rim, fog), never hand edits:
  it applies to every current and future asset.
- Every change behind a setting so testers can flip old/new on their phones.

## Week 1: one game
- Sunday: art bible in the repo (palette per region, one warm light, sizes
  64/128/320x180, 1px dark outline + top-left moonlit rim, one pixel scale per
  screen, region looks). Audit tool rendering contact sheets of all monsters per
  region, heroes per class, icons, backgrounds, UI. Mark keep / fix in code / replace.
- Monday: region palette shader (upgrade of the dark grade, optional dithering),
  automatic outline + rim on every sprite, whole-number sizes and pixel snapping,
  shared torchlight / vignette / fog per region, performance check (low graphics).
  Before/after sheet per region.
- Tuesday: replace the non-commercial effects pack (BDragon1727) with Gothicvania
  Magic Pack 9 (CC0); Shikashi item icons recolored; backgrounds the audit flags;
  credits and LICENSES updated (license-clean build).

## Week 2: motion and feel
Hit flash, squash and stretch, wind-up before attacks, consistent death
dissolves, particles per element, screen shake rules, idle breathing, UI motion
polish, a pixel font if it fits (Pixelify Sans, OFL).

## Week 3: store face
App icon, title screen from the unified assets, App Store screenshots with
captions, a short gameplay capture for the preview video.

## Later, with store income (commissions)
1. Style kit from one artist (hero in 2 classes, 3-5 monsters, a UI frame, a room).
2. The 10 Calamities (128x128). 3. Title / splash art. 4. A region at a time.
Paperwork: full commercial rights in writing, no AI, 50/50 payment, credit them.

## Research (at the start of the session that needs it)
1. Godot 4 palette-snap and outline shaders on phones (cost, best method).
2. How free-asset pixel games got a unified look.
3. More commercial-OK, no-AI packs: monsters per region, effects, UI, fonts.
4. Juice for auto-battle games: what feedback matters when the player watches.
5. App Store screenshots and icons that convert for dark fantasy.
6. Later: commission pricing and a full-rights contract template.

## Custom town art (Juzo reached out to an artist, Oct 20)
An artist may make a pixel (8-bit) town. Brief to send them:
- Every building: Shop, Blacksmith, Tavern (Wheel), Inn, Vault, Bounty Board,
  Guild Hall, Mailbox, Clinic, the cave entrance, and the new Church and trophy cabin.
- 2-3 upgrade looks per building (buildings level up in 2.1).
- Each building on its own transparent layer, plus the empty background, so
  upgrades swap in and buildings stay tappable (town.json hotspots).
- Portrait phone scene, whole-number pixel scale, the same pixel size as the
  monsters; palette and rules from the Art Direction page (Claude can export a
  palette file); send a screenshot of the current town and a monster.
- Nice extras: chimney smoke, torch flicker, the Wheel turning; night/season versions.
- Paperwork: full commercial rights in writing, no AI, credit in the game.
- Juzo's idea: a **wide town you swipe through** (about 3 portrait screens long),
  tap a building to open its page (already how the town works). Parallax layers
  (sky, far hills/castle, town, foreground) for depth; empty plots where new
  buildings and upgrades appear (Church, trophy cabin); people, smoke, torches,
  pets in the pen; position dots and a "jump to building" list. Ask the artist for
  the wide scene split into background layers plus each building on its own layer,
  with a few empty plots.

## Town artist talks (Oct 22)
- Artist ("Prince john") is open to long-term work in stages. Juzo's budget:
  **$50-100 every two weeks**, more for bigger pieces. Juzo told him: no AI art.
- Staged plan: (1) paid style test, one building (~$50); (2) sky, far background,
  ground for the wide scene; (3+) buildings by priority: Tavern + Wheel, Shop,
  Blacksmith, Inn upgrades, cave entrance, then Church and trophy cabin, then the
  rest and upgrade looks; last: animations and night. Likely 2-5 months total, so
  the new town may arrive in an update after the Nov 10 release.
- Protection: pay per stage after seeing work in progress (PayPal Goods and
  Services); ask for WIP shots or layered files (no-AI check); rights in writing.

## AI art policy update (Oct 22)
Juzo: **AI art is fine if it's really good.** Idea: Claude tries a few town pieces
with the SpriteCook plugin (needs Juzo to authorize it via /mcp), then cleans them in
code (snap to a true pixel grid, remove soft edges, map to the dusk palette). Compare
side by side with the artist's test before paying for the $120 stage. Spend the art
budget where AI is weak (Calamities, title art).
