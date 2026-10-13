"""Builds credits.gd (the in-game Credits page) from art/lpc/CREDITS.md and art/fx/CREDITS.md.
Run after tools/lpc_extract.py and tools/fx_extract.py."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
parts = []
for p in ["art/lpc/CREDITS.md", "art/fx/CREDITS.md"]:
    t = open(os.path.join(ROOT, p)).read()
    lines = []
    for l in t.splitlines():
        if l.startswith("# "):
            lines.append("[b][color=#e8b14a]%s[/color][/b]" % l[2:])
        elif l.startswith("- **"):
            k, rest = l[4:].split("**:", 1)
            lines.append("[color=#aab3c8]%s[/color]:%s" % (k, rest))
        else:
            lines.append(l)
    parts.append("\n".join(lines))
text = "\n\n".join(parts).replace("\\", "\\\\").replace('"', '\\"')
open(os.path.join(ROOT, "credits.gd"), "w").write(
    'class_name Credits\nextends RefCounted\n## Made by tools/make_credits.py - who made the art (their licenses ask for this). Don\'t edit by hand.\n\nconst TEXT := "%s"\n' % text.replace("\n", "\\n"))
print(len(text))
