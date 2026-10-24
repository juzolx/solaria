#!/bin/sh
# Rebuild every pass-2 layer and sheet.
cd "$(dirname "$0")"
PY=/c/ai/ComfyUI/python_embeded/python.exe
$PY -I draw_v2.py && $PY -I draw_portrait.py || exit 1
# the hand-drawn mop (battle + portrait) is kept as the "mop" style before hairlib writes "short"
for f in hair_short port_hair_short; do
  n=$(echo $f | sed 's/short/mop/')
  cp layers/$f.txt layers/$n.txt && cp layers/$f.shade.txt layers/$n.shade.txt
done
$PY -I hairlib.py && $PY -I draw_arms.py && $PY -I make_sheets.py --all
rm -rf __pycache__
