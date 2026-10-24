# Stable ids

Every monster, boss, zone, sub-area, unique, Signature, set, set piece, race gear piece,
class node and pet species now has a permanent snake_case id. Saves, the Codex and every
lookup use ids. Display names live only in the data and can change freely.

## Survey: what was keyed by display name (before)

- **Codex bestiary**: `codex.entry/kills/seen/meet/record_kill(monster name)`; `value("mids")`,
  `value("signatures")` and `value("seen")` iterated names. `GameState.enemy_species` held the name.
- **Codex collection**: Unique / Signature / Set pieces keyed by `item["base_name"]`;
  `value("uniques")` and Realms completion looked up `u["name"]`.
- **Pet species / Codex pet_book**: `species` was the monster name (calamity pets: their pet name).
- **Monster data**: `Monsters.INFO` and `Realms.MONSTER_INFO` keyed by name; `all_monsters()`,
  `all_bosses()`, `monster_home()`, `signature_owner()`, wanderer info by name.
- **"boss:<name>" requirement keys**: 10 achievements (codex.gd), Hidden "Demon Saint"-style need
  (`boss:Azgaroth, Lord of the Abyss`), counted by `Hidden._have` / `Codex.value`.
- **Races**: awakening keys `from: {"boss": "Fafnir"}`, Lich phylactery `item_from` boss,
  Vampire / Werewolf `biters` lists.
- **Combat**: `BOSS_MECHANICS` by boss name, `ZONE_ELEMENTS` and the breath table by zone name.
- **World**: `ZONE_HAZARDS` by zone name. **Town**: `LOOKS` labelled by zone name.
- **Bounties / contracts**: `b["monster"]` / `c["monster"]` stored the name.
- **Sprites**: `enemy_key(name)` / `GameData.art_key(name)` built art keys from names; unique art
  `u_` + name; Signature art `s_` + name; race gear art `r_` + name; `SET_STYLES` by set name.
- **Items**: `ItemPool.SPECIAL_TYPES` by unique name, `GameData.SET_TYPES` by piece name,
  `SETS` / `EVO_SETS` / `SET_ORDER` by set name, items' `"set"` held the set name.
- **Classes**: tree node ids were computed with `ClassTree.slug(name)` at build time (a rename would
  change the id); `Signatures.NAMES`, `ClassTree.FINAL_STATS`, `ClassTree.MID_EXTRA` keyed by name;
  God classes' `"from"` and `"path:<name>"` deeds; Hidden `"path:<name>"` needs; `discovered[name]`.
- **Grave / spare / trophies**: grave `killer`, Lineage `befriended`, wanderer trophy titles by name.
- Already fine (keyed by ids or indices): achievements, travelers, guide pages, hidden classes,
  God classes, realms (`elf`...), calamities (by index; their art key is now also their id),
  lore pages (by index: append-only), art_info (by art key), materials (by index).

## Design

- **Monsters**: each def in `GameData.ROOT_ZONES`, `Realms.ZONES` (enemies, sub-area monsters,
  mid and zone bosses) and `Wanderers.LIST` has an explicit `"id"`. Regular monsters' ids equal
  their art key (`kobold`, `will_o_wisp`), bosses' ids are their art key minus `boss_` (`grendel`,
  `hel`, `azgaroth`). Calamities use their art key (`calamity_0`), their pets `calamity_0_pet`.
  `Monsters.SPECIAL` holds `treasure_goblin`, `mimic` and `trial` (every trial fight).
  One lookup: `Monsters.registry()`, `Monsters.by_id(id)`, `Monsters.name_of(id)`
  (`id_of(name)` exists for tools and tests only). `INFO` / `MONSTER_INFO` are keyed by id.
  `GameState.enemy_species` is the id; `enemy_name` is the shown name.
- **Zones**: root zones and sub-areas have `"id"` (`mossy_hollows`, `fernlight_glade`); a realm's
  zone id is its realm id (`elf`). Combat, World and Town tables key by zone id.
- **Items**: uniques have `"id"`; items carry `"def"` (unique id, `sig_<monster id>` for Signatures,
  `<set id>_<slot>` for set pieces via `GameData.piece_id()`, race gear id). The Codex collection is
  keyed by `def`. Art keys: `u_<unique id>`, `s_<monster id>`, `r_<race gear id>`.
  `SETS` / `EVO_SETS` are keyed by set id with a `"name"`; items store the set id in `"set"`;
  `GameData.set_name_of(id)` shows it. Piece looks moved into each set's `"types"`.
  Generic item bases (ItemPool) are not keys anywhere: items store their `"type"`.
- **Classes**: every TREES node is `[id, name, side, ...]` with its old slug frozen in the data.
  `Signatures.NAMES`, `FINAL_STATS`, `MID_EXTRA`, God `"from"`, and `path:` keys use node ids;
  God classes use their `god_*` ids; `discovered` records node ids.
- **Saves**: SAVE_EPOCH 13 is a fresh start, so nothing is migrated. Unknown keys are harmless:
  counters iterate the data, `name_of` / `set_name_of` fall back to the id, unknown sets give no
  bonus, `ClassTree.from_save` drops unknown class ids (tests/stage6_ids.gd checks these).
- Bounty / contract `text` is written once when posted (with the name of that day); they reset
  daily. Items keep the name they dropped with (like a printed label); logic never reads it.

## Still keyed by name (out of this pass)

Base classes (`"Warrior"`: `hero_class`, `class:` keys, `TREES` keys) and races (`"Elf"`) use their
name as their id; race awakening rank names (`discovered`), race key items (`race_keys`), realm
rivals and lore page titles are display strings used as keys. Rename those only together with
their uses, or give them ids the same way.

## How to rename something now

Change only its `"name"` in the data (GameData.ROOT_ZONES / Realms.ZONES / Wanderers.LIST /
Calamity.LIST / SETS / RACE_GEAR / the class TREES / GodClasses.LIST / Hidden.CLASSES) and any
prose that mentions it (lore, flavor, achievement text). Never edit an `"id"` (or a class node's
first element): saves, the Codex, pets, requirement keys (`boss:<id>`, `path:<id>`), boss
mechanics, signatures and art all point at the id, so they keep working. A new entry needs a new
unique snake_case id (`ClassTree.slug(name)` makes one); tests/stage6_ids.gd checks that ids are
unique and that every key that names a boss, monster or class exists.

## Pet art (Pets 2, Oct 24 2026)

Pet pictures are keyed by id too: `art/pets/32/<species id>.png` (+ `_idle.png`), Calamity pets
`calamity_N_pet`, companions `<class>_<stage>`, eggs `egg_<region id>` (Pets.art / Pets.idle /
Pets.egg). A new hatchable monster needs its baby art there; tests/run_tests.gd lists any missing.
