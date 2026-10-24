# Solaria UI research (interface dev, from Oct 24 2026)

Why: Juzo rejected the PixelLab-made UI pieces: "the ui has to match the game we cant randomly use weird ai art for things we have to make everything cohesive and playable". This document is the research loop (10 rounds) that the UI redesign follows. Each round adds sources, re-checks the previous round, and rewrites the rules at the bottom.

## Round 1: what great pixel-game UIs actually do

### Blasphemous (dark-fantasy pixel, 2019): the closest match to Solaria's mood
Studied 5 full-res screens (abilities, prayers, relics, shop prompt, boss fight) from Interface In Game.
- **Chrome is thin, not heavy.** Panels are flat near-black/dark-maroon fills with a 1-2 px dull-gold line border. Small ornamental pixel flourishes sit only at the corners and line ends. There are no textured slabs, rivets or stone blocks behind the text.
- **One accent colour taken from the world.** Dull gold/bone (the game's religious gilding) is used for borders, the selected tab and the selected cell. Everything else is black, maroon and bone text. Red/blue appear only in health/fervour bars and element icons.
- **Pixel font at the sprite's pixel scale.** A gothic bitmap font, so text looks drawn by the same hand as the sprites. Titles are all caps, letter-spaced, in gold.
- **The centrepiece is game art, not frame art.** Each menu page shows one big in-world object (the prayer book, the reliquary) drawn in the same pixel style as the world, using the empty half of the screen. The UI frames stay quiet so the art is the star.
- **Icon tabs.** Top tabs are small pixel pictograms in little bordered cells, with the selected cell in brighter gold. The page title is written once above them.
- **Grids.** Inventory cells are dark squares with a faint 1 px border. Selected = bright gold square frame. Locked or empty cells are just darker.
- **Boss bar.** A segmented red bar at the bottom centre with ornate gold end caps, the boss name above it in the pixel font. It is part of the HUD, not on the monster.
- **HUD.** Top-left portrait medallion + thin bars + flask icons; currency top-right in a small ornate cartouche. The rest of the screen is the world.
- **Negative space.** Big dark empty areas are fine; they make the gold read as precious.

### Sea of Stars (2023, pixel RPG)
- Dialogue/save panels: translucent deep-navy fill with a thin light border and small corner ticks, a small pixel font, character portraits in pixel art next to the box. Again the panel is simple and the colour comes from the world (night-blue).

### General sources
- Game Developer / "user interface design in video games": diegetic vs non-diegetic. Non-diegetic UI (menus, HUD) should still borrow the world's visual language (BioShock's art-deco HUD) or it reads as a separate layer; Far Cry 2's mixed approach looked conflicted. https://www.gamedeveloper.com/design/user-interface-design-in-video-games
- Wayline "Game UI & HUD pixel art": UI should read instantly and stay out of the way; belong to the same world; icons silhouette-first, tested at real size; dark rim + one highlight for icon depth; nine-slice panels; ONE palette, ONE light direction, ONE scale across the whole HUD. https://www.wayline.io/learn/game-ui-art

### What this says about my rejected mockups
- PixelLab frames and buttons came with their own palette, shading and noise. Each piece was "nice" alone but did not share Solaria's palette (art/palette.gpl), outline (#0e0812) or pixel scale, so the screen looked like a collage.
- The heavy textured stone/iron frames competed with the hero and monster art, which is the opposite of Blasphemous.
- The text was a smooth system font, so it looked like a web page over pixel art.

## Running rules (rewritten each round)
1. UI chrome is drawn from the game's palette (art/palette.gpl) with its #0e0812 outline, at ONE integer pixel scale shared with the sprites. No imported/AI frame textures.
2. Frames are quiet: a flat dark fill + a 1-2 art-px border + small corner ornaments. The art (hero, monsters, items) is the star.
3. One accent (dull gold) for borders of selected or important things. Everything else is neutral.
4. A pixel font at integer scale (to research: licence, legibility at >= 15 pt on phone).
5. Icons come from the game's own sprites (item art, monster art) or are drawn in the same style at the same scale.
