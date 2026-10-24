# Solaria art style bible (single source of truth, Oct 24 2026)

Every art session (hero, races, 3D rooms, town, pets, monsters, icons, effects) follows this so the game looks like ONE game. When in doubt, match the base hero and the zone 1 Catacombs look. Details: art-critique.md (Juzo's decisions), sprite-design.md (races, gear), art-pipeline.md (method).

## One pixel scale
- All sprites are drawn at true pixel size and shown at the SAME integer scale (3x on phone) with nearest filtering. No sprite is ever scaled by a non-integer or smoothed.
- Base hero: about 60 px tall on a 64 px canvas (locked). Everything else is sized relative to the hero:
  - pets: small, about 24-36 px tall (a pet sits at the hero's knee/hip);
  - normal monsters: about 48-80 px (a wolf ~hero height lying low, an ogre ~1.3x the hero);
  - bosses: about 96-128 px; Calamities up to 160 px;
  - 3D room textures 32x32 tiles; town tiles 32x32 (3/4 view), buildings sized so a door is ~hero height.

## The base hero is the reference
The PixelLab base hero stays exactly as drawn (Juzo, Oct 24). Where this bible's outline or shading notes differ from the hero, THE HERO WINS: match its outline colour, outline thickness and shading style.

## One look
- Dark fantasy mood: muted, desaturated base colours, dusk light, one bright accent per sprite (eyes, flame, gem, rarity trim).
- Clean 1 px dark outline (near-black #0e0812 on the outside; may lighten to a darker local colour inside).
- Light from the TOP-LEFT everywhere (sprites, buildings, props, textures).
- 3-5 shades per material, hue-shifted ramps (shadows cooler/purple, highlights warmer). No soft gradients, no blur, no photo textures, no noise; dithering only on shade transitions, sparingly.
- Readable at 1x on a phone: strong silhouette, big clear shapes, no single stray pixels.

## Per subject
- Heroes/races: dark chibi (big head ~40-43%), battle view from behind (north), portrait front (south). NEW (Juzo, Oct 24): armour does NOT change the look. Each CLASS has its own outfit fitted to every body/race/hair; only the equipped WEAPON changes the look (drawn in the hand). Appearance (race, body, skin, face, hair, colours) is chosen in the character creator. Fixed short frame set; every part drawn on exactly those frames (old-creator structure). Colours recolour at runtime. Rarity shows only in inventory/item screens (frames, gems, glow there); WORN gear keeps its own look on the hero (decided with the hero session, Oct 24).
- Town view: same pixel density as battle (building doors about the hero's height), but the town is shown at 2x with pinch-zoom 2x/3x (battle stays 3x). Fallback if Juzo dislikes it: ~32 px town-walker heroes.
- Monsters: classic-handheld creature-sprite energy (bold outline, few colours ~10-14, dynamic expressive pose, big personality), heavily FANTASY and mythic (not cute pocket pets), in the dark palette. A zone's monsters share a material/motif/accent colour but each has a distinct silhouette. One still per monster (the game animates them in code); bosses get more detail.
- Pets: the CUTE side of the same creature style (chibi creatures, big eyes, few colours) but still the same outline, light and palette logic so they sit next to the hero and monsters naturally. Pets hatch from region nests: each region's pets echo that region's creatures and accent colours.
- 3D rooms: low-res pixel textures (32x32, nearest), one signature look per zone matching that zone's monsters; props as billboard sprites in the same style.
- Town: dark-fantasy Stardew-like 3/4 top-down depth (cliffs/terraces, layered trees, detailed buildings with walls + roofs), walled prison town at dusk, dungeon entrance as the lit focal point; Regular towns' Church holy and lit, Hardcore towns' Church dark/abandoned with an active graveyard.

## Rules
- Style references are style ONLY: never copy other games' designs, characters or layouts (Pokemon, Stardew, etc.), never name them in prompts.
- PHONE FIRST: small textures, chunks <= 2048 px, runtime recolours over baked copies, cheap code tweens over particles.
- Before delivering, put new art next to the base hero and a Catacombs monster at game scale and check it looks like the same game. Show Juzo numbered samples before batches.
- PixelLab generations are shared by all sessions (~1,800 left on Oct 24): check the balance before each batch and stay within your budget.
