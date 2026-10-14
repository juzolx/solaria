"""Run on Juzo's PC inside the game folder: prints 'md5 path' for every file (for tools/make_install_zip.py)."""
import hashlib, os
for root, dirs, files in os.walk("."):
    dirs[:] = [d for d in dirs if d not in (".godot", ".git", "_free_assets")]
    for f in files:
        if f.endswith((".import", ".uid")):
            continue
        p = os.path.join(root, f)
        print(hashlib.md5(open(p, "rb").read()).hexdigest(), p[2:].replace(os.sep, "/"))
