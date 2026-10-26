#!/bin/bash
# One command for every check. Prints only a short summary (and failures).
#   tools/check.sh          parse check + all tests
#   tools/check.sh shots    ...plus every screen at phone size (shots/tour)
#   tools/check.sh perf     ...plus a 60 s Auto-play frame-time report (shots/perf)
#   tools/check.sh parse    parse check only
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
[ "$1" = "parse" ] && exit 0
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
