# Solaria — Dungeon Revamp Design

Decided with Juzo on 2026-10-13. This is the plan the dungeon rebuild follows. Status: stage 1 is built and waiting for install (see `claude/stage1-progress.md`).

## The premise
Every player starts in their own race's home town and dives into the dungeon to get deeper than everyone else. Depth is the score. Ranking high on the leaderboard earns rewards.

## The dungeon
- **1,000 floors.** It should take people a long time to finish.
- **Checkpoint every 25 floors**, each guarded by a mid boss.
- **Big boss every 100 floors.**
- **Walls:** a very strong boss at 250 and a basically unbeatable boss at 500. The walls keep getting bigger all the way to 1,000.
- **Floors are generated** from tilesets and rules, not built by hand. That keeps the download small.

## Risk and reward (built locally)
- **Dying:** you wake at the start of your 25-floor stretch (1, 26, 51...). You lose everything you carried in: bag loot, gold on you, backpacks, the gear your heroes were wearing, and potions and Return Scrolls (Juzo, 10:04 PM).
- **Leaving:** you can go home between floors. Tapping Town mid-floor means you head home as soon as the floor is cleared. Dives start from a checkpoint.
- **Return Scrolls:** escape home any time, even mid-fight, by tapping Town. Snik sells them.
- **Always safe:** the Vault, the Bank, the Mailbox, your pets, and Soulbound and Account-bound items.

## Loot rarity (built locally)
- **Base luck is bad on purpose.** This is an extraction game with gambling, crafting and luck classes, and those are the ways to beat the odds.
- **A blue is exciting, a purple is a big moment, a Legendary is lucky.**
- **Base odds per drop:** Common about 75%, Uncommon 22%, Rare 2.5%, Epic 0.4%.
- **Bonuses multiply instead of adding:** +10 doubles the Rare and Epic odds, +20 triples them. Tougher monster tiers, bosses, goblins and luck give bonuses.
- **Legendaries scale with depth:** rare early, normal by floor 200, twice as common from floor 400 down.
- **Other changes:**
  - Featured shop deal Legendary chance cut from 10% to 4%.
  - Mystery box Legendary chance cut from 20% to 6%.
- **Each rarity is much stronger than the one below it** (x1.0, 1.35, 1.85, 2.6, 3.6), so the colors feel different.
- **Simulated two hours of play** (to about floor 70-90): roughly 60-80 blues, 11-18 purples and 1-4 Legendaries. Before the change it was about 250 purples and 5-9 Legendaries.
- **New top rarities, from Calamities only:**
  - **Mythic:** the pieces of a Calamity's gear set.
  - **Unique Mythic:** one per Calamity, the single most special item in the game.
- **Binding traits (rare):**
  - **Soulbound:** never lost on death, and can't be traded or sold. You can give it to any of your own heroes. It only changes owner through the game's own system (going back into the loot pool, see below).
  - **Account-bound:** belongs to your account and the hero you register it to. Never lost on death. Only a Hall of Fame challenge can take it away.

## Calamities: the rarest encounter in the game
- **One Calamity per 100-floor region:** 10 in all for the 1,000 floors, each a named, unique monster that roams its own region.
- **Monsters that randomly appear and are overwhelmingly strong:** insta-kill level.
- **Power benchmark:** even if the dungeon went to floor 2,000, and you had the best loot from every boss through that floor, a Calamity should still take everything you have and then some. They're tuned above the game's own endgame, not against your current floor. Their strength doesn't scale down to where you meet them.
- **The lowest encounter chance in the game,** lower than every other rare thing, including the 1-in-1,000 Signature drops. Suggested: about 1 in 20,000 fights. Most players will see only a few in their whole time playing.
- **When one appears you choose: fight or try to run.** Running is a chance, not a sure thing.
- **Losing never counts as a death.** If the Calamity wins (or catches you running), your character passes out and the screen goes black. You wake up on the same floor with everything you had: no checkpoint drop, no lost loot or gear, and it doesn't add to the leaderboard death count. So there's no reason not to try.

### Killing one
- **It's gone forever, for everyone.** Once any player kills a Calamity, it never appears again for anyone. Its region has no Calamity from then on.
- **You get a piece of gear for every equipment slot,** made from the Calamity itself. The beast's stats are broken down across the slots in gear form, so wearing the whole set makes you as strong as the beast was.
  - **Every piece but one is Mythic and Soulbound.** You can equip them on any of your heroes, even ones without affinity for that gear type.
  - **One piece is the Unique Mythic, and it's Account-bound.** It holds your place in the Hall of Fame.
- **Also:**
  - A pet themed on the Calamity.
  - A title.
  - Max friendliness with every race.
  - The kill is announced to every player.

### Items with history
- **Every Mythic and Unique Mythic keeps a history:** who killed the Calamity, and every player who has held the item since. You can read it on the item, and it shows in the Hall of Fame.

### After a full year of inactivity (365 days)
- **The Unique Mythic and the Hall of Fame seat:** other players can challenge the holder's ghost. The ghost is an AI copy of the registered hero with all its gear; you never fight the real player. You bring your team of 3. Beat it and the seat and the Unique Mythic are yours.
- **The Mythic pieces go back into the loot pool,** but only in that Calamity's own 100-floor region. They leave the inactive player and become the rarest drops in the game there. Their history carries on with each new owner.
- **An active player can never be challenged** and never loses their Mythics.
- **It's fair because the seat holders are the strongest players in the game.** Taking a seat means beating one of the best builds ever made with your own team of 3.

### Still to settle
- **Leaderboard:** a Calamity killer becomes stronger than anything else in the game and could run away with the depth board. Fine as the ultimate reward, or does the killer go on a separate legends board?
- **Needs online:** "gone for everyone", the Hall of Fame, challenges and the loot pool all need the server. Until the game is online, Calamities can't be killed for good (or stay disabled).

### Feel
The screen darkens, unique music, a warning banner ("A CALAMITY APPROACHES"), and its name and art are unlike anything else.

## Fits a phone game
Checked with Juzo on 2026-10-13: everything in this doc works on a phone.
- **On the phone:** turn-based fights, tap-only rooms, pixel art and generated floors are light. The whole game should stay a small download, mostly the Godot engine itself.
- **On the server (Supabase), not the phone:** leaderboards, mail to all players, which Calamities are alive, the Hall of Fame, item history, inactivity timers and the released-Mythic loot pool. These are small tables and cheap.
- **Ghost fights** reuse the normal fight system: the server stores a snapshot of the registered hero (stats, gear, skills), and the challenger's phone fights it like any monster.
- **The one real risk is cheating.** Saves live on the phone and can be edited. Anything that affects other players (Calamity kills, Mythics, Hall of Fame seats, leaderboard depth) must be checked by the server before it counts. Online-only play for those features (which fits the "no offline progress" rule) makes this much easier.

## The roster
- **Up to 9 characters.** You choose **3** to send into the dungeon.
- **All your heroes (up to 9) appear in town,** walking around with the townsfolk, along with any pets.
- **Gear risk is a choice.** Players can keep favorite gear safe by leaving that character, or that gear, at home. They can also send a team in "risk free", with nothing they'd mind losing.
- **If one hero falls,** only that hero loses their worn gear (except Soulbound and Account-bound items). The run fails only when all 3 are down.
- **Team over one star:** a full, well-built team of B-tier heroes should be able to beat a badly built S-tier hero. Team synergy and build matter more than one strong character.

## Hardcore
- No preference from Juzo. Default: permadeath stays, on top of the new death penalty. A fallen Hardcore hero is gone for good, and Hardcore has its own leaderboard.
- A Calamity knockout is not a death on Hardcore either.

## Gold, the Bank and the goblin (built locally)
- **Bank at home:** banked gold is always safe. Before a dive you choose how much gold to take (none, a quarter, half, all).
- **Carried gold is at risk:** you lose it on death and bank it when you get home. Gold found in the dungeon works the same way.
- **Snik the goblin trader** replaces the wandering merchant. He waits at forks after bosses, and more often the deeper you go.
  - Cheap prices, carried gold only.
  - Sells 2 pieces of gear, potions, a Return Scroll and a random scroll.
  - Buys your junk (unlocked Common and Uncommon gear) for half its value.

## Mailbox (inbox), built locally
- **Every reward that would otherwise be handed straight to you goes to the mail:** bounties (paid the moment the contract finishes), Guild Hall deeds and achievements, and later leaderboard, season, first-kill rewards and gifts.
- **Mail is safe:** it never counts as carried loot and can't be lost on death.
- **Each letter shows its gear as pictures.** "Collect" takes what fits; gear that doesn't fit waits in the letter. "Collect all" collects every letter. Opened letters can be thrown away. Nothing overflows the bag.
- **Juzo can send messages to every player** (news, apologies, gifts, event announcements), with or without attached rewards.
  - Now: letters ship inside updates (the NEWS list in mail.gd) and reach each account once.
  - Online: messages are posted to a table on the server (Supabase) and every player's game pulls new mail when it connects.
- **The Mailbox is in town:** a "Mail" button on the town bar plus a Mailbox page, with unread and waiting counts.
- To do: letters with an expiry date so old event mail clears out.

## Pets (part of this update)
### Who has pets
- **Four ways to have a pet:**
  1. Be a Beast Tamer.
  2. Play a class where a pet makes sense.
  3. Hatch an egg. Any hero can keep the pet from an egg.
  4. Kill a Calamity.
- **The automatic companion every class gets now goes away** for classes where it doesn't fit.
- **Which classes keep a pet (Juzo confirmed, 10:04 PM):**
  - **Keep:**
    - Ranger (hawk line)
    - Knight (gryphon line, as a mount and guardian)
    - Mage (elemental familiar)
    - Wanderer (spirit fox)
    - Bard (songbird to phoenix)
    - Pet-themed evolutions such as Beastmaster, Druid and summoner or necromancer branches
  - **Lose:** Warrior, Cleric, Acolyte, Trickster.
- **Bard → Beast Whisperer** (Juzo): Bards can evolve into a class that calms animals and is a great helper to the Beast Tamer. Built as a Troubadour branch-off (calm 150 wild monsters by sparing them). On the team it makes catching easier and pets hit harder.
- **The Beast Tamer can own many pets** and bring **up to 3 at a time** on a run.
- **Pets show in town,** walking with your heroes.
- **A Pet tab is visible to everyone** from the start, so players know pets exist even before they have one. It shows your pets, and empty slots hint at what's out there.

### Pets are always safe
- **A pet is never lost,** not even when a run fails. Losing a pet is a quick way to make players quit.
- **Instead, pets get hurt.** A pet that goes down in a fight, or whose run fails, comes home wounded and can't go on runs until it's healed.
- **The Clinic** is a new town building that only appears once you own a pet. You heal wounded pets there, with gold or by waiting. It could also sell pet food and treats, and be where pets are kept.

### Taming: Beast Tamer only
- **Only the Beast Tamer can tame monsters, and only in the dungeon.**
- **Beast Tamer is a secret unique class.** Unlock: run away from 100 monsters while your run-away chance is 100%. This replaces the current unlock (spare 60 kinds of monster). The rule stays secret in game; only a rumor hints at it.
  - The run-away chance is currently capped at 90% (plus small class bonuses). The cap has to allow 100% for this to be possible, reached through Agility, gear and skills. That makes 100% a real achievement.
  - Only clean 100% escapes count toward the 100.
- **Catching:** when a monster's run-away chance is over 80% (it's weak next to you), a Beast Tamer gets a "Catch" option on it instead of only fighting or running.

### Eggs: mostly from quests
- **Getting an egg should be possible but definitely not easy.**
- **Eggs come mostly from quests, the ones where an egg makes sense.** For example:
  - An NPC in a dungeon town asks you to recover something stolen from a nest.
  - A ranger asks you to protect a hatchery.
  - A dying beast asks you to look after its young.
- **Other odd sources, kept rare:**
  - A nest hidden behind an unmarked door.
  - Something a goblin very rarely sells.
  - Sparing a mother monster, or protecting a nest instead of looting it.
  - Secrets tied to friendliness or alignment.
- **The pet inside is chosen at random.** Most egg quests don't build a story around the egg itself, so any pet can hatch from any egg.
- **A few special eggs can be exceptions:** a legendary questline whose egg is always a certain pet. Kept rare.
- **Hatching (built):** eggs are kept safe at home and hatch after 10 cleared floors. Eggs look scary on purpose: glowing eyes in the crack and claws poking out (Juzo).
- **Egg sources built so far:** contracts that mention a nest (4%), Snik (3%), sparing a wild beast (0.4%). Quest eggs come with dungeon towns (stage 4).

### Still to settle
- **Pet roles, levels and evolution:** fighter, healer, scout that reveals what's behind doors, pack animal for extra bag space, treasure sniffer; level up by coming on runs; evolve by alignment.
- **How many pets a non-tamer hero can bring:** default is one.

## Hidden dungeons (portals)
- **Every so often, one of the three doors is a portal** instead of a normal door. It looks clearly different: a swirling portal, not a doorway.
- **A hidden dungeon is a 10-floor side event.** You step out of the main dungeon, clear 10 floors, and come back where you left off.
- **Rewards:**
  - Guaranteed gold, paid out as you clear its floors.
  - A higher chance of good gear: the whole hidden dungeon gets a rarity bonus.
  - A bigger reward for clearing all 10 floors.
- **Each portal has a theme,** so they feel special: a vault of gold, an armory, a monster nest, a cursed crypt. The portal's color can hint at the theme.
- **Risk follows the normal rules:** dying in a hidden dungeon is dying in the dungeon.
- **Ideas to settle:**
  - How rare portals are (roughly one every 30-50 floors?).
  - Whether you can leave mid-portal, or must finish or die.
  - Whether some portals only appear for certain alignments, friendliness or classes.

## Dungeon towns and friendliness (Claude designs it)
Juzo's only requirement: a strongly built friendliness system that changes NPCs and which route you take.
- **This builds on the reputation system the game already has:** every race rates you from Hated to Exalted, rivals start hostile, sparing raises reputation and killing lowers it, friendly races let you run away, trade and show hidden paths, and some class branches need Honored standing.
- **Towns inside the dungeon:** safe floors (at first about one per 100-floor region), each run by a race or a mix of races. They have shops, NPCs with requests and rumors, rest, a mailbox, and a place to leave or bank gold.
- **Town entrances are hidden.** They look like any other door until you find one (see "The dungeon layout").
- **Friendliness is a score per race,** with per-town adjustments on top. Hurt one Orc town and every Orc hears about it, but each town also remembers what you did there.
- **Claude drafts the starting race table** (how each race feels about the others) from the book's world for Juzo to edit. Your race sets where you start with each town.
- **Your actions change it:** helping or hurting people, event choices, and bounties for or against a race.
- **Friendliness changes what you get:** prices, stock, which requests you're offered, whether guards let you in, and whether a town turns hostile or opens a secret.
- **Kind vs mean depends on who you're kind or mean to:**
  - Kindness to the kind: good.
  - Standing up to cruelty: good or neutral, not evil.
  - Kindness to someone being mean to you: strongly toward Good.
  - Meanness to someone who was kind to you: strongly toward Evil.
- **This ties into the existing hidden faith (Good / Neutral / Evil).** NPCs react to your alignment, so the same town plays differently for each path: different dialogue, quests, hidden vendors, shrines and secrets. Players compare notes and find their stories don't match.
- **Killing a Calamity sets friendliness to max with every race.**

## Bag (built locally)
- Bag expansions bought in town (Shop, for gold) or crafted (Blacksmith, from materials).
- **Rare backpack drops,** more common from bosses. Bring one home and the bag grows by 2 slots for good, up to 10 backpacks. Fall first and it's lost.

## The dungeon layout (top-down, tap only, like the town)
Added by Juzo on 2026-10-13, 9:17 PM.
- **Each floor is one room seen from above.** Fights play out in the room.
- **The choice is always "move forward":** pick one of the exits (left, middle, right).
- **The doors are blank.** They don't tell you what's behind them. That's what classes like Wayfinders and Dungeon Guides are for: they can read the doors, sense danger, or see further ahead. Scout pets can help too.
- **Completely random:** room layouts and what's behind each door change every time. You can't memorize the dungeon.
- **Traps:** rooms and doors can be trapped. Classes and skills can spot and disarm them.
- **What stays the same:**
  - **Town entrances,** on certain floors. A town entrance looks like a regular door until you find it.
  - **Tunnels** on certain floors, once you've done their quest.
- **Once you find a town entrance:**
  - It stays on that floor for good, named and unique.
  - It becomes a **fast travel point,** so you can return to it.
- **Things to tap in rooms:** chests (some are mimics), pots, traps, shrines, levers, keys and locked doors, nests, NPC events.
- **Other doors** (behind blank doors): goblin trader, elite, treasure, rest, shrine, portal to a hidden dungeon, stairs.
- **Autoplay** picks doors at random and skips interactions. Manual play gets the interactions, and class sight makes manual choices better.
- **To settle:**
  - Which existing classes become Wayfinder / Dungeon Guide types. New classes, branches, or skills on current classes?
  - How fast travel to a found town works with checkpoints. Suggested: a found town works like a checkpoint you can start dives from.

## Existing systems stay
Realms, race powers and awakening, god trials, classes and evolutions, curses and the rest are all kept. Each one gets fitted into the 1,000 floors: where it unlocks, and how it works with towns, friendliness and death. Pets change as described above.

## Art
- Sprites for health potions and every consumable, like the gear icons.
- Egg sprites and pet sprites, including walking sprites for pets in town.
- A Clinic building for the town map.
- Portal art for hidden dungeon doors, one color per theme.
- Room tiles, blank doors, traps, and a "found town" door look.
- For each of the 10 Calamities: the monster, a full gear set (one piece per slot, including its Unique Mythic), and its pet. Plus Mythic and Unique Mythic frame colors, Soulbound and Account-bound markers, an item history panel, a Hall of Fame screen, a ghost look for challenge fights, and a black-out screen for the Calamity knockout.

## Leaderboard and towns (needs online)
- **Rank order:**
  1. Deepest floor reached.
  2. Same floor: fewer deaths ranks higher.
  3. Same floor and same deaths: higher damage output ranks higher. Damage output means the team's average damage per turn on the run that set the record, measured by the game (not a gear number), so it reflects how well the team is actually built.
- Death count and damage output are both shown next to each name.
- **One board for everyone:** autoplay and manual players share it. Autoplay gets no advantage because manual play gets the better choices and every interaction.
- **Hardcore has its own board.**
- **Calamity Hall of Fame:** 10 seats, one per Calamity, each held by a registered hero. After a full year of inactivity, anyone can challenge the holder's ghost with a team of 3 for the seat and the Unique Mythic, and the Mythic pieces go back into that Calamity region's loot pool. Every holder is remembered forever.
- A starting town per race, each with its own look, music, shop stock and NPCs.
- **Seasonal leaderboards** with status rewards: titles, cosmetics, name colors. No power rewards. Rewards arrive by mail.
- **First-kill names** carved on bosses.
- **Race standings** that give small town bonuses.
- Maybe a neutral hub deep in the dungeon where all races meet.

## Build order
1. **Rules:** Mailbox, loot rarity, Bank, death penalty and checkpoints, leaving between floors, backpacks, goblin trader and Return Scrolls, consumable sprites, 1,000 floors, the 9-hero roster with 3 sent in, heroes and pets in town, Beast Tamer unlock and catching, the Pet tab, pets and eggs, the Clinic, Soulbound and Account-bound items, Calamity encounters and the knockout, and the one-time save reset (all built locally; stage 1 complete, waiting for install).
2. **Top-down room view** with three blank doors, random layouts, traps, and classes that read doors.
3. **Room interactions:** chests, traps, shrines, pots, nests, keys, events, hidden dungeon portals.
4. **Dungeon towns and friendliness:** hidden town entrances that become named fast travel points, quest tunnels, the race friendliness table, NPC reactions by alignment, kind/mean choices, egg quests.
5. **Online:** leaderboards, seasons, race home towns, server mail to all players, Calamities killed for everyone, Mythics and Unique Mythics with history, the Hall of Fame, ghost challenges, released Mythics in the loot pool, and server checks against cheating.
