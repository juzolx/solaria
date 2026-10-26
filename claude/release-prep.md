# Release prep (after 2.1)

Juzo, 26 Oct 2026: after the 2.1 update and his hard playtest, get the game ready for release on the App Store. Fixes from the playtest are part of the final big update.

## Order of work
1. Finish 2.1: 5 Fable rounds per area, final Fable check, full suite, install to the play copy, push.
2. Juzo playtests. Notes go in `claude/playtest-notes.md`.
3. Final big update: fix the playtest notes, plus a first-hour new-player Fable check.
4. Release prep (below), which can partly run in parallel with step 3.

## Needs Juzo (money, accounts, decisions)
- [ ] Apple Developer account ($99/yr; planned after payday, about Nov 6). Juzo signs up himself, and Claude never handles the login.
- [ ] Codemagic (cloud Mac builds) account linked to the GitHub repo. Juzo authorizes it.
- [ ] App name check on the App Store ("Solaria" may be taken; pick a subtitle or alternative).
- [ ] Price: free with cosmetic in-app purchases, or paid? (The plan so far: cosmetic/status IAP only, no paid random items.)
- [ ] Age rating answers (fantasy violence).
- [ ] Goddess name (working name: Solaris), if it appears in release text.

## Claude can prepare
- [ ] iOS export preset in Godot (bundle id, portrait lock, icons, launch screen, version 2.1.0 / build number).
- [ ] App icon set (1024 px plus the sizes Godot needs) in the game's pixel style; Juzo approves.
- [ ] App Store screenshots: 6.9" and 6.5" iPhone sizes, from the real game; Juzo approves.
- [ ] Store text: description, keywords, promo line and what's new. Juzo approves.
- [ ] Privacy policy page (the game collects no personal data while online is off) and the App Privacy answers.
- [ ] Credits and licence check: every free art/sound asset listed with its licence (LPC is already removed).
- [ ] Codemagic build config (codemagic.yaml) for an unsigned and then a signed TestFlight build.
- [ ] Phone performance budget: memory caps, texture sizes, 60 fps check on an older iPhone in TestFlight.
- [ ] Save safety: the save wipe for 2.1 (decided 23 Oct), versioned saves, and a backup/restore test.
- [ ] Crash and error logging plan (Godot logs into the save folder; optional later).
- [ ] TestFlight checklist: install, first run, a long session, background/resume, low storage, airplane mode.
- [ ] IAP: the screens exist but stay switched off until accounts are ready (decide at release).

## Dates
- Target was Nov 10, flexible; quality comes before the date.
