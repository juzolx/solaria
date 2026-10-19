# Solaria: things to study and build (after v0.11 ships)

Ranked by how much they help the game. "Study" means research pro sources first, then build.
Status as of Oct 13 morning: ✅ done · 🔶 partly done · ⬜ not started.

## 1. Art (biggest visible upgrade)
1. ✅ **LPC dark fantasy heroes.** lpc.gd + tools/lpc_extract.py: layered parts recolored to the game's own skin, hair and material ramps. All 12 races, 37 hairstyles, every gear type. Art credits page in Settings (credits.gd).
2. ✅ **Real animations.** Slash, thrust, spellcast and shoot in fights (oversize weapon swings included).
3. 🔶 **Monsters to match.** 32 humanoid monsters and 17 named bosses (shown twice the size) built from LPC parts (Lpc.MONSTERS). Robes now recolor too (sheets drawn outside LPC's palettes get their own source palette). Beasts, spirits, serpents and the non-humanoid bosses (Scylla, Charybdis, Fafnir, Echidna, Typhon) keep the older art. Next: redraw those in the same palette, or find matching packs.
4. ✅ **Hit effects.** 20 effects from the 750 FX pack (tools/fx_extract.py) on hits, crits, weak hits, combos, poison, skills and healing. The free license is non-commercial only.
5. ✅ **Companion art.** 36 pictures from monster art (tools/art_pets.py). Companions now stand beside the hero in fights and lunge when they attack. Could be redrawn properly later.
6. 🔶 **Moodier backgrounds.** Light shafts and pixel fog added. Parallax not done.
7. ⬜ **Study:** palette design for dark fantasy.

## 2. Screen redesign (approved mockup)
1. ✅ Bottom navigation on phones (Fight, Hero, Items, Town, Codex, Online); the fight fills the screen.
2. ✅ Bigger fight scene, goal card (the "Next:" line), skill buttons with effect icons.
3. 🔶 Hero screen: bigger portrait card ✅; one-tap builds ✅; 2-column stat grid kept as one column for readability on small phones.
4. ⬜ **Study:** phone game UI.

## 3. Game feel
1. ✅ Screen shake and hit-stop tuned per weapon (axes and maces land heavy, daggers stay snappy).
2. ✅ Damage numbers: white flash on impact, bevel, sideways arc; crits tilt, shake and carry a CRIT tag.
3. ✅ Loot beams by rarity; chest-opening moment for treasure.
4. ✅ Boss music phase two (faster and heavier below half health or when enraged).
5. ⬜ **Study:** "juice" talks, Diablo and Vampire Survivors loot feel.

## 4. Gameplay depth
1. ✅ Balance tool: tests/balance11.gd (classes or races, several seeds). Balance pass done.
2. ⬜ Class identity pass (needs Juzo's input).
3. ✅ Boss variety: every named boss has its own mechanics; new telegraphed Crushing Blow you can stagger with a skill.
4. ⬜ Endgame: realm modifiers, Hardcore seasons, God trial rewards.
5. ⬜ **Study:** progression pacing.

## 4b. The Town (Oct 13)
1. ✅ Town hub: a separate, tap-to-enter place with no fighting (town.gd, town_view.gd). It's built from LPC Revised art by tools/town_compose.py, with 4 season versions plus a color grade, weather and lamp glow per zone, and townsfolk walking the square.
2. ✅ Buildings: Shop (wares follow the zone you're in), Blacksmith, Tavern (wheel), Inn (rest), Vault, Bounty Board and Guild Hall, plus the cave back down.
3. ✅ Bounty Board contracts (hunt, elite, WANTED boss) show their reward up front: gold, gear, or a weapon for your class. Turn-in happens in town.
4. ✅ Achievements become deeds with real rewards (gold plus gear by difficulty), claimed at the Guild Hall.
5. ⬜ Next: NPC visitors in town (traveling merchant, quest givers), building upgrades (Darkest Dungeon style), a town theme per realm.

## 5. Story and world (from Solaris Chronicles)
⬜ All three need lore decisions with Juzo first.

## 6. Tech (deferred list, when you're ready)
GitHub plus auto-updates, phone export, save-on-close, back button, FPS cap, sound compression, phone safe area, splitting game_state.gd.
Note for the phone export: the art data files (art/lpc/*.json, art/fx/fx.json) load as resources, so they will be included.
