# Solaria expert agents (from Oct 23 2026)

How work flows:
1. **Research loop** (Fable): 10 rounds on one topic. Each round researches, then
   double-checks the previous round's claims against sources, goes deeper on gaps,
   and rewrites the document. Output: one complete document in `claude/research/`.
2. **Expert agent** takes that document and does the work slowly and carefully in
   its own worktree, following the rules in CLAUDE.md and this file.
3. **Final checker** (Fable): critiques every mistake; the expert fixes; repeat
   until "VERDICT: CLEAN". Only then the lead merges and runs the full suite.

Every expert prompt starts by reading this file, CLAUDE.md, claude/dispatch-plan-2.1.md,
claude/stable-ids.md and its research document.

## Roles

| Expert | Owns | Must know |
|---|---|---|
| Art Director | heroes (2x), town, dungeon look, monsters, animation, effects | art_style.gd palette/outline/grid, tools/bake_art.gd, C:\ai ComfyUI (SDXL + pixel LoRA, ControlNet pose, IP-Adapter, rembg), Juzo's reference shots |
| Systems Designer | classes, pets, buildings, Church, collections, portals, presets | owner's class rules (15/35/75, unique + God classes by secret deeds), pets from nests, cosmetics never power |
| Balance & Economy | progression curve, gold/scrap/dust, drop rates, Wheel odds | tools/balance_sim.gd, claude/economy.md, target floor 100 in 4-6 h |
| Save & Platform | saves, iOS lifecycle, performance, export, Codemagic/TestFlight | save_io.gd, export_presets.cfg, codemagic.yaml, Xcode 26 rule |
| UX & Onboarding | first-time flow, What's New, hints, text, phone layout | portrait 430x932, big touch targets, plain words, no casino words |
| Release & Store | privacy, age rating, listing, screenshots, credits/licenses | store/*.md, claude/age-rating.md, claude/licenses-audit.md |
| Final Checker (Fable) | reviews every change before merge | critique every mistake; VERDICT line |

## Rules for every expert
- Work only in your own worktree `C:\gamedev\solaria_wt_<name>` with its own override.cfg.
- `tools/check.sh` must end ALL GOOD (own log file name); never commit override.cfg.
- Never kill Godot processes you didn't start; never touch C:\gamedev\solaria or real saves.
- Small hooks in game_state.gd; logic in own files; stable ids; gold/scrap/dust only.
- Owner decisions win; if a call is truly the owner's, pick a sensible default, write it
  as an open question, and keep going.
