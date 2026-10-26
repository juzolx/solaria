#!/bin/bash
# One command for every check. Prints only a short summary (and failures).
#   tools/check.sh          parse check + all tests
#   tools/check.sh shots    ...plus every screen at phone size (shots/tour)
#   tools/check.sh perf     ...plus a 60 s Auto-play frame-time report (shots/perf)
#   tools/check.sh parse    parse check only
#   tools/check.sh halls [tag]  the dungeon rooms and room events of all 10 zones at 430x932 and 375x667 into
#                           shots/halls/<tag>{,_se} and shots/room_events/<tag>{,_se} (needs a window), then
#                           one contact sheet per zone into claude/art_test/halls/<tag>/ (tools/halls_sheets.py)
#   tools/check.sh sim      balance simulator only (quick: ~1 min), writes claude/balance-report.md. Not part of the normal check.
#                           Full run: godot --headless --path . -s tools/balance_sim.gd -- [heroes] [hours]
cd "$(dirname "$0")/.."
G=${GODOT:-/root/godot/Godot_v4.7.2-stable_linux.x86_64}
[ -f override.cfg ] || { echo "No override.cfg: tests delete saves, so they only run against the test folder. See CLAUDE.md."; exit 1; }
fail=0
timeout 600 $G --headless --editor --quit --path . >/dev/null 2>&1   # reimport + register classes
errs=$(for f in *.gd; do $G --headless --path . --check-only --script $f 2>&1 | grep -E "SCRIPT ERROR|Parse Error" -A1 | grep -v "^--"; done | sort -u | head -20)
if [ -n "$errs" ]; then echo "PARSE ERRORS:"; echo "$errs"; exit 1; fi
echo "parse: ok"
# Fable r3 house style: paths use "›" (#1), sizes sit on the type scale 15/20/30/40 (#7), costs say
# "gold" (#9) and the interface doesn't shout in caps (#17; the fight's floaters and moment titles may)
style=$( {
  grep -nE 'Character >' *.gd
  grep -nE '(UI\.(label|wrap|rich)|[^a-z_]_line)\(.*, (1[0-46-9]|2[1-9]|3[1-9]|[5-9][0-9])(, |\))|font_size", (1[0-46-9]|2[1-9]|3[1-9])\)|font_size=[0-9]+\]' *.gd | grep -vE 'font_size=(15|20|30|40)\]'
  grep -nE '%[ds]g[" )]' *.gd
  grep -nE 'UI\.(label|heading|chip|button|primary)\(.*to_upper\(\)\s*[,)]|UI\.(label|heading|chip)\("[A-Z]{3,} [A-Z]{3,}' *.gd
  # Fable r4 #15: the fight's scene words sit on the scale too
  grep -nE 'SCENE_FS := (1[0-46-9]|2[1-9])' *.gd
  # Fable r4 #19: a phone game says Tap, not Press / hover / drag (story lines like "they press on" are fine)
  awk '{l=$0; sub(/^[ \t]*#.*/,"",l); sub(/[ \t]#[^"]*$/,"",l); if (l ~ /"[^"]*(Press|press|Hover|hover|Drag|drag) [^"]*"/ && l !~ /Oxen could not drag|press (on|their|%[ds]|.*into your hands)/) print FILENAME":"FNR": "$0}' *.gd
} )
if [ -n "$style" ]; then echo "STYLE:"; echo "$style" | head -20; fail=1; else echo "style: ok"; fi
[ "$1" = "parse" ] && exit 0
if [ "$1" = "halls" ]; then
  tag=${2:-halls_all}
  for res in 430x932 375x667; do
    suf=""; [ $res = 375x667 ] && suf="_se"
    for z in 0 1 2 3 4 5 6 7 8 9; do
      for script in _halls_zone_shot _room_events_shot; do
        for try in 1 2 3; do
          out=$(timeout 300 "$G" --path . --resolution $res --position 3000,3000 -s tests/$script.gd -- $z $tag$suf 2>&1)
          echo "$out" | grep -q "SHOTS DONE" && break
        done
        echo "$out" | grep -q "SHOTS DONE" || { echo "halls: zone $z $script at $res FAILED"; echo "$out" | grep -E "SCRIPT ERROR|Thorin" -A1 | head -4; fail=1; }
      done
    done
  done
  python3 tools/halls_sheets.py "$tag" 2>/dev/null || py -X utf8 tools/halls_sheets.py "$tag"
  [ $fail = 0 ] && echo "halls: shots and sheets in claude/art_test/halls/$tag" && exit 0
  exit 1
fi
if [ "$1" = "sim" ]; then
  out=$(timeout 900 $G --headless --path . -s tools/balance_sim.gd -- quick 2>&1)
  echo "$out" | grep -E "^BALANCE SIM DONE|SCRIPT ERROR" -A1 | head -5
  echo "$out" | grep -q "BALANCE SIM DONE" && exit 0 || exit 1
fi
run() {  # name, command
  out=$(eval "$2" 2>&1)
  sum=$(echo "$out" | grep -E "DONE, failures|TESTS DONE" | tail -1)
  fails=$(echo "$out" | grep -E "^FAIL|SCRIPT ERROR" | head -15)
  echo "$1: ${sum:-no summary (crashed?)}"
  [ -n "$fails" ] && echo "$fails" && fail=1
  echo "$sum" | grep -q "failures: 0" || fail=1
}
run "main tests" "timeout 900 $G --headless --path . -s tests/run_tests.gd"
run "town tests" "timeout 300 $G --headless --path . -s tests/town_logic.gd"
run "fresh start" "timeout 300 $G --headless --path . -s tests/fresh_start.gd"
run "phase 11" "timeout 300 $G --headless --path . -s tests/test_phase11.gd"
for t in tests/stage[0-9]_*.gd; do [ -f "$t" ] && run "$(basename $t .gd)" "timeout 600 $G --headless --path . -s $t"; done
if [ "$1" = "shots" ]; then
  # Every screen at phone size into shots/tour (needs a real window: run on the PC, or under xvfb-run on Linux)
  wrap=""; command -v xvfb-run >/dev/null 2>&1 && wrap="xvfb-run -a -s \"-screen 0 1400x1400x24\""
  # Fable r2 #18: a gate at both phone sizes (430 pt and the 375 pt SE): overflow, short buttons,
  # small text (TOUR FAIL lines) and any engine error fail the check
  for sz in "430x932" "375x667 se"; do
    read -r res arg <<< "$sz"
    out=$(eval "timeout 400 $wrap \"$G\" --path . --resolution $res -s tests/ui_tour.gd -- $arg" 2>&1)
    if echo "$out" | grep -q "TOUR DONE"; then echo "$out" | grep "TOUR DONE" | sed "s/^/shots $res: /"; else echo "shots $res: FAILED"; echo "$out" | grep -E "SCRIPT ERROR|Refusing" -A1 | head; fail=1; fi
    echo "$out" | grep -E "TOUR FAIL" && fail=1   # (no head: its exit status is 0 even with no lines)
    echo "$out" | grep -E "^(ERROR|SCRIPT ERROR|USER ERROR):" -A1 | grep -v "^--" | sort -u | head -10 | sed "s/^/shots $res: /" | grep . && fail=1
  done
fi
if [ "$1" = "perf" ]; then
  # 60 s of Auto play at phone size; compare with earlier runs saved in shots/perf
  out=$(timeout 200 "$G" --path . --resolution 430x932 -s tests/perf_run.gd -- 60 2>&1)
  echo "$out" | grep -E "^PERF" || { echo "perf: FAILED"; echo "$out" | grep -E "SCRIPT ERROR|Refusing" -A1 | head; fail=1; }
fi
[ $fail = 0 ] && echo "ALL GOOD" || echo "SOMETHING FAILED"
exit $fail
