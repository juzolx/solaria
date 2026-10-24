# Pets 2: roster plan (Oct 24 2026)

## What the code has
- Region pets: an egg hatches one of its region's monsters (Menagerie.hatch: zone enemies + sub-area monsters; mids and bosses never hatch). 10 regions: 5 root zones x 12 species + 5 realms x 10 species = **110 species**. A Beast Tamer can also catch these.
- Calamity pets: 10 (`calamity_N_pet`: Hollow Acolyte, Ember Whelp, Root Grub, Drowned Pup, Morrow Foal, Blinking Mote, Frostling, Pebble Golem, Star Wyrmling, Nightling).
- Class companions (World.PETS): 5 lines x 4 growth stages = 20 (`art/pets/<class>_<stage>.png`; today they are different zone monsters per stage).
- Eggs: one per region = 10 (today one shared egg icon).
- Families (pet_abilities.gd) come from the monster's shape: beast, brute, spirit, serpent, folk (humanoid), calamity.

## Look
- Each pet is a chibi BABY of its species (same name the game shows: "a baby Kelpie"): big head, big eyes, short legs, 3/4 side view like Juzo's refs, ~24-32 px inside a 32 px canvas, 1 px #0e0812 outline, top-left light, the dark palette, region accent colour, 10-14 colours. A small pet marker (collar/tag) on region pets so they never read as the zone enemy.
- Eggs: 20x24 egg on a 32 canvas, shell pattern + accent from its region.
- Class companions: ONE creature per line that grows (stage 0 tiny .. stage 3 grand, still <= 36 px).
- Idle: 2 frames (breathe: body squashes 1 px, eyes stay) baked by our own script from the still. Free, phone-light (one 64x32 strip per pet).

## Cost (PixelLab, 1-direction objects at 32 px: one call returns up to 64 sprites, each with its own description)
- Sample: 1 call, 3 pets x ~6 variants + 3 eggs x ~6 variants, about 10-15 generations.
- Full: ~150 sprites x 2 candidates = ~5 calls, about 50-75 generations, + ~20 for re-rolls.
- Total about 75-110 of the 120 budget. Idle frames cost nothing.

## Sample (3 regions, 3 families)
1. Barghest pup (Mossy Hollows, beast) + Mossy Hollows egg
2. Banshee wisp (Sunken Catacombs, spirit) + Catacombs egg
3. Salamander (Ember Halls, serpent) + Ember Halls egg

## Region accents (from solaria_wt_halls/claude/zone-palettes.md, binding for region pets + eggs)
Mossy #75a743 moss; Catacombs bone #e4e0ec + teal moss; Flooded #4fb0c6 + #3e8948 + bronze #c8a060; Ember #e43b44/#feae34 lava on basalt; Shadow #9a4fc0/#c27ad8 violet; Hushwood #d0dcc8 ghost-pale + #5a72a8; Glimmer #c27ad8/#f6757a/#ff0044 on deep violet night; Ironroot #c8a060 brass + #feae34; Gilded Spire #c8a060 dull gold (no pastel/white); Cinder Abyss #e43b44/#f77622 + bone #a3825f.
Full-batch prompts name each region's accent; the sample eggs already match (moss / bone skull / lava).
