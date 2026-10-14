# Solaria — rules for Claude

Juzo's phone-first, dark fantasy, pixel-art extraction dungeon crawler. Godot 4.7.2, GDScript (warnings are errors).
Juzo is not a coder: talk in plain words, show screenshots, ask before big design calls.

## Never
- Touch saved passwords or any credential store (Juzo's one hard rule).
- Install to Juzo's PC unless he says "install it" (or plainly asks for the files on his PC).
- Reveal hidden classes or their unlock rules in game text (rumors only).
- Add offline progress (nothing advances while the game is closed).
- Commit stage 2 work to `master`. `master` / tag `stage1-0.12` is what's installed (0.12 "The Deep"). Stage 2 lives on branch `stage2`.

## Start of every session
1. Read the Project doc `claude/stage2-progress.md` (plan + log). Design decisions: `claude/dungeon-revamp-design.md`.
2. `cd /root/solaria && git checkout stage2 && git status` — finish or fix uncommitted work first.
3. Use `CODE_INDEX.md` (regenerate: `python3 tools/index.py`) to jump to the right lines instead of reading whole files. game_state.gd and battle_view.gd are huge: read only the ranges you need.

## Checks (run before every commit)
- `tools/check.sh` — reimport, parse-check every script, run every test file. Prints a short summary; ends with ALL GOOD or SOMETHING FAILED.
- `tools/check.sh shots` — same, plus phone screenshots in /root/shots/town (look at the ones your change touched).
- Known flaky checks: "elite is tougher" (rerun once).
- New test files for stage 2 go in `tests/stage2_*.gd` (the check script picks them up). Print "... DONE, failures: N" at the end.

## Commits
Commit each finished part on `stage2` with a clear message, ending with:
```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019Z55pVpXVF9JmQdqZFyzvt
```
Then add a line to the Log in `claude/stage2-progress.md` (Project doc) and patch notes (`patch_notes.gd`, version 0.13).

## Installing (only when Juzo says so)
Juzo's PC: C:\gamedev\solaria (and C:\Users\count\Downloads), reached through the device tools.
1. On the PC: hash every file (skip .godot, _free_assets, .import, .uid) into Downloads, stage that list.
2. Here: zip only the git-tracked files whose hash differs (never `.godot/`).
3. SendUserFile → device_commit_files to Downloads → device_bash python unzip into $HOME/mnt/solaria.
4. Tell Juzo to open the project in the Godot editor once (registers new scripts) before playing.

## Art
- Heroes: LPC parts (art/lpc, `tools/lpc_extract.py`, source /home/claude/lpc). Directions: "" right, "up" back, "down" front.
- Monsters, bosses, Calamities, pets: Dungeon Crawl Stone Soup tiles, CC0 (`tools/dcss_monsters.py`, source /home/claude/dcss; re-download "Dungeon Crawl 32x32 tiles" from OpenGameArt if missing).
- Free downloads on Juzo's PC go to C:\gamedev\solaria\_free_assets, light on storage. Credit every artist (credits.gd + CREDITS.md files).

## Agents
Spawning subagents costs more tokens than it saves for step-by-step work. Use one only for big independent jobs.

## Saving usage (be realistic)
What actually costs the most is reading big files and long command output into the conversation.
- Use `tools/check.sh` (short summary) instead of raw test output; read only line ranges from CODE_INDEX.md.
- Cheaper helper agents live in `.claude/agents/`: `checker` (Haiku: runs checks, reports failures) and `art-scout` (Sonnet: bulk sprite matching). Use them only for jobs that would otherwise flood the conversation; for normal step-by-step work, doing it directly is cheaper.
- Don't re-render or re-read screenshots you've already checked.
