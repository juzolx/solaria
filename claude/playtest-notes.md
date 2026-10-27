# Playtest notes (Juzo)

Findings from Juzo's playtest of the 2.1 build. Each line: date, where, what he saw, status.
These go into the final big update after 2.1.


## 2026-10-26 (first install of the pre-hero build)
- P1: PC wide window: the UI grows wider than the window and drifts right ("the game keeps moving the screen further"; half the screen hidden: top bar, Hero tab gear doll, right column). Sent to interface dev. Workaround: make the window taller than it is wide (phone layout).
- Town, Shop: a purple-awning market stall is hidden under the Shop's stone base; crates/barrels on the base's west edge look like they float. Sent to town dev (with a stronger check: building bases occlude, plinth props must stand fully on the plinth).
- Town: let the player zoom out far enough to see the whole town (Juzo). Sent to town dev.
- Town, gatehouse: curtain walls don't meet the gate towers (gap on the west, offset on the east); field runs up to the wall line. Sent to town dev with a wall-continuity check.
- Town, Clinic: deck overhangs the town wall; a cart hidden under the deck; town pets stacked on each other and the fence; lamp post half hidden by a planter. Sent to town dev.
- PC gets very slow while playing (with the team's background Godot runs going at the same time). Check the game's own frame cost on PC too (perf run) in the final pass.

## Install 27 Oct (big-update 7322cd6a, everything except hero Fable round 5; replaced by fde61996 below)
Installed to C:\gamedev\solaria. 5,699 old files (mostly the retired LPC hero art) moved to C:\gamedev\solaria_old_files_2.1\install_1027_1439. Juzo: open it in the Godot editor once so it re-imports, then play. Hero round 5 (bald heads, Angel wings) lands in the next install.

## Install 27 Oct, final (big-update fde61996, the whole 2.1 big update incl. hero Fable round 5)
check.sh ALL GOOD on this build. Installed to C:\gamedev\solaria, matches the build file-for-file. Juzo: open it in the Godot editor once so it re-imports, then play. Open question for Juzo while playing: on the f tier-75 outfit there's a small red bar beside the gauntlet: rune or stray? The final whole-game Fable check runs after the Sunday reset (usage).
