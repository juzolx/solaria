# Solaria — Code Map: what affects what

A checklist for changing the game without breaking something else. Before changing a system, check every place listed under it. Keep this updated as new systems land.

## Items and pictures
- **One picture source:** `Sprites.item_icon(item)` makes every item picture. `ItemGrid.cell()` wraps it in a rarity-colored square.
- **Every screen that shows items must use ItemGrid or item_icon:** Bag, Gear, Vault, Shop (shelf + featured), Fortune's Wheel, Craft, Mailbox, wandering merchant, Collection, item popup.
  - Lesson learned: pictures first went into the Vault only, and the other screens kept text lists. New item screens must use ItemGrid from the start.
- **Still text-only:** the loot name that pops out of a monster in the fight (the event carries only the name). Bounty rewards are described in words until they're paid.
- **Item descriptions:** `ItemText.describe()` (full) and `ItemText.plain()` (tooltips). Change wording in one place.
- **Item detail popup:** `ItemPopup.show_item()`, used by Bag, Gear and Mailbox.

## Getting an item (every path must do the same bookkeeping)
Each new item should:
1. Go through `add_to_wardrobe(item)`, so its look can be worn.
2. Go through `codex.found_item(item)` when it's found or earned (counts, Collection). Purchases skip this.
3. Respect `bag_full()`. Never append to a full bag.
4. Bump `bag_version` so the Bag, Vault and Mailbox redraw.

Where items come from:
- **Monster drops:** `_give_item`
- **Shop:** `buy_shop`, `buy_featured`
- **Wandering merchant:** `buy_merchant`
- **Crafting:** `craft_gear`, `craft_set_piece`
- **Mailbox:** `Mail.collect`
- **Vault:** `from_stash`
- **Dev tools:** `dev_grant`

Fixed this round: shop buys and crafted gear now add their look to the wardrobe, and crafted gear counts as found.

## Rewards
- **All rewards go through the Mailbox** (`mail.gd`, `Mail.post`). Nothing pays straight into the bag any more.
- **Senders:**
  - Bounties: `Town._pay`, called the moment a contract finishes in `Town.on_kill`.
  - Achievements and deeds: `_check_codex`, and `Town.claim_deed` for old saves.
  - News from Juzo: `Mail.NEWS`, delivered by `Mail.sync` when a hero loads.
- **Gold and scrap scale with depth when the letter is posted,** with the same formulas as `give_reward`. If the reward scaling changes, change both.
- **Other reward keys** (`scroll`, `look`, `mats`) still go through `give_reward`. A new reward type must be added to `give_reward` and `Mail.summary`.

## Gold
- **Earning gold:** always use `_add_gold()`. It feeds the codex and class growth.
- **Spending gold:** Shop, Smith, Inn, Wheel, Vault upgrades, the merchant and bounty rerolls.
- **Coming with the revamp:** the Bank and carried gold will change every place that spends or earns gold, so audit this whole list then.

## Town
- **Town pages** (`main.TOWN_PAGES`) and the tap targets on the map (`Town.BUILDINGS` mapped to page indexes, plus `art/town/town.json` spots) must stay in the same order. Adding a page means updating all three, plus the tab badges in `main._refresh_tabs` and `town_view.badges`.
- **The town's look by zone:** `Town.LOOKS` plus the `TownView` shader. Shop stock by zone: `Town.local_goods`.
- **Being in town** (`state.in_town`) stops turns in `take_turn`. It also changes the music (`sfx`) and hides the fight in `main._sync_town`.

## Classes, races and secrecy
- **Class secrecy rule:** players only see their path and level milestones. Any screen showing class info must follow it: Class tab, Guide, patch notes, tips, world goal text, merchant lines.
- **Race fit:** hair, crests and fur are in `lpc.gd` (`spec`, `HAIR_DY`, `fur_ramp`). The character creator hides rows per race (`row_parts`). A new race needs both.
- **Faith (Good / Neutral / Evil):** `Classes.FAITH` and `g._faith()`. It gates classes in `class_tree.gd` and realms. The coming friendliness system must feed into and read from it.

## Autoplay
- **Settings:** `state.autoplay` (master switch) and `auto_paths`.
- **Turns run only when autoplay is on** (`main._on_tick`). Manual turns go through `main._manual_turn()`.
- **Any new automatic behavior must check autoplay,** and a manual way to do it must exist.

## Saving
- **New hero data:** add it in three places in `game_state.gd`: the variable, the save dictionary, and loading with a default.
- **New account data:** the same three places in `profile.gd`.
- **Codex** (account achievements and stats): `codex.gd`, saved separately.

## UI rules
- Phone first, 430x932 portrait. Check with `tests/town_shots.gd` and `tests/screenshot_v11.gd`.
- Pages redraw only when their `shown` key changes. If a page shows new data, add it to the key or the page won't update.
- Use methods instead of lambdas for `resized` signals, or the tests hang.

## Text that repeats the rules
When a rule changes, update its text too:
- Patch notes: `patch_notes.gd`
- Guide pages: `guide.gd`
- Inn rumors: `inn_tab.gd`
- Town tips: `town.gd` (`enter`)
- Page notes: Bounty, Guild Hall, Vault, Mailbox
- The welcome mail: `Mail.NEWS`

## Tests to run after changes
- **Full suite:** `tests/run_tests.gd`, about 3 minutes, should end with "failures: 0".
- **Town and Mailbox logic:** `tests/town_logic.gd`.
- **Screenshots:** `tests/town_shots.gd` (town, every building, the Mailbox).
