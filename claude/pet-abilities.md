# Pet abilities by rank (2.1, G5)

Code: `pet_abilities.gd` (all data tables + effects). Hooks: `Menagerie.turn` (after each
pet's hit), `Menagerie.on_kill`, and one line in `GameState._bonus_sources` (passives count
like gear/race bonuses). UI: Hero > Pets (each pet lists what it knows, plus locked lines),
Codex > Pets (rank table, each family's passive and trick, each region's Mythic signature,
hold a pet for its own). Test: `tests/stage6_pet_abilities.gd`.

Only pets on the run count (healthy and picked). Everything triggers on its own, so Auto
play uses it with no buttons.

## What each rank adds

| Rank | Adds |
|---|---|
| Common | the family's passive |
| Uncommon | stronger passive |
| Rare | stronger passive |
| Epic | the family's trick (a chance each turn) |
| Legendary | the trick more often and stronger |
| Mythic | the home region's signature |

## Families (the monster's shape)

| Family | Passive (Common .. Mythic) | Trick (Epic / Legendary+) |
|---|---|---|
| Beast | Keen Eye: +1..5% crit | Pounce: 15/22% a turn, extra hit for 1/1.5x its hit |
| Brute | Thick Hide: +2..7% max HP | Guard: 12/18% a turn, shield 5/8% max HP |
| Spirit | Soft Glow: 0.2..0.7% max HP regen a turn | Mend: 15/20% a turn while below half HP, heal 4/6% |
| Serpent | Leech: +1..3% lifesteal | Venom: 15/22% a turn, poison 0.5/0.8x its hit a turn (doesn't stack) |
| Folk (humanoid) | Sticky Fingers: +3..12% gold | Pickpocket: 15/22% a turn, 0.5/1x the floor's coin, once a fight |
| Calamity (Calamity pets) | Dread: +6% Defense | Ruin: 20/25% a turn, extra hit 2x |

## Mythic signatures (by region id)

| Region | Signature |
|---|---|
| mossy_hollows | Bramble Snare: stuns the monster for its first turn |
| sunken_catacombs | Grave Chill: monster hits 25% softer for 3 turns at fight start |
| flooded_depths | Undertow: once a fight below 35% HP, heal 15% |
| ember_halls | Ember Breath: fight opens with a burn (1x its hit, 3 turns) |
| the_shadow_deep | Shadow Fang: fight opens with a 3x hit |
| elf | Hush of the Wood: once a fight below 35% HP, shield 20% |
| fairy | Fairy Gold: every kill, 1x the floor's coin |
| dwarf | Ironroot Wall: every fight starts with a 10% shield |
| angel | Gilded Grace: once a fight below 35% HP, heal 25% |
| demon | Hellfire: fight opens with a burn (1.5x its hit) |
| calamity | Echo of the End: fight opens with a 4x hit |
| (none) | Wild Heart: fight opens with a 2x hit |

Balance: "its hit" is the pet's normal hit (8-45% of your Attack by rank), so even a 4x
opener is under two of your own swings. Passives top out around a single gear roll.
A Beast Tamer with three Mythics gets three sets; that's the hidden class's reward.

## Open questions for Juzo

1. Tricks start at **Epic** (as in the 2.1 ideas list). Should Rare get one too?
2. A pet's rank never changes, so "locked" lines show what a higher-ranked pet of the same
   kind would know. Should pets be able to rank up (for example at max level)?
3. Families come from the monster's shape (beast, brute, spirit, serpent, folk). Want any
   species to get its own trick instead (e.g. Gullinbursti)?
4. Calamity pets (always Mythic) get their own family and signature. OK?
5. Trick pop-ups show as a floating name ("POUNCE!") like skills. Too noisy with 3 pets?

## Caps (checker pass, Oct 23)
- All pets together heal at most 1.5% of max HP a turn (REGEN_CAP).
- Pet shields never push your shield past half your max HP (SHIELD_CAP), are cleared at the
  next fight, and don't stop Auto play casting its own shield skill (GameState auto checks
  `PetAbilities.pet_shield`).
- "Low" signatures are only used up when they actually go off; a pet's fire keeps a Blood bleed's tag.
- Passives are cached on the hero until the team on the run changes.
