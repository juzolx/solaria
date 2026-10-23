# App Store age rating: draft answers for Solaria 2.1

Draft for Juzo to check in App Store Connect at release prep. Apple's tiers changed
recently (now 4+, 9+, 13+, 16+, 18+; 12+ and 17+ are gone) and the new questionnaire
must be answered or updates can be blocked (research-2.1.md, Section 6). Re-read
Apple's age ratings reference before submitting: the mapping below is copied from
our research notes, not re-verified today.

## Suggested result: 13+

Two answers decide it: frequent fantasy violence (13+) and infrequent simulated
gambling (13+). Nothing else goes higher. If the Wheel is judged "frequent", the
whole game becomes 18+, so the Wheel's design is what keeps it at 13+.

## Answers, one by one

| Question | Answer | Why |
|---|---|---|
| Cartoon or fantasy violence | **Frequent** | Every dive is fight after fight with monsters and bosses. Pixel art, no gore, but it is the core loop. Frequent = 13+ (research, Section 6). |
| Realistic violence | None | Fantasy creatures and pixel sprites only. No real-world weapons, people or blood effects. |
| Prolonged graphic or sadistic realistic violence | None | Same reason. |
| Horror / fear themes | **Infrequent** (Frequent is also defensible) | Dark-fantasy catacombs, undead, demons, Calamities and a blackout scene. Not jump scares or gore. Infrequent = 9+, frequent = 13+; either way it stays under the violence answer, so pick the honest one without worrying about the result. |
| Profanity or crude humor | None | No swearing in game text today. Re-check once the 2.1 story text lands. |
| Mature or suggestive themes | None | Death and curses are fantasy-adventure level. |
| Alcohol, tobacco or drug references | **Infrequent** | The Wheel sits in the Tavern with a barkeep and the Inn exists. Nobody drinks on screen. Check Apple's current mapping for this one; it should not go above 13+. |
| Sexual content or nudity | None | |
| Medical or treatment information | None | The "cures" are fantasy (vampire/werewolf curses), not health advice. |
| **Simulated gambling** | **Infrequent** | See below. Infrequent = 13+, frequent = 18+ (research, Section 6). |
| Real-money gambling | No | Nothing pays out real value, gold cannot be cashed out, Guideline 5.3 does not apply (research, Section 6). |
| Loot boxes | No | Wheel spins and gold are never sold for real money; the cosmetics store is off at launch. If gold or spins are ever sold, this becomes Yes (9+, Australia 16+) and Guideline 3.1.1 odds disclosure applies (research, recommendations 2 and Section 6). The odds are already on screen, so that part is ready. |
| Contests | No | No prizes for rankings. If leaderboards ever give rewards, answer Infrequent (4+). |
| Unrestricted web access | No | |
| User-generated content / messaging | No (re-check) | True if the online tabs at release are leaderboards and similar. If any chat or free-text names other players can see ships, answer Yes and add reporting/blocking. |
| Advertising | No | No ads planned. |

## Simulated gambling: why "infrequent" is honest (and what would break it)

Apple defines simulated gambling as betting without real money or cashable currency
(research, Section 6); our Wheel is exactly that. Apple does not define
"frequent", so it is our honest call (research, Section 6, interpretation).

What keeps it infrequent:
- It is a **place** (Town > Tavern > Wheel), opened on purpose. It never prompts
  during a fight or a dive, and there are no pop-ups, daily free spins or reminders.
- The game's loop is diving and fighting. The Wheel is an optional side activity
  you can ignore for a whole playthrough.
- Game gold only. Spins are never sold for real money (owner rule, 2.1).
- The Legendary table opens only at floor 250 and costs a lot of gold per spin
  (27,500 at floor 250), so it is a rare treat, not a loop.
- Odds are always on screen (the Odds button), read from the same table the code
  rolls (wheel_tables.gd). Apple only requires this for paid random items (3.1.1),
  but it is free insurance and the feature most likely to draw review questions
  (research, "Surprising / urgent").
- UI text avoids casino words: no "casino", "jackpot", "bet"; the Wheel says
  "spin", "prize", "fortune". Keep "gambling" and "casino" out of the store title,
  keywords and screenshot captions (research, Section 5; update-2.1-ideas.md).

What could make a reviewer call it frequent:
- **Many wheels / heat**: spinning again within 9 seconds builds heat, more wheels
  at once and faster spins. That rewards rapid repeat spinning. It was called
  "High stakes" and is renamed "Many wheels" in 2.1, but the mechanic is the
  strongest argument against "infrequent". Options: keep it and accept the risk,
  or drop the heat speed-up (a smaller change) if review pushes back.
- Store screenshots that lead with the Wheel. Show it in screenshot 3 or 4, not 1
  (research, Section 5).
- Any future daily spin, streak reward or notification that pulls players to the
  Wheel.

Not yet cleaned: one dungeon event still says "Bet %d gold on a coin toss"
(game_state.gd, event text). It is a game-gold coin toss, rare, and fine for the
rating, but reword it to match the no-casino-words rule when game_state.gd is free.

## Regional notes

- **Australia**: even infrequent simulated gambling is rated R18+ there (research,
  Sections 6 and "Surprising / urgent"). Not blocking. Removing the Wheel for the
  AU storefront is possible but probably not worth it.
- **Brazil** uses its own scale; fixed-odds betting needs a license, but that is
  about real money, which we do not have (research, Section 6).

## Before submitting

1. Re-read Apple's age ratings reference (developer.apple.com/help/app-store-connect/reference/age-ratings).
2. Confirm the online features at release (chat or not).
3. Confirm the story text adds no profanity or sexual content.
4. Confirm nothing sells gold or spins for real money.
