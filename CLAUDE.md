# Solaria — rules for Claude

Juzo's phone-first, dark fantasy, pixel-art extraction dungeon crawler. Godot 4.7.2, GDScript (warnings are errors).
Juzo is not a coder: talk in plain words, show screenshots, ask before big design calls.

Since 19 Oct 2026 the game is built by a Claude session on Juzo's Windows PC (real GPU). The cloud session handed over and stopped.

## Never
- Touch saved passwords or any credential store (Juzo's one hard rule).
- Install to Juzo's PC unless he asked. (For 0.13 he did: install each finished, tested part as you go.)
- Reveal hidden classes or their unlock rules in game text (rumors only).
- Add offline progress (nothing advances while the game is closed).
- Commit to `master` (= tag `stage1-0.12`, 0.12 "The Deep"). 0.13 is on `stage2`; the big update is on `big-update` (branched from `stage2`).
- Run tests without the `override.cfg` in place: tests delete saves. It redirects user data to `%APPDATA%\solaria_claude_test`; Juzo's real saves are in `%APPDATA%\Godot\app_userdata\solaria`. `override.cfg` is git-ignored; never commit it.

## Start of every session
1. Read `claude/stage2-progress.md` (0.13 log) and the big-update plan (artifact: https://claude.ai/artifact/7wjh2ZR5MvDMCHizf8Q12X). Design decisions: `claude/dungeon-revamp-design.md`. Build notes: `.claude/skills/solaria-godot-build/SKILL.md`.
2. `cd C:/gamedev/solaria_dev && git checkout big-update && git status`: finish or fix uncommitted work first.
3. Use `CODE_INDEX.md` to jump to the right lines instead of reading whole files. game_state.gd and battle_view.gd are huge: read only the ranges you need. (Regenerating it needs Python, which isn't installed on the PC.)

## Checks (run before every commit)
- `GODOT="/c/Users/count/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe" bash tools/check.sh` (Git Bash): reimport, parse-check every script, run every test file. Ends with ALL GOOD or SOMETHING FAILED.
- Screenshots need a windowed run (`--resolution 430x932`); `tests/_ui_tour.gd` captures every screen.
- Known flaky checks: "pets fight" (rerun once). "elite is tougher" was a real bug, fixed in the dark-art patch.
- New test files go in `tests/stage2_*.gd` (the check script picks them up). Print "... DONE, failures: N" at the end.

## Commits
Commit each finished part on `big-update` with a clear message, ending with:
```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```
Then add a line to the log in `claude/stage2-progress.md` and the patch notes (`patch_notes.gd`).

## Installing (only when Juzo says so)
The playable copy is C:\gamedev\solaria (no git). Copy changed git-tracked files from C:\gamedev\solaria_dev into it (never `.godot/`, never `override.cfg`), then tell Juzo to open the project in the Godot editor once (registers new scripts) before playing.

## Art
- Heroes: PixelLab frames (art/heroes, hero_art.gd): back view in fights, front portrait in menus. No LPC art ships (removed for the App Store, decision D1).
- Monsters, bosses, Calamities, pets: Dungeon Crawl Stone Soup tiles, CC0 (`tools/dcss_monsters.py`). Sources (DCSS + Screaming Brain textures) are zipped in C:\gamedev\solaria_sources. The art tools are Python + Pillow: ask Juzo before installing Python, or port the step to GDScript.
- Free downloads on Juzo's PC go to C:\gamedev\solaria\_free_assets, light on storage. Credit every artist (credits_data.gd + CREDITS.md files).

## Agents
Spawning subagents costs more tokens than it saves for step-by-step work. Use one only for big independent jobs.

## Saving usage (be realistic)
What actually costs the most is reading big files and long command output into the conversation.
- Use `tools/check.sh` (short summary) instead of raw test output; read only line ranges from CODE_INDEX.md.
- Don't re-render or re-read screenshots you've already checked.
