"""Builds credits.gd (the in-game Credits page) from art/lpc/CREDITS.md (the part-by-part LPC list; all other sources live in credits_data.gd).
Run after tools/lpc_extract.py."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
parts = []
for p in ["art/lpc/CREDITS.md"]:
    t = open(os.path.join(ROOT, p), encoding="utf-8").read()
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
open(os.path.join(ROOT, "credits.gd"), "w", encoding="utf-8", newline="").write(
    'class_name Credits\nextends RefCounted\n## Made by tools/make_credits.py: the part-by-part LPC credit list (their licenses ask for it). Don\'t edit by hand. Every other source is in credits_data.gd.\n\nconst TEXT := "%s"\n' % text.replace("\n", "\\n"))
print(len(text))
