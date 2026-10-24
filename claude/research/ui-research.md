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

## Round 2: phone-first pixel UIs and whole-screen metaphors

### Shattered Pixel Dungeon (open-source dark pixel roguelike built for phones)
Studied its actual UI art files (assets/interfaces: chrome.png 128x64, status_pane.png, toolbar.png, menu_pane.png, menu_button.png). Study only; GPL art, nothing copied.
- **The whole UI chrome is one 128x64 sheet.** Windows are 9-slice pieces about 8-16 px square: a dark charcoal fill, a 1 px mid-grey border, a 1 px highlight, and tiny 2x2 square "rivets" in the corners. A light variant is used for buttons and a parchment-scroll variant for signs and notes. They are drawn at the same pixel scale as the 16 px dungeon tiles, so the UI and the world share one pixel grid.
- **Only 2-3 neutral shades plus the outline.** Colour comes from the content (item sprites, red HP, gold XP, buff icons), never from the frame.
- **Bars are tiny pixel strips** (HP red, shield grey, XP gold), 2-4 art px tall with a 1 px top highlight, shown at the game scale. They read clearly because the frame around them is calm.
- **Toolbar = flat bevelled slots** with item sprites inside; system actions are tiny pixel pictograms (backpack, clock, magnifier) in the same style as the items.
- A reviewer notes the buttons and tiles are "sufficiently large" for touch, and enemy HP shows as a bar + small status icons, so state reads at a glance. https://goodolddays.net/en/game/Shattered-Pixel-Dungeon
- Lesson: a phone pixel game can look cohesive with a TINY, hand-drawn, low-colour chrome sheet. Phone-light: one small texture, all 9-slices.

### Moonlighter (pixel action-RPG, inventory screen)
- **The whole inventory is one in-world object**: an open journal in the game's pixel style. Left page = item grid; right page = the hero sprite large in a framed portrait, with equipment slots around it.
- **Empty gear slots show a faint silhouette of what goes there** (helmet, chest, boots, pouch) instead of "+" or words.
- **Stats are icon + number tabs** (heart 100, sword 11, shield 10, boot 185) on a side tab strip. No words.
- One accent colour (teal) for selection, tabs and labels; paper tones for everything else.
- Item cells: a light square with the item sprite at the game scale + a small count number in the corner.

## Round 3: phone ergonomics and screen layout
- Touch targets: Apple 44x44 pt, Google 48x48 dp (WCAG 2.2 floor 24x24). The visible icon can be smaller than the hit area. Spacing between targets matters as much as size; one designer aims for 48 pt on iOS for anything in the lower thumb zone. https://www.weaccess.ai/blogs/mobile-touch-target-size , https://www.72technologies.com/blog/tap-targets-thumb-zones-mobile-ux
- Thumb zones: the bottom third is easiest one-handed, the centre is comfortable, the top corners need a stretch (Hoober's reach maps, via secondary sources). Main actions (attack/skills, tab bar) go at the bottom; read-only info (floor, gold) goes at the top. https://weareaffective.com/learning-centre/how-should-i-design-my-app-for-one-handed-use
- Equipment layout: a "paper doll" (slots placed around the hero where the gear is worn) matches the player's mental model (Diablo, Dark Souls, most MMOs). A labelled slot row is simpler and fits narrow portrait screens better. https://www.abratabia.com/game-ui-design/inventory-ui.php
- Fewer elements = less cluttered; Stats and Equipment are the most-used screens between fights, so they get the best spots.

## Round 4: type
- Solaria's own Art Direction page already picks **Pixelify Sans** (Google Fonts, SIL OFL) for display text. The page uses Alegreya Sans for body text, but that is the web page's font, not the game's. https://claude.ai/artifact/JGiBWRZkaGrykiueNgGKTq
- Pixel fonts must be drawn at whole multiples of their design size (m6x11: 16/32/48; m6x11plus: 18/36), with antialiasing off, or the strokes blur and wobble. m6x11 (Daniel Linssen) is "free to use with attribution". https://managore.itch.io/m6x11
- Damage numbers: compact, near-monospaced, never scaled down to illegible during their animation. Animate something behind them (a flash or burst) rather than distorting the number. https://shweep.medium.com/damage-numbers-in-rpgs-1f0e3b1bc23a
- Contrast: put text on a solid backing panel or give it an outline. A review of a turn-based game criticises white-on-grey text without one.
- Decision to check with Juzo: a pixel font for titles/numbers (Pixelify Sans) and either the same font or a clean small pixel font for body text, all at integer sizes.

## Round 5: combat HUD
- Bars for glancing, numbers for detail: a colour-filled bar reads in a glance, with the exact value on/under it (Atelier Ryza example in the Min/Max combat UI case study). https://uxplanet.org/from-frustration-to-fun-how-i-revamped-min-maxs-combat-interface-1f2d7ccf3c2c
- Boss bars as a wide segmented bar at the bottom or top centre with the name (Blasphemous). Normal enemies get a compact plate near the sprite.
- Colour-code damage numbers (physical / magic / heal), with the option to tone them down when they get cluttered. https://crunknation.itch.io/metabattler/devlog/474438/v027-update-health-bars
- Visible damage numbers are expected in turn-based RPGs: instant feedback on whether an attack choice works.

## Round 6: accessibility (Game Accessibility Guidelines, basic level)
High contrast between text/UI and background; an easily readable default font size; never colour alone for essential info; interactive elements large and well spaced on touch screens; simple clear language and formatting. Intermediate: a clear sign that something is tappable; stationary touch targets; a contrast option. Advanced: adjustable font size. https://gameaccessibilityguidelines.com/full-list/
Solaria already has a 15 px minimum, a colourblind labels setting, high-contrast dim text and reduce-motion (ui.gd); keep all of these.

## Round 7: Solaria's own visual language (the source the UI must come from)
- **Art Direction page** (https://claude.ai/artifact/JGiBWRZkaGrykiueNgGKTq):
  - "Ink, not black": shadows are deep indigo/teal (#0b0a1d, #0a313a), never neutral grey.
  - One accent light per scene (torch #f9905e or rune #5ad1e6).
  - Bone highlights (#d9ccaf), never pure white.
  - Silhouette first.
  - Pixel discipline: "never mix pixel sizes in one frame".
  - Region moods: each zone has a 4-colour mood (shadow / mid / highlight / accent).
  - It lists a Dark RPG GUI Kit as "avoid: AI-assisted graphics". The intent was always a UI that isn't AI-made.
- **art/palette.gpl** (74 colours, the house palette) already has every UI colour needed:
  - ink #181425, #172038, #1f1d24
  - slate ramp #262b44 / #3a4466 / #5a6988 / #8b9bb4 / #c0cbdc
  - warm-iron ramp #34323b / #4a4852 / #625f6a
  - dull-gold ramp #6a4a28 / #9a7040 / #c8a060, bright gold #feae34
  - bone #ead4aa / #f4e6c4
  - blood #a22633 / #e43b44, moss green #3e8948 / #63c74d, torch #f77622
- ui_skin.gd already draws iron frames with rivets in code (PX = 2, a 16 art px frame). That is the right method (code- or hand-drawn, palette-locked, tiny); the look was too generic and too heavy.
- The hero (PixelLab base hero, 64 px), monsters (48-128 px), pets (32 px) and item art are the visual stars. The UI must frame them, not compete.

## Round 8: clarity champions and cautionary cases
### Into the Breach (pixel tactics, often cited for UI clarity)
- **Frames:** flat dark-navy panels, a 2 px light-steel border, and title tabs with cut (45°) corners. There's no texture: the geometry gives the look, and it is drawn on the same pixel grid as the art.
- **Type hierarchy:** a chunky pixel display font for titles, buttons and big numbers ("End Turn", "CONTINUE", "2 turns"), and a smaller clean font for body text. Three sizes at most on a screen.
- **Segmented bars** (Power Grid): each point is a separate chunky cell, so the count reads without numbers.
- **Status strip:** icon + number pairs (star 3, core 0, grid 18%, people 2900) in one top strip.
- **Portraits:** the pilot's pixel portrait and the mech sprite sit inside plain frames and carry all the colour.
- **Colour states:** green = done, red = danger, yellow = selected/warning; the rest stays neutral steel.
### Dungeon of the Endless (pixel roguelike): the cautionary case
- Tiny panels with ~8 px text in the corners of a huge screen; unreadable at phone size. Shows what happens when PC-sized UI is shrunk.
### Lessons across all eight games
1. The world/characters are the colour; the UI is neutral with ONE accent.
2. Frames are simple shapes on the art's pixel grid (lines, cut corners, small ornaments), not textures.
3. Type does most of the styling: a characterful pixel display font + a clean readable body face.
4. Numbers with icons beat words with numbers.
5. Selection is shown by the accent frame, and state by a small set of fixed colours.

## Round 9: verification
- Pixelify Sans: SIL Open Font License 1.1 (OFL.txt from google/fonts, copyright "The Pixelify Sans Project Authors"). Variable font with Regular/Medium/SemiBold/Bold. Measured: one font "pixel" = font size / 10 (strokes are 10 px at size 100). So at 20 px every glyph pixel is a 2x2 block, and at 30 px a 3x3 block.
- Apple's 44x44 pt minimum tap area: widely cited (WeAccess, 72Technologies), and Apple's HIG page didn't render in the fetch. Solaria already uses TAP = 44 design px; keep it, and aim for 48+ on the fight buttons.
- Godot FontFile settings for pixel text: antialiasing off, subpixel positioning off, no MSDF, no mipmaps (Godot docs, FontFile). StyleBoxTexture's 9-slice should TILE its edges for pixel art; stretching distorts unless sizes match (Godot docs, StyleBoxTexture).
- Solaria's real render unit (verified in code): ui_skin.gd PX = 2 and sprites.gd HD = 2. UI frames and sprites are already drawn at 2 design px per art pixel, and the phone layout is 504 design px wide. So the shared grid is 252 x 546 art px on a phone screen.
- Dropped from round 1: the guess that the Blasphemous font is bitmap-only. It doesn't matter; the rule is "pixel font on the art grid".

## Round 10: the Solaria UI spec (what gets built)
### One grid
- Everything on screen sits on ONE art grid: 1 art px = 2 design px (the existing PX/HD). Frames, icons, bars, the cursor/selection, sprites at 1x, and TEXT: Pixelify Sans at 20 px (body; 1 font pixel = 1 art pixel), 30 px (numbers/subtitles) or 40 px (titles; 2 art px). The 15 px minimum stays for rare captions only.
- Big centrepieces (the Hero screen hero, a boss card) may use 2x (each sprite pixel = 2x2 grid pixels), never fractional scales.
### Colours: only art/palette.gpl
- Ink #181425 for panel fill; #0e0812 outline (the hero/monster outline); slate #262b44 / #3a4466 for raised parts; #5a6988 for edges; dust #8b9bb4 for secondary text; bone #ead4aa for main text.
- ONE accent: dull gold ramp #6a4a28 / #9a7040 / #c8a060, bright #feae34 only for the selected/main action. States: moss #63c74d = good, blood #e43b44 = bad. Rarity colours appear only on items.
### Chrome (hand-drawn, palette-locked, a few small 9-slices, like Shattered Pixel Dungeon's 128x64 sheet)
- Panel: ink fill, a 1 px #0e0812 outline, a 1 px #3a4466 inner line, and tiny 3x3 gold corner studs (Blasphemous-style ornament, kept small).
- Title plate: a cut-corner (45°) slate tab with the title in gold (Into the Breach).
- Button: a slate block with a 1 px lit top edge, a 1 px dark bottom edge and the #0e0812 outline. The main action gets a gold edge; a danger action gets a blood edge. Pressed = shifted 1 px down, edges swapped.
- Selected (tab, slot, card) = a 1 px gold frame. Nothing else uses gold.
- Bars: 4-6 px tall, outline + fill + a 1 px light top line; HP blood, XP gold, enemy HP segmented for bosses.
### Content first
- Icons come from the game's own art: gear icons (recoloured masks), consumable art, monster/pet sprites. New UI glyphs (tab and stat icons) are hand-drawn on the same grid in the same palette with the #0e0812 outline: 12-16 px, silhouette first.
- The background behind menus is the game's own art (the current zone's backdrop, dimmed), never an unrelated picture.
- Hero screen: the hero big (2x) on the zone floor, with a paper-doll of gear slots (empty = a faint slot silhouette, Moonlighter) and stats as icon + number.
- Fight: the scene is the star; an enemy plate (name in the pixel font, segmented HP); hero HP at the bottom; actions in the bottom thumb zone, 48+ px tall.
### Process
- Mockups are composed ONLY from game files (sprites, palette, the code-drawn chrome, the OFL font), then rated by Juzo. No AI-generated UI pieces.

## Running rules (rewritten each round)
1. One grid: UI art, icons, sprites and pixel text share 2 design px per art pixel.
2. Only palette.gpl colours; #0e0812 outline; ink fills; bone text; one dull-gold accent.
3. Quiet chrome: thin lines, small corner studs, cut-corner title plates. The art is the star.
4. Pixelify Sans (OFL) at 20/30/40 px; antialiasing off.
5. Icons from game art or hand-drawn on the grid; numbers + icons over words.
6. Thumb zone for actions; 44 px minimum (48+ for fight actions); colour never alone.
