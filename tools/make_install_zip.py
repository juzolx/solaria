"""Zips the git-tracked files that differ from Juzo's PC copy.
1. On the PC (device_bash):  cd $HOME/mnt/solaria && python3 tools/pc_hash.py > $HOME/mnt/Downloads/solaria_pc_hashes.txt
2. Stage that file, then here:  python3 tools/make_install_zip.py /mnt/user-data/uploads/Downloads/solaria_pc_hashes.txt NAME
Writes /mnt/user-data/outputs/NAME.zip and prints the changed files.
"""
import hashlib, os, subprocess, sys, zipfile
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(root)
pc = {}
for line in open(sys.argv[1], encoding="utf-8"):
    h, p = line.rstrip("\n").split(" ", 1)
    pc[p] = h
files = subprocess.check_output(["git", "ls-files"], text=True).split("\n")
changed = [f for f in files if f and not f.startswith(".godot/") and not f.endswith((".import", ".uid"))
           and os.path.exists(f) and pc.get(f) != hashlib.md5(open(f, "rb").read()).hexdigest()]
os.makedirs("/mnt/user-data/outputs", exist_ok=True)
out = "/mnt/user-data/outputs/%s.zip" % sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in changed:
        z.write(f, f)
print(len(changed), "files,", os.path.getsize(out), "bytes ->", out)
print(" ".join(f for f in changed if not f.startswith("art/lpc/f/"))[:3000])
