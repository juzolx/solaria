#!/bin/bash
# Pets 2: downloads one call's 64 review candidates. usage: fetch.sh <call> <object_id>
D="$(dirname "$0")/../raw/call$1"; mkdir -p "$D"
B="https://backblaze.pixellab.ai/file/pixellab-characters/objects/298f7e86-4e4a-42d0-b071-84e88b6e1161/$2/rotations"
for i in $(seq 0 63); do curl -s -o "$D/c_$(printf %02d $i).png" "$B/frame_$i.png" & done; wait
ls "$D" | wc -l
