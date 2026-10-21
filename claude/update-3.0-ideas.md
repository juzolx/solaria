# Solaria 3.0: brainstorm (started Oct 20 2026)

Version names (Juzo, Oct 20): the original game was 1.0. The big update we just
finished is 2.0 (it goes out at release). The next update after release is 3.0.
Brainstorm only for now: nothing gets built until Juzo says so.

## Pets
- Pets come from **nests only**. A nest is the second-rarest find in the game,
  after a Calamity (Calamity: about 1 in 20,000 fights; idea: a nest behind about
  1 in 2,000 doors, from floor 3; every nest holds an egg).
- **Every region has its own eggs**: they hatch into that region's monsters.
- **Clear ranks**: Common, Uncommon, Rare, Epic, Legendary, Mythic. The rank shows
  the moment you find the egg (in its color), and each rank is clearly stronger
  (idea: a pet hits for 8 / 12 / 17 / 24 / 33 / 45% of your Attack).
- **Remove** the other egg sources: Snik's eggs, eggs as quest/bounty rewards,
  dying beasts, spared monsters.
- Keep (to confirm with Juzo): the egg's little care task before it hatches,
  and Beast Tamer catching (that hidden class's ability).
- Started code is saved in claude/patches/3.0-pets-nests-started.patch (not applied).

## Story
- Juzo writes a real story, based on the game. Claude then fits the game to it:
  zone and boss names, lore pages, NPC lines (town keepers, travelers), hidden
  class lore and rumors, loading-screen tips.
- Offer: a short list of what the game already implies (the eclipsed sun of the
  splash, the dungeon and its 1,000 floors, the Calamities, the descenders' camps,
  the towns) for the story to build on.

## Art and sound (no budget)
- Stay with the vetted free packs on the Art Direction page (Gothicvania, Pixel
  Beasts, Dead Forest, Shikashi's icons), recolored to the palette in code.
- Must fix before selling: replace the non-commercial effects pack (BDragon1727)
  with Gothicvania Magic Pack 9 (CC0).
- Music and sound: free CC0 / CC-BY packs (OpenGameArt, itch.io; Kevin MacLeod
  with credit).
- Later, if there's money: commission only what packs can't cover (the 10
  Calamities). Places: itch.io, r/gameDevClassifieds, r/PixelArt.

## Release notes to keep in mind
- Playtesters pick things up quickly, and retention is strong, especially with the
  Wheel (gambling). Apple rates simulated gambling (even for game gold) at 12+ or
  17+ depending on how often it happens: pick the App Store age rating on purpose.
- A tester plays for two weeks before release while updates continue.

## From Claude's design review (to consider)
- An economy sheet: every source and sink of gold, scrap, dust and materials.
- Target times for milestones (how long to floor 100, which now opens a town's
  second hero, and 250 / 500 / 750).
- Check the power curve: hidden classes (about x2.1 by 60), the bench, a team of
  three, against the monster curve.
- Make the extraction choices (which door, when to go home, what to carry) come
  up often and read clearly.
- A short living design doc (rules, numbers, the reasons), so decisions like
  9 -> 5 hero slots or hidden classes becoming permanent stay written down.
