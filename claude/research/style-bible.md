# Solaria art style bible (single source of truth, Oct 24 2026)

Every art session (hero, races, 3D rooms, town, pets, monsters, icons, effects) follows this so the game looks like ONE game. When in doubt, match the base hero and the zone 1 Catacombs look. Details: art-critique.md (Juzo's decisions), sprite-design.md (races, gear), art-pipeline.md (method).

## One pixel scale
- All sprites are drawn at true pixel size and shown at the SAME integer scale (3x on phone) with nearest filtering. No sprite is ever scaled by a non-integer or smoothed.
- Base hero: about 60 px tall on a 64 px canvas (locked). Everything else is sized relative to the hero:
  - pets: small, about 24-36 px tall (a pet sits at the hero's knee/hip);
  - normal monsters: about 48-80 px (a wolf ~hero height lying low, an ogre ~1.3x the hero);
  - bosses: about 96-128 px; Calamities up to 160 px;
  - 3D room textures 32x32 tiles; town tiles 32x32 (3/4 view), buildings sized so a door is ~hero height.

## One look
- Dark fantasy mood: muted, desaturated base colours, dusk light, one bright accent per sprite (eyes, flame, gem, rarity trim).
- Clean 1 px dark outline (near-black #0e0812 on the outside; may lighten to a darker local colour inside).
- Light from the TOP-LEFT everywhere (sprites, buildings, props, textures).
- 3-5 shades per material, hue-shifted ramps (shadows cooler/purple, highlights warmer). No soft gradients, no blur, no photo textures, no noise; dithering only on shade transitions, sparingly.
- Readable at 1x on a phone: strong silhouette, big clear shapes, no single stray pixels.

## Per subject
- Heroes/races: dark chibi (big head ~40-43%), battle view from behind (north), portrait front (south). Every gear piece is its own swappable layer (6 visual slots: weapon, off hand, helmet, chest, legs, feet; necklace = small pendant on the portrait; ring = no layer). Colours recolour at runtime; colour comes from rarity only; Rare vs Epic by trim + gem; glow/particles only on Mythic.
- Monsters: classic-handheld creature-sprite energy (bold outline, few colours ~10-14, dynamic expressive pose, big personality), heavily FANTASY and mythic (not cute pocket pets), in the dark palette. A zone's monsters share a material/motif/accent colour but each has a distinct silhouette. One still per monster (the game animates them in code); bosses get more detail.
- Pets: the CUTE side of the same creature style (chibi creatures, big eyes, few colours) but still the same outline, light and palette logic so they sit next to the hero and monsters naturally. Pets hatch from region nests: each region's pets echo that region's creatures and accent colours.
- 3D rooms: low-res pixel textures (32x32, nearest), one signature look per zone matching that zone's monsters; props as billboard sprites in the same style.
- Town: dark-fantasy Stardew-like 3/4 top-down depth (cliffs/terraces, layered trees, detailed buildings with walls + roofs), walled prison town at dusk, dungeon entrance as the lit focal point; Regular towns' Church holy and lit, Hardcore towns' Church dark/abandoned with an active graveyard.

## Rules
- Style references are style ONLY: never copy other games' designs, characters or layouts (Pokemon, Stardew, etc.), never name them in prompts.
- PHONE FIRST: small textures, chunks <= 2048 px, runtime recolours over baked copies, cheap code tweens over particles.
- Before delivering, put new art next to the base hero and a Catacombs monster at game scale and check it looks like the same game. Show Juzo numbered samples before batches.
- PixelLab generations are shared by all sessions (~1,800 left on Oct 24): check the balance before each batch and stay within your budget.
