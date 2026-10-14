#!/bin/bash
# One command for every check. Prints only a short summary (and failures).
#   tools/check.sh          parse check + all tests
#   tools/check.sh shots    ...plus phone screenshots (/root/shots/town)
#   tools/check.sh parse    parse check only
cd "$(dirname "$0")/.."
G=${GODOT:-/root/godot/Godot_v4.7.2-stable_linux.x86_64}
fail=0
timeout 600 $G --headless --editor --quit --path . >/dev/null 2>&1   # reimport + register classes
errs=$(for f in *.gd; do $G --headless --path . --check-only --script $f 2>&1 | grep -E "SCRIPT ERROR|Parse Error" -A1 | grep -v "^--"; done | sort -u | head -20)
if [ -n "$errs" ]; then echo "PARSE ERRORS:"; echo "$errs"; exit 1; fi
echo "parse: ok"
[ "$1" = "parse" ] && exit 0
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
for t in tests/stage2_*.gd; do [ -f "$t" ] && run "$(basename $t .gd)" "timeout 600 $G --headless --path . -s $t"; done
if [ "$1" = "shots" ]; then
  out=$(timeout 400 xvfb-run -a -s "-screen 0 1400x1400x24" $G --path . --resolution 430x932 -s tests/town_shots.gd 2>&1)
  echo "$out" | grep -q "shots ok" && echo "shots: ok (/root/shots/town)" || { echo "shots: FAILED"; echo "$out" | grep -E "SCRIPT ERROR" -A1 | head; fail=1; }
fi
[ $fail = 0 ] && echo "ALL GOOD" || echo "SOMETHING FAILED"
exit $fail
