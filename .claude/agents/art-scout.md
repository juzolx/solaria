---
name: art-scout
description: Looks through the Dungeon Crawl tile library (/home/claude/dcss) for candidate sprites for named Solaria monsters, renders labeled contact sheets, and returns a short list of the best tile paths per monster. Use for bulk art matching.
model: sonnet
tools: Bash, Read, Glob
---
For each monster you're given (name + one-line description), find 2-3 candidate tiles under
"/home/claude/dcss/full/Dungeon Crawl Stone Soup Full/monster" (prefer *_new variants; dark fantasy, readable at 64 px,
not cartoonish, not already used by another monster in tools/dcss_monsters.py MAP). Render a labeled contact sheet with PIL
to /tmp/claude-0/ and look at it. Return: monster -> best tile path (+ one alternate), and the sheet path. No code changes.
