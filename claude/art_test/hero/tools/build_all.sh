#!/bin/sh
# Rebuild every pass-2 layer and sheet.
cd "$(dirname "$0")"
PY=/c/ai/ComfyUI/python_embeded/python.exe
$PY -I draw_v2.py && $PY -I draw_portrait.py && \
cp layers/hair_short.txt layers/hair_mop.txt && cp layers/hair_short.shade.txt layers/hair_mop.shade.txt && \
cp layers/port_hair_short.txt layers/port_hair_mop.txt \&\& cp layers/port_hair_short.shade.txt layers/port_hair_mop.shade.txt \&\& 
$PY -I hairlib.py && $PY -I draw_arms.py && $PY -I make_sheets.py --all
rm -rf __pycache__
